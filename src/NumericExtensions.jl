module NumericExtensions

    using ArrayViews

    import 
        # size information
        Base.size, Base.length, Base.ndims, Base.isempty, Base.stride,

        # iteration and indexing
        Base.start, Base.next, Base.done, Base.getindex, Base.setindex!,

        # common operations
        Base.show, Base.add!, Base.copy, Base.similar, Base.pointer, Base.parent,

        # higher-level map & reduction functions to be extended
        Base.map, Base.map!, Base.reduce, Base.reducedim, Base.mapreduce, Base.foldl, Base.foldr,

        # arithmetic functions
        Base.+, Base.*, Base.\, Base./, Base.==,

        # reduction functions to be extended
        Base.sum, Base.prod, Base.maximum, Base.minimum, Base.dot, 
        Base.cumsum, Base.cummax, Base.cummin, Base.cumprod,
        Base.norm, 

        Base.sum!, Base.maximum!, Base.minimum!,

        # statistics
        Base.mean, Base.var, Base.varm, Base.std, Base.stdm,

        # matrix related
        Base.logdet, Base.full, Base.inv, Base.diag, Base.diagm,

        # view
        ArrayViews.view, ArrayViews.ellipview, ArrayViews.offset

    export 
        # reexport views
        view, ellipview,

        # shapes
        mapshape, maplength,

        # views
        view, unsafe_view,

        # mathfuns
        sqr, rcp, rsqrt, rcbrt, 
        logit, xlogx, xlogy, logistic, invlogistic, softplus, invsoftplus,

        # functors
        Functor, @functor1, @functor2, evaluate, fptype,

        # map
        map, map!, map1!, mapdiff, mapdiff!, 
        add!, subtract!, multiply!, divide!, negate!, rcp!, 
        sqrt!, abs!, sqr!, abs2!, pow!, exp!, log!,
        floor!, ceil!, round!, trunc!,
        absdiff, sqrdiff, fma, fma!,

        # vbroadcast
        vbroadcast, vbroadcast!, vbroadcast1!,
        badd, badd!, bsubtract, bsubtract!, bmultiply, bmultiply!, bdivide, bdivide!,

        # diagop
        add_diag!, add_diag, set_diag!, set_diag,

        # transforms
        Transpose, LinearTransform, AffineTransform, 
        transform, transform!,

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

        # pdmat
        AbstractPDMat, PDMat, PDiagMat, ScalMat, 
        dim, full, whiten, whiten!, unwhiten, unwhiten!, add_scal!, add_scal,
        quad, quad!, invquad, invquad!, X_A_Xt, Xt_A_X, X_invA_Xt, Xt_invA_X,
        unwhiten_winv!, unwhiten_winv,

        # benchmark
        BenchmarkTable, nrows, ncolumns, add_row!


    # codes

    include("common.jl")
    include("shapes.jl")
    include("mathfuns.jl")
    include("functors.jl")
    include("codegen.jl")
    include("map.jl")
    
    include("vbroadcast.jl")
    include("diagop.jl")
    include("utils.jl")
    include("transforms.jl")

    include("rkernels.jl")
    include("reduce.jl")
    include("folddim.jl")
    include("reducedim.jl")

    include("norms.jl")
    include("scan.jl")
    include("statistics.jl")
    # include("wsum.jl")

    # include("pdmat.jl")

    include("benchmark.jl")

    include("deprecates.jl")
end
