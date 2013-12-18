# Information about mathematical functions needed for expression parsing

#################################################
#
#    Additional math functions
#
#################################################

sqr(x::Number) = x * x
rcp(x::Number) = one(x) / x
rsqrt(x::Number) = one(x) / sqrt(x) 
rcbrt(x::Real) = one(x) / cbrt(x)

logit(x::Real) = log(x / (one(x) - x))
xlogx(x::Real) = x > zero(x) ? x * log(x) : zero(x)
xlogy(x::Real, y::Real) = x > zero(x) ? x * log(y) : zero(x)

logistic(x::Real) = one(x) / (one(x) + exp(-x))
invlogistic(y::Real) = -log(one(y) / y - one(y))

softplus(x::Real) = log(one(x) + exp(x))
invsoftplus(x::Real) = log(exp(x) - one(x))

@vectorize_1arg Number sqr
@vectorize_1arg Number rcp
@vectorize_1arg Real rsqrt
@vectorize_1arg Real rcbrt

@vectorize_1arg Real logit
@vectorize_1arg Real logistic

