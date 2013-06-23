# Code generation facilities

# type aliases

typealias SymOrNum Union(Symbol, Number)

typealias ArrayOrNumber Union(ContiguousArray, Number)
typealias VectorOrNumber Union(ContiguousVector, Number)
typealias MatrixOrNumber Union(ContiguousMatrix, Number)
typealias CubeOrNumber Union(ContiguousCube, Number)

typealias DimSpec Union(Int, (Int, Int))

# element access

get_scalar(x::ContiguousArray, i::Int) = x[i]
get_scalar(x::ContiguousArray, i::Int, j::Int) = x[i,j]
get_scalar(x::ContiguousArray, i::Int, j::Int, k::Int) = x[i,j,k]

get_scalar(x::Number, i::Int) = x
get_scalar(x::Number, i::Int, j::Int) = x
get_scalar(x::Number, i::Int, j::Int, k::Int) = x

# value type inference

result_eltype(op::UnaryFunctor, x::ContiguousArray) = result_type(op, eltype(x))
result_eltype(op::BinaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber) = result_type(op, eltype(x1), eltype(x2))
result_eltype(op::TernaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, x3::ArrayOrNumber) = result_type(op, eltype(x1), eltype(x2), eltype(x3))

to_fparray{T<:FloatingPoint}(x::AbstractArray{T}) = x
to_fparray{T<:Integer,N}(x::AbstractArray{T,N}) = convert(Array{to_fptype(T), N}, x)

# building block generators

abstract EwiseCoder

type TrivialCoder <: EwiseCoder end

generate_paramlist(::TrivialCoder) = (:(x::ContiguousArray),)
generate_paramlist_forcubes(::TrivialCoder) = (:(x::ContiguousCube),)

generate_arglist(::TrivialCoder) = (:x,)
generate_kernel(::TrivialCoder, i::SymOrNum) = :(x[$i])
generate_emptytest(::TrivialCoder) = :(isempty(x))

length_inference(::TrivialCoder) = :(length(x))
shape_inference(::TrivialCoder) = :(size(x))
eltype_inference(::TrivialCoder) = :(eltype(x))

type UnaryCoder <: EwiseCoder end

generate_paramlist(::UnaryCoder) = (:(f::UnaryFunctor), :(x::ContiguousArray))
generate_paramlist_forcubes(::UnaryCoder) = (:(f::UnaryFunctor), :(x::ContiguousCube))

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

length_inference(::BinaryCoder) = :(prod(map_shape(x1, x2)))
shape_inference(::BinaryCoder) = :(map_shape(x1, x2))
eltype_inference(::BinaryCoder) = :(result_type(f, eltype(x1), eltype(x2)))

type FDiffCoder <: EwiseCoder end

generate_paramlist(::FDiffCoder) = (:(f::UnaryFunctor), :(x1::ArrayOrNumber), :(x2::ArrayOrNumber))
generate_paramlist_forcubes(::FDiffCoder) = (:(f::UnaryFunctor), :(x1::CubeOrNumber), :(x2::CubeOrNumber))

generate_arglist(::FDiffCoder) = (:f, :x1, :x2)
generate_kernel(::FDiffCoder, i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i) - get_scalar(x2, $i)))
generate_emptytest(::FDiffCoder) = :(isempty(x1) || isempty(x2))

length_inference(::FDiffCoder) = :(prod(map_shape(x1, x2)))
shape_inference(::FDiffCoder) = :(map_shape(x1, x2))
eltype_inference(::FDiffCoder) = :(result_type(f, promote_type(eltype(x1), eltype(x2))))

type TernaryCoder <: EwiseCoder end

generate_paramlist(::TernaryCoder) = (:(f::TernaryFunctor), :(x1::ArrayOrNumber), :(x2::ArrayOrNumber), :(x3::ArrayOrNumber))
generate_paramlist_forcubes(::TernaryCoder) = (:(f::TernaryFunctor), :(x1::CubeOrNumber), :(x2::CubeOrNumber), :(x3::CubeOrNumber))

generate_arglist(::TernaryCoder) = (:f, :x1, :x2, :x3)
generate_kernel(::TernaryCoder, i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i), get_scalar(x2, $i), get_scalar(x3, $i)))
generate_emptytest(::TernaryCoder) = :(isempty(x1) || isempty(x2) || isempty(x3))

length_inference(::TernaryCoder) = :(prod(map_shape(x1, x2, x3)))
shape_inference(::TernaryCoder) = :(map_shape(x1, x2, x3))
eltype_inference(::TernaryCoder) = :(result_type(f, eltype(x1), eltype(x2), eltype(x3)))

