# Information about mathematical functions needed for expression parsing

#################################################
#
#    Additional math functions
#
#################################################

sqr(x::Number) = x * x
rcp(x::Number) = one(x) / x
rsqrt(x::Real) = one(x) / sqrt(x) 
rcbrt(x::Real) = one(x) / cbrt(x)

@vectorize_1arg Number sqr
@vectorize_1arg Number rcp
@vectorize_1arg Real rsqrt
@vectorize_1arg Real rcbrt


#################################################
#
#    Recognizable element-wise functions
#
#################################################

const UNARY_EWISE_FUNCTIONS = Set(
	:+, :-, :~, 
	:abs, :abs2, :sqr, :sqrt, :cbrt, :rcp, :rsqrt, :rcbrt,
	:real, :imag, :conj, :angle, :sign, :signbit,
	:log, :log2, :log10, :log1p, :logb, :ilogb,
	:exp, :exp2, :exp10, :expm1, 
	:floor, :ceil, :round, :trunc, 
	:ifloor, :iceil, :iround, :itrunc,
	:sin, :cos, :tan, :sec, :csc, :cot, :sinc, :cosc,
	:asin, :acos, :atan, :asec, :acsc, :acot,
	:sind, :cosd, :tand, :secd, :cscd, :cotd,
	:asind, :acosd, :atand, :asecd, :acscd, :acotd,
	:sinh, :cosh, :tanh, :sech, :csch, :coth,
	:asinh, :acosh, :atanh, :asech, :acsch, :acoth,
	:erf, :erfc, :erfcx, :gamma, :lgamma, :digamma, 
	:airy, :airyai, :airyprime, :airyaiprime, :airybi, :airybiprime, 
	:besselj0, :besselj1, :bessely0, :bessely1, :eta, :zeta)

const BINARY_EWISE_FUNCTIONS = Set(
	:+, :-, :.+, :.-, :.*, :./, :.\, :.^, :.%, 
	:(==), :(!=), :(<), :(>), :(<=), :(>=), :cmp,
	:(.==), :(.!=), :(.<), :(.>), :(.<=), :(.>=),
	:&, :|, :$, :div, :fld, :mod, :rem, 
	:atan2, :hypot, :frexp, :ldexp, :copysign, :flipsign,
	:besselj, :bessely, :hankelh1, :hankelh2, :besseli, :besselk,
	:beta, :lbeta)

# This functions are recognized as element-wise operation
# only when one of the operands is a literal number
const BINARY_SEWISE_FUNCTIONS = Set(:*, :/, :\, :^, :%)
