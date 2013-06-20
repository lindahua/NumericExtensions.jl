## NumericFunctors.jl

Fast vectorized computation for Julia, based on typed functors.

### Motivation

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

### Main Features

The package aims to provide generic and high performance functions for numerical computation, especially *mapping* and *reduction*.

* A large collection of pre-defined functors cover most typical mathematical computation.
* User can easily define customized functors.
* Higher order functions ``vmap`` and ``vreduce`` are provided for mapping and reduction (both full reduction and reduction along specific dimensions). They are carefully optimized and tuned, often resulting in *2x - 10x* speed up compared to the counterpart in Julia Base.
* Map-reduce can be done in one call of ``vreduce``, which performs the computation in a cache-friendly manner and without creating any intermediate arrays.
* Broadcasting computation (supporting both inplace updating and writing results to new arrays).

### Functors

``Functor`` is the abstract base type for all functors, which are formally defined as below

```julia
abstract Functor{N}  # N: the number of arguments

typealias UnaryFunctor Functor{1}
typealias BinaryFunctor Functor{2}
typealias TernaryFunctor Functor{3}
```

##### Predefined functors

Following is a list of pre-defined functors provided by this package:

* Arithmetic functors: ``Add``, ``Subtract``, ``Multiply``, ``Divide``, ``Negate``, ``Abs``
* Max and Min functors: ``Max``, ``Min``
* Rounding functors: ``Floor``, ``Ceil``, ``Round``, ``Trunc``
* Power functors: ``Pow``, ``Sqrt``, ``Cbrt``, ``Abs2``, ``Hypot``
* Exp and log functors: ``Exp``, ``Exp2``, ``Exp10``, ``Log``, ``Log2``, ``Log10``, ``Expm1``, ``Log1p``
* Trigonometric functors: ``Sin``, ``Cos``, ``Tan``, ``Asin``, ``Acos``, ``Atan``, ``Atan2``
* Hyperbolic functors: ``Sinh``, ``Cosh``, ``Tanh``, ``Asinh``, ``Acosh``, ``Atanh``
* Error functors: ``Erf``, ``Erfc``
* Gamma functors: ``Gamma``, ``Lgamma``, ``Digamma``
* Comparison functors: ``Greater``, ``GreaterEqual``, ``Less``, ``LessEqual``, ``Equal``, ``NotEqual``
* Number class functors: ``Isfinite``, ``Isinf``, ``Isnan``
* Fused multiply and add: ``FMA`` (i.e. ``(a, b, c) -> a + b * c``)

Except for several functors that corresponding to operators, most functors are named using the capitalized version of the corresponding math function. Therefore, you don't have to look up this list to find the names. The collection of pre-defined functors will be extended in future. Please refer to ``src/functors.jl`` for the most updated list.

##### Customized functors

User can define new functors by sub-typing ``Functor``. For example, to define a functor that calculates squared difference, we can do the following:

```julia
type SqrDiff <: BinaryFunctor end

NumericFunctors.evaluate(::SqrDiff, x, y) = abs2(x - y)
NumericFunctors.result_type(::SqrDiff, t1::Type, t2::Type) = promote_type(t1, t2)
```

To define multiple functors, it would be more concise to first import ``evaluate`` and ``result_type`` before extending them, as follows:

```julia
import NumericFunctors.evaluate, NumericFunctors.result_type

type SqrDiff <: BinaryFunctor end

evaluate(::SqrDiff, x, y) = abs2(x - y)
result_type(::SqrDiff, t1::Type, t2::Type) = promote_type(t1, t2)
```

**Note:** Higher order functions such as ``vmap`` and ``vreduce`` rely on the ``result_type`` method to determine the element type of the result. This is necessary, as Julia does not provide a generic mechanism to acquire the return type of a method.


### Mapping

This package provides ``vmap`` and ``vmap!`` that allows efficient element-wise mapping using functors:

```julia
typealias ArrayOrNumber Union(AbstractArray, Number)

vmap(f::Functor, xs::ArrayOrNumber...)   # perform element-wise computation using functor f
                                         # each argument in xs can be either an array or a number

vmap(Sqrt(), x)    # == sqrt(x)
vmap(Add(), x, 1)  # == x + 1
vmap(FMA(), x, y, z)  # == x + y .* z
```

The function ``vmap!`` allows inplace computation, with the results written to the first argument or a pre-allocated array.

```julia
vmap!(dst::AbstractArray, f::Functor, xs::ArrayOrNumber...)  # write results to dst
vmap!(f::Functor, x1::AbstractArray, xr::ArrayOrNumber...)   # update x1

vmap!(dst, Add(), x, y)   # dst <- x + y
vmap!(Add(), x, y)        # x <- x + y
```

Practical applications usually requires computing expressions in the form of ``f(x - y)``. We provide ``vmapdiff`` and ``vmapdiff!`` for this purpose, as follows:

```julia
vmapdiff(f, x, y)          # return an array as f(x - y)
vmapdiff!(dst, f, x, y)    # dst <- f(x - y)
```

Note that this function uses an efficient implementation, which completes the computation in one-pass and never creates the intermediate array ``x - y``. 


##### Pre-defined mapping functions

Julia already provides vectorized function for most math computations. In this package, we additionally define several functions for vectorized inplace computation (based on ``vmap!``), as follows

```julia
add!(x, y)        # x <- x + y
subtract!(x, y)   # x <- x - y
multiply!(x, y)   # x <- x .* y
divide!(x, y)     # x <- x ./ y
negate!(x)        # x <- -x
pow!(x, y)        # x <- x .^ y

abs!(x)           # x <- abs(x)
abs2!(x)          # x <- abs2(x)
rcp!(x)           # x <- 1 ./ x
sqrt!(x)          # x <- sqrt(x)
exp!(x)           # x <- exp(x)
log!(x)           # x <- log(x)

floor!(x)         # x <- floor(x)
ceil!(x)          # x <- ceil(x)
round!(x)         # x <- round(x)
trunc!(x)         # x <- trunc(x)
```
In the codes above, ``x`` must be an array (*i.e.* an instance of ``AbstractArray``), while ``y`` can be either an array or a scalar.

In addition, we also provide some useful functions using compound functors:

```julia
absdiff(x, y)     # abs(x - y)
sqrdiff(x, y)     # abs2(x - y)
fma(x, y, c)      # x + y .* c, where c can be array or scalar
fma!(x, y, c)     # x <- x + y .* c
```

##### Performance

For simple functions, such as ``x + y`` or ``exp(x)``, the performance of the vmap version such as ``vmap(Add(), x, y)`` and ``vmap(Exp(), x)`` is comparable to the Julia counter part. However, ``vmap`` can accelerate computation considerably in a variety of cases:

* When the result storage has been allocated (e.g. in iterative updating algorithms) or you want inplace update, then ``vmap!`` or the pre-defined inplace computation function can be used to avoid unnecessary memory allocation/garbage collection, which can sometimes be the performance killer.

* When the inner copy contains two or multiple steps, ``vmap`` and ``vmap!`` can complete the computation in one-pass without creating intermediate arrays, usually resulting in about ``2x`` or even more speed up. Benchmark shows that ``absdiff(x, y)`` and ``sqrdiff(x, y)`` are about ``2.2x`` faster than ``abs(x - y)`` and ``abs2(x - y)``. 

* The script ``test/benchmark_vmap.jl`` runs a series of benchmarks to compare the performance ``vmap`` and the Julia vectorized expressions for a variety of computation.



