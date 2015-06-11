using NumericFuns
using NumericExtensions
using Base.Test

## Data preparation

a1 = 2 * rand(8) .- 1.0
a2 = 2 * rand(8, 7) .- 1.0
a3 = 2 * rand(8, 7, 6) .- 1.0
a4 = 2 * rand(8, 7, 6, 5) .- 1.0

b1 = 2 * rand(8) .- 1.0
b2 = 2 * rand(8, 7) .- 1.0
b3 = 2 * rand(8, 7, 6) .- 1.0
b4 = 2 * rand(8, 7, 6, 5) .- 1.0

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

arrs_a = Any[a1, a2, a3, a4, ua1, va1, ua2, va2, ua3, va3, ua4, va4]
arrs_b = Any[b1, b2, b3, b4, ub1, vb1, ub2, vb2, ub3, vb3, ub4, vb4]
arrs_p = Any[p1, p2, p3, p4]
arrs_q = Any[q1, q2, q3, q4]

tdims = Any[
    Any[1],   # N = 1
    Any[1, 2, (1, 2)], # N = 2
    Any[1, 2, 3, (1, 2), (1, 3), (2, 3), (1, 2, 3)], # N = 3
    Any[1, 2, 3, 4, (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4), 
     (1, 2, 3), (1, 2, 4), (1, 3, 4), (2, 3, 4), (1, 2, 3, 4)] # N = 4
]


# auxiliary

safe_sumdim(a::DenseArray, reg) = invoke(sum, (AbstractArray{Float64}, Any), copy(a), reg)
safe_maxdim(a::DenseArray, reg) = invoke(maximum, (AbstractArray{Float64}, Any), copy(a), reg)
safe_mindim(a::DenseArray, reg) = invoke(minimum, (AbstractArray{Float64}, Any), copy(a), reg)
safe_meandim(a::DenseArray, reg) = invoke(mean, (AbstractArray{Float64}, Any), copy(a), reg)

do_sum(a::DenseArray, reg) = sum!(zeros(Base.reduced_dims(size(a), reg)), a, reg)
do_maximum(a::DenseArray, reg) = maximum!(fill(-Inf, Base.reduced_dims(size(a), reg)), a, reg)
do_minimum(a::DenseArray, reg) = minimum!(fill(Inf, Base.reduced_dims(size(a), reg)), a, reg)
do_mean(a::DenseArray, reg) = mean!(rand(Base.reduced_dims(size(a), reg)), a, reg)
do_sumabs(a::DenseArray, reg) = NumericExtensions.sumabs!(zeros(Base.reduced_dims(size(a), reg)), a, reg)

# testing of basic functions

println("  -- basic functions")

@test sum(trues(4, 3), 1) == [4 4 4]

for a in arrs_a
    nd = ndims(a)
    for reg in tdims[nd]
        # println("ND = $nd, siz = $(size(a)): region = $(reg)")
        saferes = safe_sumdim(a, reg)
        @test_approx_eq sum(a, reg) saferes
        @test_approx_eq do_sum(a, reg) saferes
        @test_approx_eq sum!(ones(Base.reduced_dims(size(a), reg)), a, reg) saferes .+ 1.0

        saferes = safe_maxdim(a, reg)
        @test_approx_eq maximum(a, reg) saferes
        @test_approx_eq do_maximum(a, reg) saferes

        saferes = safe_mindim(a, reg)
        @test_approx_eq minimum(a, reg) saferes
        @test_approx_eq do_minimum(a, reg) saferes

        saferes = safe_meandim(a, reg)
        @test_approx_eq mean(a, reg) saferes
        @test_approx_eq do_mean(a, reg) saferes

        @test_approx_eq NumericExtensions.sumabs(a, reg) sum(abs(copy(a)), reg)
        @test_approx_eq do_sumabs(a, reg) sum(abs(copy(a)), reg)

        @test_approx_eq NumericExtensions.maxabs(a, reg) maximum(abs(copy(a)), reg)
        @test_approx_eq NumericExtensions.minabs(a, reg) minimum(abs(copy(a)), reg)
        @test_approx_eq meanabs(a, reg) mean(abs(copy(a)), reg)
        @test_approx_eq sumsq(a, reg) sum(abs2(copy(a)), reg)
        @test_approx_eq meansq(a, reg) mean(abs2(copy(a)), reg)
    end
end

println("  -- derived functions")

for (a, b) in zip(arrs_a, arrs_b)
    @assert size(a) == size(b)
    nd = ndims(a)
    for reg in tdims[nd]
        # println("ND = $nd, siz = $(size(a)): region = $(reg)")
        @test_approx_eq dot(a, b, reg) sum(a .* b, reg)
        @test_approx_eq sumabsdiff(a, b, reg) sum(abs(a - b), reg)
        @test_approx_eq maxabsdiff(a, b, reg) maximum(abs(a - b), reg)
        @test_approx_eq minabsdiff(a, b, reg) minimum(abs(a - b), reg)
        @test_approx_eq meanabsdiff(a, b, reg) mean(abs(a - b), reg)
        @test_approx_eq sumsqdiff(a, b, reg) sum(abs2(a - b), reg)
        @test_approx_eq meansqdiff(a, b, reg) mean(abs2(a - b), reg)

        @test_approx_eq dot(a, 2.0, reg) sum(a .* 2.0, reg)
        @test_approx_eq dot(2.0, b, reg) sum(b .* 2.0, reg)

        @test_approx_eq sumsqdiff(a, 2.0, reg) sum(abs2(a .- 2.0), reg)
        @test_approx_eq sumsqdiff(2.0, b, reg) sum(abs2(2.0 .- b), reg)

        @test_approx_eq sum(FMA(), 2.0, a, b, reg) sum(2.0 .+ a .* b, reg)
        @test_approx_eq sum(FMA(), a, 2.0, b, reg) sum(a .+ b * 2.0, reg)
        @test_approx_eq sum(FMA(), a, b, 2.0, reg) sum(a .+ b * 2.0, reg)
    end
end

for (a, b) in zip(arrs_p, arrs_q)
    @assert size(a) == size(b)
    nd = ndims(a)
    for reg in tdims[nd]
        @test_approx_eq sumxlogx(a, reg) sum(ifelse(a .> 0, a .* log(a), 0.0), reg)
        @test_approx_eq sumxlogy(a, b, reg) sum(ifelse(a .> 0, a .* log(b), 0.0), reg)
        @test_approx_eq entropy(a, reg) -sumxlogx(a, reg)
    end
end

