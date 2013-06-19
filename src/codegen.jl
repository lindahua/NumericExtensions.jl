# Code generation facilities

# type aliases

typealias SymOrNum Union(Symbol, Number)
typealias ArrayOrNumber Union(AbstractArray, Number)
typealias VectorOrNumber Union(AbstractVector, Number)
typealias MatrixOrNumber Union(AbstractMatrix, Number)
typealias AbstractCube{T} AbstractArray{T,3}
typealias CubeOrNumber Union(AbstractCube, Number)

typealias DimSpec Union(Int, (Int, Int))

# element access

get_scalar(x::AbstractArray, i::Int) = x[i]
get_scalar(x::AbstractArray, i::Int, j::Int) = x[i,j]
get_scalar(x::AbstractArray, i::Int, j::Int, k::Int) = x[i,j,k]

get_scalar(x::Number, i::Int) = x
get_scalar(x::Number, i::Int, j::Int) = x
get_scalar(x::Number, i::Int, j::Int, k::Int) = x

# shape inference

map_shape(x1::AbstractArray) = size(x1)
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

precede_length(siz::NTuple{Int}, d::Int) = d == 2 ? siz[1] : d == 3 ? siz[1] * siz[2] : prod(siz[1:d-1])
trail_length(siz::NTuple{Int}, d::Int) = (nd = length(siz); d == nd - 1 ? siz[nd] : prod(siz[d+1:nd]))

# value type inference

result_eltype{T}(op::UnaryFunctor, x::AbstractArray{T}) = result_type(op, T)
result_eltype{T1,T2}(op::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2}) = result_type(op, T1, T2)
result_eltype{T1,T2<:Number}(op::BinaryFunctor, x1::AbstractArray{T1}, x2::T2) = result_type(op, T1, T2)
result_eltype{T1<:Number,T2}(op::BinaryFunctor, x1::T1, x2::AbstractArray{T2}) = result_type(op, T1, T2)

# building block generators

abstract AbstractFunCoder

type TrivialCoder <: AbstractFunCoder end

generate_paramlist(::TrivialCoder) = (:(x::AbstractArray),)
generate_paramlist_forcubes(::TrivialCoder) = (:(x::AbstractCube),)

generate_arglist(::TrivialCoder) = (:x,)
generate_kernel(::TrivialCoder, i::SymOrNum) = :(x[$i])
generate_emptytest(::TrivialCoder) = :(isempty(x))

length_inference(::TrivialCoder) = :(length(x))
shape_inference(::TrivialCoder) = :(size(x))
eltype_inference(::TrivialCoder) = :(eltype(x))

type UnaryCoder <: AbstractFunCoder end

generate_paramlist(::UnaryCoder) = (:(f::UnaryFunctor), :(x::AbstractArray))
generate_paramlist_forcubes(::UnaryCoder) = (:(f::UnaryFunctor), :(x::AbstractCube))

generate_arglist(::UnaryCoder) = (:f, :x)
generate_kernel(::UnaryCoder, i::SymOrNum) = :(evaluate(f, x[$i]))
generate_emptytest(::UnaryCoder) = :(isempty(x))

length_inference(::UnaryCoder) = :(length(x))
shape_inference(::UnaryCoder) = :(size(x))
eltype_inference(::UnaryCoder) = :(result_type(f, eltype(x))) 

type BinaryCoder <: AbstractFunCoder end

generate_paramlist(::BinaryCoder) = (:(f::BinaryFunctor), :(x1::ArrayOrNumber), :(x2::ArrayOrNumber))
generate_paramlist_forcubes(::BinaryCoder) = (:(f::BinaryFunctor), :(x1::CubeOrNumber), :(x2::CubeOrNumber))

generate_arglist(::BinaryCoder) = (:f, :x1, :x2)
generate_kernel(::BinaryCoder, i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i), get_scalar(x2, $i)))
generate_emptytest(::BinaryCoder) = :(isempty(x1) || isempty(x2))

length_inference(::BinaryCoder) = :(map_length(x1, x2))
shape_inference(::BinaryCoder) = :(map_shape(x1, x2))
eltype_inference(::BinaryCoder) = :(result_type(f, eltype(x1), eltype(x2)))

type FDiffCoder <: AbstractFunCoder end

generate_paramlist(::FDiffCoder) = (:(f::UnaryFunctor), :(x1::ArrayOrNumber), :(x2::ArrayOrNumber))
generate_paramlist_forcubes(::FDiffCoder) = (:(f::UnaryFunctor), :(x1::CubeOrNumber), :(x2::CubeOrNumber))

generate_arglist(::FDiffCoder) = (:f, :x1, :x2)
generate_kernel(::FDiffCoder, i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i) - get_scalar(x2, $i)))
generate_emptytest(::FDiffCoder) = :(isempty(x1) || isempty(x2))

length_inference(::FDiffCoder) = :(map_length(x1, x2))
shape_inference(::FDiffCoder) = :(map_shape(x1, x2))
eltype_inference(::FDiffCoder) = :(result_type(f, promote_type(eltype(x1), eltype(x2))))

