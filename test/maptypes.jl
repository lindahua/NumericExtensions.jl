# return types

using NumericExtensions
using Base.Test

## Auxiliary stuff

const inttypes = [Bool, Int8, Uint8, Int16, Uint16, Int32, Uint32, Int64, Uint64]
const fptypes = [Float32, Float64]
const realtypes = [inttypes, fptypes]
const _realtypes = [Int8, Int16, Int32, Int64, Float32, Float64]

function actual_type(op::Symbol, xs::Number...)
	args = [[x] for x in xs]
	eltype(eval(Expr(:call, op, args...)))
end

function test_rtype(op::Symbol, T1::Type)
	f = tfun(op)
	rt = maptype(f, T1)
	R = actual_type(op, one(T1))
	if !(rt == R)
		error("maptype of TFun{$op} on $(T1) ==> $rt ($R expected).")
	end
end

function test_rtype(op::Symbol, T1::Type, T2::Type; dot_ewise::Bool=false)
	f = tfun(op)
	rt = maptype(f, T1, T2)
	R = dot_ewise ? 
		actual_type(symbol(".$op"), one(T1), one(T2)) : 
		actual_type(op, one(T1), one(T2))
	if !(rt == R)
		error("maptype of TFun{$op} on ($T1, $T2) ==> $rt ($R expected).")
	end
end


## Main test cases

# arithmetics

println("    on arithmetics ...")

for op in [:+, :-, :*, :/, :\, :^, :%]
	for T1 in realtypes, T2 in realtypes
		test_rtype(op, T1, T2; dot_ewise=true)
	end
end

for op in [:div]
	for T1 in realtypes, T2 in realtypes
		test_rtype(op, T1, T2)
	end
end

# comparison

println("    on comparison ...")

for op in [:(==), :(!=), :<, :>, :<=, :>=]
	for T1 in realtypes, T2 in realtypes
		test_rtype(op, T1, T2; dot_ewise=true)
	end
end

for op in [:isnan, :isinf, :isfinite]
	for T in realtypes
		test_rtype(op, T)
	end
end

# logical operations

println("    on logical operations ...")

for op in [:&, :|, :$]
	for T1 in inttypes, T2 in inttypes
		test_rtype(op, T1, T2)
	end
end

for T in inttypes
	test_rtype(:~, T)
end


# algebraic math

println("    on algebraic functions ...")

for op in [:abs, :abs2, :sign, :sqrt, :cbrt, :rcp, :rsqrt, :rcbrt,
	:floor, :ceil, :round, :trunc, :ifloor, :iceil, :iround, :itrunc]

	for T in realtypes
		test_rtype(op, T)
	end
end

# for op in [:hypot]
# 	for T1 in _realtypes, T2 in _realtypes
# 		test_rtype(op, T1, T2)
# 	end
# end

# transcendental functions

println("    on transcendental functions ...")

for op in [
	:exp, :exp2, :exp10, :expm1, :log, :log2, :log10, :log1p, 
	:sin, :cos, :tan, :cot, :sec, :csc,
	:sinh, :cosh, :tanh, :coth, :sech, :csch,
	:asin, :acos, :atan, # :acot, :asec, :acsc,
	:asinh, :acosh, :atanh] # :acoth, :asech, :acsch,  

	for T in _realtypes
		test_rtype(op, T)
	end
end

for op in [:atan2]
	for T1 in _realtypes, T2 in _realtypes
		test_rtype(op, T1, T2)
	end
end

# special functions

println("    on special functions ...")

for op in [:erf, :erfc, :erfinv, :erfcinv, :gamma, :lgamma] # :digamma
	for T in _realtypes
		test_rtype(op, T)
	end
end

# for op in [:beta, :lbeta]
# 	for T1 in _realtypes, T2 in _realtypes
# 		test_rtype(op, T1, T2)
# 	end
# end

