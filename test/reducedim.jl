using ArrayViews
using NumericExtensions
using Base.Test


## Data preparation

a1 = 2 * rand(8) - 1.0
a2 = 2 * rand(8, 7) - 1.0
a3 = 2 * rand(8, 7, 6) - 1.0
a4 = 2 * rand(8, 7, 6, 5) - 1.0

b1 = 2 * rand(8) - 1.0
b2 = 2 * rand(8, 7) - 1.0
b3 = 2 * rand(8, 7, 6) - 1.0
b4 = 2 * rand(8, 7, 6, 5) - 1.0

ua1 = view(a1, 1:6)
ub1 = view(b1, 2:7)
va1 = view(a1, 1:2:7)
vb1 = view(b1, 3:1:6)

ua2 = view(a2, 1:6, 1:5)
ub2 = view(b2, 2:7, 2:6)
va2 = view(a2, 1:2:7, 1:5)
vb2 = view(b2, 3:1:6, 2:6)

ua3 = view(a3, 1:6, 1:5, 1:3)
ub3 = view(b3, 2:7, 2:6, 3:5)
va3 = view(a3, 1:2:7, 1:5, 1:3)
vb3 = view(b3, 3:1:6, 2:6, 3:5)

ua4 = view(a4, 1:6, 1:5, 1:3, 1:4)
ub4 = view(b4, 2:7, 2:6, 3:5, 2:5)
va4 = view(a4, 1:2:7, 1:5, 1:3, 1:4)
vb4 = view(b4, 3:1:6, 2:6, 3:5, 2:5)

p1 = rand(8)
p2 = rand(8, 7)
p3 = rand(8, 7, 6)
p4 = rand(8, 7, 6, 5)

q1 = rand(8)
q2 = rand(8, 7)
q3 = rand(8, 7, 6)
q4 = rand(8, 7, 6, 5)

arrs_a = {a1, a2, a3, a4, ua1, va1, ua2, va2, ua3, va3, ua4, va4}
arrs_b = {b1, b2, b3, b4, ub1, vb1, ub2, vb2, ub3, vb3, ub4, vb4}
arrs_p = {p1, p2, p3, p4}
arrs_q = {q1, q2, q3, q4}

tdims = {
    {1},   # N = 1
    {1, 2, (1, 2)}, # N = 2
    {1, 2, 3, (1, 2), (1, 3), (2, 3), (1, 2, 3)}, # N = 3
    {1, 2, 3, 4, (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4), 
     (1, 2, 3), (1, 2, 4), (1, 3, 4), (2, 3, 4), (1, 2, 3, 4)} # N = 4
}



# auxiliary

safe_sumdim(a::DenseArray, reg) = invoke(sum, (AbstractArray{Float64}, Any), copy(a), reg)
safe_maxdim(a::DenseArray, reg) = invoke(maximum, (AbstractArray{Float64}, Any), copy(a), reg)
safe_mindim(a::DenseArray, reg) = invoke(minimum, (AbstractArray{Float64}, Any), copy(a), reg)
safe_meandim(a::DenseArray, reg) = invoke(mean, (AbstractArray{Float64}, Any), copy(a), reg)

do_sum(a::DenseArray, reg) = sum!(zeros(Base.reduced_dims(size(a), reg)), a, reg)
do_maximum(a::DenseArray, reg) = maximum!(fill(-Inf, Base.reduced_dims(size(a), reg)), a, reg)
do_minimum(a::DenseArray, reg) = minimum!(fill(Inf, Base.reduced_dims(size(a), reg)), a, reg)
do_mean(a::DenseArray, reg) = mean!(rand(Base.reduced_dims(size(a), reg)), a, reg)

# testing of basic functions

for a in arrs_a
    nd = ndims(a)
    for reg in tdims[nd]
        println("ND = $nd, siz = $(size(a)): region = $(reg)")
        # println("which: $(which(sum, a, reg))")
        saferes = safe_sumdim(a, reg)
        @test_approx_eq sum(a, reg) saferes
        @test_approx_eq do_sum(a, reg) saferes
        @test_approx_eq sum!(ones(Base.reduced_dims(size(a), reg)), a, reg) saferes + 1.0

        saferes = safe_maxdim(a, reg)
        @test_approx_eq maximum(a, reg) saferes
        @test_approx_eq do_maximum(a, reg) saferes

        saferes = safe_mindim(a, reg)
        @test_approx_eq minimum(a, reg) saferes
        @test_approx_eq do_minimum(a, reg) saferes

        saferes = safe_meandim(a, reg)
        @test_approx_eq mean(a, reg) saferes
        @test_approx_eq do_mean(a, reg) saferes
    end
end


# # testing sumabs

# @test_approx_eq sumabs(a1, 1) sum(abs(a1), 1)

# @test_approx_eq sumabs(a2, 1) sum(abs(a2), 1)
# @test_approx_eq sumabs(a2, 2) sum(abs(a2), 2)

# @test_approx_eq sumabs(a3, 1) sum(abs(a3), 1)
# @test_approx_eq sumabs(a3, 2) sum(abs(a3), 2)
# @test_approx_eq sumabs(a3, 3) sum(abs(a3), 3)

# @test_approx_eq sumabs(a4, 1) sum(abs(a4), 1)
# @test_approx_eq sumabs(a4, 2) sum(abs(a4), 2)
# @test_approx_eq sumabs(a4, 3) sum(abs(a4), 3)
# @test_approx_eq sumabs(a4, 4) sum(abs(a4), 4)

# # testing meanabs

# @test_approx_eq meanabs(a1, 1) mean(abs(a1), 1)

# @test_approx_eq meanabs(a2, 1) mean(abs(a2), 1)
# @test_approx_eq meanabs(a2, 2) mean(abs(a2), 2)

# @test_approx_eq meanabs(a3, 1) mean(abs(a3), 1)
# @test_approx_eq meanabs(a3, 2) mean(abs(a3), 2)
# @test_approx_eq meanabs(a3, 3) mean(abs(a3), 3)

# @test_approx_eq meanabs(a4, 1) mean(abs(a4), 1)
# @test_approx_eq meanabs(a4, 2) mean(abs(a4), 2)
# @test_approx_eq meanabs(a4, 3) mean(abs(a4), 3)
# @test_approx_eq meanabs(a4, 4) mean(abs(a4), 4)

# # testing maxabs

# @test_approx_eq maxabs(a1, 1) maximum(abs(a1), 1)

# @test_approx_eq maxabs(a2, 1) maximum(abs(a2), 1)
# @test_approx_eq maxabs(a2, 2) maximum(abs(a2), 2)

# @test_approx_eq maxabs(a3, 1) maximum(abs(a3), 1)
# @test_approx_eq maxabs(a3, 2) maximum(abs(a3), 2)
# @test_approx_eq maxabs(a3, 3) maximum(abs(a3), 3)

# @test_approx_eq maxabs(a4, 1) maximum(abs(a4), 1)
# @test_approx_eq maxabs(a4, 2) maximum(abs(a4), 2)
# @test_approx_eq maxabs(a4, 3) maximum(abs(a4), 3)
# @test_approx_eq maxabs(a4, 4) maximum(abs(a4), 4)

# # testing minabs

# @test_approx_eq minabs(a1, 1) minimum(abs(a1), 1)

# @test_approx_eq minabs(a2, 1) minimum(abs(a2), 1)
# @test_approx_eq minabs(a2, 2) minimum(abs(a2), 2)

# @test_approx_eq minabs(a3, 1) minimum(abs(a3), 1)
# @test_approx_eq minabs(a3, 2) minimum(abs(a3), 2)
# @test_approx_eq minabs(a3, 3) minimum(abs(a3), 3)

# @test_approx_eq minabs(a4, 1) minimum(abs(a4), 1)
# @test_approx_eq minabs(a4, 2) minimum(abs(a4), 2)
# @test_approx_eq minabs(a4, 3) minimum(abs(a4), 3)
# @test_approx_eq minabs(a4, 4) minimum(abs(a4), 4)


# # testing sumsq

# @test_approx_eq sumsq(a1, 1) sum(abs2(a1), 1)

# @test_approx_eq sumsq(a2, 1) sum(abs2(a2), 1)
# @test_approx_eq sumsq(a2, 2) sum(abs2(a2), 2)

# @test_approx_eq sumsq(a3, 1) sum(abs2(a3), 1)
# @test_approx_eq sumsq(a3, 2) sum(abs2(a3), 2)
# @test_approx_eq sumsq(a3, 3) sum(abs2(a3), 3)

# @test_approx_eq sumsq(a4, 1) sum(abs2(a4), 1)
# @test_approx_eq sumsq(a4, 2) sum(abs2(a4), 2)
# @test_approx_eq sumsq(a4, 3) sum(abs2(a4), 3)
# @test_approx_eq sumsq(a4, 4) sum(abs2(a4), 4)

# # testing meansq

# @test_approx_eq meansq(a1, 1) mean(abs2(a1), 1)

# @test_approx_eq meansq(a2, 1) mean(abs2(a2), 1)
# @test_approx_eq meansq(a2, 2) mean(abs2(a2), 2)

# @test_approx_eq meansq(a3, 1) mean(abs2(a3), 1)
# @test_approx_eq meansq(a3, 2) mean(abs2(a3), 2)
# @test_approx_eq meansq(a3, 3) mean(abs2(a3), 3)

# @test_approx_eq meansq(a4, 1) mean(abs2(a4), 1)
# @test_approx_eq meansq(a4, 2) mean(abs2(a4), 2)
# @test_approx_eq meansq(a4, 3) mean(abs2(a4), 3)
# @test_approx_eq meansq(a4, 4) mean(abs2(a4), 4)

# # testing sumabsdiff

# @test_approx_eq sumabsdiff(a1, b1, 1) sum(abs(a1 - b1), 1)

# @test_approx_eq sumabsdiff(a2, b2, 1) sum(abs(a2 - b2), 1)
# @test_approx_eq sumabsdiff(a2, b2, 2) sum(abs(a2 - b2), 2)

# @test_approx_eq sumabsdiff(a3, b3, 1) sum(abs(a3 - b3), 1)
# @test_approx_eq sumabsdiff(a3, b3, 2) sum(abs(a3 - b3), 2)
# @test_approx_eq sumabsdiff(a3, b3, 3) sum(abs(a3 - b3), 3)

# @test_approx_eq sumabsdiff(a4, b4, 1) sum(abs(a4 - b4), 1)
# @test_approx_eq sumabsdiff(a4, b4, 2) sum(abs(a4 - b4), 2)
# @test_approx_eq sumabsdiff(a4, b4, 3) sum(abs(a4 - b4), 3)
# @test_approx_eq sumabsdiff(a4, b4, 4) sum(abs(a4 - b4), 4)


# @test_approx_eq sumabsdiff(a1, 0.5, 1) sum(abs(a1 - 0.5), 1)

# @test_approx_eq sumabsdiff(a2, 0.5, 1) sum(abs(a2 - 0.5), 1)
# @test_approx_eq sumabsdiff(a2, 0.5, 2) sum(abs(a2 - 0.5), 2)

# @test_approx_eq sumabsdiff(a3, 0.5, 1) sum(abs(a3 - 0.5), 1)
# @test_approx_eq sumabsdiff(a3, 0.5, 2) sum(abs(a3 - 0.5), 2)
# @test_approx_eq sumabsdiff(a3, 0.5, 3) sum(abs(a3 - 0.5), 3)

# @test_approx_eq sumabsdiff(a4, 0.5, 1) sum(abs(a4 - 0.5), 1)
# @test_approx_eq sumabsdiff(a4, 0.5, 2) sum(abs(a4 - 0.5), 2)
# @test_approx_eq sumabsdiff(a4, 0.5, 3) sum(abs(a4 - 0.5), 3)
# @test_approx_eq sumabsdiff(a4, 0.5, 4) sum(abs(a4 - 0.5), 4)


# @test_approx_eq sumabsdiff(0.5, b1, 1) sum(abs(0.5 - b1), 1)

# @test_approx_eq sumabsdiff(0.5, b2, 1) sum(abs(0.5 - b2), 1)
# @test_approx_eq sumabsdiff(0.5, b2, 2) sum(abs(0.5 - b2), 2)

# @test_approx_eq sumabsdiff(0.5, b3, 1) sum(abs(0.5 - b3), 1)
# @test_approx_eq sumabsdiff(0.5, b3, 2) sum(abs(0.5 - b3), 2)
# @test_approx_eq sumabsdiff(0.5, b3, 3) sum(abs(0.5 - b3), 3)

# @test_approx_eq sumabsdiff(0.5, b4, 1) sum(abs(0.5 - b4), 1)
# @test_approx_eq sumabsdiff(0.5, b4, 2) sum(abs(0.5 - b4), 2)
# @test_approx_eq sumabsdiff(0.5, b4, 3) sum(abs(0.5 - b4), 3)
# @test_approx_eq sumabsdiff(0.5, b4, 4) sum(abs(0.5 - b4), 4)


# # testing sumsqdiff

# @test_approx_eq sumsqdiff(a1, b1, 1) sum(abs2(a1 - b1), 1)

# @test_approx_eq sumsqdiff(a2, b2, 1) sum(abs2(a2 - b2), 1)
# @test_approx_eq sumsqdiff(a2, b2, 2) sum(abs2(a2 - b2), 2)

# @test_approx_eq sumsqdiff(a3, b3, 1) sum(abs2(a3 - b3), 1)
# @test_approx_eq sumsqdiff(a3, b3, 2) sum(abs2(a3 - b3), 2)
# @test_approx_eq sumsqdiff(a3, b3, 3) sum(abs2(a3 - b3), 3)

# @test_approx_eq sumsqdiff(a4, b4, 1) sum(abs2(a4 - b4), 1)
# @test_approx_eq sumsqdiff(a4, b4, 2) sum(abs2(a4 - b4), 2)
# @test_approx_eq sumsqdiff(a4, b4, 3) sum(abs2(a4 - b4), 3)
# @test_approx_eq sumsqdiff(a4, b4, 4) sum(abs2(a4 - b4), 4)

# # testing maxabsdiff

# @test_approx_eq maxabsdiff(a1, b1, 1) maximum(abs(a1 - b1), 1)

# @test_approx_eq maxabsdiff(a2, b2, 1) maximum(abs(a2 - b2), 1)
# @test_approx_eq maxabsdiff(a2, b2, 2) maximum(abs(a2 - b2), 2)

# @test_approx_eq maxabsdiff(a3, b3, 1) maximum(abs(a3 - b3), 1)
# @test_approx_eq maxabsdiff(a3, b3, 2) maximum(abs(a3 - b3), 2)
# @test_approx_eq maxabsdiff(a3, b3, 3) maximum(abs(a3 - b3), 3)

# @test_approx_eq maxabsdiff(a4, b4, 1) maximum(abs(a4 - b4), 1)
# @test_approx_eq maxabsdiff(a4, b4, 2) maximum(abs(a4 - b4), 2)
# @test_approx_eq maxabsdiff(a4, b4, 3) maximum(abs(a4 - b4), 3)
# @test_approx_eq maxabsdiff(a4, b4, 4) maximum(abs(a4 - b4), 4)

# # testing minabsdiff

# @test_approx_eq minabsdiff(a1, b1, 1) minimum(abs(a1 - b1), 1)

# @test_approx_eq minabsdiff(a2, b2, 1) minimum(abs(a2 - b2), 1)
# @test_approx_eq minabsdiff(a2, b2, 2) minimum(abs(a2 - b2), 2)

# @test_approx_eq minabsdiff(a3, b3, 1) minimum(abs(a3 - b3), 1)
# @test_approx_eq minabsdiff(a3, b3, 2) minimum(abs(a3 - b3), 2)
# @test_approx_eq minabsdiff(a3, b3, 3) minimum(abs(a3 - b3), 3)

# @test_approx_eq minabsdiff(a4, b4, 1) minimum(abs(a4 - b4), 1)
# @test_approx_eq minabsdiff(a4, b4, 2) minimum(abs(a4 - b4), 2)
# @test_approx_eq minabsdiff(a4, b4, 3) minimum(abs(a4 - b4), 3)
# @test_approx_eq minabsdiff(a4, b4, 4) minimum(abs(a4 - b4), 4)

# # testing meanabsdiff

# @test_approx_eq meanabsdiff(a1, b1, 1) mean(abs(a1 - b1), 1)

# @test_approx_eq meanabsdiff(a2, b2, 1) mean(abs(a2 - b2), 1)
# @test_approx_eq meanabsdiff(a2, b2, 2) mean(abs(a2 - b2), 2)

# @test_approx_eq meanabsdiff(a3, b3, 1) mean(abs(a3 - b3), 1)
# @test_approx_eq meanabsdiff(a3, b3, 2) mean(abs(a3 - b3), 2)
# @test_approx_eq meanabsdiff(a3, b3, 3) mean(abs(a3 - b3), 3)

# @test_approx_eq meanabsdiff(a4, b4, 1) mean(abs(a4 - b4), 1)
# @test_approx_eq meanabsdiff(a4, b4, 2) mean(abs(a4 - b4), 2)
# @test_approx_eq meanabsdiff(a4, b4, 3) mean(abs(a4 - b4), 3)
# @test_approx_eq meanabsdiff(a4, b4, 4) mean(abs(a4 - b4), 4)

# # testing meansqdiff

# @test_approx_eq meansqdiff(a1, b1, 1) mean(abs2(a1 - b1), 1)

# @test_approx_eq meansqdiff(a2, b2, 1) mean(abs2(a2 - b2), 1)
# @test_approx_eq meansqdiff(a2, b2, 2) mean(abs2(a2 - b2), 2)

# @test_approx_eq meansqdiff(a3, b3, 1) mean(abs2(a3 - b3), 1)
# @test_approx_eq meansqdiff(a3, b3, 2) mean(abs2(a3 - b3), 2)
# @test_approx_eq meansqdiff(a3, b3, 3) mean(abs2(a3 - b3), 3)

# @test_approx_eq meansqdiff(a4, b4, 1) mean(abs2(a4 - b4), 1)
# @test_approx_eq meansqdiff(a4, b4, 2) mean(abs2(a4 - b4), 2)
# @test_approx_eq meansqdiff(a4, b4, 3) mean(abs2(a4 - b4), 3)
# @test_approx_eq meansqdiff(a4, b4, 4) mean(abs2(a4 - b4), 4)


# # testing dot

# @test_approx_eq dot(a1, b1, 1) sum(a1 .* b1, 1)

# @test_approx_eq dot(a2, b2, 1) sum(a2 .* b2, 1)
# @test_approx_eq dot(a2, b2, 2) sum(a2 .* b2, 2)

# @test_approx_eq dot(a3, b3, 1) sum(a3 .* b3, 1)
# @test_approx_eq dot(a3, b3, 2) sum(a3 .* b3, 2)
# @test_approx_eq dot(a3, b3, 3) sum(a3 .* b3, 3)

# @test_approx_eq dot(a4, b4, 1) sum(a4 .* b4, 1)
# @test_approx_eq dot(a4, b4, 2) sum(a4 .* b4, 2)
# @test_approx_eq dot(a4, b4, 3) sum(a4 .* b4, 3)
# @test_approx_eq dot(a4, b4, 4) sum(a4 .* b4, 4)

# # testing sumxlogx

# @test_approx_eq sumxlogx(p1, 1) sum(p1 .* log(p1), 1)

# @test_approx_eq sumxlogx(p2, 1) sum(p2 .* log(p2), 1)
# @test_approx_eq sumxlogx(p2, 2) sum(p2 .* log(p2), 2)

# @test_approx_eq sumxlogx(p3, 1) sum(p3 .* log(p3), 1)
# @test_approx_eq sumxlogx(p3, 2) sum(p3 .* log(p3), 2)
# @test_approx_eq sumxlogx(p3, 3) sum(p3 .* log(p3), 3)

# @test_approx_eq sumxlogx(p4, 1) sum(p4 .* log(p4), 1)
# @test_approx_eq sumxlogx(p4, 2) sum(p4 .* log(p4), 2)
# @test_approx_eq sumxlogx(p4, 3) sum(p4 .* log(p4), 3)
# @test_approx_eq sumxlogx(p4, 4) sum(p4 .* log(p4), 4)

# # testing sumxlogy

# @test_approx_eq sumxlogy(p1, q1, 1) sum(p1 .* log(q1), 1)

# @test_approx_eq sumxlogy(p2, q2, 1) sum(p2 .* log(q2), 1)
# @test_approx_eq sumxlogy(p2, q2, 2) sum(p2 .* log(q2), 2)

# @test_approx_eq sumxlogy(p3, q3, 1) sum(p3 .* log(q3), 1)
# @test_approx_eq sumxlogy(p3, q3, 2) sum(p3 .* log(q3), 2)
# @test_approx_eq sumxlogy(p3, q3, 3) sum(p3 .* log(q3), 3)

# @test_approx_eq sumxlogy(p4, q4, 1) sum(p4 .* log(q4), 1)
# @test_approx_eq sumxlogy(p4, q4, 2) sum(p4 .* log(q4), 2)
# @test_approx_eq sumxlogy(p4, q4, 3) sum(p4 .* log(q4), 3)
# @test_approx_eq sumxlogy(p4, q4, 4) sum(p4 .* log(q4), 4)

# # testing entropy

# @test_approx_eq entropy(p1, 1) sum(-p1 .* log(p1), 1)

# @test_approx_eq entropy(p2, 1) sum(-p2 .* log(p2), 1)
# @test_approx_eq entropy(p2, 2) sum(-p2 .* log(p2), 2)

# @test_approx_eq entropy(p3, 1) sum(-p3 .* log(p3), 1)
# @test_approx_eq entropy(p3, 2) sum(-p3 .* log(p3), 2)
# @test_approx_eq entropy(p3, 3) sum(-p3 .* log(p3), 3)

# @test_approx_eq entropy(p4, 1) sum(-p4 .* log(p4), 1)
# @test_approx_eq entropy(p4, 2) sum(-p4 .* log(p4), 2)
# @test_approx_eq entropy(p4, 3) sum(-p4 .* log(p4), 3)
# @test_approx_eq entropy(p4, 4) sum(-p4 .* log(p4), 4)


# # sum on fma

# @test_approx_eq sum(FMA(), a1, b1, p1, 1) sum(a1 + b1 .* p1, 1)

# @test_approx_eq sum(FMA(), a2, b2, p2, 1) sum(a2 + b2 .* p2, 1)
# @test_approx_eq sum(FMA(), a2, b2, p2, 2) sum(a2 + b2 .* p2, 2)

# @test_approx_eq sum(FMA(), a3, b3, p3, 1) sum(a3 + b3 .* p3, 1)
# @test_approx_eq sum(FMA(), a3, b3, p3, 2) sum(a3 + b3 .* p3, 2)
# @test_approx_eq sum(FMA(), a3, b3, p3, 3) sum(a3 + b3 .* p3, 3)

# @test_approx_eq sum(FMA(), a4, b4, p4, 1) sum(a4 + b4 .* p4, 1)
# @test_approx_eq sum(FMA(), a4, b4, p4, 2) sum(a4 + b4 .* p4, 2)
# @test_approx_eq sum(FMA(), a4, b4, p4, 3) sum(a4 + b4 .* p4, 3)
# @test_approx_eq sum(FMA(), a4, b4, p4, 4) sum(a4 + b4 .* p4, 4)


# # foldl

# foldlsum(xs...) = foldl(Add(), 0., xs...)
# foldlsumfdiff(f, x1, x2, dim) = foldl_fdiff(Add(), 0., f, x1, x2, dim)

# @test_approx_eq foldlsum(a1, 1) sum(a1, 1)
# @test_approx_eq foldlsum(a2, 1) sum(a2, 1)
# @test_approx_eq foldlsum(a2, 2) sum(a2, 2)
# @test_approx_eq foldlsum(a3, 1) sum(a3, 1)
# @test_approx_eq foldlsum(a3, 2) sum(a3, 2)
# @test_approx_eq foldlsum(a3, 3) sum(a3, 3)
# @test_approx_eq foldlsum(a4, 1) sum(a4, 1)
# @test_approx_eq foldlsum(a4, 2) sum(a4, 2)
# @test_approx_eq foldlsum(a4, 3) sum(a4, 3)
# @test_approx_eq foldlsum(a4, 4) sum(a4, 4)

# do_foldlsum!(a, dim) = foldl!(zeros(reduced_shape(size(a), dim)), Add(), 0., a, dim)

# @test_approx_eq do_foldlsum!(a1, 1) sum(a1, 1)
# @test_approx_eq do_foldlsum!(a2, 1) sum(a2, 1)
# @test_approx_eq do_foldlsum!(a2, 2) sum(a2, 2)
# @test_approx_eq do_foldlsum!(a3, 1) sum(a3, 1)
# @test_approx_eq do_foldlsum!(a3, 2) sum(a3, 2)
# @test_approx_eq do_foldlsum!(a3, 3) sum(a3, 3)
# @test_approx_eq do_foldlsum!(a4, 1) sum(a4, 1)
# @test_approx_eq do_foldlsum!(a4, 2) sum(a4, 2)
# @test_approx_eq do_foldlsum!(a4, 3) sum(a4, 3)
# @test_approx_eq do_foldlsum!(a4, 4) sum(a4, 4)

# @test_approx_eq foldlsum(Abs2Fun(), a1, 1) sum(abs2(a1), 1)
# @test_approx_eq foldlsum(Abs2Fun(), a2, 1) sum(abs2(a2), 1)
# @test_approx_eq foldlsum(Abs2Fun(), a2, 2) sum(abs2(a2), 2)
# @test_approx_eq foldlsum(Abs2Fun(), a3, 1) sum(abs2(a3), 1)
# @test_approx_eq foldlsum(Abs2Fun(), a3, 2) sum(abs2(a3), 2)
# @test_approx_eq foldlsum(Abs2Fun(), a3, 3) sum(abs2(a3), 3)
# @test_approx_eq foldlsum(Abs2Fun(), a4, 1) sum(abs2(a4), 1)
# @test_approx_eq foldlsum(Abs2Fun(), a4, 2) sum(abs2(a4), 2)
# @test_approx_eq foldlsum(Abs2Fun(), a4, 3) sum(abs2(a4), 3)
# @test_approx_eq foldlsum(Abs2Fun(), a4, 4) sum(abs2(a4), 4)

# @test_approx_eq foldlsum(Multiply(), a1, b1, 1) sum(a1 .* b1, 1)
# @test_approx_eq foldlsum(Multiply(), a2, b2, 1) sum(a2 .* b2, 1)
# @test_approx_eq foldlsum(Multiply(), a2, b2, 2) sum(a2 .* b2, 2)
# @test_approx_eq foldlsum(Multiply(), a3, b3, 1) sum(a3 .* b3, 1)
# @test_approx_eq foldlsum(Multiply(), a3, b3, 2) sum(a3 .* b3, 2)
# @test_approx_eq foldlsum(Multiply(), a3, b3, 3) sum(a3 .* b3, 3)
# @test_approx_eq foldlsum(Multiply(), a4, b4, 1) sum(a4 .* b4, 1)
# @test_approx_eq foldlsum(Multiply(), a4, b4, 2) sum(a4 .* b4, 2)
# @test_approx_eq foldlsum(Multiply(), a4, b4, 3) sum(a4 .* b4, 3)
# @test_approx_eq foldlsum(Multiply(), a4, b4, 4) sum(a4 .* b4, 4)

# @test_approx_eq foldlsumfdiff(Abs2Fun(), a1, b1, 1) sum(abs2(a1 - b1), 1)
# @test_approx_eq foldlsumfdiff(Abs2Fun(), a2, b2, 1) sum(abs2(a2 - b2), 1)
# @test_approx_eq foldlsumfdiff(Abs2Fun(), a2, b2, 2) sum(abs2(a2 - b2), 2)
# @test_approx_eq foldlsumfdiff(Abs2Fun(), a3, b3, 1) sum(abs2(a3 - b3), 1)
# @test_approx_eq foldlsumfdiff(Abs2Fun(), a3, b3, 2) sum(abs2(a3 - b3), 2)
# @test_approx_eq foldlsumfdiff(Abs2Fun(), a3, b3, 3) sum(abs2(a3 - b3), 3)
# @test_approx_eq foldlsumfdiff(Abs2Fun(), a4, b4, 1) sum(abs2(a4 - b4), 1)
# @test_approx_eq foldlsumfdiff(Abs2Fun(), a4, b4, 2) sum(abs2(a4 - b4), 2)
# @test_approx_eq foldlsumfdiff(Abs2Fun(), a4, b4, 3) sum(abs2(a4 - b4), 3)
# @test_approx_eq foldlsumfdiff(Abs2Fun(), a4, b4, 4) sum(abs2(a4 - b4), 4)





