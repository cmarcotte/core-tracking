module iteratorTests

include("../pairIterator.jl")
import Base: fill!
using .pairIterator, BenchmarkTools, Test, Random

function setup(N::Int64, ::Type{T}) where {T}
	A = Vector{T}(undef,N)
	fill!(A)
	return A
end

function fill!(A::Vector{T}) where {T<:Number}
	rand!(A, T)
	return nothing
end

function fill!(A::Vector{NTuple{D,T}}) where {D, T<:Number}
	@inbounds for n in eachindex(A)
		A[n] = ntuple(i->T(2)*rand(T)-one(T), Val(D))
	end
	return nothing
end

function buildIteratorTest(v)
	return PairIterator(v)
end

function loopPI(PI::PairIterator)
	for (a0, a1) in PI
		# do something?
	end
	return nothing
end

function iteratorBenchmark(N::Int64, T::Type)
	v = setup(N, T)
	return @benchmark loopPI(PairIterator($v))
end

for N in (1_000,10_000,100_000,1_000_000), T in (Float16, Float32, Float64)

	bm = iteratorBenchmark(N, T);	
	@test (bm.allocs <= 0)
	@test (bm.memory <= 0)
	@test (maximum(bm.times)/N <= 1)
	
	for D in (2, 3)
		bm = iteratorBenchmark(N, NTuple{D,T});	
		@test (bm.allocs <= 0)
		@test (bm.memory <= 0)
		@test (maximum(bm.times)/N <= (25D))
	end

end
end
