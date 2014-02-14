# kernels for reduction

### facilities for debugging

function safe_sum(x)
    r = zero(eltype(x))
    for i in 1 : length(x)
        r = r + x[i]
    end
    r
end

function safe_max(x)
    r = typemin(eltype(x))
    for i in 1 : length(x)
        r = max(r, x[i])
    end
    r
end

function safe_min(x)
    r = typemax(eltype(x))
    for i in 1 : length(x)
        r = min(r, x[i])
    end
    r
end


### sum

suminit{T<:Number}(::Type{T}) = zero(T)
suminit{T<:Unsigned}(::Type{T}) = uint(0)
suminit{T<:Signed}(::Type{T}) = 0
suminit(::Type{Int64}) = int64(0)
suminit(::Type{Uint64}) = uint64(0)
suminit(::Type{Int128}) = int128(0)
suminit(::Type{Uint128}) = uint128(0)
suminit(::Type{Bool}) = 0
 
suminit{T<:Number}(::Type{T}) = zero(T)
suminit{T<:Unsigned}(::Type{T}) = uint(0)
suminit{T<:Signed}(::Type{T}) = 0
suminit(::Type{Int64}) = int64(0)
suminit(::Type{Uint64}) = uint64(0)
suminit(::Type{Int128}) = int128(0)
suminit(::Type{Uint128}) = uint128(0)
suminit(::Type{Bool}) = 0
 
function vecsum{T}(n::Int, a::Array{T}, ia::Int)
    v::T
    ia_end = ia + n
    @inbounds if n <= 4
        v = a[ia]
        ia += 1
        while ia < ia_end
            v += a[ia]
            ia += 1
        end
    else
        v1 = a[ia]
        v2 = a[ia + 1]
        v3 = a[ia + 2]
        v4 = a[ia + 3]
        ia += 4
        ia_ = ia_end - 3
        while ia < ia_
            v1 += a[ia]
            v2 += a[ia+1]
            v3 += a[ia+2]
            v4 += a[ia+3]
            ia += 4
        end
        v = v1 + v2 + v3 + v4
        while ia < ia_end
            v += a[ia]
            ia += 1
        end 
    end
    return v
end
 
function vecsum{T}(n::Int, a::Array{T}, ia::Int, sa::Int)
    v::T
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = a[ia]
        ia += sa
        while ia < ia_end
            v += a[ia]
            ia += sa
        end
    else
        sa2 = 2sa
        v1 = a[ia]
        v2 = a[ia + sa]
        ia += sa2
        ia_ = ia_end - sa
        while ia < ia_
            v1 += a[ia]
            v2 += a[ia + sa]
            ia += sa2
        end
        v = v1 + v2
        if ia < ia_end
            v += a[ia]
        end
    end
    return v
end

function vecadd!(n::Int, d::Array, id::Int, a::Array, ia::Int)
    ia_end = ia + n
    ia_ = ia_end - 3
    @inbounds while ia < ia_
        d[id] += a[ia]
        d[id+1] += a[ia+1]
        d[id+2] += a[ia+2]
        d[id+3] += a[ia+3]
        ia += 4
        id += 4
    end
 
    @inbounds while ia < ia_end
        d[id] += a[ia]
        id += 1
        ia += 1
    end
end

function vecadd!(n::Int, d::Array, id::Int, sd::Int, a::Array, ia::Int, sa::Int)
    ia_end = ia + sa * n
    ia_ = ia_end - sa
    sa2 = 2sa
    sd2 = 2sd

    @inbounds while ia < ia_
        d[id] += a[ia]
        d[id + sd] += a[ia + sa]
        ia += sa2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] += a[ia]
    end
end

