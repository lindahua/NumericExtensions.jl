Reduction
===========

A key advantage of this package are highly optimized reduction and map-reduction functions, which sometimes lead to over ``10x`` speed up. 

Full reduction
---------------

**Synopsis**

This package extends ``reduce`` and ``mapreduce``, and additionally provides ``mapdiff_reduce`` for generic reduction and map-reduction.

Let ``f1``, ``f2``, and ``f3`` be respectively unary, binary, and ternary functors, and ``op`` be an binary functor.
The general usage of these extended methods is summarized below:

.. code-block:: julia

    reduce(op, x)   # reduction using op to combine values

    mapreduce(f1, op, x)             # reduction using op to combine terms as f1(x)
    mapreduce(f2, op, x1, x2)        # reduction using op to combine terms as f2(x1, x2)
    mapreduce(f3, op, x1, x2, x3)    # reduction using op to combine terms as f3(x1, x2, x3)

    mapdiff_reduce(f2, op, x, y)     # reduction using op to combine terms as f2(x - y)

**Examples**

.. code-block:: julia

    mapreduce(Abs2(), Add(), x)           # compute the sum of squared of x (i.e. sum(abs2(x)))
    mapreduce(Multiply(), Add(), x, y)    # compute the dot product between x, y
    mapdiff_reduce(Abs2(), Max(), x, y)   # compute the maximum squared difference between x and y


Reduction along dimensions
----------------------------

The extended ``reduce`` and ``mapreduce`` and the additional ``mapdiff_reduce`` also allow reduction along specific dimension(s):

**Synopsis**

.. code-block:: julia

    reduce(op, x, dims)
    
    mapreduce(f1, op, x, dims)
    mapreduce(f2, op, x1, x2, dims)
    mapreduce(f3, op, x1, x2, x3, dims)

    mapdiff_reduce(f2, op, x, y, dims)


Here, ``dims`` can be either an integer to specify arbitrary dimension, or a pair of integers such as ``(1, 2)`` for reduction along two dimensions. 

When ``dims`` is a pair of integers such as ``(1, 2)`` or ``(2, 3)``, each argument must be either a cube or a scalar. We believe this has covered most usage in practice. That being said, we will try to support cases where ``dims`` can be an arbitrary tuple in the future.

The package additionally provides ``reduce!``, ``mapreduce!``, and ``mapdiff_reduce!``, which allow to write the results of reduction/map-reduction along dimensions to pre-allocated arrays:

.. code-block:: julia

    reduce!(dst, op, x, dims)

    mapreduce!(dst, f1, op, x1)
    mapreduce!(dst, f2, op, x1, x2, dims)
    mapreduce!(dst, f3, op, x1, x2, x3, dims)

    mapdiff_reduce!(dst, f2, op, x, y, dims)

**Examples**

.. code-block:: julia

    reduce(Add(), x, 1)      # sum x along columns
    reduce(Add(), x, 2)      # sum x along rows

    reduce(Add(), x, (1, 2))   # sum each page of x
    reduce(Add(), x, (1, 3))   # sum along both the first and the third dimension

    mapreduce(Abs(), Max(), x, 1)   # compute maximum absolute value along each column
    mapreduce(Sqr(), Add(), x, 2)   # compute sum square along each row

    mapdiff_reduce(Abs(), Min(), x, y, (1, 2))  # compute minimum absolute difference 
                                                # between x and y for each page

Basic reduction functions
---------------------------

The package extends/specializes ``sum``, ``max``, and ``min``, and additionally provides ``sum!``, ``max!``, and ``min!``, as follows

The funtion ``sum`` and its variant forms:

.. code-block:: julia 

    sum(x)
    sum(f1, x)            # compute sum of f1(x)
    sum(f2, x1, x2)       # compute sum of f2(x1, x2)
    sum(f3, x1, x2, x3)   # compute sum of f3(x1, x2, x3)

    sum(x, dims)
    sum(f1, x, dims)
    sum(f2, x1, x2, dims)
    sum(f3, x1, x2, x3, dims)

    sum!(dst, x, dims)    # write results to dst
    sum!(dst, f1, x1, dims)
    sum!(dst, f2, x1, x2, dims)
    sum!(dst, f3, x1, x2, x3, dims)

    sum_fdiff(f2, x, y)     # compute sum of f2(x - y)
    sum_fdiff(f2, x, y, dims)
    sum_fdiff!(dst, f2, x, y, dims)


The function ``max`` and its variants:

.. code-block:: julia

    max(x)
    max(f1, x)            # compute maximum of f1(x)
    max(f2, x1, x2)       # compute maximum of f2(x1, x2)
    max(f3, x1, x2, x3)   # compute maximum of f3(x1, x2, x3)

    max(x, (), dims)
    max(f1, x, dims)
    max(f2, x1, x2, dims)
    max(f3, x1, x2, x3, dims)

    max!(dst, x, dims)    # write results to dst
    max!(dst, f1, x1, dims)
    max!(dst, f2, x1, x2, dims)
    max!(dst, f3, x1, x2, x3, dims)

    max_fdiff(f2, x, y)     # compute maximum of f2(x - y)
    max_fdiff(f2, x, y, dims)
    max_fdiff!(dst, f2, x, y, dims)

The function ``min`` and its variants

.. code-block:: julia

    min(x)
    min(f1, x)            # compute minimum of f1(x)
    min(f2, x1, x2)       # compute minimum of f2(x1, x2)
    min(f3, x1, x2, x3)   # compute minimum of f3(x1, x2, x3)

    min(x, (), dims)
    min(f1, x, dims)
    min(f2, x1, x2, dims)
    min(f3, x1, x2, x3, dims)

    min!(dst, x, dims)    # write results to dst
    min!(dst, f1, x1, dims)
    min!(dst, f2, x1, x2, dims)
    min!(dst, f3, x1, x2, x3, dims)

    min_fdiff(f2, x, y)     # compute minimum of f2(x - y)
    min_fdiff(f2, x, y, dims)
    min_fdiff!(dst, f2, x, y, dims)

**Note:** when computing maximum/minimum along specific dimension, we use ``max(x, (), dims)`` and ``min(x, (), dims)`` instead of ``max(x, dims)`` and ``min(x, dims)`` to avoid ambiguities that would otherwise occur.


Derived reduction functions
-----------------------------

In addition to these basic reduction functions, we also define a set of derived reduction functions, as follows:

.. code-block:: julia

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

Although this is quite a large set of functions, the actual code is quite concise, as most of such functions are generated through macros (see ``src/reduce.jl``)

In addition to the common reduction functions, this package also provides a set of statistics functions that are particularly useful in probabilistic or information theoretical computation, as follows

.. code-block:: julia

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

For ``logsumexp`` and ``softmax``, special care is taken to ensure numerical stability for large x values, that is, their values will be properly shifted during computation.


Weighted Sum
--------------

Computation of weighted sum as below is common in practice.

.. math::

    \sum_{i=1}^n w_i x_i

    \sum_{i=1}^n w_i f(x_i, \ldots)

    \sum_{i=1}^n w_i f(x_i - y_i)


*NumericExtensions.jl* directly supports such computation via ``wsum`` and ``wsum_fdiff``:

.. code-block:: julia

    wsum(w, x)                 # weighted sum of x with weights w
    wsum(w, f1, x1)            # weighted sum of f1(x1) with weights w
    wsum(w, f2, x1, x2)        # weighted sum of f2(x1, x2) with weights w
    wsum(w, f3, x1, x2, x3)    # weighted sum of f3(x1, x2, x3) with weights w
    wsum_fdiff(w, f2, x, y)    # weighted sum of f2(x - y) with weights w

These functions also support computing the weighted sums along a specific dimension:

.. code-block:: julia
    
    wsum(w, x, dim)
    wsum!(dst, w, x, dim)

    wsum(w, f1, x1, dim)
    wsum!(dst, w, f1, x1, dim)

    wsum(w, f2, x1, x2, dim)
    wsum!(dst, w, f2, x1, x2, dim)

    wsum(w, f3, x1, x2, x3, dim)
    wsum!(dst, w, f3, x1, x2, x3, dim)

    wsum_fdiff(w, f2, x, y, dim)
    wsum_fdiff!(dst, w, f2, x, y, dim)

Furthermore, ``wasum``, ``wadiffsum``, ``wsqsum``, ``wsqdiffsum`` are provided to compute weighted sum of absolute values / squares to simplify common use:

.. code-block:: julia

    wasum(x)              # weighted sum of abs(x)
    wasum(x, dim)
    wasum!(dst, x, dim)

    wadiffsum(x, y)       # weighted sum of abs(x - y)
    wadiffsum(x, y, dim)
    wadiffsum!(dst, x, y, dim)

    wsqsum(x)             # weighted sum of abs2(x)
    wsqsum(x, dim)
    wsqsum!(dst, x, dim) 

    wsqdiffsum(x, y)      # weighted sum of abs2(x - y)
    wsqdiffsum(x, y, dim)
    wsqdiffsum!(dst, x, y, dim)


Performance
-------------

The reduction and map-reduction functions are carefully optimized. In particular, several tricks lead to performance improvement:

* computation is performed in a cache-friendly manner;
* computation completes in a single pass without creating intermediate arrays;
* kernels are inlined via the use of typed functors;
* inner loops use linear indexing (with pre-computed offset);
* opportunities of using BLAS are exploited.

Generally, many of the reduction functions in this package can achieve *3x - 10x* speed up as compared to the typical Julia expression.

We observe further speed up for certain functions:
* full reduction with ``asum``, ``sqsum``, and ``dot`` utilize BLAS level 1 routines, and they achieve *10x* to *30x* speed up.
* For ``var`` and ``std``, we devise dedicated procedures, where computational steps are very carefully scheduled such that most computation is conducted in a single pass. This results in about *25x* speedup.

