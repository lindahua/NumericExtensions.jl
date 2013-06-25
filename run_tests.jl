# run all tests

tests = ["functors", "views", "map", "vbroadcast", "reduce", "statistics", "wsum"]

for t in tests
	tf = joinpath("test", "test_$t.jl")
	println("Running $tf ...")
	include(tf)
end
