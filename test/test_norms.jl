# Testing of functions in norms.jl

using NumericExtensions
using Base.Test

x1 = randn(6)
y1 = randn(6)

x2 = randn(5, 6)
y2 = randn(5, 6)

x3 = randn(3, 4, 5)
y3 = randn(3, 4, 5)

# vnorm

@test_approx_eq vnorm(x1, 1, 1) sum(abs(x1), 1)
@test_approx_eq vnorm(x2, 1, 1) sum(abs(x2), 1)
@test_approx_eq vnorm(x2, 1, 2) sum(abs(x2), 2)
@test_approx_eq vnorm(x3, 1, 1) sum(abs(x3), 1)
@test_approx_eq vnorm(x3, 1, 2) sum(abs(x3), 2)
@test_approx_eq vnorm(x3, 1, 3) sum(abs(x3), 3)

@test_approx_eq vnorm(x1, 2, 1) sqrt(sum(abs2(x1), 1))
@test_approx_eq vnorm(x2, 2, 1) sqrt(sum(abs2(x2), 1))
@test_approx_eq vnorm(x2, 2, 2) sqrt(sum(abs2(x2), 2))
@test_approx_eq vnorm(x3, 2, 1) sqrt(sum(abs2(x3), 1))
@test_approx_eq vnorm(x3, 2, 2) sqrt(sum(abs2(x3), 2))
@test_approx_eq vnorm(x3, 2, 3) sqrt(sum(abs2(x3), 3))

@test_approx_eq vnorm(x1, Inf, 1) max(abs(x1), (), 1)
@test_approx_eq vnorm(x2, Inf, 1) max(abs(x2), (), 1)
@test_approx_eq vnorm(x2, Inf, 2) max(abs(x2), (), 2)
@test_approx_eq vnorm(x3, Inf, 1) max(abs(x3), (), 1)
@test_approx_eq vnorm(x3, Inf, 2) max(abs(x3), (), 2)
@test_approx_eq vnorm(x3, Inf, 3) max(abs(x3), (), 3)

@test_approx_eq vnorm(x1, 3, 1) sum(abs(x1).^3, 1).^(1/3)
@test_approx_eq vnorm(x2, 3, 1) sum(abs(x2).^3, 1).^(1/3)
@test_approx_eq vnorm(x2, 3, 2) sum(abs(x2).^3, 2).^(1/3)
@test_approx_eq vnorm(x3, 3, 1) sum(abs(x3).^3, 1).^(1/3)
@test_approx_eq vnorm(x3, 3, 2) sum(abs(x3).^3, 2).^(1/3)
@test_approx_eq vnorm(x3, 3, 3) sum(abs(x3).^3, 3).^(1/3)

# vnormdiff

@test_approx_eq vdiffnorm(x1, y1, 1, 1) sum(abs(x1 - y1), 1)
@test_approx_eq vdiffnorm(x2, y2, 1, 1) sum(abs(x2 - y2), 1)
@test_approx_eq vdiffnorm(x2, y2, 1, 2) sum(abs(x2 - y2), 2)
@test_approx_eq vdiffnorm(x3, y3, 1, 1) sum(abs(x3 - y3), 1)
@test_approx_eq vdiffnorm(x3, y3, 1, 2) sum(abs(x3 - y3), 2)
@test_approx_eq vdiffnorm(x3, y3, 1, 3) sum(abs(x3 - y3), 3)

@test_approx_eq vdiffnorm(x1, y1, 2, 1) sqrt(sum(abs2(x1 - y1), 1))
@test_approx_eq vdiffnorm(x2, y2, 2, 1) sqrt(sum(abs2(x2 - y2), 1))
@test_approx_eq vdiffnorm(x2, y2, 2, 2) sqrt(sum(abs2(x2 - y2), 2))
@test_approx_eq vdiffnorm(x3, y3, 2, 1) sqrt(sum(abs2(x3 - y3), 1))
@test_approx_eq vdiffnorm(x3, y3, 2, 2) sqrt(sum(abs2(x3 - y3), 2))
@test_approx_eq vdiffnorm(x3, y3, 2, 3) sqrt(sum(abs2(x3 - y3), 3))

@test_approx_eq vdiffnorm(x1, y1, Inf, 1) max(abs(x1 - y1), (), 1)
@test_approx_eq vdiffnorm(x2, y2, Inf, 1) max(abs(x2 - y2), (), 1)
@test_approx_eq vdiffnorm(x2, y2, Inf, 2) max(abs(x2 - y2), (), 2)
@test_approx_eq vdiffnorm(x3, y3, Inf, 1) max(abs(x3 - y3), (), 1)
@test_approx_eq vdiffnorm(x3, y3, Inf, 2) max(abs(x3 - y3), (), 2)
@test_approx_eq vdiffnorm(x3, y3, Inf, 3) max(abs(x3 - y3), (), 3)

@test_approx_eq vdiffnorm(x1, y1, 3, 1) sum(abs(x1 - y1).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x2, y2, 3, 1) sum(abs(x2 - y2).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x2, y2, 3, 2) sum(abs(x2 - y2).^3, 2).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 1) sum(abs(x3 - y3).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 2) sum(abs(x3 - y3).^3, 2).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 3) sum(abs(x3 - y3).^3, 3).^(1/3)

# normalization

@test_approx_eq normalize(x1, 1) x1 ./ vnorm(x1, 1)
@test_approx_eq normalize(x1, 2) x1 ./ vnorm(x1, 2)
@test_approx_eq normalize(x1, 3) x1 ./ vnorm(x1, 3)
@test_approx_eq normalize(x1, Inf) x1 ./ vnorm(x1, Inf)

x2c = copy(x2)
normalize!(x2c, 1)
@test_approx_eq x2c x2 ./ vnorm(x2, 1)

@test_approx_eq normalize(x1, 1, 1) x1 ./ vnorm(x1, 1, 1)
@test_approx_eq normalize(x2, 1, 1) x2 ./ vnorm(x2, 1, 1)
@test_approx_eq normalize(x2, 1, 2) x2 ./ vnorm(x2, 1, 2)
@test_approx_eq normalize(x3, 1, 1) x3 ./ vnorm(x3, 1, 1)
@test_approx_eq normalize(x3, 1, 2) x3 ./ vnorm(x3, 1, 2)
@test_approx_eq normalize(x3, 1, 3) x3 ./ vnorm(x3, 1, 3)

@test_approx_eq normalize(x1, 2, 1) x1 ./ vnorm(x1, 2, 1)
@test_approx_eq normalize(x2, 2, 1) x2 ./ vnorm(x2, 2, 1)
@test_approx_eq normalize(x2, 2, 2) x2 ./ vnorm(x2, 2, 2)
@test_approx_eq normalize(x3, 2, 1) x3 ./ vnorm(x3, 2, 1)
@test_approx_eq normalize(x3, 2, 2) x3 ./ vnorm(x3, 2, 2)
@test_approx_eq normalize(x3, 2, 3) x3 ./ vnorm(x3, 2, 3)

@test_approx_eq normalize(x1, 3, 1) x1 ./ vnorm(x1, 3, 1)
@test_approx_eq normalize(x2, 3, 1) x2 ./ vnorm(x2, 3, 1)
@test_approx_eq normalize(x2, 3, 2) x2 ./ vnorm(x2, 3, 2)
@test_approx_eq normalize(x3, 3, 1) x3 ./ vnorm(x3, 3, 1)
@test_approx_eq normalize(x3, 3, 2) x3 ./ vnorm(x3, 3, 2)
@test_approx_eq normalize(x3, 3, 3) x3 ./ vnorm(x3, 3, 3)

@test_approx_eq normalize(x1, Inf, 1) x1 ./ vnorm(x1, Inf, 1)
@test_approx_eq normalize(x2, Inf, 1) x2 ./ vnorm(x2, Inf, 1)
@test_approx_eq normalize(x2, Inf, 2) x2 ./ vnorm(x2, Inf, 2)
@test_approx_eq normalize(x3, Inf, 1) x3 ./ vnorm(x3, Inf, 1)
@test_approx_eq normalize(x3, Inf, 2) x3 ./ vnorm(x3, Inf, 2)
@test_approx_eq normalize(x3, Inf, 3) x3 ./ vnorm(x3, Inf, 3)

x2c = copy(x2)
normalize!(x2c, 2, 1)
@test_approx_eq x2c x2 ./ vnorm(x2, 2, 1)

x2c = copy(x2)
normalize!(x2c, 2, 2)
@test_approx_eq x2c x2 ./ vnorm(x2, 2, 2)


