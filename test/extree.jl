## Unit testing of extree.jl

using NumericExtensions
using Base.Test

import NumericExtensions.is_unary_ewise
import NumericExtensions.is_binary_ewise
import NumericExtensions.is_binary_sewise
import NumericExtensions.is_unary_reduc
import NumericExtensions.is_binary_reduc

import NumericExtensions.AbstractExpr
import NumericExtensions.EwiseExpr
import NumericExtensions.SimpleExpr
import NumericExtensions.EGenericExpr
import NumericExtensions.EConst
import NumericExtensions.EVar
import NumericExtensions.ERange
import NumericExtensions.EFun
import NumericExtensions.ECall
import NumericExtensions.EMapCall
import NumericExtensions.EReducCall
import NumericExtensions.EGenericCall
import NumericExtensions.EColon
import NumericExtensions.ERef
import NumericExtensions.EEnd
import NumericExtensions.EColon

#### Type System

@assert EwiseExpr <: AbstractExpr
@assert EGenericExpr <: AbstractExpr
@assert SimpleExpr <: EwiseExpr
@assert EConst <: SimpleExpr
@assert EVar   <: SimpleExpr
@assert ERange <: SimpleExpr

@assert ECall <: AbstractExpr
@assert EMapCall <: ECall
@assert EReducCall <: ECall
@assert EGenericCall <: ECall

@assert EMapCall <: EwiseExpr
@assert !(EReducCall <: EwiseExpr)
@assert !(EGenericCall <: EwiseExpr)

@assert ERef <: EwiseExpr


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

@test is_unary_reduc(EFun(:sum))
@test is_unary_reduc(EFun(:mean))
@test is_binary_reduc(EFun(:sumsqdiff))


#### Expression elements

x = extree(4.5)
@test isa(x, EConst{Float64})
@test x.value == 4.5

x = extree(:a)
@test isa(x, EVar)
@test !x.isscalar
@test x.sym == :(a)

x = extree(:(1:3))
@test isa(x, ERange)
@test x.args == (extree(1), extree(3))

x = extree(:(u:))
@test isa(x, ERange)
@test x.args == (extree(:u), EEnd())

x = extree(:(1:2:n))
@test isa(x, ERange)
@test x.args == (extree(1), extree(2), extree(:n))

x = extree(:(a:2:))
@test isa(x, ERange)
@test x.args == (extree(:a), extree(2), EEnd())






