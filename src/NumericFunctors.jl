module NumericFunctors

	export 
		# functors
		Functor, UnaryFunctor, BinaryFunctor, TernaryFunctor,
		result_type, evaluate,
		Add, Subtract, Multiply, Divide, Negate, Max, Min,
		Abs, Abs2, Sqrt, Cbrt, Pow, Hypot, FixAbsPow, 
		Floor, Ceil, Round, Trunc,
		Exp, Exp2, Exp10, Expm1, 
		Log, Log2, Log10, Log1p,
		Sin, Cos, Tan, Asin, Acos, Atan, Atan2,
		Sinh, Cosh, Tanh, Asinh, Acosh, Atanh, 
		Erf, Erfc, Gamma, Lgamma, Digamma, 
		Greater, GreaterEqual, Less, LessEqual, Equal, NotEqual,
		Isfinite, Isnan, Isinf,

		# vmap
		vmap, vmap!, vmapdiff, vmapdiff!,

		# vreduce
		vreduce, vreduce!, vreduce_fdiff, vreduce_fdiff!,
		vsum, vsum!, vmax, vmax!, vmin, vmin!, nonneg_vmax, nonneg_vmax!,
		vasum, vasum!, vamax, vamax!, vamin, vamin!, vsqsum, vsqsum!,  
		vdot, vdot!, vadiffsum, vadiffsum!, vsqdiffsum, vsqdiffsum!,
		vadiffmax, vadiffmax!, vadiffmin, vadiffmin!,  
		vnorm, vnorm!, vdiffnorm, vdiffnorm!

	include("functors.jl")
	include("vmap.jl")
	include("vreduce.jl")

end
