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

for op in [:^, :.^]
	@eval maptype{T1<:FloatingPoint, T2<:FloatingPoint}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = promote_type(T1, T2)
	@eval maptype{T1<:FloatingPoint, T2<:Integer}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = T1
	@eval maptype{T1<:Integer, T2<:FloatingPoint}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = T2
	@eval maptype{T1<:Integer, T2<:Integer}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = promote_type(T1, T2)
	@eval maptype{T2<:Integer}(::TFun{$(Meta.quot(op))}, ::Type{Bool}, ::Type{T2}) = Bool
end


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


#################################################
#
#    Math functions
#
#################################################

for op in [:abs2]
	@eval maptype{T<:Number}(::TFun{$(Meta.quot(op))}, ::Type{T}) = T 
end
