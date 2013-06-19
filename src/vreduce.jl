#################################################
#
# 	Generic full reduction
#
#################################################

_xreshape(x::Number, m::Int, n::Int) = x
_xreshape(x::AbstractArray, m::Int, n::Int) = reshape(x, m, n)

# vreduce with init

function _code_vreduce_withinit(kergen::Symbol)
	kernel = eval(:($kergen(:i)))
	quote
		v::R = init
		for i in 1 : length(x)
			v = evaluate(op, v, $kernel)
		end
		v
	end
end

macro _vreduce_withinit(kergen)
	esc(_code_vreduce_withinit(kergen))
end

function vreduce{R<:Union(Number, Bool)}(op::BinaryFunctor, init::R, x::AbstractArray)
	@_vreduce_withinit _ker_nofun
end

function vreduce{R<:Union(Number, Bool)}(op::BinaryFunctor, init::R, f::UnaryFunctor, x::AbstractArray)
	@_vreduce_withinit _ker_unaryfun
end

function vreduce{R<:Union(Number, Bool)}(op::BinaryFunctor, init::R, f::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	@_vreduce_withinit _ker_binaryfun
end

# vreduce without init

function _code_vreduce(kergen::Symbol)
	ker1 = eval(:($kergen(1))) 
	kernel = eval(:($kergen(:i)))
	quote
		v = $ker1
		for i in 2 : n
			v = evaluate(op, v, $kernel)
		end
		v
	end
end

macro _vreduce(kergen)
	esc(_code_vreduce(kergen))
end


function vreduce(op::BinaryFunctor, x::AbstractArray)
	n = length(x)
	@_vreduce _ker_nofun
end

function vreduce(op::BinaryFunctor, f::UnaryFunctor, x::AbstractArray)
	n = length(x)
	@_vreduce _ker_unaryfun
end

function vreduce(op::BinaryFunctor, f::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	n::Int = map_length(x1, x2)
	@_vreduce _ker_binaryfun
end

function vreduce_fdiff(op::BinaryFunctor, f::UnaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	n::Int = map_length(x1, x2)
	@_vreduce _ker_fdiff
end


########################################################
#
# 	Core routines for reduction along dimensions
#
########################################################

# Matrix along (1,)

function _code_vreduce_dim1(kergen::Symbol)
	ker1 = eval(:($kergen(1, :j))) 
	kernel = eval(:($kergen(:i, :j)))
	quote
		for j in 1 : n
			v = $ker1
			for i in 2 : m
				v = evaluate(op, v, $kernel)
			end
			dst[j] = v
		end
	end
end

macro _vreduce_dim1(kergen)
	esc(_code_vreduce_dim1(kergen))
end

function vreduce_dim1!(dst::AbstractArray, op::BinaryFunctor, x::AbstractMatrix)
	m = size(x, 1)
	n = size(x, 2)
	@_vreduce_dim1 _ker_nofun
end

function vreduce_dim1!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractMatrix)
	m = size(x, 1)
	n = size(x, 2)
	@_vreduce_dim1 _ker_unaryfun
end

function vreduce_dim1!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::MatrixOrNumber, x2::MatrixOrNumber)
	siz = map_shape(x1, x2)
	m::Int = siz[1]
	n::Int = siz[2]
	@_vreduce_dim1 _ker_binaryfun
end

function vreduce_fdiff_dim1!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::MatrixOrNumber, x2::MatrixOrNumber)
	siz = map_shape(x1, x2)
	m::Int = siz[1]
	n::Int = siz[2]
	@_vreduce_dim1 _ker_fdiff
end


# Matrix along (2,)

function _code_vreduce_dim2(kergen::Symbol)
	ker1 = eval(:($kergen(:i, 1)))
	kernel = eval(:($kergen(:i, :j)))
	quote
		for i in 1 : m
			dst[i] = $ker1
		end	

		for j in 2 : n
			for i in 1 : m
				dst[i] = evaluate(op, dst[i], $kernel)
			end
		end
	end
end

macro _vreduce_dim2(kergen)
	esc(_code_vreduce_dim2(kergen))
end

function vreduce_dim2!(dst::AbstractArray, op::BinaryFunctor, x::AbstractMatrix)
	m = size(x, 1)
	n = size(x, 2)
	@_vreduce_dim2 _ker_nofun
end

function vreduce_dim2!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractMatrix)
	m = size(x, 1)
	n = size(x, 2)
	@_vreduce_dim2 _ker_unaryfun
end

function vreduce_dim2!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::MatrixOrNumber, x2::MatrixOrNumber)
	siz = map_shape(x1, x2)
	m::Int = siz[1]
	n::Int = siz[2]
	@_vreduce_dim2 _ker_binaryfun
end

function vreduce_fdiff_dim2!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::MatrixOrNumber, x2::MatrixOrNumber)
	siz = map_shape(x1, x2)
	m::Int = siz[1]
	n::Int = siz[2]
	@_vreduce_dim2 _ker_fdiff
end


# Cube along (2,)

function _code_vreduce_dim2_cube(kergen::Symbol)
	ker1 = eval(:($kergen(:i, 1, :l)))
	kernel = eval(:($kergen(:i, :j, :l)))

	quote
		for l in 1 : k
			for i in 1 : m
				dst[i,l] = $ker1
			end

			for j in 2 : n
				for i in 1 : m
					dst[i,l] = evaluate(op, dst[i,l], $kernel)
				end
			end
		end
	end
end

macro _vreduce_dim2_cube(kergen)
	esc(_code_vreduce_dim2_cube(kergen))
end

function vreduce_dim2!(dst::AbstractArray, op::BinaryFunctor, x::AbstractCube)
	m = size(x, 1)
	n = size(x, 2)
	k = size(x, 3)
	@_vreduce_dim2_cube _ker_nofun
end

function vreduce_dim2!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractCube)
	m = size(x, 1)
	n = size(x, 2)
	k = size(x, 3)
	@_vreduce_dim2_cube _ker_unaryfun
end

function vreduce_dim2!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber)
	siz = map_shape(x1, x2)
	m::Int = siz[1]
	n::Int = siz[2]
	k::Int = siz[3]
	@_vreduce_dim2_cube _ker_binaryfun
end

function vreduce_fdiff_dim2!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber)
	siz = map_shape(x1, x2)
	m::Int = siz[1]
	n::Int = siz[2]
	k::Int = siz[3]
	@_vreduce_dim2_cube _ker_fdiff
end


# Cube along (1,2)

function vreduce_dim12!(dst::AbstractArray, op::BinaryFunctor, x::AbstractCube)
	d1 = size(x, 1) * size(x, 2)
	d2 = size(x, 3)
	vreduce_dim1!(dst, op, reshape(x, d1, d2))
end

function vreduce_dim12!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractCube)
	d1 = size(x, 1) * size(x, 2)
	d2 = size(x, 3)
	vreduce_dim1!(dst, op, f, reshape(x, d1, d2))
end

function vreduce_dim12!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber)
	siz = map_shape(x1, x2)
	d1::Int = siz[1] * siz[2]
	d2::Int = siz[3]
	vreduce_dim1!(dst, op, f, _xreshape(x1, d1, d2), _xreshape(x2, d1, d2))
end

function vreduce_fdiff_dim12!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber)
	siz = map_shape(x1, x2)
	d1::Int = siz[1] * siz[2]
	d2::Int = siz[3]
	vreduce_fdiff_dim1!(dst, op, f, _xreshape(x1, d1, d2), _xreshape(x2, d1, d2))
end


# Cube along (1,3)

function vreduce_dim23!(dst::AbstractArray, op::BinaryFunctor, x::AbstractCube)
	d1 = size(x, 1)
	d2 = size(x, 2) * size(x, 3)
	vreduce_dim2!(dst, op, reshape(x, d1, d2))
end

function vreduce_dim23!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractCube)
	d1 = size(x, 1)
	d2 = size(x, 2) * size(x, 3)
	vreduce_dim2!(dst, op, f, reshape(x, d1, d2))
end

function vreduce_dim23!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber)
	siz = map_shape(x1, x2)
	d1::Int = siz[1]
	d2::Int = siz[2] * siz[3]
	vreduce_dim2!(dst, op, f, _xreshape(x1, d1, d2), _xreshape(x2, d1, d2))
end

function vreduce_fdiff_dim23!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber)
	siz = map_shape(x1, x2)
	d1::Int = siz[1]
	d2::Int = siz[2] * siz[3]
	vreduce_fdiff_dim2!(dst, op, f, _xreshape(x1, d1, d2), _xreshape(x2, d1, d2))
end


# Cube along (1,3)

function _code_vreduce_dim13_cube(kergen::Symbol)
	ker0 = eval(:($kergen(1, :j, 1)))
	ker1 = eval(:($kergen(:i, :j, 1)))
	kernel = eval(:($kergen(:i, :j, :l)))

	quote
		# first page
		for j in 1 : n
			v = $ker0
			for i in 2 : m
				v = evaluate(op, v, $ker1)
			end
			dst[j] = v
		end

		# remaining pages
		for l in 2 : k
			for j in 1 : n
				v = dst[j]
				for i in 1 : m
					v = evaluate(op, v, $kernel)
				end
				dst[j] = v
			end
		end		
	end
end

macro _vreduce_dim13_cube(kergen)
	esc(_code_vreduce_dim13_cube(kergen))
end

function vreduce_dim13!(dst::AbstractArray, op::BinaryFunctor, x::AbstractCube)
	m = size(x, 1)
	n = size(x, 2)
	k = size(x, 3)
	@_vreduce_dim13_cube _ker_nofun
end

function vreduce_dim13!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractCube)
	m = size(x, 1)
	n = size(x, 2)
	k = size(x, 3)
	@_vreduce_dim13_cube _ker_unaryfun
end

function vreduce_dim13!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber)
	siz = map_shape(x1, x2)
	m::Int = siz[1]
	n::Int = siz[2]
	k::Int = siz[3]
	@_vreduce_dim13_cube _ker_binaryfun
end

function vreduce_fdiff_dim13!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber)
	siz = map_shape(x1, x2)
	m::Int = siz[1]
	n::Int = siz[2]
	k::Int = siz[3]
	@_vreduce_dim13_cube _ker_fdiff
end


########################################################
#
# 	Generic dispatch functions
#
########################################################

# vector

function vreduce!(dst::AbstractArray, op::BinaryFunctor, x::AbstractVector, dim::Integer)
	if dim == 1
		dst[1] = vreduce(op, x)
	else
		copy!(dst, x)
	end
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractVector, dim::Integer)
	if dim == 1
		dst[1] = vreduce(op, f, x)
	else
		vmap!(dst, f, x)
	end
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::VectorOrNumber, x2::VectorOrNumber, dim::Integer)
	if dim == 1
		dst[1] = vreduce(op, f, x1, x2)
	else
		vmap!(dst, f, x1, x2)
	end
	dst
end

function vreduce_fdiff!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::VectorOrNumber, x2::VectorOrNumber, dim::Integer)
	if dim == 1
		dst[1] = vreduce_fdiff(op, f, x1, x2)
	else
		vmapdiff!(dst, f, x1, x2)
	end
	dst
end

# matrix

function vreduce!(dst::AbstractArray, op::BinaryFunctor, x::AbstractMatrix, dim::Integer)
	if dim == 1
		vreduce_dim1!(dst, op, x)
	elseif dim == 2
		vreduce_dim2!(dst, op, x)
	else
		copy!(dst, x)
	end
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractMatrix, dim::Integer)
	if dim == 1
		vreduce_dim1!(dst, op, f, x)
	elseif dim == 2
		vreduce_dim2!(dst, op, f, x)
	else
		vmap!(dst, f, x)
	end
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::MatrixOrNumber, x2::MatrixOrNumber, dim::Integer)
	if dim == 1
		vreduce_dim1!(dst, op, f, x1, x2)
	elseif dim == 2
		vreduce_dim2!(dst, op, f, x1, x2)
	else
		vmap!(dst, f, x1, x2)
	end
	dst
end

function vreduce_fdiff!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::MatrixOrNumber, x2::MatrixOrNumber, dim::Integer)
	if dim == 1
		vreduce_fdiff_dim1!(dst, op, f, x1, x2)
	elseif dim == 2
		vreduce_fdiff_dim2!(dst, op, f, x1, x2)
	else
		vmapdiff!(dst, f, x1, x2)
	end
	dst
end


# cube

function vreduce!(dst::AbstractArray, op::BinaryFunctor, x::AbstractCube, dim::Integer)
	m = size(x, 1)
	n = size(x, 2)
	k = size(x, 3)

	if dim == 1
		vreduce_dim1!(dst, op, reshape(x, m, n * k))
	elseif dim == 2
		vreduce_dim2!(reshape(dst, m, k), op, x)
	elseif dim == 3
		vreduce_dim2!(dst, op, reshape(x, m * n, k))
	else
		copy!(dst, x)
	end
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractCube, dim::Integer)
	m = size(x, 1)
	n = size(x, 2)
	k = size(x, 3)

	if dim == 1
		vreduce_dim1!(dst, op, f, reshape(x, m, n * k))
	elseif dim == 2
		vreduce_dim2!(reshape(dst, m, k), op, f, x)
	elseif dim == 3
		vreduce_dim2!(dst, op, f, reshape(x, m * n, k))
	else
		vmap!(dst, f, x)
	end
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber, dim::Integer)
	siz = map_shape(x1, x2)
	m = siz[1]
	n = siz[2]
	k = siz[3]

	if dim == 1
		nk = n * k
		vreduce_dim1!(dst, op, f, _xreshape(x1, m, nk), _xreshape(x2, m, nk))
	elseif dim == 2
		vreduce_dim2!(reshape(dst, m, k), op, f, x1, x2)
	elseif dim == 3
		mn = m * n
		vreduce_dim2!(dst, op, f, _xreshape(x1, mn, k), _xreshape(x2, mn, k))
	else
		vmap!(dst, f, x1, x2)
	end
	dst
end

function vreduce_fdiff!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber, dim::Integer)
	siz = map_shape(x1, x2)
	m = siz[1]
	n = siz[2]
	k = siz[3]

	if dim == 1
		nk = n * k
		vreduce_fdiff_dim1!(dst, op, f, _xreshape(x1, m, nk), _xreshape(x2, m, nk))
	elseif dim == 2
		vreduce_fdiff_dim2!(reshape(dst, m, k), op, f, x1, x2)
	elseif dim == 3
		mn = m * n
		vreduce_fdiff_dim2!(dst, op, f, _xreshape(x1, mn, k), _xreshape(x2, mn, k))
	else
		vmapdiff!(dst, f, x1, x2)
	end
	dst
end

# cube with rgn

function vreduce!(dst::AbstractArray, op::BinaryFunctor, x::AbstractCube, rgn::(Int, Int))
	rgn == (1, 2) ? vreduce_dim12!(dst, op, x) :
	rgn == (1, 3) ? vreduce_dim13!(dst, op, x) :
	rgn == (2, 3) ? vreduce_dim23!(dst, op, x) : 
	throw(ArgumentError("rgn must be either of (1, 2), (1, 3), or (2, 3)."))
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractCube, rgn::(Int, Int))
	rgn == (1, 2) ? vreduce_dim12!(dst, op, f, x) :
	rgn == (1, 3) ? vreduce_dim13!(dst, op, f, x) :
	rgn == (2, 3) ? vreduce_dim23!(dst, op, f, x) : 
	throw(ArgumentError("rgn must be either of (1, 2), (1, 3), or (2, 3)."))
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber, rgn::(Int, Int))
	rgn == (1, 2) ? vreduce_dim12!(dst, op, f, x1, x2) :
	rgn == (1, 3) ? vreduce_dim13!(dst, op, f, x1, x2) :
	rgn == (2, 3) ? vreduce_dim23!(dst, op, f, x1, x2) : 
	throw(ArgumentError("rgn must be either of (1, 2), (1, 3), or (2, 3)."))
	dst
end

function vreduce_fdiff!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::CubeOrNumber, x2::CubeOrNumber, rgn::(Int, Int))
	rgn == (1, 2) ? vreduce_fdiff_dim12!(dst, op, f, x1, x2) :
	rgn == (1, 3) ? vreduce_fdiff_dim13!(dst, op, f, x1, x2) :
	rgn == (2, 3) ? vreduce_fdiff_dim23!(dst, op, f, x1, x2) : 
	throw(ArgumentError("rgn must be either of (1, 2), (1, 3), or (2, 3)."))
	dst
end

# higher order arrays

function vreduce!(dst::AbstractArray, op::BinaryFunctor, x::AbstractArray, dim::Integer)
	siz = size(x)
	nd = length(siz)
	@assert nd >= 4

	if dim == 1
		dl = prod(siz[2:])
		vreduce_dim1!(dst, op, reshape(x, siz[1], dl))
	elseif dim == nd
		df = prod(siz[1:end-1])
		vreduce_dim2!(dst, op, reshape(x, df, siz[nd]))
	elseif 1 < dim < nd
		df = prod(siz[1:dim-1])
		dl = prod(siz[dim+1:])
		vreduce_dim2!(reshape(dst, df, dl), op, reshape(x, df, siz[dim], dl))
	else
		copy!(dst, x)
	end
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x::AbstractArray, dim::Integer)
	siz = size(x)
	nd = length(siz)
	@assert nd >= 4

	if dim == 1
		dl = prod(siz[2:])
		vreduce_dim1!(dst, op, f, reshape(x, siz[1], dl))
	elseif dim == nd
		df = prod(siz[1:end-1])
		vreduce_dim2!(dst, op, f, reshape(x, df, siz[nd]))
	elseif 1 < dim < nd
		df = prod(siz[1:dim-1])
		dl = prod(siz[dim+1:])
		vreduce_dim2!(reshape(dst, df, dl), op, f, reshape(x, df, siz[dim], dl))
	else
		vmap!(dst, f, x)
	end
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, f::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, dim::Integer)
	siz = map_shape(x1, x2)
	nd = length(siz)
	@assert nd >= 4

	if dim == 1
		dl = prod(siz[2:])
		vreduce_dim1!(dst, op, f, reshape(x1, siz[1], dl), reshape(x2, siz[1], dl))
	elseif dim == nd
		df = prod(siz[1:end-1])
		vreduce_dim2!(dst, op, f, reshape(x1, df, siz[nd]), reshape(x2, df, siz[nd]))
	elseif 1 < dim < nd
		df = prod(siz[1:dim-1])
		dl = prod(siz[dim+1:])
		vreduce_dim2!(reshape(dst, df, dl), op, f, reshape(x1, df, siz[dim], dl), reshape(x2, df, siz[dim], dl))
	else
		vmap!(dst, f, x1, x2)
	end
	dst
end

function vreduce_fdiff!(dst::AbstractArray, op::BinaryFunctor, f::UnaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, dim::Integer)
	siz = map_shape(x1, x2)
	nd = length(siz)
	@assert nd >= 4

	if dim == 1
		dl = prod(siz[2:])
		vreduce_fdiff_dim1!(dst, op, f, reshape(x1, siz[1], dl), reshape(x2, siz[1], dl))
	elseif dim == nd
		df = prod(siz[1:end-1])
		vreduce_fdiff_dim2!(dst, op, f, reshape(x1, df, siz[nd]), reshape(x2, df, siz[nd]))
	elseif 1 < dim < nd
		df = prod(siz[1:dim-1])
		dl = prod(siz[dim+1:])
		vreduce_fdiff_dim2!(reshape(dst, df, dl), op, f, reshape(x1, df, siz[dim], dl), reshape(x2, df, siz[dim], dl))
	else
		vmapdiff!(dst, f, x1, x2)
	end
	dst
end


# out-of-place vreduce along dimensions

typealias DimSpec Union(Int, (Int, Int))

function reduced_size(siz::(Int,), dim::Integer)
	dim == 1 ? (1,) : siz
end

function reduced_size(siz::(Int,Int), dim::Integer)
	dim == 1 ? (1,siz[2]) :
	dim == 2 ? (siz[1],1) : siz
end

function reduced_size(siz::(Int,Int,Int), dim::Integer)
	dim == 1 ? (1,siz[2],siz[3]) :
	dim == 2 ? (siz[1],1,siz[3]) :
	dim == 3 ? (siz[1],siz[2],1) : siz
end

function reduced_size(siz::NTuple{Int}, dim::Integer)
	nd = length(siz)
	dim == 1 ? tuple(1, siz[2:]...) :
	dim == nd ? tuple(siz[1:end-1]..., 1) :
	1 < dim < nd ? tuple(siz[1:dim-1]...,1,siz[dim+1:]...) :
	siz
end

function reduced_size(siz::NTuple{Int}, rgn::NTuple{Int})
	rsiz = [siz...]
	for i in rgn 
		rsiz[i] = 1
	end
	tuple(rsiz...)
end


function vreduce{T}(op::BinaryFunctor, x::AbstractArray{T}, dims::DimSpec)
	r = Array(result_type(op, T, T), reduced_size(size(x), dims))
	vreduce!(r, op, x, dims)
end

function vreduce{T}(op::BinaryFunctor, f::UnaryFunctor, x::AbstractArray{T}, dims::DimSpec)
	tt = result_type(f, T)
	r = Array(result_type(op, tt, tt), reduced_size(size(x), dims))
	vreduce!(r, op, f, x, dims)
end

function vreduce{T1,T2}(op::BinaryFunctor, f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2}, dims::DimSpec)
	tt = result_type(f, T1, T2)
	r = Array(result_type(op, tt, tt), reduced_size(map_shape(x1, x2), dims))
	vreduce!(r, op, f, x1, x2, dims)
end

function vreduce{T1,T2<:Number}(op::BinaryFunctor, f::BinaryFunctor, x1::AbstractArray{T1}, x2::T2, dims::DimSpec)
	tt = result_type(f, T1, T2)
	r = Array(result_type(op, tt, tt), reduced_size(size(x1), dims))
	vreduce!(r, op, f, x1, x2, dims)
end

function vreduce{T1<:Number,T2}(op::BinaryFunctor, f::BinaryFunctor, x1::T1, x2::AbstractArray{T2}, dims::DimSpec)
	tt = result_type(f, T1, T2)
	r = Array(result_type(op, tt, tt), reduced_size(size(x2), dims))
	vreduce!(r, op, f, x1, x2, dims)
end

function vreduce_fdiff{T1,T2}(op::BinaryFunctor, f::UnaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2}, dims::DimSpec)
	tt = result_type(f, promote_type(T1, T2))
	r = Array(result_type(op, tt, tt), reduced_size(map_shape(x1, x2), dims))
	vreduce_fdiff!(r, op, f, x1, x2, dims)
end

function vreduce_fdiff{T1,T2<:Number}(op::BinaryFunctor, f::UnaryFunctor, x1::AbstractArray{T1}, x2::T2, dims::DimSpec)
	tt = result_type(f, promote_type(T1, T2))
	r = Array(result_type(op, tt, tt), reduced_size(size(x1), dims))
	vreduce_fdiff!(r, op, f, x1, x2, dims)
end

function vreduce_fdiff{T1<:Number,T2}(op::BinaryFunctor, f::UnaryFunctor, x1::T1, x2::AbstractArray{T2}, dims::DimSpec)
	tt = result_type(f, promote_type(T1, T2))
	r = Array(result_type(op, tt, tt), reduced_size(size(x2), dims))
	vreduce_fdiff!(r, op, f, x1, x2, dims)
end


#################################################
#
# 	Basic reduction functions
#
#################################################

# sum

function vsum{T}(x::AbstractArray{T})
	isempty(x) ? zero(T) : vreduce(Add(), x)
end

function vsum{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? zero(result_type(f, T)) : vreduce(Add(), f, x)
end

function vsum{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? zero(result_type(f, T1, T2)) : vreduce(Add(), f, x1, x2)
end

vsum(x::AbstractArray, dims::DimSpec) = vreduce(Add(), x, dims)
vsum!(dst::AbstractArray, x::AbstractArray, dims::DimSpec) = vreduce!(dst, Add(), x, dims)

vsum(f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce(Add(), f, x, dims)
vsum!(dst::AbstractArray, f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce!(dst, Add(), f, x, dims)
	
function vsum(f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce(Add(), f, x1, x2, dims)
end

function vsum!(dst::AbstractArray, f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce!(dst, Add(), f, x1, x2, dims)
end

# sum on diff

function vsum_fdiff{T1<:Number,T2<:Number}(f::UnaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? zero(result_type(f, T1, T2)) : vreduce_fdiff(Add(), f, x1, x2)
end

function vsum_fdiff{T1<:Number,T2<:Number}(f::UnaryFunctor, x1::AbstractArray{T1}, x2::T2)
	isempty(x1) && isempty(x2) ? zero(result_type(f, T1, T2)) : vreduce_fdiff(Add(), f, x1, x2)
end

function vsum_fdiff{T1<:Number,T2<:Number}(f::UnaryFunctor, x1::T1, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? zero(result_type(f, T1, T2)) : vreduce_fdiff(Add(), f, x1, x2)
end

function vsum_fdiff(f::UnaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce_fdiff(Add(), f, x1, x2, dims)
end

function vsum_fdiff!(dst::AbstractArray, f::UnaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce_fdiff!(dst, Add(), f, x1, x2, dims)
end


# nonneg max

function nonneg_vmax{T}(x::AbstractArray{T})
	isempty(x) ? zero(T) : vreduce(Max(), x)
end

function nonneg_vmax{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? zero(result_type(f, T)) : vreduce(Max(), f, x)
end

function nonneg_vmax{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? zero(result_type(f, T1, T2)) : vreduce(Max(), f, x1, x2)
end

# max

function vmax{T}(x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmax cannot accept empty array.")) : vreduce(Max(), x)
end

function vmax{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmax cannot accept empty array.")) : vreduce(Max(), f, x)
end

function vmax{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? throw(ArgumentError("vmax cannot accept empty array.")) : vreduce(Max(), f, x1, x2)
end

vmax(x::AbstractArray, dims::DimSpec) = vreduce(Max(), x, dims)
vmax!(dst::AbstractArray, x::AbstractArray, dims::DimSpec) = vreduce!(dst, Max(), x, dims)

vmax(f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce(Max(), f, x, dims)
vmax!(dst::AbstractArray, f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce!(dst, Max(), f, x, dims)
	
function vmax(f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce(Max(), f, x1, x2, dims)
end

function vmax!(dst::AbstractArray, f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce!(dst, Max(), f, x1, x2, dims)
end


# min

function vmin{T}(x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmin cannot accept empty array.")) : vreduce(Min(), x)
end

function vmin{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmin cannot accept empty array.")) : vreduce(Min(), f, x)
end

function vmin{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? throw(ArgumentError("vmin cannot accept empty array.")) : vreduce(Min(), f, x1, x2)
end

vmin(x::AbstractArray, dims::DimSpec) = vreduce(Min(), x, dims)
vmin!(dst::AbstractArray, x::AbstractArray, dims::DimSpec) = vreduce!(dst, Min(), x, dims)

vmin(f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce(Min(), f, x, dims)
vmin!(dst::AbstractArray, f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce!(dst, Min(), f, x, dims)
	
function vmin(f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce(Min(), f, x1, x2, dims)
end

function vmin!(dst::AbstractArray, f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce!(dst, Min(), f, x1, x2, dims)
end



#################################################
#
# 	Derived reduction functions
#
#################################################

const asum = Base.LinAlg.BLAS.asum

vasum(x::Array) = asum(x)
vasum(x::AbstractArray) = vsum(Abs(), x)
vasum(x::AbstractArray, dims::DimSpec) = vsum(Abs(), x, dims)
vasum!(dst::AbstractArray, x::AbstractArray, dims::DimSpec) = vsum!(dst, Abs(), x, dims)

vamax(x::AbstractArray) = nonneg_vmax(Abs(), x)
vamax(x::AbstractArray, dims::DimSpec) = vmax(Abs(), x, dims)
vamax!(dst::AbstractArray, x::AbstractArray, dims::DimSpec) = vmax!(dst, Abs(), x, dims)

vamin(x::AbstractArray) = vmin(Abs(), x)
vamin(x::AbstractArray, dims::DimSpec) = vmin(Abs(), x, dims)
vamin!(dst::AbstractArray, x::AbstractArray, dims::DimSpec) = vmin!(dst, Abs(), x, dims)

vsqsum(x::Vector) = dot(x, x)
vsqsum(x::Array) = vsqsum(vec(x))
vsqsum(x::AbstractArray) = vsum(Abs2(), x)
vsqsum(x::AbstractArray, dims::DimSpec) = vsum(Abs2(), x, dims)
vsqsum!(dst::AbstractArray, x::AbstractArray, dims::DimSpec) = vsum!(dst, Abs2(), x, dims)

vdot(x::Vector, y::Vector) = dot(x, y)
vdot(x::Array, y::Array) = dot(vec(x), vec(y))
vdot(x::AbstractArray, y::AbstractArray) = vsum(Multiply(), x, y)
vdot(x::AbstractArray, y::AbstractArray, dims::DimSpec) = vsum(Multiply(), x, y, dims)
vdot!(dst::AbstractArray, x::AbstractArray, y::AbstractArray, dims::DimSpec) = vsum!(dst, Multiply(), x, y, dims)

vadiffsum(x::AbstractArray, y::ArrayOrNumber) = vsum_fdiff(Abs(), x, y)
vadiffsum(x::AbstractArray, y::ArrayOrNumber, dims::DimSpec) = vsum_fdiff(Abs(), x, y, dims)
function vadiffsum!(dst::AbstractArray, x::AbstractArray, y::ArrayOrNumber, dims::DimSpec)
	vsum_fdiff!(dst, Abs(), x, y, dims)
end

vadiffmax(x::AbstractArray, y::ArrayOrNumber) = vreduce_fdiff(Max(), Abs(), x, y)
vadiffmax(x::AbstractArray, y::ArrayOrNumber, dims::DimSpec) = vreduce_fdiff(Max(), Abs(), x, y, dims)
function vadiffmax!(dst::AbstractArray, x::AbstractArray, y::ArrayOrNumber, dims::DimSpec)
	vreduce_fdiff!(dst, Max(), Abs(), x, y, dims)
end

vadiffmin(x::AbstractArray, y::ArrayOrNumber) = vreduce_fdiff(Min(), Abs(), x, y)
vadiffmin(x::AbstractArray, y::ArrayOrNumber, dims::DimSpec) = vreduce_fdiff(Min(), Abs(), x, y, dims)
function vadiffmin!(dst::AbstractArray, x::AbstractArray, y::ArrayOrNumber, dims::DimSpec)
	vreduce_fdiff!(dst, Min(), Abs(), x, y, dims)
end

vsqdiffsum(x::AbstractArray, y::ArrayOrNumber) = vsum_fdiff(Abs2(), x, y)
vsqdiffsum(x::AbstractArray, y::ArrayOrNumber, dims::DimSpec) = vsum_fdiff(Abs2(), x, y, dims)
function vsqdiffsum!(dst::AbstractArray, x::AbstractArray, y::ArrayOrNumber, dims::DimSpec)
	vsum_fdiff!(dst, Abs2(), x, y, dims)
end

# vnorm

function vnorm(x::AbstractArray, p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? vasum(x) :
	p == 2 ? sqrt(vsqsum(x)) :	
	isinf(p) ? vamax(x) :
	vsum(FixAbsPow(p), x) .^ inv(p)
end

vnorm(x::AbstractArray) = vnorm(x, 2)

function vnorm!(dst::AbstractArray, x::AbstractArray, p::Real, dims::DimSpec)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? vasum!(dst, x, dims) :
	p == 2 ? vmap!(Sqrt(), vsqsum!(dst, x, dims)) :	
	isinf(p) ? vamax!(dst, x, dims) :
	vmap!(FixAbsPow(inv(p)), vsum!(dst, FixAbsPow(p), x, dims))
end

function vnorm{Tx<:Number,Tp<:Real}(x::AbstractArray{Tx}, p::Tp, dims::DimSpec) 
	tt = to_fptype(promote_type(Tx, Tp))
	r = Array(tt, reduced_size(size(x), dims))
	vnorm!(r, x, p, dims)
	r
end

# vdiffnorm

function vdiffnorm(x::AbstractArray, y::ArrayOrNumber, p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? vadiffsum(x, y) :
	p == 2 ? sqrt(vsqdiffsum(x, y)) :	
	isinf(p) ? vadiffmax(x, y) :
	vsum_fdiff(FixAbsPow(p), x, y) .^ inv(p)
end

vdiffnorm(x::AbstractArray, y::ArrayOrNumber) = vdiffnorm(x, y, 2)

function vdiffnorm!(dst::AbstractArray, x::AbstractArray, y::ArrayOrNumber, p::Real, dims::DimSpec)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? vadiffsum!(dst, x, y, dims) :
	p == 2 ? vmap!(Sqrt(), vsqdiffsum!(dst, x, y, dims)) :	
	isinf(p) ? vadiffmax!(dst, x, y, dims) :
	vmap!(FixAbsPow(inv(p)), vsum_fdiff!(dst, FixAbsPow(p), x, y, dims))
end

function vdiffnorm{Tx<:Number,Ty<:Number,Tp<:Real}(x::AbstractArray{Tx}, y::AbstractArray{Ty}, p::Tp, dims::DimSpec) 
	tt = to_fptype(promote_type(promote_type(Tx, Ty), Tp))
	r = Array(tt, reduced_size(size(x), dims))
	vdiffnorm!(r, x, y, p, dims)
	r
end

