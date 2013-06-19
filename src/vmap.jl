# map operations to elements

# code generators

function code_vmap_function(fname::Symbol, coder_expr::Expr)
	coder = eval(coder_expr)
	paramlist = generate_paramlist(coder)
	kernel = generate_kernel(coder, :i)
	quote
		function ($fname)(dst::AbstractArray, $(paramlist...))
			for i in 1 : length(dst)
				dst[i] = $kernel
			end
			dst
		end
	end
end

macro vmap_function(fname, coder)
	esc(code_vmap_function(fname, coder))
end

# generic vmap functions

@vmap_function vmap! UnaryCoder()
@vmap_function vmap! BinaryCoder()
@vmap_function vmapdiff! FDiffCoder()
@vmap_function vmap! TernaryCoder()

vmap!(f::Functor, x1, xr...) = vmap!(x1, f, x1, xr...)

function vmap(f::Functor, xs...)
	vmap!(Array(result_eltype(f, xs...), map_shape(xs...)), f, xs...)
end

function vmapdiff(f::UnaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	rt = result_type(f, promote_type(eltype(x1), eltype(x2)))
	vmapdiff!(Array(rt, map_shape(x1, x2)), f, x1, x2)
end	

# specific inplace functions

add!(x::AbstractArray, y::ArrayOrNumber) = vmap!(Add(), x, y)
subtract!(x::AbstractArray, y::ArrayOrNumber) = vmap!(Subtract(), x, y)
multiply!(x::AbstractArray, y::ArrayOrNumber) = vmap!(Multiply(), x, y)
divide!(x::AbstractArray, y::ArrayOrNumber) = vmap!(Divide(), x, y)

negate!(x::AbstractArray) = vmap!(Negate(), x)
abs!(x::AbstractArray) = vmap!(Abs(), x)
abs2!(x::AbstractArray) = vmap!(Abs2(), x)
rcp!{T}(x::AbstractArray{T}) = vmap!(x, Divide(), one(T), x)
sqrt!(x::AbstractArray) = vmap!(Sqrt(), x)
pow!(x::AbstractArray, p::ArrayOrNumber) = vmap!(Pow(), x, p)

floor!(x::AbstractArray) = vmap!(Floor(), x)
ceil!(x::AbstractArray) = vmap!(Ceil(), x)
round!(x::AbstractArray) = vmap!(Round(), x)
trunc!(x::AbstractArray) = vmap!(Trunc(), x)

exp!(x::AbstractArray) = vmap!(Exp(), x)
log!(x::AbstractArray) = vmap!(Log(), x)

# extensions

absdiff(x::AbstractArray, y::AbstractArray) = vmapdiff(Abs(), x, y)
sqrdiff(x::AbstractArray, y::AbstractArray) = vmapdiff(Abs2(), x, y)

fma!(a::AbstractArray, b::AbstractArray, c::ArrayOrNumber) = vmap!(FMA(), a, b, c)
fma(a::AbstractArray, b::AbstractArray, c::ArrayOrNumber) = vmap(FMA(), a, b, c)

