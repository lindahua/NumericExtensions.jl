# Scanning

#################################################
#
# 	Scanning along a vector
#
#################################################

function code_vecscan_functions{KType<:EwiseKernel}(fname::Symbol, ktype::Type{KType})
	fname! = symbol(string(fname, '!'))
	plst = reduc_paramlist(ktype, :ContiguousVector)
	alst = reduc_arglist(ktype)
	ker_i = kernel(ktype, :i)
	len = length_inference(ktype)

	vtype = eltype_inference(ktype)
	len = length_inference(ktype)

	quote
		function ($fname!)(dst::ContiguousVector, $(plst...))
			n::Int = $len
			i = 1
			dst[1] = v = $ker_i
			for i in 2 : n
				dst[i] = v = evaluate(op, v, $ker_i)
			end
			dst
		end

		function ($fname)($(plst...))
			dst = Array($vtype, $len)
			($fname!)(dst, $(alst...))
		end
	end
end

macro vecscan_functions(fname, ktype)
	esc(code_vecscan_functions(fname, eval(ktype)))
end

@vecscan_functions scan DirectKernel
@vecscan_functions mapscan UnaryFunKernel
@vecscan_functions mapscan BinaryFunKernel
@vecscan_functions mapscan TernaryFunKernel

# inplace scan

scan!(op::BinaryFunctor, x::ContiguousVector) = scan!(x, op, x)


#################################################
#
# 	Scanning along a specific dimension
#
#################################################

function code_dimscan_functions{KType<:EwiseKernel}(fname::Symbol, ktype::Type{KType})
	fname_impl! = symbol(string(fname, "_impl!"))
	_fname! = symbol(string('_', fname, '!'))
	fname! = symbol(string(fname, '!'))

	plst = reduc_paramlist(ktype, :ContiguousArray)
	alst = reduc_arglist(ktype)
	ker_idx = kernel(ktype, :idx)
	len = length_inference(ktype)

	vtype = eltype_inference(ktype)
	shape = shape_inference(ktype)

	quote
		function ($fname_impl!)(dst::ContiguousArray, m::Int, n::Int, k::Int, $(plst...))
			if n == 1  # each page has a single column (simply evaluate)
				for idx = 1:m*k
					dst[idx] = $ker_idx
				end

			elseif m == 1  # each page has a single row
				idx = 0
				for l = 1:k
					idx += 1
					dst[idx] = s = $ker_idx
					for j = 2:n
						idx += 1
						dst[idx] = s = evaluate(op, s, $ker_idx)
					end					
				end

			elseif k == 1 # only one page
				for idx = 1:m
					dst[idx] = $ker_idx
				end
				idx = m
				for j = 2:n
					for i = 1:m
						idx += 1
						dst[idx] = evaluate(op, dst[idx-m], $ker_idx)
					end
				end

			else  # multiple generic pages
				idx = 0
				for l = 1:k					
					for i = 1:m
						idx += 1
						dst[idx] = $ker_idx
					end
					for j = 2:n
						for i = 1:m
							idx += 1
							dst[idx] = evaluate(op, dst[idx-m], $ker_idx)
						end
					end
				end
			end
		end

		function ($_fname!)(siz::NTuple, dst::ContiguousArray, $(plst...), dim::Int)
			if 1 <= dim <= length(siz)
				($fname_impl!)(dst, prec_length(siz, dim), siz[dim], succ_length(siz, dim), $(alst...))
			else
				throw(ArgumentError("The value of dim is invalid."))
			end
			dst			
		end

		function ($fname!)(dst::ContiguousArray, $(plst...), dim::Int)
			siz = $shape
			if length(dst) != prod(siz)
				throw(ArgumentError("Inconsistent argument dimensions."))
			end
			($_fname!)(siz, dst, $(alst...), dim)
		end

		function ($fname)($(plst...), dim::Int)
			siz = $shape
			($_fname!)(siz, Array($vtype, siz), $(alst...), dim)
		end
	end	
end

macro dimscan_functions(fname, ktype)
	esc(code_dimscan_functions(fname, eval(ktype)))
end

@dimscan_functions scan DirectKernel
@dimscan_functions mapscan UnaryFunKernel
@dimscan_functions mapscan BinaryFunKernel
@dimscan_functions mapscan TernaryFunKernel

# inplace scan

scan!(op::BinaryFunctor, x::ContiguousArray, dim::Int) = scan!(x, op, x, dim)


#################################################
#
# 	Specific scanning functions
#
#################################################

function code_cumfuns(fname::Symbol, op::Expr, ktype::Type{DirectKernel})
	fname! = symbol(string(fname, '!'))

	quote
		($fname!)(dst::ContiguousVector, x::ContiguousVector) = scan!(dst, $op, x)

		($fname!)(dst::ContiguousArray, x::ContiguousArray, dim::Int) = scan!(dst, $op, x, dim)

		($fname!)(x::ContiguousVector) = scan!($op, x)

		($fname!)(x::ContiguousArray, dim::Int) = scan!($op, x, dim)

		($fname)(x::ContiguousVector) = scan($op, x)

		($fname)(x::ContiguousArray, dim::Int) = scan($op, x, dim)
	end
end

function code_cumfuns{KType<:EwiseFunKernel}(fname::Symbol, op::Expr, ktype::Type{KType})
	fname! = symbol(string(fname, '!'))
	plst1 = paramlist(ktype, :ContiguousVector)
	plst = paramlist(ktype, :ContiguousArray)
	alst = arglist(ktype)

	quote
		function ($fname!)(dst::ContiguousVector, $(plst1...))
			mapscan!(dst, $(alst[1]), $op, $(alst[2:]...))
		end

		function ($fname!)(dst::ContiguousArray, $(plst...), dim::Int)
			mapscan!(dst, $(alst[1]), $op, $(alst[2:]...), dim)
		end

		function ($fname)($(plst...))
			mapscan($(alst[1]), $op, $(alst[2:]...))
		end

		function ($fname)($(plst...), dim::Int)
			mapscan($(alst[1]), $op, $(alst[2:]...), dim)
		end
	end
end

function code_cumfuns(fname::Symbol, op::Expr)
	fname! = symbol(string(fname, '!'))

	F0 = code_cumfuns(fname, op, DirectKernel)
	F1 = code_cumfuns(fname, op, UnaryFunKernel)
	F2 = code_cumfuns(fname, op, BinaryFunKernel)
	F3 = code_cumfuns(fname, op, TernaryFunKernel)

	Expr(:block, F0.args..., F1.args..., F2.args..., F3.args...)
end

macro cumfuns(fname, op)
	esc(code_cumfuns(fname, op))
end

@cumfuns cumsum Add()
@cumfuns cummax Max()
@cumfuns cummin Min()

