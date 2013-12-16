# return types

using NumericExtensions
using Base.Test

## Auxiliary stuff

const inttypes = [Bool, Int8, Uint8, Int16, Uint16, Int32, Uint32, Int64, Uint64]
const fptypes = [Float32, Float64]
const realtypes = [inttypes, fptypes]

function actual_type(op::Symbol, xs::Number...)
	args = [[x] for x in xs]
	eltype(eval(Expr(:call, op, args...)))
end

macro test_rtype1(op, T1, R)
	quote
		f = tfun(:($op))
		rt = maptype(f, $T1)
		if !(rt == $R)
			error("maptype of TFun{:$op} on $($T1) ==> $rt ($($R) expected).")
		end
	end
end

macro test_rtype2(op, T1, T2, R)
	quote
		f = tfun(:($op))
		rt = maptype(f, $T1, $T2)
		if !(rt == $R)
			error("maptype of TFun{:$op} on ($($T1), $($T2)) ==> $rt ($($R) expected).")
		end
	end
end


## Main test cases

# comparison

# println("    on arithmetics ...")

# for op in [:+, :-, :*, :/, :\, :^, :%]
# 	ewise_op = symbol(".$op")
# 	for T1 in realtypes, T2 in realtypes
# 		R = actual_type(ewise_op, one(T1), one(T2))
# 		@test_rtype2 op T1 T2 R
# 	end
# end

# for op in [:div]
# 	for T1 in realtypes, T2 in realtypes
# 		R = actual_type(op, one(T1), one(T2))
# 		@test_rtype2 op T1 T2 R
# 	end
# end

# comparison

# println("    on comparison ...")

# for op in [:(==), :(!=), :<, :>, :<=, :>=]
# 	ewise_op = symbol(".$op")
# 	for T1 in realtypes, T2 in realtypes
# 		R = actual_type(ewise_op, one(T1), one(T2))
# 		@test_rtype2 op T1 T2 R
# 	end
# end

# for op in [:isnan, :isinf, :isfinite]
# 	for T in realtypes
# 		R = actual_type(op, one(T))
# 		@test_rtype1 op T R
# 	end
# end

# # logical operations

# println("    on logical operations ...")

# for op in [:&, :|, :$]
# 	for T1 in inttypes, T2 in inttypes
# 		R = actual_type(op, one(T1), one(T2))
# 		@test_rtype2 op T1 T2 R
# 	end
# end

# for op in [:~]
# 	for T in inttypes
# 		R = actual_type(op, one(T))
# 		@test_rtype1 op T R
# 	end
# end

# algebraic math

println("    on algebraic functions ...")

for op in [:abs, :abs2, :sign, :sqrt, :cbrt, :rcp, :rsqrt, :rcbrt,
	:floor, :ceil, :round, :trunc, :ifloor, :iceil, :iround, :itrunc]

	for T in realtypes
		R = actual_type(op, one(T))
		@test_rtype1 op T R
	end
end





