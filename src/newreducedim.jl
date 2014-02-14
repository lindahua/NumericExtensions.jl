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

macro compose_reducedim(fun, BT, sker, pker, initvalf)
    # fun: the function name, e.g. sum
    # BT: the base type, e.g. Number, Real

    fun! = symbol(string(fun, '!'))
    _fun! = symbol(string('_', fun!))

    quote
        global $(_fun!)
        function $(_fun!){S<:$(BT),T<:$(BT)}(dst::DenseArray{S,2}, a::DenseArray{T,2}, r2::Bool, r1::Bool)
            a0 = parent(a)
            d0 = parent(dst)
            m, n = size(a)::(Int, Int)
            sa1, sa2 = strides(a)::(Int, Int)
            sd1, sd2 = strides(dst)::(Int, Int)
         
            ia = offset(a) + 1
            id = offset(dst) + 1
            
            if r1
                if r2
                    if sa1 == 1
                        s = $(sker)(m, a0, ia)
                        ia += sa2
                        for j = 2:n
                            s += $(sker)(m, a0, ia)
                            ia += sa2
                        end
                        d0[id] += s
                    else
                        s = $(sker)(m, a0, ia, sa1)
                        ia += sa2
                        for j = 2:n
                            s += $(sker)(m, a0, ia, sa1)
                            ia += sa2
                        end
                        d0[id] += s
                    end
                else
                    if sa1 == 1
                        for j = 1:n
                            d0[id] += $(sker)(m, a0, ia)
                            ia += sa2
                            id += sd2
                        end
                    else
                        for j = 1:n
                            d0[id] += $(sker)(m, a0, ia, sa1)
                            ia += sa2
                            id += sd2
                        end
                    end
                end
            else
                if r2
                    if sa1 == 1 && sd1 == 1
                        for j = 1:n
                            $(pker)(m, d0, id, a0, ia)
                            ia += sa2
                        end
                    else
                        for j = 1:n
                            $(pker)(m, d0, id, sd1, a0, ia, sa1)
                            ia += sa2
                        end
                    end
                else
                    if sa1 == 1 && sd1 == 1
                        for j = 1:n
                            $(pker)(m, d0, id, a0, ia)
                            ia += sa2
                            id += sd2
                        end
                    else
                        for j = 1:n
                            $(pker)(m, d0, id, sd1, a0, ia, sa1)
                            ia += sa2
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



