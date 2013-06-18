# Benchmark on vreduce

using NumericFunctors

macro bench_vreduce1(name, rp, a, f1, f2)
	quote
		println("Benchmark on $($name):")

		($f1)($a)
		($f2)($a)

		t1 = @elapsed for i in 1 : ($rp)
			($f1)($a) 
		end

		t2 = @elapsed for i in 1 : ($rp)
			($f2)($a) 
		end

		@printf("\tJulia:    %7.4f sec\n", t1)
		@printf("\tvreduce:  %7.4f sec | gain = %6.3f\n", t2, t1 / t2)
		println()
	end
end

macro bench_vreduce2(name, rp, a, b, f1, f2)
	quote
		println("Benchmark on $($name):")

		($f1)($a, $b)
		($f2)($a, $b)

		t1 = @elapsed for i in 1 : ($rp)
			($f1)($a, $b) 
		end

		t2 = @elapsed for i in 1 : ($rp)
			($f2)($a, $b) 
		end

		@printf("\tJulia:    %7.4f sec\n", t1)
		@printf("\tvreduce:  %7.4f sec | gain = %6.3f\n", t2, t1 / t2)
		println()
	end
end

# data

a = rand(1000, 1000)
b = rand(1000, 1000)

# benchmark

@bench_vreduce1("sum", 10, a, sum, vsum)
@bench_vreduce1("max", 10, a, max, vmax)
@bench_vreduce1("min", 10, a, min, vmin)

asum(a) = sum(abs(a))
amax(a) = max(abs(a))
amin(a) = min(abs(a))
sqsum(a) = sum(abs2(a))

cubesum(a) = sum(abs(a).^3.)
vcubesum(a) = vsum(FixAbsPow(3.), a)

@bench_vreduce1("asum", 10, a, asum, vasum)
@bench_vreduce1("amax", 10, a, amax, vamax)
@bench_vreduce1("amin", 10, a, amin, vamin)
@bench_vreduce1("sqsum", 10, a, sqsum, vsqsum)
@bench_vreduce1("cubesum", 10, a, cubesum, vcubesum)

my_dot(a, b) = sum(a .* b)
diff_asum(a, b) = sum(abs(a - b))
diff_amax(a, b) = max(abs(a - b))
diff_amin(a, b) = min(abs(a - b))
diff_sqsum(a, b) = sum(abs2(a - b))
diff_cubesum(a, b) = sum(abs(a - b).^3.)

@bench_vreduce2("dot", 10, a, b, my_dot, vdot)
@bench_vreduce2("diff_asum", 10, a, b, diff_asum, vadiffsum)
@bench_vreduce2("diff_amax", 10, a, b, diff_amax, vadiffmax)
@bench_vreduce2("diff_amin", 10, a, b, diff_amin, vadiffmin)
@bench_vreduce2("diff_sqsum", 10, a, b, diff_sqsum, vsqdiffsum)

