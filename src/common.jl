# common functions

# shape inference for mapping

map_shape(x1::AbstractArray) = size(x1)

map_shape(x1::AbstractArray, x2::Number) = size(x1)
map_shape(x1::Number, x2::AbstractArray) = size(x2)
map_shape(x1::AbstractArray, x2::AbstractArray) = promote_shape(size(x1), size(x2))

map_shape(x1::AbstractArray, x2::AbstractArray, x3::AbstractArray) = promote_shape(size(x1), map_shape(x2, x3))
map_shape(x1::AbstractArray, x2::AbstractArray, x3::Number) = map_shape(x1, x2)
map_shape(x1::AbstractArray, x2::Number, x3::AbstractArray) = map_shape(x1, x3)
map_shape(x1::Number, x2::AbstractArray, x3::AbstractArray) = map_shape(x2, x3)
map_shape(x1::AbstractArray, x2::Number, x3::Number) = size(x1)
map_shape(x1::Number, x2::AbstractArray, x3::Number) = size(x2)
map_shape(x1::Number, x2::Number, x3::AbstractArray) = size(x3)

# get length value from shape

function _precede_length(s::(Int,), d::Int)
	dim == 1 ? 1 : throw(BoundsError())
end

function _precede_length(s::(Int,Int), d::Int)
	d == 2 ? s[1] : throw(BoundsError())
end

function _precede_length(s::(Int, Int, Int), d::Int)
	d == 2 ? s[1] : 
	d == 3 ? s[1] * s[2] :
	throw(BoundsError())
end

function _precede_length{N}(s::NTuple{N}, d::Int)
	2 <= d <= N ? prod(s[1:d-1]) : throw(BoundsError())
end

function _trail_length(s::(Int,), d::Int)
	d == 1 ? 1 : throw(BoundsError())
end

function _trail_length(s::(Int,Int), d::Int)
	d == 1 ? s[2] : throw(BoundsError())
end

function _trail_length(s::(Int, Int, Int), d::Int)
	d == 1 ? s[2] * s[3] :
	d == 2 ? s[3] :
	throw(BoundsError())
end

function _trail_length{N}(s::NTuple{N}, d::Int)
	1 <= d <= N-1 ? prod(s[d+1:N]) : throw(BoundsError())
end

