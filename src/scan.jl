# Scanning

#################################################
#
# 	Scanning along a vector
#
#################################################

macro code_scan(AN)

	h = codegen_helper(AN)
	t1 = h.term(1)
	ti = h.term(:i)

	quote
		# generic scanning functions

		global _scan!
		function _scan!(s, r::AbstractArray, op::Functor{2}, $(h.aparams...))
			i = 1
			@inbounds r[1] = s

			for i = 2 : length(r)
				@inbounds vi = $(ti)
				s = evaluate(op, s, vi)
				@inbounds r[i] = s
			end
		end

		global scan!
		function scan!(r::AbstractArray, op::Functor{2}, $(h.aparams...))
			n = $(h.inputlen)
			if n > 0
				@inbounds s = $(t1)
				_scan!(s, r, op, $(h.args...))
			end
			return r
		end

		global scan
		function scan(op::Functor{2}, $(h.aparams...))
			shp = $(h.inputsize)
			n = prod(shp)
			if n > 0
				@inbounds s = $(t1)
				r = Array(typeof(s), shp)
				_scan!(s, r, op, $(h.args...))
				return r
			else
				Any[]
			end
		end

		# specific scanning functions
		global cumsum!, cummax!, cummin!
		cumsum!(r::AbstractArray, $(h.aparams...)) = scan!(r, Add(), $(h.args...))
		cummax!(r::AbstractArray, $(h.aparams...)) = scan!(r, MaxFun(), $(h.args...))
		cummin!(r::AbstractArray, $(h.aparams...)) = scan!(r, MinFun(), $(h.args...))

		global cumsum, cummax, cummin
		cumsum($(h.aparams...)) = scan(Add(), $(h.args...))
		cummax($(h.aparams...)) = scan(MaxFun(), $(h.args...))
		cummin($(h.aparams...)) = scan(MinFun(), $(h.args...))
	end
end

@code_scan 0
@code_scan 1
@code_scan 2
@code_scan 3
@code_scan (-2)

# inplace scanning

scan!(op::Functor{2}, r::ContiguousArray) = scan!(r, op, r)

cumsum!(r::ContiguousArray) = scan!(Add(), r)
cummax!(r::ContiguousArray) = scan!(MaxFun(), r)
cummin!(r::ContiguousArray) = scan!(MinFun(), r)

