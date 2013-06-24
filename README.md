## NumericExtensions.jl

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

Run this script in you computer, you will find that statement (1) is over *20+ times* slower than statement (2). The reason is that the function argument ``plus`` is resolved and called at each iteration of the inner loop within the ``map`` function.

This package addresses this issue through *type functors* (*i.e.* function-like objects with specific types) and a set of highly optimized higher level functions for mapping and reduction. The codes above can be rewritten as

```julia
using NumericExtensions

 # benchmark
@time for i in 1 : 10 map(Add(), a, b) end     # -- statement(1)
@time for i in 1 : 10 a + b end                # -- statement(2)
```  

Here, using a typed functor ``Add`` and an extended ``map`` function provided in this package, statement (1) is *20%* faster than statement (2) in my benchmark (run ``test/benchmark_map.jl``). The reason is that typed functors triggered the compilation of specialized methods, where the codes associated with the functor will probably be *inlined*.

### Main Features

The package aims to provide generic and high performance functions for numerical computation, especially *mapping*, *reduction*, and *map-reduction*. Main features of this package are highlighted below:

* Pre-defined functors that cover most typical mathematical computation;
* A easy way for user to define customized functors;
* Extended/specialized methods for ``map``, ``map!``, ``reduce``, and ``mapreduce``. These methods are carefully optimized, which often result in *2x - 10x* speed up;
* Additional functions such as ``map1!``, ``reduce!``, and ``mapreduce!`` that allow inplace updating or writing results to preallocated arrays;
* Vector broadcasting computation (supporting both inplace updating and writing results to new arrays).
* Shared-memory views of arrays.

Since many of the methods are extensions of base functions. Simply adding a statement ``using NumericExtensions`` is often enough for substantial performance improvement. Consider the following code snippet:

```julia
using NumericExtensions

x = rand(1000, 1000)
r = sum(x, 2)
```

Here, when adding the statement ``using NumericExtensions`` *transparently replace* the method provided in the Base module by the specialized method in *NumericExtensions*. As a consequence, the statement ``r = sum(x, 2)`` becomes *6x* faster. Using additional functions provided by this package can further improve the performance. For example, modifying ``sum(abs2(x - y))`` to ``sqdiffsum(x, y)`` leads to nearly *11x* speed up.


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
* Others: ``Xlogx``, ``Xlogy``

Except for several functors that corresponding to operators, most functors are named using the capitalized version of the corresponding math function. Therefore, you don't have to look up this list to find the names. The collection of pre-defined functors will be extended in future. Please refer to ``src/functors.jl`` for the most updated list.

##### Customized functors

User can define new functors by sub-typing ``Functor``. For example, to define a functor that calculates squared difference, we can do the following:

```julia
type SqrDiff <: BinaryFunctor end

NumericExtensions.evaluate(::SqrDiff, x, y) = abs2(x - y)
NumericExtensions.result_type(::SqrDiff, t1::Type, t2::Type) = promote_type(t1, t2)
```

To define multiple functors, it would be more concise to first import ``evaluate`` and ``result_type`` before extending them, as follows:

```julia
import NumericExtensions.evaluate, NumericExtensions.result_type

type SqrDiff <: BinaryFunctor end

evaluate(::SqrDiff, x, y) = abs2(x - y)
result_type(::SqrDiff, t1::Type, t2::Type) = promote_type(t1, t2)
```

**Note:** Higher order functions such as ``map`` and ``reduce`` rely on the ``result_type`` method to determine the element type of the result. This is necessary, as Julia does not provide a generic mechanism to acquire the return type of a method.


### Mapping

This package provides extended methods of ``map`` and ``map!`` that allows efficient element-wise mapping using functors:

```julia
typealias ArrayOrNumber Union(AbstractArray, Number)

map(f::Functor, xs::ArrayOrNumber...)   # perform element-wise computation using functor f
                                         # each argument in xs can be either an array or a number

map(Sqrt(), x)       # == sqrt(x)
map(Add(), x, 1)     # == x + 1
map(FMA(), x, y, z)  # == x + y .* z
```

The function ``map!`` allows writing results to a pre-allocated array, while ``map1!`` allows inplace updating of the first argument, which is often handy and efficient:

```julia
map!(f, dst, xs...)   # write results to dst
map1!(f, x1, xr...)   # update x1

map!(Add(), dst, x, y)   # dst <- x + y
map1!(Add(), x, y)       # x <- x + y
```

Practical applications usually requires computing expressions in the form of ``f(x - y)``. We provide ``mapdiff`` and ``mapdiff!`` for this purpose, as follows:

```julia
mapdiff(f, x, y)          # return an array as f(x - y)
mapdiff!(f, dst, x, y)    # dst <- f(x - y)
```

Note that this function uses an efficient implementation, which completes the computation in one-pass and never creates the intermediate array ``x - y``. 


##### Pre-defined mapping functions

Julia already provides vectorized function for most math computations. In this package, we additionally define several functions for vectorized inplace computation (based on ``map!``), as follows

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

For simple functions, such as ``x + y`` or ``exp(x)``, the performance of the map version such as ``map(Add(), x, y)`` and ``map(Exp(), x)`` is comparable to the Julia counter part. However, ``map`` can accelerate computation considerably in a variety of cases:

* When the result storage has been allocated (e.g. in iterative updating algorithms) or you want inplace update, then ``map!`` or the pre-defined inplace computation function can be used to avoid unnecessary memory allocation/garbage collection, which can sometimes be the performance killer.

* When the inner copy contains two or multiple steps, ``map`` and ``map!`` can complete the computation in one-pass without creating intermediate arrays, usually resulting in about ``2x`` or even more speed up. Benchmark shows that ``absdiff(x, y)`` and ``sqrdiff(x, y)`` are about ``2.2x`` faster than ``abs(x - y)`` and ``abs2(x - y)``. 

* The script ``test/benchmark_map.jl`` runs a series of benchmarks to compare the performance ``map`` and the Julia vectorized expressions for a variety of computation.


### Shared-memory Views

Getting a slice/part of an array is common in numerical computation. Julia itself provides two ways to do this: reference (e.g. ``x[:, J]``) and the ``sub`` function (e.g. ``sub(x, :, J)``). Both have performance issues: the former makes a copy each time you call it, while the latter results in an ``SubArray`` instance. Despite that ``sub`` does not create a copy, accessing elements of a ``SubArray`` instance is usually very slow (with current implementation).

This package addresses this problem by providing a ``unsafe_view`` function, which returns a view of specific part of an array. **Note** that ``unsafe_view`` only applies to the case when the part being referenced is contiguous. Below is a list of valid usage:

```julia
unsafe_view(a)

unsafe_view(a, :)
unsafe_view(a, i0:i1)

unsafe_view(a, :, :)
unsafe_view(a, :, j)
unsafe_view(a, i0:i1, j)
unsafe_view(a, :, j0:j1)

unsafe_view(a, :, j, k)
unsafe_view(a, i0:i1, j, k)
unsafe_view(a, :, :, k)
unsafe_view(a, :, j0:j1, k)

unsafe_view(a, :, :, :)
unsafe_view(a, :, :, k0:k1)
```


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

The function ``vbroadcast!`` writes results to a pre-allocated array, and ``vbroadcast1!`` updates the first argument inplace:
```julia
vbroadcast!(f, fst, x, y)   # results written to a pre-allocated array dst
vbroadcast1!(f, x, y)        # x will be updated by results
```

##### Performance

``broadcast`` is more general than ``vbroadcast`` in functionality. However, ``vbroadcast`` can offer better performance in various cases:

* Benchmark (``test/benchmark_vbroadcast.jl``) shows that ``vbroadcast(x, y, 2)`` and ``vbroadcast(x, y, 3)`` improve the performance by ``50%`` to ``80%`` as compared to ``broadcast``, while ``vbroadcast(x, y, 1)`` is comparable to ``broadcast``.

* ``vbroadcast`` allows the use of functors (instead of functions) as argument, which can lead to over ``20x`` speed-up in most cases. 

* At the expense of requiring the user to input ``dims``, the overhead of broadcasting shape computation is reduced. 


### Reduction and Map-Reduction

A key advantage of this package are highly optimized reduction and map-reduction functions, which sometimes lead to over ``10x`` speed up. 

This package extends ``reduce`` and ``mapreduce``, and additionally provides ``mapdiff_reduce`` for generic reduction and map-reduction, as follows

```julia
reduce(op, x)   # reduction using op to combine values
                # e.g. vreduce(Add(), x) is equivalent to sum(x)

mapreduce(f, op, fxs...)   # use functor f to compute terms and then use op to combine them
                           # each argument in xs can be either an array or a scalar

 # examples:
mapreduce(Abs2(), Add(), x)           # compute the sum of squared of x (i.e. sum(abs2(x)))
mapreduce(Multiply(), Add(), x, y)    # compute the dot product between x, y

mapdiff_reduce(f, op, x, y)   # use f to compute terms based on x - y, and then reduce

 # examples:
mapdiff_reduce(Abs2(), Max(), x, y)   # compute the maximum squared difference between x and y
```

The function ``vreduce`` also allows reduction along specific dimension(s):

```julia
reduce(Add(), x, 1)      # sum x along columns
reduce(Add(), x, 2)      # sum x along rows
reduce(Add(), x, dim)    # sum x along a specific dimension

reduce(Add(), x, (1, 2))   # sum each page of x
reduce(Add(), x, (1, 3))   # sum along both the first and the third dimension

 # map reduction along specific dimension(s), here both f and op are functors
mapreduce(f, op, x, dims)
mapreduce(f, op, x1, x2, dims)
mapreduce(f, op, x1, x2, x3, dims)
```

**Note:** When ``dims`` is an integer, arguments can be arrays/scalars of arbitrary number of dimensions, and ``dims`` can take any integer value. When ``dims`` is a pair of integers such as ``(1, 2)`` or ``(2, 3)``, each argument must be either a cube or a scalar. We believe this has covered most usage in practice. That being said, we will try to support cases where ``dims`` can be an arbitrary tuple in the future.

``mapdiff_reduce`` also supports reduction along specific dimension(s) in a similar way.

The package additionally provides ``reduce!``, ``mapreduce!``, and ``mapdiff_reduce!``, which allow to write the results of reduction/map-reduction along dimensions to pre-allocated arrays:

```julia
reduce!(dst, op, x, dims)
mapreduce!(dst, f, op, x1)
mapreduce!(dst, f, op, x1, x2, dims)
mapreduce!(dst, f, op, x1, x2, x3, dims)
mapdiff_reduce!(dst, f, op, x, y, dims)
```

###### Pre-defined reduction functions

The package extends/specializes ``sum``, ``max``, and ``min``, and additionally provides ``sum!``, ``max!``, and ``min!``, as follows

The funtion ``sum`` and its variant forms:

```julia
sum(x)
sum(f, x)            # compute sum of f(x)
sum(f, x1, x2)       # compute sum of f(x1, x2)
sum(f, x1, x2, x3)   # compute sum of f(x1, x2, x3)

sum(x, dims)
sum(f, x, dims)
sum(f, x1, x2, dims)
sum(f, x1, x2, x3, dims)

sum!(dst, x, dims)
sum!(dst, f, x1, dims)
sum!(dst, f, x1, x2, dims)
sum!(dst, f, x1, x2, x3, dims)

sum_fdiff(f, x, y)     # compute sum of f(x - y)
sum_fdiff(f, x, y, dims)
sum_fdiff!(dst, f, x, y, dims)
```

The function ``max`` and its variants:

```julia
max(x)
max(f, x)            # compute max of f(x)
max(f, x1, x2)       # compute max of f(x1, x2)
max(f, x1, x2, x3)   # compute max of f(x1, x2, x3)

max(x, (), dims)
max(f, x, dims)
max(f, x1, x2, dims)
max(f, x1, x2, x3, dims)

max!(dst, x, (), dims)
max!(dst, f, x1, dims)
max!(dst, f, x1, x2, dims)
max!(dst, f, x1, x2, x3, dims)

max_fdiff(f, x, y)     # compute max of f(x - y)
max_fdiff(f, x, y, dims)
max_fdiff!(dst, f, x, y, dims)
```

The function ``min`` and its variants

```julia
min(x)
min(f, x)            # compute min of f(x)
min(f, x1, x2)       # compute min of f(x1, x2)
min(f, x1, x2, x3)   # compute min of f(x1, x2, x3)

min(x, (), dims)
min(f, x, dims)
min(f, x1, x2, dims)
min(f, x1, x2, x3, dims)

min!(dst, x, (), dims)
min!(dst, f, x1, dims)
min!(dst, f, x1, x2, dims)
min!(dst, f, x1, x2, x3, dims)

min_fdiff(f, x, y)     # compute min of f(x - y)
min_fdiff(f, x, y, dims)
min_fdiff!(dst, f, x, y, dims)
```

In addition to these basic reduction functions, we also define a set of derived reduction functions, as follows:

```julia
mean(x)
mean(x, dims)
mean!(dst, x, dims)

var(x)
var(x, dim)
var!(dst, x, dim)

std(x)
std(x, dim)
std!(dst, x, dim)

asum(x)  # == sum(abs(x))
asum(x, dims)
asum!(dst, x, dims)

amax(x)   # == max(abs(x))
amax(x, dims)
amax!(dst, x, dims)

amin(x)   # == min(abs(x))
amin(x, dims)
amin!(dst, x, dims)

sqsum(x)  # == sum(abs2(x))
sqsum(x, dims)
sqsum!(dst, x, dims)

dot(x, y)  # == sum(x .* y)
dot(x, y, dims)
dot!(dst, x, y, dims)

adiffsum(x, y)   # == sum(abs(x - y))
adiffsum(x, y, dims)
adiffsum!(dst, x, y, dims)

adiffmax(x, y)   # == max(abs(x - y))
adiffmax(x, y, dims)
adiffmax!(dst, x, y, dims)

adiffmin(x, y)   # == min(abs(x - y))
adiffmin(x, y, dims)
adiffmin!(dst, x, y, dims)

sqdiffsum(x, y)  # == sum(abs2(x - y))
sqdiffsum(x, y, dims)
sqdiffsum!(dst, x, y, dims)

vnorm(x, p)   # == norm(vec(x), p)
vnorm(x, p, dims)
vnorm!(dst, x, p, dims)

vdiffnorm(x, y, p)  # == norm(vec(x - y), p)
vdiffnorm(x, y, p, dims)
vdiffnorm!(dst, x, y, p, dims)
```

Although this is quite a large set of functions, the actual code is quite concise, as most of such functions are generated through macros (see ``src/reduce.jl``)

In addition to the common reduction functions, this package also provides a set of statistics functions that are particularly useful in probabilistic or information theoretical computation, as follows

```julia
sum_xlogx(x)  # == sum(xlogx(x)) with xlog(x) = x > 0 ? x * log(x) : 0
sum_xlogx(x, dims)
sum_xlogx!(dst, x, dims)

sum_xlogy(x, y)  # == sum(xlog(x,y)) with xlogy(x,y) = x > 0 ? x * log(y) : 0
sum_xlogy(x, y, dims)
sum_xlogy!(dst, x, y, dims)

entropy(x)   # == - sum_xlogx(x)
entropy(x, dims)
entropy!(dst, x, dims)

logsumexp(x)   # == log(sum(exp(x)))
logsumexp(x, dim)
logsumexp!(dst, x, dim)

softmax!(dst, x)    # dst[i] = exp(x[i]) / sum(exp(x))
softmax(x)
softmax!(dst, x, dim)
softmax(x, dim)
```

For ``logsumexp`` and ``softmax``, special care is taken to ensure numerical stability for large x values, that is, their values will be properly shifted during computation.


##### Performance

The reduction and map-reduction functions are carefully optimized. In particular, several tricks lead to performance improvement:

* computation is performed in a cache-friendly manner;
* computation completes in a single pass without creating intermediate arrays;
* kernels are inlined via the use of typed functors;
* inner loops use linear indexing (with pre-computed offset);
* opportunities of using BLAS are exploited.

Below is a table that compares the performance with vectorized Julia expressions (the numbers in the table are speed-up ratio of the functions in this package as opposed to the Julia expressions):

|            | full reduction    | colwise reduction | rowwise reduction | 
|------------|------------------:|------------------:|------------------:|
| sum        |            1.0226 |            1.4240 |            6.0690 | 
| max        |            2.8189 |            2.8360 |            4.9710 | 
| min        |            2.7882 |            2.8397 |            4.9209 | 
| mean       |            1.0320 |            1.0495 |            5.9525 | 
| var        |            6.6246 |           24.7842 |           20.5711 | 
| std        |            6.5594 |           25.5396 |           20.2574 | 
| asum       |           15.1029 |            6.8452 |           10.8808 | 
| amax       |            3.4944 |            3.1673 |            4.4154 | 
| amin       |            3.5981 |            3.2054 |            4.0856 | 
| sqsum      |           28.7898 |            6.5466 |            9.5175 | 
| dot        |           10.0092 |            4.4618 |            6.1406 | 
| adiffsum   |            7.9627 |            7.4145 |            8.9031 | 
| adiffmax   |            4.1893 |            4.5171 |            5.2755 | 
| adiffmin   |            4.5097 |            4.4343 |            5.2083 | 
| sqdiffsum  |            8.1937 |            8.3540 |           10.7342 | 


Here, full reduction with ``asum``, ``sqsum``, and ``dot`` utilize BLAS level 1 routines, and they achieve *10x* to *30x* speed up. Even though BLAS is not used in other cases, we still observe remarkable improvement there, especially for rowwise reduction and when the kernel is a compound of more than one steps (*e.g.*, we notice over *10x* speed up for rowwise squared sum).

For ``var`` and ``std``, we devise dedicated procedures, where computational steps are very carefully scheduled such that most computation is conducted in a single pass. This results in very remarkable speed up, as you can see from the table above.




