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

add!(x::AbstractArray, y::ArrayOrNumber) = map1!(Add(), x, y)
subtract!(x::AbstractArray, y::ArrayOrNumber) = map1!(Subtract(), x, y)
multiply!(x::AbstractArray, y::ArrayOrNumber) = map1!(Multiply(), x, y)
divide!(x::AbstractArray, y::ArrayOrNumber) = map1!(Divide(), x, y)

negate!(x::AbstractArray) = map1!(Negate(), x)
abs!(x::AbstractArray) = map1!(Abs(), x)
abs2!(x::AbstractArray) = map1!(Abs2(), x)
rcp!{T}(x::AbstractArray{T}) = map!(Divide(), x, one(T), x)
sqrt!(x::AbstractArray) = map1!(Sqrt(), x)
pow!(x::AbstractArray, p::ArrayOrNumber) = map1!(Pow(), x, p)

floor!(x::AbstractArray) = map1!(Floor(), x)
ceil!(x::AbstractArray) = map1!(Ceil(), x)
round!(x::AbstractArray) = map1!(Round(), x)
trunc!(x::AbstractArray) = map1!(Trunc(), x)

exp!(x::AbstractArray) = map1!(Exp(), x)
log!(x::AbstractArray) = map1!(Log(), x)

# extensions

absdiff(x::AbstractArray, y::AbstractArray) = mapdiff(Abs(), x, y)
sqrdiff(x::AbstractArray, y::AbstractArray) = mapdiff(Abs2(), x, y)

fma!(a::AbstractArray, b::AbstractArray, c::ArrayOrNumber) = map1!(FMA(), a, b, c)
fma(a::AbstractArray, b::AbstractArray, c::ArrayOrNumber) = map(FMA(), a, b, c)

