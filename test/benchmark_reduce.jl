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

		push!($ptname, ($name, [t0, t1, t2] * 1000.))
	end
end

macro bench_reduc2(ptname, name, rp, f, a, b)
	quote
		println("    on $($name) ...")

		($f)($a, $b)
		t0 = @elapsed for i in 1 : ($rp)
			($f)($a, $b) 
		end

		($f)($a, $b, 1)
		t1 = @elapsed for i in 1 : ($rp)
			($f)($a, $b, 1) 
		end

		($f)($a, $b, 2)
		t2 = @elapsed for i in 1 : ($rp)
			($f)($a, $b, 2)
		end

		push!($ptname, ($name, [t0, t1, t2] * 1000.))
	end
end


# data preparation

a2 = randn(1000, 1000)
b2 = rand(1000, 1000) + 0.5


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

_dot(x::Array, y::Array) = sum(x .* y)
_dot(x::Array, y::Array, d::DIMS) = sum(x .* y, d)

_adiffsum(x::Array, y::Array) = sum(abs(x - y))
_adiffsum(x::Array, y::Array, d::DIMS) = sum(abs(x - y), d)

_adiffmax(x::Array, y::Array) = max(abs(x - y))
_adiffmax(x::Array, y::Array, d::DIMS) = max(abs(x - y), (), d)

_adiffmin(x::Array, y::Array) = min(abs(x - y))
_adiffmin(x::Array, y::Array, d::DIMS) = min(abs(x - y), (), d)

_sqdiffsum(x::Array, y::Array) = sum(abs2(x - y))
_sqdiffsum(x::Array, y::Array, d::DIMS) = sum(abs2(x - y), d)

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

@bench_reduc2 oldperf "dot" 10 _dot a2 b2
@bench_reduc2 oldperf "adiffsum" 10 _adiffsum a2 b2
@bench_reduc2 oldperf "adiffmax" 10 _adiffmax a2 b2
@bench_reduc2 oldperf "adiffmin" 10 _adiffmin a2 b2
@bench_reduc2 oldperf "sqdiffsum" 10 _sqdiffsum a2 b2

#################################################
#
#  Benchmark on new functions
#
#################################################

using NumericFunctors
const newperf = Array((ASCIIString, Vector{Float64}), 0)

new_max(x::Array) = max(x)   # cannot use _max or _min, as they will not be recompiled
new_max(x::Array, d::DIMS) = max(x, (), d)

new_min(x::Array) = min(x)
new_min(x::Array, d::DIMS) = min(x, (), d)

println("Benchmark results in New methods:")

@bench_reduc1 newperf "sum" 10 sum a2
@bench_reduc1 newperf "max" 10 new_max a2
@bench_reduc1 newperf "min" 10 new_min a2
@bench_reduc1 newperf "asum" 10 asum a2
@bench_reduc1 newperf "amax" 10 amax a2
@bench_reduc1 newperf "amin" 10 amin a2
@bench_reduc1 newperf "sqsum" 10 sqsum a2

@bench_reduc2 newperf "dot" 10 dot a2 b2
@bench_reduc2 newperf "adiffsum" 10 adiffsum a2 b2
@bench_reduc2 newperf "adiffmax" 10 adiffmax a2 b2
@bench_reduc2 newperf "adiffmin" 10 adiffmin a2 b2
@bench_reduc2 newperf "sqdiffsum" 10 sqdiffsum a2 b2


#################################################
#
#  Organize and print results
#
#################################################

function organize_results(name, raw)
	tab = BenchmarkTable(name, ["full-reduction", "colwise-reduction", "rowwise-reduction"])
	for e in raw
		rname = e[1]
		row = e[2]
		add_row!(tab, rname, row)
	end
	tab
end

function compute_gains(name, tab0::BenchmarkTable, tab1::BenchmarkTable)
	# compare colnames and rownames
	@assert tab0.colnames == tab1.colnames
	@assert tab0.rownames == tab1.rownames

	gtab = BenchmarkTable(name, tab0.colnames)
	m = nrows(tab0)
	for i in 1 : m
		add_row!(gtab, tab0.rownames[i], tab0.rows[i] ./ tab1.rows[i])
	end
	gtab
end



oldtable = organize_results("Matrix reduction using Base methods (millisec)", oldperf)
newtable = organize_results("Matrix reduction using New methods (millisec)", newperf)

gaintable = compute_gains("Speed gain of New vs. Base", oldtable, newtable)

println("\nResults:")
println("***********************\n")

println(oldtable)
println()

println(newtable)
println()

println(gaintable)
println()


