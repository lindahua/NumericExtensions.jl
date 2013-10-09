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
r = mapdiff_reduce(Abs2(), Add(), x, y)

# or more concise:
r = sum_fdiff(Abs2(), x, y)

# to compute this along a specific dimension
r = sum_fdiff(Abs2(), x, y, dim)
```
	
Here, ``Abs2`` and ``Add`` are *typed functors* provided by this package, which, unlike normal functions, can still be properly inlined with passed into a higher order function (thus causing zero overhead). This package extends ``map``, ``reduce``, and ``mapreduce`` to accept typed functors and as well introduces additional high order functions like ``mapdiff``, ``mapdiff_reduce``, ``sum_fdiff`` etc to simplify the usage in common cases. 

Benchmark shows that writing in this way is over *8x faster* than ``sum(abs2(x - y))``.

This package also provides a collection of specific functions to directly support very common computation. For this particular example, you can write ``sqdiffsum(x, y)``, where ``sqdiffsum`` is one of such functions provided here.


#### Main features

Main features of this package are highlighted below:

* Pre-defined functors that cover most typical mathematical computation;
* A easy way for user to define customized functors;
* Extended/specialized methods for ``map``, ``map!``, ``reduce``, and ``mapreduce``. These methods are carefully optimized, which often result in *2x - 10x* speed up;
* Additional functions such as ``map1!``, ``reduce!``, and ``mapreduce!`` that allow inplace updating or writing results to preallocated arrays;
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
| sum        |            1.0167 |            1.4736 |            8.0788 | 
| mean       |            0.9970 |            1.0356 |            8.0300 | 
| max        |            3.2179 |            3.2375 |            5.4292 | 
| min        |            3.2659 |            3.1634 |            5.4276 | 
| var        |            7.3342 |            7.5871 |           13.9887 | 
| std        |            9.3873 |            6.3414 |           12.5393 | 
| sumabs     |           15.6732 |            4.9506 |           10.0663 | 
| maxabs     |            3.9600 |            3.4171 |            4.3049 | 
| minabs     |            3.4851 |            3.4207 |            4.7011 | 
| sumsq      |           30.8621 |            4.8748 |           12.9086 | 
| dot        |           10.2508 |            3.9924 |            8.5912 | 
| sumabsdiff |            9.7635 |            8.4295 |           12.1404 | 
| maxabsdiff |            4.7714 |            4.7187 |            5.3950 | 
| minabsdiff |            4.9776 |            4.7575 |            5.5193 | 
| sumsqdiff  |           10.5738 |            9.0984 |           12.8125 | 

(Updated on July 5, 2013)

You can notice remarkable or even drastical speed up for many of these functions. 

#### Documentation

Please refer to [here](http://lindahua.github.io/NumericExtensions.jl/index.html) for detailed documentation.


