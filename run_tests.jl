# run all tests

tests = [ "shapes", 
		  "unsafe_views", 
		  "mathfuns",
		  "functors",
		  "extree" ]

		  # "map"
		  # "vbroadcast", 
		  # "reduce", 
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
