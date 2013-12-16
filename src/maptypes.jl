# Result types of function evaluation

# FP types

fptype{T<:FloatingPoint}(::Type{T}) = T

fptype{T<:Integer}(::Type{T}) = Float64

fptype(::Type{Bool}) = Float32
fptype(::Type{Int8}) = Float32
fptype(::Type{Uint8}) = Float32
fptype(::Type{Int16}) = Float32
fptype(::Type{Uint16}) = Float32

promote_fptype{T1<:FloatingPoint, T2<:FloatingPoint}(::Type{T1}, ::Type{T2}) = promote_type(T1, T2)
promote_fptype{T1<:FloatingPoint, T2<:Integer}(::Type{T1}, ::Type{T2}) = T1
promote_fptype{T1<:Integer, T2<:FloatingPoint}(::Type{T1}, ::Type{T2}) = T2
promote_fptype{T1<:Integer, T2<:Integer}(::Type{T1}, ::Type{T2}) = promote_type(fptype(T1), fptype(T2))


#################################################
#
#    Arithmetic operations
#
#################################################

for op in [:+, :-, :*, :.+ ,:.-, :.*]
	@eval maptype{T<:Number}(::TFun{$(Meta.quot(op))}, ::Type{T}, ::Type{T}) = T
	@eval maptype{T1<:Number,T2<:Number}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = promote_type(T1, T2)
end

maptype(::TFun{:+}, ::Type{Bool}, ::Type{Bool}) = Int
maptype(::TFun{:-}, ::Type{Bool}, ::Type{Bool}) = Int

for op in [:/, :\, :./, :.\]
	@eval maptype{T<:Number}(::TFun{$(Meta.quot(op))}, ::Type{T}, ::Type{T}) = fptype(T)
	@eval maptype{T1<:Number,T2<:Number}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = promote_fptype(T1, T2)
end

maptype{T1<:FloatingPoint, T2<:FloatingPoint}(::Union(TFun{:^},TFun{:.^}), ::Type{T1}, ::Type{T2}) = promote_type(T1, T2)
maptype{T1<:FloatingPoint, T2<:Integer}(::Union(TFun{:^},TFun{:.^}), ::Type{T1}, ::Type{T2}) = T1
maptype{T1<:Integer, T2<:FloatingPoint}(::Union(TFun{:^},TFun{:.^}), ::Type{T1}, ::Type{T2}) = T2
maptype{T1<:Integer, T2<:Integer}(::Union(TFun{:^},TFun{:.^}), ::Type{T1}, ::Type{T2}) = promote_type(T1, T2)
maptype{T2<:Integer}(::Union(TFun{:^},TFun{:.^}), ::Type{Bool}, ::Type{T2}) = Bool


#################################################
#
#    comparison, logical, & bit operations
#
#################################################

# comparison

for op in [:(==), :(!=), :<, :>, :<=, :>=, :.==, :.!=, :.<, :.>, :.<=, :.>=]
	@eval maptype{T1<:Number, T2<:Number}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = Bool
end

# logical & bit

for op in [:&, :|, :$]
	@eval maptype{T<:Integer}(::TFun{$(Meta.quot(op))}, ::Type{T}, ::Type{T}) = T
	@eval maptype{T1<:Integer, T2<:Integer}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = promote_type(T1, T2)
end

maptype{T<:Integer}(::TFun{:~}, ::Type{T}) = T


#################################################
#
#    Math functions
#
#################################################

# abs & abs2

maptype(::Union(TFun{:abs},TFun{:abs2}), ::Type{Bool}) = Bool
maptype{T<:Number}(::Union(TFun{:abs},TFun{:abs2}), ::Type{T}) = T 
maptype{T<:Signed}(::Union(TFun{:abs},TFun{:abs2}), ::Type{T}) = promote_type(T, Int)
maptype{T<:Unsigned}(::TFun{:abs}, ::Type{T}) = T
maptype{T<:Unsigned}(::TFun{:abs2}, ::Type{T}) = promote_type(T, Uint)




