using NumericExtensions
using Base.Test

## Testing of reduced shape & length

reduced_shape = NumericExtensions.reduced_shape
reduced_length = NumericExtensions.reduced_length

# reduced_shape

@test reduced_shape((5,), 1) == (1,)
@test_throws reduced_shape((5,), 2)

@test reduced_shape((3, 4), 1) == (1, 4)
@test reduced_shape((3, 4), 2) == (3, 1)
@test_throws reduced_shape((3, 4), 3)

@test reduced_shape((3, 4, 5), 1) == (1, 4, 5)
@test reduced_shape((3, 4, 5), 2) == (3, 1, 5)
@test reduced_shape((3, 4, 5), 3) == (3, 4, 1)
@test_throws reduced_shape((3, 4, 5), 4)

@test reduced_shape((3, 4, 5, 6), 1) == (1, 4, 5, 6)
@test reduced_shape((3, 4, 5, 6), 2) == (3, 1, 5, 6)
@test reduced_shape((3, 4, 5, 6), 3) == (3, 4, 1, 6)
@test reduced_shape((3, 4, 5, 6), 4) == (3, 4, 5, 1)
@test_throws reduced_shape((3, 4, 5, 6), 5)

# reduced_length

@test reduced_length((5,), 1) == 1
@test_throws reduced_length((5,), 2)

@test reduced_length((3, 4), 1) == 4
@test reduced_length((3, 4), 2) == 3
@test_throws reduced_length((3, 4), 3)

@test reduced_length((3, 4, 5), 1) == 20
@test reduced_length((3, 4, 5), 2) == 15
@test reduced_length((3, 4, 5), 3) == 12
@test_throws reduced_length((3, 4, 5), 4)

@test reduced_length((3, 4, 5, 6), 1) == 120
@test reduced_length((3, 4, 5, 6), 2) == 90
@test reduced_length((3, 4, 5, 6), 3) == 72
@test reduced_length((3, 4, 5, 6), 4) == 60
@test_throws reduced_length((3, 4, 5, 6), 5)


## Testing of reducedim functions 

a1 = 2 * rand(6) - 1.0
a2 = 2 * rand(5, 6) - 1.0
a3 = 2 * rand(5, 4, 3) - 1.0
a4 = 2 * rand(5, 4, 3, 2) - 1.0

b1 = 2 * rand(6) - 1.0
b2 = 2 * rand(5, 6) - 1.0
b3 = 2 * rand(5, 4, 3) - 1.0
b4 = 2 * rand(5, 4, 3, 2) - 1.0

p1 = rand(6)
p2 = rand(5, 6)
p3 = rand(5, 4, 3)
p4 = rand(5, 4, 3, 2)

q1 = rand(6)
q2 = rand(5, 6)
q3 = rand(5, 4, 3)
q4 = rand(5, 4, 3, 2)

# auxiliary

function safe_sumdim(a::Array, dim::Int)
	n = size(a, dim)
	s = slicedim(a, dim, 1)
	for i = 2 : n
		s += slicedim(a, dim, i)
	end
	return s
end

do_sum!(a::Array, dim::Int) = sum!(zeros(reduced_shape(size(a), dim)), a, dim)

safe_meandim(a::Array, dim::Int) = safe_sumdim(a, dim) / size(a, dim)

do_mean!(a::Array, dim::Int) = mean!(zeros(reduced_shape(size(a), dim)), a, dim)

function safe_maximumdim(a::Array, dim::Int)
	n = size(a, dim)
	s = slicedim(a, dim, 1)
	for i = 2 : n
		s = max(s, slicedim(a, dim, i))
	end
	return s
end

function safe_minimumdim(a::Array, dim::Int)
	n = size(a, dim)
	s = slicedim(a, dim, 1)
	for i = 2 : n
		s = min(s, slicedim(a, dim, i))
	end
	return s
end

do_maximum!(a::Array, dim::Int) = maximum!(zeros(reduced_shape(size(a), dim)), a, dim)
do_minimum!(a::Array, dim::Int) = minimum!(zeros(reduced_shape(size(a), dim)), a, dim)


# testing sum

@test_approx_eq sum(a1, 1) safe_sumdim(a1, 1)

@test_approx_eq sum(a2, 1) safe_sumdim(a2, 1)
@test_approx_eq sum(a2, 2) safe_sumdim(a2, 2)

@test_approx_eq sum(a3, 1) safe_sumdim(a3, 1)
@test_approx_eq sum(a3, 2) safe_sumdim(a3, 2)
@test_approx_eq sum(a3, 3) safe_sumdim(a3, 3)

@test_approx_eq sum(a4, 1) safe_sumdim(a4, 1)
@test_approx_eq sum(a4, 2) safe_sumdim(a4, 2)
@test_approx_eq sum(a4, 3) safe_sumdim(a4, 3)
@test_approx_eq sum(a4, 4) safe_sumdim(a4, 4)

# testing sum!

@test_approx_eq do_sum!(a1, 1) safe_sumdim(a1, 1)

@test_approx_eq do_sum!(a2, 1) safe_sumdim(a2, 1)
@test_approx_eq do_sum!(a2, 2) safe_sumdim(a2, 2)

@test_approx_eq do_sum!(a3, 1) safe_sumdim(a3, 1)
@test_approx_eq do_sum!(a3, 2) safe_sumdim(a3, 2)
@test_approx_eq do_sum!(a3, 3) safe_sumdim(a3, 3)

@test_approx_eq do_sum!(a4, 1) safe_sumdim(a4, 1)
@test_approx_eq do_sum!(a4, 2) safe_sumdim(a4, 2)
@test_approx_eq do_sum!(a4, 3) safe_sumdim(a4, 3)
@test_approx_eq do_sum!(a4, 4) safe_sumdim(a4, 4)

# testing mean

@test_approx_eq mean(a1, 1) safe_meandim(a1, 1)

@test_approx_eq mean(a2, 1) safe_meandim(a2, 1)
@test_approx_eq mean(a2, 2) safe_meandim(a2, 2)

@test_approx_eq mean(a3, 1) safe_meandim(a3, 1)
@test_approx_eq mean(a3, 2) safe_meandim(a3, 2)
@test_approx_eq mean(a3, 3) safe_meandim(a3, 3)

@test_approx_eq mean(a4, 1) safe_meandim(a4, 1)
@test_approx_eq mean(a4, 2) safe_meandim(a4, 2)
@test_approx_eq mean(a4, 3) safe_meandim(a4, 3)
@test_approx_eq mean(a4, 4) safe_meandim(a4, 4)

# testing mean!

@test_approx_eq do_mean!(a1, 1) safe_meandim(a1, 1)

@test_approx_eq do_mean!(a2, 1) safe_meandim(a2, 1)
@test_approx_eq do_mean!(a2, 2) safe_meandim(a2, 2)

@test_approx_eq do_mean!(a3, 1) safe_meandim(a3, 1)
@test_approx_eq do_mean!(a3, 2) safe_meandim(a3, 2)
@test_approx_eq do_mean!(a3, 3) safe_meandim(a3, 3)

@test_approx_eq do_mean!(a4, 1) safe_meandim(a4, 1)
@test_approx_eq do_mean!(a4, 2) safe_meandim(a4, 2)
@test_approx_eq do_mean!(a4, 3) safe_meandim(a4, 3)
@test_approx_eq do_mean!(a4, 4) safe_meandim(a4, 4)

# testing maximum

@test_approx_eq maximum(a1, 1) safe_maximumdim(a1, 1)

@test_approx_eq maximum(a2, 1) safe_maximumdim(a2, 1)
@test_approx_eq maximum(a2, 2) safe_maximumdim(a2, 2)

@test_approx_eq maximum(a3, 1) safe_maximumdim(a3, 1)
@test_approx_eq maximum(a3, 2) safe_maximumdim(a3, 2)
@test_approx_eq maximum(a3, 3) safe_maximumdim(a3, 3)

@test_approx_eq maximum(a4, 1) safe_maximumdim(a4, 1)
@test_approx_eq maximum(a4, 2) safe_maximumdim(a4, 2)
@test_approx_eq maximum(a4, 3) safe_maximumdim(a4, 3)
@test_approx_eq maximum(a4, 4) safe_maximumdim(a4, 4)

# testing maximum!

@test_approx_eq do_maximum!(a1, 1) safe_maximumdim(a1, 1)

@test_approx_eq do_maximum!(a2, 1) safe_maximumdim(a2, 1)
@test_approx_eq do_maximum!(a2, 2) safe_maximumdim(a2, 2)

@test_approx_eq do_maximum!(a3, 1) safe_maximumdim(a3, 1)
@test_approx_eq do_maximum!(a3, 2) safe_maximumdim(a3, 2)
@test_approx_eq do_maximum!(a3, 3) safe_maximumdim(a3, 3)

@test_approx_eq do_maximum!(a4, 1) safe_maximumdim(a4, 1)
@test_approx_eq do_maximum!(a4, 2) safe_maximumdim(a4, 2)
@test_approx_eq do_maximum!(a4, 3) safe_maximumdim(a4, 3)
@test_approx_eq do_maximum!(a4, 4) safe_maximumdim(a4, 4)

# testing minimum

@test_approx_eq minimum(a1, 1) safe_minimumdim(a1, 1)

@test_approx_eq minimum(a2, 1) safe_minimumdim(a2, 1)
@test_approx_eq minimum(a2, 2) safe_minimumdim(a2, 2)

@test_approx_eq minimum(a3, 1) safe_minimumdim(a3, 1)
@test_approx_eq minimum(a3, 2) safe_minimumdim(a3, 2)
@test_approx_eq minimum(a3, 3) safe_minimumdim(a3, 3)

@test_approx_eq minimum(a4, 1) safe_minimumdim(a4, 1)
@test_approx_eq minimum(a4, 2) safe_minimumdim(a4, 2)
@test_approx_eq minimum(a4, 3) safe_minimumdim(a4, 3)
@test_approx_eq minimum(a4, 4) safe_minimumdim(a4, 4)

# testing minimum!

@test_approx_eq do_minimum!(a1, 1) safe_minimumdim(a1, 1)

@test_approx_eq do_minimum!(a2, 1) safe_minimumdim(a2, 1)
@test_approx_eq do_minimum!(a2, 2) safe_minimumdim(a2, 2)

@test_approx_eq do_minimum!(a3, 1) safe_minimumdim(a3, 1)
@test_approx_eq do_minimum!(a3, 2) safe_minimumdim(a3, 2)
@test_approx_eq do_minimum!(a3, 3) safe_minimumdim(a3, 3)

@test_approx_eq do_minimum!(a4, 1) safe_minimumdim(a4, 1)
@test_approx_eq do_minimum!(a4, 2) safe_minimumdim(a4, 2)
@test_approx_eq do_minimum!(a4, 3) safe_minimumdim(a4, 3)
@test_approx_eq do_minimum!(a4, 4) safe_minimumdim(a4, 4)


# testing sumabs

@test_approx_eq sumabs(a1, 1) sum(abs(a1), 1)

@test_approx_eq sumabs(a2, 1) sum(abs(a2), 1)
@test_approx_eq sumabs(a2, 2) sum(abs(a2), 2)

@test_approx_eq sumabs(a3, 1) sum(abs(a3), 1)
@test_approx_eq sumabs(a3, 2) sum(abs(a3), 2)
@test_approx_eq sumabs(a3, 3) sum(abs(a3), 3)

@test_approx_eq sumabs(a4, 1) sum(abs(a4), 1)
@test_approx_eq sumabs(a4, 2) sum(abs(a4), 2)
@test_approx_eq sumabs(a4, 3) sum(abs(a4), 3)
@test_approx_eq sumabs(a4, 4) sum(abs(a4), 4)

# testing meanabs

@test_approx_eq meanabs(a1, 1) mean(abs(a1), 1)

@test_approx_eq meanabs(a2, 1) mean(abs(a2), 1)
@test_approx_eq meanabs(a2, 2) mean(abs(a2), 2)

@test_approx_eq meanabs(a3, 1) mean(abs(a3), 1)
@test_approx_eq meanabs(a3, 2) mean(abs(a3), 2)
@test_approx_eq meanabs(a3, 3) mean(abs(a3), 3)

@test_approx_eq meanabs(a4, 1) mean(abs(a4), 1)
@test_approx_eq meanabs(a4, 2) mean(abs(a4), 2)
@test_approx_eq meanabs(a4, 3) mean(abs(a4), 3)
@test_approx_eq meanabs(a4, 4) mean(abs(a4), 4)

# testing maxabs

@test_approx_eq maxabs(a1, 1) maximum(abs(a1), 1)

@test_approx_eq maxabs(a2, 1) maximum(abs(a2), 1)
@test_approx_eq maxabs(a2, 2) maximum(abs(a2), 2)

@test_approx_eq maxabs(a3, 1) maximum(abs(a3), 1)
@test_approx_eq maxabs(a3, 2) maximum(abs(a3), 2)
@test_approx_eq maxabs(a3, 3) maximum(abs(a3), 3)

@test_approx_eq maxabs(a4, 1) maximum(abs(a4), 1)
@test_approx_eq maxabs(a4, 2) maximum(abs(a4), 2)
@test_approx_eq maxabs(a4, 3) maximum(abs(a4), 3)
@test_approx_eq maxabs(a4, 4) maximum(abs(a4), 4)

# testing minabs

@test_approx_eq minabs(a1, 1) minimum(abs(a1), 1)

@test_approx_eq minabs(a2, 1) minimum(abs(a2), 1)
@test_approx_eq minabs(a2, 2) minimum(abs(a2), 2)

@test_approx_eq minabs(a3, 1) minimum(abs(a3), 1)
@test_approx_eq minabs(a3, 2) minimum(abs(a3), 2)
@test_approx_eq minabs(a3, 3) minimum(abs(a3), 3)

@test_approx_eq minabs(a4, 1) minimum(abs(a4), 1)
@test_approx_eq minabs(a4, 2) minimum(abs(a4), 2)
@test_approx_eq minabs(a4, 3) minimum(abs(a4), 3)
@test_approx_eq minabs(a4, 4) minimum(abs(a4), 4)


# testing sumsq

@test_approx_eq sumsq(a1, 1) sum(abs2(a1), 1)

@test_approx_eq sumsq(a2, 1) sum(abs2(a2), 1)
@test_approx_eq sumsq(a2, 2) sum(abs2(a2), 2)

@test_approx_eq sumsq(a3, 1) sum(abs2(a3), 1)
@test_approx_eq sumsq(a3, 2) sum(abs2(a3), 2)
@test_approx_eq sumsq(a3, 3) sum(abs2(a3), 3)

@test_approx_eq sumsq(a4, 1) sum(abs2(a4), 1)
@test_approx_eq sumsq(a4, 2) sum(abs2(a4), 2)
@test_approx_eq sumsq(a4, 3) sum(abs2(a4), 3)
@test_approx_eq sumsq(a4, 4) sum(abs2(a4), 4)

# testing meansq

@test_approx_eq meansq(a1, 1) mean(abs2(a1), 1)

@test_approx_eq meansq(a2, 1) mean(abs2(a2), 1)
@test_approx_eq meansq(a2, 2) mean(abs2(a2), 2)

@test_approx_eq meansq(a3, 1) mean(abs2(a3), 1)
@test_approx_eq meansq(a3, 2) mean(abs2(a3), 2)
@test_approx_eq meansq(a3, 3) mean(abs2(a3), 3)

@test_approx_eq meansq(a4, 1) mean(abs2(a4), 1)
@test_approx_eq meansq(a4, 2) mean(abs2(a4), 2)
@test_approx_eq meansq(a4, 3) mean(abs2(a4), 3)
@test_approx_eq meansq(a4, 4) mean(abs2(a4), 4)

# testing sumabsdiff

@test_approx_eq sumabsdiff(a1, b1, 1) sum(abs(a1 - b1), 1)

@test_approx_eq sumabsdiff(a2, b2, 1) sum(abs(a2 - b2), 1)
@test_approx_eq sumabsdiff(a2, b2, 2) sum(abs(a2 - b2), 2)

@test_approx_eq sumabsdiff(a3, b3, 1) sum(abs(a3 - b3), 1)
@test_approx_eq sumabsdiff(a3, b3, 2) sum(abs(a3 - b3), 2)
@test_approx_eq sumabsdiff(a3, b3, 3) sum(abs(a3 - b3), 3)

@test_approx_eq sumabsdiff(a4, b4, 1) sum(abs(a4 - b4), 1)
@test_approx_eq sumabsdiff(a4, b4, 2) sum(abs(a4 - b4), 2)
@test_approx_eq sumabsdiff(a4, b4, 3) sum(abs(a4 - b4), 3)
@test_approx_eq sumabsdiff(a4, b4, 4) sum(abs(a4 - b4), 4)


@test_approx_eq sumabsdiff(a1, 0.5, 1) sum(abs(a1 - 0.5), 1)

@test_approx_eq sumabsdiff(a2, 0.5, 1) sum(abs(a2 - 0.5), 1)
@test_approx_eq sumabsdiff(a2, 0.5, 2) sum(abs(a2 - 0.5), 2)

@test_approx_eq sumabsdiff(a3, 0.5, 1) sum(abs(a3 - 0.5), 1)
@test_approx_eq sumabsdiff(a3, 0.5, 2) sum(abs(a3 - 0.5), 2)
@test_approx_eq sumabsdiff(a3, 0.5, 3) sum(abs(a3 - 0.5), 3)

@test_approx_eq sumabsdiff(a4, 0.5, 1) sum(abs(a4 - 0.5), 1)
@test_approx_eq sumabsdiff(a4, 0.5, 2) sum(abs(a4 - 0.5), 2)
@test_approx_eq sumabsdiff(a4, 0.5, 3) sum(abs(a4 - 0.5), 3)
@test_approx_eq sumabsdiff(a4, 0.5, 4) sum(abs(a4 - 0.5), 4)


@test_approx_eq sumabsdiff(0.5, b1, 1) sum(abs(0.5 - b1), 1)

@test_approx_eq sumabsdiff(0.5, b2, 1) sum(abs(0.5 - b2), 1)
@test_approx_eq sumabsdiff(0.5, b2, 2) sum(abs(0.5 - b2), 2)

@test_approx_eq sumabsdiff(0.5, b3, 1) sum(abs(0.5 - b3), 1)
@test_approx_eq sumabsdiff(0.5, b3, 2) sum(abs(0.5 - b3), 2)
@test_approx_eq sumabsdiff(0.5, b3, 3) sum(abs(0.5 - b3), 3)

@test_approx_eq sumabsdiff(0.5, b4, 1) sum(abs(0.5 - b4), 1)
@test_approx_eq sumabsdiff(0.5, b4, 2) sum(abs(0.5 - b4), 2)
@test_approx_eq sumabsdiff(0.5, b4, 3) sum(abs(0.5 - b4), 3)
@test_approx_eq sumabsdiff(0.5, b4, 4) sum(abs(0.5 - b4), 4)


# testing sumsqdiff

@test_approx_eq sumsqdiff(a1, b1, 1) sum(abs2(a1 - b1), 1)

@test_approx_eq sumsqdiff(a2, b2, 1) sum(abs2(a2 - b2), 1)
@test_approx_eq sumsqdiff(a2, b2, 2) sum(abs2(a2 - b2), 2)

@test_approx_eq sumsqdiff(a3, b3, 1) sum(abs2(a3 - b3), 1)
@test_approx_eq sumsqdiff(a3, b3, 2) sum(abs2(a3 - b3), 2)
@test_approx_eq sumsqdiff(a3, b3, 3) sum(abs2(a3 - b3), 3)

@test_approx_eq sumsqdiff(a4, b4, 1) sum(abs2(a4 - b4), 1)
@test_approx_eq sumsqdiff(a4, b4, 2) sum(abs2(a4 - b4), 2)
@test_approx_eq sumsqdiff(a4, b4, 3) sum(abs2(a4 - b4), 3)
@test_approx_eq sumsqdiff(a4, b4, 4) sum(abs2(a4 - b4), 4)

# testing maxabsdiff

@test_approx_eq maxabsdiff(a1, b1, 1) maximum(abs(a1 - b1), 1)

@test_approx_eq maxabsdiff(a2, b2, 1) maximum(abs(a2 - b2), 1)
@test_approx_eq maxabsdiff(a2, b2, 2) maximum(abs(a2 - b2), 2)

@test_approx_eq maxabsdiff(a3, b3, 1) maximum(abs(a3 - b3), 1)
@test_approx_eq maxabsdiff(a3, b3, 2) maximum(abs(a3 - b3), 2)
@test_approx_eq maxabsdiff(a3, b3, 3) maximum(abs(a3 - b3), 3)

@test_approx_eq maxabsdiff(a4, b4, 1) maximum(abs(a4 - b4), 1)
@test_approx_eq maxabsdiff(a4, b4, 2) maximum(abs(a4 - b4), 2)
@test_approx_eq maxabsdiff(a4, b4, 3) maximum(abs(a4 - b4), 3)
@test_approx_eq maxabsdiff(a4, b4, 4) maximum(abs(a4 - b4), 4)

# testing minabsdiff

@test_approx_eq minabsdiff(a1, b1, 1) minimum(abs(a1 - b1), 1)

@test_approx_eq minabsdiff(a2, b2, 1) minimum(abs(a2 - b2), 1)
@test_approx_eq minabsdiff(a2, b2, 2) minimum(abs(a2 - b2), 2)

@test_approx_eq minabsdiff(a3, b3, 1) minimum(abs(a3 - b3), 1)
@test_approx_eq minabsdiff(a3, b3, 2) minimum(abs(a3 - b3), 2)
@test_approx_eq minabsdiff(a3, b3, 3) minimum(abs(a3 - b3), 3)

@test_approx_eq minabsdiff(a4, b4, 1) minimum(abs(a4 - b4), 1)
@test_approx_eq minabsdiff(a4, b4, 2) minimum(abs(a4 - b4), 2)
@test_approx_eq minabsdiff(a4, b4, 3) minimum(abs(a4 - b4), 3)
@test_approx_eq minabsdiff(a4, b4, 4) minimum(abs(a4 - b4), 4)

# testing meanabsdiff

@test_approx_eq meanabsdiff(a1, b1, 1) mean(abs(a1 - b1), 1)

@test_approx_eq meanabsdiff(a2, b2, 1) mean(abs(a2 - b2), 1)
@test_approx_eq meanabsdiff(a2, b2, 2) mean(abs(a2 - b2), 2)

@test_approx_eq meanabsdiff(a3, b3, 1) mean(abs(a3 - b3), 1)
@test_approx_eq meanabsdiff(a3, b3, 2) mean(abs(a3 - b3), 2)
@test_approx_eq meanabsdiff(a3, b3, 3) mean(abs(a3 - b3), 3)

@test_approx_eq meanabsdiff(a4, b4, 1) mean(abs(a4 - b4), 1)
@test_approx_eq meanabsdiff(a4, b4, 2) mean(abs(a4 - b4), 2)
@test_approx_eq meanabsdiff(a4, b4, 3) mean(abs(a4 - b4), 3)
@test_approx_eq meanabsdiff(a4, b4, 4) mean(abs(a4 - b4), 4)

# testing meansqdiff

@test_approx_eq meansqdiff(a1, b1, 1) mean(abs2(a1 - b1), 1)

@test_approx_eq meansqdiff(a2, b2, 1) mean(abs2(a2 - b2), 1)
@test_approx_eq meansqdiff(a2, b2, 2) mean(abs2(a2 - b2), 2)

@test_approx_eq meansqdiff(a3, b3, 1) mean(abs2(a3 - b3), 1)
@test_approx_eq meansqdiff(a3, b3, 2) mean(abs2(a3 - b3), 2)
@test_approx_eq meansqdiff(a3, b3, 3) mean(abs2(a3 - b3), 3)

@test_approx_eq meansqdiff(a4, b4, 1) mean(abs2(a4 - b4), 1)
@test_approx_eq meansqdiff(a4, b4, 2) mean(abs2(a4 - b4), 2)
@test_approx_eq meansqdiff(a4, b4, 3) mean(abs2(a4 - b4), 3)
@test_approx_eq meansqdiff(a4, b4, 4) mean(abs2(a4 - b4), 4)


# testing dot

@test_approx_eq dot(a1, b1, 1) sum(a1 .* b1, 1)

@test_approx_eq dot(a2, b2, 1) sum(a2 .* b2, 1)
@test_approx_eq dot(a2, b2, 2) sum(a2 .* b2, 2)

@test_approx_eq dot(a3, b3, 1) sum(a3 .* b3, 1)
@test_approx_eq dot(a3, b3, 2) sum(a3 .* b3, 2)
@test_approx_eq dot(a3, b3, 3) sum(a3 .* b3, 3)

@test_approx_eq dot(a4, b4, 1) sum(a4 .* b4, 1)
@test_approx_eq dot(a4, b4, 2) sum(a4 .* b4, 2)
@test_approx_eq dot(a4, b4, 3) sum(a4 .* b4, 3)
@test_approx_eq dot(a4, b4, 4) sum(a4 .* b4, 4)

# testing sumxlogx

@test_approx_eq sumxlogx(p1, 1) sum(p1 .* log(p1), 1)

@test_approx_eq sumxlogx(p2, 1) sum(p2 .* log(p2), 1)
@test_approx_eq sumxlogx(p2, 2) sum(p2 .* log(p2), 2)

@test_approx_eq sumxlogx(p3, 1) sum(p3 .* log(p3), 1)
@test_approx_eq sumxlogx(p3, 2) sum(p3 .* log(p3), 2)
@test_approx_eq sumxlogx(p3, 3) sum(p3 .* log(p3), 3)

@test_approx_eq sumxlogx(p4, 1) sum(p4 .* log(p4), 1)
@test_approx_eq sumxlogx(p4, 2) sum(p4 .* log(p4), 2)
@test_approx_eq sumxlogx(p4, 3) sum(p4 .* log(p4), 3)
@test_approx_eq sumxlogx(p4, 4) sum(p4 .* log(p4), 4)

# testing sumxlogy

@test_approx_eq sumxlogy(p1, q1, 1) sum(p1 .* log(q1), 1)

@test_approx_eq sumxlogy(p2, q2, 1) sum(p2 .* log(q2), 1)
@test_approx_eq sumxlogy(p2, q2, 2) sum(p2 .* log(q2), 2)

@test_approx_eq sumxlogy(p3, q3, 1) sum(p3 .* log(q3), 1)
@test_approx_eq sumxlogy(p3, q3, 2) sum(p3 .* log(q3), 2)
@test_approx_eq sumxlogy(p3, q3, 3) sum(p3 .* log(q3), 3)

@test_approx_eq sumxlogy(p4, q4, 1) sum(p4 .* log(q4), 1)
@test_approx_eq sumxlogy(p4, q4, 2) sum(p4 .* log(q4), 2)
@test_approx_eq sumxlogy(p4, q4, 3) sum(p4 .* log(q4), 3)
@test_approx_eq sumxlogy(p4, q4, 4) sum(p4 .* log(q4), 4)

# testing entropy

@test_approx_eq entropy(p1, 1) sum(-p1 .* log(p1), 1)

@test_approx_eq entropy(p2, 1) sum(-p2 .* log(p2), 1)
@test_approx_eq entropy(p2, 2) sum(-p2 .* log(p2), 2)

@test_approx_eq entropy(p3, 1) sum(-p3 .* log(p3), 1)
@test_approx_eq entropy(p3, 2) sum(-p3 .* log(p3), 2)
@test_approx_eq entropy(p3, 3) sum(-p3 .* log(p3), 3)

@test_approx_eq entropy(p4, 1) sum(-p4 .* log(p4), 1)
@test_approx_eq entropy(p4, 2) sum(-p4 .* log(p4), 2)
@test_approx_eq entropy(p4, 3) sum(-p4 .* log(p4), 3)
@test_approx_eq entropy(p4, 4) sum(-p4 .* log(p4), 4)


