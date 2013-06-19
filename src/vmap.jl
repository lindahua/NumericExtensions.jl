# map operations to elements

# auxiliary functions

get_scalar(x::AbstractArray, i::Int) = x[i]
get_scalar(x::AbstractArray, i::Int, j::Int) = x[i,j]
get_scalar(x::AbstractArray, i::Int, j::Int, k::Int) = x[i,j,k]

get_scalar(x::Number, i::Int) = x
get_scalar(x::Number, i::Int, j::Int) = x
get_scalar(x::Number, i::Int, j::Int, k::Int) = x

typealias SymOrNum Union(Symbol, Number)
typealias ArrayOrNumber Union(AbstractArray, Number)
typealias VectorOrNumber Union(AbstractVector, Number)
typealias MatrixOrNumber Union(AbstractMatrix, Number)
typealias AbstractCube{T} AbstractArray{T,3}
typealias CubeOrNumber Union(AbstractCube, Number)

map_shape(x1::AbstractArray, x2::AbstractArray) = promote_shape(size(x1), size(x2))
map_shape(x1::AbstractArray, x2::Number) = size(x1)
map_shape(x1::Number, x2::AbstractArray) = size(x2)

function map_length(x1::AbstractArray, x2::AbstractArray)
	if length(x1) != length(x2)
		throw(ArgumentError("Argment lengths must match."))
	end
	length(x1)
end

map_length(x1::AbstractArray, x2::Number) = length(x1)
map_length(x1::Number, x2::AbstractArray) = length(x2)

result_eltype{T}(op::UnaryFunctor, x::AbstractArray{T}) = result_type(op, T)
result_eltype{T1,T2}(op::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2}) = result_type(op, T1, T2)
result_eltype{T1,T2<:Number}(op::BinaryFunctor, x1::AbstractArray{T1}, x2::T2) = result_type(op, T1, T2)
result_eltype{T1<:Number,T2}(op::BinaryFunctor, x1::T1, x2::AbstractArray{T2}) = result_type(op, T1, T2)

# code-gen devices

_ker_nofun(i::SymOrNum) = :(x[$i])
_ker_nofun(i::SymOrNum, j::SymOrNum) = :(x[$i, $j])
_ker_nofun(i::SymOrNum, j::SymOrNum, l::SymOrNum) = :(x[$i, $j, $l])

_ker_unaryfun(i::SymOrNum) = :(evaluate(f, x[$i]))
_ker_unaryfun(i::SymOrNum, j::SymOrNum) = :(evaluate(f, x[$i, $j]))
_ker_unaryfun(i::SymOrNum, j::SymOrNum, l::SymOrNum) = :(evaluate(f, x[$i, $j, $l]))

_ker_binaryfun(i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i), get_scalar(x2, $i)))
_ker_binaryfun(i::SymOrNum, j::SymOrNum) = :(evaluate(f, get_scalar(x1, $i, $j), get_scalar(x2, $i, $j)))
_ker_binaryfun(i::SymOrNum, j::SymOrNum, l::SymOrNum) = :(evaluate(f, get_scalar(x1, $i, $j, $l), get_scalar(x2, $i, $j, $l)))

_ker_fdiff(i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i) - get_scalar(x2, $i)))
_ker_fdiff(i::SymOrNum, j::SymOrNum) = :(evaluate(f, get_scalar(x1, $i, $j) - get_scalar(x2, $i, $j)))
_ker_fdiff(i::SymOrNum, j::SymOrNum, l::SymOrNum) = :(evaluate(f, get_scalar(x1, $i, $j, $l) - get_scalar(x2, $i, $j, $l)))

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


# one argument

function vmap!(dst::AbstractArray, f::UnaryFunctor, x::AbstractArray)
	@_vmap _ker_unaryfun
end

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









