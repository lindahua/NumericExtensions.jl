# map-reduction

#################################################
#
#   sum functions
#
#################################################

const PAIRWISE_SUM_BLOCKSIZE = 1024

macro code_mapsum(AN, sumf)
	
	_sumf = symbol("_$(sumf)")
	_seqsumf = symbol("_seq$(sumf)")
	_cassumf = symbol("_cas$(sumf)")

	h = codegen_helper(AN)
	ti1 = h.term(:i1)
	ti2 = h.term(:i2)

	quote
		global $(_seqsumf)
		function $(_seqsumf)(ifirst::Int, ilast::Int, $(h.aparams...))
			i1 = ifirst
			i2 = ifirst + 1

			s1 = $(ti1)
			if ilast > ifirst
				@inbounds s2 = $(ti2)

				i1 += 2
				i2 += 2
				while i1 < ilast
					@inbounds s1 += $(ti1)
					@inbounds s2 += $(ti2)
					i1 += 2
					i2 += 2
				end

				if i1 == ilast
					@inbounds s1 += $(ti1)
				end

				return s1 + s2
			else
				return s1
			end			
		end

		global $(_cassumf)
		function $(_cassumf)(ifirst::Int, ilast::Int, $(h.aparams...))
			if ifirst + PAIRWISE_SUM_BLOCKSIZE >= ilast
				$(_seqsumf)(ifirst, ilast, $(h.args...))
			else
				imid = ifirst + ((ilast - ifirst) >> 1)
				$(_cassumf)(ifirst, imid, $(h.args...)) + $(_cassumf)(imid+1, ilast, $(h.args...))
			end
		end

		global $(_sumf)
		$(_sumf)(ifirst::Int, ilast::Int, $(h.aparams...)) = $(_cassumf)(ifirst, ilast, $(h.args...))

		global $(sumf)
		$(sumf)($(h.aparams...)) = $(_cassumf)(1, $(h.inputlen), $(h.args...))
	end
end

@code_mapsum 1 sum
@code_mapsum 2 sum
@code_mapsum 3 sum
@code_mapsum (-2) sumfdiff


#################################################
#
#   mean functions
#
#################################################

macro code_mapmean(AN, sumf, meanf)
	h = codegen_helper(AN)
	_sumf = symbol("_$(sumf)")

	quote
		global $(meanf)
		function ($meanf)($(h.aparams...))
			n = $(h.inputlen)
			n == 0 ? NaN : ($_sumf)(1, n, $(h.args...)) / n
		end	
	end
end

@code_mapmean 1 sum mean
@code_mapmean 2 sum mean
@code_mapmean 3 sum mean
@code_mapmean (-2) sumfdiff meanfdiff


#################################################
#
#	max/min functions
#
#################################################

macro code_mapmaxmin(AN, mf, ismax)
	h = codegen_helper(AN)
	_mf = symbol("_$(mf)")
	nonneg_mf = symbol("nonneg_$(mf)")

	ti = h.term(:i)
	compexpr = ismax ? :(vi > s) : :(vi < s)

	quote
		global $(_mf)
		function ($_mf)(ifirst::Int, ilast::Int, $(h.aparams...))
			i = ifirst
			s = $(ti)

			while i < ilast
				i += 1
				@inbounds vi = $(ti)
				if $(compexpr) || (s != s)
					s = vi
				end
			end
			return s
		end

		global $(mf)
		function $(mf)($(h.aparams...))
			n = $(h.inputlen)
			n > 0 || error("Empty arguments not allowed.")
			$(_mf)(1, n, $(h.args...))
		end

		global $(nonneg_mf)
		function $(nonneg_mf)($(h.aparams...))
			n = $(h.inputlen)
			n > 0 ? $(_mf)(1, n, $(h.args...)) : 0.0
		end
	end
end

@code_mapmaxmin 1 maximum true
@code_mapmaxmin 2 maximum true
@code_mapmaxmin 3 maximum true
@code_mapmaxmin (-2) maxfdiff true

@code_mapmaxmin 1 minimum false
@code_mapmaxmin 2 minimum false
@code_mapmaxmin 3 minimum false
@code_mapmaxmin (-2) minfdiff false 



#################################################
#
#	folding functions
#
#################################################

macro code_mapfold(AN, foldlf, foldrf)
	# argument preparation

	_foldlf = symbol("_$(foldlf)")
	_foldrf = symbol("_$(foldrf)")

	h = codegen_helper(AN)
	ti = h.term(:i)
	t1 = h.term(1)
	tn = h.term(:n)

	# code skeletons

	quote
		# foldl & foldr

		global $_foldlf 
		function $(_foldlf)(ifirst::Int, ilast::Int, op::Functor{2}, s::Number, $(h.aparams...))
			i = ifirst
			while i <= ilast
				@inbounds vi = $(ti)
				s = evaluate(op, s, vi)
				i += 1
			end
			return s
		end

		global $foldlf
		$(foldlf)(op::Functor{2}, s::Number, $(h.aparams...)) = $(_foldlf)(1, $(h.inputlen), op, s, $(h.args...))
		function $(foldlf)(op::Functor{2}, $(h.aparams...)) 
			n = $(h.inputlen)
			n > 0 || error("Empty argument not allowed.")
			s = $(t1)
			$(_foldlf)(2, n, op, s, $(h.args...))
		end

		global $_foldrf
		function $(_foldrf)(ifirst::Int, ilast::Int, op::Functor{2}, s::Number, $(h.aparams...))
			i = ilast
			while i >= ifirst
				@inbounds vi = $(ti)
				s = evaluate(op, vi, s)
				i -= 1
			end
			return s
		end

		global $foldrf
		$(foldrf)(op::Functor{2}, s::Number, $(h.aparams...)) = $(_foldrf)(1, $(h.inputlen), op, s, $(h.args...))
		function $(foldrf)(op::Functor{2}, $(h.aparams...))
			n = $(h.inputlen)
			n > 0 || error("Empty argument not allowed.")
			s = $(tn)
			$(_foldrf)(1, n-1, op, s, $(h.args...))
		end

	end
end


@code_mapfold 1 foldl foldr
@code_mapfold 2 foldl foldr
@code_mapfold 3 foldl foldr
@code_mapfold (-2) foldl_fdiff foldr_fdiff


#################################################
#
#   derived functions
#
#################################################

sumabs(a::NumericArray) = sum(AbsFun(), a)
maxabs(a::NumericArray) = maximum(AbsFun(), a)
minabs(a::NumericArray) = minimum(AbsFun(), a)
meanabs(a::NumericArray) = mean(AbsFun(), a)

sumsq(a::NumericArray) = sum(Abs2Fun(), a)
meansq(a::NumericArray) = mean(Abs2Fun(), a)

dot{T<:Real}(a::NumericVector{T}, b::NumericVector{T}) = sum(Multiply(), a, b)
dot{T<:Real}(a::NumericArray{T}, b::NumericArray{T}) = sum(Multiply(), a, b)

sumabsdiff(a::ArrOrNum, b::ArrOrNum) = sumfdiff(AbsFun(), a, b)
maxabsdiff(a::ArrOrNum, b::ArrOrNum) = maxfdiff(AbsFun(), a, b)
minabsdiff(a::ArrOrNum, b::ArrOrNum) = minfdiff(AbsFun(), a, b)
meanabsdiff(a::ArrOrNum, b::ArrOrNum) = meanfdiff(AbsFun(), a, b)

sumsqdiff(a::ArrOrNum, b::ArrOrNum) = sumfdiff(Abs2Fun(), a, b)
maxsqdiff(a::ArrOrNum, b::ArrOrNum) = maxfdiff(Abs2Fun(), a, b)
minsqdiff(a::ArrOrNum, b::ArrOrNum) = minfdiff(Abs2Fun(), a, b)
meansqdiff(a::ArrOrNum, b::ArrOrNum) = meanfdiff(Abs2Fun(), a, b)

sumxlogx{T<:Real}(a::NumericArray{T}) = sum(XlogxFun(), a)
sumxlogy{T<:Real}(a::ArrOrNum{T}, b::ArrOrNum{T}) = sum(XlogyFun(), a, b)
entropy{T<:Real}(a::NumericArray{T}) = -sumxlogx(a)


#################################################
#
#   BLAS acceleration
#
#################################################

function _sum{T<:BlasFP}(ifirst::Int, ilast::Int, f::AbsFun, a::ContiguousArray{T})
	Base.BLAS.asum(ilast - ifirst + 1, pointer(a, ifirst), 1)
end

function _sum{T<:BlasFP}(ifirst::Int, ilast::Int, f::Abs2Fun, a::ContiguousArray{T})
	p = pointer(a, ifirst)
	Base.BLAS.dot(ilast - ifirst + 1, p, 1, p, 1)
end

function _sum{T<:BlasFP}(ifirst::Int, ilast::Int, f::Multiply, a::ContiguousArray{T}, b::ContiguousArray{T})
	Base.BLAS.dot(ilast - ifirst + 1, pointer(a, ifirst), 1, pointer(b, ifirst), 1)
end



