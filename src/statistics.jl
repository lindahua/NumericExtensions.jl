# Reduction functions related to statistics

# auxiliary



###################
#
#  Mean
#
###################

mean{T<:Real}(x::ContiguousArray{T}) = sum(x) / length(x)
mean(f::UnaryFunctor, x::ContiguousArray) = sum(f, x) / length(x)
mean(f::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber) = sum(f, x1, x2) / prod(map_shape(x1, x2))
meanfdiff(f::UnaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber) = sumfdiff(f, x1, x2) / prod(map_shape(x1, x2))


function mean(f::TernaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, x3::ArrayOrNumber)
	sum(f, x1, x2, x3) / prod(map_shape(x1, x2, x3))
end

function mean{T<:Real}(x::ContiguousArray{T}, dims::DimSpec)
	r = to_fparray(sum(x, dims))
	c = convert(eltype(r), inv(_reduc_dim_length(x, dims)))
	multiply!(r, c)
end

function mean(f::UnaryFunctor, x::ContiguousArray, dims::DimSpec)
	r = to_fparray(sum(f, x, dims))
	c = convert(eltype(r), inv(_reduc_dim_length(x, dims)))
	multiply!(r, c)
end

function mean(f::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, dims::DimSpec)
	r = to_fparray(sum(f, x1, x2, dims))
	c = convert(eltype(r), inv(_reduc_dim_length(map_shape(x1, x2), dims)))
	multiply!(r, c)
end

function mean(f::TernaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, x3::ArrayOrNumber, dims::DimSpec)
	r = to_fparray(sum(f, x1, x2, x3, dims))
	c = convert(eltype(r), inv(_reduc_dim_length(map_shape(x1, x2, x3), dims)))
	multiply!(r, c)
end

function meanfdiff(f::UnaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, dims::DimSpec)
	r = to_fparray(sumfdiff(f, x1, x2, dims))
	c = convert(eltype(r), inv(_reduc_dim_length(map_shape(x1, x2), dims)))
	multiply!(r, c)
end


function mean!{R<:Real,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dims::DimSpec)
	c = convert(R, inv(_reduc_dim_length(x, dims)))
	multiply!(sum!(dst, x, dims), c)
end

function mean!{R<:Real}(dst::ContiguousArray{R}, f::UnaryFunctor, x::ContiguousArray, dims::DimSpec)
	c = convert(R, inv(_reduc_dim_length(x, dims)))
	multiply!(sum!(dst, f, x, dims), c)
end

function mean!{R<:Real}(dst::ContiguousArray{R}, f::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, dims::DimSpec)
	c = convert(R, inv(_reduc_dim_length(map_shape(x1, x2), dims)))
	multiply!(sum!(dst, f, x1, x2, dims), c)
end

function mean!{R<:Real}(dst::ContiguousArray{R}, f::TernaryFunctor, 
	x1::ArrayOrNumber, x2::ArrayOrNumber, x3::ArrayOrNumber, dims::DimSpec)

	c = convert(R, inv(_reduc_dim_length(map_shape(x1, x2, x3), dims)))
	multiply!(sum!(dst, f, x1, x2, x3, dims), c)
end

function meanfdiff!{R<:Real}(dst::ContiguousArray{R}, f::UnaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, dims::DimSpec)
	c = convert(R, inv(_reduc_dim_length(map_shape(x1, x2), dims)))
	multiply!(sumfdiff!(dst, f, x1, x2, dims), c)
end


# specific functions

meanabs{T<:Real}(x::ContiguousArray{T}) = sumabs(x) / length(x)
meanabs{T<:Real}(x::ContiguousArray{T}, dims::DimSpec) = mean(AbsFun(), x, dims)
meanabs!{R<:Real,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dims::DimSpec) = mean!(dst, AbsFun(), x, dims)

meansq{T<:Real}(x::ContiguousArray{T}) = sumsq(x) / length(x)
meansq{T<:Real}(x::ContiguousArray{T}, dims::DimSpec) = mean(Abs2Fun(), x, dims)
meansq!{R<:Real,T<:Real}(dst::ContiguousArray{R}, x::ContiguousArray{T}, dims::DimSpec) = mean!(dst, Abs2Fun(), x, dims)

meanabsdiff(x::ArrayOrNumber, y::ArrayOrNumber) = meanfdiff(AbsFun(), x, y)
meanabsdiff(x::ArrayOrNumber, y::ArrayOrNumber, dims::DimSpec) = meanfdiff(AbsFun(), x, y, dims)
meanabsdiff!(dst::ContiguousArray, x::ArrayOrNumber, y::ArrayOrNumber, dims::DimSpec) = meanfdiff!(dst, AbsFun(), x, y, dims)

meansqdiff(x::ArrayOrNumber, y::ArrayOrNumber) = meanfdiff(Abs2Fun(), x, y)
meansqdiff(x::ArrayOrNumber, y::ArrayOrNumber, dims::DimSpec) = meanfdiff(Abs2Fun(), x, y, dims)
meansqdiff!(dst::ContiguousArray, x::ArrayOrNumber, y::ArrayOrNumber, dims::DimSpec) = meanfdiff!(dst, Abs2Fun(), x, y, dims)


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

function varm!{R<:FloatingPoint,T<:Real}(dst::ContiguousArray{R}, x::ContiguousVector{T}, mu::Real, dim::Int)
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
		n = succ_length(siz, dim)
		_varm_colwise!(dst, x, mu, m, n)

	elseif dim == nd
		m = prec_length(siz, dim)
		n = siz[dim]
		_varm_rowwise!(dst, x, mu, m, n)

	else  # 1 < dim < nd
		m = prec_length(siz, dim)
		n = siz[dim]
		k = succ_length(siz, dim)
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

var{T<:Real}(x::ContiguousArray{T}) = varm(x, mean(x))

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
		m = siz[1]
		n = succ_length(siz, 1)
		for j in 1 : n
			dst[j] = var(unsafe_view(x, :, j))
		end		
	else
		varm!(dst, x, mean(x, dim), dim)
	end
	dst
end

function var{T<:Real}(x::ContiguousArray{T}, dim::Int)
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

entropy{T<:Real}(x::ContiguousArray{T}) = - sumxlogx(x)
entropy{T<:Real}(x::ContiguousArray{T}, dims::DimSpec) = negate!(sumxlogx(x, dims))
entropy!{T<:Real}(dst::ContiguousArray{T}, x::ContiguousArray{T}, dims::DimSpec) = negate!(sumxlogx!(dst, x, dims))


###################
#
#  LogFunsumexp
#
###################

function logsumexp{T<:Real}(x::ContiguousArray{T})
	@check_nonempty("logsumexp")
	u = max(x)
	log(sumfdiff(ExpFun(), x, u)) + u
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
	for i in 1 : m
		@inbounds u[i] = x[i]
	end
	o = m
	for j in 2 : n
		for i in 1 : m
			@inbounds u[i] = max(u[i], x[o + i])
		end
		o += m
	end

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
		_logsumexp_firstdim!(dst, x, siz[1], succ_length(siz, dim))
	elseif dim == nd
		prelen = prec_length(siz, dim)
		_logsumexp_lastdim!(dst, Array(T, prelen), x, prelen, siz[dim])
	else
		prelen = prec_length(siz, dim)
		_logsumexp_middim!(dst, Array(T, prelen), x, prelen, siz[dim], succ_length(siz, dim))
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
	for i in 1 : m
		@inbounds u[i] = x[i]
	end
	o = m
	for j in 2 : n
		for i in 1 : m
			@inbounds u[i] = max(u[i], x[o + i])
		end
		o += m
	end

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
		_softmax_firstdim!(dst, x, siz[1], succ_length(siz, dim))
	elseif dim == nd
		prelen = prec_length(siz, dim)
		_softmax_lastdim!(dst, Array(T, prelen * 2), x, prelen, siz[dim])
	else
		prelen = prec_length(siz, dim)
		_softmax_middim!(dst, Array(T, prelen * 2), x, prelen, siz[dim], succ_length(siz, dim))
	end
	dst	
end

function softmax{T<:FloatingPoint}(x::ContiguousArray{T}, dim::Int)
	softmax!(Array(T, size(x)), x, dim)
end

