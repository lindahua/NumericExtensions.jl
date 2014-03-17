# run all tests

tests = [ "shapes", 
          "diagop",
          "map",
          "vbroadcast",
          "utils",
          "rkernels",
          "reduce",
          "folddim",
          "reducedim",
          "norms",
          "scan",
          "statistics",
          "wsum"]

srand(6789)

for t in tests
    tf = joinpath("test", "$t.jl")
    println("Running $tf ...")
    include(tf)
end
