# run all tests

tests = [ "shapes", 
          "diagop",
          "mathfuns", 
          "functors",
          "map",
          "vbroadcast",
          "transforms",
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
