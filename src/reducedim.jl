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

function _sum_eachcol!{R<:Number,T<:Number}(r::ContiguousArray{R}, a::ContiguousArray{T}, m::Int, n::Int)
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

function _sum_eachrow!{R<:Number,T<:Number}(r::ContiguousArray{R}, a::ContiguousArray{T}, m::Int, n::Int, offset::Int)
	if n > 0
		for i = 1 : m
			@inbounds r[i] = a[offset + i]
		end

		for j = 2 : n
			offset += m
			for i = 1 : m
				@inbounds r[i] += a[offset + i]
			end
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
		_sum_eachcol!(r, a, m, n)

	else
		m = prec_length(shp, dim)
		n = shp[dim]
		k = succ_length(shp, dim)

		if k == 1
			_sum_eachrow!(r, a, m, n, 0)
		else
			offset = 0
			mn = m * n
			for l = 1 : k
				_sum_eachrow!(r, a, m, n, offset)
				offset += mn
			end
		end
	end
	return r
end


function sum!(r::ContiguousArray, a::ContiguousArray, dim::Int)
	length(r) != reduced_length(size(a), dim) || error("Invalid argument dimensions.")
	_sum!(r, a, dim)
end

function sum!{T}(a::ContiguousArray{T}, dim::Int)
	rshp = reduced_shape(size(a), dim)
	_sum!(Array(T, rshp), a, dim)
end

