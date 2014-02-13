# common facilities

typealias DenseVector{T} DenseArray{T,1}
typealias DenseMatrix{T} DenseArray{T,2}
typealias DenseVecOrMat{T} Union(DenseVector{T},DenseMatrix{T})

typealias NumericArray{T<:Number,N} DenseArray{T,N}
typealias ArrOrNum{T<:Number} Union(DenseArray{T}, T) 

typealias NumericVector{T<:Number} DenseVector{T}
typealias NumericMatrix{T<:Number} DenseMatrix{T}

typealias ContiguousArrOrNum{T<:Number} Union(ContiguousArray{T}, T)
typealias ContiguousNumericArray{T<:Number} ContiguousArray{T}
typealias ContiguousRealArray{T<:Real} ContiguousArray{T}

typealias DimSpec Int

getvalue(a::Number, i::Integer) = a
getvalue(a::DenseArray, i::Integer) = a[i]

