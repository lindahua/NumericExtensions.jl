module NumericExtensions

	import 
		# size information
		Base.size, Base.length, Base.ndims, Base.isempty,

		# iteration and indexing
		Base.start, Base.next, Base.done, Base.getindex, Base.setindex!,

		# common operations
		Base.show, Base.add!, Base.copy, Base.similar, Base.pointer,

		# higher-level map & reduction functions to be extended
		Base.map, Base.map!, Base.reduce, Base.mapreduce,

		# arithmetic functions
		Base.+, Base.*, Base.\, Base./,

		# reduction functions to be extended
		Base.sum, Base.prod, Base.max, Base.min, Base.dot, 
		Base.cumsum, Base.cummax, Base.cummin, Base.cumprod,
		Base.norm, Base.LinAlg.BLAS.asum,

		# statistics
		Base.mean, Base.var, Base.varm, Base.std, Base.stdm,

		# matrix related
		Base.logdet, Base.full, Base.inv, Base.diag, Base.diagm


	export 
		# views
		AbstractUnsafeView, UnsafeVectorView, UnsafeMatrixView, UnsafeCubeView,
		ContiguousArray, ContiguousVector, ContiguousMatrix, ContiguousCube,
		unsafe_view,

		# mathfuns
		sqr, rcp, rsqrt, rcbrt,

		# extree
		extree

		# # map
		# map, map!, map1!, mapdiff, mapdiff!,

		# add!, subtract!, multiply!, divide!, negate!, rcp!, 
		# sqrt!, abs!, abs2!, pow!, exp!, log!,
		# floor!, ceil!, round!, trunc!,

		# absdiff, sqrdiff, fma, fma!,

		# # vbroadcast
		# vbroadcast, vbroadcast!, vbroadcast1!,
		# badd, badd!, bsubtract, bsubtract!, bmultiply, bmultiply!, bdivide, bdivide!,

		# # diagop
		# add_diag!, add_diag, set_diag!, set_diag,

		# # reduce
		# reduce!, mapreduce!, mapdiff_reduce, mapdiff_reduce!,
		# sum!, sumfdiff, sumfdiff!,
		# max!, maxfdiff, maxfdiff!,
		# min!, minfdiff, minfdiff!,
		# sumabs, sumabs!, maxabs, maxabs!, minabs, minabs!, sumsq, sumsq!, asum,
		# dot!, sumabsdiff, sumabsdiff!, sumsqdiff, sumsqdiff!,
		# maxabsdiff, maxabsdiff!, minabsdiff, minabsdiff!,  
		# sumxlogx, sumxlogx!, sumxlogy, sumxlogy!, 

		# # norms
		# vnorm, vnorm!, vnormdiff, vnormdiff!, normalize, normalize!,

		# # scan
		# scan, scan!, mapscan, mapscan!, 
		# cumsum!, cummax!, cummin!,

		# # statistics
		# mean!, meanabs, meanabs!, meansq, meansq!,
		# meanfdiff, meanfdiff!, meanabsdiff, meanabsdiff!, meansqdiff, meansqdiff!,
		# var!, varm!, std!, stdm!, entropy, entropy!,
		# logsumexp, logsumexp!, softmax, softmax!,

		# # weightsum
		# wsum, wsum!, wsumfdiff, wsumfdiff!,
		# wsumabs, wsumabs!, wsumabsdiff, wsumabsdiff!,
		# wsumsq, wsumsq!, wsumsqdiff, wsumsqdiff!,

		# # utils
		# eachrepeat, sortindexes, groupindexes,

		# # pdmat
  #       AbstractPDMat, PDMat, PDiagMat, ScalMat, 
  #       dim, full, whiten, whiten!, unwhiten, unwhiten!, add_scal!, add_scal,
  #       quad, quad!, invquad, invquad!, X_A_Xt, Xt_A_X, X_invA_Xt, Xt_invA_X,
  #       unwhiten_winv!, unwhiten_winv,

		# # benchmark
		# BenchmarkTable, nrows, ncolumns, add_row!


	# codes

	include("common.jl")
	include("unsafe_views.jl")
	include("mathfuns.jl")
	include("extree.jl")
	
	# include("codegen.jl")
	# include("map.jl")
	# include("vbroadcast.jl")
	# include("diagop.jl")
	# include("reduce.jl")
	# include("norms.jl")
	# include("scan.jl")
	# include("statistics.jl")
	# include("weightsum.jl")

	# include("utils.jl")

	# include("pdmat.jl")

	# include("benchmark.jl")

	# include("deprecates.jl")
end
