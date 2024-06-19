module bvhTests

include("../segmentIntersections.jl")
include("../contours.jl")
include("../bvhIntersection.jl")
include("../dataParser.jl")
using .dataParser, .segmentIntersections, .contours, .bvhIntersection, BenchmarkTools, Test, Random, CairoMakie, ImplicitBVH
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

function simple(shape::NTuple{2,Int}, ::Type{T}; ep = (T(300.0), T(2/(1+sqrt(5)))^2)) where T<:Real
	# input field (random could be stress-test)
	u = zeros(T, shape..., 2)
	@inbounds for i in 1:shape[1], j in 1:shape[2]
		x = (i-shape[1]/2)/shape[1]
		y = (j-shape[2]/2)/shape[2]
		u[i,j,1] = sin(ep[1]*(x^2 + y^2))
		u[i,j,2] = tanh(x - ep[2]*y)
	end
	return u
end

function reasonable(shape::NTuple{2,Int}, ::Type{T}) where {T<:Real}
	x = Array{T,4}(undef, shape..., 1, 3);
	y = Array{T,4}(undef, shape..., 1, 3);
	dataDir = "/home/chris/Development/fenkar_program/out/"
	t = rand(Xoshiro(1234), 1:1000)
	fname = filename(dataDir, (shape...,1,t))
	if !isnothing(fname)
		readFile!(x, y, fname)
	end
	return y[:,:,1,1:2]
end

function needlesslycomplex(shape::NTuple{2,Int}, ::Type{T}) where {T<:Real}
	# input field (random could be stress-test)
	u = rand(Xoshiro(1234), T, shape..., 2).-T(0.5)
	return u
end

function testall(initFn::F, shape::NTuple{2,Int}, ::Type{T}; outname="$(initFn)") where {F<:Function,T<:Real}
	u = initFn(shape, T)
	cs = computeLevels(u)
	intersections = testIntersections(cs)
	
	fig = Figure()
	ax = Axis(fig[1,1], aspect=DataAspect())
	contour!(ax, u[:,:,1], levels=[0.0], linewidth=0.5, color=:red)
	contour!(ax, u[:,:,2], levels=[0.0], linewidth=0.5, color=:blue)
	scatter!(ax, intersections, markersize=3, color=:black)
	hidedecorations!(ax)
	save("./$(outname).svg", fig, pt_per_unit=4)
	return true
end

@test testall(simple, (128,128), Float32)
@test testall(reasonable, (512,512), Float32)
@test testall(needlesslycomplex, (128,128), Float32)

end
