# Unit tests for utils.jl

using NumericExtensions
using Base.Test

@test eachrepeat(1:3, 2) == [1, 1, 2, 2, 3, 3]
@test eachrepeat(1:4, 1:4) == [1, 2, 2, 3, 3, 3, 4, 4, 4, 4]


rmat = [1 1 2 2 3 3; 
        1 1 2 2 3 3;
        1 1 2 2 3 3;
        4 4 5 5 6 6;
        4 4 5 5 6 6;
        4 4 5 5 6 6]

@test eachrepeat([1 2 3; 4 5 6], (3, 2)) == rmat

x = [1, 1, 1, 2, 2, 3, 3, 3, 3, 1, 1, 2, 1]
sx, cx = sortindexes(x)
@test sx == sortperm(x) == [1, 2, 3, 10, 11, 13, 4, 5, 12, 6, 7, 8, 9]
@test cx == [6, 3, 4]

g = groupindexes(x)
@test size(g) == (3,)
@test g[1] == [1, 2, 3, 10, 11, 13]
@test g[2] == [4, 5, 12]
@test g[3] == [6, 7, 8, 9]

