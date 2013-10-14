# map operations to elements

# code generators

function code_map_function{KType<:EwiseFunKernel}(fname!::Symbol, ktype::Type{KType})
	plst = paramlist(ktype, :ContiguousArray)
	ker = kernel(ktype, :i)
	quote
		function ($fname!)($(plst[1]), dst::ContiguousArray, $(plst[2:]...))
			for i in 1 : length(dst)
				@inbounds dst[i] = $ker
			end
			dst
		end
	end
end

macro map_function(fname, ktype)
	esc(code_map_function(fname, eval(ktype)))
end

# generic map functions

@map_function map! UnaryFunKernel
@map_function map! BinaryFunKernel
@map_function mapdiff! DiffFunKernel
@map_function map! TernaryFunKernel

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

negate!(x::ContiguousArray) = map1!(NegateFun(), x)
abs!(x::ContiguousArray) = map1!(AbsFun(), x)
abs2!(x::ContiguousArray) = map1!(Abs2Fun(), x)
rcp!(x::ContiguousArray) = map!(Divide(), x, one(eltype(x)), x)
sqrt!(x::ContiguousArray) = map1!(Sqrt(), x)
pow!(x::ContiguousArray, p::ArrayOrNumber) = map1!(Pow(), x, p)

floor!(x::ContiguousArray) = map1!(Floor(), x)
ceil!(x::ContiguousArray) = map1!(Ceil(), x)
round!(x::ContiguousArray) = map1!(Round(), x)
trunc!(x::ContiguousArray) = map1!(Trunc(), x)

exp!(x::ContiguousArray) = map1!(Exp(), x)
log!(x::ContiguousArray) = map1!(Log(), x)

# extensions

absdiff(x::ContiguousArray, y::ContiguousArray) = mapdiff(AbsFun(), x, y)
sqrdiff(x::ContiguousArray, y::ContiguousArray) = mapdiff(Abs2Fun(), x, y)

fma!(a::ContiguousArray, b::ContiguousArray, c::ArrayOrNumber) = map1!(FMA(), a, b, c)
fma(a::ContiguousArray, b::ContiguousArray, c::ArrayOrNumber) = map(FMA(), a, b, c)

