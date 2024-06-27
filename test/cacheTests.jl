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

function initPara(D::Int64, ::Type{T}) where T<:Real
	p0 = ntuple(d->rand(T), Val(D))
	p1 = ntuple(d->rand(T), Val(D))
	dp = randn(T)
	q0 = p0 .+ dp
	q1 = p1 .+ dp
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

for T in (Float16, Float32, Float64), D in (2, 3)
	@test buildCacheTest(D,T)
	@test fillCacheTest(D,T)
	@test solveTest(D, T)
	@test checkTest(D, T)
end

function benchmarkCache(D::Int64, ::Type{T}) where T<:Real
	(p0, p1, q0, q1) = initPoints(D, T)
	return @benchmarkable createCache($p0, $p1, $q0, $q1)
end

let T = Float32
	bc = benchmarkCache(2, Float32)
	bcr = run(bc);

	@test (bcr.allocs <= 4)
	@test (bcr.memory <= 192)
	@test (minimum(bcr.times) <= 20)

	bc = benchmarkCache(3, Float32)
	bcr = run(bc);
	
	@test (bcr.allocs <= 6)
	@test (bcr.memory <= 480)
	@test (minimum(bcr.times) <= 80)
end

function saveBench(bench, filename)
	#BenchmarkTools.save("$(filename).json", bench)
	open("$(filename).dat", "w") do io
		show(io, MIME("text/plain"), bench) 
	end
	return nothing
end

const savedir="./test/bench"

for T in (Float16, Float32, Float64), D in (2, 3)
	let (p0, p1, q0, q1) = initPoints(D, T)
		mkpath(savedir);
		cache = createCache(p0, p1, q0, q1)
		fbm = @benchmarkable fillCache!($cache, $p0, $p1, $q0, $q1)
		tune!(fbm);
		rfbm = run(fbm)
		saveBench(rfbm, "$(savedir)/rfbm_$(T)_$(D)")
		sbm = @benchmarkable solveIntersection!($cache) setup=(fillCache!($cache, $p0, $p1, $q0, $q1))
		tune!(sbm);
		rsbm = run(sbm)
		saveBench(rsbm, "$(savedir)/rsbm_$(T)_$(D)")
		cbm = @benchmarkable checkSolution!($cache.X) setup=(fillCache!($cache, $p0, $p1, $q0, $q1); solveIntersection!($cache);)
		tune!(cbm);
		rcbm = run(cbm)
		saveBench(rcbm, "$(savedir)/rcbm_$(T)_$(D)")
	end
end

end
