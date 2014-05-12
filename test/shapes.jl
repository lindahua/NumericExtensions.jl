# Test shapes

using NumericExtensions
using Base.Test

@test mapshape(()) == ()
@test mapshape((3,)) == (3,)
@test mapshape((3,4)) == (3,4)

@test mapshape((3,), ()) == (3,)
@test mapshape((), (3,)) == (3,)
@test mapshape((3,), (3,)) == (3,)
@test_throws ErrorException mapshape((3,), (4,))

@test mapshape((3,1), (3,)) == (3,1)
@test mapshape((3,), (3,1)) == (3,1)
@test_throws ErrorException mapshape((3,1), (2,)) 
@test_throws ErrorException mapshape((3,1), (3,2))

@test mapshape((3,4,5), (3,4,5)) == (3,4,5)
@test mapshape((3,4,1), (3,4)) == (3,4,1)
@test mapshape((3,4), (3,4,1,1)) == (3,4,1,1)
@test_throws ErrorException mapshape((3,4), (3,4,2))
@test_throws ErrorException mapshape((3,5), (3,4,1))

@test mapshape((3,4), (3,4), (3,4)) == (3,4)
@test mapshape((3,4,1), (3,4), (3,4)) == (3,4,1)
@test mapshape((3,4), (3,4,1), (3,4)) == (3,4,1)
@test mapshape((3,4), (3,4), (3,4,1)) == (3,4,1)
@test mapshape((3,4,1), (3,4), (3,4,1)) == (3,4,1)
@test_throws ErrorException mapshape((3,4), (3,4), (3,5))

@test mapshape((3,4), (3,4), (3,4), (3,4)) == (3,4)
@test mapshape((3,), (3,1), (3,1,1), (3,1,1,1)) == (3,1,1,1)


