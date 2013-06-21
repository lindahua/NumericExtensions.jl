# Reduction functions related to statistics

using NumericFunctors
using Base.Test

# mean

macro check_mean_nonempty()
	quote
		if isempty(x)
			error("mean of empty collection undefined")
		end
	end
end

function mean(x::EwiseArray)
	@check_mean_nonempty
	sum(x) / length(x)
end

function mean(x::EwiseArray, dims::DimSpec)
	@check_mean_nonempty
	multiply!(sum(x, dims), inv(_reduc_dim_length(x, dims)))
end

function mean!(dst::EwiseArray, x::EwiseArray, dims::DimSpec)
	@check_mean_nonempty
	multiply!(sum!(dst, x, dims), inv(_reduc_dim_length(x, dims)))
end


# entropy

entropy(x::EwiseArray) = - sum_xlogx(x)
entropy(x::EwiseArray, dims::DimSpec) = negate!(sum_xlogx(x, dims))
entropy!(dst::EwiseArray, x::EwiseArray, dims::DimSpec) = negate!(sum_xlogx!(dst, x, dims))


