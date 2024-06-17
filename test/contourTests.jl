module contourTests

include("../contours.jl")
using .contours, BenchmarkTools, Test, Random


function simple(shape::NTuple{2,Int}, ::Type{T}; ep = (T(300.0), T(2/(1+sqrt(5)))^2)) where T<:Real
	
	# input field (random could be stress-test)
	u = zeros(T, shape..., 2)
	@inbounds for i in 1:size(u,1), j in 1:size(u,2)
		x = (i-shape[1]/2)/shape[1]
		y = (j-shape[2]/2)/shape[2]
		u[i,j,1] = sin(ep[1]*(x^2 + y^2))
		u[i,j,2] = tanh(x - ep[2]*y)
	end
	return u
end

function needlesslycomplex(shape::NTuple{2,Int}, ::Type{T}) where {T<:Real}
	# input field (random could be stress-test)
	u = rand(T, shape...).-T(0.5)
	return u
end

function levelsetBenchmark(u::Array{T,2}) where {T<:Real}
	return @benchmark computeLevels($u)
end

function levelsetBenchmark(u::Array{T,D}) where {D,T<:Real}
	return @benchmark computeLevels($u)
end

for N in (128, 256, 512, 1024, 2048), T in (Float16, Float32, Float64)
	for u in (simple((N,N), T), needlesslycomplex((N,N),T))
		
		#bm = levelsetBenchmark(u);	
		#@test (bm.allocs/(N*N) <= 1)
		#@test (bm.memory <= 0) broken = true
		#@test (maximum(bm.times)/(N*N) <= 100)
	end
end

end
