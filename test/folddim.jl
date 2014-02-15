using NumericExtensions
using Base.Test

a1 = 2 * rand(8) - 1.0
a2 = 2 * rand(8, 7) - 1.0
a3 = 2 * rand(8, 7, 6) - 1.0
a4 = 2 * rand(8, 7, 6, 5) - 1.0

b1 = 2 * rand(8) - 1.0
b2 = 2 * rand(8, 7) - 1.0
b3 = 2 * rand(8, 7, 6) - 1.0
b4 = 2 * rand(8, 7, 6, 5) - 1.0

foldlsum(xs...) = foldl(Add(), 0., xs...)
foldlsumfdiff(f, x1, x2, dim) = foldl_fdiff(Add(), 0., f, x1, x2, dim)

@test_approx_eq foldlsum(a1, 1) sum(a1, 1)
@test_approx_eq foldlsum(a2, 1) sum(a2, 1)
@test_approx_eq foldlsum(a2, 2) sum(a2, 2)
@test_approx_eq foldlsum(a3, 1) sum(a3, 1)
@test_approx_eq foldlsum(a3, 2) sum(a3, 2)
@test_approx_eq foldlsum(a3, 3) sum(a3, 3)
@test_approx_eq foldlsum(a4, 1) sum(a4, 1)
@test_approx_eq foldlsum(a4, 2) sum(a4, 2)
@test_approx_eq foldlsum(a4, 3) sum(a4, 3)
@test_approx_eq foldlsum(a4, 4) sum(a4, 4)

do_foldlsum!(a, dim) = foldl!(zeros(Base.reduced_dims(size(a), dim)), Add(), 0., a, dim)

@test_approx_eq do_foldlsum!(a1, 1) sum(a1, 1)
@test_approx_eq do_foldlsum!(a2, 1) sum(a2, 1)
@test_approx_eq do_foldlsum!(a2, 2) sum(a2, 2)
@test_approx_eq do_foldlsum!(a3, 1) sum(a3, 1)
@test_approx_eq do_foldlsum!(a3, 2) sum(a3, 2)
@test_approx_eq do_foldlsum!(a3, 3) sum(a3, 3)
@test_approx_eq do_foldlsum!(a4, 1) sum(a4, 1)
@test_approx_eq do_foldlsum!(a4, 2) sum(a4, 2)
@test_approx_eq do_foldlsum!(a4, 3) sum(a4, 3)
@test_approx_eq do_foldlsum!(a4, 4) sum(a4, 4)

@test_approx_eq foldlsum(Abs2Fun(), a1, 1) sum(abs2(a1), 1)
@test_approx_eq foldlsum(Abs2Fun(), a2, 1) sum(abs2(a2), 1)
@test_approx_eq foldlsum(Abs2Fun(), a2, 2) sum(abs2(a2), 2)
@test_approx_eq foldlsum(Abs2Fun(), a3, 1) sum(abs2(a3), 1)
@test_approx_eq foldlsum(Abs2Fun(), a3, 2) sum(abs2(a3), 2)
@test_approx_eq foldlsum(Abs2Fun(), a3, 3) sum(abs2(a3), 3)
@test_approx_eq foldlsum(Abs2Fun(), a4, 1) sum(abs2(a4), 1)
@test_approx_eq foldlsum(Abs2Fun(), a4, 2) sum(abs2(a4), 2)
@test_approx_eq foldlsum(Abs2Fun(), a4, 3) sum(abs2(a4), 3)
@test_approx_eq foldlsum(Abs2Fun(), a4, 4) sum(abs2(a4), 4)

@test_approx_eq foldlsum(Multiply(), a1, b1, 1) sum(a1 .* b1, 1)
@test_approx_eq foldlsum(Multiply(), a2, b2, 1) sum(a2 .* b2, 1)
@test_approx_eq foldlsum(Multiply(), a2, b2, 2) sum(a2 .* b2, 2)
@test_approx_eq foldlsum(Multiply(), a3, b3, 1) sum(a3 .* b3, 1)
@test_approx_eq foldlsum(Multiply(), a3, b3, 2) sum(a3 .* b3, 2)
@test_approx_eq foldlsum(Multiply(), a3, b3, 3) sum(a3 .* b3, 3)
@test_approx_eq foldlsum(Multiply(), a4, b4, 1) sum(a4 .* b4, 1)
@test_approx_eq foldlsum(Multiply(), a4, b4, 2) sum(a4 .* b4, 2)
@test_approx_eq foldlsum(Multiply(), a4, b4, 3) sum(a4 .* b4, 3)
@test_approx_eq foldlsum(Multiply(), a4, b4, 4) sum(a4 .* b4, 4)

@test_approx_eq foldlsumfdiff(Abs2Fun(), a1, b1, 1) sum(abs2(a1 - b1), 1)
@test_approx_eq foldlsumfdiff(Abs2Fun(), a2, b2, 1) sum(abs2(a2 - b2), 1)
@test_approx_eq foldlsumfdiff(Abs2Fun(), a2, b2, 2) sum(abs2(a2 - b2), 2)
@test_approx_eq foldlsumfdiff(Abs2Fun(), a3, b3, 1) sum(abs2(a3 - b3), 1)
@test_approx_eq foldlsumfdiff(Abs2Fun(), a3, b3, 2) sum(abs2(a3 - b3), 2)
@test_approx_eq foldlsumfdiff(Abs2Fun(), a3, b3, 3) sum(abs2(a3 - b3), 3)
@test_approx_eq foldlsumfdiff(Abs2Fun(), a4, b4, 1) sum(abs2(a4 - b4), 1)
@test_approx_eq foldlsumfdiff(Abs2Fun(), a4, b4, 2) sum(abs2(a4 - b4), 2)
@test_approx_eq foldlsumfdiff(Abs2Fun(), a4, b4, 3) sum(abs2(a4 - b4), 3)
@test_approx_eq foldlsumfdiff(Abs2Fun(), a4, b4, 4) sum(abs2(a4 - b4), 4)
