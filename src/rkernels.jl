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


### core skeleton

abstract Reduc

function saccum{Op<:Reduc}(::Type{Op}, n::Int, a::Array, ia::Int)
    ia_end = ia + n
    @inbounds if n <= 4
        v = a[ia]
        ia += 1
        while ia < ia_end
            v = combine(Op, v, a[ia])
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
            v1 = combine(Op, v1, a[ia])
            v2 = combine(Op, v2, a[ia+1])
            v3 = combine(Op, v3, a[ia+2])
            v4 = combine(Op, v4, a[ia+3])
            ia += 4
        end
        v = combine(Op, combine(Op, v1, v2), combine(Op, v3, v4))
        while ia < ia_end
            v = combine(Op, v, a[ia])
            ia += 1
        end 
    end
    return v
end
 
function saccum{Op<:Reduc}(::Type{Op}, n::Int, fun::Functor{1}, a::Array, ia::Int)
    ia_end = ia + n
    @inbounds if n <= 4
        v = evaluate(fun, a[ia])
        ia += 1
        while ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia]))
            ia += 1
        end
    else
        v1 = evaluate(fun, a[ia])
        v2 = evaluate(fun, a[ia+1])
        v3 = evaluate(fun, a[ia+2])
        v4 = evaluate(fun, a[ia+3])
        ia += 4
        ia_ = ia_end - 3
        while ia < ia_
            v1 = combine(Op, v1, evaluate(fun, a[ia]))
            v2 = combine(Op, v2, evaluate(fun, a[ia+1]))
            v3 = combine(Op, v3, evaluate(fun, a[ia+2]))
            v4 = combine(Op, v4, evaluate(fun, a[ia+3]))
            ia += 4
        end
        v = combine(Op, combine(Op, v1, v2), combine(Op, v3, v4))
        while ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia]))
            ia += 1
        end 
    end
    return v
end

function saccum{Op<:Reduc}(::Type{Op}, n::Int, fun::Functor{2}, a::Array, ia::Int, b::Array, ib::Int)
    ia_end = ia + n
    @inbounds if n <= 4
        v = evaluate(fun, a[ia], b[ib])
        ia += 1
        ib += 1
        while ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia], b[ib]))
            ia += 1
            ib += 1
        end
    else
        v1 = evaluate(fun, a[ia], b[ib])
        v2 = evaluate(fun, a[ia+1], b[ib+1])
        ia += 2
        ib += 2
        ia_ = ia_end - 1
        while ia < ia_
            v1 = combine(Op, v1, evaluate(fun, a[ia], b[ib]))
            v2 = combine(Op, v2, evaluate(fun, a[ia+1], b[ib+1]))
            ia += 2
            ib += 2
        end
        v = combine(Op, v1, v2)
        if ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia], b[ib]))
        end 
    end
    return v
end

function saccum_fdiff{Op<:Reduc}(::Type{Op}, n::Int, fun::Functor{1}, a::Array, ia::Int, b::Array, ib::Int)
    ia_end = ia + n
    @inbounds if n <= 4
        v = evaluate(fun, a[ia] - b[ib])
        ia += 1
        ib += 1
        while ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia] - b[ib]))
            ia += 1
            ib += 1
        end
    else
        v1 = evaluate(fun, a[ia] - b[ib])
        v2 = evaluate(fun, a[ia+1] - b[ib+1])
        ia += 2
        ib += 2
        ia_ = ia_end - 1
        while ia < ia_
            v1 = combine(Op, v1, evaluate(fun, a[ia] - b[ib]))
            v2 = combine(Op, v2, evaluate(fun, a[ia+1] - b[ib+1]))
            ia += 2
            ib += 2
        end
        v = combine(Op, v1, v2)
        if ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia] - b[ib]))
        end 
    end
    return v
end

function saccum{Op<:Reduc}(::Type{Op}, n::Int, fun::Functor{3}, a::Array, ia::Int, b::Array, ib::Int, c::Array, ic::Int)
    ia_end = ia + n
    @inbounds if n <= 4
        v = evaluate(fun, a[ia], b[ib], c[ic])
        ia += 1
        ib += 1
        ic += 1
        while ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia], b[ib], c[ic]))
            ia += 1
            ib += 1
            ic += 1
        end
    else
        v1 = evaluate(fun, a[ia], b[ib], c[ic])
        v2 = evaluate(fun, a[ia+1], b[ib+1], c[ic+1])
        ia += 2
        ib += 2
        ic += 2
        ia_ = ia_end - 1
        while ia < ia_
            v1 = combine(Op, v1, evaluate(fun, a[ia], b[ib], c[ic]))
            v2 = combine(Op, v2, evaluate(fun, a[ia+1], b[ib+1], c[ic+1]))
            ia += 2
            ib += 2
            ic += 2
        end
        v = combine(Op, v1, v2)
        if ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia], b[ib], c[ic]))
        end 
    end
    return v
end



function saccum{Op<:Reduc}(::Type{Op}, n::Int, a::Array, ia::Int, sa::Int)
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = a[ia]
        ia += sa
        while ia < ia_end
            v = combine(Op, v, a[ia])
            ia += sa
        end
    else
        sa2 = 2sa
        v1 = a[ia]
        v2 = a[ia + sa]
        ia += sa2
        ia_ = ia_end - sa
        while ia < ia_
            v1 = combine(Op, v1, a[ia])
            v2 = combine(Op, v2, a[ia + sa])
            ia += sa2
        end
        v = combine(Op, v1, v2)
        if ia < ia_end
            v = combine(Op, v, a[ia])
        end 
    end
    return v
end

function saccum{Op<:Reduc}(::Type{Op}, n::Int, fun::Functor{1}, a::Array, ia::Int, sa::Int)
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = evaluate(fun, a[ia])
        ia += sa
        while ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia]))
            ia += sa
        end
    else
        sa2 = 2sa
        v1 = evaluate(fun, a[ia])
        v2 = evaluate(fun, a[ia + sa])
        ia += sa2
        ia_ = ia_end - sa
        while ia < ia_
            v1 = combine(Op, v1, evaluate(fun, a[ia]))
            v2 = combine(Op, v2, evaluate(fun, a[ia + sa]))
            ia += sa2
        end
        v = combine(Op, v1, v2)
        if ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia]))
        end 
    end
    return v
end

function saccum{Op<:Reduc}(::Type{Op}, n::Int, fun::Functor{2}, a::Array, ia::Int, sa::Int, b::Array, ib::Int, sb::Int)
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = evaluate(fun, a[ia], b[ib])
        ia += sa
        ib += sb
        while ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia], b[ib]))
            ia += sa
            ib += sb
        end
    else
        sa2 = 2sa
        sb2 = 2sb
        v1 = evaluate(fun, a[ia], b[ib])
        v2 = evaluate(fun, a[ia + sa], b[ib + sb])
        ia += sa2
        ib += sb2
        ia_ = ia_end - sa
        while ia < ia_
            v1 = combine(Op, v1, evaluate(fun, a[ia], b[ib]))
            v2 = combine(Op, v2, evaluate(fun, a[ia + sa], b[ib + sb]))
            ia += sa2
            ib += sb2
        end
        v = combine(Op, v1, v2)
        if ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia], b[ib]))
        end 
    end
    return v
end

function saccum_fdiff{Op<:Reduc}(::Type{Op}, n::Int, fun::Functor{1}, a::Array, ia::Int, sa::Int, b::Array, ib::Int, sb::Int)
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = evaluate(fun, a[ia] - b[ib])
        ia += sa
        ib += sb
        while ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia] - b[ib]))
            ia += sa
            ib += sb
        end
    else
        sa2 = 2sa
        sb2 = 2sb
        v1 = evaluate(fun, a[ia] - b[ib])
        v2 = evaluate(fun, a[ia + sa] - b[ib + sb])
        ia += sa2
        ib += sb2
        ia_ = ia_end - sa
        while ia < ia_
            v1 = combine(Op, v1, evaluate(fun, a[ia] - b[ib]))
            v2 = combine(Op, v2, evaluate(fun, a[ia + sa] - b[ib + sb]))
            ia += sa2
            ib += sb2
        end
        v = combine(Op, v1, v2)
        if ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia] - b[ib]))
        end 
    end
    return v
end

function saccum{Op<:Reduc}(::Type{Op}, n::Int, fun::Functor{3}, a::Array, ia::Int, sa::Int, 
                                                                b::Array, ib::Int, sb::Int, 
                                                                c::Array, ic::Int, sc::Int)
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = evaluate(fun, a[ia], b[ib], c[ic])
        ia += sa
        ib += sb
        ic += sc
        while ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia], b[ib], c[ic]))
            ia += sa
            ib += sb
            ic += sc
        end
    else
        sa2 = 2sa
        sb2 = 2sb
        sc2 = 2sc
        v1 = evaluate(fun, a[ia], b[ib], c[ic])
        v2 = evaluate(fun, a[ia + sa], b[ib + sb], c[ic + sc])
        ia += sa2
        ib += sb2
        ic += sc2
        ia_ = ia_end - sa
        while ia < ia_
            v1 = combine(Op, v1, evaluate(fun, a[ia], b[ib], c[ic]))
            v2 = combine(Op, v2, evaluate(fun, a[ia + sa], b[ib + sb], c[ic + sc]))
            ia += sa2
            ib += sb2
            ic += sc2
        end
        v = combine(Op, v1, v2)
        if ia < ia_end
            v = combine(Op, v, evaluate(fun, a[ia], b[ib], c[ic]))
        end 
    end
    return v
end



function paccum!{Op<:Reduc}(::Type{Op}, n::Int, d::Array, id::Int, a::Array, ia::Int)
    ia_end = ia + n
    ia_ = ia_end - 3
    @inbounds while ia < ia_
        d[id] = combine(Op, d[id], a[ia])
        d[id+1] = combine(Op, d[id+1], a[ia+1])
        d[id+2] = combine(Op, d[id+2], a[ia+2])
        d[id+3] = combine(Op, d[id+3], a[ia+3])
        ia += 4
        id += 4
    end
 
    @inbounds while ia < ia_end
        d[id] = combine(Op, d[id], a[ia])
        id += 1
        ia += 1
    end
end

function paccum!{Op<:Reduc}(::Type{Op}, n::Int, d::Array, id::Int, fun::Functor{1}, a::Array, ia::Int)
    ia_end = ia + n
    ia_ = ia_end - 3
    @inbounds while ia < ia_
        d[id] = combine(Op, d[id], evaluate(fun, a[ia]))
        d[id+1] = combine(Op, d[id+1], evaluate(fun, a[ia+1]))
        d[id+2] = combine(Op, d[id+2], evaluate(fun, a[ia+2]))
        d[id+3] = combine(Op, d[id+3], evaluate(fun, a[ia+3]))
        ia += 4
        id += 4
    end
 
    @inbounds while ia < ia_end
        d[id] = combine(Op, d[id], evaluate(fun, a[ia]))
        id += 1
        ia += 1
    end
end

function paccum!{Op<:Reduc}(::Type{Op}, n::Int, d::Array, id::Int, fun::Functor{2}, a::Array, ia::Int, b::Array, ib::Int)
    ia_end = ia + n
    ia_ = ia_end - 1
    @inbounds while ia < ia_
        d[id] = combine(Op, d[id], evaluate(fun, a[ia], b[ib]))
        d[id+1] = combine(Op, d[id+1], evaluate(fun, a[ia+1], b[ib+1]))
        ia += 2
        ib += 2
        id += 2
    end
 
    @inbounds if ia < ia_end
        d[id] = combine(Op, d[id], evaluate(fun, a[ia], b[ib]))
    end
end

function paccum_fdiff!{Op<:Reduc}(::Type{Op}, n::Int, d::Array, id::Int, fun::Functor{1}, a::Array, ia::Int, b::Array, ib::Int)
    ia_end = ia + n
    ia_ = ia_end - 1
    @inbounds while ia < ia_
        d[id] = combine(Op, d[id], evaluate(fun, a[ia] - b[ib]))
        d[id+1] = combine(Op, d[id+1], evaluate(fun, a[ia+1] - b[ib+1]))
        ia += 2
        ib += 2
        id += 2
    end
 
    @inbounds if ia < ia_end
        d[id] = combine(Op, d[id], evaluate(fun, a[ia] - b[ib]))
    end
end

function paccum!{Op<:Reduc}(::Type{Op}, n::Int, d::Array, id::Int, fun::Functor{3}, a::Array, ia::Int, b::Array, ib::Int, c::Array, ic::Int)
    ia_end = ia + n
    ia_ = ia_end - 1
    @inbounds while ia < ia_
        d[id] = combine(Op, d[id], evaluate(fun, a[ia], b[ib], c[ic]))
        d[id+1] = combine(Op, d[id+1], evaluate(fun, a[ia+1], b[ib+1], c[ic+1]))
        ia += 2
        ib += 2
        ic += 2
        id += 2
    end
 
    @inbounds if ia < ia_end
        d[id] = combine(Op, d[id], evaluate(fun, a[ia], b[ib], c[ic]))
    end
end


function paccum!{Op<:Reduc}(::Type{Op}, n::Int, d::Array, id::Int, sd::Int, a::Array, ia::Int, sa::Int)
    ia_end = ia + sa * n
    sa2 = 2sa
    sd2 = 2sd
    ia_ = ia_end - sa
    @inbounds while ia < ia_
        d[id] = combine(Op, d[id], a[ia])
        d[id + sd] = combine(Op, d[id+sd], a[ia + sa])
        ia += sa2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] = combine(Op, d[id], a[ia])
    end
end

function paccum!{Op<:Reduc}(::Type{Op}, n::Int, d::Array, id::Int, sd::Int, fun::Functor{1}, a::Array, ia::Int, sa::Int)
    ia_end = ia + sa * n
    sa2 = 2sa
    sd2 = 2sd
    ia_ = ia_end - sa
    @inbounds while ia < ia_
        d[id] = combine(Op, d[id], evaluate(fun, a[ia]))
        d[id + sd] = combine(Op, d[id+sd], evaluate(fun, a[ia + sa]))
        ia += sa2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] = combine(Op, d[id], evaluate(fun, a[ia]))
    end
end

function paccum!{Op<:Reduc}(::Type{Op}, n::Int, d::Array, id::Int, sd::Int, fun::Functor{2}, a::Array, ia::Int, sa::Int,
                                                                                             b::Array, ib::Int, sb::Int)
    ia_end = ia + sa * n
    sa2 = 2sa
    sb2 = 2sb
    sd2 = 2sd
    ia_ = ia_end - sa
    @inbounds while ia < ia_
        d[id] = combine(Op, d[id], evaluate(fun, a[ia], b[ib]))
        d[id + sd] = combine(Op, d[id+sd], evaluate(fun, a[ia + sa], b[ib + sb]))
        ia += sa2
        ib += sb2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] = combine(Op, d[id], evaluate(fun, a[ia], b[ib]))
    end
end

function paccum_fdiff!{Op<:Reduc}(::Type{Op}, n::Int, d::Array, id::Int, sd::Int, fun::Functor{1}, a::Array, ia::Int, sa::Int,
                                                                                                   b::Array, ib::Int, sb::Int)
    ia_end = ia + sa * n
    sa2 = 2sa
    sb2 = 2sb
    sd2 = 2sd
    ia_ = ia_end - sa
    @inbounds while ia < ia_
        d[id] = combine(Op, d[id], evaluate(fun, a[ia] - b[ib]))
        d[id + sd] = combine(Op, d[id+sd], evaluate(fun, a[ia + sa] - b[ib + sb]))
        ia += sa2
        ib += sb2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] = combine(Op, d[id], evaluate(fun, a[ia] - b[ib]))
    end
end

function paccum!{Op<:Reduc}(::Type{Op}, n::Int, d::Array, id::Int, sd::Int, fun::Functor{3}, a::Array, ia::Int, sa::Int,
                                                                                             b::Array, ib::Int, sb::Int,
                                                                                             c::Array, ic::Int, sc::Int)
    ia_end = ia + sa * n
    sa2 = 2sa
    sb2 = 2sb
    sc2 = 2sc
    sd2 = 2sd
    ia_ = ia_end - sa
    @inbounds while ia < ia_
        d[id] = combine(Op, d[id], evaluate(fun, a[ia], b[ib], c[ic]))
        d[id + sd] = combine(Op, d[id+sd], evaluate(fun, a[ia + sa], b[ib + sb], c[ic+sc]))
        ia += sa2
        ib += sb2
        ic += sc2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] = combine(Op, d[id], evaluate(fun, a[ia], b[ib], c[ic]))
    end
end



### reduction operations

type Sum <: Reduc end

init{T<:Number}(::Type{Sum}, ::Type{T}) = zero(T)
init{T<:Unsigned}(::Type{Sum}, ::Type{T}) = uint(0)
init{T<:Signed}(::Type{Sum}, ::Type{T}) = 0
init(::Type{Sum}, ::Type{Int64}) = int64(0)
init(::Type{Sum}, ::Type{Uint64}) = uint64(0)
init(::Type{Sum}, ::Type{Int128}) = int128(0)
init(::Type{Sum}, ::Type{Uint128}) = uint128(0)
init(::Type{Sum}, ::Type{Bool}) = 0

combine(::Type{Sum}, x, y) = x + y








