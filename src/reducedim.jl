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

function prepare_reducedim_args(AN::Int)
	# AN = 0:  a
	# AN = 1:  f(a1)
	# AN = 2:  f(a1, a2)
	# ...
	# AN = -2: f(a1 - a2)

	@assert AN >= 0 || AN == -2

	AN_ = abs(AN)
	AN_ = abs(AN)

	arrargs = [symbol("a$i") for i = 1 : AN_]

	args = AN == 0 ? [:a] : [:f, arrargs...]

	aparams = AN_ == 0 ? [:(a::ContiguousArray)] :
			  AN_ == 1 ? [:(f::Functor), :(a1::ContiguousArray)] :
			  [:(f::Functor), [Expr(:(::), arrargs[i], :ContiguousArray) for i = 1 : AN]...]

	term = AN == 0 ? :(a[idx]) :
		   AN >= 1 ? functor_evalexpr(:f, arrargs, :idx) :
		   functor_evalexpr(:f, arrargs, :idx; usediff=true)

	inputsize = AN == 0 ? :(size(a)) : :(mapshape($(args...)))

	offset_args = AN == 0 ? [:(offset_view(a, ao, m, n))] : 
				  [:f, [:(offset_view($a, ao, m, n)) for a in arrargs]...]

	return (aparams, args, term, inputsize, offset_args)
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

	(aparams, args, term, inputsize, offset_args) = prepare_reducedim_args(AN)

	# generate functions

	quote
		global $(_accum_eachcol!)
		function $(_accum_eachcol!){R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(aparams...))
			offset = 0
			if m > 0
				for j = 1 : n
					rj = _sum(offset+1, offset+m, $(args...))
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
		function $(_accum_eachrow!){R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(aparams...))
			if n > 0
				for idx = 1 : m
					@inbounds vi = $term
					@inbounds r[idx] = vi
				end

				offset = m
				for j = 2 : n			
					for i = 1 : m
						idx = offset + i
						@inbounds vi = $term
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
		function $(_accum!)(r::ContiguousArray, $(aparams...), dim::Int)
			shp = size(a)
			
			if dim == 1
				m = shp[1]
				n = succ_length(shp, 1)
				_sum_eachcol!(m, n, r, $(args...))

			else
				m = prec_length(shp, dim)
				n = shp[dim]
				k = succ_length(shp, dim)

				if k == 1
					_sum_eachrow!(m, n, r, $(args...))
				else
					mn = m * n
					ro = 0
					ao = 0
					for l = 1 : k
						_sum_eachrow!(m, n, offset_view(r, ro, m), $(offset_args...))
						ro += m
						ao += mn
					end
				end
			end
			return r
		end

		global $(accum!)
		function $(accum!)(r::ContiguousArray, $(aparams...), dim::Int)
			length(r) == reduced_length($(inputsize), dim) || error("Invalid argument dimensions.")
			_sum!(r, $(args...), dim)
		end

		global $(accum)
		function $(accum){T<:Number}(a::ContiguousArray{T}, dim::Int)
			rshp = reduced_shape($(inputsize), dim)
			_sum!(Array(sumtype(T), rshp), $(args...), dim)
		end		
	end
end

macro code_sumdim(AN, fname)
	esc(generate_sumdim_codes(AN, fname))
end

@code_sumdim 0 sum
# @code_sumdim 1 sum



