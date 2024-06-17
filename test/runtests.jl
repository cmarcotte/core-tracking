using BenchmarkTools, Test

print("Running cache tests...")
took_seconds = @elapsed include("cacheTests.jl")
println("done (took ", took_seconds, " seconds)")

print("Running read tests...")
took_seconds = @elapsed include("readTests.jl")
println("done (took ", took_seconds, " seconds)")

print("Running iterator tests...")
took_seconds = @elapsed include("iteratorTests.jl")
println("done (took ", took_seconds, " seconds)")
