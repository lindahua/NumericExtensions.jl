
using NumericFunctors
using NumericExtensions
using Base.Test

## data 

a1 = 2 * rand(8) .+ 1.0
a2 = 2 * rand(8, 7) .+ 1.0
a3 = 2 * rand(8, 7, 6) .+ 1.0
a4 = 2 * rand(8, 7, 6, 5) .+ 1.0

b1 = 2 * rand(8) .- 1.0
b2 = 2 * rand(8, 7) .- 1.0
b3 = 2 * rand(8, 7, 6) .- 1.0
b4 = 2 * rand(8, 7, 6, 5) .- 1.0

c1 = 2 * rand(8) .- 1.0
c2 = 2 * rand(8, 7) .- 1.0
c3 = 2 * rand(8, 7, 6) .- 1.0
c4 = 2 * rand(8, 7, 6, 5) .- 1.0

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


## test cases

arrs_a = {a1, a2, a3, a4, ua1, va1, ua2, va2, ua3, va3, ua4, va4}
arrs_b = {b1, b2, b3, b4, ub1, vb1, ub2, vb2, ub3, vb3, ub4, vb4}

## unary cases

println("  -- unary functions")

unaryfs = [(Negate, -, negate!), 
           (AbsFun, abs, abs!), 
           (Abs2Fun, abs2, abs2!), 
           (SqrtFun, sqrt, sqrt!), 
           (FloorFun, floor, floor!), 
           (CeilFun, ceil, ceil!), 
           (ExpFun, exp, exp!), 
           (LogFun, log, log!)]

for a in arrs_a, (Op, vf, vf!) in unaryfs
    r = vf(copy(a))
    @test_approx_eq map(Op(), a) r

    y = zeros(size(r))
    vf!(y, a)
    @test_approx_eq y r

    ac = copy(a)
    vf!(ac)
    @test_approx_eq ac r
end

## binary cases

println("  -- binary functions")

binaryfs = [(Add, .+, add!), 
            (Subtract, .-, subtract!), 
            (Multiply, .*, multiply!), 
            (Divide, ./, divide!)]

for (a, b) in zip(arrs_a, arrs_b), (Op, vf, vf!) in binaryfs
    r = vf(copy(b), copy(a))
    @test_approx_eq map(Op(), b, a) r
    @test_approx_eq map(Op(), a, 2.0) vf(copy(a), 2.0)
    @test_approx_eq map(Op(), 2.0, b) vf(2.0, copy(b))

    y = zeros(size(r))
    vf!(y, b, a)
    @test_approx_eq y r

    bc = copy(b)
    vf!(bc, a)
    @test_approx_eq bc r

    bc = copy(b)
    vf!(bc, 2.0)
    @test_approx_eq bc vf(copy(b), 2.0)
end

## mapdiff cases

println("  -- mapdiff functions")

for (a, b) in zip(arrs_a, arrs_b)
    ac = copy(a)
    bc = copy(b)
    v = 2.6

    @test_approx_eq absdiff(a, b) abs(ac .- bc)
    @test_approx_eq absdiff(a, v) abs(ac .- v)
    @test_approx_eq absdiff(v, b) abs(v .- bc)

    @test_approx_eq sqrdiff(a, b) abs2(ac .- bc)
    @test_approx_eq sqrdiff(a, v) abs2(ac .- v)
    @test_approx_eq sqrdiff(v, b) abs2(v .- bc)

    @test_approx_eq absdiff!(zeros(size(a)), a, b) abs(ac .- bc)
    @test_approx_eq absdiff!(zeros(size(a)), a, v) abs(ac .- v)
    @test_approx_eq absdiff!(zeros(size(a)), v, b) abs(v .- bc)

    @test_approx_eq sqrdiff!(zeros(size(a)), a, b) abs2(ac .- bc)
    @test_approx_eq sqrdiff!(zeros(size(a)), a, v) abs2(ac .- v)
    @test_approx_eq sqrdiff!(zeros(size(a)), v, b) abs2(v .- bc)
end

## ternary cases

println("  -- ternary functions")

@test_approx_eq map(FMA(), a1, b1, c1) a1 .+ b1 .* c1

v = 2.5

for (a, b) in zip(arrs_a, arrs_b)
    ac = copy(a)
    bc = copy(b)

    @test_approx_eq map(FMA(), v, a, b) v .+ ac .* bc
    @test_approx_eq map(FMA(), a, v, b) ac .+ v .* bc
    @test_approx_eq map(FMA(), a, b, v) ac .+ bc .* v

    fma!(ac, a, b) 
    @test_approx_eq ac a .+ a .* b

    ac = copy(a)
    fma!(ac, b, v)
    @test_approx_eq ac a .+ b .* v
end

