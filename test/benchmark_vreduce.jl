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

println("Full reduction")
println("=======================================")

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


println("Colwise reduction")
println("=======================================")

colwise_sum(a) = sum(a, 1)
colwise_vsum(a) = vsum(a, 1)
@bench_vreduce1("colwise-sum", 10, a, colwise_sum, colwise_vsum)

colwise_asum(a) = sum(abs(a), 1)
colwise_vasum(a) = vasum(a, 1)
@bench_vreduce1("colwise-asum", 10, a, colwise_asum, colwise_vasum)


println("Rowwise reduction")
println("=======================================")

rowwise_sum(a) = sum(a, 2)
rowwise_vsum(a) = vsum(a, 2)
@bench_vreduce1("rowwise-sum", 10, a, rowwise_sum, rowwise_vsum)

rowwise_asum(a) = sum(abs(a), 2)
rowwise_vasum(a) = vasum(a, 2)
@bench_vreduce1("rowwise-asum", 10, a, rowwise_asum, rowwise_vasum)


println("Reduction along two-dims of a cube")
println("=======================================")

a = rand(500, 500, 10)

sum_12(a) = sum(a, (1, 2))
vsum_12(a) = vsum(a, (1, 2))
@bench_vreduce1("(1,2)-sum", 10, a, sum_12, vsum_12)

sum_13(a) = sum(a, (1, 3))
vsum_13(a) = vsum(a, (1, 3))
@bench_vreduce1("(1,3)-sum", 10, a, sum_13, vsum_13)

sum_23(a) = sum(a, (2, 3))
vsum_23(a) = vsum(a, (2, 3))
@bench_vreduce1("(2,3)-sum", 10, a, sum_23, vsum_23)

asum_12(a) = sum(abs(a), (1, 2))
vasum_12(a) = vasum(a, (1, 2))
@bench_vreduce1("(1,2)-asum", 10, a, asum_12, vasum_12)

asum_13(a) = sum(abs(a), (1, 3))
vasum_13(a) = vasum(a, (1, 3))
@bench_vreduce1("(1,3)-asum", 10, a, asum_13, vasum_13)

asum_23(a) = sum(abs(a), (2, 3))
vasum_23(a) = vasum(a, (2, 3))
@bench_vreduce1("(2,3)-asum", 10, a, asum_23, vasum_23)







