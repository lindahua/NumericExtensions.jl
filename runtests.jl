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
          "reducedim"
          #"norms",
          #"scan",
          #"statistics",
          #"wsum",
          #"pdmat" 
          ]

for t in tests
    tf = joinpath("test", "$t.jl")
    println("Running $tf ...")
    include(tf)
end
