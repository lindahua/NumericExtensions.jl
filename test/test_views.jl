
using NumericFunctors
using Base.Test

# within a matrix

a = rand(5, 6)

@test NumericFunctors.total_ncolumns(a) == 6
@test NumericFunctors.total_npages(a) == 1

@test view(a, :) == a[:]

for j in 1 : 6
	@test view(a, :, j) == a[:, j]
	@test view(a, 2:4, j) == a[2:4, j]
end

@test view(a, :, :) == a
@test view(a, :, 2:5) == a[:, 2:5]

# within a cube

a = rand(5, 6, 3)

@test NumericFunctors.total_ncolumns(a) == 18
@test NumericFunctors.total_npages(a) == 3

@test view(a, :) == a[:]

for j in 1 : 18
	@test view(a, :, j) == a[:, j]
	@test view(a, 2:4, j) == a[2:4, j]
end

for k in 1 : 3
	for j in 1 : 6
		@test view(a, :, j, k) == a[:, j, k]
		@test view(a, 2:4, j, k) == a[2:4, j, k]
	end

	@test view(a, :, :, k) == a[:, :, k]
	@test view(a, :, 2:5, k) == a[:, 2:5, k]
end

@test view(a, :, :) == a[:, :]

