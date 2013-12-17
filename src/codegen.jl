# Some facilities for code generation

function generate_argparamlist(nargs::Int)
	if nargs == 1
		[:(a1::NumericArray)]
	else
		[Expr(:(::), symbol("a$i"), :ArrOrNum) for i = 1 : nargs]
	end
end

generate_arglist(nargs::Int) = [symbol("a$i") for i = 1 : nargs]

function functor_evalexpr(f::Symbol, args::Vector{Symbol}, i::Symbol; usediff::Bool=false) 
	if usediff
		@assert length(args) == 2
		a1, a2 = args[1], args[2]
		Expr(:call, :evaluate, f, :(getvalue($a1, $i) - getvalue($a2, $i)) )
	else
		if length(args) == 1
			a = args[1]
			Expr(:call, :evaluate, f, :($a[$i]))
		else
			es = [Expr(:call, :getvalue, a, i) for a in args]
			Expr(:call, :evaluate, f, es...)
		end
	end
end

function prepare_arguments(N::Int)
	if N > 0
		aparams = generate_argparamlist(N)
		args = generate_arglist(N)
		(aparams, args, false)
	else
		@assert N == -2
		aparams = generate_argparamlist(2)
		args = generate_arglist(2)
		(aparams, args, true)
	end	
end


