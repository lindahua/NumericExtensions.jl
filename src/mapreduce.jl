# map-reduction

macro code_sumfuns(N)
	aparams = generate_argparamlist(N)
	args = generate_arglist(N)
	ti1 = functor_evalexpr(:f, args, :i1)
	ti2 = functor_evalexpr(:f, args, :i2)

	quote
		global _sum
		function _sum(ifirst::Int, ilast::Int, f::Functor, $(aparams...))
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

		global sum
		function sum(f::Functor, $(aparams...))
			n = maplength($(args...))
			n == 0 ? 0.0 : _sum(1, n, f, $(args...))
		end
	end
end

@code_sumfuns 1
@code_sumfuns 2
@code_sumfuns 3

sumabs(a::NumericArray) = sum(AbsFun(), a)
sumsq(a::NumericArray) = sum(Abs2Fun(), a)
sumxlogx(a::NumericArray) = sum(XlogxFun(), a)
sumxlogy(a::NumericArray, b::NumericArray) = sum(XlogyFun(), a, b)
