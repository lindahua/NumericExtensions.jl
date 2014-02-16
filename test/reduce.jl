# Test reduction

using NumericExtensions
using Base.Test

import NumericExtensions: _Max, _Min, NonnegMax

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

# reduce

@test reduce(Add(), Int[]) == 0
@test reduce(Add(), [1, 2, 3]) == 6
@test reduce(_Max(), Int[]) == typemin(Int)
@test reduce(_Max(), [1, 2, 3]) == 3
@test reduce(_Min(), Int[]) == typemax(Int)
@test reduce(_Min(), [1, 2, 3]) == 1
@test reduce(NonnegMax(), Int[]) == 0
@test reduce(NonnegMax(), [1, 2, 3]) == 3

@test mapreduce(Abs2Fun(), Add(), Int[]) == 0
@test mapreduce(Abs2Fun(), Add(), [1, 2, 3]) == 14

@test mapreduce(Multiply(), Add(), Int[], Int[]) == 0
@test mapreduce(Multiply(), Add(), [1, 2, 3], [2, 3, 4]) == 20
@test mapreduce(Multiply(), Add(), [1, 2, 3], 2) == 12
@test mapreduce(Multiply(), Add(), 2, [1, 2, 3]) == 12

@test mapreduce(FMA(), Add(), [1, 2, 3], [4, 5, 6], [7, 8, 9]) == 128
@test mapreduce(FMA(), Add(), 4, [4, 5, 6], [7, 8, 9]) == 134
@test mapreduce(FMA(), Add(), [1, 2, 3], 2, [7, 8, 9]) == 54
@test mapreduce(FMA(), Add(), [1, 2, 3], [4, 5, 6], 2) == 36

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


# small sample testing (for coverage)

@test sumsq([2]) == 4
@test sumsq([2:3]) == 13
@test sumsq([2:4]) == 29
@test sumsq([2:5]) == 54
@test sumsq([2:6]) == 90

@test meansq([2]) == 4
@test meansq([2:3]) == 13 / 2
@test meansq([2:4]) == 29 / 3
@test meansq([2:5]) == 54 / 4
@test meansq([2:6]) == 90 / 5

@test maxabs([3, -5, 4, -2]) == 5
@test minabs([3, -5, 4, -2]) == 2

@test dot([1, 2, 3], [4, 5, 6]) === 32

# large random sample testing

x = randn(3, 4)
y = randn(3, 4)
z = randn(3, 4)
p = rand(3, 4)
q = rand(3, 4)

@test_approx_eq sumabs(x) sum(abs(x))
@test_approx_eq maxabs(x) maximum(abs(x))
@test_approx_eq minabs(x) minimum(abs(x))
@test_approx_eq meanabs(x) mean(abs(x))

@test_approx_eq sumsq(x) sum(abs2(x))
@test_approx_eq meansq(x) mean(abs2(x))

@test_approx_eq dot(x, y) sum(x .* y)

@test_approx_eq sumabsdiff(x, y)  sum(abs(x - y))
@test_approx_eq maxabsdiff(x, y)  maximum(abs(x - y))
@test_approx_eq minabsdiff(x, y)  minimum(abs(x - y))
@test_approx_eq meanabsdiff(x, y) mean(abs(x - y))

@test_approx_eq sumsqdiff(x, y)  sum(abs2(x - y))
@test_approx_eq meansqdiff(x, y) mean(abs2(x - y))

@test_approx_eq sumabsdiff(x, 1.5)  sum(abs(x - 1.5))
@test_approx_eq maxabsdiff(x, 1.5)  maximum(abs(x - 1.5))
@test_approx_eq minabsdiff(x, 1.5)  minimum(abs(x - 1.5))
@test_approx_eq meanabsdiff(x, 1.5) mean(abs(x - 1.5))

@test_approx_eq sumsqdiff(x, 1.5) sum(abs2(x - 1.5))
@test_approx_eq meansqdiff(x, 1.5) mean(abs2(x - 1.5))

@test_approx_eq sumabsdiff(1.5, x)  sum(abs(x - 1.5))
@test_approx_eq maxabsdiff(1.5, x)  maximum(abs(x - 1.5))
@test_approx_eq minabsdiff(1.5, x)  minimum(abs(x - 1.5)) 
@test_approx_eq meanabsdiff(1.5, x) mean(abs(x - 1.5))

@test_approx_eq sumsqdiff(1.5, x)  sum(abs2(x - 1.5))
@test_approx_eq meansqdiff(1.5, x) mean(abs2(x - 1.5))

@test_approx_eq sumxlogx(p) sum(p .* log(p))
@test_approx_eq sumxlogy(p, q) sum(p .* log(q))
@test_approx_eq entropy(p) -sum(p .* log(p))

# generic & ternary

@test_approx_eq sum(FMA(), x, y, z) sum(x + y .* z)
@test_approx_eq sum(FMA(), x, y, 2.) sum(x + y .* 2)
@test_approx_eq sum(FMA(), x, 2., y) sum(x + 2 .* y)
@test_approx_eq sum(FMA(), 2., x, y) sum(2. + x .* y)
@test_approx_eq sum(FMA(), x, 2., 3.) sum(x + 6.)
@test_approx_eq sum(FMA(), 2., x, 3.) sum(2. + x * 3.)
@test_approx_eq sum(FMA(), 2., 3., x) sum(2. + 3. * x)

@test_approx_eq mean(FMA(), x, y, z) mean(x + y .* z)
@test_approx_eq mean(FMA(), x, y, 2.) mean(x + y .* 2)
@test_approx_eq mean(FMA(), x, 2., y) mean(x + 2 .* y)
@test_approx_eq mean(FMA(), 2., x, y) mean(2. + x .* y)
@test_approx_eq mean(FMA(), x, 2., 3.) mean(x + 6.)
@test_approx_eq mean(FMA(), 2., x, 3.) mean(2. + x * 3.)
@test_approx_eq mean(FMA(), 2., 3., x) mean(2. + 3. * x)

@test_approx_eq maximum(FMA(), x, y, z) maximum(x + y .* z)
@test_approx_eq maximum(FMA(), x, y, 2.) maximum(x + y .* 2)
@test_approx_eq maximum(FMA(), x, 2., y) maximum(x + 2 .* y)
@test_approx_eq maximum(FMA(), 2., x, y) maximum(2. + x .* y)
@test_approx_eq maximum(FMA(), x, 2., 3.) maximum(x + 6.)
@test_approx_eq maximum(FMA(), 2., x, 3.) maximum(2. + x * 3.)
@test_approx_eq maximum(FMA(), 2., 3., x) maximum(2. + 3. * x)

@test_approx_eq minimum(FMA(), x, y, z) minimum(x + y .* z)
@test_approx_eq minimum(FMA(), x, y, 2.) minimum(x + y .* 2)
@test_approx_eq minimum(FMA(), x, 2., y) minimum(x + 2 .* y)
@test_approx_eq minimum(FMA(), 2., x, y) minimum(2. + x .* y)
@test_approx_eq minimum(FMA(), x, 2., 3.) minimum(x + 6.)
@test_approx_eq minimum(FMA(), 2., x, 3.) minimum(2. + x * 3.)
@test_approx_eq minimum(FMA(), 2., 3., x) minimum(2. + 3. * x)

# folding

@test_approx_eq foldl(Subtract(), 10, Abs2Fun(), [1:4]) (-20)
@test_approx_eq foldr(Subtract(), 10, Abs2Fun(), [1:4]) 0

@test_approx_eq foldl(Subtract(), 10, Multiply(), [1:4], [1:4]) (-20)
@test_approx_eq foldr(Subtract(), 10, Multiply(), [1:4], [1:4]) 0

@test_approx_eq foldl_fdiff(Subtract(), 10, Abs2Fun(), [1:4], zeros(Int,4)) (-20)
@test_approx_eq foldr_fdiff(Subtract(), 10, Abs2Fun(), [1:4], zeros(Int,4)) 0

@test_approx_eq foldl(Subtract(), Abs2Fun(), [1:4]) (-28)
@test_approx_eq foldr(Subtract(), Abs2Fun(), [1:4]) (-10)

@test_approx_eq foldl(Subtract(), Multiply(), [1:4], [1:4]) (-28)
@test_approx_eq foldr(Subtract(), Multiply(), [1:4], [1:4]) (-10)

@test_approx_eq foldl_fdiff(Subtract(), Abs2Fun(), [1:4], zeros(Int,4)) (-28)
@test_approx_eq foldr_fdiff(Subtract(), Abs2Fun(), [1:4], zeros(Int,4)) (-10)

