# reduction


#################################################
#
#    Folding
#
#################################################

macro compose_foldfuns(AN, foldlf, foldrf)
    # argument preparation

    _foldlf = symbol("_$(foldlf)")
    _foldrf = symbol("_$(foldrf)")

    h = codegen_helper(AN)
    aparams = h.contiguous_aparams
    args = h.args
    ti = h.term(:i)
    t1 = h.term(1)
    tn = h.term(:n)

    # code skeletons

    quote
        # foldl & foldr

        global $_foldlf 
        function $(_foldlf)(ifirst::Int, ilast::Int, op::Functor{2}, s::Number, $(aparams...))
            i = ifirst
            while i <= ilast
                @inbounds vi = $(ti)
                s = evaluate(op, s, vi)
                i += 1
            end
            return s
        end

        global $foldlf
        $(foldlf)(op::Functor{2}, s::Number, $(aparams...)) = $(_foldlf)(1, $(h.inputlen), op, s, $(args...))
        function $(foldlf)(op::Functor{2}, $(aparams...)) 
            n = $(h.inputlen)
            n > 0 || error("Empty argument not allowed.")
            s = $(t1)
            $(_foldlf)(2, n, op, s, $(args...))
        end

        global $_foldrf
        function $(_foldrf)(ifirst::Int, ilast::Int, op::Functor{2}, s::Number, $(aparams...))
            i = ilast
            while i >= ifirst
                @inbounds vi = $(ti)
                s = evaluate(op, vi, s)
                i -= 1
            end
            return s
        end

        global $foldrf
        $(foldrf)(op::Functor{2}, s::Number, $(aparams...)) = $(_foldrf)(1, $(h.inputlen), op, s, $(args...))
        function $(foldrf)(op::Functor{2}, $(aparams...))
            n = $(h.inputlen)
            n > 0 || error("Empty argument not allowed.")
            s = $(tn)
            $(_foldrf)(1, n-1, op, s, $(args...))
        end

    end
end

@compose_foldfuns 0 foldl foldr
@compose_foldfuns 1 foldl foldr
@compose_foldfuns 2 foldl foldr
@compose_foldfuns 3 foldl foldr
@compose_foldfuns (-2) foldl_fdiff foldr_fdiff


#################################################
#
#    Sum, Maximum, Minimum, and Mean
#
#################################################

macro compose_mapreduce_funs(rf, rfdiff, OT)
    quote
        global $(rf)
        $(rf)(fun::Functor{1}, a::ContiguousNumericArray) = 
            (n = length(a); n > 0 ? saccum($OT, n, fun, a, 1) : 
                                    init($OT, result_type(fun, eltype(a))))

        function $(rf)(fun::Functor{2}, a::ContiguousArrOrNum, b::ContiguousArrOrNum)
            n = maplength(a, b); 
            n > 0 ? saccum($OT, n, fun, a, 1, b, 1) : 
                    init($OT, result_type(fun, eltype(a), eltype(b)))
        end

        function $(rf)(fun::Functor{3}, a::ContiguousArrOrNum, b::ContiguousArrOrNum, c::ContiguousArrOrNum)
            n = maplength(a, b, c); 
            n > 0 ? saccum($OT, n, fun, a, 1, b, 1, c, 1) : 
                    init($OT, result_type(fun, eltype(a), eltype(b), eltype(c)))
        end

        global $(rfdiff)
        function $(rfdiff)(fun::Functor{1}, a::ContiguousArrOrNum, b::ContiguousArrOrNum)
            n = maplength(a, b); 
            n > 0 ? saccum_fdiff($OT, n, fun, a, 1, b, 1) : 
                    init($OT, result_type(fun, promote_type(eltype(a), eltype(b))))
        end
    end
end

@compose_mapreduce_funs sum sumfdiff Sum
@compose_mapreduce_funs maximum maxfdiff Maximum
@compose_mapreduce_funs minimum minfdiff Minimum
@compose_mapreduce_funs nonneg_maximum nonneg_maxfdiff NonnegMaximum

mean(fun::Functor{1}, a::ContiguousNumericArray) = sum(fun, a) / length(a)
mean(fun::Functor{2}, a::ContiguousArrOrNum, b::ContiguousArrOrNum) = 
    sum(fun, a, b) / maplength(a, b)
mean(fun::Functor{3}, a::ContiguousArrOrNum, b::ContiguousArrOrNum, c::ContiguousArrOrNum) = 
    sum(fun, a, b, c) / maplength(a, b, c)
meanfdiff(fun::Functor{1}, a::ContiguousArrOrNum, b::ContiguousArrOrNum) = 
    sumfdiff(fun, a, b) / maplength(a, b)


#################################################
#
#    Derived functions
#
#################################################

sumabs{T<:Number}(a::ContiguousArray{T}) = sum(AbsFun(), a)
maxabs{T<:Number}(a::ContiguousArray{T}) = nonneg_maximum(AbsFun(), a)
minabs{T<:Number}(a::ContiguousArray{T}) = minimum(AbsFun(), a)
meanabs{T<:Number}(a::ContiguousArray{T}) = mean(AbsFun(), a)

sumsq{T<:Real}(a::ContiguousArray{T}) = sum(Abs2Fun(), a)
meansq{T<:Real}(a::ContiguousArray{T}) = mean(Abs2Fun(), a)
dot{T<:Real}(a::ContiguousArray{T}, b::ContiguousArray{T}) = sum(Multiply(), a, b)

sumabsdiff(a::ContiguousArrOrNum, b::ContiguousArrOrNum) = sumfdiff(AbsFun(), a, b)
maxabsdiff(a::ContiguousArrOrNum, b::ContiguousArrOrNum) = nonneg_maxfdiff(AbsFun(), a, b)
minabsdiff(a::ContiguousArrOrNum, b::ContiguousArrOrNum) = minfdiff(AbsFun(), a, b)
meanabsdiff(a::ContiguousArrOrNum, b::ContiguousArrOrNum) = meanfdiff(AbsFun(), a, b)

sumsqdiff(a::ContiguousArrOrNum, b::ContiguousArrOrNum) = sumfdiff(Abs2Fun(), a, b)
maxsqdiff(a::ContiguousArrOrNum, b::ContiguousArrOrNum) = nonneg_maxfdiff(Abs2Fun(), a, b)
minsqdiff(a::ContiguousArrOrNum, b::ContiguousArrOrNum) = minfdiff(Abs2Fun(), a, b)
meansqdiff(a::ContiguousArrOrNum, b::ContiguousArrOrNum) = meanfdiff(Abs2Fun(), a, b)

sumxlogx{T<:Real}(a::ContiguousArray{T}) = sum(XlogxFun(), a)
sumxlogy{T<:Real}(a::ContiguousArray{T}, b::ContiguousArray{T}) = sum(XlogyFun(), a, b)
entropy{T<:Real}(a::ContiguousArray{T}) = -sumxlogx(a)

