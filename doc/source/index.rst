.. NumericExtensions.jl documentation master file


Documentation of NumericExtensions.jl
================================================

*NumericExtensions.jl* is a Julia package that provides high performance support of numerical computation. This package is an extension of the Julia Base -- part of the material may be migrated into the Base in future.

*NumericExtensions.jl* provides a wide range of tools, which include:

- higher order functions for mapping, reduction, and map-reduce operation that takes typed functors to achieve performance comparable to hand-crafted loops.
- Functions that allow inplace updating and writing results to pre-allocated arrays for mapping, reduction, and map-reduce operations.
- Convenient functions for inplace vectorized computation.
- Vector broadcasting.
- Fast views for operating on contiguous blocks/slices.


**Contents:**

.. toctree::
    :maxdepth: 2

    overview.rst
    functors.rst
    map.rst
    vbroadcast.rst
    reduction.rst
    views.rst


.. Indices and tables
.. ==================

.. * :ref:`genindex`
.. * :ref:`search`

