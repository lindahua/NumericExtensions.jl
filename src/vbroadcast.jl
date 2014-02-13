# A set of inplace broadcasting functions


# broadcast along specific dimension(s)

function _vbroadcast_eachcol!(m::Int, n::Int, f::Functor{2}, r::ContiguousArray, a::ContiguousArray, b::ContiguousArray)
    o = 0
    for j = 1 : n
        for i = 1 : m
            @inbounds r[o+i] = evaluate(f, a[o+i], b[i])
        end
        o += m
    end 
end

function _vbroadcast_eachrow!(m::Int, n::Int, f::Functor{2}, r::ContiguousArray, a::ContiguousArray, b::ContiguousArray)
    o = 0
    for j = 1 : n
        @inbounds bj = b[j]
        for i = 1 : m
            @inbounds r[o+i] = evaluate(f, a[o+i], bj)
        end
        o += m
    end
end

function _vbroadcast3!{T}(m::Int, n::Int, k::Int, 
    f::Functor{2}, r::ContiguousArray, a::ContiguousArray{T,3}, b::ContiguousArray)

    for l = 1 : k
        _vbroadcast_eachrow!(m, n, f, view(r,:,:,l), view(a,:,:,l), b)
    end
end

function vbroadcast!(f::Functor{2}, r::ContiguousArray, a::ContiguousArray, b::ContiguousArray, dim::Int)
    shp = size(a)
    nd = ndims(a)
    size(r) == shp && size(a, dim) == length(b) || error("Inconsistent argument dimensions.")
    1 <= dim <= nd || error("Invalid value of dim.")
    
    if dim == 1
        m = shp[1]
        n = succ_length(shp, 1)
        _vbroadcast_eachcol!(m, n, f, r, a, b)
    else
        m = prec_length(shp, dim)
        n = shp[dim]
        k = succ_length(shp, dim)
        if k == 1
            _vbroadcast_eachrow!(m, n, f, r, a, b)
        else
            _vbroadcast3!(m, n, k, f, contiguous_view(r, (m,n,k)), a, b)
        end
    end
    return r
end


vbroadcast1!(f::Functor{2}, a::ContiguousArray, b::ContiguousArray, dim::Int) = vbroadcast!(f, a, a, b, dim)

function vbroadcast(f::Functor{2}, a::ContiguousArray, b::ContiguousArray, dim::Int)
    R = result_type(f, eltype(a), eltype(b))
    vbroadcast!(f, zeros(R, size(a)), a, b, dim)
end

# Specific broadcasting function

badd!(a::ContiguousArray, b::ContiguousArray, dim::Int) = vbroadcast1!(Add(), a, b, dim)
bsubtract!(a::ContiguousArray, b::ContiguousArray, dim::Int) = vbroadcast1!(Subtract(), a, b, dim)
bmultiply!(a::ContiguousArray, b::ContiguousArray, dim::Int) = vbroadcast1!(Multiply(), a, b, dim)
bdivide!(a::ContiguousArray, b::ContiguousArray, dim::Int) = vbroadcast1!(Divide(), a, b, dim)

badd(a::ContiguousArray, b::ContiguousArray, dim::Int) = vbroadcast(Add(), a, b, dim)
bsubtract(a::ContiguousArray, b::ContiguousArray, dim::Int) = vbroadcast(Subtract(), a, b, dim)
bmultiply(a::ContiguousArray, b::ContiguousArray, dim::Int) = vbroadcast(Multiply(), a, b, dim)
bdivide(a::ContiguousArray, b::ContiguousArray, dim::Int) = vbroadcast(Divide(), a, b, dim)

