# testing of reduction kernels

using NumericExtensions
import NumericExtensions: safe_sum, safe_max, safe_min
import NumericExtensions: saccum, saccum_fdiff, paccum!, paccum_fdiff!
import NumericExtensions: Sum, Maximum, Minimum
using Base.Test

a = randn(100)
b = randn(100)
c = randn(100)
v = 2.5
r0 = randn(100)

for (Op, safef) in [(Sum, safe_sum), (Maximum, safe_max), (Minimum, safe_min)]
    for n = 1:15
        @test_approx_eq saccum(Op, n, a, 1) safef(a[1:n])
        @test_approx_eq saccum(Op, n, a, 3) safef(a[3:n+2])
        @test_approx_eq saccum(Op, n, a, 1, 2) safef(a[1:2:2n-1])
        @test_approx_eq saccum(Op, n, a, 3, 2) safef(a[3:2:2n+1])

        @test_approx_eq saccum(Op, n, AbsFun(), a, 1) safef(abs(a[1:n]))
        @test_approx_eq saccum(Op, n, AbsFun(), a, 3) safef(abs(a[3:n+2]))
        @test_approx_eq saccum(Op, n, AbsFun(), a, 1, 2) safef(abs(a[1:2:2n-1]))
        @test_approx_eq saccum(Op, n, AbsFun(), a, 3, 2) safef(abs(a[3:2:2n+1]))

        @test_approx_eq saccum(Op, n, Abs2Fun(), a, 1) safef(abs2(a[1:n]))
        @test_approx_eq saccum(Op, n, Abs2Fun(), a, 3) safef(abs2(a[3:n+2]))
        @test_approx_eq saccum(Op, n, Abs2Fun(), a, 1, 2) safef(abs2(a[1:2:2n-1]))
        @test_approx_eq saccum(Op, n, Abs2Fun(), a, 3, 2) safef(abs2(a[3:2:2n+1]))

        @test_approx_eq saccum(Op, n, SinFun(), a, 1) safef(sin(a[1:n]))
        @test_approx_eq saccum(Op, n, SinFun(), a, 3) safef(sin(a[3:n+2]))
        @test_approx_eq saccum(Op, n, SinFun(), a, 1, 2) safef(sin(a[1:2:2n-1]))
        @test_approx_eq saccum(Op, n, SinFun(), a, 3, 2) safef(sin(a[3:2:2n+1]))

        @test_approx_eq saccum(Op, n, Multiply(), a, 1, b, 1) safef(.*(a[1:n], b[1:n]))
        @test_approx_eq saccum(Op, n, Multiply(), a, 3, b, 4) safef(.*(a[3:n+2], b[4:n+3]))
        @test_approx_eq saccum(Op, n, Multiply(), a, 1, 2, b, 1, 3) safef(.*(a[1:2:2n-1], b[1:3:3n-2]))
        @test_approx_eq saccum(Op, n, Multiply(), a, 3, 2, b, 4, 3) safef(.*(a[3:2:2n+1], b[4:3:3n+1]))

        @test_approx_eq saccum(Op, n, Multiply(), a, 1, v, 0) safef(a[1:n] .* v)
        @test_approx_eq saccum(Op, n, Multiply(), v, 0, b, 1) safef(v .* b[1:n])
        @test_approx_eq saccum(Op, n, Multiply(), a, 3, 2, v, 0, 1) safef(a[3:2:2n+1] .* v)

        @test_approx_eq saccum_fdiff(Op, n, Abs2Fun(), a, 1, b, 1) safef(abs2(a[1:n] - b[1:n]))
        @test_approx_eq saccum_fdiff(Op, n, Abs2Fun(), a, 3, b, 4) safef(abs2(a[3:n+2] - b[4:n+3]))
        @test_approx_eq saccum_fdiff(Op, n, Abs2Fun(), a, 1, 2, b, 1, 3) safef(abs2(a[1:2:2n-1] - b[1:3:3n-2]))
        @test_approx_eq saccum_fdiff(Op, n, Abs2Fun(), a, 3, 2, b, 4, 3) safef(abs2(a[3:2:2n+1] - b[4:3:3n+1]))

        @test_approx_eq saccum_fdiff(Op, n, Abs2Fun(), a, 1, v, 0) safef(abs2(a[1:n] - v))
        @test_approx_eq saccum_fdiff(Op, n, Abs2Fun(), v, 0, b, 1) safef(abs2(v - b[1:n]))

        @test_approx_eq saccum(Op, n, FMA(), a, 1, b, 1, c, 1) safef(fma(a[1:n], b[1:n], c[1:n]))
        @test_approx_eq saccum(Op, n, FMA(), a, 3, b, 4, c, 5) safef(fma(a[3:n+2], b[4:n+3], c[5:n+4]))
        @test_approx_eq saccum(Op, n, FMA(), a, 1, 2, b, 1, 3, c, 1, 4) safef(fma(a[1:2:2n-1], b[1:3:3n-2], c[1:4:4n-3]))
        @test_approx_eq saccum(Op, n, FMA(), a, 3, 2, b, 4, 3, c, 5, 4) safef(fma(a[3:2:2n+1], b[4:3:3n+1], c[5:4:4n+1]))
    end
end


for (Op, cf) in [(Sum, +), (Maximum, max), (Minimum, min)]
    for n = 1:15
        r = copy(r0[1:n])
        paccum!(Op, n, r, 1, a, 1)
        @test_approx_eq r cf(r0[1:n], a[1:n])

        r = copy(r0[1:n])
        paccum!(Op, n, r, 1, Abs2Fun(), a, 1)
        @test_approx_eq r cf(r0[1:n], abs2(a[1:n]))

        r = copy(r0[1:n])
        paccum!(Op, n, r, 1, Multiply(), a, 1, b, 1)
        @test_approx_eq r cf(r0[1:n], .*(a[1:n], b[1:n]))

        r = copy(r0[1:n])
        paccum_fdiff!(Op, n, r, 1, Abs2Fun(), a, 1, b, 1)
        @test_approx_eq r cf(r0[1:n], abs2(a[1:n] - b[1:n]))

        r = copy(r0[1:n])
        paccum!(Op, n, r, 1, FMA(), a, 1, b, 1, c, 1)
        @test_approx_eq r cf(r0[1:n], fma(a[1:n], b[1:n], c[1:n]))

        r = copy(r0[1:n+10])
        paccum!(Op, n, r, 11, a, 3)
        @test r[1:10] == r0[1:10]
        @test_approx_eq r[11:n+10] cf(r0[11:n+10], a[3:n+2])

        r = copy(r0[1:n+10])
        paccum!(Op, n, r, 11, Abs2Fun(), a, 3)
        @test r[1:10] == r0[1:10]
        @test_approx_eq r[11:n+10] cf(r0[11:n+10], abs2(a[3:n+2]))

        r = copy(r0[1:n+10])
        paccum!(Op, n, r, 11, Multiply(), a, 3, b, 4)
        @test r[1:10] == r0[1:10]
        @test_approx_eq r[11:n+10] cf(r0[11:n+10], .*(a[3:n+2], b[4:n+3]))

        r = copy(r0[1:n+10])
        paccum_fdiff!(Op, n, r, 11, Abs2Fun(), a, 3, b, 4)
        @test r[1:10] == r0[1:10]
        @test_approx_eq r[11:n+10] cf(r0[11:n+10], abs2(a[3:n+2] - b[4:n+3]))

        r = copy(r0[1:n+10])
        paccum!(Op, n, r, 11, FMA(), a, 3, b, 4, c, 5)
        @test r[1:10] == r0[1:10]
        @test_approx_eq r[11:n+10] cf(r0[11:n+10], fma(a[3:n+2], b[4:n+3], c[5:n+4]))

        r = copy(r0[1:4+3n])
        rc = copy(r)
        paccum!(Op, n, r, 4, 3, a, 3, 2)
        u = falses(4+3n)
        u[4:3:3n+1] = true
        @test r[~u] == rc[~u]
        @test_approx_eq r[u] cf(rc[u], a[3:2:2n+1])

        r = copy(r0[1:4+3n])
        rc = copy(r)
        paccum!(Op, n, r, 4, 3, Abs2Fun(), a, 3, 2)
        u = falses(4+3n)
        u[4:3:3n+1] = true
        @test r[~u] == rc[~u]
        @test_approx_eq r[u] cf(rc[u], abs2(a[3:2:2n+1]))

        r = copy(r0[1:4+3n])
        rc = copy(r)
        paccum!(Op, n, r, 4, 3, Multiply(), a, 3, 2, b, 5, 4)
        u = falses(4+3n)
        u[4:3:3n+1] = true
        @test r[~u] == rc[~u]
        @test_approx_eq r[u] cf(rc[u], .*(a[3:2:2n+1], b[5:4:4n+1]))

        r = copy(r0[1:4+3n])
        rc = copy(r)
        paccum_fdiff!(Op, n, r, 4, 3, Abs2Fun(), a, 3, 2, b, 5, 4)
        u = falses(4+3n)
        u[4:3:3n+1] = true
        @test r[~u] == rc[~u]
        @test_approx_eq r[u] cf(rc[u], abs2(a[3:2:2n+1] - b[5:4:4n+1]))

        r = copy(r0[1:4+3n])
        rc = copy(r)
        paccum!(Op, n, r, 4, 3, FMA(), a, 3, 2, b, 5, 4, c, 6, 5)
        u = falses(4+3n)
        u[4:3:3n+1] = true
        @test r[~u] == rc[~u]
        @test_approx_eq r[u] cf(rc[u], fma(a[3:2:2n+1], b[5:4:4n+1], c[6:5:5n+1]))
    end
end

