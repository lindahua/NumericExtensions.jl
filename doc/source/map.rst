Mapping
=========

*NumericExtensions.jl* extends ``map`` and ``map!`` to accept functors for efficient element-wise mapping:

General usage
--------------

**Synopsis:**

Let ``f1``, ``f2``, and ``f3`` be respectively unary, binary, and ternary functors. Generic usage of ``map`` and ``map!`` is summarized as follows:

.. code-block:: julia

    map(f1, x)
    map(f2, x1, x2)
    map(f3, x1, x2, x3)

    map!(f1, dst, x)
    map!(f2, dst, x1, x2)
    map!(f3, dst, x1, x2, x3)

Here, ``map`` creates and returns the resultant array, while ``map!`` writes results to a pre-allocated ``dst`` and returns it. Each argument can be either an array or a scalar number. At least one argument should be an array, and all array arguments should have compatible sizes. 

**Examples:**

.. code-block:: julia
    
    map(AbsFun(), x)            # returns abs(x)
    map(FMA(), x, y, z)      # returns x + y .* z
    map!(Add(), dst, x, 2)   # writes x + 2 to dst

Additional functions
----------------------

*NumericExtensions.jl* provides additional functions (``map1!``, ``mapdiff``, and ``mapdiff!``) to simplify common use:

**Synopsis**

``map1!`` updates the first argument inplace with the results, ``mapdiff`` maps a functor to the difference between two arguments, and ``mapdiff!`` writes the results of ``mapdiff`` to a pre-allocated array. 

.. code-block:: julia

    map1!(f1, x1)             # x1 <-- f1(x1)
    map1!(f2, x1, x2)         # x1 <-- f2(x1, x2)
    map1!(f3, x1, x2, x3)     # x1 <-- f3(x1, x2, x3)

    mapdiff(f1, x, y)         # returns f1(x - y)
    mapdiff!(f1, dst, x, y)   # dst <-- f1(x - y)

Here, ``x1`` (*i.e.* the first argument to ``map1!`` must be an array, while ``x2`` and ``x3`` can be either an array or a number).

Note that ``mapdiff`` and ``mapdiff!`` uses an efficient implementation, which completes the computation in one-pass and never creates the intermediate array ``x - y``. 

**Examples**

.. code-block:: julia

    map1!(Mul(), x, 2)       # multiply x by 2 (inplace)
    mapdiff(Abs2Fun(), x, y)    # compute squared differences between x and y
    mapdiff(AbsFun(), x, 1)     # compute |x - 1|


Pre-defined mapping functions
------------------------------

Julia already provides vectorized function for most math computations. In this package, we additionally define several functions for vectorized inplace computation (based on ``map!``), as follows

.. code-block:: julia

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

In the codes above, ``x`` must be an array (*i.e.* an instance of ``AbstractArray``), while ``y`` can be either an array or a scalar.

In addition, this package also define some useful functions using compound functos:

.. code-block:: julia

    absdiff(x, y)     # abs(x - y)
    sqrdiff(x, y)     # abs2(x - y)
    fma(x, y, c)      # x + y .* c, where c can be array or scalar
    fma!(x, y, c)     # x <- x + y .* c


Performance
------------

For simple functions, such as ``x + y`` or ``exp(x)``, the performance of the map version such as ``map(Add(), x, y)`` and ``map(ExpFun(), x)`` is comparable to the Julia counter part. However, ``map`` can accelerate computation considerably in a variety of cases:

* When the result storage has been allocated (e.g. in iterative updating algorithms) or you want inplace update, then ``map!`` or the pre-defined inplace computation function can be used to avoid unnecessary memory allocation/garbage collection, which can sometimes be the performance killer.

* When the inner copy contains two or multiple steps, ``map`` and ``map!`` can complete the computation in one-pass without creating intermediate arrays, usually resulting in about ``2x`` or even more speed up. Benchmark shows that ``absdiff(x, y)`` and ``sqrdiff(x, y)`` are about *2.2x* faster than ``abs(x - y)`` and ``abs2(x - y)``. 

* The script ``test/benchmark_map.jl`` runs a series of benchmarks to compare the performance ``map`` and the Julia vectorized expressions for a variety of computation.



