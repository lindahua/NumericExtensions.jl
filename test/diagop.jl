# Diagonal operations

using NumericExtensions
using Base.Test

function zero_diag(x::Matrix)
	xc = copy(x)
	for i in 1 : min(size(x,1), size(x,2))
		xc[i,i] = 0
	end
	xc
end


@test diagm(3, 2.) == [2. 0. 0.; 0. 2. 0.; 0. 0. 2.]
@test eltype(diagm(3, 2.)) == Float64

x = rand(3, 3)
xc = copy(x)

@test set_diag(x, 2) == zero_diag(x) + diagm(3, 2.)
@test set_diag(x, [1. 2. 3.]) == zero_diag(x) + diagm([1., 2., 3.])
@test set_diag(x, [1. 2. 3.], 2.) == zero_diag(x) + diagm([2., 4., 6.])

@test xc == x

@test add_diag(x, 2) == x + diagm(3, 2.)
@test add_diag(x, [1. 2. 3.]) == x + diagm([1., 2., 3.])
@test add_diag(x, [1. 2. 3.], 2.) == x + diagm([2., 4., 6.])

@test xc == x

