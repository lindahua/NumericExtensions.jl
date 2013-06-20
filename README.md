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


### Broadcasting

Julia has a very nice and performant ``broadcast`` and ``broadcast!`` function, which however does not work with functors. For customized computation, you have to pass in function argument, which would lead to severe performance degradation. This package provides ``vbroadcast`` and ``vbroadcast!`` to address this issue.

```julia
vbroadcast(f, x, y, dim)  # apply vector y to vectors of x along dimension dim

vbroadcast(f, x, y, 1)    # r[:,i] = f(x[:,i], y)
vbroadcast(f, x, y, 2)    # r[i,:] = f(x[i,:], y)

vbroadcast(f, x, y, 3)    # r[i,j,:] = f(x[i,j,:], y)
```

Unlike ``broadcast``, you have to specify the vector dimension for ``vbroadcast``. The benefit is two-fold: (1) the overhead of figuring out broadcasting shape information is elimintated; (2) the shape of ``y`` can be flexible. It is fine as along as ``length(y) == size(x, dim)``. For example

```julia
x = rand(5, 6)
y = rand(6)

vbroadcast(Add(), x, y, 2)    # this adds y to each row of x
broadcast(+, x, reshape(y, 1, 6))  # with broadcast, you have to first reshape y into a row
```

For cubes, it supports computation along two dimensions
```julia
x = rand(2, 3, 4)
y = rand(2, 3)

vbroadcast(x, y, (1, 2))    # this adds y to each page of x
```

The function ``vbroadcast!`` supports inplace computation:
```julia
vbroadcast!(dst, f, x, y)   # results written to a pre-allocated array dst
vbroadcast!(f, x, y)        # x will be overrided by results
```

##### Performance

``broadcast`` is more general than ``vbroadcast`` in functionality. However, ``vbroadcast`` can offer better performance in various cases:

* Benchmark (``test/benchmark_vbroadcast.jl``) shows that ``vbroadcast(x, y, 2)`` and ``vbroadcast(x, y, 3)`` improve the performance by ``50%`` to ``80%`` as compared to ``broadcast``, while ``vbroadcast(x, y, 1)`` is comparable to ``broadcast``.

* ``vbroadcast`` allows the use of functors (instead of functions) as argument, which can lead to over ``20x`` speed-up in most cases. 

* At the expense of requiring the user to input ``dims``, the overhead of broadcasting shape computation is reduced. 


### Reduction and Map-Reduction

A key advantage of this package are highly optimized reduction and map-reduction functions, which sometimes lead to over ``10x`` speed up. 

This package provides ``vreduce`` and ``vreduce_fdiff`` for generic reduction and map-reduction, as follows

```julia
vreduce(op::BinaryFunctor, x)  # reduction using op to combine values
                               # e.g. vreduce(Add(), x) is equivalent to sum(x)

vreduce(op::BinaryFunctor, f, xs...)  # use functor f to compute terms and then use op to combine them
                                      # each argument in xs can be either an array or a scalar

 # examples:
vreduce(Add(), Abs2(), x)           # compute the sum of squared of x (i.e. sum(abs2(x)))
vreduce(Add(), Multiply(), x, y)    # compute the dot product between x, y

vreduce_fdiff(op::BinaryFunctor, f::UnaryFunctor, x, y)   # use f to compute terms based on x - y, and then reduce

 # examples:
vreduce_fdiff(Max(), Abs2(), x, y)   # compute the maximum squared difference between x and y
```

The function ``vreduce`` also allows reduction along specific dimension(s):

```julia
vreduce(Add(), x, 1)      # sum x along columns
vreduce(Add(), x, 2)      # sum x along rows
vreduce(Add(), x, dim)    # sum x along a specific dimension

vreduce(Add(), x, (1, 2))   # sum each page of x
vreduce(Add(), x, (1, 3))   # sum along both the first and the third dimension

 # map reduction along specific dimension(s)
vreduce(op, f::UnaryFunctor, x, dims)
vreduce(op, f::BinaryFunctor, x1, x2, dims)
vreduce(op, f::TernaryFunctor, x1, x2, x3, dims)
```

**Note:** When ``dims`` is an integer, arguments can be arrays/scalars of arbitrary number of dimensions, and ``dims`` can take any integer value. When ``dims`` is a pair of integers such as ``(1, 2)`` or ``(2, 3)``, each argument must be either a cube or a scalar. We believe this has covered most usage in practice. That being said, we will try to support cases where ``dims`` can be an arbitrary tuple in the future.

``vreduce_fdiff`` also supports reduction along specific dimension(s) in a similar way.

The functions ``vreduce!`` and ``vreduce_fdiff`` allow to write reduction results to pre-allocated arrays:

```julia
vreduce!(dst, op, x, dims)
vreduce!(dst, op, f::UnaryFunctor, x1)
vreduce!(dst, op, f::BinaryFunctor, x1, x2, dims)
vreduce!(dst, op, f::TernaryFunctor, x1, x2, x3, dims)
vreduce_fdiff!(dst, op, f::BinaryFunctor, x, y, dims)
```

###### Pre-defined reduction functions

The package provides commonly used reduction functions: ``vsum``, ``vmax``, and ``vmin``, as follows

```julia
vsum(x)
vsum(f, x)
vsum(f, x1, x2)
vsum(f, x1, x2, x3)

vsum(x, dims)
vsum(f, x, dims)
vsum(f, x1, x2, dims)
vsum(f, x1, x2, x3, dims)

vsum!(dst, x, dims)
vsum!(dst, f, x1, dims)
vsum!(dst, f, x1, x2, dims)
vsum!(dst, f, x1, x2, x3, dims)

vsum_fdiff(x, y)
vsum_fdiff(x, y, dims)
vsum_fdiff!(dst, f, x, y, dims)
```

Functions ``vmax`` and ``vmin`` provide methods of all such varieties.

In addition to these basic reduction functions, we also define a set of derived reduction functions, as follows:

```julia
vasum(x)  # == sum(abs(x))
vasum(x, dims)
vasum!(dst, x, dims)

vamax(x)   # == max(abs(x))
vamax(x, dims)
vamax!(dst, x, dims)

vamin(x)   # == min(abs(x))
vamin(x, dims)
vamin!(dst, x, dims)

vsqsum(x)  # == sum(abs2(x))
vsqsum(x, dims)
vsqsum!(dst, x, dims)

vdot(x, y)  # == sum(x .* y)
vdot(x, y, dims)
vdot!(dst, x, y, dims)

vadiffsum(x, y)   # == sum(abs(x - y))
vadiffsum(x, y, dims)
vadiffsum!(dst, x, y, dims)

vadiffmax(x, y)   # == max(abs(x - y))
vadiffmax(x, y, dims)
vadiffmax!(dst, x, y, dims)

vadiffmin(x, y)   # == min(abs(x - y))
vadiffmin(x, y, dims)
vadiffmin!(dst, x, y, dims)

vsqdiffsum(x, y)  # == sum(abs2(x - y))
vsqdiffsum(x, y, dims)
vsqdiffsum!(dst, x, y, dims)

vnorm(x, p)   # == norm(x, p)
vnorm(x, p, dims)
vnorm!(dst, x, p, dims)

vdiffnorm(x, y, p)  # == norm(x - y, p)
vdiffnorm(x, y, p, dims)
vdiffnorm!(dst, x, y, p, dims)
```

Although this is quite a large set of functions, the actual code is quite concise, as most of such functions are generated through macros (see ``src/vreduce.jl``)


##### Performance

The reduction and map-reduction functions are carefully optimized. In particular, several tricks lead to performance improvement:

* computation is performed in a cache-friendly manner;
* computation completes in a single pass without creating intermediate arrays;
* kernels are inlined via the use of typed functors;
* inner loops use linear indexing (with pre-computed offset);
* opportunities of using BLAS are exploited.

Below is a table that compares the performance with vectorized Julia expressions (when gain > 1, it means the function in this package is faster than the ordinary Julia expression):

| function     | full reduction  | colwise reduction | rowwise reduction |   
|--------------|-----------------|-------------------|-------------------|
|  vsum        |   1.105         |    1.278          |    6.300          |
|  vmax        |   1.870         |    1.802          |    2.874          |
|  vmin        |   1.900         |    1.813          |    3.098          |
|  vasum       |  *16.057*       |    6.869          |    9.891          |
|  vamax       |   3.497         |    3.645          |    4.455          |
|  vamin       |   3.431         |    3.649          |    4.434          |
|  vsqsum      |  *36.440*       |    7.014          |    9.420          |
|  vdot        |  *11.941*       |    6.380          |    7.912          |
|  vadiffsum   |   6.216         |    7.471          |    9.359          |
|  vadiffmax   |   4.911         |    4.554          |    5.222          |
|  vadiffmin   |   4.894         |    4.527          |    5.310          |
|  vsqdiffsum  |   8.146         |    8.234          |   10.859          |

Here, full reduction with ``vasum``, ``vsqsum``, and ``vdot`` utilize BLAS level 1 routines, and they achieve *10x* to *40x* speed up. Even though BLAS is not used in other cases, we still observe remarkable improvement there, especially for rowwise reduction and when the kernel is a compound of more than one steps (*e.g.*, we notice over *10x* speed up for rowwise squared sum).

