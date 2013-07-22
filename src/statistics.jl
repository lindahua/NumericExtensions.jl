# Reduction functions related to statistics

###################
#
#  Mean
#
###################

macro check_nonempty(funname)
	quote
		if isempty(x)
			error("$($funname) of empty collection undefined")
		end
	end
end

function mean(x::ContiguousArray)
	@check_nonempty("mean")
	sum(x) / length(x)
end

function mean{T<:Real}(x::ContiguousArray{T}, dims::DimSpec)
	@check_nonempty("mean")
	r = to_fparray(sum(x, dims))
	c = convert(eltype(r), inv(_reduc_dim_length(x, dims)))
	multiply!(r, c)
end

function mean!{R<:Real,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dims::DimSpec)
	@check_nonempty("mean")
	c = convert(R, inv(_reduc_dim_length(x, dims)))
	multiply!(sum!(dst, x, dims), c)
end

###################
#
#  Varm & Stdm
#
###################

# varm

function varm{T<:Real}(x::ContiguousArray{T}, mu::Real)
	@check_nonempty("varm")
	n = length(x)

	s2 = abs2(x[1] - mu)
	for i = 2:n
		@inbounds s2 += abs2(x[i] - mu)
	end
	s2 / (n - 1)
end

function varm!{R<:FloatingPoint,T<:Real}(dst::Array{R}, x::ContiguousVector{T}, mu::Real, dim::Int)
	if dim == 1
		dst[1] = varm(x, mu)
	else
		error("varm: dim must be 1 for vector.")
	end
	dst
end

function _varm_colwise!{R}(dst::ContiguousArray{R}, x, mu, m::Int, n::Int)
	c = inv(m - 1)
	o = 0
	for j = 1:n
		s2 = zero(R)
		mu_j = mu[j]
		for i = 1:m
			@inbounds s2 += abs2(x[o + i] - mu_j)
		end
		dst[j] = s2 * c
		o += m
	end	
end

function _varm_rowwise!(dst, x, mu, m::Int, n::Int)
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

function varm!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, 
	x::ContiguousArray{T}, mu::ContiguousArray{R}, dim::Int)

	@check_nonempty("var")
	nd = ndims(x)
	if !(1 <= dim <= nd)
		error("varm: invalid value for the dim argument.")
	end
	siz = size(x)

	if dim == 1
		m = siz[1]
		n = _trail_length(siz, dim)
		_varm_colwise!(dst, x, mu, m, n)

	elseif dim == nd
		m = _precede_length(siz, dim)
		n = siz[dim]
		_varm_rowwise!(dst, x, mu, m, n)

	else  # 1 < dim < nd
		m = _precede_length(siz, dim)
		n = siz[dim]
		k = _trail_length(siz, dim)
		for l = 1:k
			_varm_rowwise!(
				unsafe_view(dst,:,l), unsafe_view(x,:,:,l), 
				unsafe_view(mu,:,l), m, n)
		end
	end
	dst
end

function varm{R<:FloatingPoint, T<:Real}(x::ContiguousArray{T}, mu::ContiguousArray{R}, dim::Int)
	rsiz = reduced_size(size(x), dim)
	if length(mu) != prod(rsiz)
		error("Inconsistent argument dimensions.")
	end
	varm!(Array(R, rsiz), x, mu, dim)
end

# stdm

stdm{T<:Real}(x::ContiguousArray{T}, mu::Real) = sqrt(varm(x, mu))
stdm{T<:Real}(x::ContiguousArray{T}, mu::ContiguousArray{T}, dim::Int) = sqrt!(varm(x, mu, dim))

function stdm!{R<:FloatingPoint, T<:Real}(dst::ContiguousArray{R}, 
	x::ContiguousArray{T}, mu::ContiguousArray{T}, dim::Int)

	sqrt!(varm!(dst, x, mu, dim))
end


###################
#
#  Var & Std
#
###################

function _var{R<:FloatingPoint, T<:Real}(::Type{R}, x::ContiguousArray{T}, ifirst::Int, ilast::Int)
	s = zero(R)
	s2 = zero(R)
	
	nm1 = ilast - ifirst
	n = nm1 + 1
	rg = ifirst : ilast

	for i in rg
		@inbounds xi = x[i]
		s += xi
	end
	mu = s / n

	for i in rg
		@inbounds xi = x[i]
		s2 += abs2(xi - mu)
	end
	s2 / nm1
end

function var{T<:Real}(x::Array{T})
	@check_nonempty("var")
	_var(to_fptype(T), x, 1, length(x))
end

function var!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, x::ContiguousVector{T}, dim::Int)
	if dim == 1
		dst[1] = var(x)
	else
		error("var: dim must be 1 for vector.")
	end
	dst
end

function var!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dim::Int)
	@check_nonempty("var")
	nd = ndims(x)
	if !(1 <= dim <= nd)
		error("var: invalid value for the dim argument.")
	end
	siz = size(x)

	if dim == 1
		o = 0
		m = siz[1]
		n = _trail_length(siz, 1)
		for j in 1 : n
			dst[j] = _var(R, x, o+1, o+m)
			o += m
		end		
	else
		varm!(dst, x, mean(x, dim), dim)
	end
	dst
end

function var{T<:Real}(x::Array{T}, dim::Int)
	var!(Array(to_fptype(T), reduced_size(size(x), dim)), x, dim)
end

# std

std{T<:Real}(x::ContiguousArray{T}) = sqrt(var(x))
std{T<:Real}(x::ContiguousArray{T}, dim::Int) = sqrt!(var(x, dim))
std!{R<:FloatingPoint, T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dim::Int) = sqrt!(var!(dst, x, dim))


###################
#
#  Entropy
#
###################

entropy{T<:Real}(x::ContiguousArray{T}) = - sum_xlogx(x)
entropy{T<:Real}(x::ContiguousArray{T}, dims::DimSpec) = negate!(sum_xlogx(x, dims))
entropy!{T<:Real}(dst::ContiguousArray{T}, x::ContiguousArray{T}, dims::DimSpec) = negate!(sum_xlogx!(dst, x, dims))


###################
#
#  Logsumexp
#
###################

function logsumexp{T<:Real}(x::ContiguousArray{T})
	@check_nonempty("logsumexp")
	u = max(x)
	log(sum_fdiff(Exp(), x, u)) + u
end

function logsumexp!{R<:FloatingPoint, T<:Real}(dst::ContiguousArray{R}, x::ContiguousVector{T}, dim::Int)
	if dim == 1
		dst[1] = logsumexp(x)
	else
		error("logsumexp: dim must be 1 for vector.")
	end
	dst
end

function _logsumexp_firstdim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, m::Int, n::Int)
	o = 0
	for j in 1 : n
		# compute max
		u = x[o + 1]
		for i in 2 : m
			@inbounds xi = x[o + i]
			if xi > u
				u = xi
			end
		end

		# sum exp
		@inbounds s = exp(x[o + 1] - u)
		for i in 2 : m
			@inbounds s += exp(x[o + i] - u)
		end

		# compute log
		dst[j] = log(s) + u
		o += m
	end
end

function _logsumexp_lastdim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, 
	u::ContiguousArray{T}, x::ContiguousArray{T}, m::Int, n::Int)

	# compute max
	max!(u, unsafe_view(x, :, 1:n), (), 2)

	# sum exp
	for i in 1 : m
		@inbounds dst[i] = exp(x[i] - u[i])
	end
	o = m
	for j in 2 : n
		for i in 1 : m
			@inbounds dst[i] += exp(x[o + i] - u[i])
		end
		o += m
	end

	# compute log
	for i in 1 : m
		@inbounds dst[i] = log(dst[i]) + u[i]
	end
end

function _logsumexp_middim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, 
	u::ContiguousArray{T}, x::ContiguousArray{T}, m::Int, n::Int, k::Int)

	for l in 1 : k
		_logsumexp_lastdim!(unsafe_view(dst, :, l), u, unsafe_view(x, :, :, l), m, n)
	end
end


function logsumexp!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dim::Int)
	@check_nonempty("logsumexp")
	nd = ndims(x)
	if !(1 <= dim <= nd)
		error("logsumexp: invalid value for the dim argument.")
	end
	siz = size(x)

	if dim == 1
		_logsumexp_firstdim!(dst, x, siz[1], _trail_length(siz, dim))
	elseif dim == nd
		prelen = _precede_length(siz, dim)
		_logsumexp_lastdim!(dst, Array(T, prelen), x, prelen, siz[dim])
	else
		prelen = _precede_length(siz, dim)
		_logsumexp_middim!(dst, Array(T, prelen), x, prelen, siz[dim], _trail_length(siz, dim))
	end
	dst
end

function logsumexp{T<:Real}(x::ContiguousArray{T}, dim::Int)
	logsumexp!(Array(to_fptype(T), reduced_size(size(x), dim)), x, dim)
end


###################
#
#  Softmax
#
###################

function softmax!{T<:FloatingPoint}(dst::ContiguousArray{T}, x::ContiguousArray{T})
	@check_nonempty("softmax")
	u = max(x)
	s = dst[1] = exp(x[1] - u)
	n = length(x)
	for i in 2 : n
		@inbounds s += (dst[i] = exp(x[i] - u))
	end
	c = inv(s)
	for i in 1 : n
		@inbounds dst[i] *= c
	end
	dst
end

function softmax{T<:FloatingPoint}(x::ContiguousArray{T})
	softmax!(Array(T, size(x)), x)
end

function softmax!{T<:FloatingPoint}(dst::ContiguousArray{T}, x::ContiguousVector{T}, dim::Int)
	if dim == 1
		softmax!(dst, x)
	else
		error("softmax: dim must be 1 for vector.")
	end
	dst	
end

function _softmax_firstdim!{T<:FloatingPoint}(dst::ContiguousArray{T}, x::ContiguousArray{T}, m::Int, n::Int)
	for j in 1 : n
		softmax!(unsafe_view(dst, :, j), unsafe_view(x, :, j))
	end
end

function _softmax_lastdim!{T<:FloatingPoint}(dst::ContiguousArray{T}, 
	u::ContiguousArray{T}, x::ContiguousArray{T}, m::Int, n::Int)

	# compute max
	max!(u, unsafe_view(x, :, 1:n), (), 2)

	# compute sum
	s = unsafe_view(u, m+1:2*m)

	for i in 1 : m
		@inbounds s[i] = dst[i] = exp(x[i] - u[i])
	end
	o = m

	for j in 2 : n
		for i in 1 : m
			@inbounds s[i] += (dst[o + i] = exp(x[o + i] - u[i]))
		end
		o += m
	end

	rcp!(s)
	o = 0
	for j in 1 : n
		for i in 1 : m
			@inbounds dst[o + i] .*= s[i]
		end
		o += m
	end
end

function _softmax_middim!{T<:FloatingPoint}(dst::ContiguousArray{T}, 
	u::ContiguousArray{T}, x::ContiguousArray{T}, m::Int, n::Int, k::Int)

	for l in 1 : k
		_softmax_lastdim!(unsafe_view(dst, :, :, l), u, unsafe_view(x, :, :, l), m, n)
	end
end

function softmax!{T<:FloatingPoint}(dst::ContiguousArray{T}, x::ContiguousArray{T}, dim::Int)
	@check_nonempty("softmax!")
	nd = ndims(x)
	if !(1 <= dim <= nd)
		error("softmax: invalid value for the dim argument.")
	end
	siz = size(x)

	if dim == 1
		_softmax_firstdim!(dst, x, siz[1], _trail_length(siz, dim))
	elseif dim == nd
		prelen = _precede_length(siz, dim)
		_softmax_lastdim!(dst, Array(T, prelen * 2), x, prelen, siz[dim])
	else
		prelen = _precede_length(siz, dim)
		_softmax_middim!(dst, Array(T, prelen * 2), x, prelen, siz[dim], _trail_length(siz, dim))
	end
	dst	
end

function softmax{T<:FloatingPoint}(x::ContiguousArray{T}, dim::Int)
	softmax!(Array(T, size(x)), x, dim)
end

