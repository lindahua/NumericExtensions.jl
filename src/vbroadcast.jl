# A set of inplace broadcasting functions

function _check_dimlen(a::AbstractArray, b::AbstractArray, dim::Int)
	size(a, dim) == length(b) ? nothing : throw(ArgumentError("Argument dimensions must match."))
end

# broadcast along specific dimension(s)

function vbroadcast!(dst::StridedMatrix, f::BinaryFunctor, a::Matrix, b::AbstractArray, dim::Int)
	_check_dimlen(a, b, dim)
	m = size(a, 1)
	n = size(a, 2)
	if dim == 1
		o = 0
		for j in 1 : n
			for i in 1 : m
				oi = o + i
				dst[oi] = evaluate(f, a[oi], b[i])
			end
			o += m
		end
	elseif dim == 2
		o = 0
		for j in 1 : n
			bj = b[j]
			for i in 1 : m
				oi = o + i
				dst[oi] = evaluate(f, a[oi], bj)
			end
			o += m
		end
	else
		throw(ArgumentError("dim must be either 1 or 2."))
	end
	dst
end

function vbroadcast!{R,T}(dst::Array{R,3}, f::BinaryFunctor, a::Array{T,3}, b::AbstractArray, dim::Int)
	_check_dimlen(a, b, dim)
	m = size(a, 1)
	n = size(a, 2)
	k = size(a, 3)
	if dim == 1
		nk = n * k
		vbroadcast!(reshape(dst, m, nk), f, reshape(a, m, nk), b, 1)
	elseif dim == 2
		for l in 1 : k
			for j in 1 : n
				bj = b[j]
				for i in 1 : m
					dst[i,j,l] = evaluate(f, a[i,j,l], bj)
				end
			end
		end
	elseif dim == 3
		mn = m * n
		vbroadcast!(reshape(dst, mn, k), f, reshape(a, mn, k), b, 2)
	else
		throw(ArgumentError("dim must be either 1 or 2."))
	end
	dst
end

function vbroadcast!{R,T}(dst::Array{R,3}, f::BinaryFunctor, a::Array{T,3}, b::AbstractMatrix, dims::(Int, Int))
	if !(size(b, 1) == size(a, dims[1]) && size(b, 2) == size(a, dims[2]))
		throw(ArgumentError("Argument dimensions must match."))
	end

	m = size(a, 1)
	n = size(a, 2)
	k = size(a, 3)

	if dims == (1, 2)
		mn = m * n
		vbroadcast!(reshape(dst, mn, k), f, reshape(a, mn, k), b, 1)
	elseif dims == (1, 3)
		for l in 1 : k
			for j in 1 : n
				for i in 1 : m
					dst[i,j,l] = evaluate(f, a[i,j,l], b[i,l])
				end
			end
		end
	elseif dims == (2, 3)
		nk = n * k
		vbroadcast!(reshape(dst, m, nk), f, reshape(a, m, nk), b, 2)
	else
		throw(ArgumentError("dim must be either 1 or 2."))
	end
	dst
end

vbroadcast!(f::BinaryFunctor, a::Array, b::AbstractArray, dims::DimSpec) = vbroadcast!(a, f, a, b, dims)

function vbroadcast(f::BinaryFunctor, a::Array, b::AbstractArray, dims::DimSpec)
	R = result_type(f, eltype(a), eltype(b))
	vbroadcast!(Array(R, size(a)), f, a, b, dims)
end

# Specific broadcasting function

badd!(a::Array, b::AbstractArray, dims::DimSpec) = vbroadcast!(Add(), a, b, dims)
bsubtract!(a::Array, b::AbstractArray, dims::DimSpec) = vbroadcast!(Subtract(), a, b, dims)
bmultiply!(a::Array, b::AbstractArray, dims::DimSpec) = vbroadcast!(Multiply(), a, b, dims)
bdivide!(a::Array, b::AbstractArray, dims::DimSpec) = vbroadcast!(Divide(), a, b, dims)

badd(a::Array, b::AbstractArray, dims::DimSpec) = vbroadcast(Add(), a, b, dims)
bsubtract(a::Array, b::AbstractArray, dims::DimSpec) = vbroadcast(Subtract(), a, b, dims)
bmultiply(a::Array, b::AbstractArray, dims::DimSpec) = vbroadcast(Multiply(), a, b, dims)
bdivide(a::Array, b::AbstractArray, dims::DimSpec) = vbroadcast(Divide(), a, b, dims)


