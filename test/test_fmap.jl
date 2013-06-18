
using NumericFunctors
using Base.Test

x = [1., 2., 3.]
y = [6., 5., 4.]

@test fmap(Abs2(), x) == abs2(x)

r = copy(x)
fmap!(Abs2(), r)
@test r == abs2(x)

@test fmap(Add(), x, y) == x + y
@test fmap(Multiply(), x, y) == x .* y

@test fmap(Subtract(), x, 1) == x - 1
@test fmap(Subtract(), 1, x) == 1 - x

r = copy(x)
fmap!(Add(), r, y)
@test r == x + y

r = copy(x)
fmap!(Add(), r, 1)
@test r == x + 1

