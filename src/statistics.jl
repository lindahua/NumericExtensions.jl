# Reduction functions related to statistics


###################
#
#  Varm & Stdm
#
###################

# varm

function varm(x::ContiguousRealArray, mu::Real)
    !isempty(x) || error("varm: empty array is not allowed.")
    n = length(x)

    @inbounds s2 = abs2(x[1] - mu)
    for i = 2:n
        @inbounds s2 += abs2(x[i] - mu)
    end
    s2 / (n - 1)
end

function _varm_eachcol!{R<:Real}(m::Int, n::Int, dst::ContiguousArray{R}, x, mu)
    c = inv(m - 1)
    o = 0
    for j = 1:n
        s2 = zero(R)
        @inbounds mu_j = mu[j]
        for i = 1:m
            @inbounds s2 += abs2(x[o + i] - mu_j)
        end
        @inbounds dst[j] = s2 * c
        o += m
    end 
end

function _varm_eachrow!(m::Int, n::Int, dst::ContiguousRealArray, x, mu)
    o::Int = 0
    for i = 1:m
        @inbounds dst[i] = abs2(x[o + i] - mu[i])
    end
    o += m
    for j = 2:n-1
        for i = 1:m
            @inbounds dst[i] += abs2(x[o + i] - mu[i])
        end
        o += m
    end 
    c = inv(n - 1)
    for i = 1:m
        @inbounds v = dst[i] + abs2(x[o + i] - mu[i])
        dst[i] = v * c
    end
end

function varm!(dst::ContiguousRealArray, x::ContiguousRealArray, mu::ContiguousRealArray, dim::Int)
    !isempty(x) || error("varm!: empty array is not allowed.")

    nd = ndims(x)
    1 <= dim <= nd || error("varm: invalid value of dim.")

    shp = size(x)
    rlen = prod(Base.reduced_dims(shp, dim))
    length(dst) == length(mu) == rlen || error("Inconsistent argument dimensions.")

    if dim == 1
        m = shp[1]
        n = succ_length(shp, dim)
        _varm_eachcol!(m, n, dst, x, mu)

    else
        m = prec_length(shp, dim)
        n = shp[dim]
        k = succ_length(shp, dim)

        _varm_eachrow!(m, n, dst, x, mu)
        if k > 1
            mn = m * n
            ro = m
            ao = mn
            for l = 2 : k
                _varm_eachrow!(m, n, 
                    offset_view(dst, ro, m), offset_view(x, ao, m, n), 
                    offset_view(mu, ro, m))

                ro += m
                ao += mn
            end
        end
    end
    dst
end

function varm(x::ContiguousRealArray, mu::ContiguousRealArray, dim::Int)
    rsiz = Base.reduced_dims(size(x), dim)
    length(mu) == prod(rsiz) || error("Inconsistent argument dimensions.")
    R = fptype(promote_type(eltype(x), eltype(mu)))
    varm!(Array(R, rsiz), x, mu, dim)
end

# stdm

stdm(x::ContiguousRealArray, mu::Real) = sqrt(varm(x, mu))
stdm(x::ContiguousRealArray, mu::ContiguousArray, dim::Int) = sqrt!(varm(x, mu, dim))

function stdm!(dst::ContiguousRealArray, x::ContiguousRealArray, mu::ContiguousRealArray, dim::Int)
    sqrt!(varm!(dst, x, mu, dim))
end


###################
#
#  Var & Std
#
###################

var(x::ContiguousRealArray) = varm(x, mean(x))

function var!(dst::ContiguousRealArray, x::ContiguousRealArray, dim::Int)
    !isempty(dst) || error("var: empty array is not allowed.")
    nd = ndims(x)
    1 <= dim <= nd || error("var: invalid value of dim.")
    shp = size(x)

    if dim == 1
        m = shp[1]
        n = succ_length(shp, 1)
        ao = 0
        for j in 1 : n
            dst[j] = var(offset_view(x, ao, m))
            ao += m
        end     
    else
        varm!(dst, x, mean(x, dim), dim)
    end
    dst
end

function var(x::ContiguousRealArray, dim::Int)
    var!(Array(fptype(eltype(x)), Base.reduced_dims(size(x), dim)), x, dim)
end

# std

std(x::ContiguousRealArray) = sqrt(var(x))
std(x::ContiguousRealArray, dim::Int) = sqrt!(var(x, dim))
std!(dst::ContiguousRealArray, x::ContiguousRealArray, dim::Int) = sqrt!(var!(dst, x, dim))


###################
#
#  LogFunsumexp
#
###################

function logsumexp(x::ContiguousRealArray)
    !isempty(x) || error("logsumexp: empty array not allowed.")
    u = maximum(x)
    log(sumfdiff(ExpFun(), x, u)) + u
end

function _logsumexp_eachcol!(m::Int, n::Int, dst::ContiguousRealArray, x::ContiguousRealArray)
    o = 0
    for j in 1 : n
        # compute max
        u = x[o + 1]
        for i in 2 : m
            @inbounds xi = x[o + i]
            if xi > u
                u = xi
            end
        end

        # sum exp
        @inbounds s = exp(x[o + 1] - u)
        for i in 2 : m
            @inbounds s += exp(x[o + i] - u)
        end

        # compute log
        dst[j] = log(s) + u
        o += m
    end
end

function _logsumexp_eachrow!(m::Int, n::Int, dst::ContiguousRealArray, 
    u::ContiguousRealArray, x::ContiguousRealArray)

    # compute max
    for i in 1 : m
        @inbounds u[i] = x[i]
    end
    o = m
    for j in 2 : n
        for i in 1 : m
            @inbounds ui = u[i]
            @inbounds xi = x[o+i]
            if xi > ui
                @inbounds u[i] = xi
            end
        end
        o += m
    end

    # sum exp
    for i in 1 : m
        @inbounds dst[i] = exp(x[i] - u[i])
    end
    o = m
    for j in 2 : n
        for i in 1 : m
            @inbounds dst[i] += exp(x[o + i] - u[i])
        end
        o += m
    end

    # compute log
    for i in 1 : m
        @inbounds dst[i] = log(dst[i]) + u[i]
    end
end


function logsumexp!{R<:Real,T<:Real}(dst::ContiguousArray{R}, x::ContiguousRealArray{T}, dim::Int)
    !isempty(x) || error("logsumexp!: empty array not allowed.")
    nd = ndims(x)
    1 <= dim <= nd || error("logsumexp!: invalid value of dim.")
    shp = size(x)

    if dim == 1
        m = shp[1]
        n = succ_length(shp, dim)
        _logsumexp_eachcol!(m, n, dst, x)
    else
        m = prec_length(shp, dim)
        n = shp[dim]
        k = succ_length(shp, dim)

        u = Array(T, m)
        _logsumexp_eachrow!(m, n, dst, u, x)
        if k > 1
            mn = m * n
            ro = m
            ao = mn
            for l = 2 : k
                _logsumexp_eachrow!(m, n, offset_view(dst, ro, m), u, offset_view(x, ao, m, n))
                ro += m
                ao += mn
            end
        end
    end
    dst
end

function logsumexp{T<:Real}(x::ContiguousArray{T}, dim::Int)
    logsumexp!(Array(fptype(T), Base.reduced_dims(size(x), dim)), x, dim)
end


###################
#
#  Softmax
#
###################

function softmax!(dst::ContiguousRealArray, x::ContiguousRealArray)
    !isempty(x) || error("softmax!: empty array is not allowed.")
    n = length(x)
    length(dst) == n || error("Inconsistent argument dimensions.")

    u = maximum(x)
    @inbounds s = dst[1] = exp(x[1] - u)
    for i in 2 : n
        @inbounds s += (dst[i] = exp(x[i] - u))
    end
    c = inv(s)
    for i in 1 : n
        @inbounds dst[i] *= c
    end
    dst
end

softmax(x::ContiguousArray) = softmax!(Array(fptype(eltype(x)), size(x)), x)


function _softmax_eachcol!(m::Int, n::Int, dst::ContiguousRealArray, x::ContiguousRealArray)
    o = 0
    for j in 1 : n
        softmax!(offset_view(dst, o, m), offset_view(x, o, m))
        o += m
    end
end

function _softmax_eachrow!(m::Int, n::Int, dst::ContiguousRealArray, u::ContiguousRealArray, x::ContiguousRealArray)

    # compute max
    for i in 1 : m
        @inbounds u[i] = x[i]
    end
    o = m
    for j in 2 : n
        for i in 1 : m
            @inbounds ui = u[i]
            @inbounds xi = x[o + i]
            if xi > ui
                @inbounds u[i] = xi
            end
        end
        o += m
    end

    # compute sum
    s = view(u, m+1:2*m)

    for i in 1 : m
        @inbounds s[i] = dst[i] = exp(x[i] - u[i])
    end
    o = m

    for j in 2 : n
        for i in 1 : m
            @inbounds s[i] += (dst[o + i] = exp(x[o + i] - u[i]))
        end
        o += m
    end

    rcp!(s)
    o = 0
    for j in 1 : n
        for i in 1 : m
            @inbounds dst[o + i] .*= s[i]
        end
        o += m
    end
end

function softmax!{T<:Real}(dst::ContiguousRealArray, x::ContiguousArray{T}, dim::Int)
    !isempty(x) || error("softmax!: empty array is not allowed.")
    nd = ndims(x)
    1 <= dim <= nd || error("softmax!: invalid value for the dim argument.")
    shp = size(x)

    if dim == 1
        m = shp[1]
        n = succ_length(shp, dim)
        _softmax_eachcol!(m, n, dst, x)

    else
        m = prec_length(shp, dim)
        n = shp[dim]
        k = succ_length(shp, dim)

        u = Array(fptype(T), 2*m)
        _softmax_eachrow!(m, n, dst, u, x)
        if k > 1
            mn = m * n
            o = mn
            for l = 2 : k
                _softmax_eachrow!(m, n, offset_view(dst, o, m, n), u, offset_view(x, o, m, n))
                o += mn
            end
        end
    end
    dst 
end

softmax(x::ContiguousRealArray, dim::Int) = softmax!(Array(fptype(eltype(x)), size(x)), x, dim)

