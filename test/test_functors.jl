# Test functors

using NumericExtensions
using Base.Test

# basics

x = rand(3)
@test is(to_fparray(x), x)
@test to_fparray([1,2,3]) == [1., 2., 3.]

# Test unary functors

for e in [
	(Negate, -),
	(Abs, abs), (Abs2, abs2), (Sqrt, sqrt), (Cbrt, cbrt), 
	(Floor, floor), (Ceil, ceil), (Round, round), (Trunc, trunc), 
	(Exp, exp), (Exp2, exp2), (Exp10, exp10), (Expm1, expm1),
	(Log, log), (Log2, log2), (Log10, log10), (Log1p, log1p),
	(Sin, sin), (Cos, cos), (Tan, tan), (Asin, asin), (Acos, acos), (Atan, atan),
	(Sinh, sinh), (Cosh, cosh), (Tanh, tanh), (Asinh, asinh), (Acosh, acosh), (Atanh, atanh), 
	(Erf, erf), (Erfc, erfc), (Gamma, gamma), (Lgamma, lgamma), (Digamma, digamma), 
	(Isfinite, isfinite), (Isinf, isinf), (Isnan, isnan)]

	T = e[1]
	f = e[2]

	@test evaluate(T(), 1.0) === f(1.0)
	@test evaluate(T(), 1) === f(1)

	@test typeof(evaluate(T(), 1.0)) == typeof(f(1.0)) == result_type(T(), Float64)
	@test typeof(evaluate(T(), 1)) === typeof(f(1)) == result_type(T(), Int)
end

# Test binary functors

for e in [
	(Add, +), 
	(Subtract, -), 
	(Multiply, *), 
	(Divide, /), 
	(Pow, ^), 
	(Max, max),
	(Min, min),
	(Hypot, hypot),
	(Atan2, atan2),
	(Greater, >), 
	(GreaterEqual, >=),
	(Less, <), 
	(LessEqual, <=), 
	(Equal, ==), 
	(NotEqual, !=)]

	T = e[1]
	f = e[2]

	@test evaluate(T(), 2.0, 3.0) === f(2.0, 3.0)
	@test evaluate(T(), 2, 3) === f(2, 3)
	@test evaluate(T(), 2.0, 3) === f(2.0, 3)
	@test evaluate(T(), 2, 3.0) === f(2, 3.0)

	@test typeof(evaluate(T(), 2.0, 3.0)) == typeof(f(2.0, 3.0)) == result_type(T(), Float64, Float64)
	@test typeof(evaluate(T(), 2, 3)) == typeof(f(2, 3)) == result_type(T(), Int, Int)
	@test typeof(evaluate(T(), 2.0, 3)) === typeof(f(2.0, 3)) == result_type(T(), Float64, Int)
	@test typeof(evaluate(T(), 2, 3.0)) === typeof(f(2, 3.0)) == result_type(T(), Int, Float64)
end

