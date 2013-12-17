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

a1 = rand(6)
a2 = rand(5, 6)
a3 = rand(5, 4, 3)
a4 = rand(5, 4, 3, 2)

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







