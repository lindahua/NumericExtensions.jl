# reduction


#################################################
#
#    generic folding
#
#################################################

function _foldl(ifirst::Int, ilast::Int, op::Functor{2}, s::Number, a::NumericArray)
	i = ifirst
	while i <= ilast
		@inbounds ai = a[i]
		s = evaluate(op, s, ai)
		i += 1
	end
	return s
end

foldl(op::Functor{2}, s::Number, a::NumericArray) = _foldl(1, length(a), op, s, a)
foldl(op::Functor{2}, a::NumericArray) = _foldl(2, length(a), op, a[1], a)


function _foldr(ifirst::Int, ilast::Int, op::Functor{2}, s::Number, a::NumericArray)
	i = ilast
	while i >= ifirst
		@inbounds ai = a[i]
		s = evaluate(op, ai, s)
		i -= 1
	end
	return s
end

foldr(op::Functor{2}, s::Number, a::NumericArray) = _foldr(1, length(a), op, s, a)
foldr(op::Functor{2}, a::NumericArray) = _foldr(1, length(a)-1, op, a[end], a)


#################################################
#
#    sum & mean
#
#################################################

## 
#  sequential sum
# 
function seqsum{T}(a::NumericArray{T}, ifirst::Int, ilast::Int)
	if ifirst + 3 >= ilast
		s = zero(T)
		i = ifirst
		while i <= ilast
			@inbounds s += a[i]
			i += 1
		end
		return s

	else # a has more than four elements

		# the purpose of using multiple accumulators here
		# is to leverage instruction pairing to hide 
		# read-after-write latency. Benchmark shows that
		# this can lead to considerable performance
		# improvement (nearly 2x).		

		@inbounds s1 = a[ifirst]
		@inbounds s2 = a[ifirst + 1]
		@inbounds s3 = a[ifirst + 2]
		@inbounds s4 = a[ifirst + 3]

		i = ifirst + 4
		il = ilast - 3
		while i <= il
			@inbounds s1 += a[i]
			@inbounds s2 += a[i+1]
			@inbounds s3 += a[i+2]
			@inbounds s4 += a[i+3]
			i += 4
		end

		while i <= ilast
			@inbounds s1 += a[i]
			i += 1
		end

		return s1 + s2 + s3 + s4
	end
end

seqsum(a::NumericArray) = seqsum(a, 1, length(a))

const CASSUM_BLOCKLEN = 1024

##
#
#  cascade sum
#
function cassum(a::NumericArray, ifirst::Int, ilast::Int)
	if ifirst + CASSUM_BLOCKLEN >= ilast
		seqsum(a, ifirst, ilast)
	else
		imid = ifirst + ((ilast - ifirst) >> 1)
		cassum(a, ifirst, imid) + cassum(a, imid+1, ilast)
	end
end


cassum(a::NumericArray, ifirst::Integer, ilast::Integer) = cassum(a, int(ifirst), int(ilast))
cassum(a::NumericArray) = cassum(a, 1, length(a))

_sum(ifirst::Int, ilast::Int, a::NumericArray) = cassum(a, ifirst, ilast)

##
#
#  default sum
#
sum(a::NumericArray) = cassum(a)
mean(a::NumericArray) = cassum(a) / length(a)


#################################################
#
#    maximum & minimum
#
#################################################

gt_or_nan(s::Number, x) = (s > x)
lt_or_nan(s::Number, x) = (s < x)

gt_or_nan(s::FloatingPoint, x) = (s > x || s != s)
lt_or_nan(s::FloatingPoint, x) = (s < x || s != s)


function _maximum{T<:Integer}(ifirst::Int, ilast::Int, a::NumericArray{T})
	if ifirst > ilast
		error("Argument for maximum cannot be empty.")
	end
	@inbounds s = a[ifirst]

	i = ifirst + 1
	while i <= ilast
		@inbounds ai = a[i]
		if ai > s
			s = ai
		end
		i += 1
	end
	return s
end

function _maximum{T<:FloatingPoint}(ifirst::Int, ilast::Int, a::NumericArray{T})
	if ifirst > ilast
		error("Argument for maximum cannot be empty.")
	end
	@inbounds s = a[ifirst]
	
	# locate the first non-nan value
	i = ifirst + 1
	while i <= ilast && s != s
		@inbounds s = a[i]
		i += 1
	end

	# continue the remaining part
	while i <= ilast
		@inbounds ai = a[i]
		if ai > s  # ai must not be NaN
			s = ai
		end
		i += 1
	end

	return s
end

function _minimum{T<:Integer}(ifirst::Int, ilast::Int, a::NumericArray{T})
	if ifirst > ilast
		error("Argument for minimum cannot be empty.")
	end
	@inbounds s = a[ifirst]

	i = ifirst + 1
	while i <= ilast
		@inbounds ai = a[i]
		if ai < s
			s = ai
		end
		i += 1
	end
	return s
end

function _minimum{T<:FloatingPoint}(ifirst::Int, ilast::Int, a::NumericArray{T})
	if ifirst > ilast
		error("Argument for minimum cannot be empty.")
	end
	@inbounds s = a[ifirst]
	
	# locate the first non-nan value
	i = ifirst + 1
	while i <= ilast && s != s
		@inbounds s = a[i]
		i += 1
	end

	# continue the remaining part
	while i <= ilast
		@inbounds ai = a[i]
		if ai < s  # ai must not be NaN
			s = ai
		end
		i += 1
	end

	return s
end

maximum{T<:Integer}(a::NumericArray{T}) = _maximum(1, length(a), a)
maximum{T<:FloatingPoint}(a::NumericArray{T}) = _maximum(1, length(a), a)
minimum{T<:Integer}(a::NumericArray{T}) = _minimum(1, length(a), a)
minimum{T<:FloatingPoint}(a::NumericArray{T}) = _minimum(1, length(a), a)


