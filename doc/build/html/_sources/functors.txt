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

    type SqrDiff <: Functor{2} end
    NumericExtensions.evaluate(::SqrDiff, x, y) = abs2(x - y)


The package also provides macros ``@functor1`` and ``@functor2``, respectively for defining unary and binary functors. For example,

.. code-block:: julia

    # this defines a functor type MyAbs, which, 
    # when evaluated, invokes abs
    @functor1 MyAbsFun abs  

    # this defines a functor type SqrDiff
    sqrdiff(x, y) = abs2(x - y)
    @functor2 SqrDiff sqrdiff



Pre-defined functors
-----------------------

*NumericExtensions.jl* has defined a series of functors as listed below:

* Arithmetic operators: ``Add``, ``Subtract``, ``Multiply``, ``Divide``, ``Negate``, ``Pow``, ``Modulo``
* Comparison operators: ``Greater``, ``GreaterEqual``, ``Less``, ``LessEqual``, ``Equal``, ``NotEqual``
* Floating-point predicates: ``IsfiniteFun``, ``IsinfFun``, ``IsnanFun``, ``IsequalFun``
* Logical operators: ``Not``, ``And``, ``Or``
* Bitwise operators: ``BitwiseNot``, ``BitwiseAnd``, ``BitwiseOr``, ``BitwiseXor``
* max and min: ``MaxFun``, ``MinFun``
* Rounding functors: ``FloorFun``, ``CeilFun``, ``RoundFun``, ``TruncFun``, ``IfloorFun``, ``IceilFun``, ``IroundFun``, ``ItruncFun``
* Algebraic functors: ``AbsFun``, ``Abs2Fun``, ``SqrFun``, ``SqrtFun``, ``CbrtFun``, ``RcpFun``, ``RsqrtFun``, ``RcbrtFun``, ``HypotFun``
* exp and log functors: ``ExpFun``, ``Exp2Fun``, ``Exp10Fun``, ``LogFun``, ``Log2Fun``, ``Log10Fun``, ``Expm1Fun``, ``Log1pFun``
* Trigonometric functors: ``SinFun``, ``CosFun``, ``TanFun``, ``CotFun``, ``CscFun``, ``SecFun``
* Inverse Trigono functors: ``AsinFun``, ``AcosFun``, ``AtanFun``, ``Atan2Fun``, ``AcotFun``, ``AcscFun``, ``AsecFun``
* Hyperbolic functors: ``SinhFun``, ``CoshFun``, ``TanhFun``, ``CothFun``, ``CschFun``, ``SechFun``
* Inverse Hyperbolic functors: ``AsinhFun``, ``AcoshFun``, ``AtanhFun``, ``AcothFun``, ``AcschFun``, ``AsechFun``
* Error functors: ``ErfFun``, ``ErfcFun``, ``ErfInvFun``, ``ErfcInvFun``
* Gamma functors: ``GammaFun``, ``LgammaFun``, ``LfactFun``, ``DigammaFun``
* Beta functors: ``BetaFun``, ``LbetaFun``, ``EtaFun``, ``ZetaFun``
* Airy functors: ``AiryFun``, ``AiryprimeFun``, ``AiryaiFun``, ``AiryaiprimeFun``, ``AirybiFun``, ``AirybiprimeFun``
* Bessel functors: ``BesseljFun``, ``Besselj0Fun``, ``Besselj1Fun``, ``BesseliFun``, ``BesselkFun``
* Fused multiply and add: ``FMA`` (i.e. ``(a, b, c) -> a + b * c``)
* Others: ``LogitFun``, ``LogisticFun``, ``InvLogisticFun``, ``XlogxFun``, ``XlogyFun``

Except for several functors that corresponding to operators, most functors are named using the capitalized version of the corresponding math function. Therefore, you don't have to look up this list to find the names. The collection of pre-defined functors will be extended in future. Please refer to ``src/functors.jl`` for the most updated list.


