## NumericExtensions.jl

[![Build Status](https://travis-ci.org/lindahua/NumericExtensions.jl.png)](https://travis-ci.org/lindahua/NumericExtensions.jl)

Julia extensions to provide high performance computational support.

-------------------------------------

Julia is a fantastic technical computing environment that allows you to write codes that are both performant and generic. However, as it is still at its early stage, some functions are not as performant as they can be and writing computational algorithms directly based on builtin functions may not give you the best performance. This package provides you with a variety of tools to address such issues.

To see how this package may help you, let's first consider a simple example, that is, to compute the sum of squared difference between two vectors. This can be easily done in Julia in one line as follows

```julia
r = sum(abs2(x - y))
```

Whereas this is simple, this expression involves some unnecessary operations that would lead to suboptimal performance: (1) it creates two temporary arrays respectively to store ``x - y`` and ``abs(x - y)``, (2) it completes the computation through three passes over the data -- computing ``x - y``, computing ``abs2(x - y)``, and finally computing the sum. Julia provides a ``mapreduce`` function which allows you to complete the operation in a single pass without creating any temporaries:

```julia
r = mapreduce((x, y) -> abs2(x - y), +, x, y)
```

However, if you really run this you may probably find that this is even slower. The culprit here is that the anonymous function ``(x, y) -> abs2(x - y)`` is not lined, which will be resolved and called at each iteration. Therefore, to compute this efficiently, one has to write loops as below

```julia
s = 0.
for i = 1 : length(x)
	s += abs2(x[i] - y[i])
end
```

This is not too bad though, until you have more complex needs, e.g. computing this along each row/column of the matrix. Then writing the loops can become more involved, and it is more tricky to implement it in a cache-friendly way.

With this package, we can compute this efficiently without writing loops, as

```julia
r = sumfdiff(Abs2Fun(), x, y)

# to compute this along a specific dimension
r = sumfdiff(Abs2Fun(), x, y, dim)
```
	
Here, ``Abs2Fun`` and ``Add`` are *typed functors* provided by this package, which, unlike normal functions, can still be properly inlined with passed into a higher order function (thus causing zero overhead). This package extends ``map``, ``foldl``, ``sum``, ``maximum`` etc to accept typed functors and as well introduces additional high order functions like ``sumfdiff`` and ``scan`` etc to simplify the usage in other common cases. 

Benchmark shows that writing in this way is over *9x faster* than ``sum(abs2(x - y))``.

This package also provides a collection of specific functions to directly support very common computation. For this particular example, you can write ``sumsqdiff(x, y)``, where ``sumsqdiff`` is one of such functions provided here.


#### Main features

Main features of this package are highlighted below:

* Pre-defined functors that cover most typical mathematical computation;
* Easy ways for user to define customized functors;
* Extended/specialized methods for ``map``, ``map!``, ``foldl``, and ``foldr``. These methods are carefully optimized, which often result in *2x - 10x* speed up;
* Additional functions such as ``map1!``, ``reduce!``, and ``mapreduce!`` that allow inplace updating or writing results to preallocated arrays;
* Extended methods for ``sum``, ``maximum``, ``minimum`` that allow reduction over function values (e.g. ``sum(Abs2(), x)``). It also introduces ``sum!``, ``maximum!``, and ``minimum!`` that allows writing results to preallocated storage when performing reduction along a specific dimension. 
* A collection of highly optimized numerical computation functions, e.g. ``sumabs``, ``sumsq``, ``sumabsdiff``, ``sumsqdiff``, etc.
* Highly optimized statistical functions, e.g. ``varm``, ``var``, ``stdm``, ``std``, ``logsumexp``, and ``softmax``, etc.
* Vector broadcasting computation (supporting both inplace updating and writing results to new arrays).
* Fast shared-memory views of arrays.


#### Performance

Functions in this package are carefully optimized. In particular, several tricks lead to performance improvement:

* computation is performed in a cache-friendly manner;
* computation completes in a single pass without creating intermediate arrays;
* kernels are inlined via the use of typed functors;
* inner loops use linear indexing (with pre-computed offset);
* opportunities of using BLAS are exploited.

Below is a table that compares the performance of several reduction/map-reduction functions with vectorized Julia expressions (the numbers in the table are speed-up ratio of the functions in this package as opposed to the Julia expressions):

|            | full reduction    | colwise reduction | rowwise reduction | 
|------------|------------------:|------------------:|------------------:|
| sum        |            2.0937 |            2.8078 |           10.4734 | 
| mean       |            1.9904 |            2.1337 |           10.5682 | 
| max        |            1.5099 |            1.8758 |            6.4157 | 
| min        |            1.4989 |            1.8951 |            6.3920 | 
| var        |            1.3661 |            7.8874 |           13.3508 | 
| std        |            1.3478 |            7.6905 |           12.5884 | 
| sumabs     |           15.3186 |           12.0027 |           11.9859 | 
| maxabs     |            3.3363 |            3.3574 |            8.8502 |
| minabs     |            3.9176 |            3.3089 |            8.1781 |
| sumsq      |           28.4254 |           10.9547 |           12.9004 | 
| dot        |           10.1431 |            6.1043 |            9.1512 |
| sumabsdiff |            6.9483 |            8.1992 |           11.8763 | 
| maxabsdiff |            4.9515 |            4.8702 |            8.6670 |
| minabsdiff |            4.8202 |            4.8156 |            8.7172 | 
| sumsqdiff  |            9.2721 |            8.9602 |           13.8102 |
| logsumexp  |            4.8980 |            6.0000 |            6.0321 |
| softmax    |            4.6224 |            4.8134 |            5.1364 | 

(Updated on Dec 19, 2013, Julia version 0.3.0-prerelease+579, NumericExtensions version 0.3.0)

You can notice remarkable speed up for many of these functions. 

#### Documentation

Please refer to [here](http://lindahua.github.io/NumericExtensions.jl/index.html) for detailed documentation.


