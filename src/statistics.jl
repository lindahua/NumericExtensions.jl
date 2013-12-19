# Reduction functions related to statistics


###################
#
#  Varm & Stdm
#
###################

# varm

function varm(x::ContiguousRealArray, mu::Real)
	!isempty(x) || error("varm: empty array is not allowed.")
	n = length(x)

	@inbounds s2 = abs2(x[1] - mu)
	for i = 2:n
		@inbounds s2 += abs2(x[i] - mu)
	end
	s2 / (n - 1)
end

function _varm_eachcol!{R<:Real}(m::Int, n::Int, dst::ContiguousArray{R}, x, mu)
	c = inv(m - 1)
	o = 0
	for j = 1:n
		s2 = zero(R)
		@inbounds mu_j = mu[j]
		for i = 1:m
			@inbounds s2 += abs2(x[o + i] - mu_j)
		end
		@inbounds dst[j] = s2 * c
		o += m
	end	
end

function _varm_eachrow!(m::Int, n::Int, dst::ContiguousRealArray, x, mu)
	o::Int = 0
	for i = 1:m
		@inbounds dst[i] = abs2(x[o + i] - mu[i])
	end
	o += m
	for j = 2:n-1
		for i = 1:m
			@inbounds dst[i] += abs2(x[o + i] - mu[i])
		end
		o += m
	end 
	c = inv(n - 1)
	for i = 1:m
		@inbounds v = dst[i] + abs2(x[o + i] - mu[i])
		dst[i] = v * c
	end
end

function varm!(dst::ContiguousRealArray, x::ContiguousRealArray, mu::ContiguousRealArray, dim::Int)
	!isempty(x) || error("varm!: empty array is not allowed.")

	nd = ndims(x)
	1 <= dim <= nd || error("varm: invalid value of dim.")

	shp = size(x)
	length(dst) == length(mu) == reduced_length(shp, dim) || error("Inconsistent argument dimensions.")

	if dim == 1
		m = shp[1]
		n = succ_length(shp, dim)
		_varm_eachcol!(m, n, dst, x, mu)

	else
		m = prec_length(shp, dim)
		n = shp[dim]
		k = succ_length(shp, dim)

		_varm_eachrow!(m, n, dst, x, mu)
		if k > 1
			mn = m * n
			ro = m
			ao = mn
			for l = 2 : k
				_varm_eachrow!(m, n, 
					offset_view(dst, ro, m), offset_view(x, ao, m, n), 
					offset_view(mu, ro, m))

				ro += m
				ao += mn
			end
		end
	end
	dst
end

function varm(x::ContiguousRealArray, mu::ContiguousRealArray, dim::Int)
	rsiz = reduced_shape(size(x), dim)
	length(mu) == prod(rsiz) || error("Inconsistent argument dimensions.")
	R = fptype(promote_type(eltype(x), eltype(mu)))
	varm!(Array(R, rsiz), x, mu, dim)
end

# stdm

stdm(x::ContiguousRealArray, mu::Real) = sqrt(varm(x, mu))
stdm(x::ContiguousRealArray, mu::ContiguousArray, dim::Int) = sqrt!(varm(x, mu, dim))

function stdm!(dst::ContiguousRealArray, x::ContiguousRealArray, mu::ContiguousRealArray, dim::Int)
	sqrt!(varm!(dst, x, mu, dim))
end


# ###################
# #
# #  Var & Std
# #
# ###################

# var{T<:Real}(x::ContiguousArray{T}) = varm(x, mean(x))

# function var!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, x::ContiguousVector{T}, dim::Int)
# 	if dim == 1
# 		dst[1] = var(x)
# 	else
# 		error("var: dim must be 1 for vector.")
# 	end
# 	dst
# end

# function var!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dim::Int)
# 	@check_nonempty("var")
# 	nd = ndims(x)
# 	if !(1 <= dim <= nd)
# 		error("var: invalid value for the dim argument.")
# 	end
# 	siz = size(x)

# 	if dim == 1
# 		m = siz[1]
# 		n = succ_length(siz, 1)
# 		for j in 1 : n
# 			dst[j] = var(unsafe_view(x, :, j))
# 		end		
# 	else
# 		varm!(dst, x, mean(x, dim), dim)
# 	end
# 	dst
# end

# function var{T<:Real}(x::ContiguousArray{T}, dim::Int)
# 	var!(Array(to_fptype(T), reduced_size(size(x), dim)), x, dim)
# end

# # std

# std{T<:Real}(x::ContiguousArray{T}) = sqrt(var(x))
# std{T<:Real}(x::ContiguousArray{T}, dim::Int) = sqrt!(var(x, dim))
# std!{R<:FloatingPoint, T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dim::Int) = sqrt!(var!(dst, x, dim))


# ###################
# #
# #  LogFunsumexp
# #
# ###################

# function logsumexp{T<:Real}(x::ContiguousArray{T})
# 	@check_nonempty("logsumexp")
# 	u = maximum(x)
# 	log(sumfdiff(ExpFun(), x, u)) + u
# end

# function logsumexp!{R<:FloatingPoint, T<:Real}(dst::ContiguousArray{R}, x::ContiguousVector{T}, dim::Int)
# 	if dim == 1
# 		dst[1] = logsumexp(x)
# 	else
# 		error("logsumexp: dim must be 1 for vector.")
# 	end
# 	dst
# end

# function _logsumexp_firstdim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, m::Int, n::Int)
# 	o = 0
# 	for j in 1 : n
# 		# compute max
# 		u = x[o + 1]
# 		for i in 2 : m
# 			@inbounds xi = x[o + i]
# 			if xi > u
# 				u = xi
# 			end
# 		end

# 		# sum exp
# 		@inbounds s = exp(x[o + 1] - u)
# 		for i in 2 : m
# 			@inbounds s += exp(x[o + i] - u)
# 		end

# 		# compute log
# 		dst[j] = log(s) + u
# 		o += m
# 	end
# end

# function _logsumexp_lastdim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, 
# 	u::ContiguousArray{T}, x::ContiguousArray{T}, m::Int, n::Int)

# 	# compute max
# 	for i in 1 : m
# 		@inbounds u[i] = x[i]
# 	end
# 	o = m
# 	for j in 2 : n
# 		for i in 1 : m
# 			@inbounds u[i] = max(u[i], x[o + i])
# 		end
# 		o += m
# 	end

# 	# sum exp
# 	for i in 1 : m
# 		@inbounds dst[i] = exp(x[i] - u[i])
# 	end
# 	o = m
# 	for j in 2 : n
# 		for i in 1 : m
# 			@inbounds dst[i] += exp(x[o + i] - u[i])
# 		end
# 		o += m
# 	end

# 	# compute log
# 	for i in 1 : m
# 		@inbounds dst[i] = log(dst[i]) + u[i]
# 	end
# end

# function _logsumexp_middim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, 
# 	u::ContiguousArray{T}, x::ContiguousArray{T}, m::Int, n::Int, k::Int)

# 	for l in 1 : k
# 		_logsumexp_lastdim!(unsafe_view(dst, :, l), u, unsafe_view(x, :, :, l), m, n)
# 	end
# end


# function logsumexp!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dim::Int)
# 	@check_nonempty("logsumexp")
# 	nd = ndims(x)
# 	if !(1 <= dim <= nd)
# 		error("logsumexp: invalid value for the dim argument.")
# 	end
# 	siz = size(x)

# 	if dim == 1
# 		_logsumexp_firstdim!(dst, x, siz[1], succ_length(siz, dim))
# 	elseif dim == nd
# 		prelen = prec_length(siz, dim)
# 		_logsumexp_lastdim!(dst, Array(T, prelen), x, prelen, siz[dim])
# 	else
# 		prelen = prec_length(siz, dim)
# 		_logsumexp_middim!(dst, Array(T, prelen), x, prelen, siz[dim], succ_length(siz, dim))
# 	end
# 	dst
# end

# function logsumexp{T<:Real}(x::ContiguousArray{T}, dim::Int)
# 	logsumexp!(Array(to_fptype(T), reduced_size(size(x), dim)), x, dim)
# end


# ###################
# #
# #  Softmax
# #
# ###################

# function softmax!{T<:FloatingPoint}(dst::ContiguousArray{T}, x::ContiguousArray{T})
# 	@check_nonempty("softmax")
# 	u = maximum(x)
# 	s = dst[1] = exp(x[1] - u)
# 	n = length(x)
# 	for i in 2 : n
# 		@inbounds s += (dst[i] = exp(x[i] - u))
# 	end
# 	c = inv(s)
# 	for i in 1 : n
# 		@inbounds dst[i] *= c
# 	end
# 	dst
# end

# function softmax{T<:FloatingPoint}(x::ContiguousArray{T})
# 	softmax!(Array(T, size(x)), x)
# end

# function softmax!{T<:FloatingPoint}(dst::ContiguousArray{T}, x::ContiguousVector{T}, dim::Int)
# 	if dim == 1
# 		softmax!(dst, x)
# 	else
# 		error("softmax: dim must be 1 for vector.")
# 	end
# 	dst	
# end

# function _softmax_firstdim!{T<:FloatingPoint}(dst::ContiguousArray{T}, x::ContiguousArray{T}, m::Int, n::Int)
# 	for j in 1 : n
# 		softmax!(unsafe_view(dst, :, j), unsafe_view(x, :, j))
# 	end
# end

# function _softmax_lastdim!{T<:FloatingPoint}(dst::ContiguousArray{T}, 
# 	u::ContiguousArray{T}, x::ContiguousArray{T}, m::Int, n::Int)

# 	# compute max
# 	for i in 1 : m
# 		@inbounds u[i] = x[i]
# 	end
# 	o = m
# 	for j in 2 : n
# 		for i in 1 : m
# 			@inbounds u[i] = max(u[i], x[o + i])
# 		end
# 		o += m
# 	end

# 	# compute sum
# 	s = unsafe_view(u, m+1:2*m)

# 	for i in 1 : m
# 		@inbounds s[i] = dst[i] = exp(x[i] - u[i])
# 	end
# 	o = m

# 	for j in 2 : n
# 		for i in 1 : m
# 			@inbounds s[i] += (dst[o + i] = exp(x[o + i] - u[i]))
# 		end
# 		o += m
# 	end

# 	rcp!(s)
# 	o = 0
# 	for j in 1 : n
# 		for i in 1 : m
# 			@inbounds dst[o + i] .*= s[i]
# 		end
# 		o += m
# 	end
# end

# function _softmax_middim!{T<:FloatingPoint}(dst::ContiguousArray{T}, 
# 	u::ContiguousArray{T}, x::ContiguousArray{T}, m::Int, n::Int, k::Int)

# 	for l in 1 : k
# 		_softmax_lastdim!(unsafe_view(dst, :, :, l), u, unsafe_view(x, :, :, l), m, n)
# 	end
# end

# function softmax!{T<:FloatingPoint}(dst::ContiguousArray{T}, x::ContiguousArray{T}, dim::Int)
# 	@check_nonempty("softmax!")
# 	nd = ndims(x)
# 	if !(1 <= dim <= nd)
# 		error("softmax: invalid value for the dim argument.")
# 	end
# 	siz = size(x)

# 	if dim == 1
# 		_softmax_firstdim!(dst, x, siz[1], succ_length(siz, dim))
# 	elseif dim == nd
# 		prelen = prec_length(siz, dim)
# 		_softmax_lastdim!(dst, Array(T, prelen * 2), x, prelen, siz[dim])
# 	else
# 		prelen = prec_length(siz, dim)
# 		_softmax_middim!(dst, Array(T, prelen * 2), x, prelen, siz[dim], succ_length(siz, dim))
# 	end
# 	dst	
# end

# function softmax{T<:FloatingPoint}(x::ContiguousArray{T}, dim::Int)
# 	softmax!(Array(T, size(x)), x, dim)
# end

