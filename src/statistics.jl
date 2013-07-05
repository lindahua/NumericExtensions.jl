# Reduction functions related to statistics

# mean

macro check_nonempty(funname)
	quote
		if isempty(x)
			error("$($funname) of empty collection undefined")
		end
	end
end

function mean(x::Array)
	@check_nonempty("mean")
	sum(x) / length(x)
end

function mean{T<:Real}(x::Array{T}, dims::DimSpec)
	@check_nonempty("mean")
	r = to_fparray(sum(x, dims))
	c = convert(eltype(r), inv(_reduc_dim_length(x, dims)))
	multiply!(r, c)
end

function mean!{R<:Real,T<:Real}(dst::Array{R}, x::Array{T}, dims::DimSpec)
	@check_nonempty("mean")
	c = convert(R, inv(_reduc_dim_length(x, dims)))
	multiply!(sum!(dst, x, dims), c)
end

# var

function _var{R<:FloatingPoint, T<:Real}(::Type{R}, x::Array{T}, ifirst::Int, ilast::Int)
	xi = x[ifirst]
	s = convert(R, xi)
	s2 = convert(R, xi * xi)

	for i in ifirst+1 : ilast
		@inbounds xi = x[i]
		s += xi
		s2 += xi * xi
	end

	nm1 = ilast - ifirst
	n = nm1 + 1
	mu = s / n
	max((s2 - n * (mu * mu)) / nm1, zero(R))
end


function var{T<:Real}(x::Array{T})
	@check_nonempty("var")
	_var(to_fptype(T), x, 1, length(x))
end


function var!{R<:FloatingPoint,T<:Real}(dst::Array{R}, x::Vector{T}, dim::Int)
	if dim == 1
		dst[1] = var(x)
	else
		error("var: dim must be 1 for vector.")
	end
	dst
end

function _varimpl_firstdim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, m::Int, n::Int)
	o = 0
	for j in 1 : n
		dst[j] = _var(R, x, o+1, o+m)
		o += m
	end
end

function _varimpl_lastdim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, s::Array{R}, x::ContiguousArray{T}, m::Int, n::Int)
	for i in 1 : m
		@inbounds xi = x[i]
		@inbounds s[i] = xi
		@inbounds dst[i] = xi * xi
	end

	o = m
	for j in 2 : n
		for i in 1 : m
			@inbounds xi = x[o + i]
			@inbounds s[i] += xi
			@inbounds dst[i] += xi * xi
		end
		o += m
	end

	inv_n = one(R) / convert(R, n)
	inv_nm1 = one(R) / convert(R, n - 1)
	for i in 1 : m
		@inbounds mu = s[i] * inv_n
		dst[i] = max(dst[i] - n * (mu * mu), zero(R)) * inv_nm1
	end
end

function _varimpl_middim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, s::Array{R}, x::ContiguousArray{T}, m::Int, n::Int, k::Int)
	_varimpl_lastdim!(dst, s, x, m, n)
	for l in 2 : k
		_varimpl_lastdim!(unsafe_view(dst, :, l), s, unsafe_view(x, :, :, l), m, n)
	end
end


function var!{R<:FloatingPoint,T<:Real}(dst::Array{R}, x::Array{T}, dim::Int)
	@check_nonempty("var")
	nd = ndims(x)
	if !(1 <= dim <= nd)
		error("var: invalid value for the dim argument.")
	end
	siz = size(x)

	if dim == 1
		_varimpl_firstdim!(dst, x, siz[1], _trail_length(siz, dim))
	elseif dim == nd
		prelen = _precede_length(siz, dim)
		_varimpl_lastdim!(dst, Array(R, prelen), x, prelen, siz[dim])
	else
		prelen = _precede_length(siz, dim)
		_varimpl_middim!(dst, Array(R, prelen), x, prelen, siz[dim], _trail_length(siz, dim))
	end
	dst
end

function var{T<:Real}(x::Array{T}, dim::Int)
	var!(Array(to_fptype(T), reduced_size(size(x), dim)), x, dim)
end

# std

std{T<:Real}(x::Array{T}) = sqrt(var(x))
std{T<:Real}(x::Array{T}, dim::Int) = sqrt!(var(x, dim))
std!{R<:FloatingPoint, T<:Real}(dst::Array{R}, x::Matrix{T}, dim::Int) = sqrt!(var!(dst, x, dim))

# entropy

entropy(x::Array) = - sum_xlogx(x)
entropy(x::Array, dims::DimSpec) = negate!(sum_xlogx(x, dims))
entropy!(dst::Array, x::Array, dims::DimSpec) = negate!(sum_xlogx!(dst, x, dims))


# logsumexp

function logsumexp{T<:Real}(x::Array{T})
	@check_nonempty("logsumexp")
	u = max(x)
	log(sum_fdiff(Exp(), x, u)) + u
end

function logsumexp!{R<:FloatingPoint, T<:Real}(dst::Array{R}, x::Vector{T}, dim::Int)
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

function _logsumexp_lastdim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, u::Array{T}, x::ContiguousArray{T}, m::Int, n::Int)
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

function _logsumexp_middim!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, u::Array{T}, x::ContiguousArray{T}, m::Int, n::Int, k::Int)
	for l in 1 : k
		_logsumexp_lastdim!(unsafe_view(dst, :, l), u, unsafe_view(x, :, :, l), m, n)
	end
end


function logsumexp!{R<:FloatingPoint,T<:Real}(dst::Array{R}, x::Array{T}, dim::Int)
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

function logsumexp{T<:Real}(x::Array{T}, dim::Int)
	logsumexp!(Array(to_fptype(T), reduced_size(size(x), dim)), x, dim)
end


# softmax

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

function _softmax_lastdim!{T<:FloatingPoint}(dst::ContiguousArray{T}, u::Array{T}, x::ContiguousArray{T}, m::Int, n::Int)
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

function _softmax_middim!{T<:FloatingPoint}(dst::ContiguousArray{T}, u::Array{T}, x::ContiguousArray{T}, m::Int, n::Int, k::Int)
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

