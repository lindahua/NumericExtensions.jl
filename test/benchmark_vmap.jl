# Benchmark on vmap

using NumericFunctors

macro bench_vmap1(name, rp, a, f1, f2)
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
		@printf("\tvmap:   %7.4f sec | gain = %6.3f\n", t2, t1 / t2)
		println()
	end
end

macro bench_vmap2(name, rp, a, b, f1, f2)
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
		@printf("\tvmap:   %7.4f sec | gain = %6.3f\n", t2, t1 / t2)
		println()
	end
end

macro bench_vmap3(name, rp, a, b, c, f1, f2)
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
		@printf("\tvmap:   %7.4f sec | gain = %6.3f\n", t2, t1 / t2)
		println()
	end
end


# data

a = rand(1000, 1000)
b = rand(1000, 1000)
c = rand(1000, 1000)

add_vmap(a::Array, b::Array) = vmap(Add(), a, b)
@bench_vmap2("add", 10, a, b, +, add_vmap)

mul_vmap(a::Array, b::Array) = vmap(Multiply(), a, b)
@bench_vmap2("multiply", 10, a, b, .*, mul_vmap)

my_inv(a::Array) = 1.0 ./ a
inv_vmap(a::Array) = vmap(Divide(), 1.0, a)
@bench_vmap1("inv", 10, a, my_inv, inv_vmap)

pow_vmap(a::Array, b::Array) = vmap(Pow(), a, b)
@bench_vmap2("pow", 10, a, b, .^, pow_vmap)

max_vmap(a::Array, b::Array) = vmap(Max(), a, b)
@bench_vmap2("max", 10, a, b, max, max_vmap)

min_vmap(a::Array, b::Array) = vmap(Min(), a, b)
@bench_vmap2("min", 10, a, b, min, min_vmap)

abs_vmap(a::Array) = vmap(Abs(), a)
@bench_vmap1("abs", 10, a, abs, abs_vmap)

abs2_vmap(a::Array) = vmap(Abs2(), a)
@bench_vmap1("abs2", 10, a, abs2, abs2_vmap)

sqrt_vmap(a::Array) = vmap(Sqrt(), a)
@bench_vmap1("sqrt", 10, a, sqrt, sqrt_vmap)

exp_vmap(a::Array) = vmap(Exp(), a)
@bench_vmap1("exp", 10, a, exp, exp_vmap)

log_vmap(a::Array) = vmap(Log(), a)
@bench_vmap1("log", 10, a, log, log_vmap)

ju_absdiff(a::Array, b::Array) = abs(a - b)
@bench_vmap2("absdiff", 10, a, b, ju_absdiff, absdiff)

ju_sqrdiff(a::Array, b::Array) = abs2(a - b)
@bench_vmap2("sqrdiff", 10, a, b, ju_sqrdiff, sqrdiff)

ju_fma(a::Array, b::Array, c::Array) = a + b .* c
@bench_vmap3("fma", 10, a, b, c, ju_fma, fma)



