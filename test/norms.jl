# Testing of functions in norms.jl

using NumericExtensions
using Base.Test

x1 = randn(6)
y1 = randn(6)

x2 = randn(5, 6)
y2 = randn(5, 6)

x3 = randn(3, 4, 5)
y3 = randn(3, 4, 5)

xs = {x1, x2, x3}
ys = {y1, y2, y3}
ps = {1, 2, 3, Inf}

tdims = {
    {1},   # N = 1
    {1, 2, (1, 2)}, # N = 2
    {1, 2, 3, (1, 2), (1, 3), (2, 3), (1, 2, 3)} # N = 3
}

safe_vnorm(x, p) = p == 1 ? sum(abs(x)) :
                   p == 2 ? sqrt(sum(abs2(x))) :
                   p == Inf ? maximum(abs(x)) :
                   sum(abs(x) .^ p) .^ inv(p)

safe_vnorm(x, p, reg) = p == 1 ? sum(abs(x), reg) :
                        p == 2 ? sqrt(sum(abs2(x), reg)) :
                        p == Inf ? maximum(abs(x), reg) :
                        sum(abs(x) .^ p, reg) .^ inv(p)

# vnorm

for x in xs, p in ps
    @test_approx_eq vnorm(x, p) safe_vnorm(x, p)
end

for x in xs, reg in tdims[ndims(x)], p in ps
    @test_approx_eq vnorm(x, p, reg) safe_vnorm(x, p, reg)
end

# vnormdiff

for (x, y) in zip(xs, ys), p in ps
    @test_approx_eq vnormdiff(x, y, p) safe_vnorm(x - y, p)
end

for (x, y) in zip(xs, ys), reg in tdims[ndims(x)], p in ps
    @test_approx_eq vnormdiff(x, y, p, reg) safe_vnorm(x - y, p, reg)
end

# normalize

for x in xs, p in ps
    r = x ./ vnorm(x, p)
    @test_approx_eq normalize(x, p) r

    xc = copy(x)
    normalize!(xc, p)
    @test_approx_eq xc r
end

for x in xs, reg in tdims[ndims(x)], p in ps
    r = x ./ vnorm(x, p, reg)
    @test_approx_eq normalize(x, p, reg) r

    xc = copy(x)
    normalize!(xc, p, reg)
    @test_approx_eq xc r
end
