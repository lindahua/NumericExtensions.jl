# Code generation facilities

# type aliases

typealias SymOrNum Union(Symbol, Number)

typealias ArrayOrNumber Union(ContiguousArray, Number)
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
function result_eltype(op::TernaryFunctor, x1::ArrayOrNumber, x2::ArrayOrNumber, x3::ArrayOrNumber)
	return result_type(op, eltype(x1), eltype(x2), eltype(x3))
end

to_fparray{T<:FloatingPoint}(x::AbstractArray{T}) = x
to_fparray{T<:Integer,N}(x::AbstractArray{T,N}) = convert(Array{to_fptype(T), N}, x)


# building block generators

abstract EwiseKernel
abstract EwiseFunKernel <: EwiseKernel

type DirectKernel <: EwiseKernel end

arglist(::Type{DirectKernel}) = (:x,)
paramlist(::Type{DirectKernel}, aty::Symbol) = (:(x::$aty),)
kernel(::Type{DirectKernel}, i::SymOrNum) = :(x[$i])
emptytest(::Type{DirectKernel}) = :(isempty(x))

length_inference(::Type{DirectKernel}) = :(length(x))
shape_inference(::Type{DirectKernel}) = :(size(x))
eltype_inference(::Type{DirectKernel}) = :(eltype(x))

type UnaryFunKernel <: EwiseFunKernel end

arglist(::Type{UnaryFunKernel}) = (:f, :x)
paramlist(::Type{UnaryFunKernel}, aty::Symbol) = (:(f::UnaryFunctor), :(x::$aty))
kernel(::Type{UnaryFunKernel}, i::SymOrNum) = :(evaluate(f, x[$i]))
emptytest(::Type{UnaryFunKernel}) = :(isempty(x))

length_inference(::Type{UnaryFunKernel}) = :(length(x))
shape_inference(::Type{UnaryFunKernel}) = :(size(x))
eltype_inference(::Type{UnaryFunKernel}) = :(result_type(f, eltype(x))) 

type BinaryFunKernel <: EwiseFunKernel end

arglist(::Type{BinaryFunKernel}) = (:f, :x1, :x2)
paramlist(::Type{BinaryFunKernel}, aty::Symbol) = (:(f::BinaryFunctor), 
	:(x1::Union($aty,Number)), :(x2::Union($aty,Number)))
kernel(::Type{BinaryFunKernel}, i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i), get_scalar(x2, $i)))
emptytest(::Type{BinaryFunKernel}) = :(isempty(x1) || isempty(x2))

length_inference(::Type{BinaryFunKernel}) = :(prod(map_shape(x1, x2)))
shape_inference(::Type{BinaryFunKernel}) = :(map_shape(x1, x2))
eltype_inference(::Type{BinaryFunKernel}) = :(result_type(f, eltype(x1), eltype(x2)))

type DiffFunKernel <: EwiseFunKernel end

arglist(::Type{DiffFunKernel}) = (:f, :x1, :x2)
paramlist(::Type{DiffFunKernel}, aty::Symbol) = (:(f::UnaryFunctor), 
	:(x1::Union($aty,Number)), :(x2::Union($aty,Number)))
kernel(::Type{DiffFunKernel}, i::SymOrNum) = :(evaluate(f, get_scalar(x1, $i) - get_scalar(x2, $i)))
emptytest(::Type{DiffFunKernel}) = :(isempty(x1) || isempty(x2))

length_inference(::Type{DiffFunKernel}) = :(prod(map_shape(x1, x2)))
shape_inference(::Type{DiffFunKernel}) = :(map_shape(x1, x2))
eltype_inference(::Type{DiffFunKernel}) = :(result_type(f, promote_type(eltype(x1), eltype(x2))))

type TernaryFunKernel <: EwiseFunKernel end

arglist(::Type{TernaryFunKernel}) = (:f, :x1, :x2, :x3)
paramlist(::Type{TernaryFunKernel}, aty::Symbol) = (:(f::TernaryFunctor), 
	:(x1::Union($aty,Number)), :(x2::Union($aty,Number)), :(x3::Union($aty,Number)))
kernel(::Type{TernaryFunKernel}, i::SymOrNum) = :(evaluate(f, 
	get_scalar(x1, $i), get_scalar(x2, $i), get_scalar(x3, $i)))
emptytest(::Type{TernaryFunKernel}) = :(isempty(x1) || isempty(x2) || isempty(x3))

length_inference(::Type{TernaryFunKernel}) = :(prod(map_shape(x1, x2, x3)))
shape_inference(::Type{TernaryFunKernel}) = :(map_shape(x1, x2, x3))
eltype_inference(::Type{TernaryFunKernel}) = :(result_type(f, eltype(x1), eltype(x2), eltype(x3)))

