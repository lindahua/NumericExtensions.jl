
# auxiliary code-generation routines

function reduc_paramlist{KType<:EwiseFunKernel}(kgen::Type{KType}, aty::Symbol)
	plst = paramlist(kgen, aty)
	tuple(plst[1], :(op::BinaryFunctor), plst[2:]...)
end

function reduc_arglist(ktype::Type{DirectKernel})
	alst = arglist(ktype)
	tuple(:op, alst...)
end

function reduc_paramlist(ktype::Type{DirectKernel}, aty::Symbol)
	plst = paramlist(ktype, aty)
	tuple(:(op::BinaryFunctor), plst...)
end

function reduc_arglist{KType<:EwiseFunKernel}(ktype::Type{KType})
	alst = arglist(ktype)
	tuple(alst[1], :op, alst[2:]...)
end


#################################################
#
# 	Full reduction
#
#################################################

function code_full_reduction{KType<:EwiseKernel}(fname::Symbol, ktype::Type{KType})
	plst = reduc_paramlist(ktype, :ContiguousArray)
	ker_i = kernel(ktype, :i)
	len = length_inference(ktype)
	quote
		function ($fname)($(plst...))
			n::Int = $len
			i = 1
			@inbounds v = $ker_i
			for i in 2 : n
				@inbounds v = evaluate(op, v, $ker_i)
			end
			v
		end
	end
end

macro full_reduction(fname, ktype)
	esc(code_full_reduction(fname, eval(ktype)))
end

@full_reduction reduce DirectKernel
@full_reduction mapreduce UnaryFunKernel
@full_reduction mapreduce BinaryFunKernel
@full_reduction mapreduce TernaryFunKernel
@full_reduction mapdiff_reduce DiffFunKernel


########################################################
#
# 	Reduction along a single dimension
#
########################################################

function code_singledim_reduction{KType<:EwiseKernel}(fname::Symbol, ktype::Type{KType}, mapfun!::Symbol)
	plst = reduc_paramlist(ktype, :ContiguousArray)
	alst0 = arglist(ktype)
	alst = reduc_arglist(ktype)
	shape = shape_inference(ktype)
	ker_idx = kernel(ktype, :idx)

	fname! = symbol(string(fname, '!'))
	fname_impl! = symbol(string(fname, "_impl!"))

	quote
		function ($fname_impl!)(dst::ContiguousArray, m::Int, n::Int, k::Int, $(plst...))
			if n == 1  # each page has a single column (simply evaluate)
				for idx = 1:m*k
					@inbounds dst[idx] = $ker_idx
				end

			elseif m == 1  # each page has a single row
				idx = 0
				for l = 1:k
					idx += 1
					@inbounds s = $ker_idx
					for j = 2:n
						idx += 1
						@inbounds s = evaluate(op, s, $ker_idx)
					end
					@inbounds dst[l] = s
				end

			elseif k == 1 # only one page
				for idx = 1:m
					@inbounds dst[idx] = $ker_idx
				end
				idx = m
				for j = 2:n
					for i = 1:m
						idx += 1
						@inbounds dst[i] = evaluate(op, dst[i], $ker_idx)
					end
				end

			else  # multiple generic pages
				idx = 0
				od = 0
				for l = 1:k					
					for i = 1:m
						idx += 1
						@inbounds dst[od+i] = $ker_idx
					end
					for j = 2:n
						for i = 1:m
							idx += 1
							odi = od + i
							@inbounds dst[odi] = evaluate(op, dst[odi], $ker_idx)
						end
					end
					od += m
				end
			end
		end

		function ($fname!)(dst::ContiguousArray, $(plst...), dim::Int)
			siz = $shape
			if 1 <= dim <= length(siz)
				($fname_impl!)(dst, prec_length(siz, dim), siz[dim], succ_length(siz, dim), $(alst...))
			else
				($fname_impl!)(dst, prod(siz), 1, 1, $(alst...))
			end
			dst
		end
	end
end

macro singledim_reduction(fname, ktype, mapfun)
	esc(code_singledim_reduction(fname, eval(ktype), mapfun))
end

_map_to_dest!(dst::ContiguousArray, f::Functor, xs...) = map!(f, dst, xs...)
_mapdiff_to_dest!(dst::ContiguousArray, f::UnaryFunctor, x1, x2) = mapdiff!(f, dst, x1, x2)

@singledim_reduction reduce         DirectKernel     copy!
@singledim_reduction mapreduce      UnaryFunKernel   _map_to_dest!
@singledim_reduction mapreduce      BinaryFunKernel  _map_to_dest!
@singledim_reduction mapreduce      TernaryFunKernel _map_to_dest!
@singledim_reduction mapdiff_reduce DiffFunKernel    _mapdiff_to_dest!


########################################################
#
# 	Reduction along two dimensions (for cubes)
#
########################################################

function code_doubledims_reduction{KType<:EwiseKernel}(fname::Symbol, ktype::Type{KType})
	plst = reduc_paramlist(ktype, :ContiguousCube)
	alst = reduc_arglist(ktype)
	shape = shape_inference(ktype)
	ker_idx = kernel(ktype, :idx)

	fname! = symbol(string(fname, '!'))
	fname_impl! = symbol(string(fname, "_impl!"))
	fname_dim13! = symbol(string(fname, "_dim13!"))

	quote
		function ($fname_dim13!)(dst::ContiguousArray, m::Int, n::Int, k::Int, $(plst...))
			idx = 0
			for j in 1 : n
				idx += 1
				@inbounds v = $ker_idx

				for i in 2 : m
					idx += 1
					@inbounds v = evaluate(op, v, $ker_idx)
				end
				@inbounds dst[j] = v
			end

			for l in 2 : k
				for j in 1 : n
					@inbounds v = dst[j]
					for i in 1 : m
						idx += 1
						@inbounds v = evaluate(op, v, $ker_idx)
					end
					@inbounds dst[j] = v
				end
			end				
		end

		function ($fname!)(dst::ContiguousArray, $(plst...), dims::(Int, Int))
			siz = $shape
			dims == (1, 2) ? ($fname_impl!)(dst, 1, siz[1] * siz[2], siz[3], $(alst...)) :
			dims == (1, 3) ? ($fname_dim13!)(dst, siz[1], siz[2], siz[3], $(alst...)) :
			dims == (2, 3) ? ($fname_impl!)(dst, siz[1], siz[2] * siz[3], 1, $(alst...)) :
			throw(ArgumentError("dims must be either of (1, 2), (1, 3), or (2, 3)."))
			dst
		end
	end
end

macro doubledims_reduction(fname, ktype)
	esc(code_doubledims_reduction(fname, eval(ktype)))
end

@doubledims_reduction reduce DirectKernel
@doubledims_reduction mapreduce UnaryFunKernel
@doubledims_reduction mapreduce BinaryFunKernel
@doubledims_reduction mapreduce TernaryFunKernel
@doubledims_reduction mapdiff_reduce DiffFunKernel


########################################################
#
# 	reduce (non in-place functions)
#
########################################################

reduced_size(siz::(Int,), dim::Integer) = dim == 1 ? (1,) : siz

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


_reduc_dim_length(x::AbstractArray, dim::Int) = 1 <= dim <= ndims(x) ? size(x, dim) : 1
_reduc_dim_length(siz::NTuple, dim::Int) = 1 <= dim <= length(siz) ? siz[dim] : 1

function _reduc_dim_length(x::AbstractArray, dims::(Int, Int))
	nd = ndims(x)
	d1 = dims[1]
	s::Int = (1 <= d1 <= nd ? size(x, d1) : 1)
	d2 = dims[2]
	if 1 <= d2 <= nd 
		s *= size(x, d2)
	end
	s
end

function _reduc_dim_length(siz::NTuple, dims::(Int, Int))
	nd = length(siz)
	d1 = dims[1]
	s::Int = (1 <= d1 <= nd ? siz[d1] : 1)
	d2 = dims[2]
	if 1 <= d2 <= nd 
		s *= siz[d2]
	end
	s
end


function code_reduce_function{KType<:EwiseKernel}(fname::Symbol, ktype::Type{KType})
	plst = reduc_paramlist(ktype, :ContiguousArray)
	alst = reduc_arglist(ktype)
	shape = shape_inference(ktype)
	vtype = eltype_inference(ktype)

	fname! = symbol(string(fname, '!'))

	quote 
		function ($fname)($(plst...), dims::DimSpec)
			vty = $vtype
			r = Array(result_type(op, vty, vty), reduced_size($shape, dims))
			($fname!)(r, $(alst...), dims)
		end
	end
end

macro reduce_function(fname, ktype)
	esc(code_reduce_function(fname, eval(ktype)))
end

@reduce_function reduce DirectKernel
@reduce_function mapreduce UnaryFunKernel
@reduce_function mapreduce BinaryFunKernel
@reduce_function mapreduce TernaryFunKernel
@reduce_function mapdiff_reduce DiffFunKernel


#################################################
#
# 	Basic reduction functions
#
#################################################

empty_notallowed(ty::Type) = throw(ArgumentError("Empty array is not allowed."))

function code_basic_reduction{KType<:EwiseKernel}(fname::Symbol, op::Expr, ktype::Type{KType}, gfun::Symbol, emptyfun::Symbol)
	plst = paramlist(ktype, :ContiguousArray)
	alst = arglist(ktype)
	vtype = eltype_inference(ktype)
	eptest = emptytest(ktype)

	fname! = symbol(string(fname, '!'))
	gfun! = symbol(string(gfun, '!'))

	quote
		($fname)($(plst...)) = ($eptest) ? ($emptyfun)($vtype) : ($gfun)($(alst[1]), $op, $(alst[2:]...))
		($fname)($(plst...), dims::DimSpec) = ($gfun)($(alst[1]), $op, $(alst[2:]...), dims) 
		($fname!)(dst::ContiguousArray, $(plst...), dims::DimSpec) = ($gfun!)(dst, $(alst[1]), $op, $(alst[2:]...), dims)
	end
end

function code_basic_mapreduction(fname::Symbol, op::Expr, emptyfun::Symbol)
	c1 = code_basic_reduction(fname, op, UnaryFunKernel, :mapreduce, emptyfun)
	c2 = code_basic_reduction(fname, op, BinaryFunKernel, :mapreduce, emptyfun)
	c3 = code_basic_reduction(fname, op, TernaryFunKernel, :mapreduce, emptyfun)
	c2d = code_basic_reduction(symbol(string(fname, "fdiff")), op, DiffFunKernel, :mapdiff_reduce, emptyfun)

	combined = Expr(:block, c1.args..., c2.args..., c3.args..., c2d.args...)
end

macro basic_mapreduction(fname, op, emptyfun)
	esc(code_basic_mapreduction(fname, op, emptyfun))
end


function sum(x::ContiguousArray{Bool})
	r = 0
	for e in x
		if e r+= 1 end
	end
	r
end

sum{T<:Number}(x::ContiguousArray{T}) = isempty(x) ? zero(T) : reduce(Add(), x)
sum{T<:Number}(x::ContiguousArray{T}, dims::DimSpec) = isempty(x) ? zeros(T, reduced_size(x, dims)) : reduce(Add(), x, dims)
sum!{R<:Number, T<:Number}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dims::DimSpec) = reduce!(dst, Add(), x, dims) 

function sum_range{T<:Number}(x::AbstractArray{T}, rg::Range1)
	s = zero(T)
	for i in rg
		@inbounds s += x[i]
	end
	s
end


max{T<:Real}(x::ContiguousArray{T}) = isempty(x) ? empty_notallowed(T) : reduce(MaxFun(), x)
max{T<:Real}(x::ContiguousArray{T}, ::(), dims::DimSpec) = isempty(x) ? empty_notallowed(T) : reduce(MaxFun(), x, dims)
max!{R<:Real, T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, ::(), dims::DimSpec) = reduce!(dst, MaxFun(), x, dims) 

min{T<:Real}(x::ContiguousArray{T}) = isempty(x) ? empty_notallowed(T) : reduce(MinFun(), x)
min{T<:Real}(x::ContiguousArray{T}, ::(), dims::DimSpec) = isempty(x) ? empty_notallowed(T) : reduce(MinFun(), x, dims)
min!{R<:Real, T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, ::(), dims::DimSpec) = reduce!(dst, MinFun(), x, dims) 

@basic_mapreduction sum Add() zero 
@basic_mapreduction max MaxFun() empty_notallowed
@basic_mapreduction min MinFun() empty_notallowed

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
		($fname)(x::ContiguousArray) = ($rfun)($tfunctor, x)
		($fname)(x::ContiguousArray, dims::DimSpec) = ($rfun)($tfunctor, x, dims)
		($fname!)(dst::ContiguousArray, x::ContiguousArray, dims::DimSpec) = ($rfun!)(dst, $tfunctor, x, dims)
	end
end

function code_derived_reduction2(fname::Symbol, rfun::Symbol, tfunctor::Expr)
	fname! = symbol(string(fname, '!'))
	rfun! = symbol(string(rfun, '!'))

	quote
		($fname)(x1::Number, x2::Number) = error("At least one of the arguments must be an array.")
		($fname)(x1::ArrayOrNumber, x2::ArrayOrNumber) = ($rfun)($tfunctor, x1, x2)
		($fname)(x1::ArrayOrNumber, x2::ArrayOrNumber, dims::DimSpec) = ($rfun)($tfunctor, x1, x2, dims)
		($fname!)(dst::ContiguousArray, x1::ArrayOrNumber, x2::ArrayOrNumber, dims::DimSpec) = ($rfun!)(dst, $tfunctor, x1, x2, dims)
	end
end

macro derived_reduction1(fname, rfun, tfunctor)
	esc(code_derived_reduction1(fname, rfun, tfunctor))
end

macro derived_reduction2(fname, rfun, tfunctor)
	esc(code_derived_reduction2(fname, rfun, tfunctor))
end

# specific function definitions

@derived_reduction1 sumabs sum AbsFun()
@derived_reduction1 maxabs max AbsFun()
@derived_reduction1 minabs min AbsFun()
@derived_reduction1 sumsq sum Abs2Fun()
@derived_reduction1 sumxlogx sum XlogxFun()

@derived_reduction2 sumabsdiff sumfdiff AbsFun()
@derived_reduction2 maxabsdiff maxfdiff AbsFun()
@derived_reduction2 minabsdiff minfdiff AbsFun()
@derived_reduction2 sumsqdiff sumfdiff Abs2Fun()
@derived_reduction2 sumxlogy sum XlogyFun()

# special treatment for dot for sqsum

typealias BlasFP Union(Float32, Float64, Complex{Float32}, Complex{Float64})
const blas_dot = Base.LinAlg.BLAS.dot
const blas_asum = Base.LinAlg.BLAS.asum

dot(x1::ContiguousArray, x2::ContiguousArray, dims::DimSpec) = sum(Multiply(), x1, x2, dims)
dot!(dst::ContiguousArray, x1::ContiguousArray, x2::ContiguousArray, dims::DimSpec) = sum!(dst, Multiply(), x1, x2, dims)

dot{T<:BlasFP}(x1::Array{T}, x2::Array{T}) = blas_dot(x1, x2)
sumsq{T<:BlasFP}(x::Array{T}) = blas_dot(x, x)
sumabs{T<:BlasFP}(x::Array{T}) = blas_asum(x)

