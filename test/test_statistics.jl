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
z1 = randn(6)
p1 = rand(6)
q1 = rand(6)

x2 = randn(5, 6)
y2 = randn(5, 6)
z2 = randn(5, 6)
p2 = rand(5, 6)
q2 = rand(5, 6)

x3 = randn(3, 4, 5)
y3 = randn(3, 4, 5)
z3 = randn(3, 4, 5)
p3 = rand(3, 4, 5)
q3 = rand(3, 4, 5)

x4 = randn(3, 4, 5, 2)

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

@test_approx_eq mean(AbsFun(), x) safe_mean(abs(x))
@test_approx_eq meanabs(x) safe_mean(abs(x))
@test_approx_eq meanabs(x1, 1) safe_mean(abs(x1), 1) 
@test_approx_eq meanabs(x2, 1) safe_mean(abs(x2), 1)
@test_approx_eq meanabs(x2, 2) safe_mean(abs(x2), 2)
@test_approx_eq meanabs(x3, 1) safe_mean(abs(x3), 1)
@test_approx_eq meanabs(x3, 2) safe_mean(abs(x3), 2)
@test_approx_eq meanabs(x3, 3) safe_mean(abs(x3), 3)
@test_approx_eq meanabs(x3, (1, 2)) safe_mean(abs(x3), (1, 2))
@test_approx_eq meanabs(x3, (1, 3)) safe_mean(abs(x3), (1, 3))
@test_approx_eq meanabs(x3, (2, 3)) safe_mean(abs(x3), (2, 3))

r = zeros(size(x2, 2)); meanabs!(r, x2, 1) 
@test_approx_eq r vec(meanabs(x2, 1))

@test_approx_eq mean(Abs2Fun(), x) safe_mean(abs2(x))
@test_approx_eq meansq(x) safe_mean(abs2(x))
@test_approx_eq meansq(x1, 1) safe_mean(abs2(x1), 1) 
@test_approx_eq meansq(x2, 1) safe_mean(abs2(x2), 1)
@test_approx_eq meansq(x2, 2) safe_mean(abs2(x2), 2)
@test_approx_eq meansq(x3, 1) safe_mean(abs2(x3), 1)
@test_approx_eq meansq(x3, 2) safe_mean(abs2(x3), 2)
@test_approx_eq meansq(x3, 3) safe_mean(abs2(x3), 3)
@test_approx_eq meansq(x3, (1, 2)) safe_mean(abs2(x3), (1, 2))
@test_approx_eq meansq(x3, (1, 3)) safe_mean(abs2(x3), (1, 3))
@test_approx_eq meansq(x3, (2, 3)) safe_mean(abs2(x3), (2, 3))

r = zeros(size(x2, 2)); meansq!(r, x2, 1) 
@test_approx_eq r vec(meansq(x2, 1))

@test_approx_eq mean(Multiply(), x, y) safe_mean(x .* y)
@test_approx_eq mean(Multiply(), x1, y1, 1) safe_mean(x1 .* y1, 1)
@test_approx_eq mean(Multiply(), x2, y2, 1) safe_mean(x2 .* y2, 1)
@test_approx_eq mean(Multiply(), x2, y2, 2) safe_mean(x2 .* y2, 2)
@test_approx_eq mean(Multiply(), x3, y3, 1) safe_mean(x3 .* y3, 1)
@test_approx_eq mean(Multiply(), x3, y3, 2) safe_mean(x3 .* y3, 2)
@test_approx_eq mean(Multiply(), x3, y3, 3) safe_mean(x3 .* y3, 3)
@test_approx_eq mean(Multiply(), x3, y3, (1, 2)) safe_mean(x3 .* y3, (1, 2))
@test_approx_eq mean(Multiply(), x3, y3, (1, 3)) safe_mean(x3 .* y3, (1, 3))
@test_approx_eq mean(Multiply(), x3, y3, (2, 3)) safe_mean(x3 .* y3, (2, 3))

r = zeros(size(x2, 2)); mean!(r, Multiply(), x2, y2, 1) 
@test_approx_eq r vec(mean(x2 .* y2, 1))

@test_approx_eq mean(FMA(), x, y, z) safe_mean(x + y .* z)
@test_approx_eq mean(FMA(), x1, y1, z1, 1) safe_mean(x1 + y1 .* z1, 1)
@test_approx_eq mean(FMA(), x2, y2, z2, 1) safe_mean(x2 + y2 .* z2, 1)
@test_approx_eq mean(FMA(), x2, y2, z2, 2) safe_mean(x2 + y2 .* z2, 2)
@test_approx_eq mean(FMA(), x3, y3, z3, 1) safe_mean(x3 + y3 .* z3, 1)
@test_approx_eq mean(FMA(), x3, y3, z3, 2) safe_mean(x3 + y3 .* z3, 2)
@test_approx_eq mean(FMA(), x3, y3, z3, 3) safe_mean(x3 + y3 .* z3, 3)
@test_approx_eq mean(FMA(), x3, y3, z3, (1, 2)) safe_mean(x3 + y3 .* z3, (1, 2))
@test_approx_eq mean(FMA(), x3, y3, z3, (1, 3)) safe_mean(x3 + y3 .* z3, (1, 3))
@test_approx_eq mean(FMA(), x3, y3, z3, (2, 3)) safe_mean(x3 + y3 .* z3, (2, 3))

r = zeros(size(x2, 2)); mean!(r, FMA(), x2, y2, z2, 1) 
@test_approx_eq r vec(mean(x2 + y2 .* z2, 1))

# meanfdiff

@test_approx_eq meanabsdiff(x, y) safe_mean(abs(x - y))
@test_approx_eq meanabsdiff(x1, y1, 1) safe_mean(abs(x1 - y1), 1)
@test_approx_eq meanabsdiff(x2, y2, 1) safe_mean(abs(x2 - y2), 1)
@test_approx_eq meanabsdiff(x2, y2, 2) safe_mean(abs(x2 - y2), 2)
@test_approx_eq meanabsdiff(x3, y3, 1) safe_mean(abs(x3 - y3), 1)
@test_approx_eq meanabsdiff(x3, y3, 2) safe_mean(abs(x3 - y3), 2)
@test_approx_eq meanabsdiff(x3, y3, 3) safe_mean(abs(x3 - y3), 3)
@test_approx_eq meanabsdiff(x3, y3, (1, 2)) safe_mean(abs(x3 - y3), (1, 2))
@test_approx_eq meanabsdiff(x3, y3, (1, 3)) safe_mean(abs(x3 - y3), (1, 3))
@test_approx_eq meanabsdiff(x3, y3, (2, 3)) safe_mean(abs(x3 - y3), (2, 3))

r = zeros(size(x2, 2)); meanabsdiff!(r, x2, y2, 1) 
@test_approx_eq r vec(meanabsdiff(x2, y2, 1))

@test_approx_eq meansqdiff(x, y) safe_mean(abs2(x - y))
@test_approx_eq meansqdiff(x1, y1, 1) safe_mean(abs2(x1 - y1), 1)
@test_approx_eq meansqdiff(x2, y2, 1) safe_mean(abs2(x2 - y2), 1)
@test_approx_eq meansqdiff(x2, y2, 2) safe_mean(abs2(x2 - y2), 2)
@test_approx_eq meansqdiff(x3, y3, 1) safe_mean(abs2(x3 - y3), 1)
@test_approx_eq meansqdiff(x3, y3, 2) safe_mean(abs2(x3 - y3), 2)
@test_approx_eq meansqdiff(x3, y3, 3) safe_mean(abs2(x3 - y3), 3)
@test_approx_eq meansqdiff(x3, y3, (1, 2)) safe_mean(abs2(x3 - y3), (1, 2))
@test_approx_eq meansqdiff(x3, y3, (1, 3)) safe_mean(abs2(x3 - y3), (1, 3))
@test_approx_eq meansqdiff(x3, y3, (2, 3)) safe_mean(abs2(x3 - y3), (2, 3))

r = zeros(size(x2, 2)); meansqdiff!(r, x2, y2, 1) 
@test_approx_eq r vec(meansqdiff(x2, y2, 1))


# varm

safe_varm(x, u) = sum(abs2(x - u)) / (length(x) - 1)
safe_varm(x, u, d::Int) = sum(abs2(x .- u), d) / (size(x, d) - 1)

@test_approx_eq varm(x, mean(y)) safe_varm(x, mean(y))
@test_approx_eq varm(x1, mean(y1,1), 1) safe_varm(x1, mean(y1,1), 1)
@test_approx_eq varm(x2, mean(y2,1), 1) safe_varm(x2, mean(y2,1), 1)
@test_approx_eq varm(x2, mean(y2,2), 2) safe_varm(x2, mean(y2,2), 2)
@test_approx_eq varm(x3, mean(y3,1), 1) safe_varm(x3, mean(y3,1), 1)
@test_approx_eq varm(x3, mean(y3,2), 2) safe_varm(x3, mean(y3,2), 2)
@test_approx_eq varm(x3, mean(y3,3), 3) safe_varm(x3, mean(y3,3), 3)

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

r = zeros(size(x2, 2)); var!(r, x2, 1) 
@test_approx_eq r vec(var(x2, 1))

@test_approx_eq var(x4, 1) safe_var(x4, 1)
@test_approx_eq var(x4, 2) safe_var(x4, 2)
@test_approx_eq var(x4, 3) safe_var(x4, 3)
@test_approx_eq var(x4, 4) safe_var(x4, 4)

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



