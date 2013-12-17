using NumericExtensions
using Base.Test

x = randn(3, 4)
y = randn(3, 4)
z = randn(3, 4)
p = rand(3, 4)
q = rand(3, 4)

@test sumsq([2]) == 4
@test sumsq([2:3]) == 13
@test sumsq([2:4]) == 29
@test sumsq([2:5]) == 54
@test sumsq([2:6]) == 90

@test_approx_eq sumabs(x) sum(abs(x))
# @test_approx_eq maxabs(x) safe_max(abs(x))
# @test_approx_eq minabs(x) safe_min(abs(x))
@test_approx_eq sumsq(x) sum(abs2(x))

# @test_approx_eq dot(x, y) safe_sum(x .* y)
# @test_approx_eq sumabsdiff(x, y) safe_sum(abs(x - y))
# @test_approx_eq maxabsdiff(x, y) safe_max(abs(x - y))
# @test_approx_eq minabsdiff(x, y) safe_min(abs(x - y))
# @test_approx_eq sumsqdiff(x, y) safe_sum(abs2(x - y))

# @test_approx_eq sumabsdiff(x, 1.5) safe_sum(abs(x - 1.5))
# @test_approx_eq maxabsdiff(x, 1.5) safe_max(abs(x - 1.5))
# @test_approx_eq minabsdiff(x, 1.5) safe_min(abs(x - 1.5))
# @test_approx_eq sumsqdiff(x, 1.5) safe_sum(abs2(x - 1.5))

# @test_approx_eq mapreduce(Abs2Fun(), Add(), x) safe_sum(abs2(x))
# @test_approx_eq mapreduce(Multiply(), Add(), x, y) safe_sum(x .* y)
# @test_approx_eq mapdiff_reduce(Abs2Fun(), Add(), 2.3, x) safe_sum(abs2(2.3 - x))

@test_approx_eq sumxlogx(p) sum(p .* log(p))
@test_approx_eq sumxlogy(p, q) sum(p .* log(q))

# @test_approx_eq vnorm(x, 1) safe_sum(abs(x))
# @test_approx_eq vnorm(x, 2) sqrt(safe_sum(abs2(x)))
# @test_approx_eq vnorm(x, 3) safe_sum(abs(x) .^ 3) .^ (1/3)
# @test_approx_eq vnorm(x, Inf) safe_max(abs(x))

# @test_approx_eq vnormdiff(x, y, 1) safe_sum(abs(x - y))
# @test_approx_eq vnormdiff(x, y, 2) sqrt(safe_sum(abs2(x - y)))
# @test_approx_eq vnormdiff(x, y, 3) safe_sum(abs(x - y) .^ 3) .^ (1/3)
# @test_approx_eq vnormdiff(x, y, Inf) safe_max(abs(x - y))

@test_approx_eq sum(FMA(), x, y, z) sum(x + y .* z)
@test_approx_eq sum(FMA(), x, y, 2.) sum(x + y .* 2)
@test_approx_eq sum(FMA(), x, 2., y) sum(x + 2 .* y)
@test_approx_eq sum(FMA(), 2., x, y) sum(2. + x .* y)
@test_approx_eq sum(FMA(), x, 2., 3.) sum(x + 6.)
@test_approx_eq sum(FMA(), 2., x, 3.) sum(2. + x * 3.)
@test_approx_eq sum(FMA(), 2., 3., x) sum(2. + 3. * x)

