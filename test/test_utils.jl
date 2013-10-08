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

