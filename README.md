## NumericFunctors.jl

Fast vectorized computation for Julia, based on typed functors.

## Motivation

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

This package addresses this issue through *type functors* (*i.e.* function-like objects with specific types) and a set of highly optimized higher level functions for mapping and reduction. The codes above can be rewritten as

```julia
using NumericFunctors

 # benchmark
@time for i in 1 : 10 vmap(Add(), a, b) end     # -- statement(1)
@time for i in 1 : 10 a + b end                 # -- statement(2)
```  

Here, using a typed functor ``Add`` and the ``vmap`` function provided in this package, statement (1) is *20%* faster than statement (2) in my benchmark (run ``test/benchmark_vmap.jl``). The reason is that typed functors triggered the compilation of specialized methods, where the codes associated with the functor will probably be *inlined*.

## Main Features

The package aims to provide generic and high performance functions for numerical computation, especially *mapping* and *reduction*.

* A large collection of pre-defined functors cover most typical mathematical computation.
* User can easily define customized functors.
* Higher order functions ``vmap`` and ``vreduce`` are provided for mapping and reduction (both full reduction and reduction along specific dimensions). They are carefully optimized and tuned, often resulting in *2x - 10x* speed up compared to the counterpart in Julia Base.
* Map-reduce can be done in one call of ``vreduce``, which performs the computation in a cache-friendly manner and without creating any intermediate arrays.
* Broadcasting computation (supporting both inplace updating and writing results to new arrays).












