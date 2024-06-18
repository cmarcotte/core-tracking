using BenchmarkTools, Test

const testNames = ["cache", "read", "iterator", "contour", "bvh"]
const testFiles = ["$(test)Tests" for test in testNames]

for (name, file) in zip(testNames, testFiles)
	tbs = (3-length(name)÷3);
	print("Running $name tests...", "\t"^tbs)
	took_seconds = @elapsed include("$(file).jl")
	print("done. (Elapsed: $took_seconds seconds).\n")
end
