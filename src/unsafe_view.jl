# views that provide efficient construction and element access

abstract AbstractUnsafeView{T, N} <: AbstractArray{T, N}

typealias ContiguousArray{T, N} Union(Array{T, N}, AbstractUnsafeView{T, N})
typealias ContiguousVector{T} ContiguousArray{T, 1}
typealias ContiguousMatrix{T} ContiguousArray{T, 2}
typealias ContiguousCube{T} ContiguousArray{T, 3}

similar(a::AbstractUnsafeView, T::DataType, shape::NTuple) = Array(T, shape)
similar{T}(a::AbstractUnsafeView{T}) = Array(T, size(a))

function copy{T}(a::AbstractUnsafeView{T})
	r = similar(a)
	if isbits(T)
		unsafe_copy!(pointer(r), pointer(a), length(a))
	else
		for i = 1 : length(a)
	    	r[i] = a[i]
		end
	end
	r
end


immutable UnsafeVectorView{T} <: AbstractUnsafeView{T, 1}
	ptr::Ptr{T}
	len::Int
end

pointer(a::UnsafeVectorView) = a.ptr
pointer{T}(a::UnsafeVectorView{T}, i::Int) = a.ptr + (i - 1) * sizeof(T)
size(a::UnsafeVectorView) = (a.len,)
size(a::UnsafeVectorView, d::Int) = d == 1 ? a.len : 1
length(a::UnsafeVectorView) = a.len

getindex(a::UnsafeVectorView, i::Int) = unsafe_load(a.ptr, i)
setindex!(a::UnsafeVectorView, v, i::Int) = unsafe_store!(a.ptr, v, i)


immutable UnsafeMatrixView{T} <: AbstractUnsafeView{T, 2}
	ptr::Ptr{T}
	dim1::Int
	dim2::Int
	len::Int

	UnsafeMatrixView(ptr::Ptr{T}, d1::Int, d2::Int) = new(ptr, d1, d2, d1 * d2)
end

pointer(a::UnsafeMatrixView) = a.ptr
pointer{T}(a::UnsafeMatrixView{T}, i::Int) = a.ptr + (i - 1) * sizeof(T)
size(a::UnsafeMatrixView) = (a.dim1, a.dim2)
size(a::UnsafeMatrixView, d::Int) = d == 1 ? a.dim1 : d == 2 ? a.dim2 : 1
length(a::UnsafeMatrixView) = a.len

getindex(a::UnsafeMatrixView, i::Int) = unsafe_load(a.ptr, i)
getindex(a::UnsafeMatrixView, i::Int, j::Int) = unsafe_load(a.ptr, i + (j-1) * a.dim1)

setindex!(a::UnsafeMatrixView, v, i::Int) = unsafe_store!(a.ptr, v, i)
setindex!(a::UnsafeMatrixView, v, i::Int, j::Int) = unsafe_store!(a.ptr, v, i + (j-1) * a.dim1)


immutable UnsafeCubeView{T} <: AbstractUnsafeView{T, 3}
	ptr::Ptr{T}
	dim1::Int
	dim2::Int
	dim3::Int
	len::Int
	plen::Int

	UnsafeCubeView(ptr::Ptr{T}, d1::Int, d2::Int, d3::Int) = new(ptr, d1, d2, d3, d1 * d2 * d3, d1 * d2)
end

pointer(a::UnsafeCubeView) = a.ptr
pointer{T}(a::UnsafeCubeView{T}, i::Int) = a.ptr + (i - 1) * sizeof(T)
size(a::UnsafeCubeView) = (a.dim1, a.dim2, a.dim3)
size(a::UnsafeCubeView, d::Int) = d == 1 ? a.dim1 : d == 2 ? a.dim2 : d == 3 ? a.dim3 : 1
length(a::UnsafeCubeView) = a.len

getindex(a::UnsafeCubeView, i::Int) = unsafe_load(a.ptr, i)
getindex(a::UnsafeCubeView, i::Int, j::Int) = unsafe_load(a.ptr, i + (j-1) * a.dim1)
getindex(a::UnsafeCubeView, i::Int, j::Int, k::Int) = unsafe_load(a.ptr, i + (j-1) * a.dim1 + (k-1) * a.plen)

setindex!(a::UnsafeCubeView, v, i::Int) = unsafe_store!(a.ptr, v, i)
setindex!(a::UnsafeCubeView, v, i::Int, j::Int) = unsafe_store!(a.ptr, v, i + (j-1) * a.dim1)
setindex!(a::UnsafeCubeView, v, i::Int, j::Int, k::Int) = unsafe_store!(a.ptr, v, i + (j-1) * a.dim1 + (k-1) * a.plen)


# calculate offset of an element

offset(a::ContiguousArray, i::Int) = (i - 1)
offset(a::ContiguousArray, i::Int, j::Int) = (i - 1) + size(a, 1) * (j - 1)
offset(a::ContiguousArray, i::Int, j::Int, k::Int) = (i - 1) + size(a, 1) * ((j - 1) + size(a, 2) * (k - 1)) 

offset(a::UnsafeMatrixView, i::Int, j::Int) = (i - 1) + a.dim1 * (j - 1)
offset(a::UnsafeCubeView, i::Int, j::Int, k::Int) = (i - 1) + a.dim1 * ((j - 1) + a.dim2 * (k - 1))


# view constructors

offset_view{T}(a::ContiguousArray{T}, offset::Int, d1::Int) = UnsafeVectorView(pointer(a) + sizeof(T) * offset, d1)
offset_view{T}(a::ContiguousArray{T}, offset::Int, d1::Int, d2::Int) = UnsafeMatrixView{T}(pointer(a) + sizeof(T) * offset, d1, d2)

function offset_view{T}(a::ContiguousArray{T}, offset::Int, d1::Int, d2::Int, d3::Int)
	UnsafeCubeView{T}(pointer(a) + sizeof(T) * offset, d1, d2, d3)
end

unsafe_view(v) = v  # fallback

# 1D

unsafe_view(a::ContiguousVector) = UnsafeVectorView(pointer(a), length(a))

unsafe_view(a::ContiguousArray, r::Colon) = UnsafeVectorView(pointer(a), length(a))
unsafe_view(a::ContiguousArray, r::Colon, j::Int) = offset_view(a, offset(a, 1, j), size(a, 1))
unsafe_view(a::ContiguousArray, r::Colon, j::Int, k::Int) = offset_view(a, offset(a, 1, j, k), size(a, 1))

unsafe_view(a::ContiguousArray, r::Range1{Int}) = offset_view(a, r[1] - 1, length(r))
unsafe_view(a::ContiguousArray, r::Range1{Int}, j::Int) = offset_view(a, offset(a, r[1], j), length(r))
unsafe_view(a::ContiguousArray, r::Range1{Int}, j::Int, k::Int) = offset_view(a, offset(a, r[1], j, k), length(r))

# 2D

unsafe_view{T}(a::ContiguousMatrix{T}) = UnsafeMatrixView{T}(pointer(a), size(a, 1), size(a, 2))

unsafe_view{T}(a::ContiguousVector{T}, r1::Colon, r2::Colon) = UnsafeMatrixView{T}(pointer(a), length(a), 1)
unsafe_view{T}(a::ContiguousMatrix{T}, r1::Colon, r2::Colon) = UnsafeMatrixView{T}(pointer(a), size(a, 1), size(a, 2))

function unsafe_view{T}(a::ContiguousArray{T}, r1::Colon, r2::Colon) 
	siz = size(a)
	UnsafeMatrixView{T}(pointer(a), siz[1], succ_length(siz, 1))
end

unsafe_view(a::ContiguousArray, r::Colon, r2::Range1{Int}) = offset_view(a, offset(a, 1, r2[1]), size(a, 1), length(r2))
unsafe_view(a::ContiguousArray, r::Colon, r2::Range1{Int}, k::Int) = offset_view(a, offset(a, 1, r2[1], k), size(a, 1), length(r2))
unsafe_view(a::ContiguousArray, r::Colon, r2::Colon, k::Int) = offset_view(a, offset(a, 1, 1, k), size(a, 1), size(a, 2))

# 3D

unsafe_view{T}(a::ContiguousCube{T}) = UnsafeCubeView{T}(pointer(a), size(a, 1), size(a, 2), size(a, 3)) 

unsafe_view{T}(a::ContiguousVector{T}, r::Colon, r2::Colon, r3::Colon) = UnsafeCubeView{T}(pointer(a), size(a, 1), 1, 1)
unsafe_view{T}(a::ContiguousMatrix{T}, r::Colon, r2::Colon, r3::Colon) = UnsafeCubeView{T}(pointer(a), size(a, 1), size(a, 2), 1)

function unsafe_view{T}(a::ContiguousArray{T}, r::Colon, r2::Colon, r3::Colon)
	siz = size(a)
	UnsafeCubeView{T}(pointer(a), siz[1], siz[2], succ_length(siz, 2))
end

function unsafe_view(a::ContiguousArray, r::Colon, r2::Colon, r3::Range1{Int})
	offset_view(a, offset(a, 1, 1, r3[1]), size(a, 1), size(a, 2), length(r3))
end
