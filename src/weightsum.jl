# Weighted sum and related reduction function

macro check_weightsize(cond)
	quote
		if !($(cond))
			throw(ArgumentError("The size of the array of weights is inconsistent with others."))
		end
	end
end


function code_weighted_sumfuns{KType<:EwiseKernel}(fname::Symbol, ktype::Type{KType})
	plst = paramlist(ktype, :ContiguousArray)
	alst = arglist(ktype)

	ker_idx = kernel(ktype, :idx)

	len = length_inference(ktype)
	shape = shape_inference(ktype)
	vtype = eltype_inference(ktype)

	fname! = symbol(string(fname, '!'))
	fname_impl! = symbol(string(fname, "_impl!"))

	quote
		function ($fname){W<:Number}(weights::ContiguousArray{W}, $(plst...))
			n::Int = $len
			@check_weightsize n == length(weights)

			if n == 0
				zero(T) * zero(W)
			else
				idx = 1
				@inbounds s = ($ker_idx) * weights[1]
				for idx in 2 : n
					@inbounds s += ($ker_idx) * weights[idx]
				end
				s
			end
		end

		function ($fname_impl!)(dst::ContiguousArray, m::Int, n::Int, k::Int, w::ContiguousArray, $(plst...))
			@check_weightsize length(w) == n

			if n == 1  # each page has a single row (simply evaluate)
				@inbounds w1 = w[1]
				for idx = 1:m*k
					@inbounds dst[idx] = w1 * $ker_idx
				end

			elseif m == 1  # each page has a single column
				idx = 0
				for l = 1:k
					idx += 1
					@inbounds s = w[1] * ($ker_idx)
					for j = 2:n
						idx += 1
						@inbounds s += w[j] * ($ker_idx)						
					end
					@inbounds dst[l] = s
				end

			elseif k == 1 # only one page
				@inbounds w1 = w[1]
				for idx = 1:m
					@inbounds dst[idx] = w1 * $ker_idx
				end
				idx = m
				for j = 2:n
					@inbounds wj = w[j]
					for i = 1:m
						idx += 1
						@inbounds dst[i] += wj * ($ker_idx)
					end
				end

			else  # multiple generic pages
				idx = 0
				od = 0
				@inbounds w1 = w[1]
				for l = 1:k					
					for i = 1:m
						idx += 1
						@inbounds dst[od+i] = w1 * $ker_idx
					end
					for j = 2:n
						@inbounds wj = w[j]
						for i = 1:m
							idx += 1
							odi = od + i
							@inbounds dst[odi] += wj * ($ker_idx)
						end
					end
					od += m
				end
			end
		end

		function ($fname!){W<:Number}(dst::ContiguousArray, weights::ContiguousArray{W}, $(plst...), dim::Int)
			siz = $shape
			if 1 <= dim <= length(siz)
				($fname_impl!)(dst, prec_length(siz, dim), siz[dim], succ_length(siz, dim), weights, $(alst...))
			else
				throw(ArgumentError("The value of dim is invalid."))
			end			
			dst
		end

		function ($fname){W<:Number}(weights::ContiguousArray{W}, $(plst...), dim::Int)
			r = Array(promote_type($vtype, W), reduced_size($shape, dim))
			($fname!)(r, weights, $(alst...), dim)
		end
	end
end

macro weighted_sumfuns(fname, ktype)
	esc(code_weighted_sumfuns(fname, eval(ktype)))
end


@weighted_sumfuns wsum DirectKernel
@weighted_sumfuns wsum UnaryFunKernel
@weighted_sumfuns wsum BinaryFunKernel
@weighted_sumfuns wsum TernaryFunKernel
@weighted_sumfuns wsumfdiff DiffFunKernel


# Specialized cases

wsum{T<:BlasFP}(w::Array{T}, x::Array{T}) = blas_dot(w, x)

function wsum!{T<:BlasFP}(dst::Array{T}, w::Array{T}, x::Vector{T}, dim::Int)
	dst[1] = wsum(x, w)
	dst
end

function wsum!{T<:BlasFP}(dst::Array{T}, w::Array{T}, x::Matrix{T}, dim::Int)
	if dim == 1
		gemv!('T', one(T), x, vec(w), zero(T), vec(dst))
	elseif dim == 2
		gemv!('N', one(T), x, vec(w), zero(T), vec(dst))
	else
		error("dim must be either 1 or 2.")
	end
	dst
end

function wsum!{T<:BlasFP}(dst::Array{T}, w::Array{T}, x::Array{T}, dim::Int)
	siz = size(x)
	nd = length(siz)
	rd = siz[dim]  # this ensures 1 <= dim <= nd

	if dim == 1
		rx = reshape(x, siz[1], succ_length(siz, 1))
		gemv!('T', one(T), rx, vec(w), zero(T), vec(dst))
	elseif dim == nd
		rx = reshape(x, prec_length(siz, nd), siz[nd])
		gemv!('N', one(T), rx, vec(w), zero(T), vec(dst))
	else
		m::Int = prec_length(siz, dim)
		n::Int = siz[dim]
		k::Int = succ_length(siz, dim)
		plen = m * n

		vw = vec(w)
		for l in 1 : k
			sx = pointer_to_array(pointer(x, plen * (l - 1) + 1), (m, n))
			sdst = pointer_to_array(pointer(dst, m * (l - 1) + 1), m)
			gemv!('N', one(T), sx, vw, zero(T), sdst) 
		end
	end
	dst
end


# Convenience functions

wsumabs(w::ContiguousArray, x::ContiguousArray) = wsum(w, Abs(), x)
wsumabs!(dst::ContiguousArray, w::ContiguousArray, x::ContiguousArray, dim::Int) = wsum!(dst, w, Abs(), x, dim) 
wsumabs(w::ContiguousArray, x::ContiguousArray, dim::Int) = wsum(w, Abs(), x, dim)

wsumabsdiff(w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber) = wsumfdiff(w, Abs(), x, y)
wsumabsdiff!(dst::ContiguousArray, w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber, dim::Int) = wsumfdiff!(dst, w, Abs(), x, y, dim) 
wsumabsdiff(w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber, dim::Int) = wsumfdiff(w, Abs(), x, y, dim)

wsumsq(w::ContiguousArray, x::ContiguousArray) = wsum(w, Abs2(), x)
wsumsq!(dst::ContiguousArray, w::ContiguousArray, x::ContiguousArray, dim::Int) = wsum!(dst, w, Abs2(), x, dim) 
wsumsq(w::ContiguousArray, x::ContiguousArray, dim::Int) = wsum(w, Abs2(), x, dim)

wsumsqdiff(w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber) = wsumfdiff(w, Abs2(), x, y)
wsumsqdiff!(dst::ContiguousArray, w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber, dim::Int) = wsumfdiff!(dst, w, Abs2(), x, y, dim) 
wsumsqdiff(w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber, dim::Int) = wsumfdiff(w, Abs2(), x, y, dim)

