# run all tests

tests = [ "unsafe_views", 
		  "mathfuns",
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
