module NumericFunctors

	import Base.map, Base.map!, Base.reduce
	import Base.add!, Base.show, Base.getindex
	import Base.sum, Base.max, Base.min, Base.mean, Base.dot, Base.LinAlg.BLAS.asum, Base.norm

	export 
		# functors
		Functor, UnaryFunctor, BinaryFunctor, TernaryFunctor,
		result_type, evaluate,
		Add, Subtract, Multiply, Divide, Negate, Max, Min,
		Abs, Abs2, Sqrt, Cbrt, Pow, Hypot, FixAbsPow, FMA,
		Floor, Ceil, Round, Trunc,
		Exp, Exp2, Exp10, Expm1, 
		Log, Log2, Log10, Log1p,
		Sin, Cos, Tan, Asin, Acos, Atan, Atan2,
		Sinh, Cosh, Tanh, Asinh, Acosh, Atanh, 
		Erf, Erfc, Gamma, Lgamma, Digamma, 
		Greater, GreaterEqual, Less, LessEqual, Equal, NotEqual,
		Isfinite, Isnan, Isinf,

		# vmap
		map, map!, map1!, mapdiff, mapdiff!,

		add!, subtract!, multiply!, divide!, negate!, rcp!, 
		sqrt!, abs!, abs2!, pow!, exp!, log!,
		floor!, ceil!, round!, trunc!,

		absdiff, sqrdiff, fma, fma!,

		# vbroadcast
		vbroadcast, vbroadcast!,
		badd, badd!, bsubtract, bsubtract!, bmultiply, bmultiply!, bdivide, bdivide!,

		# vreduce
		reduce, reduce!, reduce_fdiff, reduce_fdiff!,
		sum!, max!, min!, nonneg_max, nonneg_max!,
		asum, asum!, amax, amax!, amin, amin!, sqsum, sqsum!,  
		dot!, adiffsum, adiffsum!, sqdiffsum, sqdiffsum!,
		adiffmax, adiffmax!, adiffmin, adiffmin!,  
		vnorm, vnorm!, vdiffnorm, vdiffnorm!,

		# benchmark
		BenchmarkTable, nrows, ncolumns, add_row!


	include("functors.jl")
	include("codegen.jl")
	include("map.jl")
	include("vbroadcast.jl")
	include("reduce.jl")

	include("benchmark.jl")

end
