Vector Norms and Normalization
================================

This package provides functions for evaluating vector norms and normalizing vectors.

Vector Norm Evaluation
-----------------------

**Synopsis**

.. code-block:: julia

	vnorm(x, p)             # compute L-p norm of vec(x)
	vnorm(x, p, dim)        # compute L-p norm of x along dimension dim
	vnorm!(r, x, p, dim)    # compute L-p norm along specific dimension and 
	                        # write results to r

    vdiffnorm(x, y, p)             # compute L-p norm of vec(x - y)
    vdiffnorm(x, y, p, dim)        # compute L-p norm of x - y along dim
    vdiffnorm!(r, x, y, p, dim)    # compute L-p norm of x - y along dim and write to r

Notes: 

- For ``vdiffnorm`` and ``vdiffnorm!``, ``x`` or ``y`` can be either an array or a scalar.
- When ``p`` is 1, 2, or Inf, specialized fast routines are used.

**Examples**

.. code-block:: julia

	vnorm(x, 2)          # compute L-2 norm of x
	vnorm(x, 2, 1)       # compute L-2 norm of each column of x
	vnorm(x, Inf, 2)     # compute L-inf norm of each row of x
	vnorm!(r, x, 2, 1)   # compute L-2 norm of each column, and write results to r

	vdiffnorm(x, 2.5, 2)    # compute L-2 norm of x - 2.5
	vdiffnorm(x, y, 1, 2)   # compute L-1 norm of x - y for each column


Normalization
--------------

Normalizing a vector w.r.t L-p norm means to scale a vector such that the L-p norm of the vector becomes 1.

**Synopsis**

.. code-block:: julia

	normalize(x, p)         # returns a normalized vector w.r.t. L-p norm
	normalize!(x, p)        # normalize x w.r.t. L-p norm inplace
	normalize!(r, x, p)     # write the normalized vector to a pre-allocated array r

	normalize(x, p, dim)       # returns an array comprised of normalized vectors along dim
	normalize!(x, p, dim) 	   # normalize vectors of x along dim inplace w.r.t. L-p norm
	normalize!(r, x, p, dim)   # write the normalized vectors along dim to r
