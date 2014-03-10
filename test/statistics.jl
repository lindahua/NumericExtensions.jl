# Test statistics related functions

using NumericExtensions
using Base.Test

# data

x = randn(3, 4)
y = randn(3, 4)

x1 = randn(6)
y1 = randn(6)

x2 = randn(5, 6)
y2 = randn(5, 6)

x3 = randn(3, 4, 5)
y3 = randn(3, 4, 5)

x4 = randn(3, 4, 5, 3)
y4 = randn(3, 4, 5, 3)

# varm

safe_varm(x, u) = sum(abs2(x .- u)) / (length(x) - 1)
safe_varm(x, u, d::Int) = sum(abs2(x .- u), d) / (size(x, d) - 1)

@test_approx_eq varm(x, mean(y)) safe_varm(x, mean(y))
@test_approx_eq varm(x1, mean(y1,1), 1) safe_varm(x1, mean(y1,1), 1)

@test_approx_eq varm(x2, mean(y2,1), 1) safe_varm(x2, mean(y2,1), 1)
@test_approx_eq varm(x2, mean(y2,2), 2) safe_varm(x2, mean(y2,2), 2)

@test_approx_eq varm(x3, mean(y3,1), 1) safe_varm(x3, mean(y3,1), 1)
@test_approx_eq varm(x3, mean(y3,2), 2) safe_varm(x3, mean(y3,2), 2)
@test_approx_eq varm(x3, mean(y3,3), 3) safe_varm(x3, mean(y3,3), 3)

@test_approx_eq varm(x4, mean(y4,1), 1) safe_varm(x4, mean(y4,1), 1)
@test_approx_eq varm(x4, mean(y4,2), 2) safe_varm(x4, mean(y4,2), 2)
@test_approx_eq varm(x4, mean(y4,3), 3) safe_varm(x4, mean(y4,3), 3)
@test_approx_eq varm(x4, mean(y4,4), 4) safe_varm(x4, mean(y4,4), 4)

# stdm

safe_stdm(x, u) = sqrt(safe_varm(x, u))
safe_stdm(x, u, d::Int) = sqrt(safe_varm(x, u, d))

@test_approx_eq stdm(x, mean(y)) safe_stdm(x, mean(y))
@test_approx_eq stdm(x1, mean(y1,1), 1) safe_stdm(x1, mean(y1,1), 1)

@test_approx_eq stdm(x2, mean(y2,1), 1) safe_stdm(x2, mean(y2,1), 1)
@test_approx_eq stdm(x2, mean(y2,2), 2) safe_stdm(x2, mean(y2,2), 2)

@test_approx_eq stdm(x3, mean(y3,1), 1) safe_stdm(x3, mean(y3,1), 1)
@test_approx_eq stdm(x3, mean(y3,2), 2) safe_stdm(x3, mean(y3,2), 2)
@test_approx_eq stdm(x3, mean(y3,3), 3) safe_stdm(x3, mean(y3,3), 3)

@test_approx_eq stdm(x4, mean(y4,1), 1) safe_stdm(x4, mean(y4,1), 1)
@test_approx_eq stdm(x4, mean(y4,2), 2) safe_stdm(x4, mean(y4,2), 2)
@test_approx_eq stdm(x4, mean(y4,3), 3) safe_stdm(x4, mean(y4,3), 3)
@test_approx_eq stdm(x4, mean(y4,4), 4) safe_stdm(x4, mean(y4,4), 4)

# var

safe_var(x) = safe_varm(x, mean(x))
safe_var(x, d::Int) = safe_varm(x, mean(x, d), d)

@test_approx_eq var(x) safe_var(x)
@test_approx_eq var(x1, 1) safe_var(x1, 1)

@test_approx_eq var(x2, 1) safe_var(x2, 1)
@test_approx_eq var(x2, 2) safe_var(x2, 2)

@test_approx_eq var(x3, 1) safe_var(x3, 1)
@test_approx_eq var(x3, 2) safe_var(x3, 2)
@test_approx_eq var(x3, 3) safe_var(x3, 3)

@test_approx_eq var(x4, 1) safe_var(x4, 1)
@test_approx_eq var(x4, 2) safe_var(x4, 2)
@test_approx_eq var(x4, 3) safe_var(x4, 3)
@test_approx_eq var(x4, 4) safe_var(x4, 4)

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

@test_approx_eq std(x4, 1) safe_std(x4, 1)
@test_approx_eq std(x4, 2) safe_std(x4, 2)
@test_approx_eq std(x4, 3) safe_std(x4, 3)
@test_approx_eq std(x4, 4) safe_std(x4, 4)

r = zeros(size(x2, 2)); std!(r, x2, 1) 
@test_approx_eq r vec(std(x2, 1))


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

@test_approx_eq logsumexp(x .+ 1000.) logsumexp(x) .+ 1000.
@test_approx_eq logsumexp(x2 .+ 1000., 1) logsumexp(x2, 1) .+ 1000.
@test_approx_eq logsumexp(x2 .+ 1000., 2) logsumexp(x2, 2) .+ 1000.
@test_approx_eq logsumexp(x3 .+ 1000., 2) logsumexp(x3, 2) .+ 1000.

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

@test_approx_eq softmax(x .+ 1000.) softmax(x)
@test_approx_eq softmax(x2 .+ 1000., 1) softmax(x2, 1)
@test_approx_eq softmax(x2 .+ 1000., 2) softmax(x2, 2)
@test_approx_eq softmax(x3 .+ 1000., 2) softmax(x3, 2)



