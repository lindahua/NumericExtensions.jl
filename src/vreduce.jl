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
	v::R = init
	for i in 1 : length(x)
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
	v = f(x[1])
	for i in 2 : length(x)
		v = evaluate(op, v, evaluate(f, x[i]))
	end
	v
end

function vreduce(op::BinaryFunctor, f::BinaryFunctor, x1::AbstractArray, x2::AbstractArray)
	v = f(x1[1], x2[1])
	for i in 2 : length(x)
		v = evaluate(op, v, evaluate(f, x1[i], x2[i]))
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
	isempty(x) ? zero(result_type(f, T1, T2)) : vreduce(Add(), f, x1, x2)
end

# nonneg max

function nonneg_vmax{T}(x::AbstractArray{T})
	isempty(x) ? zero(T) : vreduce(Max(), x)
end

function nonneg_vmax{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? zero(result_type(f, T)) : vreduce(Max(), f, x)
end

function nonneg_vmax{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x) ? zero(result_type(f, T1, T2)) : vreduce(Max(), f, x1, x2)
end

# max

function vmax{T}(x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmax cannot accept empty array.")) : vreduce(Max(), x)
end

function vmax{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmax cannot accept empty array.")) : vreduce(Max(), f, x)
end

function vmax{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x) ? throw(ArgumentError("vmax cannot accept empty array.")) : vreduce(Max(), f, x1, x2)
end

# min

function vmin{T}(x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmin cannot accept empty array.")) : vreduce(Min(), x)
end

function vmin{T}(f::UnaryFunctor, x::AbstractArray{T})
	isempty(x) ? throw(ArgumentError("vmin cannot accept empty array.")) : vreduce(Min(), f, x)
end

function vmin{T1,T2}(f::BinaryFunctor, x1::AbstractArray{T1}, x2::AbstractArray{T2})
	isempty(x) ? throw(ArgumentError("vmin cannot accept empty array.")) : vreduce(Min(), f, x1, x2)
end


#################################################
#
# 	Derived reduction functions
#
#################################################

vasum(x::AbstractArray{T}) = vsum(Abs(), x)
vamax(x::AbstractArray{T}) = nonneg_vmax(Abs(), x)
vamin(x::AbstractArray{T}) = vmin(Abs(), x)

vsqsum(x::AbstractArray{T}) = vsum(Abs2(), x)




