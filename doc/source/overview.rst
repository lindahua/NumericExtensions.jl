Package Overview
=================

Julia provides a fantastic technical computing environment that allows you to write codes that are both performant and generic. However, as it is still at its early stage, some functions are not as performant as they can be and writing computational algorithms directly based on builtin functions may not give you the best performance. This package provides you with a variety of tools to address such issues.

Motivating example
-------------------

To see how this package may help you, let's first consider a simple example, that is, to compute the sum of squared difference between two vectors. This can be easily done in Julia in one line as follows

.. code-block:: julia

    r = sum(abs2(x - y))

Whereas this is simple, this expression involves some unnecessary operations that would lead to suboptimal performance: (1) it creates two temporary arrays respectively to store ``x - y`` and ``abs(x - y)``, (2) it completes the computation through three passes over the data -- computing ``x - y``, computing ``abs2(x - y)``, and finally computing the sum. Julia provides a ``mapreduce`` function which allows you to complete the operation in a single pass without creating any temporaries:

.. code-block:: julia

    r = mapreduce((x, y) -> abs2(x - y), +, x, y)

However, if you really run this you may probably find that this is even slower. The culprit here is that the anonymous function ``(x, y) -> abs2(x - y)`` is not lined, which will be resolved and called at each iteration. Therefore, to compute this efficiently, one has to write loops as below

.. code-block:: julia

    s = 0.
    for i = 1 : length(x)
    	s += abs2(x[i] - y[i])
    end

This is not too bad though, until you have more complex needs, e.g. computing this along each row/column of the matrix. Then writing the loops can become more involved, and it is more tricky to implement it in a cache-friendly way.

With this package, we can compute this efficiently without writing loops, as

.. code-block:: julia

    r = mapdiff_reduce(Abs2Fun(), Add(), x, y)

    # or more concise:
    r = sum_fdiff(Abs2Fun(), x, y)

    # to compute this along a specific dimension
    r = sum_fdiff(Abs2Fun(), x, y, dim)
	
Here, ``Abs2Fun`` and ``Add`` are *typed functors* provided by this package, which, unlike normal functions, can still be properly inlined with passed into a higher order function (thus causing zero overhead). This package extends ``map``, ``reduce``, and ``mapreduce`` to accept typed functors and as well introduces additional high order functions like ``mapdiff``, ``mapdiff_reduce``, ``sum_fdiff`` etc to simplify the usage in common cases. 

Benchmark shows that writing in this way is over *8x faster* than ``sum(abs2(x - y))``.

This package also provides a collection of specific functions to directly support very common computation. For this particular example, you can write ``sqdiffsum(x, y)``, where ``sqdiffsum`` is one of such functions provided here.


Main features
---------------

Main features of this package are highlighted below:

* Pre-defined functors that cover most typical mathematical computation;
* A easy way for user to define customized functors;
* Extended/specialized methods for ``map``, ``map!``, ``reduce``, and ``mapreduce``. These methods are carefully optimized, which often result in *2x - 10x* speed up;
* Additional functions such as ``map1!``, ``reduce!``, and ``mapreduce!`` that allow inplace updating or writing results to preallocated arrays;
* Vector broadcasting computation (supporting both inplace updating and writing results to new arrays).
* Fast shared-memory views of arrays.

Since many of the methods are extensions of base functions. Simply adding a statement ``using NumericExtensions`` is often enough for substantial performance improvement. Consider the following code snippet:

.. code-block:: julia

    using NumericExtensions

    x = rand(1000, 1000)
    r = sum(x, 2)

Here, when adding the statement ``using NumericExtensions`` *transparently replace* the method provided in the Base module by the specialized method in *NumericExtensions*. As a consequence, the statement ``r = sum(x, 2)`` becomes *6x* faster. Using additional functions provided by this package can further improve the performance. 


