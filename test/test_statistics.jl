# Test statistics related functions

using NumericFunctors
using Base.Test

# data

x = randn(3, 4)
y = randn(3, 4)
z = randn(3, 4)
p = rand(3, 4)
q = rand(3, 4)

x1 = randn(6)
y1 = randn(6)
p1 = rand(6)
q1 = rand(6)

x2 = randn(5, 6)
y2 = randn(5, 6)
p2 = rand(5, 6)
q2 = rand(5, 6)

x3 = randn(3, 4, 5)
y3 = randn(3, 4, 5)
z3 = randn(3, 4, 5)
p3 = rand(3, 4, 5)
q3 = rand(3, 4, 5)

# mean

safe_mean(x) = sum(x) / length(x)
safe_mean(x, d::Int) = sum(x, d) / size(x, d)
safe_mean(x, d::(Int, Int)) = sum(x, d) / (size(x, d[1]) * size(x, d[2]))

@test_approx_eq mean(x) safe_mean(x)
@test_approx_eq mean(x1, 1) safe_mean(x1, 1) 
@test_approx_eq mean(x2, 1) safe_mean(x2, 1)
@test_approx_eq mean(x2, 2) safe_mean(x2, 2)
@test_approx_eq mean(x3, 1) safe_mean(x3, 1)
@test_approx_eq mean(x3, 2) safe_mean(x3, 2)
@test_approx_eq mean(x3, 3) safe_mean(x3, 3)
@test_approx_eq mean(x3, (1, 2)) safe_mean(x3, (1, 2))
@test_approx_eq mean(x3, (1, 3)) safe_mean(x3, (1, 3))
@test_approx_eq mean(x3, (2, 3)) safe_mean(x3, (2, 3))

r = zeros(size(x2, 2)); mean!(r, x2, 1) 
@test_approx_eq r vec(mean(x2, 1))

# entropy

@test_approx_eq entropy(p) -sum(p .* log(p))
@test_approx_eq entropy(p1, 1) -sum(p1 .* log(p1), 1)
@test_approx_eq entropy(p2, 1) -sum(p2 .* log(p2), 1)
@test_approx_eq entropy(p2, 2) -sum(p2 .* log(p2), 2)
@test_approx_eq entropy(p3, 1) -sum(p3 .* log(p3), 1)
@test_approx_eq entropy(p3, 2) -sum(p3 .* log(p3), 2)
@test_approx_eq entropy(p3, 3) -sum(p3 .* log(p3), 3)
@test_approx_eq entropy(p3, (1, 2)) -sum(p3 .* log(p3), (1, 2))
@test_approx_eq entropy(p3, (1, 3)) -sum(p3 .* log(p3), (1, 3))
@test_approx_eq entropy(p3, (2, 3)) -sum(p3 .* log(p3), (2, 3))
