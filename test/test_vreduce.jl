# Test reduction

using NumericFunctors
using Base.Test

# full reduction

x = randn(3, 4)
y = randn(3, 4)

@test_approx_eq vsum(x) sum(x)
@test vsum(x) == vreduce(Add(), x) == vreduce(Add(), 0., x)

@test max(x) == vmax(x) == vreduce(Max(), x) == vreduce(Max(), -Inf, x)
@test min(x) == vmin(x) == vreduce(Min(), x) == vreduce(Min(), Inf, x)
@test nonneg_vmax(x) == max(max(x), 0.)

@test_approx_eq vasum(x) sum(abs(x))
@test_approx_eq vamax(x) max(abs(x))
@test_approx_eq vamin(x) min(abs(x))
@test_approx_eq vsqsum(x) sum(abs2(x))

@test_approx_eq vdot(x, y) sum(x .* y)
@test_approx_eq vadiffsum(x, y) sum(abs(x - y))
@test_approx_eq vadiffmax(x, y) max(abs(x - y))
@test_approx_eq vadiffmin(x, y) min(abs(x - y))
@test_approx_eq vsqdiffsum(x, y) sum(abs2(x - y))

@test_approx_eq vadiffsum(x, 1.5) sum(abs(x - 1.5))
@test_approx_eq vadiffmax(x, 1.5) max(abs(x - 1.5))
@test_approx_eq vadiffmin(x, 1.5) min(abs(x - 1.5))
@test_approx_eq vsqdiffsum(x, 1.5) sum(abs2(x - 1.5))

@test_approx_eq vreduce_fdiff(Add(), Abs2(), 2.3, x) sum(abs2(2.3 - x))

@test_approx_eq vnorm(x, 1) sum(abs(x))
@test_approx_eq vnorm(x, 2) sqrt(sum(abs2(x)))
@test_approx_eq vnorm(x, 3) sum(abs(x) .^ 3) .^ (1/3)
@test_approx_eq vnorm(x, Inf) max(abs(x))

@test_approx_eq vdiffnorm(x, y, 1) sum(abs(x - y))
@test_approx_eq vdiffnorm(x, y, 2) sqrt(sum(abs2(x - y)))
@test_approx_eq vdiffnorm(x, y, 3) sum(abs(x - y) .^ 3) .^ (1/3)
@test_approx_eq vdiffnorm(x, y, Inf) max(abs(x - y))

# partial reduction

x1 = randn(6)
y1 = randn(6)

x2 = randn(5, 6)
y2 = randn(5, 6)

x3 = randn(3, 4, 5)
y3 = randn(3, 4, 5)

x4 = randn(3, 4, 5, 2)
y4 = randn(3, 4, 5, 2)

@test size(vsum(x1, 1)) == size(sum(x1, 1))
@test size(vsum(x1, 2)) == size(sum(x1, 2))
@test size(vsum(x2, 1)) == size(sum(x2, 1))
@test size(vsum(x2, 2)) == size(sum(x2, 2))
@test size(vsum(x2, 3)) == size(sum(x2, 3))
@test size(vsum(x3, 1)) == size(sum(x3, 1))
@test size(vsum(x3, 2)) == size(sum(x3, 2))
@test size(vsum(x3, 3)) == size(sum(x3, 3))
@test size(vsum(x3, 4)) == size(sum(x3, 4))
@test size(vsum(x4, 1)) == size(sum(x4, 1))
@test size(vsum(x4, 2)) == size(sum(x4, 2))
@test size(vsum(x4, 3)) == size(sum(x4, 3))
@test size(vsum(x4, 4)) == size(sum(x4, 4))
@test size(vsum(x4, 5)) == size(sum(x4, 5))

@test_approx_eq vsum(x1, 1) sum(x1, 1)
@test_approx_eq vsum(x1, 2) sum(x1, 2)
@test_approx_eq vsum(x2, 1) sum(x2, 1)
@test_approx_eq vsum(x2, 2) sum(x2, 2)
@test_approx_eq vsum(x2, 3) sum(x2, 3)
@test_approx_eq vsum(x3, 1) sum(x3, 1)
@test_approx_eq vsum(x3, 2) sum(x3, 2)
@test_approx_eq vsum(x3, 3) sum(x3, 3)
@test_approx_eq vsum(x3, 4) sum(x3, 4)
@test_approx_eq vsum(x4, 1) sum(x4, 1)
@test_approx_eq vsum(x4, 2) sum(x4, 2)
@test_approx_eq vsum(x4, 3) sum(x4, 3)
@test_approx_eq vsum(x4, 4) sum(x4, 4)
@test_approx_eq vsum(x4, 5) sum(x4, 5)




