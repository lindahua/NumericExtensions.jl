# Reduction functions related to statistics

using NumericFunctors
using Base.Test

# mean

macro check_nonempty(funname)
	quote
		if isempty(x)
			error("$($funname) of empty collection undefined")
		end
	end
end

function mean(x::Array)
	@check_nonempty("mean")
	sum(x) / length(x)
end

function mean{T<:Real}(x::Array{T}, dims::DimSpec)
	@check_nonempty("mean")
	r = to_fparray(sum(x, dims))
	c = convert(eltype(r), inv(_reduc_dim_length(x, dims)))
	multiply!(r, c)
end

function mean!{R<:Real,T<:Real}(dst::Array{R}, x::Array{T}, dims::DimSpec)
	@check_nonempty("mean")
	c = convert(R, inv(_reduc_dim_length(x, dims)))
	multiply!(sum!(dst, x, dims), c)
end

# entropy

entropy(x::Array) = - sum_xlogx(x)
entropy(x::Array, dims::DimSpec) = negate!(sum_xlogx(x, dims))
entropy!(dst::Array, x::Array, dims::DimSpec) = negate!(sum_xlogx!(dst, x, dims))


