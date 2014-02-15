# facilities for code generation


type ArgInfo{AN} end

arginfo(n::Int) = ArgInfo{n}()

immutable CodegenHelper
    args::Vector{Symbol}
    contiguous_aparams::Vector{Expr}
    dense_aparams::Vector{Expr}
    
    term::Function
    termtype::Expr
    inputlen::Expr
    inputsize::Expr
end


function codegen_helper(AN::Int) 
    N = abs(AN)

    if AN == 0
        args = [:a]
        contiguous_aparams = [:(a::ContiguousNumericArray)]
        dense_aparams = [:(a::NumericArray)]
        term = idx->:(a[$idx])
        termtype = :(eltype(a))
    elseif AN == 1
        args = [:fun, :a]
        contiguous_aparams = [:(fun::Functor{1}), :(a::ContiguousNumericArray)]
        dense_aparams = [:(fun::Functor{1}), :(a::NumericArray)]
        term = idx->:(evaluate(fun, a[$idx]))
        termtype = :(result_type(fun, eltype(a)))
    else
        FN = AN
        if AN == -2
            FN = 1
        end
        aargs = [symbol('a' + (i-1)) for i = 1:N]
        args = [:fun, aargs...]
        contiguous_aparams = [:(fun::Functor{$FN}), [:($a::ContiguousArrOrNum) for a in aargs]...]
        dense_aparams = [:(fun::Functor{$FN}), [:($a::DenseArrOrNum) for a in aargs]...]

        if AN > 1
            term = idx->Expr(:call, :evaluate, :fun, [:(getvalue($a, $idx)) for a in aargs]...)
            termtype = Expr(:call, :result_type, :fun, [:(eltype($a)) for a in aargs]...)
        elseif AN == -2
            term = idx->:(evaluate(fun, getvalue(a, $idx) - getvalue(b, $idx)))
            termtype = :(result_type(fun, promote_type(eltype(a), eltype(b))))
        end
    end

    if N <= 1
        inputlen = :(length(a))
        inputsize = :(size(a))
    else
        inputlen = Expr(:call, :maplength, aargs...)
        inputsize = Expr(:call, :mapshape, aargs...)
    end

    CodegenHelper(args, 
                  contiguous_aparams, 
                  dense_aparams, 
                  term, 
                  termtype,
                  inputlen, 
                  inputsize)
end

