
using NumericExtensions
using Base.Test

x = [1., 2., 3.]
y = [6., 5., 4.]

@test map(Abs2(), x) == abs2(x)

r = copy(x)
map1!(Abs2(), r)
@test r == abs2(x)

@test map(Add(), x, y) == x + y
@test map(Multiply(), x, y) == x .* y
@test map(Subtract(), x, 1) == x - 1
@test map(Subtract(), 1, x) == 1 - x

@test mapdiff(Abs2(), x, y) == abs2(x - y)
@test mapdiff(Abs2(), 1., y) == abs2(1 - y)
@test mapdiff(Abs2(), x, 1.) == abs2(x - 1)

r = copy(x)
map1!(Add(), r, y)
@test r == x + y

r = copy(x)
map1!(Add(), r, 1)
@test r == x + 1

r = copy(x)
mapdiff!(Abs2(), r, x, y)
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


# Test extended functions

@test_approx_eq absdiff(x, y) abs(x - y)
@test_approx_eq sqrdiff(x, y) abs2(x - y)


# Ternary functions

a = rand(8)
b = rand(8)
c = rand(8)

@test_approx_eq map(FMA(), a, b, c)  a + b .* c
@test_approx_eq map(FMA(), a, b, 2.) a + b * 2.
@test_approx_eq map(FMA(), a, 2., c) a + 2. * c
@test_approx_eq map(FMA(), 2., b, c)  2. + b .* c
@test_approx_eq map(FMA(), a, 2., 3.) a + 2. * 3.
@test_approx_eq map(FMA(), 2., b, 3.) 2. + b * 3.
@test_approx_eq map(FMA(), 2., 3., c) 2. + 3. * c

@test_approx_eq fma(a, b, c) a + b .* c
@test_approx_eq fma(a, b, 2.) a + b * 2.

r = copy(a); fma!(r, b, c)
@test_approx_eq r a + b .* c
r = copy(a); fma!(r, b, 2.)
@test_approx_eq r a + b .* 2.

# customized functions

type Plus <: BinaryFunctor end
NumericExtensions.evaluate(::Plus, x, y) = x + y
NumericExtensions.result_type{T1,T2}(::Plus, ::Type{T1}, ::Type{T2}) = promote_type(T1, T2)

@test_approx_eq map(Plus(), a, b) a + b





