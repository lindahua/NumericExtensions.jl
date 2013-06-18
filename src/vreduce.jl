#################################################
#
# 	Generic reduction
#
#################################################

function vreduce{R<:Union(Number, Bool)}(op::BinaryFunctor, init::R, x::AbstractArray)
	v::R = init
	for i in 1 : length(x)
		v = evaluate(op, v, x[i])
	end
	v
end

function vreduce{R<:Union(Number, Bool)}(op::BinaryFunctor, init::R, f::UnaryFunctor, x::AbstractArray)
	v::R = init
	for i in 1 : length(x)
		v = evaluate(op, v, evaluate(f, x[i]))
	end
	v
end

function vreduce{R<:Union(Number, Bool)}(op::BinaryFunctor, init::R, f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray)
	if length(x1) != length(x2)
		throw(ArgumentError("Argument length must match."))
	end
	v::R = init
	for i in 1 : length(x1)
		v = evaluate(op, v, evaluate(f, x1[i], x2[i]))
	end
	v
end

function vreduce(op::BinaryFunctor, x::AbstractArray)
	v = x[1]
	for i in 2 : length(x)
		v = evaluate(op, v, x[i])
	end
	v
end

function vreduce(op::BinaryFunctor, f::UnaryFunctor, x::AbstractArray)
	v = evaluate(f, x[1])
	for i in 2 : length(x)
		v = evaluate(op, v, evaluate(f, x[i]))
	end
	v
end

function vreduce(op::BinaryFunctor, f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray)
	if length(x1) != length(x2)
		throw(ArgumentError("Argument length must match."))
	end
	v = evaluate(f, x1[1], x2[1])
	for i in 2 : length(x1)
		v = evaluate(op, v, evaluate(f, x1[i], x2[i]))
	end
	v
end

function vreduce_fdiff(op::BinaryFunctor, f::UnaryFunctor, x1::AbstractArray, x2::AbstractArray)
	if length(x1) != length(x2)
		throw(ArgumentError("Argument length must match."))
	end
	v = evaluate(f, x1[1] - x2[1])
	for i in 2 : length(x1)
		v = evaluate(op, v, evaluate(f, x1[i] - x2[i]))
	end
	v
end

function vreduce_fdiff(op::BinaryFunctor, f::UnaryFunctor, x1::AbstractArray, x2::Number)
	v = evaluate(f, x1[1] - x2)
	for i in 2 : length(x1)
		v = evaluate(op, v, evaluate(f, x1[i] - x2))
	end
	v
end

function vreduce_fdiff(op::BinaryFunctor, f::UnaryFunctor, x1::Number, x2::AbstractArray)
	v = evaluate(f, x1 - x2[1])
	for i in 2 : length(x2)
		v = evaluate(op, v, evaluate(f, x1 - x2[i]))
	end
	v
end



#################################################
#
# 	Basic reduction functions
#
#################################################

# sum

function vsum{T}(x::AbstractArray{T})
	isempty(x) ? zero(T) : vreduce(Add(), x)
end

function vsum{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? zero(result_type(f, T)) : vreduce(Add(), f, x)
end

function vsum{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? zero(result_type(f, T1, T2)) : vreduce(Add(), f, x1, x2)
end

# sum on diff

function vsum_fdiff{T1<:Number,T2<:Number}(f::UnaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? zero(result_type(f, T1, T2)) : vreduce_fdiff(Add(), f, x1, x2)
end

function vsum_fdiff{T1<:Number,T2<:Number}(f::UnaryFunctor, x1::AbstractArray{T1}, x2::T2)
	isempty(x1) && isempty(x2) ? zero(result_type(f, T1, T2)) : vreduce_fdiff(Add(), f, x1, x2)
end

function vsum_fdiff{T1<:Number,T2<:Number}(f::UnaryFunctor, x1::T1, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? zero(result_type(f, T1, T2)) : vreduce_fdiff(Add(), f, x1, x2)
end

# nonneg max

function nonneg_vmax{T}(x::AbstractArray{T})
	isempty(x) ? zero(T) : vreduce(Max(), x)
end

function nonneg_vmax{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? zero(result_type(f, T)) : vreduce(Max(), f, x)
end

function nonneg_vmax{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? zero(result_type(f, T1, T2)) : vreduce(Max(), f, x1, x2)
end

# max

function vmax{T}(x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmax cannot accept empty array.")) : vreduce(Max(), x)
end

function vmax{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmax cannot accept empty array.")) : vreduce(Max(), f, x)
end

function vmax{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? throw(ArgumentError("vmax cannot accept empty array.")) : vreduce(Max(), f, x1, x2)
end

# min

function vmin{T}(x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmin cannot accept empty array.")) : vreduce(Min(), x)
end

function vmin{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmin cannot accept empty array.")) : vreduce(Min(), f, x)
end

function vmin{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x1) && isempty(x2) ? throw(ArgumentError("vmin cannot accept empty array.")) : vreduce(Min(), f, x1, x2)
end


#################################################
#
# 	Derived reduction functions
#
#################################################

const asum = Base.LinAlg.BLAS.asum

vasum(x::Array) = asum(x)
vasum(x::AbstractArray) = vsum(Abs(), x)
vamax(x::AbstractArray) = nonneg_vmax(Abs(), x)
vamin(x::AbstractArray) = vmin(Abs(), x)

vsqsum(x::Vector) = dot(x, x)
vsqsum(x::Array) = vsqsum(vec(x))
vsqsum(x::AbstractArray) = vsum(Abs2(), x)

vdot(x::Vector, y::Vector) = dot(x, y)
vdot(x::Array, y::Array) = dot(vec(x), vec(y))
vdot(x::AbstractArray, y::AbstractArray) = vsum(Multiply(), x, y)

vadiffsum(x::AbstractArray, y::Union(AbstractArray,Number)) = vsum_fdiff(Abs(), x, y)
vadiffmax(x::AbstractArray, y::Union(AbstractArray,Number)) = vreduce_fdiff(Max(), Abs(), x, y)
vadiffmin(x::AbstractArray, y::Union(AbstractArray,Number)) = vreduce_fdiff(Min(), Abs(), x, y)
vsqdiffsum(x::AbstractArray, y::Union(AbstractArray,Number)) = vsum_fdiff(Abs2(), x, y)

# vnorm

function vnorm(x::AbstractArray, p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? vasum(x) :
	p == 2 ? sqrt(vsqsum(x)) :	
	isinf(p) ? vamax(x) :
	vsum(FixAbsPow(p), x) .^ inv(p)
end

function vdiffnorm(x::AbstractArray, y::Union(AbstractArray,Number), p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? vadiffsum(x, y) :
	p == 2 ? sqrt(vsqdiffsum(x, y)) :	
	isinf(p) ? vadiffmax(x, y) :
	vsum_fdiff(FixAbsPow(p), x, y) .^ inv(p)
end

vnorm(x::AbstractArray) = vnorm(x, 2)
vdiffnorm(x::AbstractArray, y::Union(AbstractArray,Number)) = vdiffnorm(x, y, 2)



