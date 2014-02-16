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

# rename @inbounds to @inbounds (when want to disable @inbounds effect)
macro inboundss(x)
    esc(x)
end

#################################################
#
#   Core skeleton
#
#################################################

function saccum{Op<:Functor{2}}(op::Op, n::Int, a::Array, ia::Int)
    ia_end = ia + n
    @inbounds if n <= 4
        v = getvalue(a, ia)
        ia += 1
        while ia < ia_end
            v = evaluate(op, v, getvalue(a, ia))
            ia += 1
        end
    else
        v1 = getvalue(a, ia)
        v2 = getvalue(a, ia+1)
        v3 = getvalue(a, ia+2)
        v4 = getvalue(a, ia+3)
        ia += 4
        ia_ = ia_end - 3
        while ia < ia_
            v1 = evaluate(op, v1, getvalue(a, ia))
            v2 = evaluate(op, v2, getvalue(a, ia+1))
            v3 = evaluate(op, v3, getvalue(a, ia+2))
            v4 = evaluate(op, v4, getvalue(a, ia+3))
            ia += 4
        end
        v = evaluate(op, evaluate(op, v1, v2), evaluate(op, v3, v4))
        while ia < ia_end
            v = evaluate(op, v, getvalue(a, ia))
            ia += 1
        end 
    end
    return v
end
 
function saccum{Op<:Functor{2}}(op::Op, n::Int, fun::Functor{1}, a::Array, ia::Int)
    ia_end = ia + n
    @inbounds if n <= 4
        v = evaluate(fun, getvalue(a, ia))
        ia += 1
        while ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia)))
            ia += 1
        end
    else
        v1 = evaluate(fun, getvalue(a, ia))
        v2 = evaluate(fun, getvalue(a, ia+1))
        v3 = evaluate(fun, getvalue(a, ia+2))
        v4 = evaluate(fun, getvalue(a, ia+3))
        ia += 4
        ia_ = ia_end - 3
        while ia < ia_
            v1 = evaluate(op, v1, evaluate(fun, getvalue(a, ia)))
            v2 = evaluate(op, v2, evaluate(fun, getvalue(a, ia+1)))
            v3 = evaluate(op, v3, evaluate(fun, getvalue(a, ia+2)))
            v4 = evaluate(op, v4, evaluate(fun, getvalue(a, ia+3)))
            ia += 4
        end
        v = evaluate(op, evaluate(op, v1, v2), evaluate(op, v3, v4))
        while ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia)))
            ia += 1
        end 
    end
    return v
end

function saccum{Op<:Functor{2}}(op::Op, n::Int, fun::Functor{2}, a::ArrayOrNum, ia::Int, b::ArrayOrNum, ib::Int)
    ia_end = ia + n
    @inbounds if n <= 4
        v = evaluate(fun, getvalue(a, ia), getvalue(b, ib))
        ia += 1
        ib += 1
        while ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia), getvalue(b, ib)))
            ia += 1
            ib += 1
        end
    else
        v1 = evaluate(fun, getvalue(a, ia), getvalue(b, ib))
        v2 = evaluate(fun, getvalue(a, ia+1), getvalue(b, ib+1))
        ia += 2
        ib += 2
        ia_ = ia_end - 1
        while ia < ia_
            v1 = evaluate(op, v1, evaluate(fun, getvalue(a, ia), getvalue(b, ib)))
            v2 = evaluate(op, v2, evaluate(fun, getvalue(a, ia+1), getvalue(b, ib+1)))
            ia += 2
            ib += 2
        end
        v = evaluate(op, v1, v2)
        if ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia), getvalue(b, ib)))
        end 
    end
    return v
end

function saccum_fdiff{Op<:Functor{2}}(op::Op, n::Int, fun::Functor{1}, a::ArrayOrNum, ia::Int, b::ArrayOrNum, ib::Int)
    ia_end = ia + n
    @inbounds if n <= 4
        v = evaluate(fun, getvalue(a, ia) - getvalue(b, ib))
        ia += 1
        ib += 1
        while ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia) - getvalue(b, ib)))
            ia += 1
            ib += 1
        end
    else
        v1 = evaluate(fun, getvalue(a, ia) - getvalue(b, ib))
        v2 = evaluate(fun, getvalue(a, ia+1) - getvalue(b, ib+1))
        ia += 2
        ib += 2
        ia_ = ia_end - 1
        while ia < ia_
            v1 = evaluate(op, v1, evaluate(fun, getvalue(a, ia) - getvalue(b, ib)))
            v2 = evaluate(op, v2, evaluate(fun, getvalue(a, ia+1) - getvalue(b, ib+1)))
            ia += 2
            ib += 2
        end
        v = evaluate(op, v1, v2)
        if ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia) - getvalue(b, ib)))
        end 
    end
    return v
end

function saccum{Op<:Functor{2}}(op::Op, n::Int, fun::Functor{3}, a::ArrayOrNum, ia::Int, b::ArrayOrNum, ib::Int, c::ArrayOrNum, ic::Int)
    ia_end = ia + n
    @inbounds if n <= 4
        v = evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic))
        ia += 1
        ib += 1
        ic += 1
        while ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic)))
            ia += 1
            ib += 1
            ic += 1
        end
    else
        v1 = evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic))
        v2 = evaluate(fun, getvalue(a, ia+1), getvalue(b, ib+1), getvalue(c, ic+1))
        ia += 2
        ib += 2
        ic += 2
        ia_ = ia_end - 1
        while ia < ia_
            v1 = evaluate(op, v1, evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic)))
            v2 = evaluate(op, v2, evaluate(fun, getvalue(a, ia+1), getvalue(b, ib+1), getvalue(c, ic+1)))
            ia += 2
            ib += 2
            ic += 2
        end
        v = evaluate(op, v1, v2)
        if ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic)))
        end 
    end
    return v
end



function saccum{Op<:Functor{2}}(op::Op, n::Int, a::Array, ia::Int, sa::Int)
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = getvalue(a, ia)
        ia += sa
        while ia < ia_end
            v = evaluate(op, v, getvalue(a, ia))
            ia += sa
        end
    else
        sa2 = 2sa
        v1 = getvalue(a, ia)
        v2 = getvalue(a, ia+sa)
        ia += sa2
        ia_ = ia_end - sa
        while ia < ia_
            v1 = evaluate(op, v1, getvalue(a, ia))
            v2 = evaluate(op, v2, getvalue(a, ia+sa))
            ia += sa2
        end
        v = evaluate(op, v1, v2)
        if ia < ia_end
            v = evaluate(op, v, getvalue(a, ia))
        end 
    end
    return v
end

function saccum{Op<:Functor{2}}(op::Op, n::Int, fun::Functor{1}, a::Array, ia::Int, sa::Int)
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = evaluate(fun, getvalue(a, ia))
        ia += sa
        while ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia)))
            ia += sa
        end
    else
        sa2 = 2sa
        v1 = evaluate(fun, getvalue(a, ia))
        v2 = evaluate(fun, getvalue(a, ia+sa))
        ia += sa2
        ia_ = ia_end - sa
        while ia < ia_
            v1 = evaluate(op, v1, evaluate(fun, getvalue(a, ia)))
            v2 = evaluate(op, v2, evaluate(fun, getvalue(a, ia+sa)))
            ia += sa2
        end
        v = evaluate(op, v1, v2)
        if ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia)))
        end 
    end
    return v
end

function saccum{Op<:Functor{2}}(op::Op, n::Int, fun::Functor{2}, a::ArrayOrNum, ia::Int, sa::Int, b::ArrayOrNum, ib::Int, sb::Int)
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = evaluate(fun, getvalue(a, ia), getvalue(b, ib))
        ia += sa
        ib += sb
        while ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia), getvalue(b, ib)))
            ia += sa
            ib += sb
        end
    else
        sa2 = 2sa
        sb2 = 2sb
        v1 = evaluate(fun, getvalue(a, ia), getvalue(b, ib))
        v2 = evaluate(fun, getvalue(a, ia+sa), getvalue(b, ib+sb))
        ia += sa2
        ib += sb2
        ia_ = ia_end - sa
        while ia < ia_
            v1 = evaluate(op, v1, evaluate(fun, getvalue(a, ia), getvalue(b, ib)))
            v2 = evaluate(op, v2, evaluate(fun, getvalue(a, ia+sa), getvalue(b, ib+sb)))
            ia += sa2
            ib += sb2
        end
        v = evaluate(op, v1, v2)
        if ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia), getvalue(b, ib)))
        end 
    end
    return v
end

function saccum_fdiff{Op<:Functor{2}}(op::Op, n::Int, fun::Functor{1}, a::ArrayOrNum, ia::Int, sa::Int, b::ArrayOrNum, ib::Int, sb::Int)
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = evaluate(fun, getvalue(a, ia) - getvalue(b, ib))
        ia += sa
        ib += sb
        while ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia) - getvalue(b, ib)))
            ia += sa
            ib += sb
        end
    else
        sa2 = 2sa
        sb2 = 2sb
        v1 = evaluate(fun, getvalue(a, ia) - getvalue(b, ib))
        v2 = evaluate(fun, getvalue(a, ia+sa) - getvalue(b, ib+sb))
        ia += sa2
        ib += sb2
        ia_ = ia_end - sa
        while ia < ia_
            v1 = evaluate(op, v1, evaluate(fun, getvalue(a, ia) - getvalue(b, ib)))
            v2 = evaluate(op, v2, evaluate(fun, getvalue(a, ia+sa) - getvalue(b, ib+sb)))
            ia += sa2
            ib += sb2
        end
        v = evaluate(op, v1, v2)
        if ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia) - getvalue(b, ib)))
        end 
    end
    return v
end

function saccum{Op<:Functor{2}}(op::Op, n::Int, fun::Functor{3}, a::ArrayOrNum, ia::Int, sa::Int, 
                                                                b::ArrayOrNum, ib::Int, sb::Int, 
                                                                c::ArrayOrNum, ic::Int, sc::Int)
    ia_end = ia + sa * n
    @inbounds if n <= 4
        v = evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic))
        ia += sa
        ib += sb
        ic += sc
        while ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic)))
            ia += sa
            ib += sb
            ic += sc
        end
    else
        sa2 = 2sa
        sb2 = 2sb
        sc2 = 2sc
        v1 = evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic))
        v2 = evaluate(fun, getvalue(a, ia+sa), getvalue(b, ib+sb), getvalue(c, ic+sc))
        ia += sa2
        ib += sb2
        ic += sc2
        ia_ = ia_end - sa
        while ia < ia_
            v1 = evaluate(op, v1, evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic)))
            v2 = evaluate(op, v2, evaluate(fun, getvalue(a, ia+sa), getvalue(b, ib+sb), getvalue(c, ic+sc)))
            ia += sa2
            ib += sb2
            ic += sc2
        end
        v = evaluate(op, v1, v2)
        if ia < ia_end
            v = evaluate(op, v, evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic)))
        end 
    end
    return v
end

function paccum!{Op<:Functor{2}}(op::Op, n::Int, d::Array, id::Int, a::Array, ia::Int)
    ia_end = ia + n
    ia_ = ia_end - 3
    @inbounds while ia < ia_
        d[id] = evaluate(op, d[id], getvalue(a, ia))
        d[id+1] = evaluate(op, d[id+1], getvalue(a, ia+1))
        d[id+2] = evaluate(op, d[id+2], getvalue(a, ia+2))
        d[id+3] = evaluate(op, d[id+3], getvalue(a, ia+3))
        ia += 4
        id += 4
    end
 
    @inbounds while ia < ia_end
        d[id] = evaluate(op, d[id], getvalue(a, ia))
        id += 1
        ia += 1
    end
end

function paccum!{Op<:Functor{2}}(op::Op, n::Int, d::Array, id::Int, fun::Functor{1}, a::Array, ia::Int)
    ia_end = ia + n
    ia_ = ia_end - 3
    @inbounds while ia < ia_
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia)))
        d[id+1] = evaluate(op, d[id+1], evaluate(fun, getvalue(a, ia+1)))
        d[id+2] = evaluate(op, d[id+2], evaluate(fun, getvalue(a, ia+2)))
        d[id+3] = evaluate(op, d[id+3], evaluate(fun, getvalue(a, ia+3)))
        ia += 4
        id += 4
    end
 
    @inbounds while ia < ia_end
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia)))
        id += 1
        ia += 1
    end
end

function paccum!{Op<:Functor{2}}(op::Op, n::Int, d::Array, id::Int, fun::Functor{2}, a::ArrayOrNum, ia::Int, b::ArrayOrNum, ib::Int)
    ia_end = ia + n
    ia_ = ia_end - 1
    @inbounds while ia < ia_
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia), getvalue(b, ib)))
        d[id+1] = evaluate(op, d[id+1], evaluate(fun, getvalue(a, ia+1), getvalue(b, ib+1)))
        ia += 2
        ib += 2
        id += 2
    end
 
    @inbounds if ia < ia_end
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia), getvalue(b, ib)))
    end
end

function paccum_fdiff!{Op<:Functor{2}}(op::Op, n::Int, d::Array, id::Int, fun::Functor{1}, a::ArrayOrNum, ia::Int, b::ArrayOrNum, ib::Int)
    ia_end = ia + n
    ia_ = ia_end - 1
    @inbounds while ia < ia_
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia) - getvalue(b, ib)))
        d[id+1] = evaluate(op, d[id+1], evaluate(fun, getvalue(a, ia+1) - getvalue(b, ib+1)))
        ia += 2
        ib += 2
        id += 2
    end
 
    @inbounds if ia < ia_end
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia) - getvalue(b, ib)))
    end
end

function paccum!{Op<:Functor{2}}(op::Op, n::Int, d::Array, id::Int, fun::Functor{3}, a::ArrayOrNum, ia::Int, 
                                                                                    b::ArrayOrNum, ib::Int, 
                                                                                    c::ArrayOrNum, ic::Int)
    ia_end = ia + n
    ia_ = ia_end - 1
    @inbounds while ia < ia_
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic)))
        d[id+1] = evaluate(op, d[id+1], evaluate(fun, getvalue(a, ia+1), getvalue(b, ib+1), getvalue(c, ic+1)))
        ia += 2
        ib += 2
        ic += 2
        id += 2
    end
 
    @inbounds if ia < ia_end
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic)))
    end
end


function paccum!{Op<:Functor{2}}(op::Op, n::Int, d::Array, id::Int, sd::Int, a::Array, ia::Int, sa::Int)
    ia_end = ia + sa * n
    sa2 = 2sa
    sd2 = 2sd
    ia_ = ia_end - sa
    @inbounds while ia < ia_
        d[id] = evaluate(op, d[id], getvalue(a, ia))
        d[id + sd] = evaluate(op, d[id+sd], getvalue(a, ia+sa))
        ia += sa2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] = evaluate(op, d[id], getvalue(a, ia))
    end
end

function paccum!{Op<:Functor{2}}(op::Op, n::Int, d::Array, id::Int, sd::Int, fun::Functor{1}, a::Array, ia::Int, sa::Int)
    ia_end = ia + sa * n
    sa2 = 2sa
    sd2 = 2sd
    ia_ = ia_end - sa
    @inbounds while ia < ia_
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia)))
        d[id + sd] = evaluate(op, d[id+sd], evaluate(fun, getvalue(a, ia+sa)))
        ia += sa2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia)))
    end
end

function paccum!{Op<:Functor{2}}(op::Op, n::Int, d::Array, id::Int, sd::Int, fun::Functor{2}, a::ArrayOrNum, ia::Int, sa::Int,
                                                                                             b::ArrayOrNum, ib::Int, sb::Int)
    ia_end = ia + sa * n
    sa2 = 2sa
    sb2 = 2sb
    sd2 = 2sd
    ia_ = ia_end - sa
    @inbounds while ia < ia_
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia), getvalue(b, ib)))
        d[id + sd] = evaluate(op, d[id+sd], evaluate(fun, getvalue(a, ia+sa), getvalue(b, ib+sb)))
        ia += sa2
        ib += sb2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia), getvalue(b, ib)))
    end
end

function paccum_fdiff!{Op<:Functor{2}}(op::Op, n::Int, d::Array, id::Int, sd::Int, fun::Functor{1}, a::ArrayOrNum, ia::Int, sa::Int,
                                                                                                   b::ArrayOrNum, ib::Int, sb::Int)
    ia_end = ia + sa * n
    sa2 = 2sa
    sb2 = 2sb
    sd2 = 2sd
    ia_ = ia_end - sa
    @inbounds while ia < ia_
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia) - getvalue(b, ib)))
        d[id + sd] = evaluate(op, d[id+sd], evaluate(fun, getvalue(a, ia+sa) - getvalue(b, ib+sb)))
        ia += sa2
        ib += sb2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia) - getvalue(b, ib)))
    end
end

function paccum!{Op<:Functor{2}}(op::Op, n::Int, d::Array, id::Int, sd::Int, fun::Functor{3}, a::ArrayOrNum, ia::Int, sa::Int,
                                                                                             b::ArrayOrNum, ib::Int, sb::Int,
                                                                                             c::ArrayOrNum, ic::Int, sc::Int)
    ia_end = ia + sa * n
    sa2 = 2sa
    sb2 = 2sb
    sc2 = 2sc
    sd2 = 2sd
    ia_ = ia_end - sa
    @inbounds while ia < ia_
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic)))
        d[id + sd] = evaluate(op, d[id+sd], evaluate(fun, getvalue(a, ia+sa), getvalue(b, ib+sb), getvalue(c, ic+sc)))
        ia += sa2
        ib += sb2
        ic += sc2
        id += sd2
    end
 
    @inbounds if ia < ia_end
        d[id] = evaluate(op, d[id], evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic)))
    end
end

#################################################
#
#   BLAS acceleration
#
#################################################

saccum{T<:BlasFP}(::Add, n::Int, f::AbsFun, a::Array{T}, ia::Int) = 
    BLAS.asum(n, pointer(a, ia), 1)

saccum{T<:BlasFP}(::Add, n::Int, f::Abs2Fun, a::Array{T}, ia::Int) = 
    (p = pointer(a, ia); BLAS.dot(n, p, 1, p, 1))

saccum{T<:BlasFP}(::Add, n::Int, f::Multiply, a::Array{T}, ia::Int, b::Array{T}, ib::Int) = 
    (pa = pointer(a, ia); pb = pointer(b, ib); BLAS.dot(n, pa, 1, pb, 1))

