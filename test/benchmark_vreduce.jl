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

cube_a = rand(500, 500, 4)
cube_b = rand(500, 500, 4)

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

colwise_max(a) = max(a, (), 1)
colwise_vmax(a) = vmax(a, 1)
@bench_vreduce1("colwise-max", 10, a, colwise_max, colwise_vmax)

colwise_min(a) = min(a, (), 1)
colwise_vmin(a) = vmin(a, 1)
@bench_vreduce1("colwise-min", 10, a, colwise_min, colwise_vmin)

colwise_asum(a) = sum(abs(a), 1)
colwise_vasum(a) = vasum(a, 1)
@bench_vreduce1("colwise-asum", 10, a, colwise_asum, colwise_vasum)

colwise_amax(a) = max(abs(a), (), 1)
colwise_vamax(a) = vamax(a, 1)
@bench_vreduce1("colwise-amax", 10, a, colwise_amax, colwise_vamax)

colwise_amin(a) = min(abs(a), (), 1)
colwise_vamin(a) = vamin(a, 1)
@bench_vreduce1("colwise-amin", 10, a, colwise_amin, colwise_vamin)

colwise_sqsum(a) = sum(abs2(a), 1)
colwise_vsqsum(a) = vsqsum(a, 1)
@bench_vreduce1("colwise-sqsum", 10, a, colwise_sqsum, colwise_vsqsum)

colwise_dot(a, b) = sum(a .* b, 1)
colwise_vdot(a, b) = vdot(a, b, 1)
@bench_vreduce2("colwise-dot", 10, a, b, colwise_dot, colwise_vdot)

colwise_adiffsum(a, b) = sum(abs(a - b), 1)
colwise_vadiffsum(a, b) = vadiffsum(a, b, 1)
@bench_vreduce2("colwise-adiffsum", 10, a, b, colwise_adiffsum, colwise_vadiffsum)

colwise_adiffmax(a, b) = max(abs(a - b), (), 1)
colwise_vadiffmax(a, b) = vadiffmax(a, b, 1)
@bench_vreduce2("colwise-adiffmax", 10, a, b, colwise_adiffmax, colwise_vadiffmax)

colwise_adiffmin(a, b) = min(abs(a - b), (), 1)
colwise_vadiffmin(a, b) = vadiffmin(a, b, 1)
@bench_vreduce2("colwise-adiffmin", 10, a, b, colwise_adiffmin, colwise_vadiffmin)

colwise_sqdiffsum(a, b) = sum(abs2(a - b), 1)
colwise_vsqdiffsum(a, b) = vsqdiffsum(a, b, 1)
@bench_vreduce2("colwise-sqdiffsum", 10, a, b, colwise_sqdiffsum, colwise_vsqdiffsum)


println("Rowwise reduction")
println("=======================================")

rowwise_sum(a) = sum(a, 2)
rowwise_vsum(a) = vsum(a, 2)
@bench_vreduce1("rowwise-sum", 10, a, rowwise_sum, rowwise_vsum)

rowwise_max(a) = max(a, (), 2)
rowwise_vmax(a) = vmax(a, 2)
@bench_vreduce1("rowwise-max", 10, a, rowwise_max, rowwise_vmax)

rowwise_min(a) = min(a, (), 2)
rowwise_vmin(a) = vmin(a, 2)
@bench_vreduce1("rowwise-min", 10, a, rowwise_min, rowwise_vmin)

rowwise_asum(a) = sum(abs(a), 2)
rowwise_vasum(a) = vasum(a, 2)
@bench_vreduce1("rowwise-asum", 10, a, rowwise_asum, rowwise_vasum)

rowwise_amax(a) = max(abs(a), (), 2)
rowwise_vamax(a) = vamax(a, 2)
@bench_vreduce1("rowwise-amax", 10, a, rowwise_amax, rowwise_vamax)

rowwise_amin(a) = min(abs(a), (), 2)
rowwise_vamin(a) = vamin(a, 2)
@bench_vreduce1("rowwise-amin", 10, a, rowwise_amin, rowwise_vamin)

rowwise_sqsum(a) = sum(abs2(a), 2)
rowwise_vsqsum(a) = vsqsum(a, 2)
@bench_vreduce1("rowwise-sqsum", 10, a, rowwise_sqsum, rowwise_vsqsum)

rowwise_dot(a, b) = sum(a .* b, 2)
rowwise_vdot(a, b) = vdot(a, b, 2)
@bench_vreduce2("rowwise-dot", 10, a, b, rowwise_dot, rowwise_vdot)

rowwise_adiffsum(a, b) = sum(abs(a - b), 2)
rowwise_vadiffsum(a, b) = vadiffsum(a, b, 2)
@bench_vreduce2("rowwise-adiffsum", 10, a, b, rowwise_adiffsum, rowwise_vadiffsum)

rowwise_adiffmax(a, b) = max(abs(a - b), (), 2)
rowwise_vadiffmax(a, b) = vadiffmax(a, b, 2)
@bench_vreduce2("rowwise-adiffmax", 10, a, b, rowwise_adiffmax, rowwise_vadiffmax)

rowwise_adiffmin(a, b) = min(abs(a - b), (), 2)
rowwise_vadiffmin(a, b) = vadiffmin(a, b, 2)
@bench_vreduce2("rowwise-adiffmin", 10, a, b, rowwise_adiffmin, rowwise_vadiffmin)

rowwise_sqdiffsum(a, b) = sum(abs2(a - b), 2)
rowwise_vsqdiffsum(a, b) = vsqdiffsum(a, b, 2)
@bench_vreduce2("rowwise-sqdiffsum", 10, a, b, rowwise_sqdiffsum, rowwise_vsqdiffsum)

println("Colwise Reduction for Cube")
println("=======================================")

@bench_vreduce1("colwise-sum (cube)", 10, cube_a, colwise_sum, colwise_vsum)
@bench_vreduce1("colwise-asum (cube)", 10, cube_a, colwise_asum, colwise_vasum)
@bench_vreduce1("colwise-amax (cube)", 10, cube_a, colwise_amax, colwise_vamax)
@bench_vreduce1("colwise-amin (cube)", 10, cube_a, colwise_amin, colwise_vamin)
@bench_vreduce1("colwise-sqsum (cube)", 10, cube_a, colwise_sqsum, colwise_vsqsum)
@bench_vreduce2("colwise-dot (cube)", 10, cube_a, cube_b, colwise_dot, colwise_vdot)
@bench_vreduce2("colwise-adiffsum (cube)", 10, cube_a, cube_b, colwise_adiffsum, colwise_vadiffsum)
@bench_vreduce2("colwise-adiffmax (cube)", 10, cube_a, cube_b, colwise_adiffmax, colwise_vadiffmax)
@bench_vreduce2("colwise-adiffmin (cube)", 10, cube_a, cube_b, colwise_adiffmin, colwise_vadiffmin)
@bench_vreduce2("colwise-sqdiffsum (cube)", 10, cube_a, cube_b, colwise_sqdiffsum, colwise_vsqdiffsum)


println("Rowwise Reduction for Cube")
println("=======================================")

@bench_vreduce1("rowwise-sum (cube)", 10, cube_a, rowwise_sum, rowwise_vsum)
@bench_vreduce1("rowwise-asum (cube)", 10, cube_a, rowwise_asum, rowwise_vasum)
@bench_vreduce1("rowwise-amax (cube)", 10, cube_a, rowwise_amax, rowwise_vamax)
@bench_vreduce1("rowwise-amin (cube)", 10, cube_a, rowwise_amin, rowwise_vamin)
@bench_vreduce1("rowwise-sqsum (cube)", 10, cube_a, rowwise_sqsum, rowwise_vsqsum)
@bench_vreduce2("rowwise-dot (cube)", 10, cube_a, cube_b, rowwise_dot, rowwise_vdot)
@bench_vreduce2("rowwise-adiffsum (cube)", 10, cube_a, cube_b, rowwise_adiffsum, rowwise_vadiffsum)
@bench_vreduce2("rowwise-adiffmax (cube)", 10, cube_a, cube_b, rowwise_adiffmax, rowwise_vadiffmax)
@bench_vreduce2("rowwise-adiffmin (cube)", 10, cube_a, cube_b, rowwise_adiffmin, rowwise_vadiffmin)
@bench_vreduce2("rowwise-sqdiffsum (cube)", 10, cube_a, cube_b, rowwise_sqdiffsum, rowwise_vsqdiffsum)


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

sqsum_12(a) = sum(abs2(a), (1, 2))
vsqsum_12(a) = vsqsum(a, (1, 2))
@bench_vreduce1("(1,2)-sqsum", 10, a, sqsum_12, vsqsum_12)

sqsum_13(a) = sum(abs2(a), (1, 3))
vsqsum_13(a) = vsqsum(a, (1, 3))
@bench_vreduce1("(1,3)-sqsum", 10, a, sqsum_13, vsqsum_13)

sqsum_23(a) = sum(abs2(a), (2, 3))
vsqsum_23(a) = vsqsum(a, (2, 3))
@bench_vreduce1("(2,3)-sqsum", 10, a, sqsum_23, vsqsum_23)





