module readTests

include("../bvhIntersection.jl")
using .bvhIntersection, BenchmarkTools, Test, Random


function simple(shape::NTuple{2,Int}, ::Type{T}; ep = (T(300.0), T(2/(1+sqrt(5)))^2)) where T<:Real
	
	# input field (random could be stress-test)
	u = zeros(T, shape...)
	v = zeros(T, shape...)
	@inbounds for i in 1:size(u,1), j in 1:size(u,2)
		x = (i-shape[1]/2)/shape[1]
		y = (j-shape[2]/2)/shape[2]
		u[i,j] = sin(ep[1]*(x^2 + y^2))
		v[i,j] = tanh(x - ep[2]*y)
	end
	
	intersects = find_cores(u; outname="simple_test")
	@show length(intersects)
	return nothing
end

function needlesslycomplex(shape::NTuple{2,Int}, ::Type{T})

	# input field (random could be stress-test)
	u = rand(T, shape...).-T(0.5)
	v = rand(T, shape...).-T(0.5)
	intersects = find_cores(u; outname="needlesslycomplex")
	@show length(intersects)
	return nothing
end



@test filenameTest(testShape,testt)
@test filenameTest(testShape,5000) broken=true
@test filenameTest((testShape...,testt))
@test readTest1(testShape, testt)
@test readTest2(testShape, testt)

for readFunction in (read1Benchmark, read2Benchmark)
	bm = readFunction(testShape, testt);	
	@test (bm.allocs <= 0) broken=true
	@test (bm.memory <= 0) broken=true
	@test (maximum(bm.times)/prod(testShape) <= 25)
end
end
