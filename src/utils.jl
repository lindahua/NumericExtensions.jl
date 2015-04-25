# Some useful utilities for computation

#################################################
#
#   Repeat each element for specific times
#
#   e.g. eachrepeat([3, 4], 2) ==> [3, 3, 4, 4]
#
#################################################

function eachrepeat{T}(x::AbstractVector{T}, rt::Integer)
    # repeat each element in x for rt times

    nx = length(x)
    r = Array(T, nx * rt)
    j = 0
    for i = 1 : nx
        @inbounds xi = x[i]
        for i2 = 1 : rt
            @inbounds r[j += 1] = xi
        end
    end
    return r
end

function eachrepeat{T,I<:Integer}(x::AbstractVector{T}, rt::AbstractArray{I})
    nx = length(x)
    nx == length(rt) || throw(ArgumentError("Inconsistent array lengths."))

    r = Array(T, sum(rt))
    j = 0
    for i = 1 : nx
        @inbounds xi = x[i]
        for i2 = 1 : rt[i]
            @inbounds r[j += 1] = xi
        end
    end
    return r
end

function eachrepeat{T}(x::AbstractMatrix{T}, rt::@compat(Tuple{Int,Int}))
    mx = size(x, 1)
    nx = size(x, 2)
    r1::Int = rt[1]
    r2::Int = rt[2]

    r = Array(T, mx * r1, nx * r2)
    p::Int = 0

    for j = 1 : nx
        for j2 = 1 : r2
            for i = 1 : mx
                @inbounds xij = x[i, j]
                for i2 = 1 : r1
                    r[p += 1] = xij 
                end
            end
        end
    end
    return r
end


#################################################
#
#   Integer organization
#
#################################################

function sortindexes!{I<:Integer, C<:Integer}(x::AbstractArray{I}, sinds::AbstractArray{I}, cnts::AbstractArray{C})
    n = length(x)
    k = length(cnts)

    # count integers
    fill!(cnts, zero(C))
    for i = 1 : n
        cnts[x[i]] += 1   # no @inbounds, as no guarantee of x[i] is actually in bound
    end

    # calculate offsets
    offsets = Array(C, k)
    offsets[1] = 0
    for i = 2 : k
        @inbounds offsets[i] = offsets[i-1] + cnts[i-1]
    end

    # write sorted indexes
    for i = 1 : n
        sinds[offsets[x[i]] += 1] = i
    end
end

function sortindexes{I<:Integer}(x::AbstractArray{I}, k::Integer)
    sinds = Array(I, length(x))
    cnts = Array(Int, k)
    sortindexes!(x, sinds, cnts)
    return (sinds, cnts)
end

sortindexes{I<:Integer}(x::AbstractArray{I}) = sortindexes(x, maximum(x))

function groupindexes{I<:Integer}(x::AbstractArray{I}, k::Integer)
    sinds::Vector{I}, cnts::Vector{Int} = sortindexes(x, k)
    p = 0
    grps = Array(Vector{Int}, k)
    for i in 1 : k
        ci = cnts[i]
        grps[i] = sinds[p+1 : p+ci]
        p += ci
    end
    grps    
end

groupindexes{I<:Integer}(x::AbstractArray{I}) = groupindexes(x, maximum(x))


