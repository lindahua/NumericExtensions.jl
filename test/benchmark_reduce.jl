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
u = randn(1000)

#################################################
#
#  Benchmark on old functions
#
#################################################

typealias DIMS Union(Int, (Int, Int))

_sum(x::Array) = sum(x)
_sum(x::Array, d::DIMS) = sum(x, d)

_maximum(x::Array) = maximum(x)
_maximum(x::Array, d::DIMS) = maximum(x, d)

_minimum(x::Array) = minimum(x)
_minimum(x::Array, d::DIMS) = minimum(x, d)

_sumabs(x::Array) = sum(abs(x))
_sumabs(x::Array, d::DIMS) = sum(abs(x), d)

_maxabs(x::Array) = maximum(abs(x))
_maxabs(x::Array, d::DIMS) = maximum(abs(x), d)

_minabs(x::Array) = minimum(abs(x))
_minabs(x::Array, d::DIMS) = minimum(abs(x), d)

_sumsq(x::Array) = sum(abs2(x))
_sumsq(x::Array, d::DIMS) = sum(abs2(x), d)

_dot(x::Array, y::Array) = sum(x .* y)
_dot(x::Array, y::Array, d::DIMS) = sum(x .* y, d)

_sumabsdiff(x::Array, y::Array) = sum(abs(x - y))
_sumabsdiff(x::Array, y::Array, d::DIMS) = sum(abs(x - y), d)

_maxabsdiff(x::Array, y::Array) = maximum(abs(x - y))
_maxabsdiff(x::Array, y::Array, d::DIMS) = maximum(abs(x - y), d)

_minabsdiff(x::Array, y::Array) = minimum(abs(x - y))
_minabsdiff(x::Array, y::Array, d::DIMS) = minimum(abs(x - y), d)

_sumsqdiff(x::Array, y::Array) = sum(abs2(x - y))
_sumsqdiff(x::Array, y::Array, d::DIMS) = sum(abs2(x - y), d)

_entropy(x::Array) = -sum(x .* log(x))
_entropy(x::Array, d::DIMS) = -sum(x .* log(x), d)

_sumxlogy(x::Array, y::Array) = sum(x .* log(y)) 
_sumxlogy(x::Array, y::Array, d::DIMS) = sum(x .* log(y), d)

_var(x::Array) = var(x)
_var(x::Array, d::DIMS) = var(x, d)

_std(x::Array) = std(x)
_std(x::Array, d::DIMS) = std(x, d)

_logsumexp(x::Array) = (u = maximum(x); log(sum(exp(x - u))) + u)
_logsumexp(x::Array, d::DIMS) = (u = maximum(x, d); log(sum(exp(x .- u))) .+ u)

function _softmax(x::Array)
    u = maximum(x)
    r = exp(x - u)
    r / sum(r)
end

function _softmax(x::Array, d::Int)
    u = maximum(x, d)
    r = exp(x .- u)
    r ./ sum(r, d)
end

# benchmark

const oldperf = Array((ASCIIString, Vector{Float64}), 0)

println("Benchmark results on Base methods:")

@bench_reduc1 oldperf "sum" 10 _sum a2
@bench_reduc1 oldperf "maximum" 10 _maximum a2
@bench_reduc1 oldperf "minimum" 10 _minimum a2

@bench_reduc1 oldperf "sumabs" 10 _sumabs a2
@bench_reduc1 oldperf "maxabs" 10 _maxabs a2
@bench_reduc1 oldperf "minabs" 10 _minabs a2
@bench_reduc1 oldperf "sumsq" 10 _sumsq a2

@bench_reduc2 oldperf "dot" 10 _dot a2 b2
@bench_reduc2 oldperf "sumabsdiff" 10 _sumabsdiff a2 b2
@bench_reduc2 oldperf "maxabsdiff" 10 _maxabsdiff a2 b2
@bench_reduc2 oldperf "minabsdiff" 10 _minabsdiff a2 b2
@bench_reduc2 oldperf "sumsqdiff" 10 _sumsqdiff a2 b2

@bench_reduc1 oldperf "entropy" 10 _entropy b2
@bench_reduc2 oldperf "sumxlogy" 10 _sumxlogy b2 b2
# @bench_reduc1 oldperf "var" 10 _var a2
# @bench_reduc1 oldperf "std" 10 _std a2
# @bench_reduc1 oldperf "logsumexp" 10 _logsumexp a2
# @bench_reduc1 oldperf "softmax" 10 _softmax a2

# push!(oldperf, ("varm", [NaN, NaN, NaN]))

#################################################
#
#  Benchmark on new functions
#
#################################################

using NumericExtensions
const newperf = Array((ASCIIString, Vector{Float64}), 0)

println("Benchmark results in New methods:")

@bench_reduc1 newperf "sum" 10 sum a2
@bench_reduc1 newperf "maximum" 10 maximum a2
@bench_reduc1 newperf "minimum" 10 minimum a2

@bench_reduc1 newperf "sumabs" 10 sumabs a2
@bench_reduc1 newperf "maxabs" 10 maxabs a2
@bench_reduc1 newperf "minabs" 10 minabs a2
@bench_reduc1 newperf "sumsq" 10 sumsq a2

@bench_reduc2 newperf "dot" 10 dot a2 b2
@bench_reduc2 newperf "sumabsdiff" 10 sumabsdiff a2 b2
@bench_reduc2 newperf "maxabsdiff" 10 maxabsdiff a2 b2
@bench_reduc2 newperf "minabsdiff" 10 minabsdiff a2 b2
@bench_reduc2 newperf "sumsqdiff" 10 sumsqdiff a2 b2

@bench_reduc1 newperf "entropy" 10 entropy b2
@bench_reduc2 newperf "sumxlogy" 10 sumxlogy b2 b2
# @bench_reduc1 newperf "var" 10 var a2
# @bench_reduc1 newperf "std" 10 std a2
# @bench_reduc1 newperf "logsumexp" 10 logsumexp a2
# @bench_reduc1 newperf "softmax" 10 softmax a2

# println("    on varm ...")
# varm(a2, 1.0) 
# t0 = @elapsed for i = 1:10; varm(a2, 1.0); end
# varm(a2, u, 1)
# t1 = @elapsed for i = 1:10; varm(a2, u, 1); end
# varm(a2, u, 2)
# t2 = @elapsed for i = 1:10; varm(a2, u, 2); end
# push!(newperf, ("varm", [t0, t1, t2] * 1000.))


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


