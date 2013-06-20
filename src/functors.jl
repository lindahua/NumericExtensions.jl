# common functors

abstract Functor{N}  # N: the number of arguments

typealias UnaryFunctor Functor{1}
typealias BinaryFunctor Functor{2}
typealias TernaryFunctor Functor{3}

# unary functors 

for e in [
    (:Negate, :-), (:Abs, :abs), (:Abs2, :abs2), (:Sqrt, :sqrt), (:Cbrt, :cbrt),
    (:Floor, :floor), (:Ceil, :ceil), (:Round, :round), (:Trunc, :trunc),
    (:Exp, :exp), (:Exp2, :exp2), (:Exp10, :exp10), (:Expm1, :expm1),
    (:Log, :log), (:Log2, :log2), (:Log10, :log10), (:Log1p, :log1p), 
    (:Sin, :sin), (:Cos, :cos), (:Tan, :tan), 
    (:Asin, :asin), (:Acos, :acos), (:Atan, :atan), 
    (:Sinh, :sinh), (:Cosh, :cosh), (:Tanh, :tanh),
    (:Asinh, :asinh), (:Acosh, :acosh), (:Atanh, :atanh), 
    (:Erf, :erf), (:Erfc, :erfc), 
    (:Gamma, :gamma), (:Lgamma, :lgamma), (:Digamma, :digamma), 
    (:Isfinite, :isfinite), (:Isnan, :isnan), (:Isinf, :isinf)]

    @eval type $(e[1]) <: UnaryFunctor end
    @eval evaluate(::($(e[1])), x::Number) = ($(e[2]))(x)
end

# binary functors

for e in [
    (:Add, :+), (:Subtract, :-), (:Multiply, :*), (:Divide, :/), (:Pow, :^), 
    (:Greater, :>), (:GreaterEqual, :>=), (:Less, :<), (:LessEqual, :<=), 
    (:Equal, :(==)), (:NotEqual, :(!=)),
    (:Max, :max), (:Min, :min), (:Hypot, :hypot), (:Atan2, :atan2)]

    @eval type $(e[1]) <: BinaryFunctor end
    @eval evaluate(::($(e[1])), x::Number, y::Number) = ($(e[2]))(x, y)
end

evaluate{T<:Real}(::Max, x::T, y::T) = x < y ? y : x
evaluate{T<:Real}(::Min, x::T, y::T) = x > y ? y : x

immutable FixAbsPow{T<:Real} <: UnaryFunctor 
    p::T
end
evaluate(op::FixAbsPow, x::Number) = abs(x) ^ op.p

# ternary functors

type FMA <: TernaryFunctor end

evaluate(op::FMA, a::Number, b::Number, c::Number) = a + b * c


#################################################
#
#  Result type inference
#
#################################################

to_fptype{T<:Number}(x::Type{T}) = typeof(convert(FloatingPoint, zero(T)))

for Op in [:Add, :Subtract, :Multiply, :Pow, :Max, :Min]
    @eval result_type{T1<:Number, T2<:Number}(::($Op), ::Type{T1}, ::Type{T2}) = promote_type(T1, T2)
    @eval result_type{T<:Number}(::($Op), ::Type{T}, ::Type{T}) = T
end

for Op in [:Divide, :Hypot, :Atan2]
    @eval result_type{T1<:Number, T2<:Number}(::$(Op), ::Type{T1}, ::Type{T2}) = to_fptype(promote_type(T1, T2))
    @eval result_type{T<:Number}(::$(Op), ::Type{T}, ::Type{T}) = to_fptype(T)
    @eval result_type{T<:FloatingPoint}(::$(Op), ::Type{T}, ::Type{T}) = T
end

for Op in [:Negate, :Floor, :Ceil, :Round, :Trunc]
    @eval result_type{T<:Number}(::$(Op), ::Type{T}) = T
end

for Op in [:Sqrt, :Cbrt, 
    :Exp, :Exp2, :Exp10, :Expm1, 
    :Log, :Log2, :Log10, :Log1p, 
    :Sin, :Cos, :Tan, :Asin, :Acos, :Atan, 
    :Sinh, :Cosh, :Tanh, :Asinh, :Acosh, :Atanh, 
    :Erf, :Erfc, :Gamma, :Lgamma, :Digamma]

    @eval result_type{T<:Number}(::$(Op), ::Type{T}) = to_fptype(T)
end

for Op in [:Greater, :GreaterEqual, :Less, :LessEqual, :Equal, :NotEqual]
    @eval result_type{T1, T2}(::$(Op), ::Type{T1}, ::Type{T2}) = Bool
end

for Op in [:Isfinite, :Isnan, :Isinf]
    @eval result_type{T<:Real}(::$(Op), ::Type{T}) = Bool
end

result_type{T<:Real}(::Abs, ::Type{T}) = T
result_type{T<:Real}(::Abs, ::Type{Complex{T}}) = to_fptype(T)
result_type{T<:Real}(::Abs2, ::Type{T}) = T
result_type{T<:Real}(::Abs2, ::Type{Complex{T}}) = T
result_type{Tp<:Real, T<:Number}(::FixAbsPow, ::Type{T}) = promote_type(Tp, T)

result_type{T1<:Number,T2<:Number,T3<:Number}(::FMA, ::Type{T1}, ::Type{T2}, ::Type{T3}) = promote_type(T1, promote_type(T2, T3))
result_type{T<:Number}(::FMA, ::Type{T}, ::Type{T}, ::Type{T}) = T

