# reduce along dimensions

import ArrayViews: offset
offset(x::Number) = 0

## auxiliary functions

_rtup(siz::NTuple{1,Int}, d::Integer) = (d == 1 ? (true,) : (false,))
 
_rtup(siz::NTuple{2,Int}, d::Integer) = (d == 1 ? (false, true) :
                                         d == 2 ? (true, false) : 
                                                  (false, false) )
 
_rtup(siz::NTuple{3,Int}, d::Integer) = (d == 1 ? (false, false, true) :
                                         d == 2 ? (false, true, false) : 
                                         d == 3 ? (true, false, false) : 
                                                  (false, false, false))
 
_rtup{N}(siz::NTuple{N,Int}, d::Integer) = (ds = fill(false,N); ds[N+1-d]=true; tuple(ds...))::NTuple{N,Bool}
 
function _rtup{N}(siz::NTuple{N,Int}, dims::Union(Dims,Vector))
    ds = fill(false,N)
    for d in dims
        ds[N+1-d] = true
    end
    return tuple(ds...)::NTuple{N,Bool}
end


#################################################
#
#   main macro
#
#################################################

macro compose_reducedim(fun, OT, AN)
    # fun: the function name, e.g. sum
    # BT: the base type, e.g. Number, Real

    fun! = symbol(string(fun, '!'))
    _fun! = symbol(string('_', fun!))
    _funimpl! = symbol(string('_', fun, "impl!"))
    _funimpl1d! = symbol(string('_', fun, "impl1d!"))
    _funimpl2d! = symbol(string('_', fun, "impl2d!"))

    # code-gen preparation

    h = codegen_helper(AN)
    args = h.args
    aparams = h.dense_aparams

    saccumf = AN >= 0 ? :saccum : :saccum_fdiff
    paccumf! = AN >= 0 ? :paccum! : :paccum_fdiff!

    if AN == 0
        imparams1d = [:(a::ContiguousArray), :(ia::Int), :(sa1::Int)]
        imparams2d = [:(a::ContiguousArray), :(ia::Int), :(sa1::Int), :(sa2::Int)]
        imargs1d = [:(parent(a)), :ia, :sa1]
        imargs2d = [:(parent(a)), :ia, :sa1, :sa2]
        eviewargs = [:(ellipview(a, i))]
        getoffsets = :(ia = offset(a) + 1)
        getstrides1 = :(sa1 = stride(a, 1)::Int)
        getstrides2 = :(sa1 = stride(a, 1)::Int; sa2 = stride(a, 2)::Int)
        contcol = :(sa1 == 1)
        nextcol = :(ia += sa2)
        kargs = [:a, :ia]
        kargs1 = [:a, :ia, :sa1]
    elseif AN == 1
        imparams1d = [:(fun::Functor{1}), :(a::ContiguousArray), :(ia::Int), :(sa1::Int)]
        imparams2d = [:(fun::Functor{1}), :(a::ContiguousArray), :(ia::Int), :(sa1::Int), :(sa2::Int)]
        imargs1d = [:fun, :(parent(a)), :ia, :sa1]
        imargs2d = [:fun, :(parent(a)), :ia, :sa1, :sa2]
        eviewargs = [:fun, :(ellipview(a, i))]
        getoffsets = :(ia = offset(a) + 1)
        getstrides1 = :(sa1 = stride(a, 1)::Int)
        getstrides2 = :(sa1 = stride(a, 1)::Int; sa2 = stride(a, 2)::Int)
        contcol = :(sa1 == 1)
        nextcol = :(ia += sa2)
        kargs = [:fun, :a, :ia]
        kargs1 = [:fun, :a, :ia, :sa1]
    elseif AN == 2 || AN == -2
        FN = AN == 2 ? 2 : 1
        imparams1d = [:(fun::Functor{$FN}), :(a::ContiguousArrOrNum), :(ia::Int), :(sa1::Int), 
                                            :(b::ContiguousArrOrNum), :(ib::Int), :(sb1::Int)]
        imparams2d = [:(fun::Functor{$FN}), :(a::ContiguousArrOrNum), :(ia::Int), :(sa1::Int), :(sa2::Int), 
                                            :(b::ContiguousArrOrNum), :(ib::Int), :(sb1::Int), :(sb2::Int)]
        imargs1d = [:fun, :(parent(a)), :ia, :sa1, 
                          :(parent(b)), :ib, :sb1]
        imargs2d = [:fun, :(parent(a)), :ia, :sa1, :sa2, 
                          :(parent(b)), :ib, :sb1, :sb2]
        eviewargs = [:fun, :(ellipview(a, i)), :(ellipview(b, i))]
        getoffsets = :(ia = offset(a) + 1; 
                       ib = offset(b) + 1)
        getstrides1 = :(sa1 = stride(a, 1)::Int; 
                        sb1 = stride(b, 1)::Int)
        getstrides2 = :(sa1 = stride(a, 1)::Int; sa2 = stride(a, 2)::Int; 
                        sb1 = stride(b, 1)::Int; sb2 = stride(b, 2)::Int)
        contcol = :(sa1 == 1 && sb1 == 1)
        nextcol = :(ia += sa2; ib += sb2)
        kargs = [:fun, :a, :ia, :b, :ib]
        kargs1 = [:fun, :a, :ia, :sa1, :b, :ib, :sb1]
    elseif AN == 3
        imparams1d = [:(fun::Functor{3}), :(a::ContiguousArrOrNum), :(ia::Int), :(sa1::Int), 
                                          :(b::ContiguousArrOrNum), :(ib::Int), :(sb1::Int), 
                                          :(c::ContiguousArrOrNum), :(ic::Int), :(sc1::Int)]
        imparams2d = [:(fun::Functor{3}), :(a::ContiguousArrOrNum), :(ia::Int), :(sa1::Int), :(sa2::Int), 
                                          :(b::ContiguousArrOrNum), :(ib::Int), :(sb1::Int), :(sb2::Int), 
                                          :(c::ContiguousArrOrNum), :(ic::Int), :(sc1::Int), :(sc2::Int)]
        imargs1d = [:fun, :(parent(a)), :ia, :sa1, 
                          :(parent(b)), :ib, :sb1, 
                          :(parent(c)), :ic, :sc1]
        imargs2d = [:fun, :(parent(a)), :ia, :sa1, :sa2, 
                          :(parent(b)), :ib, :sb1, :sb2, 
                          :(parent(c)), :ic, :sc1, :sc2]
        eviewargs = [:fun, :(ellipview(a, i)), :(ellipview(b, i)), :(ellipview(c, i))]
        getoffsets = :(ia = offset(a) + 1; 
                       ib = offset(b) + 1; 
                       ic = offset(c) + 1)
        getstrides1 = :(sa1 = stride(a, 1)::Int; 
                        sb1 = stride(b, 1)::Int;
                        sc1 = stride(c, 1)::Int)
        getstrides2 = :(sa1 = stride(a, 1)::Int; sa2 = stride(a, 2)::Int; 
                        sb1 = stride(b, 1)::Int; sb2 = stride(b, 2)::Int; 
                        sc1 = stride(c, 1)::Int; sc2 = stride(c, 2)::Int)
        contcol = :(sa1 == 1 && sb1 == 1 && sc1 == 1)
        nextcol = :(ia += sa2; ib += sb2; ic += sc2)
        kargs = [:fun, :a, :ia, :b, :ib, :c, :ic]
        kargs1 = [:fun, :a, :ia, :sa1, :b, :ib, :sb1, :c, :ic, :sc1]
    else
        error("AN = $(AN) is unsupported.")
    end

    quote
        global $(_funimpl1d!)
        function $(_funimpl1d!)(r1::Bool, n::Int, 
                                dst::ContiguousArray, idst::Int, sdst1::Int, $(imparams1d...))
            if r1
                if $(contcol)
                    dst[1] = combine($OT, dst[1], $(saccumf)($OT, n, $(kargs...)))
                else
                    dst[1] = combine($OT, dst[1], $(saccumf)($OT, n, $(kargs1...)))
                end
            else
                if $(contcol) && (sdst1 == 1)
                    $(paccumf!)($OT, n, dst, idst, $(kargs...))
                else
                    $(paccumf!)($OT, n, dst, idst, sdst1, $(kargs1...))
                end
            end            
        end

        global $(_funimpl2d!)
        function $(_funimpl2d!)(r2::Bool, r1::Bool, m::Int, n::Int, 
                                dst::ContiguousArray, idst::Int, sdst1::Int, sdst2::Int, 
                                $(imparams2d...))
            if r1
                if r2
                    if $(contcol)
                        s = $(saccumf)($OT, m, $(kargs...))
                        $(nextcol)
                        for j = 2:n
                            s = combine($OT, s, $(saccumf)($OT, m, $(kargs...)))
                            $(nextcol)
                        end
                        dst[idst] = combine($OT, dst[idst], s)
                    else
                        s = $(saccumf)($OT, m, $(kargs1...))
                        $(nextcol)
                        for j = 2:n
                            s = combine($OT, s, $(saccumf)($OT, m, $(kargs1...)))
                            $(nextcol)
                        end
                        dst[idst] = combine($OT, dst[idst], s)
                    end
                else
                    if $(contcol)
                        for j = 1:n
                            dst[idst] = combine($OT, dst[idst], $(saccumf)($OT, m, $(kargs...)))
                            $(nextcol)
                            idst += sdst2
                        end
                    else
                        for j = 1:n
                            dst[idst] = combine($OT, dst[idst], $(saccumf)($OT, m, $(kargs1...)))
                            $(nextcol)
                            idst += sdst2
                        end
                    end
                end
            else
                if r2
                    if $(contcol) && sdst1 == 1
                        for j = 1:n
                            $(paccumf!)($OT, m, dst, idst, $(kargs...))
                            $(nextcol)
                        end
                    else
                        for j = 1:n
                            $(paccumf!)($OT, m, dst, idst, sdst1, $(kargs1...))
                            $(nextcol)
                        end
                    end
                else
                    if $(contcol) && sdst1 == 1
                        for j = 1:n
                            $(paccumf!)($OT, m, dst, idst, $(kargs...))
                            $(nextcol)
                            idst += sdst2
                        end
                    else
                        for j = 1:n
                            $(paccumf!)($OT, m, dst, idst, sdst1, $(kargs1...))
                            $(nextcol)
                            idst += sdst2
                        end
                    end
                end
            end            
        end

        global $(_funimpl!)
        function $(_funimpl!)(dst::DenseArray, $(aparams...), dim::Int, insiz::Dims, r1::Bool)
            n = insiz[1]::Int
            $(getstrides1)
            sdst1 = stride(dst, 1)::Int
            $(getoffsets)
            idst = offset(dst) + 1
            $(_funimpl1d!)(r1, n, parent(dst), idst, sdst1, $(imargs1d...))
        end

        function $(_funimpl!)(dst::DenseArray, $(aparams...), dim::Int, insiz::Dims, r2::Bool, r1::Bool)
            m = insiz[1]::Int
            n = insiz[2]::Int
            $(getstrides2)
            sdst1, sdst2 = strides(dst)::(Int, Int)         
            $(getoffsets)
            idst = offset(dst) + 1
            $(_funimpl2d!)(r2, r1, m, n, parent(dst), idst, sdst1, sdst2, $(imargs2d...))
        end

        function $(_funimpl!)(dst::DenseArray, $(aparams...), dim::Int, insiz::Dims, 
                              rN::Bool, rNm1::Bool, rNm2::Bool, rr::Bool...)
            n = insiz[dim]::Int
            if rN
                _dst = ellipview(dst, 1)
                for i = 1:n
                    $(_funimpl!)(_dst, $(eviewargs...), dim-1, insiz, rNm1, rNm2, rr...)
                end
            else
                for i = 1:n
                    $(_funimpl!)(ellipview(dst, i), $(eviewargs...), dim-1, insiz, rNm1, rNm2, rr...)
                end
            end
        end    
         
        global $(_fun!)
        function $(_fun!){S<:Number,N}(dst::DenseArray{S,N}, $(aparams...), insiz::NTuple{N,Int}, dims::DimSpec)
            $(_funimpl!)(dst, $(args...), length(insiz), insiz, _rtup(insiz, dims)...)
            return dst
        end

        global $(fun!)
        function $(fun!)(dst::ContiguousArray, $(aparams...), dims::DimSpec)
            insiz = $(h.inputsize)
            rsiz = Base.reduced_dims(insiz, dims)
            prod(rsiz) == length(dst) || throw(DimensionMismatch("Incorrect size of dst."))
            $(_fun!)(contiguous_view(dst, rsiz), $(args...), insiz, dims)
        end

        global $(fun)
        function $(fun)($(aparams...), dims::DimSpec)
            insiz = $(h.inputsize)
            dst = fill(init($OT, $(h.termtype)), Base.reduced_dims(insiz,dims))
            $(_fun!)(dst, $(args...), insiz, dims)
        end
    end
end 
 

#################################################
#
#   basic functions
#
#################################################

@compose_reducedim sum Sum 0
@compose_reducedim sum Sum 1
@compose_reducedim sum Sum 2
@compose_reducedim sum Sum 3
@compose_reducedim sumfdiff Sum (-2)

@compose_reducedim maximum Maximum 0
@compose_reducedim maximum Maximum 1
@compose_reducedim maximum Maximum 2
@compose_reducedim maximum Maximum 3
@compose_reducedim maxfdiff Maximum (-2)

@compose_reducedim minimum Minimum 0
@compose_reducedim minimum Minimum 1
@compose_reducedim minimum Minimum 2
@compose_reducedim minimum Minimum 3
@compose_reducedim minfdiff Minimum (-2)

@compose_reducedim nonneg_maximum NonnegMaximum 0
@compose_reducedim nonneg_maximum NonnegMaximum 1
@compose_reducedim nonneg_maximum NonnegMaximum 2
@compose_reducedim nonneg_maximum NonnegMaximum 3
@compose_reducedim nonneg_maxfdiff NonnegMaximum (-2)

_rlen(siz::Dims, d::Int) = siz[d]
_rlen(siz::Dims, reg::(Int,Int)) = siz[reg[1]] * siz[reg[2]]
function _rlen(siz::Dims, reg::Dims) 
    p = 1
    for d in reg
        p *= siz[d]
    end
    return p::Int
end

macro compose_meandim(meanf, sumf, AN)
    sumf! = symbol(string(sumf, '!'))
    meanf! = symbol(string(meanf, '!'))
    h = codegen_helper(AN)
    aparams = h.dense_aparams
    args = h.args

    quote
        global $(meanf!)
        function $(meanf!)(r::NumericArray, $(aparams...), dims::DimSpec)
            siz = $(h.inputsize)
            scale!($(sumf!)(fill!(r, 0.0), $(args...), dims), inv(_rlen(siz, dims)))
        end

        global $(meanf)
        function $(meanf)($(aparams...), dims::DimSpec) 
            siz = $(h.inputsize)
            scale!($(sumf)($(args...), dims), inv(_rlen(siz, dims)))
        end
    end
end

@compose_meandim mean sum 0
@compose_meandim mean sum 1
@compose_meandim mean sum 2
@compose_meandim mean sum 3
@compose_meandim meanfdiff sumfdiff (-2)

#################################################
#
#   derived functions
#
#################################################

macro mapreducedim_fun1(fname, accum, F, BT)
    fname! = symbol("$(fname)!")
    accum! = symbol("$(accum)!")

    quote
        global $(fname)
        $(fname){T<:$(BT)}(a::DenseArray{T}, dims::DimSpec) = $(accum)(($F)(), a, dims)

        global $(fname!)
        $(fname!){T<:$(BT)}(dst::DenseArray, a::DenseArray{T}, dims::DimSpec) = 
            $(accum!)(dst, ($F)(), a, dims) 
    end
end

macro mapreducedim_fun2(fname, accum, F, BT)
    fname! = symbol("$(fname)!")
    accum! = symbol("$(accum)!")

    quote
        global $(fname)
        $(fname){TA<:$(BT),TB<:$(BT)}(a::DenseArrOrNum{TA}, b::DenseArrOrNum{TB}, dims::DimSpec) = 
            $(accum)(($F)(), a, b, dims)

        global $(fname!)
        $(fname!){TA<:$(BT),TB<:$(BT)}(dst::DenseArray, a::DenseArrOrNum{TA}, b::DenseArrOrNum{TB}, dims::DimSpec) = 
            $(accum!)(dst, ($F)(), a, b, dims) 
    end
end


# derived functions

@mapreducedim_fun1 sumabs sum AbsFun Number
@mapreducedim_fun1 meanabs mean AbsFun Number
@mapreducedim_fun1 maxabs nonneg_maximum AbsFun Number
@mapreducedim_fun1 minabs minimum AbsFun Number

@mapreducedim_fun1 sumsq sum Abs2Fun Number
@mapreducedim_fun1 meansq mean Abs2Fun Number

@mapreducedim_fun2 sumabsdiff sumfdiff AbsFun Number
@mapreducedim_fun2 meanabsdiff meanfdiff AbsFun Number
@mapreducedim_fun2 maxabsdiff nonneg_maxfdiff AbsFun Number
@mapreducedim_fun2 minabsdiff minfdiff AbsFun Number

@mapreducedim_fun2 sumsqdiff sumfdiff Abs2Fun Number
@mapreducedim_fun2 meansqdiff meanfdiff Abs2Fun Number

@mapreducedim_fun2 dot sum Multiply Real

@mapreducedim_fun1 sumxlogx sum XlogxFun Real
@mapreducedim_fun2 sumxlogy sum XlogyFun Real

entropy{T<:Real}(a::DenseArray{T}, dims::DimSpec) = negate!(sumxlogx(a, dims))
entropy!{T<:Real}(r::DenseArray{T}, a::ContiguousRealArray, dims::DimSpec) = negate!(sumxlogx!(r, a, dims))


