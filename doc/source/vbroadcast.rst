Vector Broadcasting
=====================

Julia has very nice and performant functions for broadcasting: ``broadcast`` and ``broadcast!``, which however does not work with functors. For customized computation, you have to pass in function argument, which would lead to severe performance degradation. *NumericExtensions.jl* provides ``vbroadcast`` and ``vbroadcast!`` to address this issue.

**Synopsis**

.. code-block:: julia

    vbroadcast(f, x, y, dim)  # apply a vector y to vectors of x along a specific dimension
    vbroadcast!(f, dst, x, y, dim)  # write results to dst
    vbroadcast1!(f, x, y)            # update x with the results

Here, ``f`` is a binary functor, and ``x`` and ``y`` are arrays such that ``length(y) == size(x, dim)``. 

**Examples**

.. code-block:: julia

    vbroadcast(f, x, y, 1)    # r[:,i] = f(x[:,i], y) for each i
    vbroadcast(f, x, y, 2)    # r[i,:] = f(x[i,:], y) for each i
    vbroadcast(f, x, y, 3)    # r[i,j,:] = f(x[i,j,:], y) for each i, j

    vbroadcast1!(Add(), x, y, 1)   # x[:,i] += y[:,i] for each i
    vbroadcast1!(Mul(), x, y, 2)   # x[i,:] .*= y[i,:] for each i

**Difference from** ``broadcast``

Unlike ``broadcast``, you have to specify the vector dimension for ``vbroadcast``. The benefit is two-fold: (1) the overhead of figuring out broadcasting shape information is elimintated; (2) the shape of ``y`` can be flexible. 

.. code-block:: julia

    x = rand(5, 6)
    y = rand(6)

    vbroadcast(Add(), x, y, 2)    # this adds y to each row of x
    broadcast(+, x, reshape(y, 1, 6))  # with broadcast, you have to first reshape y into a row

