# Benchmark on reduction

const oldperf = Array(Vector{Float64})

# data preparation

a2 = randn(1000, 1000)
b2 = rand(1000, 1000) + 0.5

a3 = randn(1000, 1000)
b3 = rand(1000, 1000) + 0.5


#################################################
#
#  Benchmark on old functions
#
#################################################

sum(a2, 2)
@time for i in 1 : 10 sum(a2, 2) end


#################################################
#
#  Benchmark on new functions
#
#################################################

using NumericFunctors

sum(a2, 2)
@time for i in 1 : 10 sum(a2, 2) end


