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
import NumericExtensions.EMap
import NumericExtensions.EReduc
import NumericExtensions.EGenericCall
import NumericExtensions.EColon
import NumericExtensions.ERef
import NumericExtensions.EEnd
import NumericExtensions.EAssignment
import NumericExtensions.EBlock

#### Type System

@assert EwiseExpr <: AbstractExpr
@assert EGenericExpr <: AbstractExpr
@assert SimpleExpr <: EwiseExpr
@assert EConst <: SimpleExpr
@assert EVar   <: SimpleExpr
@assert ERange <: SimpleExpr

@assert ECall <: AbstractExpr
@assert EMap <: ECall
@assert EReduc <: ECall
@assert EGenericCall <: ECall

@assert EMap <: EwiseExpr
@assert !(EReduc <: EwiseExpr)
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

x = extree(:(scalar(a[i, j])))
@test isa(x, ERef)
@test x.arr == extree(:a)
@test x.args == (EVar(:i), EVar(:j))
@test is_scalar_expr(x)


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
@test isa(x, EMap)
@test x.fun == EFun(:-)
@test x.args == (EVar(:z),)
@test !is_scalar_expr(x)

x = extree(:(exp(scalar(a))))
@test isa(x, EMap)
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
@test isa(x, EMap)
@test x.fun == EFun(:*)
@test x.args == (EConst(3), EVar(:z, true))
@test is_scalar_expr(x)

x = extree(:(hypot(scalar(z), 2)))
@test isa(x, EMap)
@test x.fun == EFun(:hypot)
@test x.args == (EVar(:z, true), EConst(2))
@test is_scalar_expr(x)

x = extree(:(scalar(y) / scalar(z)))
@test isa(x, EMap)
@test x.fun == EFun(:/)
@test x.args == (EVar(:y, true), EVar(:z, true))
@test is_scalar_expr(x)

x = extree(:(atan2(p, 3.0)))
@test isa(x, EMap)
@test x.fun == EFun(:atan2)
@test x.args == (EVar(:p), EConst(3.0))
@test !is_scalar_expr(x)

x = extree(:(atan2(p, q)))
@test isa(x, EMap)
@test x.fun == EFun(:atan2)
@test x.args == (EVar(:p), EVar(:q))
@test !is_scalar_expr(x)

x = extree(:(b * scalar(a)))
@test isa(x, EMap)
@test x.fun == EFun(:*)
@test x.args == (EVar(:b), EVar(:a, true))
@test !is_scalar_expr(x)

x = extree(:(2x))
@test isa(x, EMap)
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
@test isa(x, EMap)
@test x.fun == EFun(:+)
@test x.args == (EVar(:x1), EVar(:x2), EVar(:x3), EVar(:x4), EVar(:x5))
@test !is_scalar_expr(x)

# compound ewise-map

x = extree( :(sin(x + y)) )
@test x == EMap(EFun(:sin), (EMap(EFun(:+), (EVar(:x), EVar(:y))),))
@test !is_scalar_expr(x)

x = extree( :(x.^2 + y.^3 + z.^4) )
@test x == EMap(EFun(:+), (
	EMap(EFun(:.^), (EVar(:x), EConst(2))),
	EMap(EFun(:.^), (EVar(:y), EConst(3))),
	EMap(EFun(:.^), (EVar(:z), EConst(4)))
	))
@test !is_scalar_expr(x)

x = extree( :(exp(x + a) .* atan2(abs(s), abs2(2.0))) )
@test x == EMap(EFun(:.*), (
	EMap(EFun(:exp), (EMap(EFun(:+), (EVar(:x), EVar(:a))),)), 
	EMap(EFun(:atan2), (EMap(EFun(:abs), (EVar(:s),)), EConst(4.0)))
	))
@test !is_scalar_expr(x)

x = extree( :(2 * scalar(x) + scalar(y)) )
@test x == EMap(EFun(:+), 
	(EMap(EFun(:*), (EConst(2), EVar(:x, true)); isscalar=true), EVar(:y, true)); isscalar=true)
@test is_scalar_expr(x)

x = extree( :(2 + 3^2 + 4 * 5) )
@test x == EConst(31)

x = extree( :(scalar(x) + y) )
@test x == EMap(EFun(:+), (EVar(:x, true), EVar(:y)))
@test !is_scalar_expr(x)


# reduction call

x = extree( :(sum(x)) )
@test x == EReduc(EFun(:sum), (EVar(:x),))
@test is_scalar_expr(x)

x = extree( :(meansqdiff(x, 2.0)) )
@test x == EReduc(EFun(:meansqdiff), (EVar(:x), EConst(2.0)))
@test is_scalar_expr(x)

x = extree( :(sum(2.5)) )
@test x == EConst(2.5)

x = extree( :(sum(scalar(a))) )
@test x == EReduc(EFun(:sum), (EVar(:a, true),))
@test is_scalar_expr(x)

x = extree( :(maxabsdiff(scalar(x), scalar(y))) )
@test x == EReduc(EFun(:maxabsdiff), (EVar(:x, true), EVar(:y, true)))
@test is_scalar_expr(x)

# composition of ewise map, reduction, and reference

x = extree( :(log(x[:,i])) )
@test x == EMap(EFun(:log), (ERef(EVar(:x), (EColon(), EVar(:i))),))
@test !is_scalar_expr(x)

x = extree( :(b[:,1] + a[:]) )
@test x == EMap(EFun(:+), 
	(ERef(EVar(:b), (EColon(), EConst(1))), ERef(EVar(:a), (EColon(),))))
@test !is_scalar_expr(x)

x = extree( :(abs2(scalar(a[i, j]))) )
@test x == EMap(EFun(:abs2), 
	(ERef(EVar(:a), (EVar(:i), EVar(:j)); isscalar=true),); isscalar=true)
@test is_scalar_expr(x)

x = extree( :(sum((x - y).^2)) )
@test x == EReduc(EFun(:sum), 
	(EMap(EFun(:.^), (EMap(EFun(:-), (EVar(:x), EVar(:y))), EConst(2))),))
@test is_scalar_expr(x)

x = extree( :(sum(x) + maximum(y)) )
@test x == EMap(EFun(:+), 
	(EReduc(EFun(:sum), (EVar(:x),)), EReduc(EFun(:maximum), (EVar(:y),))); 
	isscalar=true)
@test is_scalar_expr(x)


# more complex expressions that require part lifting

#
x = extree( :(g + sum(x) + h) )
@test isa(x, EBlock) && numargs(x) == 2
e1, e2 = x.exprs[1], x.exprs[2]
@test isa(e1, EAssignment)
@test isa(e1.lhs, EVar) && e1.lhs.isscalar
e1r = e1.rhs
@test isa(e1r, EReduc)
@test e1r.fun == EFun(:sum) && e1r.args == (EVar(:x),)
@test isa(e2, EMap)
@test e2.fun == EFun(:+)
@test e2.args == (EVar(:g), e1.lhs, EVar(:h))
@test !is_scalar_expr(x)

#
x = extree( :(a * b + c) )
@test isa(x, EBlock) && numargs(x) == 2
e1, e2 = x.exprs[1], x.exprs[2]
@test isa(e1, EAssignment)
@test isa(e1.lhs, EVar) && !e1.lhs.isscalar
e1r = e1.rhs
@test isa(e1r, EGenericCall) 
@test e1r.fun == EFun(:*) && e1r.args == (EVar(:a), EVar(:b))
@test isa(e2, EMap)
@test e2.fun == EFun(:+)
@test e2.args == (e1.lhs, EVar(:c))
@test !is_scalar_expr(x)

# 
x = extree( :(sum(x) * (a * b) + maximum(y) + scalar(e + f)) )
@test isa(x, EBlock) && numargs(x) == 5

e1 = x.exprs[1]
@test isa(e1, EAssignment)
@test isa(e1.lhs, EVar) && e1.lhs.isscalar
e1r = e1.rhs
@test isa(e1r, EReduc) && e1r.fun == EFun(:sum) && e1r.args == (EVar(:x),)

e2 = x.exprs[2]
@test isa(e2, EAssignment)
@test isa(e2.lhs, EVar) && !e2.lhs.isscalar
e2r = e2.rhs
@test isa(e2r, EGenericCall) && e2r.fun == EFun(:*) && e2r.args == (EVar(:a), EVar(:b))

e3 = x.exprs[3]
@test isa(e3, EAssignment)
@test isa(e3.lhs, EVar) && e3.lhs.isscalar
e3r = e3.rhs
@test isa(e3r, EReduc) && e3r.fun == EFun(:maximum) && e3r.args == (EVar(:y),)

e4 = x.exprs[4]
@test isa(e4, EAssignment)
@test isa(e4.lhs, EVar) && e4.lhs.isscalar
e4r = e4.rhs
@test isa(e4r, EMap) && e4r.fun == EFun(:+) && e4r.args == (EVar(:e), EVar(:f))

e5 = x.exprs[5]
@test isa(e5, EMap)
@test e5.fun == EFun(:+) && numargs(e5) == 3
e51 = e5.args[1]
@test isa(e51, EMap) && e51.fun == EFun(:*) && e51.args == (e1.lhs, e2.lhs)
@test e5.args[2] == e3.lhs
@test e5.args[3] == e4.lhs


