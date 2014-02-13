# Linear & Affine Transforms

### Transpose

immutable Transpose{T,A<:StridedMatrix{T}}
    mat::A
end

Transpose{T}(a::StridedMatrix{T}) = Transpose{T,typeof(a)}(a)

Base.size(a::Transpose) = ((m,n)=size(a.mat); (n,m))::(Int,Int)
Base.size(a::Transpose, i::Integer) = (i == 1 ? size(a.mat,2) :
                                       i == 2 ? size(a.mat,1) : 1)

Base.length(a::Transpose) = length(a.mat)
Base.ndims(a::Transpose) = 2

### Linear transformation

typealias LinearTransform{T<:Real} Union(T,
                                         StridedVector{T},
                                         StridedMatrix{T},
                                         Transpose{T})

typealias SimpleLinearTransform{T<:Real} Union(T, StridedVector{T})

_outdim(a::StridedVector) = length(a)
_outdim(a::StridedMatrix) = size(a,1)
_outdim(a::Transpose) = size(a.mat,2)

function transform!(y::StridedVector, a::Real, x::StridedVector)
    (length(y) == length(x)) || throw(DimensionMismatch("Mismatched dimensions."))
    for i = 1:length(x)
        @inbounds y[i] = a * x[i]
    end
    return y
end

transform!(a::Real, x::StridedVector) = scale!(x, a)

function transform!(y::StridedMatrix, a::Real, x::StridedMatrix)
    m, n = size(x)
    (size(y) == (m, n)) || throw(DimensionMismatch("Mismatched dimensions."))
    for j = 1:n
        xj = view(x,:,j)
        yj = view(y,:,j)
        for i = 1:m
            @inbounds yj[i] = a * xj[i]
        end
    end
    return y
end

transform!(a::Real, x::StridedMatrix) = scale!(x, a)

function transform!{T<:Real}(y::StridedVector, a::StridedVector{T}, x::StridedVector)
    (length(y) == length(a) == length(x)) || throw(DimensionMismatch("Mismatched dimensions."))
    for i = 1:length(x)
        @inbounds y[i] = a[i] * x[i]
    end
    return y
end

transform!{T<:Real}(a::StridedVector{T}, x::StridedVector) = multiply!(x, a)

function transform!{T<:Real}(y::StridedMatrix, a::StridedVector{T}, x::StridedMatrix)
    m, n = size(x)
    (size(y) == (m, n) && length(a) == m) || throw(DimensionMismatch("Mismatched dimensions."))
    for j = 1:n
        xj = view(x,:,j)
        yj = view(y,:,j)
        for i = 1:m
            @inbounds yj[i] = a[i] * xj[i]
        end
    end
    return y
end

transform!{T<:Real}(a::StridedVector{T}, x::StridedMatrix) = scale!(a, x)

transform!{T<:Real}(y::StridedVector, a::StridedMatrix{T}, x::StridedVector) = A_mul_B!(y, a, x)
transform!{T<:Real}(y::StridedMatrix, a::StridedMatrix{T}, x::StridedMatrix) = A_mul_B!(y, a, x)

transform!{T<:Real}(y::StridedVector, a::Transpose{T}, x::StridedVector) = At_mul_B!(y, a.mat, x)
transform!{T<:Real}(y::StridedMatrix, a::Transpose{T}, x::StridedMatrix) = At_mul_B!(y, a.mat, x)

transform(a::Real, x::StridedVector) = a * x
transform(a::Real, x::StridedMatrix) = a * x

transform{T<:Real}(a::LinearTransform{T}, x::StridedVector) = 
    transform!(Array(T, _outdim(a)), a, x)

transform{T<:Real}(a::LinearTransform{T}, x::StridedMatrix) = 
    transform!(Array(T, _outdim(a), size(x,2)), a, x)


### Affine Transformation: y <- a * x + b

immutable AffineTransform{T,A<:LinearTransform}
    a::A
    b::Vector{T}
end

AffineTransform{T<:Real}(a::T) = AffineTransform{T,T}(a,T[])
AffineTransform{T<:Real}(a::T, b::Vector{T}) = AffineTransform{T,T}(a, b)

AffineTransform{T<:Real}(a::LinearTransform{T}) = AffineTransform{T, typeof(a)}(a, T[])

function AffineTransform{T<:Real}(a::LinearTransform{T}, b::Vector{T})
    if !(isempty(b) || length(b) == _outdim(a))
        throw(DimensionMismatch("Mismatched dimensions."))
    end
    return AffineTransform{T, typeof(a)}(a, b)
end

hasshift(t::AffineTransform) = !isempty(t.b)

function transform!(y::StridedVector, t::AffineTransform, x::StridedVector)
    transform!(y, t.a, x)
    if hasshift(t)
        add!(y, t.b)
    end
    return y
end

function transform!(y::StridedMatrix, t::AffineTransform, x::StridedMatrix)
    transform!(y, t.a, x)
    if hasshift(t)
        badd!(y, t.b, 1)
    end
    return y
end

function transform!{T<:Real,A<:SimpleLinearTransform}(t::AffineTransform{T,A}, x::StridedVector)
    transform!(t.a, x)
    if hasshift(t)
        add!(x, t.b)
    end
    return x
end

function transform!{T<:Real,A<:SimpleLinearTransform}(t::AffineTransform{T,A}, x::StridedMatrix)
    transform!(t.a, x)
    if hasshift(t)
        badd!(x, t.b, 1)   
    end
    return x
end

transform{T<:Real}(t::AffineTransform{T,T}, x::StridedVecOrMat) = 
    transform!(Array(T, size(x)), t, x)

transform{T<:Real}(t::AffineTransform{T}, x::StridedVector) =
    transform!(Array(T, _outdim(t.a)), t, x)

transform{T<:Real}(t::AffineTransform{T}, x::StridedMatrix) =
    transform!(Array(T, _outdim(t.a), size(x,2)), t, x)

