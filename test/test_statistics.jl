# Test statistics related functions

using NumericExtensions
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

# var

safe_var(x) = sum(abs2(x - mean(x))) / (length(x) - 1)
safe_var(x, d::Int) = sum(abs2(x .- mean(x, d)), d) / (size(x, d) - 1)

@test_approx_eq var(x) safe_var(x)
@test_approx_eq var(x1, 1) safe_var(x1, 1) 
@test_approx_eq var(x2, 1) safe_var(x2, 1)
@test_approx_eq var(x2, 2) safe_var(x2, 2)
@test_approx_eq var(x3, 1) safe_var(x3, 1)
@test_approx_eq var(x3, 2) safe_var(x3, 2)
@test_approx_eq var(x3, 3) safe_var(x3, 3)

r = zeros(size(x2, 2)); var!(r, x2, 1) 
@test_approx_eq r vec(var(x2, 1))

# std

safe_std(x) = sqrt(var(x))
safe_std(x, d) = sqrt(var(x, d))

@test_approx_eq std(x) safe_std(x)
@test_approx_eq std(x1, 1) safe_std(x1, 1) 
@test_approx_eq std(x2, 1) safe_std(x2, 1)
@test_approx_eq std(x2, 2) safe_std(x2, 2)
@test_approx_eq std(x3, 1) safe_std(x3, 1)
@test_approx_eq std(x3, 2) safe_std(x3, 2)
@test_approx_eq std(x3, 3) safe_std(x3, 3)

r = zeros(size(x2, 2)); std!(r, x2, 1) 
@test_approx_eq r vec(std(x2, 1))


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

r = zeros(size(x2, 2)); entropy!(r, x2, 1) 
@test_approx_eq r vec(entropy(x2, 1))

# logsumexp

safe_logsumexp(x) = log(sum(exp(x)))
safe_logsumexp(x, d::Int) = log(sum(exp(x), d))

@test_approx_eq logsumexp(x) safe_logsumexp(x)
@test_approx_eq logsumexp(x1, 1) safe_logsumexp(x1, 1) 
@test_approx_eq logsumexp(x2, 1) safe_logsumexp(x2, 1)
@test_approx_eq logsumexp(x2, 2) safe_logsumexp(x2, 2)
@test_approx_eq logsumexp(x3, 1) safe_logsumexp(x3, 1)
@test_approx_eq logsumexp(x3, 2) safe_logsumexp(x3, 2)
@test_approx_eq logsumexp(x3, 3) safe_logsumexp(x3, 3)

r = zeros(size(x2, 2)); logsumexp!(r, x2, 1) 
@test_approx_eq r vec(logsumexp(x2, 1))

@test_approx_eq logsumexp(x + 1000.) logsumexp(x) + 1000.
@test_approx_eq logsumexp(x2 + 1000., 1) logsumexp(x2, 1) + 1000.
@test_approx_eq logsumexp(x2 + 1000., 2) logsumexp(x2, 2) + 1000.
@test_approx_eq logsumexp(x3 + 1000., 2) logsumexp(x3, 2) + 1000.

# softmax

safe_softmax(x) = exp(x) / sum(exp(x))
safe_softmax(x, d::Int) = exp(x) ./ sum(exp(x), d)

@test_approx_eq softmax(x) safe_softmax(x)
@test_approx_eq softmax(x1, 1) safe_softmax(x1, 1) 
@test_approx_eq softmax(x2, 1) safe_softmax(x2, 1)
@test_approx_eq softmax(x2, 2) safe_softmax(x2, 2)
@test_approx_eq softmax(x3, 1) safe_softmax(x3, 1)
@test_approx_eq softmax(x3, 2) safe_softmax(x3, 2)
@test_approx_eq softmax(x3, 3) safe_softmax(x3, 3)

r = zeros(size(x2)); softmax!(r, x2, 1) 
@test_approx_eq r softmax(x2, 1)

@test_approx_eq softmax(x + 1000.) softmax(x)
@test_approx_eq softmax(x2 + 1000., 1) softmax(x2, 1)
@test_approx_eq softmax(x2 + 1000., 2) softmax(x2, 2)
@test_approx_eq softmax(x3 + 1000., 2) softmax(x3, 2)



