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


function generate_reducedim_facets(h::CodegenHelper, accum::Symbol)

	# function names
	_accum_eachcol! = symbol("_$(accum)_eachcol!")
	_accum_eachrow! = symbol("_$(accum)_eachrow!")
	_accum! = symbol("_$(accum)!")
	accum! = symbol("$(accum)!")	

	quote
		global $(_accum!)
		function $(_accum!)(r::ContiguousArray, $(h.aparams...), dim::Int)
			shp = $(h.inputsize)
			
			if dim == 1
				m = shp[1]
				n = succ_length(shp, 1)
				$(_accum_eachcol!)(m, n, r, $(h.args...))

			else
				m = prec_length(shp, dim)
				n = shp[dim]
				k = succ_length(shp, dim)

				if k == 1
					$(_accum_eachrow!)(m, n, r, $(h.args...))
				else
					mn = m * n
					ro = 0
					ao = 0
					for l = 1 : k
						$(_accum_eachrow!)(m, n, offset_view(r, ro, m), $(h.offset_args...))
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
			$(_accum!)(r, $(h.args...), dim)
		end

		global $(accum)
		function $(accum)($(h.aparams...), dim::Int)
			rshp = reduced_shape($(h.inputsize), dim)
			$(_accum!)(Array(sumtype($(h.termtype)), rshp), $(h.args...), dim)
		end	
	end
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
	_accum = symbol("_$(accum)")

	# parameter & argument preparation

	h = codegen_helper(AN)
	facets = generate_reducedim_facets(h, accum) 

	# generate functions

	quote
		global $(_accum_eachcol!)
		function $(_accum_eachcol!){R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(h.aparams...))
			offset = 0
			if m > 0
				for j = 1 : n
					rj = ($_accum)(offset+1, offset+m, $(h.args...))
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

		$(facets)
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

function generate_maxmindim_codes(AN::Int, accum::Symbol, comp::Symbol)

	# function names
	_accum_eachcol! = symbol("_$(accum)_eachcol!")
	_accum_eachrow! = symbol("_$(accum)_eachrow!")
	_accum = symbol("_$(accum)")

	# parameter & argument preparation

	h = codegen_helper(AN)
	facets = generate_reducedim_facets(h, accum) 

	comparef = (v, s)->Expr(:comparison, v, comp, s)

	# generate functions

	quote
		global $(_accum_eachcol!)
		function $(_accum_eachcol!){R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(h.aparams...))
			offset = 0
			if m > 0
				for j = 1 : n
					rj = ($_accum)(offset+1, offset+m, $(h.args...))
					@inbounds r[j] = rj
					offset += m
				end
			else
				error("maximum/minimum along empty dimensions is not allowed.")
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
						@inbounds ri = r[i]
						if $(comparef(:vi, :ri)) || (ri != ri)
							@inbounds r[i] = vi
						end
					end
					offset += m
				end
			else
				error("maximum/minimum along empty dimensions is not allowed.")
			end
		end

		$(facets)
	end
end

macro code_maximumdim(AN, fname)
	esc(generate_maxmindim_codes(AN, fname, :>))
end

macro code_minimumdim(AN, fname)
	esc(generate_maxmindim_codes(AN, fname, :<))
end

@code_maximumdim 0 maximum
@code_maximumdim 1 maximum
@code_maximumdim 2 maximum
@code_maximumdim 3 maximum
@code_maximumdim (-2) maxfdiff

@code_minimumdim 0 minimum
@code_minimumdim 1 minimum
@code_minimumdim 2 minimum
@code_minimumdim 3 minimum
@code_minimumdim (-2) minfdiff


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



