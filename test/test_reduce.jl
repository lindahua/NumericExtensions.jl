# Test reduction

using NumericFunctors
using Base.Test

### safe (but slow) reduction functions for result verification

function safe_sum(x)
	r = zero(eltype(x))
	for i in 1 : length(x)
		r = r + x[i]
	end
	r
end

function safe_max(x)
	r = typemin(eltype(x))
	for i in 1 : length(x)
		r = max(r, x[i])
	end
	r
end

function safe_min(x)
	r = typemax(eltype(x))
	for i in 1 : length(x)
		r = min(r, x[i])
	end
	r
end

function rsize(x::Array, dim::Int)
	if 1 <= dim <= ndims(x)
		siz = size(x)
		rsiz_v = [siz...]
		rsiz_v[dim] = 1
		tuple(rsiz_v...)
	else
		size(x)
	end
end

function rsize{T}(x::Array{T, 3}, dims::(Int, Int))
	d1 = dims[1]
	d2 = dims[2]
	rsiz_v = [size(x)...]
	rsiz_v[d1] = 1
	rsiz_v[d2] = 1
	tuple(rsiz_v...)
end

function safe_xreduce(op::BinaryFunctor, x::Array, s0, dim::Int)
	# compute size
	nd = ndims(x)
	rsiz = rsize(x, dim)
	rd = size(x, dim)
	r = zeros(rsiz)

	# perform slice-wise computation
	ns = prod(rsiz)  # number of slices
	for i in 1 : ns
		coord = [ind2sub(rsiz, i)...]
		s = s0
		for j in 1 : rd
			if 1 <= dim <= nd 
				coord[dim] = j
			end
			s = evaluate(op, s, x[coord...])
		end
		r[i] = s
	end
	r
end

function safe_xreduce(op::BinaryFunctor, x::Array, s0, dims::(Int, Int))
	# compute size
	rsiz = rsize(x, dims)

	d1::Int = dims[1]
	d2::Int = dims[2]
	rd1 = size(x, d1)
	rd2 = size(x, d2)
	r = zeros(rsiz)

	# perform slice-wise computation
	ns = prod(rsiz)
	for i in 1 : ns
		coord = [ind2sub(rsiz, i)...]
		s = s0
		for j2 in 1 : rd2
			for j1 in 1 : rd1
				coord[d1] = j1
				coord[d2] = j2
				s = evaluate(op, s, x[coord...])
			end
		end
		r[i] = s
	end
	r
end

safe_sum(x, dim::Union(Int, (Int, Int))) = safe_xreduce(Add(), x, zero(eltype(x)), dim)
safe_max(x, dim::Union(Int, (Int, Int))) = safe_xreduce(Max(), x, typemin(eltype(x)), dim)
safe_min(x, dim::Union(Int, (Int, Int))) = safe_xreduce(Min(), x, typemax(eltype(x)), dim)



### full reduction ###

x = randn(3, 4)
y = randn(3, 4)
z = randn(3, 4)

@test_approx_eq sum(x) safe_sum(x)
@test sum(x) == reduce(Add(), x) 

@test max(x) == reduce(Max(), x) == safe_max(x)
@test min(x) == reduce(Min(), x) == safe_min(x)
@test nonneg_max(x) == max(safe_max(x), 0.)

@test_approx_eq vasum(x) safe_sum(abs(x))
@test_approx_eq vamax(x) safe_max(abs(x))
@test_approx_eq vamin(x) safe_min(abs(x))
@test_approx_eq vsqsum(x) safe_sum(abs2(x))

@test_approx_eq vdot(x, y) safe_sum(x .* y)
@test_approx_eq vadiffsum(x, y) safe_sum(abs(x - y))
@test_approx_eq vadiffmax(x, y) safe_max(abs(x - y))
@test_approx_eq vadiffmin(x, y) safe_min(abs(x - y))
@test_approx_eq vsqdiffsum(x, y) safe_sum(abs2(x - y))

@test_approx_eq vadiffsum(x, 1.5) safe_sum(abs(x - 1.5))
@test_approx_eq vadiffmax(x, 1.5) safe_max(abs(x - 1.5))
@test_approx_eq vadiffmin(x, 1.5) safe_min(abs(x - 1.5))
@test_approx_eq vsqdiffsum(x, 1.5) safe_sum(abs2(x - 1.5))

@test_approx_eq reduce_fdiff(Add(), Abs2(), 2.3, x) safe_sum(abs2(2.3 - x))

@test_approx_eq vnorm(x, 1) safe_sum(abs(x))
@test_approx_eq vnorm(x, 2) sqrt(safe_sum(abs2(x)))
@test_approx_eq vnorm(x, 3) safe_sum(abs(x) .^ 3) .^ (1/3)
@test_approx_eq vnorm(x, Inf) safe_max(abs(x))

@test_approx_eq vdiffnorm(x, y, 1) safe_sum(abs(x - y))
@test_approx_eq vdiffnorm(x, y, 2) sqrt(safe_sum(abs2(x - y)))
@test_approx_eq vdiffnorm(x, y, 3) safe_sum(abs(x - y) .^ 3) .^ (1/3)
@test_approx_eq vdiffnorm(x, y, Inf) safe_max(abs(x - y))

@test_approx_eq sum(FMA(), x, y, z) safe_sum(x + y .* z)
@test_approx_eq sum(FMA(), x, y, 2.) safe_sum(x + y .* 2)
@test_approx_eq sum(FMA(), x, 2., y) safe_sum(x + 2 .* y)
@test_approx_eq sum(FMA(), 2., x, y) safe_sum(2. + x .* y)
@test_approx_eq sum(FMA(), x, 2., 3.) safe_sum(x + 6.)
@test_approx_eq sum(FMA(), 2., x, 3.) safe_sum(2. + x * 3.)
@test_approx_eq sum(FMA(), 2., 3., x) safe_sum(2. + 3. * x)

### partial reduction ###

x1 = randn(6)
y1 = randn(6)
z1 = randn(6)

x2 = randn(5, 6)
y2 = randn(5, 6)
z2 = randn(5, 6)

x3 = randn(3, 4, 5)
y3 = randn(3, 4, 5)
z3 = randn(3, 4, 5)

x4 = randn(3, 4, 5, 2)
y4 = randn(3, 4, 5, 2)
z4 = randn(3, 4, 5, 2)

# sum

@test size(sum(x1, 1)) == rsize(x1, 1)
@test size(sum(x1, 2)) == rsize(x1, 2)
@test size(sum(x2, 1)) == rsize(x2, 1)
@test size(sum(x2, 2)) == rsize(x2, 2)
@test size(sum(x2, 3)) == rsize(x2, 3)
@test size(sum(x3, 1)) == rsize(x3, 1)
@test size(sum(x3, 2)) == rsize(x3, 2)
@test size(sum(x3, 3)) == rsize(x3, 3)
@test size(sum(x3, 4)) == rsize(x3, 4)
@test size(sum(x4, 1)) == rsize(x4, 1)
@test size(sum(x4, 2)) == rsize(x4, 2)
@test size(sum(x4, 3)) == rsize(x4, 3)
@test size(sum(x4, 4)) == rsize(x4, 4)
@test size(sum(x4, 5)) == rsize(x4, 5)

@test_approx_eq sum(x1, 1) safe_sum(x1, 1)
@test_approx_eq sum(x1, 2) safe_sum(x1, 2)
@test_approx_eq sum(x2, 1) safe_sum(x2, 1)
@test_approx_eq sum(x2, 2) safe_sum(x2, 2)
@test_approx_eq sum(x2, 3) safe_sum(x2, 3)
@test_approx_eq sum(x3, 1) safe_sum(x3, 1)
@test_approx_eq sum(x3, 2) safe_sum(x3, 2)
@test_approx_eq sum(x3, 3) safe_sum(x3, 3)
@test_approx_eq sum(x3, 4) safe_sum(x3, 4)
@test_approx_eq sum(x4, 1) safe_sum(x4, 1)
@test_approx_eq sum(x4, 2) safe_sum(x4, 2)
@test_approx_eq sum(x4, 3) safe_sum(x4, 3)
@test_approx_eq sum(x4, 4) safe_sum(x4, 4)
@test_approx_eq sum(x4, 5) safe_sum(x4, 5)

r = zeros(6); sum!(r, x2, 1)
@test_approx_eq r vec(safe_sum(x2, 1))

r = zeros(5); sum!(r, x2, 2)
@test_approx_eq r vec(safe_sum(x2, 2))

r = zeros(4, 5); sum!(r, x3, 1)
@test_approx_eq r reshape(safe_sum(x3, 1), 4, 5)

r = zeros(3, 5); sum!(r, x3, 2)
@test_approx_eq r reshape(safe_sum(x3, 2), 3, 5)

r = zeros(3, 4); sum!(r, x3, 3)
@test_approx_eq r reshape(safe_sum(x3, 3), 3, 4)

@test size(sum(x3, (1, 2))) == rsize(x3, (1, 2))
@test size(sum(x3, (1, 3))) == rsize(x3, (1, 3))
@test size(sum(x3, (2, 3))) == rsize(x3, (2, 3))

@test_approx_eq sum(x3, (1, 2)) safe_sum(x3, (1, 2))
@test_approx_eq sum(x3, (1, 3)) safe_sum(x3, (1, 3))
@test_approx_eq sum(x3, (2, 3)) safe_sum(x3, (2, 3))

r = zeros(5); sum!(r, x3, (1, 2))
@test_approx_eq r vec(safe_sum(x3, (1, 2)))

r = zeros(4); sum!(r, x3, (1, 3))
@test_approx_eq r vec(safe_sum(x3, (1, 3)))

r = zeros(3); sum!(r, x3, (2, 3))
@test_approx_eq r vec(safe_sum(x3, (2, 3)))

# max

@test_approx_eq max(x1, (), 1) safe_max(x1, 1)
@test_approx_eq max(x1, (), 2) safe_max(x1, 2)
@test_approx_eq max(x2, (), 1) safe_max(x2, 1)
@test_approx_eq max(x2, (), 2) safe_max(x2, 2)
@test_approx_eq max(x2, (), 3) safe_max(x2, 3)
@test_approx_eq max(x3, (), 1) safe_max(x3, 1)
@test_approx_eq max(x3, (), 2) safe_max(x3, 2)
@test_approx_eq max(x3, (), 3) safe_max(x3, 3)
@test_approx_eq max(x3, (), 4) safe_max(x3, 4)
@test_approx_eq max(x4, (), 1) safe_max(x4, 1)
@test_approx_eq max(x4, (), 2) safe_max(x4, 2)
@test_approx_eq max(x4, (), 3) safe_max(x4, 3)
@test_approx_eq max(x4, (), 4) safe_max(x4, 4)
@test_approx_eq max(x4, (), 5) safe_max(x4, 5)

@test_approx_eq max(x3, (), (1, 2)) safe_max(x3, (1, 2))
@test_approx_eq max(x3, (), (1, 3)) safe_max(x3, (1, 3))
@test_approx_eq max(x3, (), (2, 3)) safe_max(x3, (2, 3))

# min

@test_approx_eq min(x1, (), 1) safe_min(x1, 1)
@test_approx_eq min(x1, (), 2) safe_min(x1, 2)
@test_approx_eq min(x2, (), 1) safe_min(x2, 1)
@test_approx_eq min(x2, (), 2) safe_min(x2, 2)
@test_approx_eq min(x2, (), 3) safe_min(x2, 3)
@test_approx_eq min(x3, (), 1) safe_min(x3, 1)
@test_approx_eq min(x3, (), 2) safe_min(x3, 2)
@test_approx_eq min(x3, (), 3) safe_min(x3, 3)
@test_approx_eq min(x3, (), 4) safe_min(x3, 4)
@test_approx_eq min(x4, (), 1) safe_min(x4, 1)
@test_approx_eq min(x4, (), 2) safe_min(x4, 2)
@test_approx_eq min(x4, (), 3) safe_min(x4, 3)
@test_approx_eq min(x4, (), 4) safe_min(x4, 4)
@test_approx_eq min(x4, (), 5) safe_min(x4, 5)

@test_approx_eq min(x3, (), (1, 2)) safe_min(x3, (1, 2))
@test_approx_eq min(x3, (), (1, 3)) safe_min(x3, (1, 3))
@test_approx_eq min(x3, (), (2, 3)) safe_min(x3, (2, 3))

# vasum

@test_approx_eq vasum(x1, 1) sum(abs(x1), 1)
@test_approx_eq vasum(x1, 2) sum(abs(x1), 2)
@test_approx_eq vasum(x2, 1) sum(abs(x2), 1)
@test_approx_eq vasum(x2, 2) sum(abs(x2), 2)
@test_approx_eq vasum(x2, 3) sum(abs(x2), 3)
@test_approx_eq vasum(x3, 1) sum(abs(x3), 1)
@test_approx_eq vasum(x3, 2) sum(abs(x3), 2)
@test_approx_eq vasum(x3, 3) sum(abs(x3), 3)
@test_approx_eq vasum(x3, 4) sum(abs(x3), 4)
@test_approx_eq vasum(x4, 1) sum(abs(x4), 1)
@test_approx_eq vasum(x4, 2) sum(abs(x4), 2)
@test_approx_eq vasum(x4, 3) sum(abs(x4), 3)
@test_approx_eq vasum(x4, 4) sum(abs(x4), 4)
@test_approx_eq vasum(x4, 5) sum(abs(x4), 5)

@test_approx_eq vasum(x3, (1, 2)) sum(abs(x3), (1, 2))
@test_approx_eq vasum(x3, (1, 3)) sum(abs(x3), (1, 3))
@test_approx_eq vasum(x3, (2, 3)) sum(abs(x3), (2, 3))

r = zeros(6); vasum!(r, x2, 1)
@test_approx_eq r vec(sum(abs(x2), 1))

# vamax

@test_approx_eq vamax(x1, 1) max(abs(x1), (), 1)
@test_approx_eq vamax(x1, 2) max(abs(x1), (), 2)
@test_approx_eq vamax(x2, 1) max(abs(x2), (), 1)
@test_approx_eq vamax(x2, 2) max(abs(x2), (), 2)
@test_approx_eq vamax(x2, 3) max(abs(x2), (), 3)
@test_approx_eq vamax(x3, 1) max(abs(x3), (), 1)
@test_approx_eq vamax(x3, 2) max(abs(x3), (), 2)
@test_approx_eq vamax(x3, 3) max(abs(x3), (), 3)
@test_approx_eq vamax(x3, 4) max(abs(x3), (), 4)
@test_approx_eq vamax(x4, 1) max(abs(x4), (), 1)
@test_approx_eq vamax(x4, 2) max(abs(x4), (), 2)
@test_approx_eq vamax(x4, 3) max(abs(x4), (), 3)
@test_approx_eq vamax(x4, 4) max(abs(x4), (), 4)
@test_approx_eq vamax(x4, 5) max(abs(x4), (), 5)

@test_approx_eq vamax(x3, (1, 2)) max(abs(x3), (), (1, 2))
@test_approx_eq vamax(x3, (1, 3)) max(abs(x3), (), (1, 3))
@test_approx_eq vamax(x3, (2, 3)) max(abs(x3), (), (2, 3))

r = zeros(6); vamax!(r, x2, 1)
@test_approx_eq r vec(max(abs(x2), (), 1))

# vamin

@test_approx_eq vamin(x1, 1) min(abs(x1), (), 1)
@test_approx_eq vamin(x1, 2) min(abs(x1), (), 2)
@test_approx_eq vamin(x2, 1) min(abs(x2), (), 1)
@test_approx_eq vamin(x2, 2) min(abs(x2), (), 2)
@test_approx_eq vamin(x2, 3) min(abs(x2), (), 3)
@test_approx_eq vamin(x3, 1) min(abs(x3), (), 1)
@test_approx_eq vamin(x3, 2) min(abs(x3), (), 2)
@test_approx_eq vamin(x3, 3) min(abs(x3), (), 3)
@test_approx_eq vamin(x3, 4) min(abs(x3), (), 4)
@test_approx_eq vamin(x4, 1) min(abs(x4), (), 1)
@test_approx_eq vamin(x4, 2) min(abs(x4), (), 2)
@test_approx_eq vamin(x4, 3) min(abs(x4), (), 3)
@test_approx_eq vamin(x4, 4) min(abs(x4), (), 4)
@test_approx_eq vamin(x4, 5) min(abs(x4), (), 5)

@test_approx_eq vamin(x3, (1, 2)) min(abs(x3), (), (1, 2))
@test_approx_eq vamin(x3, (1, 3)) min(abs(x3), (), (1, 3))
@test_approx_eq vamin(x3, (2, 3)) min(abs(x3), (), (2, 3))

r = zeros(6); vamin!(r, x2, 1)
@test_approx_eq r vec(min(abs(x2), (), 1))

# vsqsum

@test_approx_eq vsqsum(x1, 1) sum(abs2(x1), 1)
@test_approx_eq vsqsum(x1, 2) sum(abs2(x1), 2)
@test_approx_eq vsqsum(x2, 1) sum(abs2(x2), 1)
@test_approx_eq vsqsum(x2, 2) sum(abs2(x2), 2)
@test_approx_eq vsqsum(x2, 3) sum(abs2(x2), 3)
@test_approx_eq vsqsum(x3, 1) sum(abs2(x3), 1)
@test_approx_eq vsqsum(x3, 2) sum(abs2(x3), 2)
@test_approx_eq vsqsum(x3, 3) sum(abs2(x3), 3)
@test_approx_eq vsqsum(x3, 4) sum(abs2(x3), 4)
@test_approx_eq vsqsum(x4, 1) sum(abs2(x4), 1)
@test_approx_eq vsqsum(x4, 2) sum(abs2(x4), 2)
@test_approx_eq vsqsum(x4, 3) sum(abs2(x4), 3)
@test_approx_eq vsqsum(x4, 4) sum(abs2(x4), 4)
@test_approx_eq vsqsum(x4, 5) sum(abs2(x4), 5)

@test_approx_eq vsqsum(x3, (1, 2)) sum(abs2(x3), (1, 2))
@test_approx_eq vsqsum(x3, (1, 3)) sum(abs2(x3), (1, 3))
@test_approx_eq vsqsum(x3, (2, 3)) sum(abs2(x3), (2, 3))

r = zeros(6); vsqsum!(r, x2, 1)
@test_approx_eq r vec(sum(abs2(x2), 1))

# vdot

@test_approx_eq vdot(x1, y1, 1) sum(x1 .* y1, 1)
@test_approx_eq vdot(x1, y1, 2) sum(x1 .* y1, 2)
@test_approx_eq vdot(x2, y2, 1) sum(x2 .* y2, 1)
@test_approx_eq vdot(x2, y2, 2) sum(x2 .* y2, 2)
@test_approx_eq vdot(x2, y2, 3) sum(x2 .* y2, 3)
@test_approx_eq vdot(x3, y3, 1) sum(x3 .* y3, 1)
@test_approx_eq vdot(x3, y3, 2) sum(x3 .* y3, 2)
@test_approx_eq vdot(x3, y3, 3) sum(x3 .* y3, 3)
@test_approx_eq vdot(x3, y3, 4) sum(x3 .* y3, 4)
@test_approx_eq vdot(x4, y4, 1) sum(x4 .* y4, 1)
@test_approx_eq vdot(x4, y4, 2) sum(x4 .* y4, 2)
@test_approx_eq vdot(x4, y4, 3) sum(x4 .* y4, 3)
@test_approx_eq vdot(x4, y4, 4) sum(x4 .* y4, 4)
@test_approx_eq vdot(x4, y4, 5) sum(x4 .* y4, 5)

@test_approx_eq vdot(x3, y3, (1, 2)) sum(x3 .* y3, (1, 2))
@test_approx_eq vdot(x3, y3, (1, 3)) sum(x3 .* y3, (1, 3))
@test_approx_eq vdot(x3, y3, (2, 3)) sum(x3 .* y3, (2, 3))

r = zeros(6); vdot!(r, x2, y2, 1)
@test_approx_eq r vec(sum(x2 .* y2, 1))

# vadiffsum

@test_approx_eq vadiffsum(x1, y1, 1) sum(abs(x1 - y1), 1)
@test_approx_eq vadiffsum(x1, y1, 2) sum(abs(x1 - y1), 2)
@test_approx_eq vadiffsum(x2, y2, 1) sum(abs(x2 - y2), 1)
@test_approx_eq vadiffsum(x2, y2, 2) sum(abs(x2 - y2), 2)
@test_approx_eq vadiffsum(x2, y2, 3) sum(abs(x2 - y2), 3)
@test_approx_eq vadiffsum(x3, y3, 1) sum(abs(x3 - y3), 1)
@test_approx_eq vadiffsum(x3, y3, 2) sum(abs(x3 - y3), 2)
@test_approx_eq vadiffsum(x3, y3, 3) sum(abs(x3 - y3), 3)
@test_approx_eq vadiffsum(x3, y3, 4) sum(abs(x3 - y3), 4)
@test_approx_eq vadiffsum(x4, y4, 1) sum(abs(x4 - y4), 1)
@test_approx_eq vadiffsum(x4, y4, 2) sum(abs(x4 - y4), 2)
@test_approx_eq vadiffsum(x4, y4, 3) sum(abs(x4 - y4), 3)
@test_approx_eq vadiffsum(x4, y4, 4) sum(abs(x4 - y4), 4)
@test_approx_eq vadiffsum(x4, y4, 5) sum(abs(x4 - y4), 5)

@test_approx_eq vadiffsum(x3, y3, (1, 2)) sum(abs(x3 - y3), (1, 2))
@test_approx_eq vadiffsum(x3, y3, (1, 3)) sum(abs(x3 - y3), (1, 3))
@test_approx_eq vadiffsum(x3, y3, (2, 3)) sum(abs(x3 - y3), (2, 3))

r = zeros(6); vadiffsum!(r, x2, y2, 1)
@test_approx_eq r vec(sum(abs(x2 - y2), 1))

# vdiffmax

@test_approx_eq vadiffmax(x1, y1, 1) max(abs(x1 - y1), (), 1)
@test_approx_eq vadiffmax(x1, y1, 2) max(abs(x1 - y1), (), 2)
@test_approx_eq vadiffmax(x2, y2, 1) max(abs(x2 - y2), (), 1)
@test_approx_eq vadiffmax(x2, y2, 2) max(abs(x2 - y2), (), 2)
@test_approx_eq vadiffmax(x2, y2, 3) max(abs(x2 - y2), (), 3)
@test_approx_eq vadiffmax(x3, y3, 1) max(abs(x3 - y3), (), 1)
@test_approx_eq vadiffmax(x3, y3, 2) max(abs(x3 - y3), (), 2)
@test_approx_eq vadiffmax(x3, y3, 3) max(abs(x3 - y3), (), 3)
@test_approx_eq vadiffmax(x3, y3, 4) max(abs(x3 - y3), (), 4)
@test_approx_eq vadiffmax(x4, y4, 1) max(abs(x4 - y4), (), 1)
@test_approx_eq vadiffmax(x4, y4, 2) max(abs(x4 - y4), (), 2)
@test_approx_eq vadiffmax(x4, y4, 3) max(abs(x4 - y4), (), 3)
@test_approx_eq vadiffmax(x4, y4, 4) max(abs(x4 - y4), (), 4)
@test_approx_eq vadiffmax(x4, y4, 5) max(abs(x4 - y4), (), 5)

@test_approx_eq vadiffmax(x3, y3, (1, 2)) max(abs(x3 - y3), (), (1, 2))
@test_approx_eq vadiffmax(x3, y3, (1, 3)) max(abs(x3 - y3), (), (1, 3))
@test_approx_eq vadiffmax(x3, y3, (2, 3)) max(abs(x3 - y3), (), (2, 3))

r = zeros(6); vadiffmax!(r, x2, y2, 1)
@test_approx_eq r vec(max(abs(x2 - y2), (), 1))

# vdiffmin

@test_approx_eq vadiffmin(x1, y1, 1) min(abs(x1 - y1), (), 1)
@test_approx_eq vadiffmin(x1, y1, 2) min(abs(x1 - y1), (), 2)
@test_approx_eq vadiffmin(x2, y2, 1) min(abs(x2 - y2), (), 1)
@test_approx_eq vadiffmin(x2, y2, 2) min(abs(x2 - y2), (), 2)
@test_approx_eq vadiffmin(x2, y2, 3) min(abs(x2 - y2), (), 3)
@test_approx_eq vadiffmin(x3, y3, 1) min(abs(x3 - y3), (), 1)
@test_approx_eq vadiffmin(x3, y3, 2) min(abs(x3 - y3), (), 2)
@test_approx_eq vadiffmin(x3, y3, 3) min(abs(x3 - y3), (), 3)
@test_approx_eq vadiffmin(x3, y3, 4) min(abs(x3 - y3), (), 4)
@test_approx_eq vadiffmin(x4, y4, 1) min(abs(x4 - y4), (), 1)
@test_approx_eq vadiffmin(x4, y4, 2) min(abs(x4 - y4), (), 2)
@test_approx_eq vadiffmin(x4, y4, 3) min(abs(x4 - y4), (), 3)
@test_approx_eq vadiffmin(x4, y4, 4) min(abs(x4 - y4), (), 4)
@test_approx_eq vadiffmin(x4, y4, 5) min(abs(x4 - y4), (), 5)

@test_approx_eq vadiffmin(x3, y3, (1, 2)) min(abs(x3 - y3), (), (1, 2))
@test_approx_eq vadiffmin(x3, y3, (1, 3)) min(abs(x3 - y3), (), (1, 3))
@test_approx_eq vadiffmin(x3, y3, (2, 3)) min(abs(x3 - y3), (), (2, 3))

r = zeros(6); vadiffmin!(r, x2, y2, 1)
@test_approx_eq r vec(min(abs(x2 - y2), (), 1))

# vsqdiffsum

@test_approx_eq vsqdiffsum(x1, y1, 1) sum(abs2(x1 - y1), 1)
@test_approx_eq vsqdiffsum(x1, y1, 2) sum(abs2(x1 - y1), 2)
@test_approx_eq vsqdiffsum(x2, y2, 1) sum(abs2(x2 - y2), 1)
@test_approx_eq vsqdiffsum(x2, y2, 2) sum(abs2(x2 - y2), 2)
@test_approx_eq vsqdiffsum(x2, y2, 3) sum(abs2(x2 - y2), 3)
@test_approx_eq vsqdiffsum(x3, y3, 1) sum(abs2(x3 - y3), 1)
@test_approx_eq vsqdiffsum(x3, y3, 2) sum(abs2(x3 - y3), 2)
@test_approx_eq vsqdiffsum(x3, y3, 3) sum(abs2(x3 - y3), 3)
@test_approx_eq vsqdiffsum(x3, y3, 4) sum(abs2(x3 - y3), 4)
@test_approx_eq vsqdiffsum(x4, y4, 1) sum(abs2(x4 - y4), 1)
@test_approx_eq vsqdiffsum(x4, y4, 2) sum(abs2(x4 - y4), 2)
@test_approx_eq vsqdiffsum(x4, y4, 3) sum(abs2(x4 - y4), 3)
@test_approx_eq vsqdiffsum(x4, y4, 4) sum(abs2(x4 - y4), 4)
@test_approx_eq vsqdiffsum(x4, y4, 5) sum(abs2(x4 - y4), 5)

@test_approx_eq vsqdiffsum(x3, y3, (1, 2)) sum(abs2(x3 - y3), (1, 2))
@test_approx_eq vsqdiffsum(x3, y3, (1, 3)) sum(abs2(x3 - y3), (1, 3))
@test_approx_eq vsqdiffsum(x3, y3, (2, 3)) sum(abs2(x3 - y3), (2, 3))

r = zeros(6); vsqdiffsum!(r, x2, y2, 1)
@test_approx_eq r vec(sum(abs2(x2 - y2), 1))

# reduce on fma

@test_approx_eq sum(FMA(), x1, y1, z1, 1) sum(x1 + y1 .* z1, 1)
@test_approx_eq sum(FMA(), x1, y1, z1, 2) sum(x1 + y1 .* z1, 2)
@test_approx_eq sum(FMA(), x2, y2, z2, 1) sum(x2 + y2 .* z2, 1)
@test_approx_eq sum(FMA(), x2, y2, z2, 2) sum(x2 + y2 .* z2, 2)
@test_approx_eq sum(FMA(), x2, y2, z2, 3) sum(x2 + y2 .* z2, 3)
@test_approx_eq sum(FMA(), x3, y3, z3, 1) sum(x3 + y3 .* z3, 1)
@test_approx_eq sum(FMA(), x3, y3, z3, 2) sum(x3 + y3 .* z3, 2)
@test_approx_eq sum(FMA(), x3, y3, z3, 3) sum(x3 + y3 .* z3, 3)
@test_approx_eq sum(FMA(), x3, y3, z3, 4) sum(x3 + y3 .* z3, 4)
@test_approx_eq sum(FMA(), x4, y4, z4, 1) sum(x4 + y4 .* z4, 1)
@test_approx_eq sum(FMA(), x4, y4, z4, 2) sum(x4 + y4 .* z4, 2)
@test_approx_eq sum(FMA(), x4, y4, z4, 3) sum(x4 + y4 .* z4, 3)
@test_approx_eq sum(FMA(), x4, y4, z4, 4) sum(x4 + y4 .* z4, 4)
@test_approx_eq sum(FMA(), x4, y4, z4, 5) sum(x4 + y4 .* z4, 5)

@test_approx_eq sum(FMA(), x3, y3, z3, (1, 2)) sum(x3 + y3 .* z3, (1, 2))
@test_approx_eq sum(FMA(), x3, y3, z3, (1, 3)) sum(x3 + y3 .* z3, (1, 3))
@test_approx_eq sum(FMA(), x3, y3, z3, (2, 3)) sum(x3 + y3 .* z3, (2, 3))

# vnorm

@test_approx_eq vnorm(x1, 1, 1) sum(abs(x1), 1)
@test_approx_eq vnorm(x1, 1, 2) sum(abs(x1), 2)
@test_approx_eq vnorm(x2, 1, 1) sum(abs(x2), 1)
@test_approx_eq vnorm(x2, 1, 2) sum(abs(x2), 2)
@test_approx_eq vnorm(x2, 1, 3) sum(abs(x2), 3)
@test_approx_eq vnorm(x3, 1, 1) sum(abs(x3), 1)
@test_approx_eq vnorm(x3, 1, 2) sum(abs(x3), 2)
@test_approx_eq vnorm(x3, 1, 3) sum(abs(x3), 3)
@test_approx_eq vnorm(x3, 1, 4) sum(abs(x3), 4)
@test_approx_eq vnorm(x4, 1, 1) sum(abs(x4), 1)
@test_approx_eq vnorm(x4, 1, 2) sum(abs(x4), 2)
@test_approx_eq vnorm(x4, 1, 3) sum(abs(x4), 3)
@test_approx_eq vnorm(x4, 1, 4) sum(abs(x4), 4)
@test_approx_eq vnorm(x4, 1, 5) sum(abs(x4), 5)

@test_approx_eq vnorm(x3, 1, (1, 2)) sum(abs(x3), (1, 2))
@test_approx_eq vnorm(x3, 1, (1, 3)) sum(abs(x3), (1, 3))
@test_approx_eq vnorm(x3, 1, (2, 3)) sum(abs(x3), (2, 3))

@test_approx_eq vnorm(x1, 2, 1) sqrt(sum(abs2(x1), 1))
@test_approx_eq vnorm(x1, 2, 2) sqrt(sum(abs2(x1), 2))
@test_approx_eq vnorm(x2, 2, 1) sqrt(sum(abs2(x2), 1))
@test_approx_eq vnorm(x2, 2, 2) sqrt(sum(abs2(x2), 2))
@test_approx_eq vnorm(x2, 2, 3) sqrt(sum(abs2(x2), 3))
@test_approx_eq vnorm(x3, 2, 1) sqrt(sum(abs2(x3), 1))
@test_approx_eq vnorm(x3, 2, 2) sqrt(sum(abs2(x3), 2))
@test_approx_eq vnorm(x3, 2, 3) sqrt(sum(abs2(x3), 3))
@test_approx_eq vnorm(x3, 2, 4) sqrt(sum(abs2(x3), 4))
@test_approx_eq vnorm(x4, 2, 1) sqrt(sum(abs2(x4), 1))
@test_approx_eq vnorm(x4, 2, 2) sqrt(sum(abs2(x4), 2))
@test_approx_eq vnorm(x4, 2, 3) sqrt(sum(abs2(x4), 3))
@test_approx_eq vnorm(x4, 2, 4) sqrt(sum(abs2(x4), 4))
@test_approx_eq vnorm(x4, 2, 5) sqrt(sum(abs2(x4), 5))

@test_approx_eq vnorm(x3, 2, (1, 2)) sqrt(sum(abs2(x3), (1, 2)))
@test_approx_eq vnorm(x3, 2, (1, 3)) sqrt(sum(abs2(x3), (1, 3)))
@test_approx_eq vnorm(x3, 2, (2, 3)) sqrt(sum(abs2(x3), (2, 3)))

@test_approx_eq vnorm(x1, Inf, 1) max(abs(x1), (), 1)
@test_approx_eq vnorm(x1, Inf, 2) max(abs(x1), (), 2)
@test_approx_eq vnorm(x2, Inf, 1) max(abs(x2), (), 1)
@test_approx_eq vnorm(x2, Inf, 2) max(abs(x2), (), 2)
@test_approx_eq vnorm(x2, Inf, 3) max(abs(x2), (), 3)
@test_approx_eq vnorm(x3, Inf, 1) max(abs(x3), (), 1)
@test_approx_eq vnorm(x3, Inf, 2) max(abs(x3), (), 2)
@test_approx_eq vnorm(x3, Inf, 3) max(abs(x3), (), 3)
@test_approx_eq vnorm(x3, Inf, 4) max(abs(x3), (), 4)
@test_approx_eq vnorm(x4, Inf, 1) max(abs(x4), (), 1)
@test_approx_eq vnorm(x4, Inf, 2) max(abs(x4), (), 2)
@test_approx_eq vnorm(x4, Inf, 3) max(abs(x4), (), 3)
@test_approx_eq vnorm(x4, Inf, 4) max(abs(x4), (), 4)
@test_approx_eq vnorm(x4, Inf, 5) max(abs(x4), (), 5)

@test_approx_eq vnorm(x3, Inf, (1, 2)) max(abs(x3), (), (1, 2))
@test_approx_eq vnorm(x3, Inf, (1, 3)) max(abs(x3), (), (1, 3))
@test_approx_eq vnorm(x3, Inf, (2, 3)) max(abs(x3), (), (2, 3))

@test_approx_eq vnorm(x1, 3, 1) sum(abs(x1).^3, 1).^(1/3)
@test_approx_eq vnorm(x1, 3, 2) sum(abs(x1).^3, 2).^(1/3)
@test_approx_eq vnorm(x2, 3, 1) sum(abs(x2).^3, 1).^(1/3)
@test_approx_eq vnorm(x2, 3, 2) sum(abs(x2).^3, 2).^(1/3)
@test_approx_eq vnorm(x2, 3, 3) sum(abs(x2).^3, 3).^(1/3)
@test_approx_eq vnorm(x3, 3, 1) sum(abs(x3).^3, 1).^(1/3)
@test_approx_eq vnorm(x3, 3, 2) sum(abs(x3).^3, 2).^(1/3)
@test_approx_eq vnorm(x3, 3, 3) sum(abs(x3).^3, 3).^(1/3)
@test_approx_eq vnorm(x3, 3, 4) sum(abs(x3).^3, 4).^(1/3)
@test_approx_eq vnorm(x4, 3, 1) sum(abs(x4).^3, 1).^(1/3)
@test_approx_eq vnorm(x4, 3, 2) sum(abs(x4).^3, 2).^(1/3)
@test_approx_eq vnorm(x4, 3, 3) sum(abs(x4).^3, 3).^(1/3)
@test_approx_eq vnorm(x4, 3, 4) sum(abs(x4).^3, 4).^(1/3)
@test_approx_eq vnorm(x4, 3, 5) sum(abs(x4).^3, 5).^(1/3)

@test_approx_eq vnorm(x3, 3, (1, 2)) sum(abs(x3).^3, (1, 2)).^(1/3)
@test_approx_eq vnorm(x3, 3, (1, 3)) sum(abs(x3).^3, (1, 3)).^(1/3)
@test_approx_eq vnorm(x3, 3, (2, 3)) sum(abs(x3).^3, (2, 3)).^(1/3)


# vnormdiff

@test_approx_eq vdiffnorm(x1, y1, 1, 1) sum(abs(x1 - y1), 1)
@test_approx_eq vdiffnorm(x1, y1, 1, 2) sum(abs(x1 - y1), 2)
@test_approx_eq vdiffnorm(x2, y2, 1, 1) sum(abs(x2 - y2), 1)
@test_approx_eq vdiffnorm(x2, y2, 1, 2) sum(abs(x2 - y2), 2)
@test_approx_eq vdiffnorm(x2, y2, 1, 3) sum(abs(x2 - y2), 3)
@test_approx_eq vdiffnorm(x3, y3, 1, 1) sum(abs(x3 - y3), 1)
@test_approx_eq vdiffnorm(x3, y3, 1, 2) sum(abs(x3 - y3), 2)
@test_approx_eq vdiffnorm(x3, y3, 1, 3) sum(abs(x3 - y3), 3)
@test_approx_eq vdiffnorm(x3, y3, 1, 4) sum(abs(x3 - y3), 4)
@test_approx_eq vdiffnorm(x4, y4, 1, 1) sum(abs(x4 - y4), 1)
@test_approx_eq vdiffnorm(x4, y4, 1, 2) sum(abs(x4 - y4), 2)
@test_approx_eq vdiffnorm(x4, y4, 1, 3) sum(abs(x4 - y4), 3)
@test_approx_eq vdiffnorm(x4, y4, 1, 4) sum(abs(x4 - y4), 4)
@test_approx_eq vdiffnorm(x4, y4, 1, 5) sum(abs(x4 - y4), 5)

@test_approx_eq vdiffnorm(x3, y3, 1, (1, 2)) sum(abs(x3 - y3), (1, 2))
@test_approx_eq vdiffnorm(x3, y3, 1, (1, 3)) sum(abs(x3 - y3), (1, 3))
@test_approx_eq vdiffnorm(x3, y3, 1, (2, 3)) sum(abs(x3 - y3), (2, 3))

@test_approx_eq vdiffnorm(x1, y1, 2, 1) sqrt(sum(abs2(x1 - y1), 1))
@test_approx_eq vdiffnorm(x1, y1, 2, 2) sqrt(sum(abs2(x1 - y1), 2))
@test_approx_eq vdiffnorm(x2, y2, 2, 1) sqrt(sum(abs2(x2 - y2), 1))
@test_approx_eq vdiffnorm(x2, y2, 2, 2) sqrt(sum(abs2(x2 - y2), 2))
@test_approx_eq vdiffnorm(x2, y2, 2, 3) sqrt(sum(abs2(x2 - y2), 3))
@test_approx_eq vdiffnorm(x3, y3, 2, 1) sqrt(sum(abs2(x3 - y3), 1))
@test_approx_eq vdiffnorm(x3, y3, 2, 2) sqrt(sum(abs2(x3 - y3), 2))
@test_approx_eq vdiffnorm(x3, y3, 2, 3) sqrt(sum(abs2(x3 - y3), 3))
@test_approx_eq vdiffnorm(x3, y3, 2, 4) sqrt(sum(abs2(x3 - y3), 4))
@test_approx_eq vdiffnorm(x4, y4, 2, 1) sqrt(sum(abs2(x4 - y4), 1))
@test_approx_eq vdiffnorm(x4, y4, 2, 2) sqrt(sum(abs2(x4 - y4), 2))
@test_approx_eq vdiffnorm(x4, y4, 2, 3) sqrt(sum(abs2(x4 - y4), 3))
@test_approx_eq vdiffnorm(x4, y4, 2, 4) sqrt(sum(abs2(x4 - y4), 4))
@test_approx_eq vdiffnorm(x4, y4, 2, 5) sqrt(sum(abs2(x4 - y4), 5))

@test_approx_eq vdiffnorm(x3, y3, 2, (1, 2)) sqrt(sum(abs2(x3 - y3), (1, 2)))
@test_approx_eq vdiffnorm(x3, y3, 2, (1, 3)) sqrt(sum(abs2(x3 - y3), (1, 3)))
@test_approx_eq vdiffnorm(x3, y3, 2, (2, 3)) sqrt(sum(abs2(x3 - y3), (2, 3)))

@test_approx_eq vdiffnorm(x1, y1, Inf, 1) max(abs(x1 - y1), (), 1)
@test_approx_eq vdiffnorm(x1, y1, Inf, 2) max(abs(x1 - y1), (), 2)
@test_approx_eq vdiffnorm(x2, y2, Inf, 1) max(abs(x2 - y2), (), 1)
@test_approx_eq vdiffnorm(x2, y2, Inf, 2) max(abs(x2 - y2), (), 2)
@test_approx_eq vdiffnorm(x2, y2, Inf, 3) max(abs(x2 - y2), (), 3)
@test_approx_eq vdiffnorm(x3, y3, Inf, 1) max(abs(x3 - y3), (), 1)
@test_approx_eq vdiffnorm(x3, y3, Inf, 2) max(abs(x3 - y3), (), 2)
@test_approx_eq vdiffnorm(x3, y3, Inf, 3) max(abs(x3 - y3), (), 3)
@test_approx_eq vdiffnorm(x3, y3, Inf, 4) max(abs(x3 - y3), (), 4)
@test_approx_eq vdiffnorm(x4, y4, Inf, 1) max(abs(x4 - y4), (), 1)
@test_approx_eq vdiffnorm(x4, y4, Inf, 2) max(abs(x4 - y4), (), 2)
@test_approx_eq vdiffnorm(x4, y4, Inf, 3) max(abs(x4 - y4), (), 3)
@test_approx_eq vdiffnorm(x4, y4, Inf, 4) max(abs(x4 - y4), (), 4)
@test_approx_eq vdiffnorm(x4, y4, Inf, 5) max(abs(x4 - y4), (), 5)

@test_approx_eq vdiffnorm(x3, y3, Inf, (1, 2)) max(abs(x3 - y3), (), (1, 2))
@test_approx_eq vdiffnorm(x3, y3, Inf, (1, 3)) max(abs(x3 - y3), (), (1, 3))
@test_approx_eq vdiffnorm(x3, y3, Inf, (2, 3)) max(abs(x3 - y3), (), (2, 3))

@test_approx_eq vdiffnorm(x1, y1, 3, 1) sum(abs(x1 - y1).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x1, y1, 3, 2) sum(abs(x1 - y1).^3, 2).^(1/3)
@test_approx_eq vdiffnorm(x2, y2, 3, 1) sum(abs(x2 - y2).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x2, y2, 3, 2) sum(abs(x2 - y2).^3, 2).^(1/3)
@test_approx_eq vdiffnorm(x2, y2, 3, 3) sum(abs(x2 - y2).^3, 3).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 1) sum(abs(x3 - y3).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 2) sum(abs(x3 - y3).^3, 2).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 3) sum(abs(x3 - y3).^3, 3).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, 4) sum(abs(x3 - y3).^3, 4).^(1/3)
@test_approx_eq vdiffnorm(x4, y4, 3, 1) sum(abs(x4 - y4).^3, 1).^(1/3)
@test_approx_eq vdiffnorm(x4, y4, 3, 2) sum(abs(x4 - y4).^3, 2).^(1/3)
@test_approx_eq vdiffnorm(x4, y4, 3, 3) sum(abs(x4 - y4).^3, 3).^(1/3)
@test_approx_eq vdiffnorm(x4, y4, 3, 4) sum(abs(x4 - y4).^3, 4).^(1/3)
@test_approx_eq vdiffnorm(x4, y4, 3, 5) sum(abs(x4 - y4).^3, 5).^(1/3)

@test_approx_eq vdiffnorm(x3, y3, 3, (1, 2)) sum(abs(x3 - y3).^3, (1, 2)).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, (1, 3)) sum(abs(x3 - y3).^3, (1, 3)).^(1/3)
@test_approx_eq vdiffnorm(x3, y3, 3, (2, 3)) sum(abs(x3 - y3).^3, (2, 3)).^(1/3)




