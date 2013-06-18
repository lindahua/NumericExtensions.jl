#################################################
#
# 	Generic full reduction
#
#################################################

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

function vreduce_dim2!{T}(dst::AbstractArray, op::BinaryFunctor, x::AbstractArray{T,3})
	m = size(x, 1)
	n = size(x, 2)
	k = size(x, 3)
	@_vreduce_dim2_cube _ker_nofun
end


# Cube along (1,2)

function vreduce_dim12!{T}(dst::AbstractArray, op::BinaryFunctor, x::AbstractArray{T,3})
	vreduce_dim1!(dst, op, reshape(x, size(x,1) * size(x,2), size(x,3)))
end

# Cube along (1,3)

function vreduce_dim23!{T}(dst::AbstractArray, op::BinaryFunctor, x::AbstractArray{T,3})
	vreduce_dim2!(dst, op, reshape(x, size(x,1), size(x,2) * size(x,3)))
end

# Cube along (2,3)

function _code_vreduce_dim13_cube(kergen::Symbol)
	ker1 = eval(:($kergen(:i, :j, 1)))
	kernel = eval(:($kergen(:i, :j, :l)))

	quote
		# first page
		for j in 1 : n
			v = x[1,j,1]
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

function vreduce_dim13!{T}(dst::AbstractArray, op::BinaryFunctor, x::AbstractArray{T,3})
	m = size(x, 1)
	n = size(x, 2)
	k = size(x, 3)
	@_vreduce_dim13_cube _ker_nofun
end


########################################################
#
# 	Generic function for reduction along dimensions
#
########################################################

function vreduce!(dst::AbstractArray, op::BinaryFunctor, x::AbstractVector, dim::Integer)
	if dim == 1
		dst[1] = vreduce(op, x)
	else
		copy!(dst, x)
	end
	dst
end

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

function vreduce!{T}(dst::AbstractArray, op::BinaryFunctor, x::AbstractArray{T,3}, dim::Integer)
	if dim == 1
		vreduce_dim1!(dst, op, reshape(x, size(x,1), size(x,2) * size(x,3)))
	elseif dim == 2
		vreduce_dim2!(reshape(dst, size(x,1), size(x,3)), op, x)
	elseif dim == 3
		vreduce_dim2!(dst, op, reshape(x, size(x,1) * size(x,2), size(x,3)))
	else
		copy!(dst, x)
	end
	dst
end

function vreduce!(dst::AbstractArray, op::BinaryFunctor, x::AbstractArray, dim::Integer)
	siz = size(x)
	nd = length(siz)
	@assert nd >= 4

	if dim == 1
		vreduce_dim1!(dst, op, reshape(x, siz[1], prod(siz[2:])))
	elseif dim == nd
		vreduce_dim2!(dst, op, reshape(x, prod(siz[1:end-1]), siz[end]))
	elseif 1 < dim < nd
		df = prod(siz[1:dim-1])
		dl = prod(siz[dim+1:])
		vreduce_dim2!(reshape(dst, df, dl), op, reshape(x, df, siz[dim], dl))
	else
		copy!(dst, x)
	end
	dst
end

function vreduce!{T}(dst::AbstractArray, op::BinaryFunctor, x::AbstractArray{T,3}, rgn::(Int, Int))
	rgn == (1, 2) ? vreduce_dim12!(dst, op, x) :
	rgn == (1, 3) ? vreduce_dim13!(dst, op, x) :
	rgn == (2, 3) ? vreduce_dim23!(dst, op, x) : 
	throw(ArgumentError("rgn must be either of (1, 2), (1, 3), or (2, 3)."))
	dst
end


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


function vreduce{T}(op::BinaryFunctor, x::AbstractArray{T}, dim::Integer)
	r = Array(result_type(op, T, T), reduced_size(size(x), dim))
	vreduce!(r, op, x, dim)
end

function vreduce{T}(op::BinaryFunctor, x::AbstractArray{T,3}, rgn::(Int, Int))
	r = Array(result_type(op, T, T), reduced_size(size(x), rgn))
	vreduce!(r, op, x, rgn)
end


#################################################
#
# 	Basic reduction functions
#
#################################################

typealias DimSpec Union(Int, (Int, Int))

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

vsum(f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce!(Add(), f, x, dims)
vsum!(dst::AbstractArray, f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce!(dst, Add(), f, x, dims)
	
function vsum(f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce!(dst, Add(), f, x1, x2, dims)
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

vmax(f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce!(Max(), f, x, dims)
vmax!(dst::AbstractArray, f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce!(dst, Max(), f, x, dims)
	
function vmax(f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce!(dst, Max(), f, x1, x2, dims)
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

vmin(f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce!(Min(), f, x, dims)
vmin!(dst::AbstractArray, f::UnaryFunctor, x::AbstractArray, dims::DimSpec) = vreduce!(dst, Min(), f, x, dims)
	
function vmin(f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray, dims::DimSpec)
	vreduce!(dst, Min(), f, x1, x2, dims)
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
vasum(x::Array, dims::DimSpec) = vsum(Abs(), x, dims)
vasum!(dst::AbstractArray, x::AbstractArray, dims::DimSpec) = vsum!(dst, Abs(), x, dims)

vamax(x::AbstractArray) = nonneg_vmax(Abs(), x)
vamin(x::AbstractArray) = vmin(Abs(), x)

vsqsum(x::Vector) = dot(x, x)
vsqsum(x::Array) = vsqsum(vec(x))
vsqsum(x::AbstractArray) = vsum(Abs2(), x)

vdot(x::Vector, y::Vector) = dot(x, y)
vdot(x::Array, y::Array) = dot(vec(x), vec(y))
vdot(x::AbstractArray, y::AbstractArray) = vsum(Multiply(), x, y)

vadiffsum(x::AbstractArray, y::Union(AbstractArray,Number)) = vsum_fdiff(Abs(), x, y)
vadiffmax(x::AbstractArray, y::Union(AbstractArray,Number)) = vreduce_fdiff(Max(), Abs(), x, y)
vadiffmin(x::AbstractArray, y::Union(AbstractArray,Number)) = vreduce_fdiff(Min(), Abs(), x, y)
vsqdiffsum(x::AbstractArray, y::Union(AbstractArray,Number)) = vsum_fdiff(Abs2(), x, y)

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

function vdiffnorm(x::AbstractArray, y::Union(AbstractArray,Number), p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? vadiffsum(x, y) :
	p == 2 ? sqrt(vsqdiffsum(x, y)) :	
	isinf(p) ? vadiffmax(x, y) :
	vsum_fdiff(FixAbsPow(p), x, y) .^ inv(p)
end

vnorm(x::AbstractArray) = vnorm(x, 2)
vdiffnorm(x::AbstractArray, y::Union(AbstractArray,Number)) = vdiffnorm(x, y, 2)



