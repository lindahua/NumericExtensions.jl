# Operation on diagonals

function diagm{T<:Number}(d::Int, v::T)
    r = zeros(T, d, d)
    idx = 1
    dp1 = d + 1
    for i in 1 : d
        r[idx] = v
        idx += dp1
    end
    r
end

function add_diag!(x::ContiguousMatrix, v::Number)
    d::Int = min(size(x, 1), size(x, 2))
    idx = 1
    mp1 = size(x, 1) + 1
    for i in 1 : d
        x[idx] += v 
        idx += mp1
    end
    x
end

function add_diag!(x::ContiguousMatrix, v::ContiguousArray)
    d::Int = min(size(x, 1), size(x, 2))
    if length(v) != d
        throw(ArgumentError("diagonal length must match."))
    end

    idx = 1
    mp1 = size(x, 1) + 1
    for i in 1 : d
        x[idx] += v[i]
        idx += mp1
    end
    x
end

function add_diag!(x::ContiguousMatrix, v::ContiguousArray, c::Number)
    d::Int = min(size(x, 1), size(x, 2))
    if length(v) != d
        throw(ArgumentError("diagonal length must match."))
    end

    idx = 1
    mp1 = size(x, 1) + 1
    for i in 1 : d
        x[idx] += v[i] * c
        idx += mp1
    end
    x
end

add_diag(x::ContiguousMatrix, v::Number) = add_diag!(copy(x), v)
add_diag(x::ContiguousMatrix, v::ContiguousArray) = add_diag!(copy(x), v)
add_diag(x::ContiguousMatrix, v::ContiguousArray, c::Number) = add_diag!(copy(x), v, c)


function set_diag!(x::ContiguousMatrix, v::Number)
    d::Int = min(size(x, 1), size(x, 2))
    idx = 1
    mp1 = size(x, 1) + 1
    for i in 1 : d
        x[idx] = v 
        idx += mp1
    end
    x
end

function set_diag!(x::ContiguousMatrix, v::ContiguousArray)
    d::Int = min(size(x, 1), size(x, 2))
    if length(v) != d
        throw(ArgumentError("diagonal length must match."))
    end

    idx = 1
    mp1 = size(x, 1) + 1
    for i in 1 : d
        x[idx] = v[i]
        idx += mp1
    end
    x
end

function set_diag!(x::ContiguousMatrix, v::ContiguousArray, c::Number)
    d::Int = min(size(x, 1), size(x, 2))
    if length(v) != d
        throw(ArgumentError("diagonal length must match."))
    end

    idx = 1
    mp1 = size(x, 1) + 1
    for i in 1 : d
        x[idx] = v[i] * c
        idx += mp1
    end
    x
end

set_diag(x::ContiguousMatrix, v::Number) = set_diag!(copy(x), v)
set_diag(x::ContiguousMatrix, v::ContiguousArray) = set_diag!(copy(x), v)
set_diag(x::ContiguousMatrix, v::ContiguousArray, c::Number) = set_diag!(copy(x), v, c)

