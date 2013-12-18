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

#################################################
#
#    codegen facilities
#
#################################################

type _RDArgs{AN} end

_rdargs(n::Int) = _RDArgs{n}()

immutable ReduceDimCodeHelper
	aparams::Vector{Expr}
	args::Vector{Symbol}
	offset_args::Vector
	term::Expr
	inputsize::Expr
	termtype::Expr
end

function prepare_reducedim_args(::_RDArgs{0})
	aparams = [:(a::ContiguousArray)]
	args = [:a]
	offset_args = [:(offset_view(a, ao, m, n))]
	term = :(a[idx])
	inputsize = :(size(a))
	termtype = :(eltype(a))
	return ReduceDimCodeHelper(aparams, args, offset_args, term, inputsize, termtype)
end

function prepare_reducedim_args(::_RDArgs{-2})
	aparams = [:(f::Functor{1}), :(a1::ContiguousArrOrNum), :(a2::ContiguousArrOrNum)]
	args = [:a1, :a2]
	offset_args = [:(offset_view(a1, ao, m, n)), :(offset_view(a2, ao, m, n))]
	term = :(evaluate(f, getvalue(a1, idx) - getvalue(a2, idx)))
	inputsize = :(mapshape(a1, a2))
	termtype = :(result_type(f, promote_type(eltype(a1), eltype(a2))))
	return ReduceDimCodeHelper(aparams, args, offset_args, term, inputsize, termtype)
end

function prepare_reducedim_args{N}(::_RDArgs{N})
	@assert N >= 1

	aargs = [symbol("a$i") for i = 1 : N]
	aparams = [:(f::Functor{$N}), [:($a::ContiguousArrOrNum) for a in aargs]...]
	args = [:f, aargs...]
	offset_args = [:f, [:(offset_view($a, ao, m, n)) for a in aargs]...]
	term = Expr(:call, :evaluate, :f, [:(getvalue($a, idx)) for a in aargs]...)
	inputsize = Expr(:call, :mapshape, aargs...)
	termtype = Expr(:call, :result_type, :f, [:(eltype($a)) for a in aargs]...)
	return ReduceDimCodeHelper(aparams, args, offset_args, term, inputsize, termtype)
end

#################################################
#
#    sum along dims
#
#################################################

sumtype{T<:Number}(::Type{T}) = T
sumtype{T<:Integer}(::Type{T}) = promote_type(T, Int)

function generate_sumdim_codes(AN::Int, accum::Symbol)

	# function names
	_accum_eachcol! = symbol("_$(accum)_eachcol!")
	_accum_eachrow! = symbol("_$(accum)_eachrow!")
	_accum! = symbol("_$(accum)!")
	accum! = symbol("$(accum)!")

	# parameter & argument preparation

	h = prepare_reducedim_args(_rdargs(AN))

	# generate functions

	quote
		global $(_accum_eachcol!)
		function $(_accum_eachcol!){R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(h.aparams...))
			offset = 0
			if m > 0
				for j = 1 : n
					rj = _sum(offset+1, offset+m, $(h.args...))
					@inbounds r[j] = rj
					offset += m
				end
			else
				z = zero(R)
				for j = 1 : n
					@inbounds r[j] = z
				end
			end	
		end
	
		global $(_accum_eachrow!)
		function $(_accum_eachrow!){R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(h.aparams...))
			if n > 0
				for idx = 1 : m
					@inbounds vi = $(h.term)
					@inbounds r[idx] = vi
				end

				offset = m
				for j = 2 : n			
					for i = 1 : m
						idx = offset + i
						@inbounds vi = $(h.term)
						@inbounds r[i] += vi
					end
					offset += m
				end
			else
				z = zero(R)
				for j = 1 : n
					@inbounds r[j] = z
				end
			end
		end

		global $(_accum!)
		function $(_accum!)(r::ContiguousArray, $(h.aparams...), dim::Int)
			shp = $(h.inputsize)
			
			if dim == 1
				m = shp[1]
				n = succ_length(shp, 1)
				_sum_eachcol!(m, n, r, $(h.args...))

			else
				m = prec_length(shp, dim)
				n = shp[dim]
				k = succ_length(shp, dim)

				if k == 1
					_sum_eachrow!(m, n, r, $(h.args...))
				else
					mn = m * n
					ro = 0
					ao = 0
					for l = 1 : k
						_sum_eachrow!(m, n, offset_view(r, ro, m), $(h.offset_args...))
						ro += m
						ao += mn
					end
				end
			end
			return r
		end

		global $(accum!)
		function $(accum!)(r::ContiguousArray, $(h.aparams...), dim::Int)
			length(r) == reduced_length($(h.inputsize), dim) || error("Invalid argument dimensions.")
			_sum!(r, $(h.args...), dim)
		end

		global $(accum)
		function $(accum)($(h.aparams...), dim::Int)
			rshp = reduced_shape($(h.inputsize), dim)
			_sum!(Array(sumtype($(h.termtype)), rshp), $(h.args...), dim)
		end		
	end
end

macro code_sumdim(AN, fname)
	esc(generate_sumdim_codes(AN, fname))
end

# specific functions

@code_sumdim 0 sum
@code_sumdim 1 sum
@code_sumdim 2 sum
@code_sumdim 3 sum
@code_sumdim (-2) sumfdiff

# derived functions

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

@mapreduce_fun1 sumabs   sum AbsFun   ContiguousArray ContiguousRealArray
@mapreduce_fun1 sumsq    sum Abs2Fun  ContiguousArray ContiguousRealArray
@mapreduce_fun1 sumxlogx sum XlogxFun ContiguousRealArray ContiguousRealArray
@mapreduce_fun2 sumxlogy sum XlogyFun ContiguousRealArray ContiguousRealArray
@mapreduce_fun2 dot      sum Multiply ContiguousRealArray ContiguousRealArray


