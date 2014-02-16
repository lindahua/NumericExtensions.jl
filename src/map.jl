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
    _fname! = symbol(string('_', fname!))

    # code-gen preparation
    h = codegen_helper(AN)
    he = codegen_helper_ex(AN)
    aargs = h.args[2:end]
    ti = h.term(:i)
    t1 = h.term(1)
    mapker! = AN > 0 ? :vecmap! : :vecmapdiff!

    quote
        global $(fname)
        $(fname)($(h.dense_aparams...)) = 
            $(fname!)(fun, Array($(h.termtype), $(h.inputsize)), $(aargs...))

        global $(fname!)
        function $(fname!)(fun::Functor{$FN}, dst::ContiguousArray, $(h.contiguous_aparams[2:end]...))
            n = length(dst)
            n == $(h.inputlen) || throw(DimensionMismatch("Inconsistent argument lengths."))
            for i = 1:n
                @inbounds dst[i] = $(ti)
            end
            return dst
        end

        function $(fname!)(fun::Functor{$FN}, dst::DenseArray, $(h.dense_aparams[2:end]...))
            siz = $(h.inputsize)
            size(dst) == siz || throw(DimensionMismatch("Inconsistent argument size."))
            $(_fname!)(siz, length(siz), dst, $(h.args...))
            return dst
        end

        global $(_fname!)
        function $(_fname!)(siz::Dims, dim::Int, dst::DenseArray, $(h.dense_aparams...))
            if dim == 1
                n = siz[1]::Int
                $(he.getstrides1)
                sdst1 = stride(dst, 1)::Int
                $(he.getoffsets)
                idst = offset(dst) + 1
                if $(he.contcol) && sdst1 == 1
                    $(mapker!)(n, parent(dst), idst, $(he.pkerargs...))
                else
                    $(mapker!)(n, parent(dst), idst, sdst1, $(he.pkerargs1...))
                end

            elseif dim == 2
                m = siz[1]::Int
                n = siz[2]::Int
                $(he.getstrides2)
                sdst1, sdst2 = strides(dst)::(Int, Int)
                $(he.getoffsets)
                idst = offset(dst) + 1
                if $(he.contcol) && sdst1 == 1
                    for j = 1:n
                        $(mapker!)(m, parent(dst), idst, $(he.pkerargs...))
                        $(he.nextcol)
                        idst += sdst2
                    end
                else
                    for j = 1:n
                        $(mapker!)(m, parent(dst), idst, sdst1, $(he.pkerargs1...))
                        $(he.nextcol)
                        idst += sdst2
                    end
                end

            else
                n = siz[dim]::Int
                for i = 1:n
                    $(_fname!)(siz, dim-1, ellipview(dst, i), $(he.eviewargs...))
                end
            end
        end        
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

absdiff(x::DenseArrOrNum, y::DenseArrOrNum) = mapdiff(AbsFun(), x, y)
sqrdiff(x::DenseArrOrNum, y::DenseArrOrNum) = mapdiff(Abs2Fun(), x, y)

absdiff!(r::NumericArray, x::DenseArrOrNum, y::DenseArrOrNum) = mapdiff!(AbsFun(), r, x, y)
sqrdiff!(r::NumericArray, x::DenseArrOrNum, y::DenseArrOrNum) = mapdiff!(Abs2Fun(), r, x, y)

fma!(a::NumericArray, b::DenseArrOrNum, c::DenseArrOrNum) = map1!(FMA(), a, b, c)
fma(a::DenseArrOrNum, b::DenseArrOrNum, c::DenseArrOrNum) = map(FMA(), a, b, c)

