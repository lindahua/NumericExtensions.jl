# Weighted sum and related reduction function

macro code_wsumfuns(AN, fname)
    h = codegen_helper(AN)

    t1 = h.term(1)
    ti = h.term(:i)
    tidx = h.term(:idx)

    fname! = symbol("$(fname)!")
    _fname! = symbol("_$(fname)!")
    aparams = h.contiguous_aparams
    args = h.args

    quote
        global $(fname)
        function ($fname)(w::ContiguousRealArray, $(aparams...))
            n::Int = $(h.inputlen)
            n == length(w) || error("Inconsistent argument dimensions.")

            if n == 0
                0.0
            else
                @inbounds s = $(t1) * w[1]
                for i = 2 : n
                    @inbounds s += ($ti) * w[i]
                end
                s
            end
        end

        global $(_fname!)
        function $(_fname!)(dst::ContiguousArray, m::Int, n::Int, k::Int, w::ContiguousRealArray, $(aparams...))

            if n == 1  # each page has a single row (simply evaluate)
                @inbounds w1 = w[1]
                for i = 1:m*k
                    @inbounds dst[i] = w1 * $(ti)
                end

            elseif m == 1  # each page has a single column
                idx = 0
                for l = 1:k
                    idx += 1
                    @inbounds s = w[1] * ($tidx)
                    for j = 2:n
                        idx += 1
                        @inbounds s += w[j] * ($tidx)
                    end
                    @inbounds dst[l] = s
                end

            elseif k == 1 # only one page
                @inbounds w1 = w[1]
                for i = 1:m
                    @inbounds dst[i] = w1 * $(ti)
                end
                idx = m
                for j = 2:n
                    @inbounds wj = w[j]
                    for i = 1:m
                        idx += 1
                        @inbounds dst[i] += wj * $(tidx)
                    end
                end

            else  # multiple generic pages
                idx = 0
                od = 0
                @inbounds w1 = w[1]
                for l = 1:k                 
                    for i = 1:m
                        idx += 1
                        @inbounds dst[od+i] = w1 * $(tidx)
                    end
                    for j = 2:n
                        @inbounds wj = w[j]
                        for i = 1:m
                            idx += 1
                            odi = od + i
                            @inbounds dst[odi] += wj * $(tidx)
                        end
                    end
                    od += m
                end
            end

            return dst
        end

        global $(fname!)
        function $(fname!)(dst::ContiguousArray, w::ContiguousRealArray, $(aparams...), dim::Int)
            shp = $(h.inputsize)
            1 <= dim <= length(shp) || error("Invalid value of dim.")
            length(w) == shp[dim] || error("Inconsistent argument dimensions.")
            m = prec_length(shp, dim)
            n = shp[dim]
            k = succ_length(shp, dim)
            $(_fname!)(dst, m, n, k, w, $(args...))
        end

        global $(fname)
        function ($fname)(w::ContiguousRealArray, $(aparams...), dim::Int)
            tt = $(h.termtype)
            shp = $(h.inputsize)
            r = Array(promote_type(tt, eltype(w)), Base.reduced_dims(shp, dim))
            ($fname!)(r, w, $(args...), dim)
        end
    end
end

@code_wsumfuns 0 wsum
@code_wsumfuns 1 wsum
@code_wsumfuns 2 wsum
@code_wsumfuns 3 wsum
@code_wsumfuns (-2) wsumfdiff


# Specialized cases

wsum{T<:BlasFP}(w::Array{T}, x::Array{T}) = Base.BLAS.dot(w, x)

function wsum!{T<:BlasFP}(dst::Array{T}, w::Array{T}, x::Vector{T}, dim::Int)
    dst[1] = wsum(x, w)
    dst
end

function wsum!{T<:BlasFP}(dst::Array{T}, w::Array{T}, x::Matrix{T}, dim::Int)
    if dim == 1
        Base.BLAS.gemv!('T', one(T), x, vec(w), zero(T), vec(dst))
    elseif dim == 2
        Base.BLAS.gemv!('N', one(T), x, vec(w), zero(T), vec(dst))
    else
        error("dim must be either 1 or 2.")
    end
    dst
end

function wsum!{T<:BlasFP}(dst::Array{T}, w::Array{T}, x::Array{T}, dim::Int)
    siz = size(x)
    nd = length(siz)
    rd = siz[dim]  # this ensures 1 <= dim <= nd

    if dim == 1
        rx = reshape(x, siz[1], succ_length(siz, 1))
        Base.BLAS.gemv!('T', one(T), rx, vec(w), zero(T), vec(dst))
    elseif dim == nd
        rx = reshape(x, prec_length(siz, nd), siz[nd])
        Base.BLAS.gemv!('N', one(T), rx, vec(w), zero(T), vec(dst))
    else
        m::Int = prec_length(siz, dim)
        n::Int = siz[dim]
        k::Int = succ_length(siz, dim)
        plen = m * n

        vw = vec(w)
        for l in 1 : k
            sx = pointer_to_array(pointer(x, plen * (l - 1) + 1), (m, n))
            sdst = pointer_to_array(pointer(dst, m * (l - 1) + 1), m)
            Base.BLAS.gemv!('N', one(T), sx, vw, zero(T), sdst) 
        end
    end
    dst
end


# Convenience functions

wsumabs(w::ContiguousRealArray, x::ContiguousArray) = wsum(w, AbsFun(), x)
wsumabs!(dst::ContiguousRealArray, w::ContiguousRealArray, x::ContiguousArray, dim::Int) = wsum!(dst, w, AbsFun(), x, dim) 
wsumabs(w::ContiguousRealArray, x::ContiguousArray, dim::Int) = wsum(w, AbsFun(), x, dim)

wsumabsdiff(w::ContiguousRealArray, x::ContiguousArray, y::ContiguousArrOrNum) = wsumfdiff(w, AbsFun(), x, y)
wsumabsdiff!(dst::ContiguousRealArray, w::ContiguousRealArray, x::ContiguousArray, y::ContiguousArrOrNum, dim::Int) = wsumfdiff!(dst, w, AbsFun(), x, y, dim) 
wsumabsdiff(w::ContiguousRealArray, x::ContiguousArray, y::ContiguousArrOrNum, dim::Int) = wsumfdiff(w, AbsFun(), x, y, dim)

wsumsq(w::ContiguousRealArray, x::ContiguousArray) = wsum(w, Abs2Fun(), x)
wsumsq!(dst::ContiguousRealArray, w::ContiguousRealArray, x::ContiguousArray, dim::Int) = wsum!(dst, w, Abs2Fun(), x, dim) 
wsumsq(w::ContiguousRealArray, x::ContiguousArray, dim::Int) = wsum(w, Abs2Fun(), x, dim)

wsumsqdiff(w::ContiguousRealArray, x::ContiguousArray, y::ContiguousArrOrNum) = wsumfdiff(w, Abs2Fun(), x, y)
wsumsqdiff!(dst::ContiguousRealArray, w::ContiguousRealArray, x::ContiguousArray, y::ContiguousArrOrNum, dim::Int) = wsumfdiff!(dst, w, Abs2Fun(), x, y, dim) 
wsumsqdiff(w::ContiguousRealArray, x::ContiguousArray, y::ContiguousArrOrNum, dim::Int) = wsumfdiff(w, Abs2Fun(), x, y, dim)

