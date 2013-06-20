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

@full_reduction reduce TrivialCoder()
@full_reduction reduce UnaryCoder()
@full_reduction reduce BinaryCoder()
@full_reduction reduce TernaryCoder()
@full_reduction reduce_fdiff FDiffCoder()

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
		function ($fname_firstdim!)(dst::EwiseArray, op::BinaryFunctor, m::Int, n::Int, $(paramlist...))
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

		function ($fname_lastdim!)(dst::EwiseArray, op::BinaryFunctor, m::Int, n::Int, $(paramlist...))
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

		function ($fname_middim!)(dst::EwiseArray, op::BinaryFunctor, m::Int, n::Int, k::Int, $(paramlist...))
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

		function ($fname!)(dst::EwiseArray, op::BinaryFunctor, $(paramlist...), dim::Int)
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

_map_to_dest!(dst::EwiseArray, f::Functor, xs...) = map!(f, dst, xs...)
_mapdiff_to_dest!(dst::EwiseArray, f::UnaryFunctor, x1, x2) = mapdiff!(f, dst, x1, x2)

@singledim_reduction reduce TrivialCoder() copy!
@singledim_reduction reduce UnaryCoder() _map_to_dest!
@singledim_reduction reduce BinaryCoder() _map_to_dest!
@singledim_reduction reduce TernaryCoder() _map_to_dest!
@singledim_reduction reduce_fdiff FDiffCoder() _mapdiff_to_dest!


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
		function ($fname_dim13!)(dst::EwiseArray, op::BinaryFunctor, m::Int, n::Int, k::Int, $(paramlist...))
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

		function ($fname!)(dst::EwiseArray, op::BinaryFunctor, $(paramlist...), dims::(Int, Int))
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

@doubledims_reduction reduce TrivialCoder()
@doubledims_reduction reduce UnaryCoder()
@doubledims_reduction reduce BinaryCoder()
@doubledims_reduction reduce TernaryCoder()
@doubledims_reduction reduce_fdiff FDiffCoder()


########################################################
#
# 	reduce (non in-place functions)
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

function code_reduce_function(fname::Symbol, coder_expr::Expr)
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

macro reduce_function(fname, coder)
	esc(code_reduce_function(fname, coder))
end

@reduce_function reduce TrivialCoder()
@reduce_function reduce UnaryCoder()
@reduce_function reduce BinaryCoder()
@reduce_function reduce TernaryCoder()
@reduce_function reduce_fdiff FDiffCoder()


#################################################
#
# 	Basic reduction functions
#
#################################################

empty_notallowed(ty::Type) = throw(ArgumentError("Empty array is not allowed."))

function code_basic_reduction(fname::Symbol, op::Expr, coder::EwiseCoder, gfun::Symbol, emptyfun::Symbol)
	paramlist = generate_paramlist(coder)
	arglist = generate_arglist(coder)
	vtype = eltype_inference(coder)
	emptytest = generate_emptytest(coder)

	fname! = symbol(string(fname, '!'))
	gfun! = symbol(string(gfun, '!'))

	quote
		($fname)($(paramlist...)) = ($emptytest) ? ($emptyfun)($vtype) : ($gfun)($op, $(arglist...))
		($fname)($(paramlist...), dims::DimSpec) = ($gfun)($op, $(arglist...), dims) 
		($fname!)(dst::EwiseArray, $(paramlist...), dims::DimSpec) = ($gfun!)(dst, $op, $(arglist...), dims)
	end
end

function code_basic_mapreduction(fname::Symbol, op::Expr, emptyfun::Symbol)
	#c0 = code_basic_reduction(fname, op, TrivialCoder(), :reduce, emptyfun)
	c1 = code_basic_reduction(fname, op, UnaryCoder(), :reduce, emptyfun)
	c2 = code_basic_reduction(fname, op, BinaryCoder(), :reduce, emptyfun)
	c3 = code_basic_reduction(fname, op, TernaryCoder(), :reduce, emptyfun)
	c2d = code_basic_reduction(symbol(string(fname, "_fdiff")), op, FDiffCoder(), :reduce_fdiff, emptyfun)

	combined = Expr(:block, c1.args..., c2.args..., c3.args..., c2d.args...)
end

macro basic_mapreduction(fname, op, emptyfun)
	esc(code_basic_mapreduction(fname, op, emptyfun))
end


sum{T}(x::Array{T}) = isempty(x) ? zero(T) : reduce(Add(), x)
sum{T}(x::Array{T}, dims::DimSpec) = isempty(x) ? zeros(T, reduced_size(x, dims)) : reduce(Add(), x, dims)
sum!(dst::Array, x::Array, dims::DimSpec) = reduce!(dst, Add(), x, dims) 

nonneg_max{T}(x::Array{T}) = isempty(x) ? zero(T) : reduce(Max(), x)
nonneg_max{T}(x::Array{T}, dims::DimSpec) = isempty(x) ? zeros(T, reduced_size(x, dims)) : reduce(Max(), x, dims)
nonneg_max!(dst::Array, x::Array, dims::DimSpec) = reduce!(dst, Max(), x, dims) 

max{T}(x::Array{T}) = isempty(x) ? empty_notallowed(T) : reduce(Max(), x)
max{T}(x::Array{T}, ::(), dims::DimSpec) = isempty(x) ? empty_notallowed(T) : reduce(Max(), x, dims)
max!(dst::Array, x::Array, dims::DimSpec) = reduce!(dst, Max(), x, dims) 

min{T}(x::Array{T}) = isempty(x) ? empty_notallowed(T) : reduce(Min(), x)
min{T}(x::Array{T}, ::(), dims::DimSpec) = isempty(x) ? empty_notallowed(T) : reduce(Min(), x, dims)
min!(dst::Array, x::Array, dims::DimSpec) = reduce!(dst, Min(), x, dims) 

@basic_mapreduction sum Add() zero 
@basic_mapreduction nonneg_max Max() zero
@basic_mapreduction max Max() empty_notallowed
@basic_mapreduction min Min() empty_notallowed

#################################################
#
# 	Derived reduction functions
#
#################################################

# generator

function code_derived_reduction1(fname::Symbol, rfun::Symbol, tfunctor::Expr)
	fname! = symbol(string(fname, '!'))
	rfun! = symbol(string(rfun, '!'))

	quote
		($fname)(x::EwiseArray) = ($rfun)($tfunctor, x)
		($fname)(x::EwiseArray, dims::DimSpec) = ($rfun)($tfunctor, x, dims)
		($fname!)(dst::EwiseArray, x::EwiseArray, dims::DimSpec) = ($rfun!)(dst, $tfunctor, x, dims)
	end
end

function code_derived_reduction2(fname::Symbol, rfun::Symbol, tfunctor::Expr)
	fname! = symbol(string(fname, '!'))
	rfun! = symbol(string(rfun, '!'))

	quote
		($fname)(x1::Number, x2::Number) = error("At least one of the arguments must be an array.")
		($fname)(x1::ArrayOrNumber, x2::ArrayOrNumber) = ($rfun)($tfunctor, x1, x2)
		($fname)(x1::ArrayOrNumber, x2::ArrayOrNumber, dims::DimSpec) = ($rfun)($tfunctor, x1, x2, dims)
		($fname!)(dst::EwiseArray, x1::ArrayOrNumber, x2::ArrayOrNumber, dims::DimSpec) = ($rfun!)(dst, $tfunctor, x1, x2, dims)
	end
end

macro derived_reduction1(fname, rfun, tfunctor)
	esc(code_derived_reduction1(fname, rfun, tfunctor))
end

macro derived_reduction2(fname, rfun, tfunctor)
	esc(code_derived_reduction2(fname, rfun, tfunctor))
end

# specific function definitions

@derived_reduction1 asum sum Abs()
@derived_reduction1 amax max Abs()
@derived_reduction1 amin min Abs()
@derived_reduction1 sqsum sum Abs2()

@derived_reduction2 adiffsum sum_fdiff Abs()
@derived_reduction2 adiffmax max_fdiff Abs()
@derived_reduction2 adiffmin min_fdiff Abs()
@derived_reduction2 sqdiffsum sum_fdiff Abs2()

# special treatment for dot for sqsum

typealias BlasFP Union(Float32, Float64, Complex{Float32}, Complex{Float64})
const blas_dot = Base.LinAlg.BLAS.dot

dot(x1::Array, x2::Array, dims::DimSpec) = sum(Multiply(), x1, x2, dims)
dot!(dst::Array, x1::Array, x2::Array, dims::DimSpec) = sum!(dst, Multiply(), x1, x2, dims)

dot{T<:BlasFP}(x1::Array{T}, x2::Array{T}) = blas_dot(x1, x2)
sqsum{T<:BlasFP}(x::Array{T}) = blas_dot(x, x)


#################################################
#
# 	Derived vector norms
#
#################################################

function vnorm(x::Array, p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? asum(x) :
	p == 2 ? sqrt(sqsum(x)) :	
	isinf(p) ? amax(x) :
	sum(FixAbsPow(p), x) .^ inv(p)
end

vnorm(x::Array) = vnorm(x, 2)

function vnorm!(dst::Array, x::Array, p::Real, dims::DimSpec)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? asum!(dst, x, dims) :
	p == 2 ? map1!(Sqrt(), sqsum!(dst, x, dims)) :	
	isinf(p) ? amax!(dst, x, dims) :
	map1!(FixAbsPow(inv(p)), sum!(dst, FixAbsPow(p), x, dims))
end

function vnorm{Tx<:Number,Tp<:Real}(x::Array{Tx}, p::Tp, dims::DimSpec) 
	tt = to_fptype(promote_type(Tx, Tp))
	r = Array(tt, reduced_size(size(x), dims))
	vnorm!(r, x, p, dims)
	r
end

# vdiffnorm

function vdiffnorm(x::Array, y::ArrayOrNumber, p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? adiffsum(x, y) :
	p == 2 ? sqrt(sqdiffsum(x, y)) :	
	isinf(p) ? adiffmax(x, y) :
	sum_fdiff(FixAbsPow(p), x, y) .^ inv(p)
end

vdiffnorm(x::Array, y::ArrayOrNumber) = vdiffnorm(x, y, 2)

function vdiffnorm!(dst::Array, x::Array, y::ArrayOrNumber, p::Real, dims::DimSpec)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? adiffsum!(dst, x, y, dims) :
	p == 2 ? map1!(Sqrt(), sqdiffsum!(dst, x, y, dims)) :	
	isinf(p) ? adiffmax!(dst, x, y, dims) :
	map1!(FixAbsPow(inv(p)), sum_fdiff!(dst, FixAbsPow(p), x, y, dims))
end

function vdiffnorm{Tx<:Number,Ty<:Number,Tp<:Real}(x::Array{Tx}, y::Array{Ty}, p::Tp, dims::DimSpec) 
	tt = to_fptype(promote_type(promote_type(Tx, Ty), Tp))
	r = Array(tt, reduced_size(size(x), dims))
	vdiffnorm!(r, x, y, p, dims)
	r
end

