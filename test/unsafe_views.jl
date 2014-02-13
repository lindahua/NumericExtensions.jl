
using NumericExtensions
using Base.Test

# Test view construction and element accessing

# 1D

a = rand(5)
b = rand(5)
v = unsafe_view(a)

@test ndims(v) == 1
@test length(v) == 5
@test size(v) == (5,)
@test size(v, 1) == 5
@test size(v, 2) == 1
@test pointer(v) == pointer(a)
@test pointer(v, 2) == pointer(a, 2)
@test copy(v) == a

for i in 1 : 5
    @test v[i] == a[i]
    v[i] = b[i]
    @test v[i] == b[i]
end

# 2D

a = rand(4, 5)
b = rand(4, 5)

ac = copy(a)
v = unsafe_view(ac)

@test ndims(v) == 2
@test length(v) == 20
@test size(v) == (4, 5)
@test size(v, 1) == 4
@test size(v, 2) == 5
@test size(v, 3) == 1
@test pointer(v) == pointer(ac)
@test pointer(v, 2) == pointer(ac, 2)
@test copy(v) == a

for i in 1 : 20
    @test v[i] == a[i]
    v[i] = b[i]
    @test v[i] == b[i]
end

ac = copy(a)
v = UnsafeMatrixView{Float64}(pointer(ac), 4, 5)

for j in 1 : 5
    for i in 1 : 4
        @test v[i,j] == a[i,j]
        v[i,j] = b[i,j]
        @test v[i,j] == b[i,j]
    end
end

# 3D

a = rand(4, 5, 3)
b = rand(4, 5, 3)

ac = copy(a)
v = unsafe_view(ac)

@test ndims(v) == 3
@test length(v) == 60
@test size(v) == (4, 5, 3)
@test size(v, 1) == 4
@test size(v, 2) == 5
@test size(v, 3) == 3
@test size(v, 4) == 1
@test pointer(v) == pointer(ac)
@test pointer(v, 2) == pointer(ac, 2)
@test copy(v) == a

for i in 1 : 60
    @test v[i] == a[i]
    v[i] = b[i]
    @test v[i] == b[i]
end

ac = copy(a)
v = unsafe_view(ac)

for j in 1 : 15
    for i in 1 : 4
        @test v[i,j] == a[i,j]
        v[i,j] = b[i,j]
        @test v[i,j] == b[i,j]
    end
end

ac = copy(a)
v = unsafe_view(ac)

for k in 1 : 3
    for j in 1 : 5
        for i in 1 : 4
            @test v[i,j,k] == a[i,j,k]
            v[i,j,k] = b[i,j,k]
            @test v[i,j,k] == b[i,j,k]
        end
    end
end

# Test Subview construction 

# 1D

a1 = rand(5)
@test copy(unsafe_view(a1, :)) == a1[:]
@test copy(unsafe_view(a1, :, 1)) == a1[:, 1]
@test copy(unsafe_view(a1, :, 1, 1)) == a1[:, 1, 1]
@test copy(unsafe_view(a1, :, :)) == a1[:, :]
@test copy(unsafe_view(a1, :, :, 1)) == a1[:, :, 1]
@test copy(unsafe_view(a1, :, :, :)) == a1[:, :, :]
@test copy(unsafe_view(a1, :, :, 1:1)) == a1[:, :, 1:1]
@test copy(unsafe_view(a1, :, 1:1)) == a1[:, 1:1]
@test copy(unsafe_view(a1, :, 1:1, 1)) == a1[:, 1:1, 1]

@test copy(unsafe_view(a1, 2:4)) == a1[2:4]
@test copy(unsafe_view(a1, 2:4, 1)) == a1[2:4, 1]
@test copy(unsafe_view(a1, 2:4, 1, 1)) == a1[2:4, 1, 1]

# 2D

a2 = rand(5, 6)
@test copy(unsafe_view(a2, :)) == a2[:]
@test copy(unsafe_view(a2, :, 3)) == a2[:, 3]
@test copy(unsafe_view(a2, :, 3, 1)) == a2[:, 3, 1]
@test copy(unsafe_view(a2, :, :)) == a2[:, :]
@test copy(unsafe_view(a2, :, :, 1)) == a2[:, :, 1]
@test copy(unsafe_view(a2, :, :, :)) == a2[:, :, :]
@test copy(unsafe_view(a2, :, :, 1:1)) == a2[:, :, 1:1]
@test copy(unsafe_view(a2, :, 2:5)) == a2[:, 2:5]
@test copy(unsafe_view(a2, :, 2:5, 1)) == a2[:, 2:5, 1]

@test copy(unsafe_view(a2, 2:4)) == a2[2:4]
@test copy(unsafe_view(a2, 2:4, 3)) == a2[2:4, 3]
@test copy(unsafe_view(a2, 2:4, 3, 1)) == a2[2:4, 3, 1]

# 3D

a3 = rand(5, 6, 3)
@test copy(unsafe_view(a3, :)) == a3[:]
@test copy(unsafe_view(a3, :, 3)) == a3[:, 3]
@test copy(unsafe_view(a3, :, 3, 2)) == a3[:, 3, 2]
@test copy(unsafe_view(a3, :, :)) == a3[:, :]
@test copy(unsafe_view(a3, :, :, 2)) == a3[:, :, 2]
@test copy(unsafe_view(a3, :, :, :)) == a3[:, :, :]
@test copy(unsafe_view(a3, :, :, 1:2)) == a3[:, :, 1:2]
@test copy(unsafe_view(a3, :, 2:5)) == a3[:, 2:5]
@test copy(unsafe_view(a3, :, 2:5, 2)) == a3[:, 2:5, 2]

@test copy(unsafe_view(a3, 2:4)) == a3[2:4]
@test copy(unsafe_view(a3, 2:4, 3)) == a3[2:4, 3]
@test copy(unsafe_view(a3, 2:4, 3, 1)) == a3[2:4, 3, 1]

# 4D

a4 = rand(5, 6, 3, 2)
@test copy(unsafe_view(a4, :)) == a4[:]
@test copy(unsafe_view(a4, :, 3)) == a4[:, 3]
@test copy(unsafe_view(a4, :, 3, 2)) == a4[:, 3, 2]
@test copy(unsafe_view(a4, :, :)) == a4[:, :]
@test copy(unsafe_view(a4, :, :, 2)) == a4[:, :, 2]
@test copy(unsafe_view(a4, :, :, :)) == a4[:, :, :]
@test copy(unsafe_view(a4, :, :, 1:2)) == a4[:, :, 1:2]
@test copy(unsafe_view(a4, :, 2:5)) == a4[:, 2:5]
@test copy(unsafe_view(a4, :, 2:5, 2)) == a4[:, 2:5, 2]

@test copy(unsafe_view(a4, 2:4)) == a4[2:4]
@test copy(unsafe_view(a4, 2:4, 3)) == a4[2:4, 3]
@test copy(unsafe_view(a4, 2:4, 3, 1)) == a4[2:4, 3, 1]



