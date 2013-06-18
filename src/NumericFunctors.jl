module NumericFunctors

	export 
		# functors
		Functor, UnaryFunctor, BinaryFunctor, TernaryFunctor,
		result_type, evaluate,
		Add, Subtract, Multiply, Divide, Negate, Max, Min,
		Abs, Abs2, Sqrt, Cbrt, Pow, Hypot, 
		Floor, Ceil, Round, Trunc,
		Exp, Exp2, Exp10, Expm1, 
		Log, Log2, Log10, Log1p,
		Sin, Cos, Tan, Asin, Acos, Atan, Atan2,
		Sinh, Cosh, Tanh, Asinh, Acosh, Atanh, 
		Erf, Erfc, Gamma, Lgamma, Digamma, 
		Greater, GreaterEqual, Less, LessEqual, Equal, NotEqual,
		Isfinite, Isnan, Isinf,

		# fmap
		fmap, fmap!

	include("functors.jl")
	include("fmap.jl")

end
