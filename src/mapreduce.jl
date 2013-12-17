# map-reduction

macro code_sumfuns(fname, N)
	_fname = symbol("_$fname")

	(aparams, args, udiff) = prepare_arguments(N)
	ti1 = functor_evalexpr(:f, args, :i1; usediff=udiff)
	ti2 = functor_evalexpr(:f, args, :i2; usediff=udiff)

	quote
		global $_fname
		function ($_fname)(ifirst::Int, ilast::Int, f::Functor, $(aparams...))
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

		global $fname
		function ($fname)(f::Functor, $(aparams...))
			n = maplength($(args...))
			n == 0 ? 0.0 : ($_fname)(1, n, f, $(args...))
		end
	end
end

@code_sumfuns sum 1
@code_sumfuns sum 2
@code_sumfuns sum 3
@code_sumfuns sumdiff (-2)

sumabs(a::NumericArray) = sum(AbsFun(), a)
sumsq(a::NumericArray) = sum(Abs2Fun(), a)
sumxlogx(a::NumericArray) = sum(XlogxFun(), a)
sumxlogy(a::ArrOrNum, b::ArrOrNum) = sum(XlogyFun(), a, b)

sumabsdiff(a::ArrOrNum, b::ArrOrNum) = sumdiff(AbsFun(), a, b)
sumsqdiff(a::ArrOrNum, b::ArrOrNum) = sumdiff(Abs2Fun(), a, b)
