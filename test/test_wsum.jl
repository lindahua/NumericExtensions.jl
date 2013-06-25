# Test weighted sum 

using NumericExtensions
using Base.Test

x = rand(6)
y = rand(6)
z = rand(6)
w = rand(6)

# full reduction

@test_approx_eq wsum(w, x) sum(w .* x)
@test_approx_eq wsum(w, Abs2(), x) sum(w .* abs2(x))
@test_approx_eq wsum(w, Multiply(), x, y) sum(w .* (x .* y))
@test_approx_eq wsum(w, FMA(), x, y, z) sum(w .* (x + y .* z))
@test_approx_eq wsum_fdiff(w, Abs2(), x, y) sum(w .* abs2(x - y))

