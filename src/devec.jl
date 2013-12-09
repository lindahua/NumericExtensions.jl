# Generation of devectorized codes

function devectorize_ewise(ex::EConst)
	return (nothing, i::Symbol->ex.value)
end

function devectorize_ewise(ex::EVar)
	if ex.isscalar
		return (nothing, i::Symbol->ex.sym)
	else
		return (nothing, i::Symbol->Expr(:call, :getvalue, ex.sym, i))
	end
end

function devectorize_ewise(ex::EMap)
	if ex.isscalar
		v = gensym("r")
		pre = Expr(:=, v, Expr(:call, :scalar, to_expr(ex)))
		return (pre, i::Symbol->v)
	else
		argpres = Any[]
		argkers = Any[]
		sizehint(argpres, length(ex.args))
		sizehint(argkers, length(ex.args))

		for a in ex.args
			(apre, aker) = devectorize(a)
			if !(apre == nothing)
				push!(argpres, apre)
			end
			push!(argkers, aker)
		end

		np = length(argpres)
		pre = np == 0 ? nothing : 
			np == 1 ? argpres[1] : Expr(:block, argpres...)

		ker = i::Symbol->Expr(:call, ex.fun.sym, [f(i) for f in argkers]...)

		return (pre, ker)
	end
end

function devectorize_ewise(ex::EMap)
	
end
