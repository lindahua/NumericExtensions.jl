# common functions

macro check_argdims(cond)
	:( if !($(esc(cond)))
	    throw(ArgumentError("Invalid argument dimensions.")) 
	end)  
end

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

function prec_length{N}(s::NTuple{N}, d::Int)
	d == 1 ? 1 :
	d == 2 ? s[1] :
	d == 3 ? s[1] * s[2] : prod(s[1:d-1])
end

function succ_length{N}(s::NTuple{N}, d::Int)
	d == N ? 1 :
	d == N-1 ? s[N] : prod(s[d+1:N])
end

