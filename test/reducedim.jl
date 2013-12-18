using NumericExtensions
using Base.Test

## Testing of reduced shape & length

reduced_shape = NumericExtensions.reduced_shape
reduced_length = NumericExtensions.reduced_length

# reduced_shape

@test reduced_shape((5,), 1) == (1,)
@test_throws reduced_shape((5,), 2)

@test reduced_shape((3, 4), 1) == (1, 4)
@test reduced_shape((3, 4), 2) == (3, 1)
@test_throws reduced_shape((3, 4), 3)

@test reduced_shape((3, 4, 5), 1) == (1, 4, 5)
@test reduced_shape((3, 4, 5), 2) == (3, 1, 5)
@test reduced_shape((3, 4, 5), 3) == (3, 4, 1)
@test_throws reduced_shape((3, 4, 5), 4)

@test reduced_shape((3, 4, 5, 6), 1) == (1, 4, 5, 6)
@test reduced_shape((3, 4, 5, 6), 2) == (3, 1, 5, 6)
@test reduced_shape((3, 4, 5, 6), 3) == (3, 4, 1, 6)
@test reduced_shape((3, 4, 5, 6), 4) == (3, 4, 5, 1)
@test_throws reduced_shape((3, 4, 5, 6), 5)

# reduced_length

@test reduced_length((5,), 1) == 1
@test_throws reduced_length((5,), 2)

@test reduced_length((3, 4), 1) == 4
@test reduced_length((3, 4), 2) == 3
@test_throws reduced_length((3, 4), 3)

@test reduced_length((3, 4, 5), 1) == 20
@test reduced_length((3, 4, 5), 2) == 15
@test reduced_length((3, 4, 5), 3) == 12
@test_throws reduced_length((3, 4, 5), 4)

@test reduced_length((3, 4, 5, 6), 1) == 120
@test reduced_length((3, 4, 5, 6), 2) == 90
@test reduced_length((3, 4, 5, 6), 3) == 72
@test reduced_length((3, 4, 5, 6), 4) == 60
@test_throws reduced_length((3, 4, 5, 6), 5)


## Testing of sum

a1 = 2 * rand(6) - 1.0
a2 = 2 * rand(5, 6) - 1.0
a3 = 2 * rand(5, 4, 3) - 1.0
a4 = 2 * rand(5, 4, 3, 2) - 1.0

p1 = rand(6)
p2 = rand(5, 6)
p3 = rand(5, 4, 3)
p4 = rand(5, 4, 3, 2)

q1 = rand(6)
q2 = rand(5, 6)
q3 = rand(5, 4, 3)
q4 = rand(5, 4, 3, 2)

# auxiliary

function safe_sumdim(a::Array, dim::Int)
	n = size(a, dim)
	s = slicedim(a, dim, 1)
	for i = 2 : n
		s += slicedim(a, dim, i)
	end
	return s
end

do_sum!(a::Array, dim::Int) = sum!(zeros(reduced_shape(size(a), dim)), a, dim)


# testing sum

@test_approx_eq sum(a1, 1) safe_sumdim(a1, 1)

@test_approx_eq sum(a2, 1) safe_sumdim(a2, 1)
@test_approx_eq sum(a2, 2) safe_sumdim(a2, 2)

@test_approx_eq sum(a3, 1) safe_sumdim(a3, 1)
@test_approx_eq sum(a3, 2) safe_sumdim(a3, 2)
@test_approx_eq sum(a3, 3) safe_sumdim(a3, 3)

@test_approx_eq sum(a4, 1) safe_sumdim(a4, 1)
@test_approx_eq sum(a4, 2) safe_sumdim(a4, 2)
@test_approx_eq sum(a4, 3) safe_sumdim(a4, 3)
@test_approx_eq sum(a4, 4) safe_sumdim(a4, 4)

# testing sum!

@test_approx_eq do_sum!(a1, 1) safe_sumdim(a1, 1)

@test_approx_eq do_sum!(a2, 1) safe_sumdim(a2, 1)
@test_approx_eq do_sum!(a2, 2) safe_sumdim(a2, 2)

@test_approx_eq do_sum!(a3, 1) safe_sumdim(a3, 1)
@test_approx_eq do_sum!(a3, 2) safe_sumdim(a3, 2)
@test_approx_eq do_sum!(a3, 3) safe_sumdim(a3, 3)

@test_approx_eq do_sum!(a4, 1) safe_sumdim(a4, 1)
@test_approx_eq do_sum!(a4, 2) safe_sumdim(a4, 2)
@test_approx_eq do_sum!(a4, 3) safe_sumdim(a4, 3)
@test_approx_eq do_sum!(a4, 4) safe_sumdim(a4, 4)

# testing sumabs

@test_approx_eq sumabs(a1, 1) sum(abs(a1), 1)

@test_approx_eq sumabs(a2, 1) sum(abs(a2), 1)
@test_approx_eq sumabs(a2, 2) sum(abs(a2), 2)

@test_approx_eq sumabs(a3, 1) sum(abs(a3), 1)
@test_approx_eq sumabs(a3, 2) sum(abs(a3), 2)
@test_approx_eq sumabs(a3, 3) sum(abs(a3), 3)

@test_approx_eq sumabs(a4, 1) sum(abs(a4), 1)
@test_approx_eq sumabs(a4, 2) sum(abs(a4), 2)
@test_approx_eq sumabs(a4, 3) sum(abs(a4), 3)
@test_approx_eq sumabs(a4, 4) sum(abs(a4), 4)

# testing sumsq

@test_approx_eq sumsq(a1, 1) sum(abs2(a1), 1)

@test_approx_eq sumsq(a2, 1) sum(abs2(a2), 1)
@test_approx_eq sumsq(a2, 2) sum(abs2(a2), 2)

@test_approx_eq sumsq(a3, 1) sum(abs2(a3), 1)
@test_approx_eq sumsq(a3, 2) sum(abs2(a3), 2)
@test_approx_eq sumsq(a3, 3) sum(abs2(a3), 3)

@test_approx_eq sumsq(a4, 1) sum(abs2(a4), 1)
@test_approx_eq sumsq(a4, 2) sum(abs2(a4), 2)
@test_approx_eq sumsq(a4, 3) sum(abs2(a4), 3)
@test_approx_eq sumsq(a4, 4) sum(abs2(a4), 4)

# testing sumxlogx

@test_approx_eq sumxlogx(p1, 1) sum(p1 .* log(p1), 1)

@test_approx_eq sumxlogx(p2, 1) sum(p2 .* log(p2), 1)
@test_approx_eq sumxlogx(p2, 2) sum(p2 .* log(p2), 2)

@test_approx_eq sumxlogx(p3, 1) sum(p3 .* log(p3), 1)
@test_approx_eq sumxlogx(p3, 2) sum(p3 .* log(p3), 2)
@test_approx_eq sumxlogx(p3, 3) sum(p3 .* log(p3), 3)

@test_approx_eq sumxlogx(p4, 1) sum(p4 .* log(p4), 1)
@test_approx_eq sumxlogx(p4, 2) sum(p4 .* log(p4), 2)
@test_approx_eq sumxlogx(p4, 3) sum(p4 .* log(p4), 3)
@test_approx_eq sumxlogx(p4, 4) sum(p4 .* log(p4), 4)

# testing sumxlogy

@test_approx_eq sumxlogy(p1, q1, 1) sum(p1 .* log(q1), 1)

@test_approx_eq sumxlogy(p2, q2, 1) sum(p2 .* log(q2), 1)
@test_approx_eq sumxlogy(p2, q2, 2) sum(p2 .* log(q2), 2)

@test_approx_eq sumxlogy(p3, q3, 1) sum(p3 .* log(q3), 1)
@test_approx_eq sumxlogy(p3, q3, 2) sum(p3 .* log(q3), 2)
@test_approx_eq sumxlogy(p3, q3, 3) sum(p3 .* log(q3), 3)

@test_approx_eq sumxlogy(p4, q4, 1) sum(p4 .* log(q4), 1)
@test_approx_eq sumxlogy(p4, q4, 2) sum(p4 .* log(q4), 2)
@test_approx_eq sumxlogy(p4, q4, 3) sum(p4 .* log(q4), 3)
@test_approx_eq sumxlogy(p4, q4, 4) sum(p4 .* log(q4), 4)




