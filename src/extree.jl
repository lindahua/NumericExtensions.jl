# Expression tree and manipulation

#################################################
#
#  Expression types
#
#################################################

abstract AbstractExpr
abstract EwiseExpr <: AbstractExpr

is_scalar_expr(ex::AbstractExpr) = false

##### Generic expressions

# Generic expressions are not further parsed. 
# Instead, they are processed in such way, new variables
# will be created to capture their values.

immutable EGenericExpr <: AbstractExpr
	expr::Expr
end


##### Simple expressions

### Notes
#
#  Some expression tree types (e.g. ERef) requires
#  simple expressions as its arguments. 
#
#  The construction of these expressions will 
#  separate complex expressions and assign them
#  to a new variable.
#
### 
abstract SimpleExpr <: EwiseExpr

typealias NumOrSym Union(Number,Symbol)

immutable EConst{T<:Number} <: SimpleExpr
	value::T
end

EConst{T<:Number}(x::T) = EConst{T}(x)
is_scalar_expr(ex::EConst) = true

immutable EVar <: SimpleExpr
	sym::Symbol
	isscalar::Bool  # inferred as scalar at parsing time

	EVar(s::Symbol) = new(s, false)
	EVar(s::Symbol, tf::Bool) = new(s, tf)	
end
is_scalar_expr(ex::EVar) = ex.isscalar


immutable EEnd end
typealias ERangeArg Union(EConst,EVar,EEnd)

immutable ERange{Args<:(ERangeArg...,)} <: SimpleExpr
	args::Args
end
ERange{Args<:(SimpleExpr...,)}(args::Args) = ERange{Args}(args)

##### Function calls

immutable EFun
	sym::Symbol
end

is_unary_ewise(f::EFun) = (f.sym in UNARY_EWISE_FUNCTIONS)
is_binary_ewise(f::EFun) = (f.sym in BINARY_EWISE_FUNCTIONS)
is_binary_sewise(f::EFun) = (f.sym in BINARY_SEWISE_FUNCTIONS)

is_unary_reduc(f::EFun) = (f.sym in UNARY_REDUC_FUNCTIONS)
is_binary_reduc(f::EFun) = (f.sym in BINARY_REDUC_FUNCTIONS)

type EMap{Args<:(AbstractExpr...,)} <: EwiseExpr
	fun::EFun
	args::Args
	isscalar::Bool
end

EMap{Args<:(AbstractExpr...,)}(f::EFun, args::Args; isscalar=false) = EMap{Args}(f, args, isscalar)
is_scalar_expr(ex::EMap) = ex.isscalar

type EReduc{Args<:(AbstractExpr...,)} <: AbstractExpr
	fun::EFun
	args::Args
end

EReduc{Args<:(AbstractExpr...,)}(f::EFun, args::Args) = EReduc{Args}(f, args)
is_scalar_expr(ex::EReduc) = true

type EGenericCall{Args<:(AbstractExpr...,)} <: AbstractExpr
	fun::EFun
	args::Args
	isscalar::Bool
end

EGenericCall{Args<:(AbstractExpr...,)}(f::EFun, args::Args; isscalar=false) = EGenericCall{Args}(f, args, isscalar)
is_scalar_expr(ex::EGenericCall) = ex.isscalar

# Note: other kind of function call expressions should 
# be captured by EGenericExpr

typealias ECall Union(EMap, EReduc, EGenericCall)
numargs(ex::ECall) = length(ex.args)


##### References

immutable EColon end

typealias ERefArg Union(SimpleExpr, EColon)

type ERef{Args<:(ERefArg...,)} <: EwiseExpr
	arr::EVar    # the host array
	args::Args
end

ERef{Args<:(ERefArg...,)}(h::EVar, args::Args) = ERef{Args}(h, args)

##### Assignment expression

type EAssignment{Lhs<:Union(EVar,ERef),Rhs<:AbstractExpr} <: AbstractExpr
	lhs::Lhs
	rhs::Rhs
end

EAssignment{Lhs<:Union(EVar,ERef),Rhs<:AbstractExpr}(l::Lhs, r::Rhs) = EAssignment{Lhs,Rhs}(l,r)

##### Block Expression

type EBlock <: AbstractExpr
	exprs::Vector{AbstractExpr}

	EBlock() = new(Array(AbstractExpr, 0))
	EBlock(a::Vector{AbstractExpr}) = new(a)
end


#################################################
#
#  Expression tree construction
#
#################################################

typealias ExprContext Vector{EAssignment}
expr_context() = EAssignment[]
make_blockexpr(ctx::ExprContext, ex::AbstractExpr) = EBlock(AbstractExpr[ctx..., ex])

function lift_expr!(ctx::ExprContext, ex::AbstractExpr)
	tmpvar = EVar(gensym("_tmp"), is_scalar_expr(ex))
	push!(ctx, EAssignment(tmpvar, ex))
	return tmpvar
end

scalar(x::Number) = x
scalar(x) = error("Input argument is not a scalar.")

extree(ex::AbstractExpr) = ex
extree(x::Number) = EConst(x)
extree(s::Symbol) = EVar(s)

function extree(x::Expr) 
	ctx = expr_context()
	ex = extree!(ctx, x)
	isempty(ctx) ? ex : make_blockexpr(ctx, ex)
end

extree!(ctx::ExprContext, x::Number) = extree(x)
extree!(ctx::ExprContext, x::Symbol) = extree(x)

function extree!(ctx::ExprContext, x::Expr)
	h::Symbol = x.head
	h == :(:)    ? extree_for_range!(ctx, x) :
	h == :(ref)  ? extree_for_ref!(ctx, x) :
	h == :(call) ? extree_for_call!(ctx, x) :
	EGenericExpr(x)
end


###
#
# Notes:
# - In such cases as f(x) where x is a constant, 
#   then when f is some known function, f(x)
#   will be evaluated upon construction.
#   However, if f is one of those recognizable
#   function, then we cannot assume f(x) as
#   a constant scalar, as f(x) can be of arbitary
#   type when f is unknown.
#
#   The same applies to binary & ternary functions.
#

# is_s2s_map returns true when f yields a scalar when
# applied to n scalar arguments.

function is_s2s_func(f::EFun, n::Int)
	(f.sym == :+ || f.sym == :*) ? true :
	n == 1 ? (is_unary_ewise(f) || is_unary_reduc(f)) :
	n == 2 ? (return is_binary_ewise(f) || is_binary_sewise(f) || is_binary_reduc(f)) : false
end

const end_sym = symbol("end")

# For range expression

erangearg!(ctx::ExprContext, a::Number) = EConst(a)
erangearg!(ctx::ExprContext, a::Symbol) = (a == end_sym || a == :(:)) ? EEnd() : EVar(a)
erangearg!(ctx::ExprContext, a::Expr) = (_a = extree!(ctx, a); isa(_a, ERangeArg) ? _a : lift_expr!(ctx, _a))

function extree_for_range!(ctx::ExprContext, x::Expr)
	nargs = length(x.args)
	2 <= nargs <= 3 || error("extree: a range must have two or three arguments.")
	ERange(tuple([erangearg!(ctx, a) for a in x.args]...))
end

# For reference expression

erefhost!(ctx::ExprContext, a::Number) = error("extree: using number as reference host is not supported.")
erefhost!(ctx::ExprContext, a::Symbol) = EVar(a)
erefhost!(ctx::ExprContext, a::Expr) = lift_expr!(ctx, extree!(ctx, a))

erefarg!(ctx::ExprContext, a::Number) = EConst(a)
erefarg!(ctx::ExprContext, a::Symbol) = a == :(:) ? EColon() : EVar(a)
erefarg!(ctx::ExprContext, a::Expr) = (_a = extree!(ctx, a); isa(_a, ERefArg) ? _a : lift_expr!(ctx, _a))

function extree_for_ref!(ctx::ExprContext, x::Expr)
	nargs = length(x.args) - 1
	nargs >= 1 || error("extree: empty reference is not supported.")
	h = erefhost!(ctx, x.args[1])
	args = tuple([erefarg!(ctx, a) for a in x.args[2:]]...)
	ERef(h, args)
end

# For function call expression

is_map_call(f::EFun, args::AbstractExpr...) = false
is_map_call(f::EFun, a1::AbstractExpr) = is_unary_ewise(f)

function is_map_call(f::EFun, a1::AbstractExpr, a2::AbstractExpr)
	is_binary_ewise(f) ? true :
	is_binary_sewise(f) ? (is_scalar_expr(a1) || is_scalar_expr(a2)) : false
end

is_reduc_call(f::EFun, args::AbstractExpr...) = false
is_reduc_call(f::EFun, a1::AbstractExpr) = is_unary_reduc(f)
is_reduc_call(f::EFun, a1::AbstractExpr, a2::AbstractExpr) = is_binary_reduc(f)


function extree_for_call!(ctx::ExprContext, x::Expr)
	fsym = x.args[1]
	isa(fsym, Symbol) || error("extree: the function name must be a symbol.")
	nargs = length(x.args) - 1

	if fsym == :(scalar)  # the scalar function 		
		# scalar function is used for the special purpose of 
		# tagging an expression as scalar expression

		nargs == 1 || error("extree: scalar function must have one argument.")
		a = x.args[2]

		if isa(a, Number)
			return EConst(a)
		elseif isa(a, Symbol)
			return EVar(a, true)
		else
			return lift_expr!(ctx, extree!(ctx, a))
		end

	else  ## ordinary function
		f = EFun(fsym)
		
		if nargs > 0
			_args = [extree!(ctx, a) for a in x.args[2:]]
			is_s2s = is_s2s_func(f, nargs)

			if is_s2s && all([isa(a, EConst) for a in _args]) # constant propagation			
				return EConst(eval_const(f, _args...))

			else 
				all_scalar_args = all([is_scalar_expr(a) for a in _args])
				if is_s2s && !all_scalar_args
					for i = 1 : nargs
						a = _args[i]
						if is_scalar_expr(a) && !(isa(a, EConst) || isa(a, EVar))
							_args[i] = lift_expr!(ctx, a)
						end
					end
				end
				rs = is_s2s && all_scalar_args
				argtup = tuple(_args...)

				if is_reduc_call(f, argtup...)
					return EReduc(f, argtup)
				elseif fsym == :(+) || is_map_call(f, argtup...)
					return EMap(f, argtup; isscalar=rs)
				else
					return EGenericCall(f, argtup; isscalar=rs)
				end
			end
		else
			return EGenericCall(f, ())
		end		
	end

end

# eval_const 

eval_const(f::EFun, a1::EConst) = eval(Expr(:call, f.sym, a1.value))
eval_const(f::EFun, a1::EConst, a2::EConst) = eval(Expr(:call, f.sym, a1.value, a2.value))
eval_const(f::EFun, a1::EConst, a2::EConst, a3::EConst) = eval(Expr(:call, f.sym, a1.value, a2.value, a3.value))

