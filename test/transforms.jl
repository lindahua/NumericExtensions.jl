# test of transforms

using NumericExtensions
using Base.Test

## linear transforms

x = rand(5)
X = rand(5, 4)

# scalar
a = 2.5
@test_approx_eq transform(a, x) a * x
@test_approx_eq transform(a, X) a * X

y = copy(x); transform!(a, y)
@test_approx_eq y a * x
Y = copy(X); transform!(a, Y)
@test_approx_eq Y a * X

# vector
a = rand(5) + 1.0
@test_approx_eq transform(a, x) a .* x
@test_approx_eq transform(a, X) a .* X

y = copy(x); transform!(a, y)
@test_approx_eq y a .* x
Y = copy(X); transform!(a, Y)
@test_approx_eq Y a .* X

# matrix
a = rand(3, 5) + 1.0

@test_approx_eq transform(a, x) a * x
@test_approx_eq transform(a, X) a * X

# transpose
a = rand(5, 3) + 1.0

@test_approx_eq transform(Transpose(a), x) a'x
@test_approx_eq transform(Transpose(a), X) a'X


## affine transforms

b = randn(5)

# scalar
a = 2.5
@test_approx_eq transform(AffineTransform(a), x) a * x
@test_approx_eq transform(AffineTransform(a), X) a * X
@test_approx_eq transform(AffineTransform(a, b), x) a * x .+ b
@test_approx_eq transform(AffineTransform(a, b), X) a * X .+ b

y = copy(x); transform!(AffineTransform(a), y)
@test_approx_eq y a * x
Y = copy(X); transform!(AffineTransform(a), Y)
@test_approx_eq Y a * X
y = copy(x); transform!(AffineTransform(a, b), y)
@test_approx_eq y a * x .+ b
Y = copy(X); transform!(AffineTransform(a, b), Y)
@test_approx_eq Y a * X .+ b

# vector
a = rand(5) + 1.0
@test_approx_eq transform(AffineTransform(a), x) a .* x
@test_approx_eq transform(AffineTransform(a), X) a .* X
@test_approx_eq transform(AffineTransform(a, b), x) a .* x .+ b
@test_approx_eq transform(AffineTransform(a, b), X) a .* X .+ b

y = copy(x); transform!(AffineTransform(a), y)
@test_approx_eq y a .* x
Y = copy(X); transform!(AffineTransform(a), Y)
@test_approx_eq Y a .* X
y = copy(x); transform!(AffineTransform(a, b), y)
@test_approx_eq y a .* x .+ b
Y = copy(X); transform!(AffineTransform(a, b), Y)
@test_approx_eq Y a .* X .+ b

# matrix
a = rand(3, 5)
b = rand(3)
@test_approx_eq transform(AffineTransform(a), x) a * x
@test_approx_eq transform(AffineTransform(a), X) a * X
@test_approx_eq transform(AffineTransform(a, b), x) a * x .+ b
@test_approx_eq transform(AffineTransform(a, b), X) a * X .+ b

# transpose
a = rand(5, 3)
b = rand(3)
@test_approx_eq transform(AffineTransform(Transpose(a)), x) a'x
@test_approx_eq transform(AffineTransform(Transpose(a)), X) a'X
@test_approx_eq transform(AffineTransform(Transpose(a), b), x) a'x .+ b
@test_approx_eq transform(AffineTransform(Transpose(a), b), X) a'X .+ b
