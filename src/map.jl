# map operations to elements

#################################################
#
#   Generic functor based mapping
#
#################################################

# the macro to generate functor-based mapping functions 
# for various number of arguments

macro compose_mapfuns(fname, AN)
    @assert AN != 0
    FN = AN > 0 ? AN : 1
    fname! = symbol(string(fname, '!'))

    # code-gen preparation
    h = codegen_helper(AN)
    aargs = h.args[2:end]
    cparams = h.contiguous_aparams[2:end]
    aparams = h.dense_aparams[2:end]
    ti = h.term(:i)

    quote
        global $(fname!)
        function $(fname!)(fun::Functor{$FN}, dst::ContiguousArray, $(cparams...))
            n = length(dst)
            n == $(h.inputlen) || throw(DimensionMismatch("Inconsistent argument lengths."))
            for i = 1:n
                @inbounds dst[i] = $(ti)
            end
            dst
        end

        global $(fname)
        $(fname)(fun::Functor{$FN}, $(cparams...)) = 
            $(fname!)(fun, Array($(h.termtype), $(h.inputsize)), $(aargs...))
    end
end

@compose_mapfuns map 1
@compose_mapfuns map 2
@compose_mapfuns map 3
@compose_mapfuns mapdiff (-2)

map1!(f::Functor{1}, a::DenseArray) = map!(f, a, a)
map1!(f::Functor{2}, a::DenseArray, b::DenseArray) = map!(f, a, a, b)
map1!(f::Functor{2}, a::DenseArray, b::Number) = map!(f, a, a, b)
map1!(f::Functor{3}, a::DenseArray, b::DenseArray, c::DenseArray) = map!(f, a, a, b, c)
map1!(f::Functor{3}, a::DenseArray, b::DenseArray, c::Number) = map!(f, a, a, b, c)
map1!(f::Functor{3}, a::DenseArray, b::Number, c::DenseArray) = map!(f, a, a, b, c)
map1!(f::Functor{3}, a::DenseArray, b::Number, c::Number) = map!(f, a, a, b, c)


#################################################
#
#   Some inplace mapping functions
#
#################################################

macro derive_mapfuns1(fname, Op, BT)
    fname! = symbol(string(fname, '!'))
    quote
        global $(fname!)
        $(fname!){T<:$(BT)}(a::DenseArray{T}) = map1!($(Op)(), a)
        $(fname!){T<:$(BT)}(dst::DenseArray, a::DenseArray{T}) = map!($(Op)(), dst, a)
    end
end

macro derive_mapfuns2(fname, Op, BT)
    fname! = symbol(string(fname, '!'))
    quote
        global $(fname!)
        $(fname!){T1<:$(BT)}(a::DenseArray{T1}, b::$(BT)) = map1!($(Op)(), a, b)
        $(fname!){T1<:$(BT),T2<:$(BT)}(a::DenseArray{T1}, b::DenseArray{T2}) = map1!($(Op)(), a, b)
        $(fname!){T1<:$(BT)}(dst::DenseArray, a::DenseArray{T1}, b::$(BT)) = map!($(Op)(), dst, a, b)
        $(fname!){T1<:$(BT),T2<:$(BT)}(dst::DenseArray, a::DenseArray{T1}, b::DenseArray{T2}) = map!($(Op)(), dst, a, b)
    end
end

@derive_mapfuns1 negate Negate Number

@derive_mapfuns2 add Add Number
@derive_mapfuns2 subtract Subtract Number
@derive_mapfuns2 multiply Multiply Number
@derive_mapfuns2 divide Divide Number

@derive_mapfuns1 abs AbsFun Number
@derive_mapfuns1 abs2 Abs2Fun Number
@derive_mapfuns1 rcp RcpFun Number
@derive_mapfuns1 sqrt SqrtFun Real
@derive_mapfuns2 pow Pow Real

@derive_mapfuns1 floor FloorFun Real
@derive_mapfuns1 ceil CeilFun Real
@derive_mapfuns1 round RoundFun Real
@derive_mapfuns1 trunc TruncFun Real

@derive_mapfuns1 exp ExpFun Real
@derive_mapfuns1 log LogFun Real

# extensions

absdiff(x::NumericArray, y::NumericArray) = mapdiff(AbsFun(), x, y)
sqrdiff(x::NumericArray, y::NumericArray) = mapdiff(Abs2Fun(), x, y)

fma!(a::NumericArray, b::DenseArrOrNum, c::DenseArrOrNum) = map1!(FMA(), a, b, c)
fma(a::DenseArrOrNum, b::DenseArrOrNum, c::DenseArrOrNum) = map(FMA(), a, b, c)

