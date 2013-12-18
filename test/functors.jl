# tests for functors

using Base.Test
using NumericExtensions

## basic operators

@test evaluate(Negate(),   2) == -2
@test evaluate(Add(),      2, 3) == 5
@test evaluate(Subtract(), 2, 3) == -1
@test evaluate(Multiply(), 2, 3) == 6
@test evaluate(Divide(),   2, 3) == 2 / 3
@test evaluate(Modulo(),   5, 3) == 2
@test evaluate(Pow(),      2, 3) == 8

@test evaluate(Greater(),      2, 3) == false
@test evaluate(Greater(),      2, 2) == false
@test evaluate(GreaterEqual(), 2, 3) == false
@test evaluate(GreaterEqual(), 2, 2) == true

@test evaluate(Less(),      3, 2) == false
@test evaluate(Less(),      3, 2) == false
@test evaluate(LessEqual(), 3, 2) == false
@test evaluate(LessEqual(), 2, 2) == true

@test evaluate(Equal(), 3, 2)    == false
@test evaluate(Equal(), 2, 2)    == true
@test evaluate(NotEqual(), 3, 2) == true
@test evaluate(NotEqual(), 2, 2) == false

@test evaluate(Not(), true)  == false
@test evaluate(Not(), false) == true
@test evaluate(And(), true, false) == false
@test evaluate(Or(),  true, false) == true

@test evaluate(BitwiseNot(), 1) == ~1
@test evaluate(BitwiseAnd(), 3, 6) == 2
@test evaluate(BitwiseOr(),  3, 6) == 7
@test evaluate(BitwiseXor(), 3, 6) == 5

# elementary math

x = 0.8
y = 0.6
z = 1.2

@test evaluate(MinFun(), x, y) == min(x, y)
@test evaluate(MaxFun(), x, y) == max(x, y)

@test evaluate(AbsFun(), -0.5) == 0.5
@test evaluate(Abs2Fun(), x) == abs2(x)
@test evaluate(SqrFun(),  x) == sqr(x)
@test evaluate(SqrtFun(), x) == sqrt(x)
@test evaluate(CbrtFun(), x) == cbrt(x)
@test evaluate(RcpFun(),  x) == rcp(x)
@test evaluate(RsqrtFun(), x) == rsqrt(x)
@test evaluate(RcbrtFun(), x) == rcbrt(x)

@test evaluate(HypotFun(), x, y) == hypot(x, y)

@test evaluate(IsfiniteFun(), 1.0) == true
@test evaluate(IsfiniteFun(), Inf) == false
@test evaluate(IsfiniteFun(), NaN) == false

@test evaluate(IsinfFun(), 1.0) == false
@test evaluate(IsinfFun(), Inf) == true
@test evaluate(IsinfFun(), NaN) == false

@test evaluate(IsnanFun(), 1.0) == false
@test evaluate(IsnanFun(), Inf) == false
@test evaluate(IsnanFun(), NaN) == true

@test evaluate(FloorFun(), x) == floor(x)
@test evaluate(CeilFun(), x)  == ceil(x)
@test evaluate(RoundFun(), x) == round(x)
@test evaluate(TruncFun(), x) == trunc(x)

@test evaluate(IfloorFun(), x) == ifloor(x)
@test evaluate(IceilFun(), x)  == iceil(x)
@test evaluate(IroundFun(), x) == iround(x)
@test evaluate(ItruncFun(), x) == itrunc(x)

@test evaluate(ModFun(), x, y) == mod(x, y)
@test evaluate(RemFun(), x, y) == rem(x, y)
@test evaluate(FldFun(), x, y) == fld(x, y)
@test evaluate(DivFun(), 8, 6) == 1

@test evaluate(ExpFun(), x)   == exp(x)
@test evaluate(Exp2Fun(), x)  == exp2(x)
@test evaluate(Exp10Fun(), x) == exp10(x)
@test evaluate(Expm1Fun(), x) == expm1(x)

@test evaluate(LogFun(), x)   == log(x)
@test evaluate(Log2Fun(), x)  == log2(x)
@test evaluate(Log10Fun(), x) == log10(x)
@test evaluate(Log1pFun(), x) == log1p(x)

@test evaluate(SinFun(), x) == sin(x)
@test evaluate(CosFun(), x) == cos(x)
@test evaluate(TanFun(), x) == tan(x)
@test evaluate(AsinFun(), x) == asin(x)
@test evaluate(AcosFun(), x) == acos(x)
@test evaluate(AtanFun(), x) == atan(x)
@test evaluate(Atan2Fun(), x, y) == atan2(x, y)

# ternary functors

@test evaluate(FMA(), x, y, z) == (x + y * z)
@test evaluate(IfelseFun(), true, y, z) == y
@test evaluate(IfelseFun(), false, y, z) == z

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
end



