module readTests

include("../dataParser.jl")
using .dataParser, BenchmarkTools, Test, Random

const testDataDir = "/home/chris/Development/fenkar_program/out/"
const testShape = (512,512,1)
const testt = rand(1:1000)
const T = Float32

function filenameTest(shape, t)
	fname = filename(testDataDir, shape, t)
	return !isnothing(fname)
end

function filenameTest(shape)
	fname = filename(testDataDir, (testShape...,testt))
	return !isnothing(fname)
end

function readTest1(shape, t)
	x = zeros(T, shape)
	fname = filename(testDataDir, shape, t)
	readFile!(x, fname);
	return true
end

function readTest2(shape, t)
	x = zeros(T, shape)
	y = zeros(T, shape)
	fname = filename(testDataDir, shape, t)
	readFile!(x, y, fname);
	return true
end

function readTest3(shape, t)
	x = zeros(T, shape)
	y = zeros(T, shape)
	fname = filename(testDataDir, shape, t)
	readFile!(x, fname, dataParser.fastread);
	readFile!(y, fname, dataParser.slowread);
	return all(y.==x)
end

function read1Benchmark(shape, t)
	x = zeros(T, shape)
	fname = filename(testDataDir, shape, t)
	return @benchmark readFile!($x, $fname)
end

function read2Benchmark(shape, t)
	x = zeros(T, shape)
	y = zeros(T, shape)
	fname = filename(testDataDir, shape, t)
	return @benchmark readFile!($x, $y, $fname)
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
