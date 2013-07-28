# run all tests

tests = [ "functors", 
		  "views", 
		  "map", 
		  "vbroadcast", 
		  "reduce", 
		  "norms",
		  "statistics", 
		  "wsum", 
		  "pdmat"]

for t in tests
	tf = joinpath("test", "test_$t.jl")
	println("Running $tf ...")
	include(tf)
end
