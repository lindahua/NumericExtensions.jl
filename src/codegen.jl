# Some facilities for code generation

function generate_argparamlist(nargs::Int)
	if nargs == 1
		[:(a1::NumericArray)]
	else
		[Expr(:(::), symbol("a$i"), :ArrOrNum) for i = 1 : nargs]
	end
end

generate_arglist(nargs::Int) = [symbol("a$i") for i = 1 : nargs]

function functor_evalexpr(f::Symbol, args::Vector{Symbol}, i::Symbol) 
	if length(args) == 1
		a = args[1]
		Expr(:call, :evaluate, f, :($a[$i]))
	else
		es = [Expr(:call, :getvalue, a, i) for a in args]
		Expr(:call, :evaluate, f, es...)
	end
end
