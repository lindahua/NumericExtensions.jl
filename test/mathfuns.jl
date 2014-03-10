# Unit testing for mathfuns.jl

using NumericExtensions
using Base.Test

@test sqr([1, 2, 3]) == [1, 4, 9]
@test_approx_eq rcp([1, 2, 3]) 1.0 ./ [1, 2, 3]
@test_approx_eq rsqrt([1, 2, 3]) 1.0 ./ sqrt([1, 2, 3])
@test_approx_eq rcbrt([1, 2, 3]) 1.0 ./ cbrt([1, 2, 3])

@test_approx_eq logsumexp(2.0, 3.0) log(exp(2.0) + exp(3.0))
@test_approx_eq logsumexp(3.0, 2.0) log(exp(2.0) + exp(3.0))
