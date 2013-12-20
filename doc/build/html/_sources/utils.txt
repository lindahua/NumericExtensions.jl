Utilities for Data Manipulation
=================================

This package provides some useful functions for data manipulation:

.. py:function:: eachrepeat(x, rt)

	Repeats each element in x for rt times. Three cases are supported:

	- ``x`` is a vector, and ``rt`` is an integer
	- ``x`` is a vector, and ``rt`` is a vector of the same size
	- ``x`` is a matrix, and ``rt`` is a pair as (p, q)

	**Examples:**

	.. code-block:: julia

		eachrepeat(1:3, 2)   # ==> [1,1,2,2,3,3]
		eachrepeat([1,4,5],[2,3,1])  #==> [1,1,4,4,4,5]

		eachrepeat([1 2 3; 4 5 6], (3, 2))
		#==> [1 1 2 2 3 3; 
		#     1 1 2 2 3 3;
		#     1 1 2 2 3 3;
		#     4 4 5 5 6 6;
		#     4 4 5 5 6 6;
		#     4 4 5 5 6 6]

.. py:function:: sortindexes(x[, k])

	This is similar to ``sortperm``. But it only applies to a sequence of elements, whose values are in ``1:k``. 
	This function implements an algorithm of complexity ``O(n)``, which is faster than ``sortperm``. 

	This function returns a pair of two outputs: 

	- ``sinds``:  the sorted indexes, i.e. ``sortperm(x)``. 
	- ``cnts``:   the counts of occurrences of each value in ``1:k``, i.e. ``cnts[i] == sum(x .== i)``. 

	**Examples:**

	.. code-block:: julia

		x = [1, 1, 1, 2, 2, 3, 3, 3, 3, 1, 1, 2, 1]
		s, c = sortindexes(x, k)
		# s == sortperm(x) == [1, 2, 3, 10, 11, 13, 4, 5, 12, 6, 7, 8, 9]
		# c == [6, 3, 4]

	**Node:** The second argument ``k`` may be omitted, in such cases, it is equivalent to ``sortindexes(x, max(x))``.


.. py:function:: sortindexes!(x, sinds, cnts)

	Perform same functionality as ``sortindexes``, but write the results to pre-allocated arrays.


.. py:function:: groupindexes(x[, k])

	Group indexes according to the integers in x, which can take values in ``1:k``. This function returns a vector of index vectors (say ``r``), such that ``r[i] == find(x .== i)``. 

	This function relies on ``sortindexes`` internally, and its complexity is ``O(n)``.

	**Examples:**

	.. code-block:: julia

		julia> x = [1, 1, 1, 2, 2, 3, 3, 3, 3, 1, 1, 2, 1];
		julia> groupindexes(x)
		3-element Array{Array{Int64,1},1}:
		[1,2,3,10,11,13]
		[4,5,12]
		[6,7,8,9]

	**Node:** The second argument ``k`` may be omitted, in such cases, it is equivalent to ``groupindexes(x, max(x))``.

