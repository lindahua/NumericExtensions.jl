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

parent(a::Number) = a

getvalue(a::Number, i::Integer) = a
getvalue(a::DenseArray, i::Integer) = a[i]

gt_or_nan(s::Number, x) = (s > x)
lt_or_nan(s::Number, x) = (s < x)

gt_or_nan(s::FloatingPoint, x) = (s > x || s != s)
lt_or_nan(s::FloatingPoint, x) = (s < x || s != s)

