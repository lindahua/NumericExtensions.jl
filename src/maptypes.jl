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

for op in [:+, :.+, :-, :.-, :*, :.*, :%, :.%, :div, :fld, :rem, :mod]
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

for op in [:(==), :(!=), :isequal]
	@eval maptype{T1<:Number, T2<:Number}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = Bool
end

for op in [:<, :>, :<=, :>=, :.==, :.!=, :.<, :.>, :.<=, :.>=]
	@eval maptype{T1<:Real, T2<:Real}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = Bool
end

# predicates

for op in [:isinf, :isnan, :isfinite]
	@eval maptype{T<:Real}(::TFun{$(Meta.quot(op))}, ::Type{T}) = Bool
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
maptype{T<:Real}(::Union(TFun{:abs},TFun{:abs2}), ::Type{T}) = T 
maptype{T<:Signed}(::Union(TFun{:abs},TFun{:abs2}), ::Type{T}) = promote_type(T, Int)
maptype{T<:Unsigned}(::TFun{:abs}, ::Type{T}) = T
maptype{T<:Unsigned}(::TFun{:abs2}, ::Type{T}) = promote_type(T, Uint)

# sign & fp rounding

for op in [:sign, :floor, :ceil, :trunc, :round]
	@eval maptype{T<:Real}(::TFun{$(Meta.quot(op))}, ::Type{T}) = T
end

for op in [:ifloor, :iceil, :itrunc, :iround]
	@eval maptype{T<:FloatingPoint}(::TFun{$(Meta.quot(op))}, ::Type{T}) = Int64
	@eval maptype{T<:Integer}(::TFun{$(Meta.quot(op))}, ::Type{T}) = T
end

# unary real functions

for op in [:sqrt, :cbrt, :rcp, :rsqrt, :rcbrt,
	:exp, :exp2, :exp10, :expm1, :log, :log2, :log10, :log1p, 
	:sin, :cos, :tan, :cot, :sec, :csc,
	:sinh, :cosh, :tanh, :coth, :sech, :csch,
	:asin, :acos, :atan, :acot, :asec, :acsc,
	:asinh, :acosh, :atanh, :acoth, :asech, :acsch,  
	:sind, :cosd, :tand, :cotd, :secd, :cscd,
	:asind, :acosd, :atand, :acotd, :asecd, :acscd, 
	:erf, :erfc, :erfinv, :erfcinv, :gamma, :lgamma, :digamma, 
	:eta, :zeta]

	@eval maptype{T<:FloatingPoint}(::TFun{$(Meta.quot(op))}, ::Type{T}) = T
	@eval maptype{T<:Integer}(::TFun{$(Meta.quot(op))}, ::Type{T}) = fptype(T)
end

maptype{T<:Number}(::TFun{:sqr}, ::Type{T}) = T

# binary real functions

for op in [:hypot, :atan2, :beta, :lbeta]
	@eval maptype{T<:Real}(::TFun{$(Meta.quot(op))}, ::Type{T}, ::Type{T}) = fptype(T)
	@eval maptype{T1<:Real,T2<:Real}(::TFun{$(Meta.quot(op))}, ::Type{T1}, ::Type{T2}) = promote_type(fptype(T1), fptype(T2))
end




