module NumericExtensions

    warn("""
    A majority of the functionalities implemented in this package has been available & optimized in Julia Base.
    This package is no longer actively developed (except for occasional bugfixes).
    Please consider removing the dependency on NumericExtensions and using the functions in JuliaBase instead.""")

    using ArrayViews
    using NumericFuns
    using Compat

    # size information
    import Base: size, length, ndims, isempty, stride

    # iteration and indexing
    import Base: start, next, done, getindex, setindex!

    # common operations
    import Base: show, copy, similar, pointer, parent, diagm

    # higher-level map & reduction functions to be extended
    import Base: map, map!, reduce, reducedim, mapreduce, foldl, foldr

    # arithmetic functions
    import Base: +, *, \, /, ==

    # reduction functions to be extended
    import Base: sum, sum!, prod, prod!, maximum, maximum!, minimum, minimum!, dot, norm

    # scan functions to be extended
    import Base: cumsum, cumsum!, cummax, cummin, cumprod

    # statistics
    import Base: mean, mean!, var, varm, std, stdm

    # from ArrayViews
    import ArrayViews: view, ellipview

    # from NumericFuns
    import NumericFuns: evaluate, result_type, logsumexp

    export 
        # reexport views
        view, ellipview,

        # re-export functor-related methods
        fptype, arithtype, evaluate, result_type,

        # re-export mathfuns
        sqr, rcp, rsqrt, rcbrt, xlogx, xlogy, 
        sigmoid, logit, softplus, invsoftplus, logsumexp,

        # shapes
        mapshape, maplength,

        # views
        view, unsafe_view,

        # mathfuns
         
        logit, xlogx, xlogy, logistic, invlogistic, softplus, invsoftplus,

        # functors
        Functor, @functor1, @functor2, evaluate, fptype,

        # map
        map, map!, map1!, mapdiff, mapdiff!, 
        add!, subtract!, multiply!, divide!, negate!, rcp!, 
        sqrt!, abs!, sqr!, abs2!, pow!, exp!, log!,
        floor!, ceil!, round!, trunc!,
        absdiff, absdiff!, sqrdiff, sqrdiff!, fma, fma!,

        # vbroadcast
        vbroadcast, vbroadcast!, vbroadcast1!,
        badd, badd!, bsubtract, bsubtract!, bmultiply, bmultiply!, bdivide, bdivide!,

        # diagop
        add_diag!, add_diag, set_diag!, set_diag,

        # reduce
        mapreduce_fdiff, sumfdiff, maxfdiff, minfdiff, meanfdiff, 
        sumabs, maxabs, minabs, meanabs, sumsq, meansq,
        sumabsdiff, maxabsdiff, minabsdiff, meanabsdiff,        
        sumsqdiff, meansqdiff, sumxlogx, sumxlogy, entropy,

        foldl_fdiff, foldr_fdiff,

        # reducedim
        reducedim!, mapreducedim, mapreducedim!, mapreducedim_fdiff, mapreducedim_fdiff!, 
        foldl!, foldr!, sum!, maximum!, minimum!, mean!, dot!,

        sumfdiff!, maxfdiff!, minfdiff!, meanfdiff!,
        sumabs!, maxabs!, minabs!, meanabs!, sumsq!, meansq!,
        sumabsdiff!, maxabsdiff!, minabsdiff!, meanabsdiff!,
        sumsqdiff!, meansqdiff!, sumxlogx!, sumxlogy!, entropy!,

        # norms
        vnorm, vnorm!, vnormdiff, vnormdiff!, normalize, normalize!,

        # scan
        scan, scan!, mapscan, mapscan!, 
        cumsum!, cummax!, cummin!,

        # statistics
        var!, varm!, std!, stdm!, 
        logsumexp, logsumexp!, softmax, softmax!,

        # weightsum
        wsum, wsum!, wsumfdiff, wsumfdiff!,
        wsumabs, wsumabs!, wsumabsdiff, wsumabsdiff!,
        wsumsq, wsumsq!, wsumsqdiff, wsumsqdiff!,

        # utils
        eachrepeat, sortindexes, groupindexes,

        # benchmark
        BenchmarkTable, nrows, ncolumns, add_row!


    # codes

    include("common.jl")
    include("shapes.jl")
    include("codegen.jl")

    include("mapkernels.jl")
    include("map.jl")
    
    include("vbroadcast.jl")
    include("diagop.jl")
    include("utils.jl")

    include("rkernels.jl")
    include("reduce.jl")
    include("folddim.jl")
    include("reducedim.jl")

    include("norms.jl")
    include("scan.jl")
    include("statistics.jl")
    include("wsum.jl")

    include("benchmark.jl")

    include("deprecates.jl")
end
