#################################################
#
# 	Full reduction
#
#################################################

function code_full_reduction(fname::Symbol, coder_expr::Expr)
	coder = eval(coder_expr)
	paramlist = generate_paramlist(coder)
	ker1 = generate_kernel(coder, 1)
	kernel = generate_kernel(coder, :i)
	len = length_inference(coder)
	quote
		function ($fname)(op::BinaryFunctor, $(paramlist...))
			n::Int = $len
			v = $ker1
			for i in 2 : n
				v = evaluate(op, v, $kernel)
			end
			v
		end
	end
end

macro full_reduction(fname, coder)
	esc(code_full_reduction(fname, coder))
end

@full_reduction vreduce TrivialCoder()
@full_reduction vreduce UnaryCoder()
@full_reduction vreduce BinaryCoder()
@full_reduction vreduce_fdiff FDiffCoder()

########################################################
#
# 	Reduction along a single dimension
#
########################################################

function code_singledim_reduction(fname::Symbol, coder_expr::Expr, mapfun!::Symbol)
	coder = eval(coder_expr)
	paramlist = generate_paramlist(coder)
	arglist = generate_arglist(coder)
	shape = shape_inference(coder)

	kernel = generate_kernel(coder, :idx)
	ker_i = generate_kernel(coder, :i)

	fname! = symbol(string(fname, '!'))
	fname_firstdim! = symbol(string(fname, "_firstdim!"))
	fname_lastdim! = symbol(string(fname, "_lastdim!"))
	fname_middim! = symbol(string(fname, "_middim!"))

	quote
		function ($fname_firstdim!)(dst::AbstractArray, op::BinaryFunctor, m::Int, n::Int, $(paramlist...))
			idx = 0
			for j in 1 : n
				idx += 1
				v = $kernel
				for i in 2 : m
					idx += 1
					v = evaluate(op, v, $kernel)
				end
				dst[j] = v
			end
		end

		function ($fname_lastdim!)(dst::AbstractArray, op::BinaryFunctor, m::Int, n::Int, $(paramlist...))
			for i in 1 : m
				dst[i] = $ker_i
			end	
			idx = m

			for j in 2 : n
				for i in 1 : m
					idx += 1
					dst[i] = evaluate(op, dst[i], $kernel)
				end
			end
		end

		function ($fname_middim!)(dst::AbstractArray, op::BinaryFunctor, m::Int, n::Int, k::Int, $(paramlist...))
			od = 0
			idx = 0
			for l in 1 : k
				for i in 1 : m
					idx += 1
					dst[od + i] = $kernel
				end

				for j in 2 : n
					for i in 1 : m
						odi = od + i
						idx += 1
						dst[odi] = evaluate(op, dst[odi], $kernel)
					end
				end

				od += m
			end
		end

		function ($fname!)(dst::AbstractArray, op::BinaryFunctor, $(paramlist...), dim::Int)
			rsiz = $shape
			nd = length(rsiz)
			if dim == 1
				d1 = rsiz[1]
				d2 = trail_length(rsiz, 1)
				($fname_firstdim!)(dst, op, d1, d2, $(arglist...))
			elseif dim < nd
				d0 = precede_length(rsiz, dim)
				d1 = rsiz[dim]
				d2 = trail_length(rsiz, dim)
				($fname_middim!)(dst, op, d0, d1, d2, $(arglist...))
			elseif dim == nd
				d0 = precede_length(rsiz, dim)
				d1 = rsiz[dim]
				($fname_lastdim!)(dst, op, d0, d1, $(arglist...))
			else
				($mapfun!)(dst, $(arglist...))
			end
			dst
		end
	end
end

macro singledim_reduction(fname, coder, mapfun)
	esc(code_singledim_reduction(fname, coder, mapfun))
end

@singledim_reduction vreduce TrivialCoder() copy!
@singledim_reduction vreduce UnaryCoder() vmap!
@singledim_reduction vreduce BinaryCoder() vmap!
@singledim_reduction vreduce_fdiff FDiffCoder() vmapdiff!


########################################################
#
# 	Reduction along two dimensions (for cubes)
#
########################################################

function code_doubledims_reduction(fname::Symbol, coder_expr::Expr)
	coder = eval(coder_expr)
	paramlist = generate_paramlist_forcubes(coder)
	arglist = generate_arglist(coder)
	shape = shape_inference(coder)
	kernel = generate_kernel(coder, :idx)

	fname! = symbol(string(fname, '!'))
	fname_firstdim! = symbol(string(fname, "_firstdim!"))
	fname_lastdim! = symbol(string(fname, "_lastdim!"))
	fname_dim13! = symbol(string(fname, "_dim13!"))

	quote
		function ($fname_dim13!)(dst::AbstractArray, op::BinaryFunctor, m::Int, n::Int, k::Int, $(paramlist...))
			idx = 0
			for j in 1 : n
				idx += 1
				v = $kernel

				for i in 2 : m
					idx += 1
					v = evaluate(op, v, $kernel)
				end
				dst[j] = v
			end

			for l in 2 : k
				for j in 1 : n
					v = dst[j]
					for i in 1 : m
						idx += 1
						v = evaluate(op, v, $kernel)
					end
					dst[j] = v
				end
			end				
		end

		function ($fname!)(dst::AbstractArray, op::BinaryFunctor, $(paramlist...), dims::(Int, Int))
			siz = $shape
			dims == (1, 2) ? ($fname_firstdim!)(dst, op, siz[1] * siz[2], siz[3], $(arglist...)) :
			dims == (1, 3) ? ($fname_dim13!)(dst, op, siz[1], siz[2], siz[3], $(arglist...)) :
			dims == (2, 3) ? ($fname_lastdim!)(dst, op, siz[1], siz[2] * siz[3], $(arglist...)) :
			throw(ArgumentError("dims must be either of (1, 2), (1, 3), or (2, 3)."))
			dst
		end
	end
end

macro doubledims_reduction(fname, coder)
	esc(code_doubledims_reduction(fname, coder))
end

@doubledims_reduction vreduce TrivialCoder()
@doubledims_reduction vreduce UnaryCoder()
@doubledims_reduction vreduce BinaryCoder()
@doubledims_reduction vreduce_fdiff FDiffCoder()


########################################################
#
# 	vreduce (non in-place functions)
#
########################################################

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

function code_vreduce_function(fname::Symbol, coder_expr::Expr)
	coder = eval(coder_expr)
	paramlist = generate_paramlist(coder)
	arglist = generate_arglist(coder)
	shape = shape_inference(coder)
	vtype = eltype_inference(coder)

	fname! = symbol(string(fname, '!'))

	quote 
		function ($fname)(op::BinaryFunctor, $(paramlist...), dims::DimSpec)
			r = Array($vtype, reduced_size($shape, dims))
			($fname!)(r, op, $(arglist...), dims)
		end
	end
end

macro vreduce_function(fname, coder)
	esc(code_vreduce_function(fname, coder))
end

@vreduce_function vreduce TrivialCoder()
@vreduce_function vreduce UnaryCoder()
@vreduce_function vreduce BinaryCoder()
@vreduce_function vreduce_fdiff FDiffCoder()


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

