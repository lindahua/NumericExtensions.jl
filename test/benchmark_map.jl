# Benchmark on map

using NumericExtensions

macro bench_map1(name, rp, f1, f2)
	quote
		println("Benchmark on $($name) ...")

		($f1)(a)
		($f2)(a)

		t1 = @elapsed for i in 1 : ($rp)
			($f1)(a) 
		end

		t2 = @elapsed for i in 1 : ($rp)
			($f2)(a) 
		end

		add_row!(perftable, $name, [t1, t2, t1/t2])
	end
end

macro bench_map2(name, rp, f1, f2)
	quote
		println("Benchmark on $($name) ...")

		($f1)(a, b)
		($f2)(a, b)

		t1 = @elapsed for i in 1 : ($rp)
			($f1)(a, b) 
		end

		t2 = @elapsed for i in 1 : ($rp)
			($f2)(a, b) 
		end

		add_row!(perftable, $name, [t1, t2, t1/t2])
	end
end

macro bench_map3(name, rp, f1, f2)
	quote
		println("Benchmark on $($name) ...")

		($f1)($a, $b, $c)
		($f2)($a, $b, $c)

		t1 = @elapsed for i in 1 : ($rp)
			($f1)($a, $b, $c) 
		end

		t2 = @elapsed for i in 1 : ($rp)
			($f2)($a, $b, $c) 
		end

		add_row!(perftable, $name, [t1, t2, t1/t2])
	end
end

# data

a = rand(1000, 1000)
b = rand(1000, 1000) + 0.5
c = rand(1000, 1000)

const perftable = BenchmarkTable("Comparison of element-wise map", ["Julia-expr", "Functor-map", "gain"])

add_map(a::Array, b::Array) = map(Add(), a, b)
@bench_map2("add", 10, +, add_map)

mul_map(a::Array, b::Array) = map(Multiply(), a, b)
@bench_map2("multiply", 10, .*, mul_map)

my_inv(a::Array) = 1.0 ./ a
inv_map(a::Array) = map(Divide(), 1.0, a)
@bench_map1("inv", 10, my_inv, inv_map)

pow_map(a::Array, b::Array) = map(Pow(), a, b)
@bench_map2("pow", 10, .^, pow_map)

max_map(a::Array, b::Array) = map(Max(), a, b)
@bench_map2("max", 10, max, max_map)

min_map(a::Array, b::Array) = map(Min(), a, b)
@bench_map2("min", 10, min, min_map)

abs_map(a::Array) = map(Abs(), a)
@bench_map1("abs", 10, abs, abs_map)

abs2_map(a::Array) = map(Abs2(), a)
@bench_map1("abs2", 10, abs2, abs2_map)

sqrt_map(a::Array) = map(Sqrt(), a)
@bench_map1("sqrt", 10, sqrt, sqrt_map)

exp_map(a::Array) = map(Exp(), a)
@bench_map1("exp", 10, exp, exp_map)

log_map(a::Array) = map(Log(), a)
@bench_map1("log", 10, log, log_map)

ju_absdiff(a::Array, b::Array) = abs(a - b)
@bench_map2("absdiff", 10, ju_absdiff, absdiff)

ju_sqrdiff(a::Array, b::Array) = abs2(a - b)
@bench_map2("sqrdiff", 10, ju_sqrdiff, sqrdiff)

ju_fma(a::Array, b::Array, c::Array) = a + b .* c
@bench_map3("fma", 10, ju_fma, fma)

println()
println(perftable)





