# map operations to elements

# mapped array

import Base.getindex, Base.size, Base.length

immutable MappedArray1{Op<:UnaryFunctor, A1<:AbstractArray} <: AbstractArray
	op::Op
	a1::A1
end

length(m::MappedArray1) = length(m.a1)
size(m::MappedArray1) = size(m.a1)
size(m::MappedArray1, d::Integer) = size(m.a1, d)

getindex(m::MappedArray1, i::Integer) = evaluate(m.op, getindex(m.a1, i))
getindex(m::MappedArray1, i::Integer, j::Integer) = evaluate(m.op, getindex(m.a1, i, j))


# one argument

# function vmap!(op::UnaryFunctor, dst::AbstractArray, x::AbstractArray)
# 	for i in 1 : length(dst)
# 		dst[i] = evaluate(op, x[i])
# 	end
# 	dst
# end

vmap!(op::UnaryFunctor, dst::AbstractArray, x::AbstractArray) = copy!(dst, MappedArray1(op, x))
vmap!(op::UnaryFunctor, x::AbstractArray) = vmap!(op, x, x)

vmap{T}(op::UnaryFunctor, x::AbstractArray{T}) = vmap!(op, Array(result_type(op, T), size(x)), x)

# two arguments

function vmap!(op::BinaryFunctor, dst::AbstractArray, x1::AbstractArray, x2::AbstractArray)
	for i in 1 : length(dst)
		dst[i] = evaluate(op, x1[i], x2[i])
	end
	dst
end

function vmap!(op::BinaryFunctor, dst::AbstractArray, x1::AbstractArray, x2::Number)
	for i in 1 : length(dst)
		dst[i] = evaluate(op, x1[i], x2)
	end
	dst
end

function vmap!(op::BinaryFunctor, dst::AbstractArray, x1::Number, x2::AbstractArray)
	for i in 1 : length(dst)
		dst[i] = evaluate(op, x1, x2[i])
	end
	dst
end

vmap!(op::BinaryFunctor, x1::AbstractArray, x2::AbstractArray) = vmap!(op, x1, x1, x2)
vmap!(op::BinaryFunctor, x1::AbstractArray, x2::Number) = vmap!(op, x1, x1, x2)

function vmap{T1,T2}(op::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	vmap!(op, Array(result_type(op, T1, T2), promote_shape(size(x1), size(x2))), x1, x2)
end

function vmap{T1,T2<:Number}(op::BinaryFunctor, x1::AbstractArray{T1}, x2::T2)
	vmap!(op, Array(result_type(op, T1, T2), size(x1)), x1, x2)
end

function vmap{T1<:Number,T2}(op::BinaryFunctor, x1::T1, x2::AbstractArray{T2})
	vmap!(op, Array(result_type(op, T1, T2), size(x2)), x1, x2)
end

