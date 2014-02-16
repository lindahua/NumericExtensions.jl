# benchmarks of reduction on views

using NumericExtensions

const a = rand(1000, 1000)

const a_sub = sub(a, 1:999, :)
const a_view = view(a, 1:999, :)

println("for sum:")
for dim = 1:2
    # warmup
    sum(a_sub, dim)
    sum(a_view, dim)

    # profile
    et1 = @elapsed for i=1:100; sum(a_sub, dim); end
    et2 = @elapsed for i=1:100; sum(a_view, dim); end

    @printf("  dim = %d:  on a_sub => %.4fs   on a_view => %.4fs   |  gain = %.4fx\n", 
        dim, et1, et2, et1 / et2)
end

println("for sumabs:")
for dim = 1:2
    # warmup
    sum(a_sub, dim)
    sum(a_view, dim)

    # profile
    et1 = @elapsed for i=1:100; sum(abs(a_sub), dim); end
    et2 = @elapsed for i=1:100; sumabs(a_view, dim); end

    @printf("  dim = %d:  on a_sub => %.4fs   on a_view => %.4fs   |  gain = %.4fx\n", 
        dim, et1, et2, et1 / et2)
end

