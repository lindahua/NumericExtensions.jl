# testing of reduction kernels

using NumericExtensions
import NumericExtensions: safe_sum, safe_max, safe_min
import NumericExtensions: saccum, saccum_fdiff, paccum!, paccum_fdiff!
import NumericExtensions: Sum
using Base.Test

a = randn(100)
b = randn(100)
c = randn(100)
r0 = randn(100)

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

    @test_approx_eq saccum_fdiff(Sum, n, Abs2Fun(), a, 1, b, 1) safe_sum(abs2(a[1:n] - b[1:n]))
    @test_approx_eq saccum_fdiff(Sum, n, Abs2Fun(), a, 3, b, 4) safe_sum(abs2(a[3:n+2] - b[4:n+3]))
    @test_approx_eq saccum_fdiff(Sum, n, Abs2Fun(), a, 1, 2, b, 1, 3) safe_sum(abs2(a[1:2:2n-1] - b[1:3:3n-2]))
    @test_approx_eq saccum_fdiff(Sum, n, Abs2Fun(), a, 3, 2, b, 4, 3) safe_sum(abs2(a[3:2:2n+1] - b[4:3:3n+1]))

    @test_approx_eq saccum(Sum, n, FMA(), a, 1, b, 1, c, 1) safe_sum(fma(a[1:n], b[1:n], c[1:n]))
    @test_approx_eq saccum(Sum, n, FMA(), a, 3, b, 4, c, 5) safe_sum(fma(a[3:n+2], b[4:n+3], c[5:n+4]))
    @test_approx_eq saccum(Sum, n, FMA(), a, 1, 2, b, 1, 3, c, 1, 4) safe_sum(fma(a[1:2:2n-1], b[1:3:3n-2], c[1:4:4n-3]))
    @test_approx_eq saccum(Sum, n, FMA(), a, 3, 2, b, 4, 3, c, 5, 4) safe_sum(fma(a[3:2:2n+1], b[4:3:3n+1], c[5:4:4n+1]))
end

for n = 1:15
    r = copy(r0[1:n])
    paccum!(Sum, n, r, 1, a, 1)
    @test_approx_eq r r0[1:n] + a[1:n]

    r = copy(r0[1:n])
    paccum!(Sum, n, r, 1, Abs2Fun(), a, 1)
    @test_approx_eq r r0[1:n] + abs2(a[1:n])

    r = copy(r0[1:n])
    paccum!(Sum, n, r, 1, Multiply(), a, 1, b, 1)
    @test_approx_eq r r0[1:n] + .*(a[1:n], b[1:n])

    r = copy(r0[1:n])
    paccum_fdiff!(Sum, n, r, 1, Abs2Fun(), a, 1, b, 1)
    @test_approx_eq r r0[1:n] + abs2(a[1:n] - b[1:n])

    r = copy(r0[1:n])
    paccum!(Sum, n, r, 1, FMA(), a, 1, b, 1, c, 1)
    @test_approx_eq r r0[1:n] + fma(a[1:n], b[1:n], c[1:n])

    r = copy(r0[1:n+10])
    paccum!(Sum, n, r, 11, a, 3)
    @test r[1:10] == r0[1:10]
    @test_approx_eq r[11:n+10] r0[11:n+10] + a[3:n+2]  

    r = copy(r0[1:n+10])
    paccum!(Sum, n, r, 11, Abs2Fun(), a, 3)
    @test r[1:10] == r0[1:10]
    @test_approx_eq r[11:n+10] r0[11:n+10] + abs2(a[3:n+2])

    r = copy(r0[1:n+10])
    paccum!(Sum, n, r, 11, Multiply(), a, 3, b, 4)
    @test r[1:10] == r0[1:10]
    @test_approx_eq r[11:n+10] r0[11:n+10] + .*(a[3:n+2], b[4:n+3])

    r = copy(r0[1:n+10])
    paccum_fdiff!(Sum, n, r, 11, Abs2Fun(), a, 3, b, 4)
    @test r[1:10] == r0[1:10]
    @test_approx_eq r[11:n+10] r0[11:n+10] + abs2(a[3:n+2] - b[4:n+3])

    r = copy(r0[1:n+10])
    paccum!(Sum, n, r, 11, FMA(), a, 3, b, 4, c, 5)
    @test r[1:10] == r0[1:10]
    @test_approx_eq r[11:n+10] r0[11:n+10] + fma(a[3:n+2], b[4:n+3], c[5:n+4])

    r = copy(r0[1:4+3n])
    rc = copy(r)
    paccum!(Sum, n, r, 4, 3, a, 3, 2)
    u = falses(4+3n)
    u[4:3:3n+1] = true
    @test r[~u] == rc[~u]
    @test_approx_eq r[u] rc[u] + a[3:2:2n+1]

    r = copy(r0[1:4+3n])
    rc = copy(r)
    paccum!(Sum, n, r, 4, 3, Abs2Fun(), a, 3, 2)
    u = falses(4+3n)
    u[4:3:3n+1] = true
    @test r[~u] == rc[~u]
    @test_approx_eq r[u] rc[u] + abs2(a[3:2:2n+1])

    r = copy(r0[1:4+3n])
    rc = copy(r)
    paccum!(Sum, n, r, 4, 3, Multiply(), a, 3, 2, b, 5, 4)
    u = falses(4+3n)
    u[4:3:3n+1] = true
    @test r[~u] == rc[~u]
    @test_approx_eq r[u] rc[u] + .*(a[3:2:2n+1], b[5:4:4n+1])

    r = copy(r0[1:4+3n])
    rc = copy(r)
    paccum_fdiff!(Sum, n, r, 4, 3, Abs2Fun(), a, 3, 2, b, 5, 4)
    u = falses(4+3n)
    u[4:3:3n+1] = true
    @test r[~u] == rc[~u]
    @test_approx_eq r[u] rc[u] + abs2(a[3:2:2n+1] - b[5:4:4n+1])

    r = copy(r0[1:4+3n])
    rc = copy(r)
    paccum!(Sum, n, r, 4, 3, FMA(), a, 3, 2, b, 5, 4, c, 6, 5)
    u = falses(4+3n)
    u[4:3:3n+1] = true
    @test r[~u] == rc[~u]
    @test_approx_eq r[u] rc[u] + fma(a[3:2:2n+1], b[5:4:4n+1], c[6:5:5n+1]) 
end



