# run all tests

tests = [ "shapes", 
		  "unsafe_views", 
		  "mathfuns", 
		  "functors",
		  "map",
		  "reduce" ]

		  # "vbroadcast",  
		  # "norms",
		  # "statistics", 
		  # "wsum", 
		  # "utils",
		  # "pdmat"

for t in tests
	tf = joinpath("test", "$t.jl")
	println("Running $tf ...")
	include(tf)
end
