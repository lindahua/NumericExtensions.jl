# Shape inference 

typealias SizeTuple{N} NTuple{N,Int}

typealias NumericArray{T<:Number,N} AbstractArray{T,N}
typealias ArrOrNum{T<:Number} Union(AbstractArray{T}, T) 

typealias NumericVector{T<:Number} AbstractVector{T}
typealias NumericMatrix{T<:Number} AbstractMatrix{T}

getvalue(a::Number, i::Integer) = a
getvalue(a::AbstractArray, i::Integer) = a[i]


#### preceding or succeeding length

function prec_length{N}(s::SizeTuple{N}, d::Int)
	d == 1 ? 1 :
	d == 2 ? s[1] :
	d == 3 ? s[1] * s[2] : prod(s[1:d-1])
end

function succ_length{N}(s::SizeTuple{N}, d::Int)
	d == N ? 1 :
	d == N-1 ? s[N] : prod(s[d+1:N])
end

### Shape of mapping

# on size tuples

mapshape(s::SizeTuple) = s

mapshape{N}(s1::SizeTuple{N}, s2::SizeTuple{N}) = (s1 == s2 || error("Argument dimensions are not map-compatible."); s1)

function mapshape{N1,N2}(s1::SizeTuple{N1}, s2::SizeTuple{N2})
	if N1 < N2
		for i = 1 : N1
			s1[i] == s2[i] || error("Argument dimensions are not map-compatible.")
		end
		for i = N1+1 : N2
			s2[i] == 1 || error("Argument dimensions are not map-compatible.")
		end		
		return s2
	else
		for i = 1 : N2
			s1[i] == s2[i] || error("Argument dimensions are not map-compatible.")
		end
		for i = N2+1 : N1
			s1[i] == 1 || error("Argument dimensions are not map-compatible.")
		end
		return s1
	end
end

mapshape(s1::(), s2::()) = ()
mapshape(s1::SizeTuple, s2::()) = s1
mapshape(s1::(), s2::SizeTuple) = s2

mapshape(s1::(Int,Int), s2::(Int,)) = ((s1[1] == s2[1] && s1[2] == 1) || error("Argument dimensions are not map-compatible."); s1)
mapshape(s1::(Int,), s2::(Int,Int)) = ((s1[1] == s2[1] && s2[2] == 1) || error("Argument dimensions are not map-compatible."); s2)

mapshape(s1::SizeTuple, s2::SizeTuple, s3::SizeTuple, rs::SizeTuple...) = mapshape(mapshape(s1, s2), mapshape(s3, rs...))

# on arrays / numbers

mapshape(a1::Number) = ()
mapshape(a1::AbstractArray) = size(a1)

mapshape(a1::Number, a2::Number) = ()
mapshape(a1::AbstractArray, a2::Number) = size(a1)
mapshape(a1::Number, a2::AbstractArray) = size(a2)
mapshape(a1::AbstractArray, a2::AbstractArray) = mapshape(size(a1), size(a2))

mapshape(a1::Number, a2::Number, a3::Number, ra::Number...) = ()
mapshape(a1::ArrOrNum, a2::ArrOrNum, a3::ArrOrNum, ra::ArrOrNum...) = mapshape(mapshape(a1, a2), mapshape(a3, ra...))


### Length of mapping

maplength(a1::Number) = 1
maplength(a1::AbstractArray) = length(a1)

maplength(a1::Number, a2::Number) = 1
maplength(a1::AbstractArray, a2::Number) = length(a1)
maplength(a1::Number, a2::AbstractArray) = length(a2)
maplength(a1::AbstractArray, a2::AbstractArray) = prod(mapshape(a1, a2))

maplength(a1::Number, a2::Number, a3::Number, ra::Number...) = 1
maplength(a1::ArrOrNum, a2::ArrOrNum, a3::ArrOrNum, ra::ArrOrNum...) = prod(mapshape(a1, a2, a3, ra...))

