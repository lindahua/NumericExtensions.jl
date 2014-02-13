# benchmark broadcasting

using NumericExtensions

macro bench_bsx(name, rp, a, b1, b2, f1, f2, dims)
    quote
        println("Benchmark on $($name) ...")

        ac = copy($a)
        b1c = copy($b1)
        b2c = copy($b2)

        broadcast!($f1, ac, ac, b1c)
        ($f2)(ac, b2c, $dims)

        t1 = @elapsed for i in 1 : ($rp)
            broadcast!($f1, ac, ac, b1c) 
        end

        t2 = @elapsed for i in 1 : ($rp)
            ($f2)(ac, b2c, $dims) 
        end

        add_row!(perftable, $name, [t1, t2, t1 / t2])
    end
end

# benchmarks

const perftable = BenchmarkTable("Comparison of broadcasting", ["broadcast", "vbroadcast", "gain"])

# matrices

a = rand(200, 200)
b = rand(200)
b1m = reshape(b, 200, 1)
b2m = reshape(b, 1, 200)

@bench_bsx "matrix-dim(1)" 5000 a b1m b (.+) badd! 1
@bench_bsx "matrix-dim(2)" 5000 a b2m b (.+) badd! 2

# cubes

a = rand(100, 100, 4)
b1 = rand(100)
b2 = rand(100)
b3 = rand(4)
b1m = reshape(b1, 100, 1, 1)
b2m = reshape(b2, 1, 100, 1)
b3m = reshape(b3, 1, 1, 4)

@bench_bsx "cube-dim(1)" 5000 a b1m b1 (.+) badd! 1
@bench_bsx "cube-dim(2)" 5000 a b2m b2 (.+) badd! 2
@bench_bsx "cube-dim(3)" 5000 a b3m b3 (.+) badd! 3

# b12 = rand(100, 100)
# b13 = rand(100, 4)
# b23 = rand(100, 4)
# b12m = reshape(b12, 100, 100, 1)
# b13m = reshape(b13, 100, 1, 4)
# b23m = reshape(b23, 1, 100, 4)

# @bench_bsx "cube-dim(1,2)" 5000 a b12m b12 (.+) badd! (1,2)
# @bench_bsx "cube-dim(1,3)" 5000 a b13m b13 (.+) badd! (1,3)
# @bench_bsx "cube-dim(2,3)" 5000 a b23m b23 (.+) badd! (2,3)

# print results

println()
println(perftable)

