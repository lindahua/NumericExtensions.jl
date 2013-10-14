Functors
=========

Passing functions as arguments are essential in writing generic algorithms. However, function arguments do not get inlined in Julia (at current version), usually resulting in suboptimal performance.

Motivating example
-------------------

Passing functions as arguments are essential in writing generic algorithms. However, function arguments do not get inlined in Julia (at current version), usually resulting in suboptimal performance. Consider the following example:

.. code-block:: julia

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

Run this script in you computer, you will find that statement (1) is over *20+ times* slower than statement (2). The reason is that the function argument ``plus`` is resolved and called at each iteration of the inner loop within the ``map`` function.

This package addresses this issue through *type functors* (*i.e.* function-like objects of specific types) and a set of highly optimized higher level functions for mapping and reduction. The codes above can be rewritten as

.. code-block:: julia

    using NumericExtensions

     # benchmark
    @time for i in 1 : 10 map(Add(), a, b) end     # -- statement(1)
    @time for i in 1 : 10 a + b end                # -- statement(2)


Here, using a typed functor ``Add`` statement (1) is *10%* faster than statement (2) in my benchmark.


Functor types
--------------

``Functor`` is the abstract base type for all functors, which are formally defined as below

.. code-block:: julia

    abstract Functor{N}  # N: the number of arguments

    typealias UnaryFunctor Functor{1}
    typealias BinaryFunctor Functor{2}
    typealias TernaryFunctor Functor{3}


Below is an example that shows how to define a functor that computes the squared difference:

.. code-block:: julia

    type SqrDiff <: BinaryFunctor end

    NumericExtensions.evaluate(::SqrDiff, x, y) = abs2(x - y)
    NumericExtensions.result_type(::SqrDiff, t1::Type, t2::Type) = promote_type(t1, t2)


To define multiple functors, it would be more concise to first import ``evaluate`` and ``result_type`` before extending them, as follows:

.. code-block:: julia

    import NumericExtensions.evaluate, NumericExtensions.result_type

    type SqrDiff <: BinaryFunctor end

    evaluate(::SqrDiff, x, y) = abs2(x - y)
    result_type(::SqrDiff, t1::Type, t2::Type) = promote_type(t1, t2)

**Note:** Higher order functions such as ``map`` and ``reduce`` rely on the ``result_type`` method to determine the element type of the result. This is necessary, as Julia does not provide a generic mechanism to acquire the return type of a method.


Pre-defined functors
-----------------------

*NumericExtensions.jl* has defined a series of functors as listed below:

* Arithmetic functors: ``Add``, ``Subtract``, ``Multiply``, ``Divide``, ``Negate``, ``AbsFun``
* MaxFun and MinFun functors: ``MaxFun``, ``MinFun``
* Rounding functors: ``Floor``, ``Ceil``, ``Round``, ``Trunc``
* Power functors: ``Pow``, ``Sqrt``, ``Cbrt``, ``Abs2Fun``, ``Hypot``
* Exp and log functors: ``Exp``, ``Exp2``, ``Exp10``, ``Log``, ``Log2``, ``Log10``, ``Expm1``, ``Log1p``
* Trigonometric functors: ``Sin``, ``Cos``, ``Tan``, ``Asin``, ``Acos``, ``Atan``, ``Atan2``
* Hyperbolic functors: ``Sinh``, ``Cosh``, ``Tanh``, ``Asinh``, ``Acosh``, ``Atanh``
* Error functors: ``Erf``, ``Erfc``
* Gamma functors: ``Gamma``, ``Lgamma``, ``Digamma``
* Comparison functors: ``Greater``, ``GreaterEqual``, ``Less``, ``LessEqual``, ``Equal``, ``NotEqual``
* Number class functors: ``Isfinite``, ``Isinf``, ``Isnan``
* Fused multiply and add: ``FMA`` (i.e. ``(a, b, c) -> a + b * c``)
* Others: ``Logit``, ``Logistic``, ``Xlogx``, ``Xlogy``

Except for several functors that corresponding to operators, most functors are named using the capitalized version of the corresponding math function. Therefore, you don't have to look up this list to find the names. The collection of pre-defined functors will be extended in future. Please refer to ``src/functors.jl`` for the most updated list.


