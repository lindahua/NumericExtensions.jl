# common facilities

typealias DenseVector{T} DenseArray{T,1}
typealias DenseMatrix{T} DenseArray{T,2}
typealias DenseVecOrMat{T} Union(DenseVector{T},DenseMatrix{T})

typealias NumericArray{T<:Number,N} DenseArray{T,N}
typealias DenseArrOrNum{T<:Number} Union(DenseArray{T}, T) 
typealias ArrayOrNum{T<:Number} Union(Array{T}, T)

typealias NumericVector{T<:Number} DenseVector{T}
typealias NumericMatrix{T<:Number} DenseMatrix{T}

typealias ContiguousArrOrNum{T<:Number} Union(ContiguousArray{T}, T)
typealias ContiguousNumericArray{T<:Number} ContiguousArray{T}
typealias ContiguousRealArray{T<:Real} ContiguousArray{T}

typealias DimSpec Union(Int,Dims,Vector{Int})
typealias BlasFP Union(Float32,Float64)

parent(a::Number) = a
stride(a::Number, d::Int) = 1
ellipview(a::Number, i::Int) = a

getvalue(a::Number, i::Integer) = a
getvalue(a::DenseArray, i::Integer) = a[i]

gt_or_nan(s::Number, x) = (s > x)
lt_or_nan(s::Number, x) = (s < x)

gt_or_nan(s::FloatingPoint, x) = (s > x || s != s)
lt_or_nan(s::FloatingPoint, x) = (s < x || s != s)

type _Max <: Functor{2} end
evaluate{T<:Real}(::_Max, x::T, y::T) = ifelse(y > x, y, x)

type NonnegMax <: Functor{2} end
evaluate{T<:Real}(::NonnegMax, x::T, y::T) = ifelse(y > x, y, x)

type _Min <: Functor{2} end
evaluate{T<:Real}(::_Min, x::T, y::T) = ifelse(y < x, y, x)

result_type{T<:Real}(::Union(_Max,_Min,NonnegMax), ::Type{T}, ::Type{T}) = T

