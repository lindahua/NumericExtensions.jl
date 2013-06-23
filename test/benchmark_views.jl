# Benchmark of indexing performance unsafe_view

using NumericExtensions
using Base.Test

const rp = 100000
const tn = rp * 1000

to_gps(t) = float64(tn) / 1.0e9 / t * sizeof(Float64)

# 1D

function cp_1d(a::ContiguousVector, b::ContiguousVector)
	for i in 1 : length(a)
		b[i] = a[i]
	end
end

# use relatively small matrix, otherwise the cost of cache-swap may dominate
a = rand(1000)   
b = zeros(1000)

av = unsafe_view(a) 
bv = unsafe_view(b)

cp_1d(a, b)
cp_1d(av, bv)

t0 = @elapsed for i in 1 : rp cp_1d(a, b) end
t1 = @elapsed for i in 1 : rp cp_1d(av, bv) end

println("1D indexing throughput:")
@printf("    builtin array: %7.4f Gbyte/s\n", to_gps(t0))
@printf("    unsafe_view:   %7.4f Gbyte/s  |  gain = %.3fx\n", to_gps(t1), t0 / t1)

# 2D

a = rand(100, 10)
b = zeros(100, 10)

av = unsafe_view(a)
bv = unsafe_view(b)

function cp_2d(a::ContiguousMatrix, b::ContiguousMatrix)
	m = size(a, 1)
	n = size(a, 2)
	for j = 1 : n
		for i = 1 : m
			b[i,j] = a[i,j]
		end
	end
end

cp_2d(a, b)
cp_2d(av, bv)

t0 = @elapsed for i in 1 : rp cp_2d(a, b) end
t1 = @elapsed for i in 1 : rp cp_2d(av, bv) end

println("2D indexing throughput:")
@printf("    builtin array: %7.4f Gbyte/s\n", to_gps(t0))
@printf("    unsafe_view:   %7.4f Gbyte/s  |  gain = %.3fx\n", to_gps(t1), t0 / t1)

# 3D

a = rand(10,10,10)
b = rand(10,10,10)

av = unsafe_view(a)
bv = unsafe_view(b)

function cp_3d(a::ContiguousCube, b::ContiguousCube)
	m = size(a, 1)
	n = size(a, 2)
	k = size(a, 3)

	for l in 1 : k
		for j in 1 : n
			for i in 1 : m
				b[i,j,l] = a[i,j,l]
			end
		end
	end
end

cp_3d(a, b)
cp_3d(av, bv)

t0 = @elapsed for i in 1 : rp cp_3d(a, b) end
t1 = @elapsed for i in 1 : rp cp_3d(av, bv) end

println("3D indexing throughput:")
@printf("    builtin array: %7.4f Gbyte/s\n", to_gps(t0))
@printf("    unsafe_view:   %7.4f Gbyte/s  |  gain = %.3fx\n", to_gps(t1), t0 / t1)


println()


