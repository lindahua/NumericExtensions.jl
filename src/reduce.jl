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

# init value

reduceinit{T<:Number}(::Add, ::Type{T}) = zero(T)
reduceinit{T<:Unsigned}(::Add, ::Type{T}) = uint(0)
reduceinit{T<:Signed}(::Add, ::Type{T}) = 0
reduceinit(::Add, ::Type{Int64}) = int64(0)
reduceinit(::Add, ::Type{Uint64}) = uint64(0)
reduceinit(::Add, ::Type{Int128}) = int128(0)
reduceinit(::Add, ::Type{Uint128}) = uint128(0)
reduceinit(::Add, ::Type{Bool}) = 0

reduceinit{T<:Real}(::_Max, ::Type{T}) = typemin(T)
reduceinit{T<:Real}(::_Min, ::Type{T}) = typemax(T)
reduceinit{T<:Real}(::NonnegMax, ::Type{T}) = zero(T)

# functions

function reduce{T<:Number}(op::Functor{2}, a::ContiguousNumericArray{T})
    n = length(a)
    n > 0 ? saccum(op, n, a, 1) : reduceinit(op, T)
end

function mapreduce(fun::Functor{1}, op::Functor{2}, a::ContiguousNumericArray)
    n = length(a)
    n > 0 ? saccum(op, n, fun, a, 1) : reduceinit(op, result_type(fun, eltype(a)))
end

function mapreduce(fun::Functor{2}, op::Functor{2}, a::ContiguousArrOrNum, b::ContiguousArrOrNum)
    n = maplength(a, b); 
    n > 0 ? saccum(op, n, fun, a, 1, b, 1) : 
            reduceinit(op, result_type(fun, eltype(a), eltype(b)))
end

function mapreduce(fun::Functor{3}, op::Functor{2}, a::ContiguousArrOrNum, b::ContiguousArrOrNum, c::ContiguousArrOrNum)
    n = maplength(a, b, c); 
    n > 0 ? saccum(op, n, fun, a, 1, b, 1, c, 1) : 
            reduceinit(op, result_type(fun, eltype(a), eltype(b), eltype(c)))
end

function mapreduce_fdiff(fun::Functor{1}, op::Functor{2}, a::ContiguousArrOrNum, b::ContiguousArrOrNum)
    n = maplength(a, b); 
    n > 0 ? saccum_fdiff(op, n, fun, a, 1, b, 1) : 
            reduceinit(op, result_type(fun, promote_type(eltype(a), eltype(b))))
end


macro compose_mapreduce_funs(rf, rfdiff, OT)
    quote
        global $(rf)
        $(rf)(fun::Functor{1}, a::ContiguousNumericArray) = mapreduce(fun, $(OT)(), a)
        $(rf)(fun::Functor{2}, a::ContiguousArrOrNum, b::ContiguousArrOrNum) = 
            mapreduce(fun, $(OT)(), a, b)
        $(rf)(fun::Functor{3}, a::ContiguousArrOrNum, b::ContiguousArrOrNum, c::ContiguousArrOrNum) = 
            mapreduce(fun, $(OT)(), a, b, c)

        global $(rfdiff)
        $(rfdiff)(fun::Functor{1}, a::ContiguousArrOrNum, b::ContiguousArrOrNum) = 
            mapreduce_fdiff(fun, $(OT)(), a, b)
    end
end

@compose_mapreduce_funs sum sumfdiff Add
@compose_mapreduce_funs maximum maxfdiff _Max
@compose_mapreduce_funs minimum minfdiff _Min
@compose_mapreduce_funs nonneg_maximum nonneg_maxfdiff NonnegMax

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

