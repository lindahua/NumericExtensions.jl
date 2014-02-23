# reduce along dimensions

import ArrayViews: offset
offset(x::Number) = 0

## auxiliary functions

reducindicators(siz::NTuple{1,Int}, d::Integer) = (d == 1 ? (true,) : (false,))
 
reducindicators(siz::NTuple{2,Int}, d::Integer) = (d == 1 ? (true, false) :
                                                   d == 2 ? (false, true) : (false, false))
 
reducindicators(siz::NTuple{3,Int}, d::Integer) = (d == 1 ? (true, false, false) :
                                                   d == 2 ? (false, true, false) : 
                                                   d == 3 ? (false, false, true) : (false, false, false))
 
reducindicators{N}(siz::NTuple{N,Int}, d::Integer) = (ds = fill(false,N); ds[d]=true; tuple(ds...))::NTuple{N,Bool}
 
function reducindicators{N}(siz::NTuple{N,Int}, dims::Union(Dims,Vector))
    ds = fill(false,N)
    for d in dims
        ds[d] = true
    end
    return tuple(ds...)::NTuple{N,Bool}
end


#################################################
#
#   main macro
#
#################################################

macro compose_reducedim(fun, AN)
    # fun: the function name, e.g. sum
    # BT: the base type, e.g. Number, Real

    fun! = symbol(string(fun, '!'))
    _fun! = symbol(string('_', fun!))
    _funimpl! = symbol(string('_', fun, "impl!"))
    _funimpl1d! = symbol(string('_', fun, "impl1d!"))
    _funimpl2d! = symbol(string('_', fun, "impl2d!"))

    # code-gen preparation

    h = codegen_helper(AN)
    he = codegen_helper_ex(AN)
    args = h.args
    aparams = h.dense_aparams

    if AN == 0
        interf_params = [:(op::Functor{2}), aparams...]
    else
        interf_params = [aparams[1], :(op::Functor{2}), aparams[2:end]...]
    end

    saccumf = AN >= 0 ? :saccum : :saccum_fdiff
    paccumf! = AN >= 0 ? :paccum! : :paccum_fdiff!


    quote
        global $(_funimpl1d!)
        function $(_funimpl1d!){Op<:Functor{2}}(op::Op, r1::Bool, n::Int, 
                                                dst::ContiguousArray, idst::Int, sdst1::Int, 
                                                $(he.imparams1d...))
            if r1
                if $(he.contcol)
                    dst[1] = evaluate(op, dst[1], $(saccumf)(op, n, $(he.kerargs...)))
                else
                    dst[1] = evaluate(op, dst[1], $(saccumf)(op, n, $(he.kerargs1...)))
                end
            else
                if $(he.contcol) && (sdst1 == 1)
                    $(paccumf!)(op, n, dst, idst, $(he.kerargs...))
                else
                    $(paccumf!)(op, n, dst, idst, sdst1, $(he.kerargs1...))
                end
            end            
        end

        global $(_funimpl2d!)
        function $(_funimpl2d!){Op<:Functor{2}}(op::Op, r2::Bool, r1::Bool, m::Int, n::Int, 
                                                dst::ContiguousArray, idst::Int, sdst1::Int, sdst2::Int, 
                                                $(he.imparams2d...))
            if r1
                if r2
                    if $(he.contcol)
                        s = $(saccumf)(op, m, $(he.kerargs...))
                        $(he.nextcol)
                        for j = 2:n
                            s = evaluate(op, s, $(saccumf)(op, m, $(he.kerargs...)))
                            $(he.nextcol)
                        end
                        dst[idst] = evaluate(op, dst[idst], s)
                    else
                        s = $(saccumf)(op, m, $(he.kerargs1...))
                        $(he.nextcol)
                        for j = 2:n
                            s = evaluate(op, s, $(saccumf)(op, m, $(he.kerargs1...)))
                            $(he.nextcol)
                        end
                        dst[idst] = evaluate(op, dst[idst], s)
                    end
                else
                    if $(he.contcol)
                        for j = 1:n
                            dst[idst] = evaluate(op, dst[idst], $(saccumf)(op, m, $(he.kerargs...)))
                            $(he.nextcol)
                            idst += sdst2
                        end
                    else
                        for j = 1:n
                            dst[idst] = evaluate(op, dst[idst], $(saccumf)(op, m, $(he.kerargs1...)))
                            $(he.nextcol)
                            idst += sdst2
                        end
                    end
                end
            else
                if r2
                    if $(he.contcol) && sdst1 == 1
                        for j = 1:n
                            $(paccumf!)(op, m, dst, idst, $(he.kerargs...))
                            $(he.nextcol)
                        end
                    else
                        for j = 1:n
                            $(paccumf!)(op, m, dst, idst, sdst1, $(he.kerargs1...))
                            $(he.nextcol)
                        end
                    end
                else
                    if $(he.contcol) && sdst1 == 1
                        for j = 1:n
                            $(paccumf!)(op, m, dst, idst, $(he.kerargs...))
                            $(he.nextcol)
                            idst += sdst2
                        end
                    else
                        for j = 1:n
                            $(paccumf!)(op, m, dst, idst, sdst1, $(he.kerargs1...))
                            $(he.nextcol)
                            idst += sdst2
                        end
                    end
                end
            end            
        end

        global $(_funimpl!)
        function $(_funimpl!){Op<:Functor{2},N}(op::Op, dst::DenseArray, $(aparams...), dim::Int, 
                                                insiz::NTuple{N,Int}, rtup::NTuple{N,Bool})

            if dim == 1
                n = insiz[1]::Int
                $(he.getstrides1)
                sdst1 = stride(dst, 1)::Int
                $(he.getoffsets)
                idst = offset(dst) + 1
                $(_funimpl1d!)(op, rtup[1], n, parent(dst), idst, sdst1, $(he.imargs1d...))

            elseif dim == 2
                m = insiz[1]::Int
                n = insiz[2]::Int
                $(he.getstrides2)
                sdst1, sdst2 = strides(dst)::(Int, Int)
                $(he.getoffsets)
                idst = offset(dst) + 1
                $(_funimpl2d!)(op, rtup[2], rtup[1], m, n, parent(dst), idst, sdst1, sdst2, $(he.imargs2d...))

            else
                n = insiz[dim]::Int
                if rtup[dim]
                    _dst = ellipview(dst, 1)
                    for i = 1:n
                        $(_funimpl!)(op, _dst, $(he.eviewargs...), dim-1, insiz, rtup)
                    end
                else
                    for i = 1:n
                        $(_funimpl!)(op, ellipview(dst, i), $(he.eviewargs...), dim-1, insiz, rtup)
                    end
                end
            end
        end    
         
        global $(_fun!)
        function $(_fun!){S<:Number,N}(dst::DenseArray{S,N}, op::Functor{2}, $(aparams...), insiz::NTuple{N,Int}, dims::DimSpec)
            $(_funimpl!)(op, dst, $(args...), length(insiz), insiz, reducindicators(insiz, dims))
            return dst
        end

        global $(fun!)
        function $(fun!)(dst::ContiguousArray, $(interf_params...), dims::DimSpec)
            insiz = $(h.inputsize)
            rsiz = Base.reduced_dims(insiz, dims)
            prod(rsiz) == length(dst) || throw(DimensionMismatch("Incorrect size of dst."))
            $(_fun!)(contiguous_view(dst, rsiz), op, $(args...), insiz, dims)
            return dst
        end

        global $(fun)
        function $(fun)($(interf_params...), dims::DimSpec)
            insiz = $(h.inputsize)
            dst = fill(reduceinit(op, $(h.termtype)), Base.reduced_dims(insiz,dims))
            $(_fun!)(dst, op, $(args...), insiz, dims)
        end
    end
end 
 
@compose_reducedim reducedim 0
@compose_reducedim mapreducedim 1
@compose_reducedim mapreducedim 2
@compose_reducedim mapreducedim 3
@compose_reducedim mapreducedim_fdiff (-2)

#################################################
#
#   basic functions
#
#################################################

sum(a::BitArray, dims::DimSpec) = invoke(sum, (BitArray, Any), a, dims)

macro compose_reducedim_basicfuns(fname, fdiff, OT)
    fname! = symbol(string(fname, '!'))
    fdiff! = symbol(string(fdiff, '!'))

    quote
        global $(fname!)
        $(fname!)(dst::DenseArray, a::NumericArray, dims::DimSpec) = reducedim!(dst, $(OT)(), a, dims)
        $(fname!)(dst::DenseArray, fun::Functor{1}, a::NumericArray, dims::DimSpec) = 
            mapreducedim!(dst, fun, $(OT)(), a, dims)
        $(fname!)(dst::DenseArray, fun::Functor{2}, a::DenseArrOrNum, b::DenseArrOrNum, dims::DimSpec) = 
            mapreducedim!(dst, fun, $(OT)(), a, b, dims)
        $(fname!)(dst::DenseArray, fun::Functor{3}, a::DenseArrOrNum, b::DenseArrOrNum, c::DenseArrOrNum, dims::DimSpec) = 
            mapreducedim!(dst, fun, $(OT)(), a, b, c, dims)

        global $(fdiff!)
        $(fdiff!)(dst::DenseArray, fun::Functor{1}, a::DenseArrOrNum, b::DenseArrOrNum, dims::DimSpec) = 
            mapreducedim_fdiff!(dst, fun, $(OT)(), a, b, dims)

        global $(fname)
        $(fname)(a::NumericArray, dims::DimSpec) = reducedim($(OT)(), a, dims)
        $(fname)(fun::Functor{1}, a::NumericArray, dims::DimSpec) = mapreducedim(fun, $(OT)(), a, dims)
        $(fname)(fun::Functor{2}, a::DenseArrOrNum, b::DenseArrOrNum, dims::DimSpec) = 
            mapreducedim(fun, $(OT)(), a, b, dims)
        $(fname)(fun::Functor{3}, a::DenseArrOrNum, b::DenseArrOrNum, c::DenseArrOrNum, dims::DimSpec) = 
            mapreducedim(fun, $(OT)(), a, b, c, dims)

        global $(fdiff)
        $(fdiff)(fun::Functor{1}, a::DenseArrOrNum, b::DenseArrOrNum, dims::DimSpec) = 
            mapreducedim_fdiff(fun, $(OT)(), a, b, dims)
    end
end

@compose_reducedim_basicfuns sum sumfdiff Add 
@compose_reducedim_basicfuns maximum maxfdiff _Max
@compose_reducedim_basicfuns minimum minfdiff _Min
@compose_reducedim_basicfuns nonneg_maximum nonneg_maxfdiff NonnegMax


# avoid the ambiguities with BitArrays

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

