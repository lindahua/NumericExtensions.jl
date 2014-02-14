# facilities for code generation


type ArgInfo{AN} end

arginfo(n::Int) = ArgInfo{n}()

immutable CodegenHelper
    aparams::Vector{Expr}
    args::Vector{Symbol}
    offset_args::Vector
    term::Function
    inputsize::Expr
    inputlen::Expr
    termtype::Expr
end

function codegen_helper(::ArgInfo{0})
    aparams = [:(a::ContiguousNumericArray)]
    args = [:a]
    offset_args = [:(offset_view(a, ao, m, n))]
    term = idx->:(a[$idx])
    inputsize = :(size(a))
    inputlen = :(length(a))
    termtype = :(eltype(a))
    return CodegenHelper(aparams, args, offset_args, term, inputsize, inputlen, termtype)
end

function codegen_helper(::ArgInfo{-2})
    aparams = [:(fun::Functor{1}), :(a::ContiguousArrOrNum), :(b::ContiguousArrOrNum)]
    args = [:fun, :a, :b]
    offset_args = [:fun, :(offset_view(a, ao, m, n)), :(offset_view(b, ao, m, n))]
    term = idx->:(evaluate(fun, getvalue(a, $idx) - getvalue(b, $idx)))
    inputsize = :(mapshape(a, b))
    inputlen = :(maplength(a, b))
    termtype = :(result_type(fun, promote_type(eltype(a), eltype(b))))
    return CodegenHelper(aparams, args, offset_args, term, inputsize, inputlen, termtype)
end

function codegen_helper{N}(::ArgInfo{N})
    @assert N >= 1
    aargs = [symbol('a' + (i-1)) for i = 1 : N]
    aparams = [:(fun::Functor{$N}), [:($a::ContiguousArrOrNum) for a in aargs]...]
    args = [:fun, aargs...]
    offset_args = [:fun, [:(offset_view($a, ao, m, n)) for a in aargs]...]
    term = idx->Expr(:call, :evaluate, :fun, [:(getvalue($a, $idx)) for a in aargs]...)
    inputsize = Expr(:call, :mapshape, aargs...)
    inputlen = Expr(:call, :maplength, aargs...)
    termtype = Expr(:call, :result_type, :fun, [:(eltype($a)) for a in aargs]...)
    return CodegenHelper(aparams, args, offset_args, term, inputsize, inputlen, termtype)
end

codegen_helper(AN::Int) = codegen_helper(arginfo(AN))

