# Reduction along specific dimensions

## auxiliary functions

reduced_shape(s::SizeTuple{1}, dim::Int) = dim == 1 ? (1,) : error("Invalid value of dim.")

reduced_shape(s::SizeTuple{2}, dim::Int) = dim == 1 ? (1,s[2]) : dim == 2 ? (s[1],1) : error("Invalid value of dim.")

function reduced_shape{D}(s::SizeTuple{D}, dim::Int)
	dim == 1 ? tuple(1, s[2:end]...) :
	1 < dim < D ? tuple(s[1:dim-1]..., 1, s[dim+1:end]...) :
	dim == D ? tuple(s[1:dim-1]..., 1) :
	error("Invalid value of dim.")
end

reduced_length(s::SizeTuple{1}, dim::Int) = dim == 1 ? 1 : error("Invalid value of dim.")
reduced_length(s::SizeTuple{2}, dim::Int) = dim == 1 ? s[2] : dim == 2 ? s[1] : error("Invalid value of dim.")

function reduced_length{D}(s::SizeTuple{D}, dim::Int)
	dim == 1 ? prod(s[2:end]) :
	1 < dim < D ? prod(s[1:dim-1]) * prod(s[dim+1:end]) :
	dim == D ? prod(s[1:dim-1]) :
	error("Invalid value of dim.")
end

offset_view(a::Number, ::Int, ::Int, ::Int) = a

#################################################
#
#    codegen facilities
#
#################################################

# reduction type dependent codes

abstract AbstractReduc 

type SumReduc <: AbstractReduc end
type MaxReduc <: AbstractReduc end
type MinReduc <: AbstractReduc end
type FoldlReduc <: AbstractReduc end

extra_params{Reduc<:AbstractReduc}(::Type{Reduc}) = []
extra_args{Reduc<:AbstractReduc}(::Type{Reduc}) = []

extra_params(::Type{FoldlReduc}) = [:(op::Functor{2}), :(s::Number)]
extra_args(::Type{FoldlReduc}) = [:op, :s]

# update code

update_code(R::Type{SumReduc}, s, x) = :( @inbounds $(s) += $(x) )

function update_code(R::Type{MaxReduc}, s, x)
	quote
		if lt_or_nan($(s), $(x))
			@inbounds $(s) = $(x)
		end
	end
end

function update_code(R::Type{MinReduc}, s, x)
	quote
		if gt_or_nan($(s), $(x))
			@inbounds $(s) = $(x)
		end
	end
end

update_code(R::Type{FoldlReduc}, s, x) = :( @inbounds $s = evaluate(op, $s, $x) )

# code for empty reduction

function emptyreduc_code(R::Type{SumReduc}, dst::Symbol, T::Symbol, n::Symbol)
	quote
		z = zero($T)
		for i = 1 : $n
			@inbounds ($dst)[i] = z
		end
	end
end

emptyreduc_code(R::Type{MaxReduc}, dst, T, n) = :(error("maximum along a zero-length dimension is not allowed."))
emptyreduc_code(R::Type{MinReduc}, dst, T, n) = :(error("minimum along a zero-length dimension is not allowed."))

function emptyreduc_code(R::Type{FoldlReduc}, dst::Symbol, T::Symbol, n::Symbol)
	quote
		for i = 1 : $n
			@inbounds ($dst)[i] = s
		end
	end
end

# reduce result

reduce_result(R::Type{SumReduc}, ty) = Expr(:call, :sumtype, ty)
reduce_result(R::Type{MaxReduc}, ty) = ty
reduce_result(R::Type{MinReduc}, ty) = ty
reduce_result(R::Type{FoldlReduc}, ty) = ty

# core skeleton

function generate_reducedim_codes{Reduc<:AbstractReduc}(AN::Int, accum::Symbol, reducty::Type{Reduc})

	# function names
	_accum_eachcol! = symbol("_$(accum)_eachcol!")
	_accum_eachrow! = symbol("_$(accum)_eachrow!")
	_accum = symbol("_$(accum)")
	_accum! = symbol("_$(accum)!")
	accum! = symbol("$(accum)!")	

	# code preparation
	h = codegen_helper(AN)
	exparams = extra_params(Reduc)
	exargs = extra_args(Reduc)

	quote
		global $(_accum_eachcol!)
		function $(_accum_eachcol!){R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(exparams...), $(h.aparams...))
			offset = 0
			if m > 0
				for j = 1 : n
					rj = ($_accum)(offset+1, offset+m, $(exargs...), $(h.args...))
					@inbounds r[j] = rj
					offset += m
				end
			else
				$(emptyreduc_code(Reduc, :r, :R, :n))
			end	
		end
	
		global $(_accum_eachrow!)
		function $(_accum_eachrow!){R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(exparams...), $(h.aparams...))
			if n > 0
				for i = 1 : m
					@inbounds vi = $(h.term(:i))
					@inbounds r[i] = vi
				end

				offset = m
				for j = 2 : n			
					for i = 1 : m
						idx = offset + i
						@inbounds vi = $(h.term(:idx))
						$(update_code(Reduc, :(r[i]), :vi))
					end
					offset += m
				end
			else
				$(emptyreduc_code(Reduc, :r, :R, :m))
			end
		end

		global $(_accum!)
		function $(_accum!)(r::ContiguousArray, $(exparams...), $(h.aparams...), dim::Int)
			shp = $(h.inputsize)
			
			if dim == 1
				m = shp[1]
				n = succ_length(shp, 1)
				$(_accum_eachcol!)(m, n, r, $(exargs...), $(h.args...))

			else
				m = prec_length(shp, dim)
				n = shp[dim]
				k = succ_length(shp, dim)

				if k == 1
					$(_accum_eachrow!)(m, n, r, $(exargs...), $(h.args...))
				else
					mn = m * n
					ro = 0
					ao = 0
					for l = 1 : k
						$(_accum_eachrow!)(m, n, offset_view(r, ro, m), $(exargs...), $(h.offset_args...))
						ro += m
						ao += mn
					end
				end
			end
			return r
		end

		global $(accum!)
		function $(accum!)(r::ContiguousArray, $(exparams...), $(h.aparams...), dim::Int)
			length(r) == reduced_length($(h.inputsize), dim) || error("Invalid argument dimensions.")
			$(_accum!)(r, $(exargs...), $(h.args...), dim)
		end

		global $(accum)
		function $(accum)($(exparams...), $(h.aparams...), dim::Int)
			rshp = reduced_shape($(h.inputsize), dim)
			$(_accum!)(Array(sumtype($(h.termtype)), rshp), $(exargs...), $(h.args...), dim)
		end	
	end
end

macro code_reducedim(AN, fname, reducty)
	R = eval(reducty)
	esc(generate_reducedim_codes(AN, fname, R))
end


#################################################
#
#    sum along dims
#
#################################################

sumtype{T<:Number}(::Type{T}) = T
sumtype{T<:Integer}(::Type{T}) = promote_type(T, Int)

# specific functions

@code_reducedim 1 sum SumReduc
@code_reducedim 2 sum SumReduc
@code_reducedim 3 sum SumReduc
@code_reducedim (-2) sumfdiff SumReduc


#################################################
#
#    mean along dims
#
#################################################

macro code_meandim(AN, meanf, sumf)

	sumf! = symbol("$(sumf)!")
	meanf! = symbol("$(meanf)!")
	h = codegen_helper(AN)

	quote
		global $(meanf)
		function $(meanf)($(h.aparams...), dim::Int) 
			shp = $(h.inputsize)
			divide!($(sumf)($(h.args...), dim), shp[dim])
		end

		global $(meanf!)
		function $(meanf!)(r::ContiguousArray, $(h.aparams...), dim::Int)
			shp = $(h.inputsize)
			divide!($(sumf!)(r, $(h.args...), dim), shp[dim])
		end

	end
end

@code_meandim 0 mean sum
@code_meandim 1 mean sum
@code_meandim 2 mean sum
@code_meandim 3 mean sum
@code_meandim (-2) meanfdiff sumfdiff


#################################################
#
#    maximum/minimum along dims
#
#################################################

@code_reducedim 1 maximum MaxReduc
@code_reducedim 2 maximum MaxReduc
@code_reducedim 3 maximum MaxReduc
@code_reducedim (-2) maxfdiff MaxReduc

@code_reducedim 0 minimum MinReduc
@code_reducedim 1 minimum MinReduc
@code_reducedim 2 minimum MinReduc
@code_reducedim 3 minimum MinReduc
@code_reducedim (-2) minfdiff MinReduc


#################################################
#
#   folding along dims
#
#################################################

macro code_foldldim(AN, fname)
	esc(generate_foldldim_codes(AN, fname))
end

@code_reducedim 0 foldl FoldlReduc
@code_reducedim 1 foldl FoldlReduc
@code_reducedim 2 foldl FoldlReduc
@code_reducedim 3 foldl FoldlReduc
@code_reducedim (-2) foldl_fdiff FoldlReduc


#################################################
#
#    derived functions
#
#################################################

# macros to generate derived functions

macro mapreduce_fun1(fname, accum, F, AT, RT)
	fname! = symbol("$(fname)!")
	accum! = symbol("$(accum)!")

	quote
		global $(fname)
		$(fname)(a::$(AT), dim::Int) = $(accum)(($F)(), a, dim)

		global $(fname!)
		$(fname!)(r::$(RT), a::$(AT), dim::Int) = $(accum!)(r, ($F)(), a, dim) 
	end
end

macro mapreduce_fun2(fname, accum, F, AT, RT)
	fname! = symbol("$(fname)!")
	accum! = symbol("$(accum)!")

	quote
		global $(fname)
		$(fname)(a::$(AT), b::$(AT), dim::Int) = $(accum)(($F)(), a, b, dim)

		global $(fname!)
		$(fname!)(r::$(RT), a::$(AT), b::$(AT), dim::Int) = $(accum!)(r, ($F)(), a, b, dim) 
	end
end

# derived functions

@mapreduce_fun1 sumabs  sum     AbsFun ContiguousArray ContiguousRealArray
@mapreduce_fun1 meanabs mean    AbsFun ContiguousArray ContiguousRealArray
@mapreduce_fun1 maxabs  maximum AbsFun ContiguousArray ContiguousRealArray
@mapreduce_fun1 minabs  minimum AbsFun ContiguousArray ContiguousRealArray

@mapreduce_fun1 sumsq  sum  Abs2Fun ContiguousArray ContiguousRealArray
@mapreduce_fun1 meansq mean Abs2Fun ContiguousArray ContiguousRealArray

@mapreduce_fun2 sumabsdiff  sumfdiff  AbsFun ContiguousArrOrNum ContiguousRealArray
@mapreduce_fun2 meanabsdiff meanfdiff AbsFun ContiguousArrOrNum ContiguousRealArray
@mapreduce_fun2 maxabsdiff  maxfdiff  AbsFun ContiguousArrOrNum ContiguousRealArray
@mapreduce_fun2 minabsdiff  minfdiff  AbsFun ContiguousArrOrNum ContiguousRealArray

@mapreduce_fun2 sumsqdiff  sumfdiff  Abs2Fun ContiguousArray ContiguousRealArray
@mapreduce_fun2 meansqdiff meanfdiff Abs2Fun ContiguousArray ContiguousRealArray

@mapreduce_fun2 dot sum Multiply ContiguousRealArray ContiguousRealArray

@mapreduce_fun1 sumxlogx sum XlogxFun ContiguousRealArray ContiguousRealArray
@mapreduce_fun2 sumxlogy sum XlogyFun ContiguousRealArray ContiguousRealArray

entropy(a::ContiguousRealArray, dim::Int) = negate!(sumxlogx(a, dim))
entropy!(r::ContiguousRealArray, a::ContiguousRealArray, dim::Int) = negate!(sumxlogx!(r, a, dim))



