Fast Shared-memory Views
==========================

Getting a slice/part of an array is common in numerical computation. Julia itself provides two ways to do this: reference (e.g. ``x[:, J]``) and the ``sub`` function (e.g. ``sub(x, :, J)``). Both have performance issues: the former makes a copy each time you call it, while the latter results in an ``SubArray`` instance. Despite that ``sub`` does not create a copy, accessing elements of a ``SubArray`` instance is usually very slow (with current implementation).

*NumericExtensions.jl* addresses this problem by providing a ``unsafe_view`` function, which returns a view of specific part of an array. Below is a list of valid usage:

.. code-block:: julia

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

Benchmark shows that using ``unsafe_view`` often increases the throughput of element accessing by *50%*.

**Notes**

* ``unsafe_view`` only applies to the case when the part being referenced is contiguous.
* ``unsafe_view`` only does not maintain reference to the source array (instead, it relies on pointers) and does not perform bounds checking. Please use it with caution. Preferrably, it should be used within a context where you can ensure that the source array is existent and the indices are correct.

