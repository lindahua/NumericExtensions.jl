# map-reduction

function _sum(ifirst::Int, ilast::Int, f::Functor, a1::NumericArray)
	s1 = evaluate(f, a1[ifirst])
	if ilast > ifirst
		@inbounds s2 = evaluate(f, a1[ifirst + 1])

		i = ifirst + 2
		while i < ilast
			@inbounds s1 += evaluate(f, a1[i])
			@inbounds s2 += evaluate(f, a1[i+1])
			i += 2
		end

		if i == ilast
			@inbounds s1 += evaluate(f, a1[i])
		end

		return s1 + s2
	else
		return s1
	end
end

sum(f::Functor, a1::NumericArray) = isempty(a1) ? 0.0 : _sum(1, length(a1), f, a1)

sumabs(a::NumericArray) = sum(AbsFun(), a)
sumsq(a::NumericArray) = sum(Abs2Fun(), a)
sumxlogx(a::NumericArray) = sum(XlogxFun(), a)

