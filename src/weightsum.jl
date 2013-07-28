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
	fname_firstdim! = symbol(string(fname, "_firstdim!"))
	fname_lastdim! = symbol(string(fname, "_lastdim!"))
	fname_middim! = symbol(string(fname, "_middim!"))

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

		function ($fname_firstdim!)(dst::ContiguousArray, m::Int, n::Int, weights::ContiguousArray, $(plst...))
			idx = 0
			for j in 1 : n
				idx += 1
				@inbounds v = ($ker_idx) * weights[1]
				for i in 2 : m
					idx += 1
					@inbounds v += ($ker_idx) * weights[i]
				end
				dst[j] = v
			end
		end

		function ($fname_lastdim!)(dst::ContiguousArray, m::Int, n::Int, weights::ContiguousArray, $(plst...))
			for idx in 1 : m
				dst[idx] = ($ker_idx) * weights[1]
			end	
			idx = m

			for j in 2 : n
				@inbounds wj = weights[j]
				for i in 1 : m
					idx += 1
					@inbounds dst[i] += ($ker_idx) * wj
				end
			end
		end

		function ($fname_middim!)(dst::ContiguousArray, m::Int, n::Int, k::Int, weights::ContiguousArray, $(plst...))
			od = 0
			idx = 0
			for l in 1 : k
				for i in 1 : m
					idx += 1
					@inbounds dst[od + i] = ($ker_idx) * weights[1]
				end

				for j in 2 : n
					@inbounds wj = weights[j]
					for i in 1 : m
						odi = od + i
						idx += 1
						@inbounds dst[odi] += ($ker_idx) * wj
					end
				end

				od += m
			end
		end

		function ($fname!){W<:Number}(dst::ContiguousArray, weights::ContiguousArray{W}, $(plst...), dim::Int)
			siz = $shape
			nd = length(siz)
			@check_weightsize siz[dim] == length(weights) # this ensures 1 <= dim <= nd

			if nd == 1
				dst[1] = ($fname)(weights, $(alst...))
			else
				if dim == 1
					d1 = siz[1]
					d2 = succ_length(siz, 1)
					($fname_firstdim!)(dst, d1, d2, weights, $(alst...))
				elseif dim < nd
					d0 = prec_length(siz, dim)
					d1 = siz[dim]
					d2 = succ_length(siz, dim)
					($fname_middim!)(dst, d0, d1, d2, weights, $(alst...))
				elseif dim == nd
					d0 = prec_length(siz, dim)
					d1 = siz[dim]
					($fname_lastdim!)(dst, d0, d1, weights, $(alst...))
				end
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
@weighted_sumfuns wsum_fdiff DiffFunKernel


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

wasum(w::ContiguousArray, x::ContiguousArray) = wsum(w, Abs(), x)
wasum!(dst::ContiguousArray, w::ContiguousArray, x::ContiguousArray, dim::Int) = wsum!(dst, w, Abs(), x, dim) 
wasum(w::ContiguousArray, x::ContiguousArray, dim::Int) = wsum(w, Abs(), x, dim)

wadiffsum(w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber) = wsum_fdiff(w, Abs(), x, y)
wadiffsum!(dst::ContiguousArray, w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber, dim::Int) = wsum_fdiff!(dst, w, Abs(), x, y, dim) 
wadiffsum(w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber, dim::Int) = wsum_fdiff(w, Abs(), x, y, dim)

wsqsum(w::ContiguousArray, x::ContiguousArray) = wsum(w, Abs2(), x)
wsqsum!(dst::ContiguousArray, w::ContiguousArray, x::ContiguousArray, dim::Int) = wsum!(dst, w, Abs2(), x, dim) 
wsqsum(w::ContiguousArray, x::ContiguousArray, dim::Int) = wsum(w, Abs2(), x, dim)

wsqdiffsum(w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber) = wsum_fdiff(w, Abs2(), x, y)
wsqdiffsum!(dst::ContiguousArray, w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber, dim::Int) = wsum_fdiff!(dst, w, Abs2(), x, y, dim) 
wsqdiffsum(w::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber, dim::Int) = wsum_fdiff(w, Abs2(), x, y, dim)

