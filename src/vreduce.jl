#################################################
#
# 	Generic full reduction
#
#################################################

function vreduce{R<:Union(Number, Bool)}(op::BinaryFunctor, init::R, x::AbstractArray)
	v::R = init
	for i in 1 : length(x)
		v = evaluate(op, v, x[i])
	end
	v
end

function vreduce{R<:Union(Number, Bool)}(op::BinaryFunctor, init::R, f::UnaryFunctor, x::AbstractArray)
	v::R = init
	for i in 1 : length(x)
		v = evaluate(op, v, evaluate(f, x[i]))
	end
	v
end

function vreduce{R<:Union(Number, Bool)}(op::BinaryFunctor, init::R, f::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	v::R = init
	for i in 1 : length(x1)
		v = evaluate(op, v, evaluate(f, get_scalar(x1, i), get_scalar(x2, i)))
	end
	v
end

function vreduce(op::BinaryFunctor, x::AbstractArray)
	v = x[1]
	for i in 2 : length(x)
		v = evaluate(op, v, x[i])
	end
	v
end

function vreduce(op::BinaryFunctor, f::UnaryFunctor, x::AbstractArray)
	v = evaluate(f, x[1])
	for i in 2 : length(x)
		v = evaluate(op, v, evaluate(f, x[i]))
	end
	v
end

function vreduce(op::BinaryFunctor, f::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	v = evaluate(f, get_scalar(x1, 1), get_scalar(x2, 1))
	for i in 2 : map_length(x1, x2)
		v = evaluate(op, v, evaluate(f, get_scalar(x1, i), get_scalar(x2, i)))
	end
	v
end

function vreduce_fdiff(op::BinaryFunctor, f::UnaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	v = evaluate(f, get_scalar(x1, 1) - get_scalar(x2, 1))
	for i in 2 : map_length(x1, x2)	
		v = evaluate(op, v, evaluate(f, get_scalar(x1, i) - get_scalar(x2, i)))
	end
	v
end


#################################################
#
# 	Reduction along specific dimension
#
#################################################

function vreduce_dim1!(dst::AbstractArray, op::BinaryFunctor, x::AbstractMatrix)
	m = size(x, 1)
	n = size(x, 2)

	for j in 1 : n
		v = x[1,j]
		for i in 2 : m
			v = evaluate(op, v, x[i,j])
		end
		dst[j] = v
	end	
end

function vreduce_dim2!(dst::AbstractArray, op::BinaryFunctor, x::AbstractMatrix)
	m = size(x, 1)
	n = size(x, 2)

	for i in 1 : m
		dst[i] = x[i,1]
	end	

	for j in 2 : n
		for i in 1 : m
			dst[i] = evaluate(op, dst[i], x[i,j])
		end
	end
end

function vreduce_dim2!{T}(dst::AbstractArray, op::BinaryFunctor, x::AbstractArray{T,3})
	m = size(x, 1)
	k = size(x, 2)
	n = size(x, 3)

	for j in 1 : n
		for i in 1 : m
			dst[i,j] = x[i,1,j]
		end

		for l in 2 : k
			for i in 1 : m
				dst[i,j] = evaluate(op, dst[i,j], x[i,l,j])
			end
		end
	end
end

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

function vreduce!{T}(dst, op::BinaryFunctor, x::AbstractArray{T,3}, dim::Integer)
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

function vreduce!(dst, op::BinaryFunctor, x::AbstractArray, dim::Integer)
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

function vreduce{T}(op::BinaryFunctor, x::AbstractArray{T}, dim::Integer)
	r = Array(result_type(op, T, T), reduced_size(size(x), dim))
	vreduce!(r, op, x, dim)
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

vsum(x::AbstractArray, dim::Integer) = vreduce(Add(), x, dim)
vsum!(dst::AbstractArray, x::AbstractArray, dim::Integer) = vreduce!(Add(), x, dim)

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


#################################################
#
# 	Derived reduction functions
#
#################################################

const asum = Base.LinAlg.BLAS.asum

vasum(x::Array) = asum(x)
vasum(x::AbstractArray) = vsum(Abs(), x)
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



