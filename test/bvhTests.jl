module bvhTests

include("../segmentIntersections.jl")
include("../contours.jl")
include("../bvhIntersection.jl")
using .segmentIntersections, .contours, .bvhIntersection, BenchmarkTools, Test, Random, CairoMakie, ImplicitBVH
using ImplicitBVH: BSphere

function testIntersections(css)
	D = length(css[1].lines[1].vertices[1])
	T = eltype(css[1].lines[1].vertices[1])
	
	# form BSphere arrays from vertices pair-wise
	bs = (bvhIntersection.segments2BSpheres(css[1]), bvhIntersection.segments2BSpheres(css[2]))
	
	# Build BVHs using bounding boxes for nodes, UInt32 indices
	bvhs = (BVH(bs[1], BSphere{T}, UInt32), BVH(bs[2], BSphere{T}, UInt32))
	
	# Traverse BVH for contact detection
	traversal = traverse(
		  bvhs[1],
		  bvhs[2],
		  default_start_level(bvhs[1]),
		  default_start_level(bvhs[2]),
		  # previous_traversal_cache,
		  num_threads=16,
	)
	
	cache = intersectionCache{2D,2+D,T}();
	
	intersections = Vector{NTuple{D,T}}(undef,0)
	
	for ct in traversal.contacts
		p0, p1 = bvhIntersection.extractSegmentPair(ct[1], css[1])
		q0, q1 = bvhIntersection.extractSegmentPair(ct[2], css[2])
		
		@test all(bs[1][ct[1]].x .≈ bvhIntersection.points2Center(p0,p1))
		@test bs[1][ct[1]].r 			≈ bvhIntersection.points2Radius(p0,p1)
		@test all(bs[2][ct[2]].x .≈ bvhIntersection.points2Center(q0,q1))
		@test bs[2][ct[2]].r 			≈ bvhIntersection.points2Radius(q0,q1)

		fillCache!(cache, p0, p1, q0, q1);
		solveIntersection!(cache)
		if !any(isnan.(cache.X))
			push!(intersections, (cache.X[3], cache.X[4]))
		end
	end
	return intersections
end

function needlesslycomplex(shape::NTuple{3,Int}, ::Type{T}) where {T<:Real}
	# input field (random could be stress-test)
	u = rand(T, shape...).-T(0.5)
	return u
end

function testall(; outname="test_rand")
	u = needlesslycomplex((128,128,2), Float32)
	cs = computeLevels(u)
	intersections = testIntersections(cs)
	
	fig = Figure()
	ax = Axis(fig[1,1], aspect=DataAspect())
	contour!(ax, u[:,:,1], levels=[0.0], linewidth=0.25, color=:red)
	contour!(ax, u[:,:,2], levels=[0.0], linewidth=0.25, color=:blue)
	scatter!(ax, intersections, markersize=1, color=:black)
	hidedecorations!(ax)
	save("./$(outname).svg", fig, pt_per_unit=4)
	return true
end

@test testall()

end
