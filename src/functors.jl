# common functors

abstract Functor{N}  # N: the number of arguments

typealias UnaryFunctor Functor{1}
typealias BinaryFunctor Functor{2}
typealias TernaryFunctor Functor{3}

# additional functions

logit{T<:FloatingPoint}(x::T) = log(x/(one(T)-x))
xlogx{T<:FloatingPoint}(x::T) = x > 0 ? x * log(x) : zero(T)
xlogy{T<:FloatingPoint}(x::T, y::T) = x > 0 ? x * log(y) : zero(T)

relu{T<:FloatingPoint}(x::T) = max(zero(T), x)

logistic{T<:FloatingPoint}(x::T) = one(T)/(one(T) + exp(-x))
invlogistic{T<:FloatingPoint}(y::T) = -log(one(T) / y - one(T))

softplus{T<:FloatingPoint}(x::T) = log(one(T) + exp(x))
invsoftplus{T<:FloatingPoint}(y::T) = log(exp(y) - one(T))

# unary functors 

for e in [
    (:Negate, :-), (:AbsFun, :abs), (:Abs2Fun, :abs2), (:SqrtFun, :sqrt), (:CbrtFun, :cbrt),
    (:FloorFun, :floor), (:CeilFun, :ceil), (:RoundFun, :round), (:TruncFun, :trunc),
    (:ExpFun, :exp), (:Exp2Fun, :exp2), (:Exp10Fun, :exp10), (:Expm1Fun, :expm1),
    (:LogFun, :log), (:Log2Fun, :log2), (:Log10Fun, :log10), (:Log1pFun, :log1p), 
    (:SinFun, :sin), (:CosFun, :cos), (:TanFun, :tan), 
    (:AsinFun, :asin), (:AcosFun, :acos), (:AtanFun, :atan), 
    (:SinhFun, :sinh), (:CoshFun, :cosh), (:TanhFun, :tanh),
    (:AsinhFun, :asinh), (:AcoshFun, :acosh), (:AtanhFun, :atanh), 
    (:ErfFun, :erf), (:ErfcFun, :erfc), 
    (:GammaFun, :gamma), (:LgammaFun, :lgamma), (:DigammaFun, :digamma), 
    (:IsfiniteFun, :isfinite), (:IsnanFun, :isnan), (:IsinfFun, :isinf)]

    @eval type $(e[1]) <: UnaryFunctor end
    @eval evaluate(::($(e[1])), x::Number) = ($(e[2]))(x)
end

# binary functors

for e in [
    (:Add, :+), (:Subtract, :-), (:Multiply, :*), (:Divide, :/), (:Pow, :^), 
    (:Greater, :>), (:GreaterEqual, :>=), (:Less, :<), (:LessEqual, :<=), 
    (:Equal, :(==)), (:NotEqual, :(!=)),
    (:MaxFun, :max), (:MinFun, :min), (:HypotFun, :hypot), (:Atan2Fun, :atan2)]

    @eval type $(e[1]) <: BinaryFunctor end
    @eval evaluate(::($(e[1])), x::Number, y::Number) = ($(e[2]))(x, y)
end

### Note: this special code is needed to get performance 
# due to compiler issues, the functions are not properly inlined without this
# in some cases

evaluate{T<:Integer}(::MaxFun, x::T, y::T) = (x > y ? x : y)
evaluate{T<:Integer}(::MinFun, x::T, y::T) = (x < y ? x : y)

@unix_only const libm = dlopen("libm")
@unix_only const _fmax  = dlsym(libm, :fmax)
@unix_only const _fmaxf = dlsym(libm, :fmaxf)
@unix_only const _fmin  = dlsym(libm, :fmin)
@unix_only const _fminf = dlsym(libm, :fminf)

@unix_only evaluate(::MaxFun, x::Float64, y::Float64) = ccall(_fmax,  Float64, (Float64, Float64), x, y)
@unix_only evaluate(::MaxFun, x::Float32, y::Float32) = ccall(_fmaxf, Float32, (Float32, Float32), x, y)
@unix_only evaluate(::MinFun, x::Float64, y::Float64) = ccall(_fmin,  Float64, (Float64, Float64), x, y)
@unix_only evaluate(::MinFun, x::Float32, y::Float32) = ccall(_fminf, Float32, (Float32, Float32), x, y)

immutable FixAbsPow{T<:Real} <: UnaryFunctor 
    p::T
end
evaluate(op::FixAbsPow, x::Number) = abs(x) ^ op.p

type Recip <: UnaryFunctor end
type LogitFun <: UnaryFunctor end
type LogisticFun <: UnaryFunctor end
type XlogxFun <: UnaryFunctor end
type XlogyFun <: BinaryFunctor end

const RecipFun = Recip

evaluate{T<:FloatingPoint}(::Recip, x::T) = one(T) / x
evaluate{T<:FloatingPoint}(::LogitFun, x::T) = log(x/(one(T)-x))
evaluate{T<:FloatingPoint}(::LogisticFun, x::T) = one(T)/(one(T) + exp(-x))
evaluate{T<:FloatingPoint}(::XlogxFun, x::T) = x > 0 ? x * log(x) : zero(T)
evaluate{T<:FloatingPoint}(::XlogyFun, x::T, y::T) = x > 0 ? x * log(y) : zero(T)

# ternary functors

type FMA <: TernaryFunctor end

evaluate(op::FMA, a::Number, b::Number, c::Number) = a + b * c


#################################################
#
#  Result type inference
#
#################################################

to_fptype{T<:Number}(x::Type{T}) = typeof(convert(FloatingPoint, zero(T)))

for Op in [:Add, :Subtract, :Multiply, :Pow, :MaxFun, :MinFun]
    @eval result_type{T1<:Number, T2<:Number}(::($Op), ::Type{T1}, ::Type{T2}) = promote_type(T1, T2)
    @eval result_type{T<:Number}(::($Op), ::Type{T}, ::Type{T}) = T
end

result_type(::Add, ::Type{Bool}, ::Type{Bool}) = Int
result_type(::Subtract, ::Type{Bool}, ::Type{Bool}) = Int

for Op in [:Divide, :HypotFun, :Atan2Fun]
    @eval result_type{T1<:Number, T2<:Number}(::$(Op), ::Type{T1}, ::Type{T2}) = to_fptype(promote_type(T1, T2))
    @eval result_type{T<:Number}(::$(Op), ::Type{T}, ::Type{T}) = to_fptype(T)
    @eval result_type{T<:FloatingPoint}(::$(Op), ::Type{T}, ::Type{T}) = T
end

for Op in [:Negate, :FloorFun, :CeilFun, :RoundFun, :TruncFun]
    @eval result_type{T<:Number}(::$(Op), ::Type{T}) = T
end

for Op in [:SqrtFun, :CbrtFun, 
    :ExpFun, :Exp2Fun, :Exp10Fun, :Expm1Fun, 
    :LogFun, :Log2Fun, :Log10Fun, :Log1pFun, 
    :SinFun, :CosFun, :TanFun, :AsinFun, :AcosFun, :AtanFun, 
    :SinhFun, :CoshFun, :TanhFun, :AsinhFun, :AcoshFun, :AtanhFun, 
    :ErfFun, :ErfcFun, :GammaFun, :LgammaFun, :DigammaFun]

    @eval result_type{T<:Number}(::$(Op), ::Type{T}) = to_fptype(T)
end

for Op in [:Greater, :GreaterEqual, :Less, :LessEqual, :Equal, :NotEqual]
    @eval result_type{T1, T2}(::$(Op), ::Type{T1}, ::Type{T2}) = Bool
end

for Op in [:IsfiniteFun, :IsnanFun, :IsinfFun]
    @eval result_type{T<:Real}(::$(Op), ::Type{T}) = Bool
end

result_type{T<:Real}(::AbsFun, ::Type{T}) = T
result_type{T<:Real}(::AbsFun, ::Type{Complex{T}}) = to_fptype(T)
result_type{T<:Real}(::Abs2Fun, ::Type{T}) = T
result_type{T<:Real}(::Abs2Fun, ::Type{Complex{T}}) = T
result_type{Tp<:Real, T<:Number}(::FixAbsPow{Tp}, ::Type{T}) = promote_type(Tp, T)

result_type{T1<:Number,T2<:Number,T3<:Number}(::FMA, ::Type{T1}, ::Type{T2}, ::Type{T3}) = promote_type(T1, promote_type(T2, T3))
result_type{T<:Number}(::FMA, ::Type{T}, ::Type{T}, ::Type{T}) = T

result_type{T<:FloatingPoint}(::Recip, ::Type{T}) = T
result_type{T<:FloatingPoint}(::LogitFun, ::Type{T}) = T
result_type{T<:FloatingPoint}(::LogisticFun, ::Type{T}, ::Type{T}) = T
result_type{T<:FloatingPoint}(::XlogxFun, ::Type{T}) = T
result_type{T<:FloatingPoint}(::XlogyFun, ::Type{T}, ::Type{T}) = T



