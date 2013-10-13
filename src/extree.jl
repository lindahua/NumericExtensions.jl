# Expression tree and manipulation

abstract AbstractExpr
abstract EwiseExpr

##### Generic expressions

# Generic expressions are not further parsed. 
# Instead, they are processed in such way, new variables
# will be created to capture their values.

immutable GenericExpr <: AbstractExpr
	expr::Expr
end


##### Simple expressions

### Notes
#
#  Some expression tree types (e.g. ERange) requires
#  simple expressions as its arguments. 
#
#  The construction of these expressions will 
#  separate complex expressions and assign them
#  to a new variable.
#
### 
abstract SimpleExpr <: EwiseExpr

immutable ELiteral{T<:Number} <: SimpleExpr
	value::T
end

immutable EVar{T<:Number} <: SimpleExpr
	sym::Symbol
end

immutable ERange <: SimpleExpr
	args::Vector{SimpleExpr}
end

##### Function calls

immutable EFun
	sym::Symbol
end

is_unary_ewise(f::EFun) = (f.sym in UNARY_EWISE_FUNCTIONS)
is_binary_ewise(f::EFun) = (f.sym in BINARY_EWISE_FUNCTIONS)
is_binary_sewise(f::EFun) = (f.sym in BINARY_SEWISE_FUNCTIONS)

type EWiseCall <: EwiseExpr
	fun::EFun
	args::Vector{AbstractExpr}
end

type ReducCall <: AbstractExpr
	fun::EFun
	args::Vector{AbstractExpr}
end

# Note: other kind of function call expressions should 
# be captured by GenericExpr

typealias ECall Union(EWiseCall, ReducCall)

numargs(ex::ECall) = length(ex.args)
isunary(ex::ECall) = (numargs(ex) == 1)
isbinary(ex::ECall) = (numargs(ex) == 2)
isternary(ex::ECall) = (numargs(ex) == 3)

##### References

type EColon end

typealias ERefArg Union(SimpleExpr, EColon)

type ERef <: AbstractExpr
	host::AbstractExpr    # host array expression
	args::Vector{ERefArg}
end
isewise(ex::ERef) = true


