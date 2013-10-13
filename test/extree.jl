## Unit testing of extree.jl

using NumericExtensions
using Base.Test

import NumericExtensions.is_unary_ewise
import NumericExtensions.is_binary_ewise
import NumericExtensions.is_binary_sewise
import NumericExtensions.EFun

#### EFun properties

@test is_unary_ewise(EFun(:-))
@test is_unary_ewise(EFun(:exp))
@test is_binary_ewise(EFun(:+))
@test is_binary_ewise(EFun(:atan2))

@test is_binary_sewise(EFun(:*))
@test is_binary_sewise(EFun(:/))
@test is_binary_sewise(EFun(:\))
@test is_binary_sewise(EFun(:^))
@test is_binary_sewise(EFun(:%))

@test !is_binary_ewise(EFun(:*))
@test !is_binary_ewise(EFun(:/))
@test !is_binary_ewise(EFun(:\))
@test !is_binary_ewise(EFun(:^))
@test !is_binary_ewise(EFun(:%))
