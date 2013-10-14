# map operations to elements

#################################################
#
#   Generic macros for map-code generation
#
#################################################



map1!(f::Functor, x1, xr...) = map!(f, x1, x1, xr...)

function map(f::Functor, xs...)
	map!(f, Array(result_eltype(f, xs...), map_shape(xs...)), xs...)
end

function mapdiff(f::UnaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	rt = result_type(f, promote_type(eltype(x1), eltype(x2)))
	mapdiff!(f, Array(rt, map_shape(x1, x2)), x1, x2)
end	

# specific inplace functions

add!(x::ContiguousArray, y::ArrayOrNumber) = map1!(Add(), x, y)
subtract!(x::ContiguousArray, y::ArrayOrNumber) = map1!(Subtract(), x, y)
multiply!(x::ContiguousArray, y::ArrayOrNumber) = map1!(Multiply(), x, y)
divide!(x::ContiguousArray, y::ArrayOrNumber) = map1!(Divide(), x, y)

negate!(x::ContiguousArray) = map1!(Negate(), x)
abs!(x::ContiguousArray) = map1!(AbsFun(), x)
abs2!(x::ContiguousArray) = map1!(Abs2Fun(), x)
rcp!(x::ContiguousArray) = map!(Divide(), x, one(eltype(x)), x)
sqrt!(x::ContiguousArray) = map1!(SqrtFun(), x)
pow!(x::ContiguousArray, p::ArrayOrNumber) = map1!(Pow(), x, p)

floor!(x::ContiguousArray) = map1!(FloorFun(), x)
ceil!(x::ContiguousArray) = map1!(CeilFun(), x)
round!(x::ContiguousArray) = map1!(RoundFun(), x)
trunc!(x::ContiguousArray) = map1!(TruncFun(), x)

exp!(x::ContiguousArray) = map1!(ExpFun(), x)
log!(x::ContiguousArray) = map1!(LogFun(), x)

# extensions

absdiff(x::ContiguousArray, y::ContiguousArray) = mapdiff(AbsFun(), x, y)
sqrdiff(x::ContiguousArray, y::ContiguousArray) = mapdiff(Abs2Fun(), x, y)

fma!(a::ContiguousArray, b::ContiguousArray, c::ArrayOrNumber) = map1!(FMA(), a, b, c)
fma(a::ContiguousArray, b::ContiguousArray, c::ArrayOrNumber) = map(FMA(), a, b, c)

