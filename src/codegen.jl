# Code generation facilities

# type aliases

typealias SymOrNum Union(Symbol, Number)

typealias EwiseArray Union(Array,BitArray)
typealias EwiseVector Union(Vector,BitVector)
typealias EwiseMatrix Union(Matrix,BitMatrix)
typealias EwiseCube{T} Union(Array{T, 3}, BitArray{3})

typealias ArrayOrNumber Union(EwiseArray, Number)
typealias VectorOrNumber Union(EwiseVector, Number)
typealias MatrixOrNumber Union(EwiseMatrix, Number)
typealias CubeOrNumber Union(EwiseCube, Number)

typealias DimSpec Union(Int, (Int, Int))

# element access

get_scalar(x::EwiseArray, i::Int) = x[i]
get_scalar(x::EwiseArray, i::Int, j::Int) = x[i,j]
get_scalar(x::EwiseArray, i::Int, j::Int, k::Int) = x[i,j,k]

get_scalar(x::Number, i::Int) = x
get_scalar(x::Number, i::Int, j::Int) = x
get_scalar(x::Number, i::Int, j::Int, k::Int) = x

# shape inference 

map_shape(x1::EwiseArray) = size(x1)

map_shape(x1::EwiseArray, x2::EwiseArray) = promote_shape(size(x1), size(x2))
map_shape(x1::EwiseArray, x2::Number) = size(x1)
map_shape(x1::Number, x2::EwiseArray) = size(x2)

map_shape(x1::EwiseArray, x2::EwiseArray, x3::EwiseArray) = promote_shape(size(x1), promote_shape(size(x2), size(x3)))
map_shape(x1::EwiseArray, x2::EwiseArray, x3::Number) = promote_shape(size(x1), size(x2))
map_shape(x1::EwiseArray, x2::Number, x3::EwiseArray) = promote_shape(size(x1), size(x3))
map_shape(x1::Number, x2::EwiseArray, x3::EwiseArray) = promote_shape(size(x2), size(x3))
map_shape(x1::EwiseArray, x2::Number, x3::Number) = size(x1)
map_shape(x1::Number, x2::EwiseArray, x3::Number) = size(x2)
map_shape(x1::Number, x2::Number, x3::EwiseArray) = size(x3)

function map_length(x1::EwiseArray, x2::EwiseArray)
	if length(x1) != length(x2)
		throw(ArgumentError("Argment lengths must match."))
	end
	length(x1)
end

map_length(x1::EwiseArray, x2::Number) = length(x1)
map_length(x1::Number, x2::EwiseArray) = length(x2)

function map_length(x1::EwiseArray, x2::EwiseArray, x3::EwiseArray)
	if !(length(x1) == length(x2) == length(x3))
		throw(ArgumentError("Argment lengths must match."))
	end
	length(x1)
end

map_length(x1::EwiseArray, x2::EwiseArray, x3::Number) = map_length(x1, x2)
map_length(x1::EwiseArray, x2::Number, x3::EwiseArray) = map_length(x1, x3)
map_length(x1::Number, x2::EwiseArray, x3::EwiseArray) = map_length(x2, x3)
map_length(x1::EwiseArray, x2::Number, x3::Number) = length(x1)
map_length(x1::Number, x2::EwiseArray, x3::Number) = length(x2)
map_length(x1::Number, x2::Number, x3::EwiseArray) = length(x3)

precede_length(siz::NTuple{Int}, d::Int) = d == 2 ? siz[1] : d == 3 ? siz[1] * siz[2] : prod(siz[1:d-1])
trail_length(siz::NTuple{Int}, d::Int) = (nd = length(siz); d == nd - 1 ? siz[nd] : prod(siz[d+1:nd]))

# value type inference

result_eltype(op::UnaryFunctor, x::EwiseArray) = result_type(op, eltype(x))
result_eltype(op::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber) = result_type(op, eltype(x1), eltype(x2))
result_eltype(op::TernaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, x3::ArrayOrNumber) = result_type(op, eltype(x1), eltype(x2), eltype(x3))


# building block generators

abstract EwiseCoder

type TrivialCoder <: EwiseCoder end

generate_paramlist(::TrivialCoder) = (:(x::EwiseArray),)
generate_paramlist_forcubes(::TrivialCoder) = (:(x::EwiseCube),)

generate_arglist(::TrivialCoder) = (:x,)
generate_kernel(::TrivialCoder, i::SymOrNum) = :(x[$i])
generate_emptytest(::TrivialCoder) = :(isempty(x))

length_inference(::TrivialCoder) = :(length(x))
shape_inference(::TrivialCoder) = :(size(x))
eltype_inference(::TrivialCoder) = :(eltype(x))

type UnaryCoder <: EwiseCoder end

generate_paramlist(::UnaryCoder) = (:(f::UnaryFunctor), :(x::EwiseArray))
generate_paramlist_forcubes(::UnaryCoder) = (:(f::UnaryFunctor), :(x::EwiseCube))

generate_arglist(::UnaryCoder) = (:f, :x)
generate_kernel(::UnaryCoder, i::SymOrNum) = :(evaluate(f, x[$i]))
generate_emptytest(::UnaryCoder) = :(isempty(x))

length_inference(::UnaryCoder) = :(length(x))
shape_inference(::UnaryCoder) = :(size(x))
eltype_inference(::UnaryCoder) = :(result_type(f, eltype(x))) 

type BinaryCoder <: EwiseCoder end

generate_paramlist(::BinaryCoder) = (:(f::BinaryFunctor), :(x1::ArrayOrNumber), :(x2::ArrayOrNumber))
generate_paramlist_forcubes(::BinaryCoder) = (:(f::BinaryFunctor), :(x1::CubeOrNumber), :(x2::CubeOrNumber))

generate_arglist(::BinaryCoder) = (:f, :x1, :x2)
generate_kernel(::BinaryCoder, i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i), get_scalar(x2, $i)))
generate_emptytest(::BinaryCoder) = :(isempty(x1) || isempty(x2))

length_inference(::BinaryCoder) = :(map_length(x1, x2))
shape_inference(::BinaryCoder) = :(map_shape(x1, x2))
eltype_inference(::BinaryCoder) = :(result_type(f, eltype(x1), eltype(x2)))

type FDiffCoder <: EwiseCoder end

generate_paramlist(::FDiffCoder) = (:(f::UnaryFunctor), :(x1::ArrayOrNumber), :(x2::ArrayOrNumber))
generate_paramlist_forcubes(::FDiffCoder) = (:(f::UnaryFunctor), :(x1::CubeOrNumber), :(x2::CubeOrNumber))

generate_arglist(::FDiffCoder) = (:f, :x1, :x2)
generate_kernel(::FDiffCoder, i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i) - get_scalar(x2, $i)))
generate_emptytest(::FDiffCoder) = :(isempty(x1) || isempty(x2))

length_inference(::FDiffCoder) = :(map_length(x1, x2))
shape_inference(::FDiffCoder) = :(map_shape(x1, x2))
eltype_inference(::FDiffCoder) = :(result_type(f, promote_type(eltype(x1), eltype(x2))))

type TernaryCoder <: EwiseCoder end

generate_paramlist(::TernaryCoder) = (:(f::TernaryFunctor), :(x1::ArrayOrNumber), :(x2::ArrayOrNumber), :(x3::ArrayOrNumber))
generate_paramlist_forcubes(::TernaryCoder) = (:(f::TernaryFunctor), :(x1::CubeOrNumber), :(x2::CubeOrNumber), :(x3::CubeOrNumber))

generate_arglist(::TernaryCoder) = (:f, :x1, :x2, :x3)
generate_kernel(::TernaryCoder, i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i), get_scalar(x2, $i), get_scalar(x3, $i)))
generate_emptytest(::TernaryCoder) = :(isempty(x1) || isempty(x2) || isempty(x3))

length_inference(::TernaryCoder) = :(map_length(x1, x2, x3))
shape_inference(::TernaryCoder) = :(map_shape(x1, x2, x3))
eltype_inference(::TernaryCoder) = :(result_type(f, eltype(x1), eltype(x2), eltype(x3)))

