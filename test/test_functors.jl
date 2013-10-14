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
	(AbsFun, abs), (Abs2Fun, abs2), (SqrtFun, sqrt), (CbrtFun, cbrt), 
	(FloorFun, floor), (CeilFun, ceil), (RoundFun, round), (TruncFun, trunc), 
	(ExpFun, exp), (Exp2Fun, exp2), (Exp10Fun, exp10), (Expm1Fun, expm1),
	(LogFun, log), (Log2Fun, log2), (Log10Fun, log10), (Log1pFun, log1p),
	(SinFun, sin), (CosFun, cos), (TanFun, tan), (AsinFun, asin), (AcosFun, acos), (AtanFun, atan),
	(SinhFun, sinh), (CoshFun, cosh), (TanhFun, tanh), (AsinhFun, asinh), (AcoshFun, acosh), (AtanhFun, atanh), 
	(ErfFun, erf), (ErfcFun, erfc), (GammaFun, gamma), (LgammaFun, lgamma), (DigammaFun, digamma), 
	(IsfiniteFun, isfinite), (IsinfFun, isinf), (IsnanFun, isnan)]

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
	(MaxFun, max),
	(MinFun, min),
	(HypotFun, hypot),
	(Atan2Fun, atan2),
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

