# testing of reduction kernels

import NumericExtensions: safe_sum, safe_max, safe_min
import NumericExtensions: vecsum, vecadd!
using Base.Test

a = rand(60)
b = rand(60)

for n = 1:15
    @test_approx_eq vecsum(n, a, 1) safe_sum(a[1:n])
    @test_approx_eq vecsum(n, a, 3) safe_sum(a[3:n+2])
    @test_approx_eq vecsum(n, a, 1, 2) safe_sum(a[1:2:2n-1])
    @test_approx_eq vecsum(n, a, 3, 2) safe_sum(a[3:2:2n+1])
end

for n = 1:15
    r = copy(b[1:n])
    vecadd!(n, r, 1, a, 1)
    @test_approx_eq r b[1:n] + a[1:n]

    r = copy(b[1:n+3])
    vecadd!(n, r, 4, a, 3)
    @test r[1:3] == b[1:3]
    @test_approx_eq r[4:n+3] b[4:n+3] + a[3:n+2]  

    r = copy(b[1:4+3n])
    rc = copy(r)
    vecadd!(n, r, 4, 3, a, 3, 2)
    u = falses(4+3n)
    u[4:3:3n+1] = true
    @test r[~u] == rc[~u]
    @test_approx_eq r[u] rc[u] + a[3:2:2n+1]
end



