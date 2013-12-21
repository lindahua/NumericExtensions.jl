# map-reduction

#################################################
#
#   sum functions
#
#################################################

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
			if ifirst + CASSUM_BLOCKLEN >= ilast
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


macro code_mapreducfuns(N)
	# argument preparation

	# function names

	_foldlf = :_foldl
	 foldlf = :foldl
	_foldrf = :_foldr
	 foldrf = :foldr

	_sumf = :_sum
	 sumf = :sum
	_maxf = :_maximum
	 maxf = :maximum
	_minf = :_minimum
	 minf = :minimum

	meanf  = :mean
	nnmaxf = :nonneg_maximum
	nnminf = :nonneg_minimum

	if N == -2
		_foldlf = :_foldl_fdiff
		 foldlf = :foldl_fdiff
		_foldrf = :_foldr_fdiff
		 foldrf = :foldr_fdiff

		_sumf = :_sumfdiff
		 sumf = :sumfdiff
		_maxf = :_maxfdiff
		 maxf = :maxfdiff
		_minf = :_minfdiff
		 minf = :minfdiff

		meanf  = :meanfdiff
		nnmaxf = :nonneg_maxfdiff
		nnminf = :nonneg_minfdiff
	end


	# code-gen preparation

	h = codegen_helper(N)
	t1 = h.term(1)
	ti = h.term(:i)
	ti1 = h.term(:i1)
	ti2 = h.term(:i2)

	# code skeletons

	quote
		# sum & mean

		global $meanf
		function ($meanf)($(h.aparams...))
			n = $(h.inputlen)
			n == 0 ? NaN : ($_sumf)(1, n, $(h.args...)) / n
		end

		# maximum & minimum

		global $_maxf
		function ($_maxf)(ifirst::Int, ilast::Int, $(h.aparams...))
			i = ifirst
			s = $(ti)

			while i < ilast
				i += 1
				@inbounds vi = $(ti)
				if vi > s || (s != s)
					s = vi
				end
			end
			return s
		end

		global $maxf
		function ($maxf)($(h.aparams...))
			n = $(h.inputlen)
			n > 0 || error("Empty arguments not allowed.")
			($_maxf)(1, n, $(h.args...))
		end

		global $nnmaxf
		function ($nnmaxf)($(h.aparams...))
			n = $(h.inputlen)
			n == 0 ? 0.0 : ($_maxf)(1, n, $(h.args...))
		end

		global $_minf
		function ($_minf)(ifirst::Int, ilast::Int, $(h.aparams...))
			i = ifirst
			s = $(ti)

			while i < ilast
				i += 1
				@inbounds vi = $(ti)
				if vi < s || (s != s)
					s = vi
				end
			end
			return s
		end

		global $minf
		function ($minf)($(h.aparams...))
			n = $(h.inputlen)
			n > 0 || error("Empty arguments not allowed.")
			($_minf)(1, n, $(h.args...))
		end

		global $nnminf
		function ($nnminf)($(h.aparams...))
			n = $(h.inputlen)
			n == 0 ? 0.0 : ($_minf)(1, n, $(h.args...))
		end


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
			i = n
			s = $(ti)
			$(_foldrf)(1, n-1, op, s, $(h.args...))
		end

	end
end


#################################################
#
#   generate specific functions
#
#################################################

@code_mapreducfuns 1
@code_mapreducfuns 2
@code_mapreducfuns 3
@code_mapreducfuns (-2)  # for *fdiff


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

dot(a::NumericVector, b::NumericVector) = sum(Multiply(), a, b)
dot(a::NumericArray, b::NumericArray) = sum(Multiply(), a, b)

sumabsdiff(a::ArrOrNum, b::ArrOrNum) = sumfdiff(AbsFun(), a, b)
maxabsdiff(a::ArrOrNum, b::ArrOrNum) = maxfdiff(AbsFun(), a, b)
minabsdiff(a::ArrOrNum, b::ArrOrNum) = minfdiff(AbsFun(), a, b)
meanabsdiff(a::ArrOrNum, b::ArrOrNum) = meanfdiff(AbsFun(), a, b)

sumsqdiff(a::ArrOrNum, b::ArrOrNum) = sumfdiff(Abs2Fun(), a, b)
maxsqdiff(a::ArrOrNum, b::ArrOrNum) = maxfdiff(Abs2Fun(), a, b)
minsqdiff(a::ArrOrNum, b::ArrOrNum) = minfdiff(Abs2Fun(), a, b)
meansqdiff(a::ArrOrNum, b::ArrOrNum) = meanfdiff(Abs2Fun(), a, b)

sumxlogx(a::NumericArray) = sum(XlogxFun(), a)
sumxlogy(a::ArrOrNum, b::ArrOrNum) = sum(XlogyFun(), a, b)
entropy(a::NumericArray) = -sumxlogx(a)


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



