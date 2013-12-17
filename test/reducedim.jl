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


