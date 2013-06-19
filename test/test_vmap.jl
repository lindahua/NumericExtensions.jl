
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

