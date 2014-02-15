# reduce along dimensions

## auxiliary functions

_rtup(siz::NTuple{1,Int}, d::Int) = (d == 1 ? (true,) : (false,))
 
_rtup(siz::NTuple{2,Int}, d::Int) = (d == 1 ? (false, true) :
                                     d == 2 ? (true, false) : 
                                              (false, false) )
 
_rtup(siz::NTuple{3,Int}, d::Int) = (d == 1 ? (false, false, true) :
                                     d == 2 ? (false, true, false) : 
                                     d == 3 ? (true, false, false) : 
                                              (false, false, false))
 
_rtup{N}(siz::NTuple{N,Int}, d::Int) = (ds = fill(false,N); ds[N+1-d]=true; tuple(ds...))::NTuple{N,Bool}
 
function _rtup{N}(siz::NTuple{N,Int}, dims::Dims)
    ds = fill(false,N)
    for d in dims
        ds[N+1-d] = true
    end
    return tuple(ds...)::NTuple{N,Bool}
end

## main macro

macro compose_reducedim(fun, BT, OT, AN)
    # fun: the function name, e.g. sum
    # BT: the base type, e.g. Number, Real

    fun! = symbol(string(fun, '!'))
    _fun! = symbol(string('_', fun!))

    if AN == 0
        getparents = :(a0 = parent(a))
        getsize = :(size(a))
        getstrides = :((sa1, sa2) = strides(a)::(Int, Int))
        getoffsets = :(ia = offset(a) + 1)
        contcol = :(sa1 == 1)
        imovs = :(ia += sa2)
        kargs = [:a0, :ia]
        kargs1 = [:a0, :ia, :sa1]
    elseif AN == 1
        getparents = :(a0 = parent(a))
        getsize = :(size(a))
        getstrides = :((sa1, sa2) = strides(a)::(Int, Int))
        getoffsets = :(ia = offset(a) + 1)
        contcol = :(sa1 == 1)
        imovs = :(ia += sa2)
        kargs = [:fun, :a0, :ia]
        kargs1 = [:fun, :a0, :ia, :sa1]
    elseif AN == 2 || AN == -2
        getparents = :(a0 = parent(a); b0 = parent(b))
        getsize = :(mapshape(a, b))
        getstrides = :((sa1, sa2) = strides(a)::(Int, Int); 
                       (sb1, sb2) = strides(b)::(Int, Int))
        getoffsets = :(ia = offset(a) + 1; ib = offset(b) + 1)
        contcol = :(sa1 == 1 && sb1 == 1)
        imovs = :(ia += sa2; ib += sb2)
        kargs = [:fun, :a0, :ia, :b0, :ib]
        kargs1 = [:fun, :a0, :ia, :sa1, :b0, :ib, :sb1]
    elseif AN == 3
        getparents = :(a0 = parent(a); b0 = parent(b); c0 = parent(c))
        getsize = :(mapshape(a, b, c))
        getstrides = :((sa1, sa2) = strides(a)::(Int, Int); 
                       (sb1, sb2) = strides(b)::(Int, Int);
                       (sc1, sc2) = strides(c)::(Int, Int))
        getoffsets = :(ia = offset(a) + 1; ib = offset(b) + 1; ic = offset(c) + 1)
        contcol = :(sa1 == 1 && sb1 == 1 && sc1 == 1)
        imovs = :(ia += sa2; ib += sb2; ic += sc2)
        kargs = [:fun, :a0, :ia, :b0, :ib, :c0, :ic]
        kargs1 = [:fun, :a0, :ia, :sa1, :b0, :ib, :sb1, :c0, :ic, :sc1]
    else
        error("Unsupported AN value")
    end      

    quote
        global $(_fun!)
        function $(_fun!){S<:$(BT),T<:$(BT)}(dst::DenseArray{S,2}, a::DenseArray{T,2}, r2::Bool, r1::Bool)
            $(getparents)
            d0 = parent(dst)
            m, n = $(getsize)::(Int, Int)
            $(getstrides)
            sd1, sd2 = strides(dst)::(Int, Int)
         
            $(getoffsets)
            id = offset(dst) + 1
            
            if r1
                if r2
                    if $(contcol)
                        s = $(saccumf)($OT, m, $(kargs...))
                        $(imovs)
                        for j = 2:n
                            s += $(saccumf)($OT, m, $(kargs...))
                            $(imovs)
                        end
                        d0[id] += s
                    else
                        s = $(saccumf)($OT, m, $(kargs1...))
                        $(imovs)
                        for j = 2:n
                            s += $(saccumf)($OT, m, $(kargs1...))
                            $(imovs)
                        end
                        d0[id] += s
                    end
                else
                    if $(contcol)
                        for j = 1:n
                            d0[id] += $(saccumf)($OT, m, $(kargs...))
                            $(imovs)
                            id += sd2
                        end
                    else
                        for j = 1:n
                            d0[id] += $(saccumf)($OT, m, $(kargs1...))
                            $(imovs)
                            id += sd2
                        end
                    end
                end
            else
                if r2
                    if $(contcol)
                        for j = 1:n
                            $(paccumf)($OT, m, d0, id, $(kargs...))
                            $(imovs)
                        end
                    else
                        for j = 1:n
                            $(pker)(m, d0, id, sd1, $(kargs1...))
                            $(imovs)
                        end
                    end
                else
                    if $(contcol) && sd1 == 1
                        for j = 1:n
                            $(pker)(m, d0, id, $(kargs...))
                            $(imovs)
                            id += sd2
                        end
                    else
                        for j = 1:n
                            $(pker)(m, d0, id, sd1, $(kargs1...))
                            $(imovs)
                            id += sd2
                        end
                    end
                end
            end
        end

        function $(_fun!){S<:$(BT),T<:$(BT),N}(dst::DenseArray{S,N}, a::DenseArray{T,N}, reduc::Bool, rr::Bool...)
            n = size(a, N)::Int
            if reduc
                _dst = ellipview(dst, 1)
                for i = 1:n
                    $(_fun!)(_dst, ellipview(a, i), rr...)
                end
            else
                for i = 1:n
                    $(_fun!)(ellipview(dst, i), ellipview(a, i), rr...)
                end
            end
        end    
         
        function $(_fun!){S<:$(BT),T<:$(BT),N}(dst::DenseArray{S,N}, a::DenseArray{T,N}, dims::Union(Int,Dims))
            $(_fun!)(dst, a, _rtup(size(a), dims)...)
            return dst
        end

        global $(fun!)
        function $(fun!){S<:$(BT),T<:$(BT),N}(dst::ContiguousArray{S,N}, a::DenseArray{T,N}, dims::Union(Int,Dims))
            rsiz = Base.reduced_dims(size(a), dims)::NTuple{N,Int}
            prod(rsiz) == length(dst) || throw(DimensionMismatch("Incorrect size of dst."))
            $(_fun!)(contiguous_view(dst, rsiz), a, dims)
        end

        global $(fun)
        $(fun){T<:$(BT),N}(a::DenseArray{T,N}, dims::Union(Int,Dims)) = 
            $(_fun!)(fill($(initvalf)(T), Base.reduced_dims(size(a),dims)), a, dims)
    end
end 
 
# @compose_reducedim sum Number vecsum vecadd! suminit



