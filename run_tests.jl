# run all tests

tests = [ "shapes", 
		  "unsafe_views", 
		  "diagop",
		  "mathfuns", 
		  "functors",
		  "map",
		  "reduce",
		  "mapreduce",
		  "reducedim",
		  "norms" ]

		  # "vbroadcast",  
		  # "statistics", 
		  # "wsum", 
		  # "utils",
		  # "pdmat"

for t in tests
	tf = joinpath("test", "$t.jl")
	println("Running $tf ...")
	include(tf)
end
