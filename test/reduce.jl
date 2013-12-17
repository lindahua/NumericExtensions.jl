# Test reduction

using NumericExtensions
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

function safe_xreduce(op::Functor, x::Array, s0, dim::Int)
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

function safe_xreduce(op::Functor, x::Array, s0, dims::(Int, Int))
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
safe_max(x, dim::Union(Int, (Int, Int))) = safe_xreduce(MaxFun(), x, typemin(eltype(x)), dim)
safe_min(x, dim::Union(Int, (Int, Int))) = safe_xreduce(MinFun(), x, typemax(eltype(x)), dim)


### full reduction ###

x = randn(3, 4)
y = randn(3, 4)
z = randn(3, 4)
p = rand(3, 4)
q = rand(3, 4)

# foldl & foldr

@test foldl(Subtract(), 10, [4, 7, 9]) === (10 - 4 - 7 - 9)
@test foldr(Subtract(), 10, [4, 7, 9]) === 4 - (7 - (9 - 10))

@test foldl(Subtract(), [4, 7, 9]) === (4 - 7 - 9)
@test foldr(Subtract(), [4, 7, 9]) === (4 - (7 - 9))

# sum

@test sum(Bool[]) === 0
@test sum([false]) === 0
@test sum([true]) === 1 
@test sum([true, false, true]) === 2

@test sum(Int[]) === 0
@test sum([5]) === 5
@test sum([2, 3]) === 5
@test sum([2, 3, 4]) === 9
@test sum([2, 3, 4, 5]) === 14
@test sum([2, 3, 4, 5, 6, 7]) === 27

@test_approx_eq sum(x) safe_sum(x)

# mean

@test isnan(mean(Int[]))
@test isnan(mean(Float64[]))
@test mean([1, 2]) == 1.5

@test_approx_eq mean(x) safe_sum(x) / length(x)

# maximum & minimum

@test_throws maximum(Int[])
@test_throws minimum(Int[])

@test maximum([4, 5, 2, 3]) === 5
@test minimum([4, 5, 2, 3]) === 2

@test maximum([NaN, 3.0, NaN, 2.0, NaN]) === 3.0
@test minimum([NaN, 3.0, NaN, 2.0, NaN]) === 2.0

@test maximum(x) == safe_max(x)
@test minimum(x) == safe_min(x)


# @test_approx_eq sumabs(x) safe_sum(abs(x))
# @test_approx_eq maxabs(x) safe_max(abs(x))
# @test_approx_eq minabs(x) safe_min(abs(x))
# @test_approx_eq sumsq(x) safe_sum(abs2(x))

# @test_approx_eq dot(x, y) safe_sum(x .* y)
# @test_approx_eq sumabsdiff(x, y) safe_sum(abs(x - y))
# @test_approx_eq maxabsdiff(x, y) safe_max(abs(x - y))
# @test_approx_eq minabsdiff(x, y) safe_min(abs(x - y))
# @test_approx_eq sumsqdiff(x, y) safe_sum(abs2(x - y))

# @test_approx_eq sumabsdiff(x, 1.5) safe_sum(abs(x - 1.5))
# @test_approx_eq maxabsdiff(x, 1.5) safe_max(abs(x - 1.5))
# @test_approx_eq minabsdiff(x, 1.5) safe_min(abs(x - 1.5))
# @test_approx_eq sumsqdiff(x, 1.5) safe_sum(abs2(x - 1.5))

# @test_approx_eq mapreduce(Abs2Fun(), Add(), x) safe_sum(abs2(x))
# @test_approx_eq mapreduce(Multiply(), Add(), x, y) safe_sum(x .* y)
# @test_approx_eq mapdiff_reduce(Abs2Fun(), Add(), 2.3, x) safe_sum(abs2(2.3 - x))

# @test_approx_eq sumxlogx(p) sum(p .* log(p))
# @test_approx_eq sumxlogy(p, q) sum(p .* log(q))

# @test_approx_eq vnorm(x, 1) safe_sum(abs(x))
# @test_approx_eq vnorm(x, 2) sqrt(safe_sum(abs2(x)))
# @test_approx_eq vnorm(x, 3) safe_sum(abs(x) .^ 3) .^ (1/3)
# @test_approx_eq vnorm(x, Inf) safe_max(abs(x))

# @test_approx_eq vnormdiff(x, y, 1) safe_sum(abs(x - y))
# @test_approx_eq vnormdiff(x, y, 2) sqrt(safe_sum(abs2(x - y)))
# @test_approx_eq vnormdiff(x, y, 3) safe_sum(abs(x - y) .^ 3) .^ (1/3)
# @test_approx_eq vnormdiff(x, y, Inf) safe_max(abs(x - y))

# @test_approx_eq sum(FMA(), x, y, z) safe_sum(x + y .* z)
# @test_approx_eq sum(FMA(), x, y, 2.) safe_sum(x + y .* 2)
# @test_approx_eq sum(FMA(), x, 2., y) safe_sum(x + 2 .* y)
# @test_approx_eq sum(FMA(), 2., x, y) safe_sum(2. + x .* y)
# @test_approx_eq sum(FMA(), x, 2., 3.) safe_sum(x + 6.)
# @test_approx_eq sum(FMA(), 2., x, 3.) safe_sum(2. + x * 3.)
# @test_approx_eq sum(FMA(), 2., 3., x) safe_sum(2. + 3. * x)



### partial reduction ###

# x1 = randn(6)
# y1 = randn(6)
# z1 = randn(6)

# x2 = randn(5, 6)
# y2 = randn(5, 6)
# z2 = randn(5, 6)

# x3 = randn(3, 4, 5)
# y3 = randn(3, 4, 5)
# z3 = randn(3, 4, 5)

# x4 = randn(3, 4, 5, 2)
# y4 = randn(3, 4, 5, 2)
# z4 = randn(3, 4, 5, 2)

# p1 = rand(size(x1))
# p2 = rand(size(x2))
# q1 = rand(size(x1))
# q2 = rand(size(x2))

# # sum

# @test size(sum(x1, 1)) == rsize(x1, 1)
# @test size(sum(x1, 2)) == rsize(x1, 2)
# @test size(sum(x2, 1)) == rsize(x2, 1)
# @test size(sum(x2, 2)) == rsize(x2, 2)
# @test size(sum(x2, 3)) == rsize(x2, 3)
# @test size(sum(x3, 1)) == rsize(x3, 1)
# @test size(sum(x3, 2)) == rsize(x3, 2)
# @test size(sum(x3, 3)) == rsize(x3, 3)
# @test size(sum(x3, 4)) == rsize(x3, 4)
# @test size(sum(x4, 1)) == rsize(x4, 1)
# @test size(sum(x4, 2)) == rsize(x4, 2)
# @test size(sum(x4, 3)) == rsize(x4, 3)
# @test size(sum(x4, 4)) == rsize(x4, 4)
# @test size(sum(x4, 5)) == rsize(x4, 5)

# @test_approx_eq sum(x1, 1) safe_sum(x1, 1)
# @test_approx_eq sum(x1, 2) safe_sum(x1, 2)
# @test_approx_eq sum(x2, 1) safe_sum(x2, 1)
# @test_approx_eq sum(x2, 2) safe_sum(x2, 2)
# @test_approx_eq sum(x2, 3) safe_sum(x2, 3)
# @test_approx_eq sum(x3, 1) safe_sum(x3, 1)
# @test_approx_eq sum(x3, 2) safe_sum(x3, 2)
# @test_approx_eq sum(x3, 3) safe_sum(x3, 3)
# @test_approx_eq sum(x3, 4) safe_sum(x3, 4)
# @test_approx_eq sum(x4, 1) safe_sum(x4, 1)
# @test_approx_eq sum(x4, 2) safe_sum(x4, 2)
# @test_approx_eq sum(x4, 3) safe_sum(x4, 3)
# @test_approx_eq sum(x4, 4) safe_sum(x4, 4)
# @test_approx_eq sum(x4, 5) safe_sum(x4, 5)

# r = zeros(6); sum!(r, x2, 1)
# @test_approx_eq r vec(safe_sum(x2, 1))

# r = zeros(5); sum!(r, x2, 2)
# @test_approx_eq r vec(safe_sum(x2, 2))

# r = zeros(4, 5); sum!(r, x3, 1)
# @test_approx_eq r reshape(safe_sum(x3, 1), 4, 5)

# r = zeros(3, 5); sum!(r, x3, 2)
# @test_approx_eq r reshape(safe_sum(x3, 2), 3, 5)

# r = zeros(3, 4); sum!(r, x3, 3)
# @test_approx_eq r reshape(safe_sum(x3, 3), 3, 4)

# @test size(sum(x3, (1, 2))) == rsize(x3, (1, 2))
# @test size(sum(x3, (1, 3))) == rsize(x3, (1, 3))
# @test size(sum(x3, (2, 3))) == rsize(x3, (2, 3))

# @test_approx_eq sum(x3, (1, 2)) safe_sum(x3, (1, 2))
# @test_approx_eq sum(x3, (1, 3)) safe_sum(x3, (1, 3))
# @test_approx_eq sum(x3, (2, 3)) safe_sum(x3, (2, 3))

# r = zeros(5); sum!(r, x3, (1, 2))
# @test_approx_eq r vec(safe_sum(x3, (1, 2)))

# r = zeros(4); sum!(r, x3, (1, 3))
# @test_approx_eq r vec(safe_sum(x3, (1, 3)))

# r = zeros(3); sum!(r, x3, (2, 3))
# @test_approx_eq r vec(safe_sum(x3, (2, 3)))

# # sum over boolean arrays

# a = [true true false; false true false]
# @test sum(a) === 3
# @test eltype(sum(a, 1)) == Int
# @test sum(a, 1) == [1 2 0]
# @test eltype(sum(a, 2)) == Int
# @test sum(a, 2) == reshape([2, 1], 2, 1)

# # max

# @test_approx_eq maximum(x1, 1) safe_max(x1, 1)
# @test_approx_eq maximum(x1, 2) safe_max(x1, 2)
# @test_approx_eq maximum(x2, 1) safe_max(x2, 1)
# @test_approx_eq maximum(x2, 2) safe_max(x2, 2)
# @test_approx_eq maximum(x2, 3) safe_max(x2, 3)
# @test_approx_eq maximum(x3, 1) safe_max(x3, 1)
# @test_approx_eq maximum(x3, 2) safe_max(x3, 2)
# @test_approx_eq maximum(x3, 3) safe_max(x3, 3)
# @test_approx_eq maximum(x3, 4) safe_max(x3, 4)
# @test_approx_eq maximum(x4, 1) safe_max(x4, 1)
# @test_approx_eq maximum(x4, 2) safe_max(x4, 2)
# @test_approx_eq maximum(x4, 3) safe_max(x4, 3)
# @test_approx_eq maximum(x4, 4) safe_max(x4, 4)
# @test_approx_eq maximum(x4, 5) safe_max(x4, 5)

# @test_approx_eq maximum(x3, (1, 2)) safe_max(x3, (1, 2))
# @test_approx_eq maximum(x3, (1, 3)) safe_max(x3, (1, 3))
# @test_approx_eq maximum(x3, (2, 3)) safe_max(x3, (2, 3))

# # min

# @test_approx_eq minimum(x1, 1) safe_min(x1, 1)
# @test_approx_eq minimum(x1, 2) safe_min(x1, 2)
# @test_approx_eq minimum(x2, 1) safe_min(x2, 1)
# @test_approx_eq minimum(x2, 2) safe_min(x2, 2)
# @test_approx_eq minimum(x2, 3) safe_min(x2, 3)
# @test_approx_eq minimum(x3, 1) safe_min(x3, 1)
# @test_approx_eq minimum(x3, 2) safe_min(x3, 2)
# @test_approx_eq minimum(x3, 3) safe_min(x3, 3)
# @test_approx_eq minimum(x3, 4) safe_min(x3, 4)
# @test_approx_eq minimum(x4, 1) safe_min(x4, 1)
# @test_approx_eq minimum(x4, 2) safe_min(x4, 2)
# @test_approx_eq minimum(x4, 3) safe_min(x4, 3)
# @test_approx_eq minimum(x4, 4) safe_min(x4, 4)
# @test_approx_eq minimum(x4, 5) safe_min(x4, 5)

# @test_approx_eq minimum(x3, (1, 2)) safe_min(x3, (1, 2))
# @test_approx_eq minimum(x3, (1, 3)) safe_min(x3, (1, 3))
# @test_approx_eq minimum(x3, (2, 3)) safe_min(x3, (2, 3))

# # mapreduce

# @test_approx_eq mapreduce(Abs2Fun(), Add(), x2, 1) safe_sum(abs2(x2), 1)
# @test_approx_eq mapreduce(Multiply(), Add(), x2, y2, 1) safe_sum(x2 .* y2, 1)
# @test_approx_eq mapdiff_reduce(Abs2Fun(), Add(), x2, y2, 1) safe_sum(abs2(x2  - y2), 1)

# r = zeros(1, 6); mapreduce!(r, Abs2Fun(), Add(), x2, 1)
# @test_approx_eq r sum(abs2(x2), 1)

# r = zeros(1, 6); mapreduce!(r, Multiply(), Add(), x2, y2, 1)
# @test_approx_eq r sum(x2 .* y2, 1)

# r = zeros(1, 6); mapdiff_reduce!(r, Abs2Fun(), Add(), x2, y2, 1)
# @test_approx_eq r sum(abs2(x2 - y2), 1)


# # sumabs

# @test_approx_eq sumabs(x1, 1) sum(abs(x1), 1)
# @test_approx_eq sumabs(x1, 2) sum(abs(x1), 2)
# @test_approx_eq sumabs(x2, 1) sum(abs(x2), 1)
# @test_approx_eq sumabs(x2, 2) sum(abs(x2), 2)
# @test_approx_eq sumabs(x2, 3) sum(abs(x2), 3)
# @test_approx_eq sumabs(x3, 1) sum(abs(x3), 1)
# @test_approx_eq sumabs(x3, 2) sum(abs(x3), 2)
# @test_approx_eq sumabs(x3, 3) sum(abs(x3), 3)
# @test_approx_eq sumabs(x3, 4) sum(abs(x3), 4)
# @test_approx_eq sumabs(x4, 1) sum(abs(x4), 1)
# @test_approx_eq sumabs(x4, 2) sum(abs(x4), 2)
# @test_approx_eq sumabs(x4, 3) sum(abs(x4), 3)
# @test_approx_eq sumabs(x4, 4) sum(abs(x4), 4)
# @test_approx_eq sumabs(x4, 5) sum(abs(x4), 5)

# @test_approx_eq sumabs(x3, (1, 2)) sum(abs(x3), (1, 2))
# @test_approx_eq sumabs(x3, (1, 3)) sum(abs(x3), (1, 3))
# @test_approx_eq sumabs(x3, (2, 3)) sum(abs(x3), (2, 3))

# r = zeros(6); sumabs!(r, x2, 1)
# @test_approx_eq r vec(sum(abs(x2), 1))

# # maxabs

# @test_approx_eq maxabs(x1, 1) maximum(abs(x1), 1)
# @test_approx_eq maxabs(x2, 1) maximum(abs(x2), 1)
# @test_approx_eq maxabs(x2, 2) maximum(abs(x2), 2)
# @test_approx_eq maxabs(x3, 1) maximum(abs(x3), 1)
# @test_approx_eq maxabs(x3, 2) maximum(abs(x3), 2)
# @test_approx_eq maxabs(x3, 3) maximum(abs(x3), 3)

# # minabs

# @test_approx_eq minabs(x1, 1) minimum(abs(x1), 1)
# @test_approx_eq minabs(x2, 1) minimum(abs(x2), 1)
# @test_approx_eq minabs(x2, 2) minimum(abs(x2), 2)
# @test_approx_eq minabs(x3, 1) minimum(abs(x3), 1)
# @test_approx_eq minabs(x3, 2) minimum(abs(x3), 2)
# @test_approx_eq minabs(x3, 3) minimum(abs(x3), 3)

# # sumsq

# @test_approx_eq sumsq(x1, 1) sum(abs2(x1), 1)
# @test_approx_eq sumsq(x2, 1) sum(abs2(x2), 1)
# @test_approx_eq sumsq(x2, 2) sum(abs2(x2), 2)
# @test_approx_eq sumsq(x3, 1) sum(abs2(x3), 1)
# @test_approx_eq sumsq(x3, 2) sum(abs2(x3), 2)
# @test_approx_eq sumsq(x3, 3) sum(abs2(x3), 3)

# # dot

# @test_approx_eq dot(x1, y1, 1) sum(x1 .* y1, 1)
# @test_approx_eq dot(x1, y1, 2) sum(x1 .* y1, 2)
# @test_approx_eq dot(x2, y2, 1) sum(x2 .* y2, 1)
# @test_approx_eq dot(x2, y2, 2) sum(x2 .* y2, 2)
# @test_approx_eq dot(x2, y2, 3) sum(x2 .* y2, 3)
# @test_approx_eq dot(x3, y3, 1) sum(x3 .* y3, 1)
# @test_approx_eq dot(x3, y3, 2) sum(x3 .* y3, 2)
# @test_approx_eq dot(x3, y3, 3) sum(x3 .* y3, 3)
# @test_approx_eq dot(x3, y3, 4) sum(x3 .* y3, 4)
# @test_approx_eq dot(x4, y4, 1) sum(x4 .* y4, 1)
# @test_approx_eq dot(x4, y4, 2) sum(x4 .* y4, 2)
# @test_approx_eq dot(x4, y4, 3) sum(x4 .* y4, 3)
# @test_approx_eq dot(x4, y4, 4) sum(x4 .* y4, 4)
# @test_approx_eq dot(x4, y4, 5) sum(x4 .* y4, 5)

# @test_approx_eq dot(x3, y3, (1, 2)) sum(x3 .* y3, (1, 2))
# @test_approx_eq dot(x3, y3, (1, 3)) sum(x3 .* y3, (1, 3))
# @test_approx_eq dot(x3, y3, (2, 3)) sum(x3 .* y3, (2, 3))

# r = zeros(6); dot!(r, x2, y2, 1)
# @test_approx_eq r vec(sum(x2 .* y2, 1))

# # sumabsdiff

# @test_approx_eq sumabsdiff(x1, y1, 1) sum(abs(x1 - y1), 1)
# @test_approx_eq sumabsdiff(x1, y1, 2) sum(abs(x1 - y1), 2)
# @test_approx_eq sumabsdiff(x2, y2, 1) sum(abs(x2 - y2), 1)
# @test_approx_eq sumabsdiff(x2, y2, 2) sum(abs(x2 - y2), 2)
# @test_approx_eq sumabsdiff(x2, y2, 3) sum(abs(x2 - y2), 3)
# @test_approx_eq sumabsdiff(x3, y3, 1) sum(abs(x3 - y3), 1)
# @test_approx_eq sumabsdiff(x3, y3, 2) sum(abs(x3 - y3), 2)
# @test_approx_eq sumabsdiff(x3, y3, 3) sum(abs(x3 - y3), 3)
# @test_approx_eq sumabsdiff(x3, y3, 4) sum(abs(x3 - y3), 4)
# @test_approx_eq sumabsdiff(x4, y4, 1) sum(abs(x4 - y4), 1)
# @test_approx_eq sumabsdiff(x4, y4, 2) sum(abs(x4 - y4), 2)
# @test_approx_eq sumabsdiff(x4, y4, 3) sum(abs(x4 - y4), 3)
# @test_approx_eq sumabsdiff(x4, y4, 4) sum(abs(x4 - y4), 4)
# @test_approx_eq sumabsdiff(x4, y4, 5) sum(abs(x4 - y4), 5)

# @test_approx_eq sumabsdiff(x3, y3, (1, 2)) sum(abs(x3 - y3), (1, 2))
# @test_approx_eq sumabsdiff(x3, y3, (1, 3)) sum(abs(x3 - y3), (1, 3))
# @test_approx_eq sumabsdiff(x3, y3, (2, 3)) sum(abs(x3 - y3), (2, 3))

# r = zeros(6); sumabsdiff!(r, x2, y2, 1)
# @test_approx_eq r vec(sum(abs(x2 - y2), 1))

# # vdiffmax

# @test_approx_eq maxabsdiff(x1, y1, 1) maximum(abs(x1 - y1), 1)
# @test_approx_eq maxabsdiff(x2, y2, 1) maximum(abs(x2 - y2), 1)
# @test_approx_eq maxabsdiff(x2, y2, 2) maximum(abs(x2 - y2), 2)
# @test_approx_eq maxabsdiff(x3, y3, 1) maximum(abs(x3 - y3), 1)
# @test_approx_eq maxabsdiff(x3, y3, 2) maximum(abs(x3 - y3), 2)
# @test_approx_eq maxabsdiff(x3, y3, 3) maximum(abs(x3 - y3), 3)

# # vdiffmin

# @test_approx_eq minabsdiff(x1, y1, 1) minimum(abs(x1 - y1), 1)
# @test_approx_eq minabsdiff(x2, y2, 1) minimum(abs(x2 - y2), 1)
# @test_approx_eq minabsdiff(x2, y2, 2) minimum(abs(x2 - y2), 2)
# @test_approx_eq minabsdiff(x3, y3, 1) minimum(abs(x3 - y3), 1)
# @test_approx_eq minabsdiff(x3, y3, 2) minimum(abs(x3 - y3), 2)
# @test_approx_eq minabsdiff(x3, y3, 3) minimum(abs(x3 - y3), 3)

# # sumsqdiff

# @test_approx_eq sumsqdiff(x1, y1, 1) sum(abs2(x1 - y1), 1)
# @test_approx_eq sumsqdiff(x2, y2, 1) sum(abs2(x2 - y2), 1)
# @test_approx_eq sumsqdiff(x2, y2, 2) sum(abs2(x2 - y2), 2)
# @test_approx_eq sumsqdiff(x3, y3, 1) sum(abs2(x3 - y3), 1)
# @test_approx_eq sumsqdiff(x3, y3, 2) sum(abs2(x3 - y3), 2)
# @test_approx_eq sumsqdiff(x3, y3, 3) sum(abs2(x3 - y3), 3)

# # reduce on fma

# @test_approx_eq sum(FMA(), x1, y1, z1, 1) sum(x1 + y1 .* z1, 1)
# @test_approx_eq sum(FMA(), x2, y2, z2, 1) sum(x2 + y2 .* z2, 1)
# @test_approx_eq sum(FMA(), x2, y2, z2, 2) sum(x2 + y2 .* z2, 2)
# @test_approx_eq sum(FMA(), x3, y3, z3, 1) sum(x3 + y3 .* z3, 1)
# @test_approx_eq sum(FMA(), x3, y3, z3, 2) sum(x3 + y3 .* z3, 2)
# @test_approx_eq sum(FMA(), x3, y3, z3, 3) sum(x3 + y3 .* z3, 3)

# # entropy

# @test_approx_eq sumxlogx(p1, 1) sum(p1 .* log(p1), 1)
# @test_approx_eq sumxlogx(p2, 1) sum(p2 .* log(p2), 1)
# @test_approx_eq sumxlogx(p2, 2) sum(p2 .* log(p2), 2)

# @test_approx_eq sumxlogy(p1, q1, 1) sum(p1 .* log(q1), 1)
# @test_approx_eq sumxlogy(p2, q2, 1) sum(p2 .* log(q2), 1)
# @test_approx_eq sumxlogy(p2, q2, 2) sum(p2 .* log(q2), 2)


