
using NumericFunctors
using Base.Test

x = [1., 2., 3.]
y = [6., 5., 4.]

@test vmap(Abs2(), x) == abs2(x)

r = copy(x)
vmap!(Abs2(), r)
@test r == abs2(x)

@test vmap(Add(), x, y) == x + y
@test vmap(Multiply(), x, y) == x .* y
@test vmap(Subtract(), x, 1) == x - 1
@test vmap(Subtract(), 1, x) == 1 - x

@test vmapdiff(Abs2(), x, y) == abs2(x - y)
@test vmapdiff(Abs2(), 1., y) == abs2(1 - y)
@test vmapdiff(Abs2(), x, 1.) == abs2(x - 1)

r = copy(x)
vmap!(Add(), r, y)
@test r == x + y

r = copy(x)
vmap!(Add(), r, 1)
@test r == x + 1

r = copy(x)
vmapdiff!(r, Abs2(), x, y)
@test r == abs2(x - y)


# Test inplace functions

x = rand(10)
y = rand(10)

r = copy(x); add!(r, y) 
@test_approx_eq r x + y

r = copy(x); add!(r, 1)
@test_approx_eq r x + 1

r = copy(x); subtract!(r, y) 
@test_approx_eq r x - y

r = copy(x); subtract!(r, 1)
@test_approx_eq r x - 1

r = copy(x); multiply!(r, y) 
@test_approx_eq r x .* y

r = copy(x); multiply!(r, 2)
@test_approx_eq r x * 2

r = copy(x); divide!(r, y) 
@test_approx_eq r x ./ y

r = copy(x); divide!(r, 2)
@test_approx_eq r x / 2

r = copy(x); negate!(r)
@test_approx_eq r (-x)

r = copy(x); rcp!(r)
@test_approx_eq r 1.0 / x

r = copy(x); pow!(r, 3)
@test_approx_eq r x.^3

r = copy(x); sqrt!(r)
@test_approx_eq r sqrt(x)

r = copy(x); exp!(r)
@test_approx_eq r exp(x)

r = copy(x); log!(r)
@test_approx_eq r log(x)

x = randn(10)
y = randn(10)

r = copy(x); abs!(r)
@test_approx_eq r abs(x)

r = copy(x); abs2!(r)
@test_approx_eq r abs2(x)

r = copy(x); floor!(r)
@test_approx_eq r floor(x)

r = copy(x); ceil!(r)
@test_approx_eq r ceil(x)

r = copy(x); round!(r)
@test_approx_eq r round(x)

r = copy(x); trunc!(r)
@test_approx_eq r trunc(x)

