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
#    sum along dims
#
#################################################

# function code_sumdim(AN::Int, accum::Symbol, initcode)

# 	@assert AN >= 0 || AN == -2

# 	# parameter & argument preparation

# 	AN_ = abs(AN)
# 	arrargs = [symbol("a$i") for i = 1 : AN_]

# 	args = AN == 0 ? [:a] : [:f, arrargs...]

# 	aparams = AN_ == 0 ? [:(a::ContiguousArray)] :
# 			  AN_ == 1 ? [:(f::Functor), :(a1::ContiguousArray)] :
# 			  [:(f::Functor), [Expr(:(::), arrargs[i], :ContiguousArray) for i = 1 : AN]...]

# 	termf = AN == 0 ? (i->:(a[$i])) :
# 			AN >= 1 ? (i->functor_evalexpr(:f, arrargs, i)) :
# 			(i->functor_evalexpr(:f, arrargs, i; usediff=true))

# 	# generate functions

# 	quote
# 		function _sum_eachcol!{R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(aparams...))
# 			offset = 0
# 			if m > 0
# 				for j = 1 : n
# 					rj = _sum(offset+1, offset+m, $(args...))
# 					@inbounds r[j] = rj
# 					offset += m
# 				end
# 			else
# 				z = zero(R)
# 				for j = 1 : n
# 					@inbounds r[j] = z
# 				end
# 			end	
# 		end
	
# 		function _sum_eachrow!{R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(aparams...))
# 			if n > 0
# 				for i = 1 : m
# 					@inbounds vi = $(termf(:i))
# 					@inbounds r[i] = vi
# 				end

# 				offset = m
# 				for j = 2 : n			
# 					for i = 1 : m
# 						idx = offset + i
# 						@inbounds vi = $(termf(:idx))
# 						@inbounds r[i] += vi
# 					end
# 					offset += m
# 				end
# 			else
# 				z = zero(R)
# 				for j = 1 : n
# 					@inbounds r[j] = z
# 				end
# 			end
# 		end

# 		function _sum!(r::ContiguousArray, $(aparams...), dim::Int)
# 			shp = size(a)
			
# 			if dim == 1
# 				m = shp[1]
# 				n = succ_length(shp, 1)
# 				_sum_eachcol!(m, n, r, $(args...))

# 			else
# 				m = prec_length(shp, dim)
# 				n = shp[dim]
# 				k = succ_length(shp, dim)

# 				if k == 1
# 					_sum_eachrow!(m, n, r, $(args...))
# 				else
# 					mn = m * n
# 					ro = 0
# 					ao = 0
# 					for l = 1 : k
# 						_sum_eachrow!(m, n, offset_view(r, ro, m), $(offset_args...))
# 						ro += m
# 						ao += mn
# 					end
# 				end
# 			end
# 			return r
# 		end

# 		function sum!(r::ContiguousArray, $(aparams...), dim::Int)
# 			length(r) == reduced_length($(input_size), dim) || error("Invalid argument dimensions.")
# 			_sum!(r, $(args...), dim)
# 		end

# 		function sum{T}(a::ContiguousArray{T}, dim::Int)
# 			rshp = reduced_shape($(input_size), dim)
# 			_sum!(Array(T, rshp), $(args...), dim)
# 		end		
# 	end
# end


function _sum_eachcol!{R<:Number,T<:Number}(m::Int, n::Int, r::ContiguousArray{R}, a::ContiguousArray{T})
	offset = 0
	if m > 0
		for j = 1 : n
			rj = cassum(a, offset+1, offset+m)
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

function _sum_eachrow!{R<:Number,T<:Number}(m::Int, n::Int, r::ContiguousArray{R}, a::ContiguousArray{T})
	if n > 0
		for i = 1 : m
			@inbounds r[i] = a[i]
		end

		offset = m
		for j = 2 : n			
			for i = 1 : m
				@inbounds r[i] += a[offset + i]
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

function _sum!{R<:Number,T<:Number,D}(r::ContiguousArray{R}, a::ContiguousArray{T,D}, dim::Int)
	shp = size(a)
	
	if dim == 1
		m = shp[1]
		n = succ_length(shp, 1)
		_sum_eachcol!(m, n, r, a)

	else
		m = prec_length(shp, dim)
		n = shp[dim]
		k = succ_length(shp, dim)

		if k == 1
			_sum_eachrow!(m, n, r, a)
		else
			mn = m * n
			ro = 0
			ao = 0
			for l = 1 : k
				_sum_eachrow!(m, n, offset_view(r, ro, m), offset_view(a, ao, m, n))
				ro += m
				ao += mn
			end
		end
	end
	return r
end


function sum!(r::ContiguousArray, a::ContiguousArray, dim::Int)
	length(r) == reduced_length(size(a), dim) || error("Invalid argument dimensions.")
	_sum!(r, a, dim)
end

function sum{T}(a::ContiguousArray{T}, dim::Int)
	rshp = reduced_shape(size(a), dim)
	_sum!(Array(T, rshp), a, dim)
end

