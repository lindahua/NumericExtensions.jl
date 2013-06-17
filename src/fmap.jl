# map operations to elements

# one argument

function fmap!(op::UnaryFunctor, dst::AbstractArray, x::AbstractArray)
	for i in 1 : length(dst)
		dst[i] = evaluate(op, x[i])
	end
	dst
end

fmap!(op::UnaryFunctor, x::AbstractArray) = fmap!(op, x, x)

fmap{T}(op::UnaryFunctor, x::AbstractArray{T}) = fmap!(op, Array(result_type(op, T), size(x)), x)

# two arguments

function fmap!(op::BinaryFunctor, dst::AbstractArray, x1::AbstractArray, x2::AbstractArray)
	for i in 1 : length(dst)
		dst[i] = evaluate(op, x1[i], x2[i])
	end
	dst
end

function fmap!(op::BinaryFunctor, dst::AbstractArray, x1::AbstractArray, x2::Number)
	for i in 1 : length(dst)
		dst[i] = evaluate(op, x1[i], x2)
	end
	dst
end

function fmap!(op::BinaryFunctor, dst::AbstractArray, x1::Number, x2::AbstractArray)
	for i in 1 : length(dst)
		dst[i] = evaluate(op, x1, x2[i])
	end
	dst
end

fmap!(op::BinaryFunctor, x1::AbstractArray, x2::AbstractArray) = fmap!(op, x1, x1, x2)
fmap!(op::BinaryFunctor, x1::AbstractArray, x2::Number) = fmap!(op, x1, x1, x2)

function fmap{T1,T2}(op::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	fmap!(op, Array(result_type(op, T1, T2), promote_shape(size(x1), size(x2))), x1, x2)
end

function fmap{T1,T2<:Number}(op::BinaryFunctor, x1::AbstractArray{T1}, x2::T2)
	fmap!(op, Array(result_type(op, T1, T2), size(x1)), x1, x2)
end

function fmap{T1<:Number,T2}(op::BinaryFunctor, x1::T1, x2::AbstractArray{T2})
	fmap!(op, Array(result_type(op, T1, T2), size(x2)), x1, x2)
end

