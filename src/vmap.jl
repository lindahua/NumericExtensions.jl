# map operations to elements

# auxiliary functions

get_scalar(x::AbstractArray, i::Int) = x[i]
get_scalar(x::AbstractArray, i::Int, j::Int) = x[i,j]
get_scalar(x::AbstractArray, i::Int, j::Int, k::Int) = x[i,j,k]

get_scalar(x::Number, i::Int) = x
get_scalar(x::Number, i::Int, j::Int) = x
get_scalar(x::Number, i::Int, j::Int, k::Int) = x

typealias ArrayOrNumber Union(AbstractArray, Number)
typealias VectorOrNumber Union(AbstractVector, Number)
typealias MatrixOrNumber Union(AbstractMatrix, Number)
typealias AbstractCube{T} AbstractArray{T,3}
typealias CubeOrNumber Union(AbstractCube, Number)

map_shape(x1::AbstractArray, x2::AbstractArray) = promote_shape(size(x1), size(x2))
map_shape(x1::AbstractArray, x2::Number) = size(x1)
map_shape(x1::Number, x2::AbstractArray) = size(x2)

function map_length(x1::AbstractArray, x2::AbstractArray)
	if length(x1) != length(x2)
		throw(ArgumentError("Argment lengths must match."))
	end
	length(x1)
end

map_length(x1::AbstractArray, x2::Number) = length(x1)
map_length(x1::Number, x2::AbstractArray) = length(x2)

result_eltype{T}(op::UnaryFunctor, x::AbstractArray{T}) = result_type(op, T)
result_eltype{T1,T2}(op::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2}) = result_type(op, T1, T2)
result_eltype{T1,T2<:Number}(op::BinaryFunctor, x1::AbstractArray{T1}, x2::T2) = result_type(op, T1, T2)
result_eltype{T1<:Number,T2}(op::BinaryFunctor, x1::T1, x2::AbstractArray{T2}) = result_type(op, T1, T2)

# one argument

function vmap!(op::UnaryFunctor, dst::AbstractArray, x::AbstractArray)
	for i in 1 : length(dst)
		dst[i] = evaluate(op, x[i])
	end
	dst
end

vmap!(op::UnaryFunctor, x::AbstractArray) = vmap!(op, x, x)

vmap(op::UnaryFunctor, x::AbstractArray) = vmap!(op, Array(result_eltype(op, x), size(x)), x)

# two arguments

function vmap!(op::BinaryFunctor, dst::AbstractArray, x1::ArrayOrNumber, x2::ArrayOrNumber)
	for i in 1 : length(dst)
		dst[i] = evaluate(op, get_scalar(x1, i), get_scalar(x2, i))
	end
	dst
end

vmap!(op::BinaryFunctor, x1::AbstractArray, x2::ArrayOrNumber) = vmap!(op, x1, x1, x2)

function vmap(op::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	vmap!(op, Array(result_eltype(op, x1, x2), map_shape(x1, x2)), x1, x2)
end

