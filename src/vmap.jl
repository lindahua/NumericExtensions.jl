# map operations to elements


function _code_vmap(kergen::Symbol)
	kernel = eval(:($kergen(:i)))
	quote
		for i in 1 : length(dst)
			(dst)[i] = $kernel
		end
		dst
	end
end

macro _vmap(kergen)
	esc(_code_vmap(kergen))
end


function _code_vmap_function(gen::Symbol)
	genf = eval(gen)
	paramlist = genf(_ParamList())
	kernel = genf(_KernelExpr(), :i)
	code = quote
		function vmap!(dst::AbstractArray, $(paramlist...))
			for i in 1 : length(dst)
				dst[i] = $kernel
			end
			dst
		end
	end
	println(code)
	code
end

macro _vmap_function(gen)
	esc(_code_vmap_function(gen))
end

# one argument

@_vmap_function gen1

# function vmap!(dst::AbstractArray, f::UnaryFunctor, x::AbstractArray)
# 	@_vmap _ker_unaryfun
# end

vmap!(f::UnaryFunctor, x::AbstractArray) = vmap!(x, f, x)
vmap(f::UnaryFunctor, x::AbstractArray) = vmap!(Array(result_eltype(f, x), size(x)), f, x)

# two arguments

function vmap!(dst::AbstractArray, f::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	@_vmap _ker_binaryfun
end

vmap!(f::BinaryFunctor, x1::AbstractArray, x2::ArrayOrNumber) = vmap!(x1, f, x1, x2)
function vmap(f::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	vmap!(Array(result_eltype(f, x1, x2), map_shape(x1, x2)), f, x1, x2)
end

# vmapdiff

function vmapdiff!(dst::AbstractArray, f::UnaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber)
	@_vmap _ker_fdiff
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









