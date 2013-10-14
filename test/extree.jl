## Unit testing of extree.jl

using NumericExtensions
using Base.Test

import NumericExtensions.is_unary_ewise
import NumericExtensions.is_binary_ewise
import NumericExtensions.is_binary_sewise
import NumericExtensions.is_unary_reduc
import NumericExtensions.is_binary_reduc
import NumericExtensions.is_scalar_expr
import NumericExtensions.numargs

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

## EConst

x = extree(4.5)
@test isa(x, EConst{Float64})
@test x.value == 4.5
@test is_scalar_expr(x)

## EVar

x = extree(:a)
@test isa(x, EVar)
@test x.sym == :(a)
@test !is_scalar_expr(x)

x = EVar(:b, true)
@test x.sym == :(b)
@test is_scalar_expr(x)

## ERange

x = extree(:(1:3))
@test isa(x, ERange)
@test x.args == (extree(1), extree(3))
@test !is_scalar_expr(x)

x = extree(:(u:))
@test isa(x, ERange)
@test x.args == (extree(:u), EEnd())
@test !is_scalar_expr(x)

x = extree(:(1:2:n))
@test isa(x, ERange)
@test x.args == (extree(1), extree(2), extree(:n))
@test !is_scalar_expr(x)

x = extree(:(a:2:))
@test isa(x, ERange)
@test x.args == (extree(:a), extree(2), EEnd())
@test !is_scalar_expr(x)

## ERef

x = extree(:(a[1]))
@test isa(x, ERef)
@test x.arr == extree(:a)
@test x.args == (extree(1),)
@test !is_scalar_expr(x)

x = extree(:(a[i, j]))
@test isa(x, ERef)
@test x.arr == extree(:a)
@test x.args == (extree(:i), extree(:j))
@test !is_scalar_expr(x)

x = extree(:(a[i1:i2, j, 1]))
@test isa(x, ERef)
@test x.arr == extree(:a)
@test x.args == (extree(:(i1:i2)), extree(:j), extree(1))
@test !is_scalar_expr(x)

x = extree(:(a[:]))
@test isa(x, ERef)
@test x.arr == extree(:a)
@test x.args == (EColon(),)
@test !is_scalar_expr(x)

x = extree(:(a[:,i,:]))
@test isa(x, ERef)
@test x.arr == extree(:a)
@test x.args == (EColon(), EVar(:i), EColon())
@test !is_scalar_expr(x)

## ECall

# unary call

x = extree(:(scalar(1.5)))
@test x == EConst(1.5)
@test is_scalar_expr(x)

x = extree(:(scalar(a)))
@test x == EVar(:a, true)
@test is_scalar_expr(x)

x = extree(:(abs2(2.0)))
@test x == EConst(4.0)
@test is_scalar_expr(x)

x = extree(:(-z))
@test isa(x, EMapCall)
@test x.fun == EFun(:-)
@test x.args == (EVar(:z),)
@test !is_scalar_expr(x)

x = extree(:(exp(scalar(a))))
@test isa(x, EMapCall)
@test x.fun == EFun(:exp)
@test x.args == (EVar(:a, true),)
@test is_scalar_expr(x)

x = extree(:(foo(x)))
@test isa(x, EGenericCall)
@test x.fun == EFun(:foo)
@test x.args == (EVar(:x),)
@test !is_scalar_expr(x)

x = extree(:(foo(1.25)))
@test isa(x, EGenericCall)
@test x.fun == EFun(:foo)
@test x.args == (EConst(1.25),)
@test !is_scalar_expr(x)

# binary call

x = extree(:(2 + 3))
@test x == EConst(5)
@test is_scalar_expr(x)

x = extree(:(3 * scalar(z)))
@test isa(x, EMapCall)
@test x.fun == EFun(:*)
@test x.args == (EConst(3), EVar(:z, true))
@test is_scalar_expr(x)

x = extree(:(hypot(scalar(z), 2)))
@test isa(x, EMapCall)
@test x.fun == EFun(:hypot)
@test x.args == (EVar(:z, true), EConst(2))
@test is_scalar_expr(x)

x = extree(:(scalar(y) / scalar(z)))
@test isa(x, EMapCall)
@test x.fun == EFun(:/)
@test x.args == (EVar(:y, true), EVar(:z, true))
@test is_scalar_expr(x)

x = extree(:(atan2(p, 3.0)))
@test isa(x, EMapCall)
@test x.fun == EFun(:atan2)
@test x.args == (EVar(:p), EConst(3.0))
@test !is_scalar_expr(x)

x = extree(:(atan2(p, q)))
@test isa(x, EMapCall)
@test x.fun == EFun(:atan2)
@test x.args == (EVar(:p), EVar(:q))
@test !is_scalar_expr(x)

x = extree(:(b * scalar(a)))
@test isa(x, EMapCall)
@test x.fun == EFun(:*)
@test x.args == (EVar(:b), EVar(:a, true))
@test !is_scalar_expr(x)

x = extree(:(2x))
@test isa(x, EMapCall)
@test x.fun == EFun(:*)
@test x.args == (EConst(2), EVar(:x))
@test !is_scalar_expr(x)

x = extree(:(x * y))
@test isa(x, EGenericCall)
@test x.fun == EFun(:*)
@test x.args == (EVar(:x), EVar(:y))
@test !is_scalar_expr(x)

# + call

x = extree(:(x1 + x2 + x3 + x4 + x5))
@test isa(x, EMapCall)
@test x.fun == EFun(:+)
@test x.args == (EVar(:x1), EVar(:x2), EVar(:x3), EVar(:x4), EVar(:x5))
@test !is_scalar_expr(x)

# compound ewise-map

x = extree( :(sin(x + y)) )
@test isa(x, EMapCall)
@test x.fun == EFun(:sin)
@test numargs(x) == 1
a1 = x.args[1]
@test isa(a1, EMapCall)
@test a1.fun == EFun(:+)
@test a1.args == (EVar(:x), EVar(:y))

x = extree( :(x.^2 + y.^3 + z.^4) )
@test isa(x, EMapCall)
@test x.fun == EFun(:+)
@test numargs(x) == 3
@test !is_scalar_expr(x)
a1, a2, a3 = x.args[1], x.args[2], x.args[3]
@test isa(a1, EMapCall) && a1.fun == EFun(:.^) && a1.args == (EVar(:x),EConst(2))
@test isa(a2, EMapCall) && a2.fun == EFun(:.^) && a2.args == (EVar(:y),EConst(3))
@test isa(a3, EMapCall) && a3.fun == EFun(:.^) && a3.args == (EVar(:z),EConst(4))

x = extree( :(exp(x + a) .* atan2(abs(s), abs2(2.0))) )
@test isa(x, EMapCall)
@test x.fun == EFun(:.*)
@test numargs(x) == 2
@test !is_scalar_expr(x)
a1, a2 = x.args[1], x.args[2]
@test isa(a1, EMapCall) && numargs(a1) == 1 && a1.fun == EFun(:exp)
a11 = a1.args[1]
@test isa(a11, EMapCall) && a11.fun == EFun(:+) && a11.args == (EVar(:x), EVar(:a))
@test isa(a2, EMapCall) && numargs(a2) == 2 && a2.fun == EFun(:atan2)
a21, a22 = a2.args[1], a2.args[2]
@test isa(a21, EMapCall) && a21.fun == EFun(:abs) && a21.args == (EVar(:s),)
@test a22 == EConst(4.0)

x = extree( :(2 * scalar(x) + scalar(y)) )
@test isa(x, EMapCall)
@test x.fun == EFun(:+) && numargs(x) == 2
a1, a2 = x.args[1], x.args[2]
@test isa(a1, EMapCall)
@test a1.fun == EFun(:*) && a1.args == (EConst(2), EVar(:x, true))
@test a2 == EVar(:y, true)
@test is_scalar_expr(x)

x = extree( :(2 + 3^2 + 4 * 5) )
@test x == EConst(31)

