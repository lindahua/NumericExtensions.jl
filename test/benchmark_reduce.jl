# Benchmark on reduction

# macros

macro bench_reduc1(ptname, name, rp, f, a)
	quote
		println("    on $($name) ...")

		($f)($a)
		t0 = @elapsed for i in 1 : ($rp)
			($f)($a) 
		end

		($f)($a, 1)
		t1 = @elapsed for i in 1 : ($rp)
			($f)($a, 1) 
		end

		($f)($a, 2)
		t2 = @elapsed for i in 1 : ($rp)
			($f)($a, 2)
		end

		push!($ptname, ($name, [t0, t1, t2]))
	end
end


# data preparation

a2 = randn(1000, 1000)
b2 = rand(1000, 1000) + 0.5

a3 = randn(1000, 1000)
b3 = rand(1000, 1000) + 0.5


#################################################
#
#  Benchmark on old functions
#
#################################################

typealias DIMS Union(Int, (Int, Int))

_max(x::Array) = max(x)
_max(x::Array, d::DIMS) = max(x, (), d)

_min(x::Array) = min(x)
_min(x::Array, d::DIMS) = min(x, (), d)

_asum(x::Array) = sum(abs(x))
_asum(x::Array, d::DIMS) = sum(abs(x), d)

_amax(x::Array) = max(abs(x))
_amax(x::Array, d::DIMS) = max(abs(x), (), d)

_amin(x::Array) = min(abs(x))
_amin(x::Array, d::DIMS) = min(abs(x), (), d)

_sqsum(x::Array) = sum(abs2(x))
_sqsum(x::Array, d::DIMS) = sum(abs2(x), d)

# benchmark

const oldperf = Array((ASCIIString, Vector{Float64}), 0)

println("Benchmark results on Base methods:")

@bench_reduc1 oldperf "sum" 10 sum a2
@bench_reduc1 oldperf "max" 10 _max a2
@bench_reduc1 oldperf "min" 10 _min a2
@bench_reduc1 oldperf "asum" 10 _asum a2
@bench_reduc1 oldperf "amax" 10 _amax a2
@bench_reduc1 oldperf "amin" 10 _amin a2
@bench_reduc1 oldperf "sqsum" 10 _sqsum a2

#################################################
#
#  Benchmark on new functions
#
#################################################

using NumericFunctors
const newperf = Array((ASCIIString, Vector{Float64}), 0)

println("Benchmark results in New methods:")

@bench_reduc1 newperf "sum" 10 sum a2

println(oldperf)

println(newperf)

