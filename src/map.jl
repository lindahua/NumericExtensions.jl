# map operations to elements

# code generators

function code_map_function(fname!::Symbol, coder_expr::Expr)
	coder = eval(coder_expr)
	paramlist = generate_paramlist(coder)
	kernel = generate_kernel(coder, :i)
	quote
		function ($fname!)($(paramlist[1]), dst::EwiseArray, $(paramlist[2:]...))
			for i in 1 : length(dst)
				dst[i] = $kernel
			end
			dst
		end
	end
end

macro map_function(fname, coder)
	esc(code_map_function(fname, coder))
end

# generic map functions

@map_function map! UnaryCoder()
@map_function map! BinaryCoder()
@map_function mapdiff! FDiffCoder()
@map_function map! TernaryCoder()

map1!(f::Functor, x1, xr...) = map!(f, x1, x1, xr...)

function map(f::Functor, xs...)
	map!(f, Array(result_eltype(f, xs...), map_shape(xs...)), xs...)
end

function mapdiff(f::UnaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	rt = result_type(f, promote_type(eltype(x1), eltype(x2)))
	mapdiff!(f, Array(rt, map_shape(x1, x2)), x1, x2)
end	

# specific inplace functions

add!(x::EwiseArray, y::ArrayOrNumber) = map1!(Add(), x, y)
subtract!(x::EwiseArray, y::ArrayOrNumber) = map1!(Subtract(), x, y)
multiply!(x::EwiseArray, y::ArrayOrNumber) = map1!(Multiply(), x, y)
divide!(x::EwiseArray, y::ArrayOrNumber) = map1!(Divide(), x, y)

negate!(x::EwiseArray) = map1!(Negate(), x)
abs!(x::EwiseArray) = map1!(Abs(), x)
abs2!(x::EwiseArray) = map1!(Abs2(), x)
rcp!(x::EwiseArray) = map!(Divide(), x, one(eltype(x)), x)
sqrt!(x::EwiseArray) = map1!(Sqrt(), x)
pow!(x::EwiseArray, p::ArrayOrNumber) = map1!(Pow(), x, p)

floor!(x::EwiseArray) = map1!(Floor(), x)
ceil!(x::EwiseArray) = map1!(Ceil(), x)
round!(x::EwiseArray) = map1!(Round(), x)
trunc!(x::EwiseArray) = map1!(Trunc(), x)

exp!(x::EwiseArray) = map1!(Exp(), x)
log!(x::EwiseArray) = map1!(Log(), x)

# extensions

absdiff(x::EwiseArray, y::EwiseArray) = mapdiff(Abs(), x, y)
sqrdiff(x::EwiseArray, y::EwiseArray) = mapdiff(Abs2(), x, y)

fma!(a::EwiseArray, b::EwiseArray, c::ArrayOrNumber) = map1!(FMA(), a, b, c)
fma(a::EwiseArray, b::EwiseArray, c::ArrayOrNumber) = map(FMA(), a, b, c)

