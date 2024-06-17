module cacheTests

include("../segmentIntersections.jl")
using .segmentIntersections, BenchmarkTools, Test

function initPoints(D::Int64, ::Type{T}) where T<:Real
	p0 = ntuple(d->rand(T), Val(D))
	p1 = ntuple(d->rand(T), Val(D)) 
	q0 = ntuple(d->rand(T), Val(D)) 
	q1 = ntuple(d->rand(T), Val(D))
	return (p0, p1, q0, q1)
end

function buildCacheTest(D::Int64, ::Type{T}) where T<:Real
	(p0, p1, q0, q1) = initPoints(D, T)
	cache = createCache(p0, p1, q0, q1)
	return true
end

function fillCacheTest(D::Int64, ::Type{T}) where T<:Real
	(p0, p1, q0, q1) = initPoints(D, T)
	cache = createCache(p0, p1, q0, q1)
	fillCache!(cache, p0, p1, q0, q1)
	return true
end

function solveTest(D::Int64, ::Type{T}) where T<:Real
	(p0, p1, q0, q1) = initPoints(D, T)
	cache = createCache(p0, p1, q0, q1)
	fillCache!(cache, p0, p1, q0, q1)
	solveIntersection!(cache)
	return true
end

function checkTest(D::Int64, ::Type{T}) where T<:Real
	(p0, p1, q0, q1) = initPoints(D, T)
	cache = createCache(p0, p1, q0, q1)
	fillCache!(cache, p0, p1, q0, q1)
	solveIntersection!(cache)
	checkSolution!(cache.X)
	return true
end

for T in (Float16, Float32, Float64), D in (2,3)
	@test buildCacheTest(D,T)
	@test fillCacheTest(D,T)
	@test solveTest(D, T)
	@test checkTest(D, T)
end

function benchmarkCache(D::Int64, ::Type{T}) where T<:Real
	(p0, p1, q0, q1) = initPoints(D, T)
	return @benchmark createCache($p0, $p1, $q0, $q1)
end

@test (benchmarkCache(2, Float32).allocs <= 4)
@test (benchmarkCache(2, Float32).memory <= 192)
@test (minimum(benchmarkCache(2, Float32).times) <= 20)

@test (benchmarkCache(3, Float32).allocs <= 6)
@test (benchmarkCache(3, Float32).memory <= 480)
@test (minimum(benchmarkCache(3, Float32).times) <= 80)

end
