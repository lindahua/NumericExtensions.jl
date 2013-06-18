# Test reduction

using NumericFunctors
using Base.Test

x = randn(10)
y = randn(10)

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
