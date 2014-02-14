# Test reduction

using NumericExtensions
using Base.Test

### safe (but slow) reduction functions for result verification

import NumericExtensions: safe_sum, safe_max, safe_min

function rsize(x::Array, dim::Int)
    if 1 <= dim <= ndims(x)
        siz = size(x)
        rsiz_v = [siz...]
        rsiz_v[dim] = 1
        tuple(rsiz_v...)
    else
        size(x)
    end
end


### full reduction ###

x = randn(3, 4)

# foldl & foldr

@test foldl(Subtract(), 10, [4, 7, 9]) === (10 - 4 - 7 - 9)
@test foldr(Subtract(), 10, [4, 7, 9]) === 4 - (7 - (9 - 10))

@test foldl(Subtract(), [4, 7, 9]) === (4 - 7 - 9)
@test foldr(Subtract(), [4, 7, 9]) === (4 - (7 - 9))

# sum

@test sum(Bool[]) === 0
@test sum([false]) === 0
@test sum([true]) === 1 
@test sum([true, false, true]) === 2

@test sum(Int[]) === 0
@test sum([5]) === 5
@test sum([2, 3]) === 5
@test sum([2, 3, 4]) === 9
@test sum([2, 3, 4, 5]) === 14
@test sum([2, 3, 4, 5, 6, 7]) === 27

@test_approx_eq sum(x) safe_sum(x)

# mean

@test isnan(mean(Int[]))
@test isnan(mean(Float64[]))
@test mean([1, 2]) == 1.5

@test_approx_eq mean(x) safe_sum(x) / length(x)

# maximum & minimum

@test_throws maximum(Int[])
@test_throws minimum(Int[])

@test maximum([4, 5, 2, 3]) === 5
@test minimum([4, 5, 2, 3]) === 2

@test maximum([NaN, 3.0, NaN, 2.0, NaN]) === 3.0
@test minimum([NaN, 3.0, NaN, 2.0, NaN]) === 2.0

@test maximum(x) == safe_max(x)
@test minimum(x) == safe_min(x)

