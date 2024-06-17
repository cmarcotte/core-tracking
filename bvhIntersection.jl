module bvhIntersection

export computeIntersections

include("contours.jl")
include("pairIterator.jl")
include("segmentIntersections.jl")
using .contours, .pairIterator, .segmentIntersections, Makie, ImplicitBVH
using Makie: Contours.contour
using ImplicitBVH: BSphere

function points2Center(p0::NTuple{2,T}, p1::NTuple{2,T}) where {T<:Real}
	return [((p0.+p1).*T(0.5))...,zero(T)]
end

function points2Center(p0::NTuple{3,T}, p1::NTuple{3,T}) where {T<:Real}
	return [((p0.+p1).*T(0.5))...]
end

function points2Radius(p0::NTuple{D,T}, p1::NTuple{D,T}) where {D, T<:Real}
	return sqrt(sum((p0.-p1).^2))
end

function segments2BSpheres(cs)
	T = eltype(cs.lines[1].vertices[1])
	bounding_spheres = BSphere{T}[]
	for l in cs.lines
		for (p0,p1) in PairIterator(l.vertices)
			push!(bounding_spheres, 
				BSphere{T}(points2Center(p0,p1), points2Radius(p0,p1))
			)
		end
	end
	return bounding_spheres
end

function extractSegmentPair(n::Int, cs)
	m=0
	for l in cs.lines
		if n-m > length(l.vertices)-1
			m+=(length(l.vertices)-1)
		else
			for q in 1:length(l.vertices)-1
				m+=1
				if (m==n)
					return (l.vertices[q],l.vertices[q+1])
				end
			end
		end
	end
end

function computeIntersections(css)
	
	# form BSphere arrays from vertices pair-wise
	bs = (segments2BSpheres(css[1]), segments2BSpheres(css[2]))
	
	# Build BVHs using bounding boxes for nodes, UInt32 indices
	bvhs = (BVH(bs0, BSphere{T}, UInt32), BVH(bs1, BSphere{T}, UInt32))
	
	# Traverse BVH for contact detection
	traversal = traverse(
		  bvh[1],
		  bvh[2],
		  default_start_level(bvh[1]),
		  default_start_level(bvh[2]),
		  # previous_traversal_cache,
		  num_threads=16,
	)
	
	cache = intersectionCache{2D,2+D,T}();
	
	intersections = Vector{NTuple{D,T}}(undef,0)
	
	for ct in traversal.contacts
		p0, p1 = extractSegmentPair(ct[1], css[1])
		q0, q1 = extractSegmentPair(ct[2], css[2])
				
		fillCache!(cache, p0, p1, q0, q1);
		solveIntersection!(cache)
		if !any(isnan.(cache.X))
			push!(intersections, cache.X[3:4])
		end
	end
	return intersections
end

end
