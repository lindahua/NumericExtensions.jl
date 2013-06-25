# Weighted sum and related reduction function

macro check_weightsize(cond)
	quote
		if !($(cond))
			throw(ArgumentError("The size of the array of weights is inconsistent with others."))
		end
	end
end


function code_weighted_sumfuns(fname::Symbol, coder_expr::Expr)
	coder = eval(coder_expr)

	paramlist = generate_paramlist(coder)
	arglist = generate_arglist(coder)

	kernel = generate_kernel(coder, :idx)
	ker_i = generate_kernel(coder, :i)

	len = length_inference(coder)
	shape = shape_inference(coder)
	vtype = eltype_inference(coder)

	fname! = symbol(string(fname, '!'))
	fname_firstdim! = symbol(string(fname, "_firstdim!"))
	fname_lastdim! = symbol(string(fname, "_lastdim!"))
	fname_middim! = symbol(string(fname, "_middim!"))

	quote
		function ($fname){W<:Number}(weights::ContiguousArray{W}, $(paramlist...))
			n::Int = $len
			@check_weightsize n == length(weights)

			if n == 0
				zero(T) * zero(W)
			else
				idx = 1
				s = ($(kernel)) * weights[1]
				for idx in 2 : n
					s += ($(kernel)) * weights[idx]
				end
				s
			end
		end

		function ($fname_firstdim!)(dst::ContiguousArray, d1::Int, d2::Int, weights::ContiguousArray, $(paramlist...))
			idx = 0
			for j in 1 : n
				idx += 1
				v = ($kernel) * weights[1]
				for i in 2 : m
					idx += 1
					v += ($kernel) * weights[i]
				end
				dst[j] = v
			end
		end

		function ($fname_lastdim!)(dst::ContiguousArray, m::Int, n::Int, weights::ContiguousArray, $(paramlist...))
			for i in 1 : m
				dst[i] = ($ker_i) * weights[1]
			end	
			idx = m

			for j in 2 : n
				wj = weights[j]
				for i in 1 : m
					idx += 1
					dst[i] += ($kernel) * wj
				end
			end
		end

		function ($fname_middim!)(dst::ContiguousArray, m::Int, n::Int, k::Int, weights::ContiguousArray, $(paramlist...))
			od = 0
			idx = 0
			for l in 1 : k
				for i in 1 : m
					idx += 1
					dst[od + i] = ($kernel) * weights[1]
				end

				for j in 2 : n
					wj = weights[j]
					for i in 1 : m
						odi = od + i
						idx += 1
						dst[odi] += ($kernel) * wj
					end
				end

				od += m
			end
		end

		function ($fname!){W<:Number}(dst::ContiguousArray, weights::ContiguousArray{W}, $(paramlist...), dim::Int)
			siz = $shape
			nd = length(siz)
			@check_weightsize siz[dim] == length(weights) # this ensures 1 <= dim <= nd

			if dim == 1
				d1 = rsiz[1]
				d2 = _trail_length(rsiz, 1)
				($fname_firstdim!)(dst, d1, d2, weights, $(arglist...))
			elseif dim < nd
				d0 = _precede_length(rsiz, dim)
				d1 = rsiz[dim]
				d2 = _trail_length(rsiz, dim)
				($fname_middim!)(dst, d0, d1, d2, weights, $(arglist...))
			elseif dim == nd
				d0 = _precede_length(rsiz, dim)
				d1 = rsiz[dim]
				($fname_lastdim!)(dst, d0, d1, weights, $(arglist...))
			end
		end

		function ($fname){W<:Number}(weights::ContiguousArray{W}, $(paramlist...), dim::Int)
			r = Array(promote_type($vtype, W), reduced_size($shape, dim))
			($fname!)(r, weights, $(arglist...), dim)
		end
	end
end

macro weighted_sumfuns(fname, coder)
	esc(code_weighted_sumfuns(fname, coder))
end


@weighted_sumfuns wsum TrivialCoder()
@weighted_sumfuns wsum UnaryCoder()
@weighted_sumfuns wsum BinaryCoder()
@weighted_sumfuns wsum TernaryCoder()
@weighted_sumfuns wsum_fdiff FDiffCoder()

