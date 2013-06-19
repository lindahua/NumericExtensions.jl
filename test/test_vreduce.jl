# Test reduction

using NumericFunctors
using Base.Test

### full reduction ###

x = randn(3, 4)
y = randn(3, 4)

@test_approx_eq vsum(x) sum(x)
@test vsum(x) == vreduce(Add(), x) 

@test max(x) == vmax(x) == vreduce(Max(), x) 
@test min(x) == vmin(x) == vreduce(Min(), x)
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


### partial reduction ###

x1 = randn(6)
y1 = randn(6)

x2 = randn(5, 6)
y2 = randn(5, 6)

x3 = randn(3, 4, 5)
y3 = randn(3, 4, 5)

x4 = randn(3, 4, 5, 2)
y4 = randn(3, 4, 5, 2)

# vsum

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

r = zeros(6); vsum!(r, x2, 1)
@test_approx_eq r vec(sum(x2, 1))

r = zeros(5); vsum!(r, x2, 2)
@test_approx_eq r vec(sum(x2, 2))

r = zeros(4, 5); vsum!(r, x3, 1)
@test_approx_eq r reshape(sum(x3, 1), 4, 5)

r = zeros(3, 5); vsum!(r, x3, 2)
@test_approx_eq r reshape(sum(x3, 2), 3, 5)

r = zeros(3, 4); vsum!(r, x3, 3)
@test_approx_eq r reshape(sum(x3, 3), 3, 4)

@test size(vsum(x3, (1, 2))) == size(sum(x3, (1, 2)))
@test size(vsum(x3, (1, 3))) == size(sum(x3, (1, 3)))
@test size(vsum(x3, (2, 3))) == size(sum(x3, (2, 3)))

@test_approx_eq vsum(x3, (1, 2)) sum(x3, (1, 2))
@test_approx_eq vsum(x3, (1, 3)) sum(x3, (1, 3))
@test_approx_eq vsum(x3, (2, 3)) sum(x3, (2, 3))

r = zeros(5); vsum!(r, x3, (1, 2))
@test_approx_eq r vec(sum(x3, (1, 2)))

r = zeros(4); vsum!(r, x3, (1, 3))
@test_approx_eq r vec(sum(x3, (1, 3)))

r = zeros(3); vsum!(r, x3, (2, 3))
@test_approx_eq r vec(sum(x3, (2, 3)))

# vmax

@test_approx_eq vmax(x1, 1) max(x1, (), 1)
@test_approx_eq vmax(x1, 2) max(x1, (), 2)
@test_approx_eq vmax(x2, 1) max(x2, (), 1)
@test_approx_eq vmax(x2, 2) max(x2, (), 2)
@test_approx_eq vmax(x2, 3) max(x2, (), 3)
@test_approx_eq vmax(x3, 1) max(x3, (), 1)
@test_approx_eq vmax(x3, 2) max(x3, (), 2)
@test_approx_eq vmax(x3, 3) max(x3, (), 3)
@test_approx_eq vmax(x3, 4) max(x3, (), 4)
@test_approx_eq vmax(x4, 1) max(x4, (), 1)
@test_approx_eq vmax(x4, 2) max(x4, (), 2)
@test_approx_eq vmax(x4, 3) max(x4, (), 3)
@test_approx_eq vmax(x4, 4) max(x4, (), 4)
@test_approx_eq vmax(x4, 5) max(x4, (), 5)

@test_approx_eq vmax(x3, (1, 2)) max(x3, (), (1, 2))
@test_approx_eq vmax(x3, (1, 3)) max(x3, (), (1, 3))
@test_approx_eq vmax(x3, (2, 3)) max(x3, (), (2, 3))

# vmin

@test_approx_eq vmin(x1, 1) min(x1, (), 1)
@test_approx_eq vmin(x1, 2) min(x1, (), 2)
@test_approx_eq vmin(x2, 1) min(x2, (), 1)
@test_approx_eq vmin(x2, 2) min(x2, (), 2)
@test_approx_eq vmin(x2, 3) min(x2, (), 3)
@test_approx_eq vmin(x3, 1) min(x3, (), 1)
@test_approx_eq vmin(x3, 2) min(x3, (), 2)
@test_approx_eq vmin(x3, 3) min(x3, (), 3)
@test_approx_eq vmin(x3, 4) min(x3, (), 4)
@test_approx_eq vmin(x4, 1) min(x4, (), 1)
@test_approx_eq vmin(x4, 2) min(x4, (), 2)
@test_approx_eq vmin(x4, 3) min(x4, (), 3)
@test_approx_eq vmin(x4, 4) min(x4, (), 4)
@test_approx_eq vmin(x4, 5) min(x4, (), 5)

@test_approx_eq vmin(x3, (1, 2)) min(x3, (), (1, 2))
@test_approx_eq vmin(x3, (1, 3)) min(x3, (), (1, 3))
@test_approx_eq vmin(x3, (2, 3)) min(x3, (), (2, 3))

# vasum

@test_approx_eq vasum(x1, 1) sum(abs(x1), 1)
@test_approx_eq vasum(x1, 2) sum(abs(x1), 2)
@test_approx_eq vasum(x2, 1) sum(abs(x2), 1)
@test_approx_eq vasum(x2, 2) sum(abs(x2), 2)
@test_approx_eq vasum(x2, 3) sum(abs(x2), 3)
@test_approx_eq vasum(x3, 1) sum(abs(x3), 1)
@test_approx_eq vasum(x3, 2) sum(abs(x3), 2)
@test_approx_eq vasum(x3, 3) sum(abs(x3), 3)
@test_approx_eq vasum(x3, 4) sum(abs(x3), 4)
@test_approx_eq vasum(x4, 1) sum(abs(x4), 1)
@test_approx_eq vasum(x4, 2) sum(abs(x4), 2)
@test_approx_eq vasum(x4, 3) sum(abs(x4), 3)
@test_approx_eq vasum(x4, 4) sum(abs(x4), 4)
@test_approx_eq vasum(x4, 5) sum(abs(x4), 5)

@test_approx_eq vasum(x3, (1, 2)) sum(abs(x3), (1, 2))
@test_approx_eq vasum(x3, (1, 3)) sum(abs(x3), (1, 3))
@test_approx_eq vasum(x3, (2, 3)) sum(abs(x3), (2, 3))

r = zeros(6); vasum!(r, x2, 1)
@test_approx_eq r vec(sum(abs(x2), 1))

# vamax

@test_approx_eq vamax(x1, 1) max(abs(x1), (), 1)
@test_approx_eq vamax(x1, 2) max(abs(x1), (), 2)
@test_approx_eq vamax(x2, 1) max(abs(x2), (), 1)
@test_approx_eq vamax(x2, 2) max(abs(x2), (), 2)
@test_approx_eq vamax(x2, 3) max(abs(x2), (), 3)
@test_approx_eq vamax(x3, 1) max(abs(x3), (), 1)
@test_approx_eq vamax(x3, 2) max(abs(x3), (), 2)
@test_approx_eq vamax(x3, 3) max(abs(x3), (), 3)
@test_approx_eq vamax(x3, 4) max(abs(x3), (), 4)
@test_approx_eq vamax(x4, 1) max(abs(x4), (), 1)
@test_approx_eq vamax(x4, 2) max(abs(x4), (), 2)
@test_approx_eq vamax(x4, 3) max(abs(x4), (), 3)
@test_approx_eq vamax(x4, 4) max(abs(x4), (), 4)
@test_approx_eq vamax(x4, 5) max(abs(x4), (), 5)

@test_approx_eq vamax(x3, (1, 2)) max(abs(x3), (), (1, 2))
@test_approx_eq vamax(x3, (1, 3)) max(abs(x3), (), (1, 3))
@test_approx_eq vamax(x3, (2, 3)) max(abs(x3), (), (2, 3))

r = zeros(6); vamax!(r, x2, 1)
@test_approx_eq r vec(max(abs(x2), (), 1))

# vamin

@test_approx_eq vamin(x1, 1) min(abs(x1), (), 1)
@test_approx_eq vamin(x1, 2) min(abs(x1), (), 2)
@test_approx_eq vamin(x2, 1) min(abs(x2), (), 1)
@test_approx_eq vamin(x2, 2) min(abs(x2), (), 2)
@test_approx_eq vamin(x2, 3) min(abs(x2), (), 3)
@test_approx_eq vamin(x3, 1) min(abs(x3), (), 1)
@test_approx_eq vamin(x3, 2) min(abs(x3), (), 2)
@test_approx_eq vamin(x3, 3) min(abs(x3), (), 3)
@test_approx_eq vamin(x3, 4) min(abs(x3), (), 4)
@test_approx_eq vamin(x4, 1) min(abs(x4), (), 1)
@test_approx_eq vamin(x4, 2) min(abs(x4), (), 2)
@test_approx_eq vamin(x4, 3) min(abs(x4), (), 3)
@test_approx_eq vamin(x4, 4) min(abs(x4), (), 4)
@test_approx_eq vamin(x4, 5) min(abs(x4), (), 5)

@test_approx_eq vamin(x3, (1, 2)) min(abs(x3), (), (1, 2))
@test_approx_eq vamin(x3, (1, 3)) min(abs(x3), (), (1, 3))
@test_approx_eq vamin(x3, (2, 3)) min(abs(x3), (), (2, 3))

r = zeros(6); vamin!(r, x2, 1)
@test_approx_eq r vec(min(abs(x2), (), 1))

# vsqsum

@test_approx_eq vsqsum(x1, 1) sum(abs2(x1), 1)
@test_approx_eq vsqsum(x1, 2) sum(abs2(x1), 2)
@test_approx_eq vsqsum(x2, 1) sum(abs2(x2), 1)
@test_approx_eq vsqsum(x2, 2) sum(abs2(x2), 2)
@test_approx_eq vsqsum(x2, 3) sum(abs2(x2), 3)
@test_approx_eq vsqsum(x3, 1) sum(abs2(x3), 1)
@test_approx_eq vsqsum(x3, 2) sum(abs2(x3), 2)
@test_approx_eq vsqsum(x3, 3) sum(abs2(x3), 3)
@test_approx_eq vsqsum(x3, 4) sum(abs2(x3), 4)
@test_approx_eq vsqsum(x4, 1) sum(abs2(x4), 1)
@test_approx_eq vsqsum(x4, 2) sum(abs2(x4), 2)
@test_approx_eq vsqsum(x4, 3) sum(abs2(x4), 3)
@test_approx_eq vsqsum(x4, 4) sum(abs2(x4), 4)
@test_approx_eq vsqsum(x4, 5) sum(abs2(x4), 5)

@test_approx_eq vsqsum(x3, (1, 2)) sum(abs2(x3), (1, 2))
@test_approx_eq vsqsum(x3, (1, 3)) sum(abs2(x3), (1, 3))
@test_approx_eq vsqsum(x3, (2, 3)) sum(abs2(x3), (2, 3))

r = zeros(6); vsqsum!(r, x2, 1)
@test_approx_eq r vec(sum(abs2(x2), 1))

# vdot

@test_approx_eq vdot(x1, y1, 1) sum(x1 .* y1, 1)
@test_approx_eq vdot(x1, y1, 2) sum(x1 .* y1, 2)
@test_approx_eq vdot(x2, y2, 1) sum(x2 .* y2, 1)
@test_approx_eq vdot(x2, y2, 2) sum(x2 .* y2, 2)
@test_approx_eq vdot(x2, y2, 3) sum(x2 .* y2, 3)
@test_approx_eq vdot(x3, y3, 1) sum(x3 .* y3, 1)
@test_approx_eq vdot(x3, y3, 2) sum(x3 .* y3, 2)
@test_approx_eq vdot(x3, y3, 3) sum(x3 .* y3, 3)
@test_approx_eq vdot(x3, y3, 4) sum(x3 .* y3, 4)
@test_approx_eq vdot(x4, y4, 1) sum(x4 .* y4, 1)
@test_approx_eq vdot(x4, y4, 2) sum(x4 .* y4, 2)
@test_approx_eq vdot(x4, y4, 3) sum(x4 .* y4, 3)
@test_approx_eq vdot(x4, y4, 4) sum(x4 .* y4, 4)
@test_approx_eq vdot(x4, y4, 5) sum(x4 .* y4, 5)

@test_approx_eq vdot(x3, y3, (1, 2)) sum(x3 .* y3, (1, 2))
@test_approx_eq vdot(x3, y3, (1, 3)) sum(x3 .* y3, (1, 3))
@test_approx_eq vdot(x3, y3, (2, 3)) sum(x3 .* y3, (2, 3))

r = zeros(6); vdot!(r, x2, y2, 1)
@test_approx_eq r vec(sum(x2 .* y2, 1))

# vadiffsum

@test_approx_eq vadiffsum(x1, y1, 1) sum(abs(x1 - y1), 1)
@test_approx_eq vadiffsum(x1, y1, 2) sum(abs(x1 - y1), 2)
@test_approx_eq vadiffsum(x2, y2, 1) sum(abs(x2 - y2), 1)
@test_approx_eq vadiffsum(x2, y2, 2) sum(abs(x2 - y2), 2)
@test_approx_eq vadiffsum(x2, y2, 3) sum(abs(x2 - y2), 3)
@test_approx_eq vadiffsum(x3, y3, 1) sum(abs(x3 - y3), 1)
@test_approx_eq vadiffsum(x3, y3, 2) sum(abs(x3 - y3), 2)
@test_approx_eq vadiffsum(x3, y3, 3) sum(abs(x3 - y3), 3)
@test_approx_eq vadiffsum(x3, y3, 4) sum(abs(x3 - y3), 4)
@test_approx_eq vadiffsum(x4, y4, 1) sum(abs(x4 - y4), 1)
@test_approx_eq vadiffsum(x4, y4, 2) sum(abs(x4 - y4), 2)
@test_approx_eq vadiffsum(x4, y4, 3) sum(abs(x4 - y4), 3)
@test_approx_eq vadiffsum(x4, y4, 4) sum(abs(x4 - y4), 4)
@test_approx_eq vadiffsum(x4, y4, 5) sum(abs(x4 - y4), 5)

@test_approx_eq vadiffsum(x3, y3, (1, 2)) sum(abs(x3 - y3), (1, 2))
@test_approx_eq vadiffsum(x3, y3, (1, 3)) sum(abs(x3 - y3), (1, 3))
@test_approx_eq vadiffsum(x3, y3, (2, 3)) sum(abs(x3 - y3), (2, 3))

r = zeros(6); vadiffsum!(r, x2, y2, 1)
@test_approx_eq r vec(sum(abs(x2 - y2), 1))

# vdiffmax

@test_approx_eq vadiffmax(x1, y1, 1) max(abs(x1 - y1), (), 1)
@test_approx_eq vadiffmax(x1, y1, 2) max(abs(x1 - y1), (), 2)
@test_approx_eq vadiffmax(x2, y2, 1) max(abs(x2 - y2), (), 1)
@test_approx_eq vadiffmax(x2, y2, 2) max(abs(x2 - y2), (), 2)
@test_approx_eq vadiffmax(x2, y2, 3) max(abs(x2 - y2), (), 3)
@test_approx_eq vadiffmax(x3, y3, 1) max(abs(x3 - y3), (), 1)
@test_approx_eq vadiffmax(x3, y3, 2) max(abs(x3 - y3), (), 2)
@test_approx_eq vadiffmax(x3, y3, 3) max(abs(x3 - y3), (), 3)
@test_approx_eq vadiffmax(x3, y3, 4) max(abs(x3 - y3), (), 4)
@test_approx_eq vadiffmax(x4, y4, 1) max(abs(x4 - y4), (), 1)
@test_approx_eq vadiffmax(x4, y4, 2) max(abs(x4 - y4), (), 2)
@test_approx_eq vadiffmax(x4, y4, 3) max(abs(x4 - y4), (), 3)
@test_approx_eq vadiffmax(x4, y4, 4) max(abs(x4 - y4), (), 4)
@test_approx_eq vadiffmax(x4, y4, 5) max(abs(x4 - y4), (), 5)

@test_approx_eq vadiffmax(x3, y3, (1, 2)) max(abs(x3 - y3), (), (1, 2))
@test_approx_eq vadiffmax(x3, y3, (1, 3)) max(abs(x3 - y3), (), (1, 3))
@test_approx_eq vadiffmax(x3, y3, (2, 3)) max(abs(x3 - y3), (), (2, 3))

r = zeros(6); vadiffmax!(r, x2, y2, 1)
@test_approx_eq r vec(max(abs(x2 - y2), (), 1))

# vdiffmin

@test_approx_eq vadiffmin(x1, y1, 1) min(abs(x1 - y1), (), 1)
@test_approx_eq vadiffmin(x1, y1, 2) min(abs(x1 - y1), (), 2)
@test_approx_eq vadiffmin(x2, y2, 1) min(abs(x2 - y2), (), 1)
@test_approx_eq vadiffmin(x2, y2, 2) min(abs(x2 - y2), (), 2)
@test_approx_eq vadiffmin(x2, y2, 3) min(abs(x2 - y2), (), 3)
@test_approx_eq vadiffmin(x3, y3, 1) min(abs(x3 - y3), (), 1)
@test_approx_eq vadiffmin(x3, y3, 2) min(abs(x3 - y3), (), 2)
@test_approx_eq vadiffmin(x3, y3, 3) min(abs(x3 - y3), (), 3)
@test_approx_eq vadiffmin(x3, y3, 4) min(abs(x3 - y3), (), 4)
@test_approx_eq vadiffmin(x4, y4, 1) min(abs(x4 - y4), (), 1)
@test_approx_eq vadiffmin(x4, y4, 2) min(abs(x4 - y4), (), 2)
@test_approx_eq vadiffmin(x4, y4, 3) min(abs(x4 - y4), (), 3)
@test_approx_eq vadiffmin(x4, y4, 4) min(abs(x4 - y4), (), 4)
@test_approx_eq vadiffmin(x4, y4, 5) min(abs(x4 - y4), (), 5)

@test_approx_eq vadiffmin(x3, y3, (1, 2)) min(abs(x3 - y3), (), (1, 2))
@test_approx_eq vadiffmin(x3, y3, (1, 3)) min(abs(x3 - y3), (), (1, 3))
@test_approx_eq vadiffmin(x3, y3, (2, 3)) min(abs(x3 - y3), (), (2, 3))

r = zeros(6); vadiffmin!(r, x2, y2, 1)
@test_approx_eq r vec(min(abs(x2 - y2), (), 1))

# vsqdiffsum

@test_approx_eq vsqdiffsum(x1, y1, 1) sum(abs2(x1 - y1), 1)
@test_approx_eq vsqdiffsum(x1, y1, 2) sum(abs2(x1 - y1), 2)
@test_approx_eq vsqdiffsum(x2, y2, 1) sum(abs2(x2 - y2), 1)
@test_approx_eq vsqdiffsum(x2, y2, 2) sum(abs2(x2 - y2), 2)
@test_approx_eq vsqdiffsum(x2, y2, 3) sum(abs2(x2 - y2), 3)
@test_approx_eq vsqdiffsum(x3, y3, 1) sum(abs2(x3 - y3), 1)
@test_approx_eq vsqdiffsum(x3, y3, 2) sum(abs2(x3 - y3), 2)
@test_approx_eq vsqdiffsum(x3, y3, 3) sum(abs2(x3 - y3), 3)
@test_approx_eq vsqdiffsum(x3, y3, 4) sum(abs2(x3 - y3), 4)
@test_approx_eq vsqdiffsum(x4, y4, 1) sum(abs2(x4 - y4), 1)
@test_approx_eq vsqdiffsum(x4, y4, 2) sum(abs2(x4 - y4), 2)
@test_approx_eq vsqdiffsum(x4, y4, 3) sum(abs2(x4 - y4), 3)
@test_approx_eq vsqdiffsum(x4, y4, 4) sum(abs2(x4 - y4), 4)
@test_approx_eq vsqdiffsum(x4, y4, 5) sum(abs2(x4 - y4), 5)

@test_approx_eq vsqdiffsum(x3, y3, (1, 2)) sum(abs2(x3 - y3), (1, 2))
@test_approx_eq vsqdiffsum(x3, y3, (1, 3)) sum(abs2(x3 - y3), (1, 3))
@test_approx_eq vsqdiffsum(x3, y3, (2, 3)) sum(abs2(x3 - y3), (2, 3))

r = zeros(6); vsqdiffsum!(r, x2, y2, 1)
@test_approx_eq r vec(sum(abs2(x2 - y2), 1))

# vnorm

@test_approx_eq vnorm(x1, 1, 1) sum(abs(x1), 1)
@test_approx_eq vnorm(x1, 1, 2) sum(abs(x1), 2)
@test_approx_eq vnorm(x2, 1, 1) sum(abs(x2), 1)
@test_approx_eq vnorm(x2, 1, 2) sum(abs(x2), 2)
@test_approx_eq vnorm(x2, 1, 3) sum(abs(x2), 3)
@test_approx_eq vnorm(x3, 1, 1) sum(abs(x3), 1)
@test_approx_eq vnorm(x3, 1, 2) sum(abs(x3), 2)
@test_approx_eq vnorm(x3, 1, 3) sum(abs(x3), 3)
@test_approx_eq vnorm(x3, 1, 4) sum(abs(x3), 4)
@test_approx_eq vnorm(x4, 1, 1) sum(abs(x4), 1)
@test_approx_eq vnorm(x4, 1, 2) sum(abs(x4), 2)
@test_approx_eq vnorm(x4, 1, 3) sum(abs(x4), 3)
@test_approx_eq vnorm(x4, 1, 4) sum(abs(x4), 4)
@test_approx_eq vnorm(x4, 1, 5) sum(abs(x4), 5)

@test_approx_eq vnorm(x3, 1, (1, 2)) sum(abs(x3), (1, 2))
@test_approx_eq vnorm(x3, 1, (1, 3)) sum(abs(x3), (1, 3))
@test_approx_eq vnorm(x3, 1, (2, 3)) sum(abs(x3), (2, 3))

@test_approx_eq vnorm(x1, 2, 1) sqrt(sum(abs2(x1), 1))
@test_approx_eq vnorm(x1, 2, 2) sqrt(sum(abs2(x1), 2))
@test_approx_eq vnorm(x2, 2, 1) sqrt(sum(abs2(x2), 1))
@test_approx_eq vnorm(x2, 2, 2) sqrt(sum(abs2(x2), 2))
@test_approx_eq vnorm(x2, 2, 3) sqrt(sum(abs2(x2), 3))
@test_approx_eq vnorm(x3, 2, 1) sqrt(sum(abs2(x3), 1))
@test_approx_eq vnorm(x3, 2, 2) sqrt(sum(abs2(x3), 2))
@test_approx_eq vnorm(x3, 2, 3) sqrt(sum(abs2(x3), 3))
@test_approx_eq vnorm(x3, 2, 4) sqrt(sum(abs2(x3), 4))
@test_approx_eq vnorm(x4, 2, 1) sqrt(sum(abs2(x4), 1))
@test_approx_eq vnorm(x4, 2, 2) sqrt(sum(abs2(x4), 2))
@test_approx_eq vnorm(x4, 2, 3) sqrt(sum(abs2(x4), 3))
@test_approx_eq vnorm(x4, 2, 4) sqrt(sum(abs2(x4), 4))
@test_approx_eq vnorm(x4, 2, 5) sqrt(sum(abs2(x4), 5))

@test_approx_eq vnorm(x3, 2, (1, 2)) sqrt(sum(abs2(x3), (1, 2)))
@test_approx_eq vnorm(x3, 2, (1, 3)) sqrt(sum(abs2(x3), (1, 3)))
@test_approx_eq vnorm(x3, 2, (2, 3)) sqrt(sum(abs2(x3), (2, 3)))

@test_approx_eq vnorm(x1, Inf, 1) max(abs(x1), (), 1)
@test_approx_eq vnorm(x1, Inf, 2) max(abs(x1), (), 2)
@test_approx_eq vnorm(x2, Inf, 1) max(abs(x2), (), 1)
@test_approx_eq vnorm(x2, Inf, 2) max(abs(x2), (), 2)
@test_approx_eq vnorm(x2, Inf, 3) max(abs(x2), (), 3)
@test_approx_eq vnorm(x3, Inf, 1) max(abs(x3), (), 1)
@test_approx_eq vnorm(x3, Inf, 2) max(abs(x3), (), 2)
@test_approx_eq vnorm(x3, Inf, 3) max(abs(x3), (), 3)
@test_approx_eq vnorm(x3, Inf, 4) max(abs(x3), (), 4)
@test_approx_eq vnorm(x4, Inf, 1) max(abs(x4), (), 1)
@test_approx_eq vnorm(x4, Inf, 2) max(abs(x4), (), 2)
@test_approx_eq vnorm(x4, Inf, 3) max(abs(x4), (), 3)
@test_approx_eq vnorm(x4, Inf, 4) max(abs(x4), (), 4)
@test_approx_eq vnorm(x4, Inf, 5) max(abs(x4), (), 5)

@test_approx_eq vnorm(x3, Inf, (1, 2)) max(abs(x3), (), (1, 2))
@test_approx_eq vnorm(x3, Inf, (1, 3)) max(abs(x3), (), (1, 3))
@test_approx_eq vnorm(x3, Inf, (2, 3)) max(abs(x3), (), (2, 3))

@test_approx_eq vnorm(x1, 3, 1) sum(abs(x1).^3, 1).^(1/3)
@test_approx_eq vnorm(x1, 3, 2) sum(abs(x1).^3, 2).^(1/3)
@test_approx_eq vnorm(x2, 3, 1) sum(abs(x2).^3, 1).^(1/3)
@test_approx_eq vnorm(x2, 3, 2) sum(abs(x2).^3, 2).^(1/3)
@test_approx_eq vnorm(x2, 3, 3) sum(abs(x2).^3, 3).^(1/3)
@test_approx_eq vnorm(x3, 3, 1) sum(abs(x3).^3, 1).^(1/3)
@test_approx_eq vnorm(x3, 3, 2) sum(abs(x3).^3, 2).^(1/3)
@test_approx_eq vnorm(x3, 3, 3) sum(abs(x3).^3, 3).^(1/3)
@test_approx_eq vnorm(x3, 3, 4) sum(abs(x3).^3, 4).^(1/3)
@test_approx_eq vnorm(x4, 3, 1) sum(abs(x4).^3, 1).^(1/3)
@test_approx_eq vnorm(x4, 3, 2) sum(abs(x4).^3, 2).^(1/3)
@test_approx_eq vnorm(x4, 3, 3) sum(abs(x4).^3, 3).^(1/3)
@test_approx_eq vnorm(x4, 3, 4) sum(abs(x4).^3, 4).^(1/3)
@test_approx_eq vnorm(x4, 3, 5) sum(abs(x4).^3, 5).^(1/3)

@test_approx_eq vnorm(x3, 3, (1, 2)) sum(abs(x3).^3, (1, 2)).^(1/3)
@test_approx_eq vnorm(x3, 3, (1, 3)) sum(abs(x3).^3, (1, 3)).^(1/3)
@test_approx_eq vnorm(x3, 3, (2, 3)) sum(abs(x3).^3, (2, 3)).^(1/3)


# vnormdiff

@test_approx_eq vdiffnorm(x1, y1, 1, 1) sum(abs(x1 - y1), 1)
@test_approx_eq vdiffnorm(x1, y1, 1, 2) sum(abs(x1 - y1), 2)
@test_approx_eq vdiffnorm(x2, y2, 1, 1) sum(abs(x2 - y2), 1)
@test_approx_eq vdiffnorm(x2, y2, 1, 2) sum(abs(x2 - y2), 2)
@test_approx_eq vdiffnorm(x2, y2, 1, 3) sum(abs(x2 - y2), 3)
@test_approx_eq vdiffnorm(x3, y3, 1, 1) sum(abs(x3 - y3), 1)
@test_approx_eq vdiffnorm(x3, y3, 1, 2) sum(abs(x3 - y3), 2)
@test_approx_eq vdiffnorm(x3, y3, 1, 3) sum(abs(x3 - y3), 3)
@test_approx_eq vdiffnorm(x3, y3, 1, 4) sum(abs(x3 - y3), 4)
@test_approx_eq vdiffnorm(x4, y4, 1, 1) sum(abs(x4 - y4), 1)
@test_approx_eq vdiffnorm(x4, y4, 1, 2) sum(abs(x4 - y4), 2)
@test_approx_eq vdiffnorm(x4, y4, 1, 3) sum(abs(x4 - y4), 3)
@test_approx_eq vdiffnorm(x4, y4, 1, 4) sum(abs(x4 - y4), 4)
@test_approx_eq vdiffnorm(x4, y4, 1, 5) sum(abs(x4 - y4), 5)

@test_approx_eq vdiffnorm(x3, y3, 1, (1, 2)) sum(abs(x3 - y3), (1, 2))
@test_approx_eq vdiffnorm(x3, y3, 1, (1, 3)) sum(abs(x3 - y3), (1, 3))
@test_approx_eq vdiffnorm(x3, y3, 1, (2, 3)) sum(abs(x3 - y3), (2, 3))

@test_approx_eq vdiffnorm(x1, y1, 2, 1) sqrt(sum(abs2(x1 - y1), 1))
@test_approx_eq vdiffnorm(x1, y1, 2, 2) sqrt(sum(abs2(x1 - y1), 2))
@test_approx_eq vdiffnorm(x2, y2, 2, 1) sqrt(sum(abs2(x2 - y2), 1))
@test_approx_eq vdiffnorm(x2, y2, 2, 2) sqrt(sum(abs2(x2 - y2), 2))
@test_approx_eq vdiffnorm(x2, y2, 2, 3) sqrt(sum(abs2(x2 - y2), 3))
@test_approx_eq vdiffnorm(x3, y3, 2, 1) sqrt(sum(abs2(x3 - y3), 1))
@test_approx_eq vdiffnorm(x3, y3, 2, 2) sqrt(sum(abs2(x3 - y3), 2))
@test_approx_eq vdiffnorm(x3, y3, 2, 3) sqrt(sum(abs2(x3 - y3), 3))
@test_approx_eq vdiffnorm(x3, y3, 2, 4) sqrt(sum(abs2(x3 - y3), 4))
@test_approx_eq vdiffnorm(x4, y4, 2, 1) sqrt(sum(abs2(x4 - y4), 1))
@test_approx_eq vdiffnorm(x4, y4, 2, 2) sqrt(sum(abs2(x4 - y4), 2))
@test_approx_eq vdiffnorm(x4, y4, 2, 3) sqrt(sum(abs2(x4 - y4), 3))
@test_approx_eq vdiffnorm(x4, y4, 2, 4) sqrt(sum(abs2(x4 - y4), 4))
@test_approx_eq vdiffnorm(x4, y4, 2, 5) sqrt(sum(abs2(x4 - y4), 5))

@test_approx_eq vdiffnorm(x3, y3, 2, (1, 2)) sqrt(sum(abs2(x3 - y3), (1, 2)))
@test_approx_eq vdiffnorm(x3, y3, 2, (1, 3)) sqrt(sum(abs2(x3 - y3), (1, 3)))
@test_approx_eq vdiffnorm(x3, y3, 2, (2, 3)) sqrt(sum(abs2(x3 - y3), (2, 3)))

@test_approx_eq vdiffnorm(x1, y1, Inf, 1) max(abs(x1 - y1), (), 1)
@test_approx_eq vdiffnorm(x1, y1, Inf, 2) max(abs(x1 - y1), (), 2)
@test_approx_eq vdiffnorm(x2, y2, Inf, 1) max(abs(x2 - y2), (), 1)
@test_approx_eq vdiffnorm(x2, y2, Inf, 2) max(abs(x2 - y2), (), 2)
@test_approx_eq vdiffnorm(x2, y2, Inf, 3) max(abs(x2 - y2), (), 3)
@test_approx_eq vdiffnorm(x3, y3, Inf, 1) max(abs(x3 - y3), (), 1)
@test_approx_eq vdiffnorm(x3, y3, Inf, 2) max(abs(x3 - y3), (), 2)
@test_approx_eq vdiffnorm(x3, y3, Inf, 3) max(abs(x3 - y3), (), 3)
@test_approx_eq vdiffnorm(x3, y3, Inf, 4) max(abs(x3 - y3), (), 4)
@test_approx_eq vdiffnorm(x4, y4, Inf, 1) max(abs(x4 - y4), (), 1)
@test_approx_eq vdiffnorm(x4, y4, Inf, 2) max(abs(x4 - y4), (), 2)
@test_approx_eq vdiffnorm(x4, y4, Inf, 3) max(abs(x4 - y4), (), 3)
@test_approx_eq vdiffnorm(x4, y4, Inf, 4) max(abs(x4 - y4), (), 4)
@test_approx_eq vdiffnorm(x4, y4, Inf, 5) max(abs(x4 - y4), (), 5)

@test_approx_eq vdiffnorm(x3, y3, Inf, (1, 2)) max(abs(x3 - y3), (), (1, 2))
@test_approx_eq vdiffnorm(x3, y3, Inf, (1, 3)) max(abs(x3 - y3), (), (1, 3))
@test_approx_eq vdiffnorm(x3, y3, Inf, (2, 3)) max(abs(x3 - y3), (), (2, 3))

@test_approx_eq vdiffnorm(x1, y1, 3, 1) sum(abs(x1 - y1).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x1, y1, 3, 2) sum(abs(x1 - y1).^3, 2).^(1/3)
@test_approx_eq vdiffnorm(x2, y2, 3, 1) sum(abs(x2 - y2).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x2, y2, 3, 2) sum(abs(x2 - y2).^3, 2).^(1/3)
@test_approx_eq vdiffnorm(x2, y2, 3, 3) sum(abs(x2 - y2).^3, 3).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 1) sum(abs(x3 - y3).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 2) sum(abs(x3 - y3).^3, 2).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 3) sum(abs(x3 - y3).^3, 3).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 4) sum(abs(x3 - y3).^3, 4).^(1/3)
@test_approx_eq vdiffnorm(x4, y4, 3, 1) sum(abs(x4 - y4).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x4, y4, 3, 2) sum(abs(x4 - y4).^3, 2).^(1/3)
@test_approx_eq vdiffnorm(x4, y4, 3, 3) sum(abs(x4 - y4).^3, 3).^(1/3)
@test_approx_eq vdiffnorm(x4, y4, 3, 4) sum(abs(x4 - y4).^3, 4).^(1/3)
@test_approx_eq vdiffnorm(x4, y4, 3, 5) sum(abs(x4 - y4).^3, 5).^(1/3)

@test_approx_eq vdiffnorm(x3, y3, 3, (1, 2)) sum(abs(x3 - y3).^3, (1, 2)).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, (1, 3)) sum(abs(x3 - y3).^3, (1, 3)).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, (2, 3)) sum(abs(x3 - y3).^3, (2, 3)).^(1/3)




