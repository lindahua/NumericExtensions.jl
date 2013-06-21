# Reduction functions related to statistics

using NumericFunctors
using Base.Test

entropy(x::EwiseArray) = - sum_xlogx(x)
entropy(x::EwiseArray, dims::DimSpec) = negate!(sum_xlogx(x, dims))
entropy!(dst::EwiseArray, x::EwiseArray, dims::DimSpec) = negate!(sum_xlogx!(dst, x, dims))


