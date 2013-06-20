# Benchmark on map

using NumericFunctors

macro bench_map1(name, rp, a, f1, f2)
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

		@printf("\tJulia:  %7.4f sec\n", t1)
		@printf("\tmap:   %7.4f sec | gain = %6.3f\n", t2, t1 / t2)
		println()
	end
end

macro bench_map2(name, rp, a, b, f1, f2)
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

		@printf("\tJulia:  %7.4f sec\n", t1)
		@printf("\tmap:   %7.4f sec | gain = %6.3f\n", t2, t1 / t2)
		println()
	end
end

macro bench_map3(name, rp, a, b, c, f1, f2)
	quote
		println("Benchmark on $($name):")

		($f1)($a, $b, $c)
		($f2)($a, $b, $c)

		t1 = @elapsed for i in 1 : ($rp)
			($f1)($a, $b, $c) 
		end

		t2 = @elapsed for i in 1 : ($rp)
			($f2)($a, $b, $c) 
		end

		@printf("\tJulia:  %7.4f sec\n", t1)
		@printf("\tmap:   %7.4f sec | gain = %6.3f\n", t2, t1 / t2)
		println()
	end
end


# data

a = rand(1000, 1000)
b = rand(1000, 1000)
c = rand(1000, 1000)

add_map(a::Array, b::Array) = map(Add(), a, b)
@bench_map2("add", 10, a, b, +, add_map)

mul_map(a::Array, b::Array) = map(Multiply(), a, b)
@bench_map2("multiply", 10, a, b, .*, mul_map)

my_inv(a::Array) = 1.0 ./ a
inv_map(a::Array) = map(Divide(), 1.0, a)
@bench_map1("inv", 10, a, my_inv, inv_map)

pow_map(a::Array, b::Array) = map(Pow(), a, b)
@bench_map2("pow", 10, a, b, .^, pow_map)

max_map(a::Array, b::Array) = map(Max(), a, b)
@bench_map2("max", 10, a, b, max, max_map)

min_map(a::Array, b::Array) = map(Min(), a, b)
@bench_map2("min", 10, a, b, min, min_map)

abs_map(a::Array) = map(Abs(), a)
@bench_map1("abs", 10, a, abs, abs_map)

abs2_map(a::Array) = map(Abs2(), a)
@bench_map1("abs2", 10, a, abs2, abs2_map)

sqrt_map(a::Array) = map(Sqrt(), a)
@bench_map1("sqrt", 10, a, sqrt, sqrt_map)

exp_map(a::Array) = map(Exp(), a)
@bench_map1("exp", 10, a, exp, exp_map)

log_map(a::Array) = map(Log(), a)
@bench_map1("log", 10, a, log, log_map)

ju_absdiff(a::Array, b::Array) = abs(a - b)
@bench_map2("absdiff", 10, a, b, ju_absdiff, absdiff)

ju_sqrdiff(a::Array, b::Array) = abs2(a - b)
@bench_map2("sqrdiff", 10, a, b, ju_sqrdiff, sqrdiff)

ju_fma(a::Array, b::Array, c::Array) = a + b .* c
@bench_map3("fma", 10, a, b, c, ju_fma, fma)



