# Some useful utilities for computation

#################################################
#
#   Repeat each element for specific times
#
#   e.g. eachrepeat([3, 4], 2) ==> [3, 3, 4, 4]
#
#################################################

function eachrepeat{T}(x::AbstractVector{T}, rt::Integer)
	# repeat each element in x for rt times

	nx = length(x)
	r = Array(T, nx * rt)
	j = 0
	for i = 1 : nx
		@inbounds xi = x[i]
		for i2 = 1 : rt
			@inbounds r[j += 1] = xi
		end
	end
	return r
end

function eachrepeat{T,I<:Integer}(x::AbstractVector{T}, rt::AbstractArray{I})
	nx = length(x)
	nx == length(rt) || throw(ArgumentError("Inconsistent array lengths."))

	r = Array(T, sum(rt))
	j = 0
	for i = 1 : nx
		@inbounds xi = x[i]
		for i2 = 1 : rt[i]
			@inbounds r[j += 1] = xi
		end
	end
	return r
end

function eachrepeat{T}(x::AbstractMatrix{T}, rt::(Int, Int))
	mx = size(x, 1)
	nx = size(x, 2)
	r1::Int = rt[1]
	r2::Int = rt[2]

	r = Array(T, mx * r1, nx * r2)
	p::Int = 0

	for j = 1 : nx
		for j2 = 1 : r2
			for i = 1 : mx
				@inbounds xij = x[i, j]
				for i2 = 1 : r1
					r[p += 1] = xij 
				end
			end
		end
	end
	return r
end





