include("dataParser.jl")
include("pairIterator.jl")
include("contours.jl")
include("segmentIntersections.jl")
include("bvhIntersection.jl")

using .dataParser, .pairIterator, .contours, .segmentIntersections, .bvhIntersection
using ProgressBars

function main()

	dataDir = "/home/chris/Development/fenkar_program/out/"
	shape = (512,512,1)
	
	tt = 1:1000
	T = Float32
	
	spacings = T.((0.02,0.02,5.0))
	
	x = Array{T,length(shape)+1}(undef, shape..., 3)
	y = Array{T,length(shape)+1}(undef, shape..., 3)

	cores = Vector{NTuple{3,T}}(undef,0)

	for t in ProgressBar(tt)
		fname = filename(dataDir, shape, t)
		readFile!(x, y, fname);
		
		cs = computeLevels(y[1:512,1:512, 1, 1:2])
		intersections = computeIntersections(cs)
		for core in intersections
			push!(cores, (core..., T(t)).*spacings)
		end
	end
	
	@show length(cores)
	
	return nothing
end

main()
