NumericFunctors.jl
====================

Fast vectorized computation for Julia, based on typed functors.

Passing functions as arguments are essential in writing generic algorithms. However, function arguments do not get inlined in Julia (at current version), usually resulting in suboptimal performance. Consider the following example:

```julia
plus(x, y) = x + y
map_plus(x, y) = map(plus, x, y)

a = rand(1000, 1000)
b = rand(1000, 1000)

 # warming up and get map_plus compiled
a + b
map_plus(a, b)

 # benchmark
@time for i in 1 : 10 map_plus(a, b) end  # -- statement (1)
@time for i in 1 : 10 a + b end           # -- statement (2)
```

Run this script in you computer, you will find that statement (2) is over *20+ times* slower than statement (1). The reason is that the function argument ``plus`` is resolved and called at each iteration of the inner loop within the ``map`` function.

This package introduces *typed functors*, which can be used as arguments to various higher order functions without compromising the run-time performance. This package also introduces a series of functions for element-wise map, reduction, and reduction along specific dimensions. These functions are highly optimized, which typically yield *2x - 10x* speed up as compared to the counterpart functions in Julia Base.





