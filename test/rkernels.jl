# testing of reduction kernels

using NumericExtensions
import NumericExtensions: safe_sum, safe_max, safe_min
import NumericExtensions: saccum, paccum!
import NumericExtensions: Sum
using Base.Test

a = randn(100)
b = randn(100)
c = randn(100)

for n = 1:15
    @test_approx_eq saccum(Sum, n, a, 1) safe_sum(a[1:n])
    @test_approx_eq saccum(Sum, n, a, 3) safe_sum(a[3:n+2])
    @test_approx_eq saccum(Sum, n, a, 1, 2) safe_sum(a[1:2:2n-1])
    @test_approx_eq saccum(Sum, n, a, 3, 2) safe_sum(a[3:2:2n+1])

    @test_approx_eq saccum(Sum, n, Abs2Fun(), a, 1) safe_sum(abs2(a[1:n]))
    @test_approx_eq saccum(Sum, n, Abs2Fun(), a, 3) safe_sum(abs2(a[3:n+2]))
    @test_approx_eq saccum(Sum, n, Abs2Fun(), a, 1, 2) safe_sum(abs2(a[1:2:2n-1]))
    @test_approx_eq saccum(Sum, n, Abs2Fun(), a, 3, 2) safe_sum(abs2(a[3:2:2n+1]))

    @test_approx_eq saccum(Sum, n, Multiply(), a, 1, b, 1) safe_sum(.*(a[1:n], b[1:n]))
    @test_approx_eq saccum(Sum, n, Multiply(), a, 3, b, 4) safe_sum(.*(a[3:n+2], b[4:n+3]))
    @test_approx_eq saccum(Sum, n, Multiply(), a, 1, 2, b, 1, 3) safe_sum(.*(a[1:2:2n-1], b[1:3:3n-2]))
    @test_approx_eq saccum(Sum, n, Multiply(), a, 3, 2, b, 4, 3) safe_sum(.*(a[3:2:2n+1], b[4:3:3n+1]))

    @test_approx_eq saccum(Sum, n, FMA(), a, 1, b, 1, c, 1) safe_sum(fma(a[1:n], b[1:n], c[1:n]))
    @test_approx_eq saccum(Sum, n, FMA(), a, 3, b, 4, c, 5) safe_sum(fma(a[3:n+2], b[4:n+3], c[5:n+4]))
    @test_approx_eq saccum(Sum, n, FMA(), a, 1, 2, b, 1, 3, c, 1, 4) safe_sum(fma(a[1:2:2n-1], b[1:3:3n-2], c[1:4:4n-3]))
    @test_approx_eq saccum(Sum, n, FMA(), a, 3, 2, b, 4, 3, c, 5, 4) safe_sum(fma(a[3:2:2n+1], b[4:3:3n+1], c[5:4:4n+1]))
end

for n = 1:15
    r = copy(b[1:n])
    paccum!(Sum, n, r, 1, a, 1)
    @test_approx_eq r b[1:n] + a[1:n]

    r = copy(b[1:n+3])
    paccum!(Sum, n, r, 4, a, 3)
    @test r[1:3] == b[1:3]
    @test_approx_eq r[4:n+3] b[4:n+3] + a[3:n+2]  

    r = copy(b[1:4+3n])
    rc = copy(r)
    paccum!(Sum, n, r, 4, 3, a, 3, 2)
    u = falses(4+3n)
    u[4:3:3n+1] = true
    @test r[~u] == rc[~u]
    @test_approx_eq r[u] rc[u] + a[3:2:2n+1]
end



