# run all tests

tests = [ "shapes", 
		  "unsafe_views", 
		  "diagop",
		  "mathfuns", 
		  "functors",
		  "map",
		  "vbroadcast",
		  "utils",
		  "reduce",
		  "mapreduce",
		  "reducedim",
		  "norms",
		  "scan" ]
 
		  # "statistics", 
		  # "wsum", 
		  # "pdmat"

for t in tests
	tf = joinpath("test", "$t.jl")
	println("Running $tf ...")
	include(tf)
end
