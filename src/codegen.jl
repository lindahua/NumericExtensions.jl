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


immutable CodegenHelperEx
    imparams1d::Vector{Expr}
    imparams2d::Vector{Expr}
    imargs1d::Vector
    imargs2d::Vector
    eviewargs::Vector

    getoffsets::Expr
    getstrides1::Expr
    getstrides2::Expr
    contcol::Expr
    nextcol::Expr
    pkerargs::Vector
    pkerargs1::Vector
    kerargs::Vector{Symbol}
    kerargs1::Vector{Symbol}
end

function codegen_helper_ex(AN::Int)
    if AN == 0
        imparams1d = [:(a::ContiguousArray), :(ia::Int), :(sa1::Int)]
        imparams2d = [:(a::ContiguousArray), :(ia::Int), :(sa1::Int), :(sa2::Int)]
        imargs1d = [:(parent(a)), :ia, :sa1]
        imargs2d = [:(parent(a)), :ia, :sa1, :sa2]
        eviewargs = [:(ellipview(a, i))]
        getoffsets = :(ia = offset(a) + 1)
        getstrides1 = :(sa1 = stride(a, 1)::Int)
        getstrides2 = :(sa1 = stride(a, 1)::Int; sa2 = stride(a, 2)::Int)
        contcol = :(sa1 == 1)
        nextcol = :(ia += sa2)
        pkargs = [:(parent(a)), :ia]
        pkargs1 = [:(parent(a)), :ia, :sa1]
        kargs = [:a, :ia]
        kargs1 = [:a, :ia, :sa1]
    elseif AN == 1
        imparams1d = [:(fun::Functor{1}), :(a::ContiguousArray), :(ia::Int), :(sa1::Int)]
        imparams2d = [:(fun::Functor{1}), :(a::ContiguousArray), :(ia::Int), :(sa1::Int), :(sa2::Int)]
        imargs1d = [:fun, :(parent(a)), :ia, :sa1]
        imargs2d = [:fun, :(parent(a)), :ia, :sa1, :sa2]
        eviewargs = [:fun, :(ellipview(a, i))]
        getoffsets = :(ia = offset(a) + 1)
        getstrides1 = :(sa1 = stride(a, 1)::Int)
        getstrides2 = :(sa1 = stride(a, 1)::Int; sa2 = stride(a, 2)::Int)
        contcol = :(sa1 == 1)
        nextcol = :(ia += sa2)
        pkargs = [:fun, :(parent(a)), :ia]
        pkargs1 = [:fun, :(parent(a)), :ia, :sa1]
        kargs = [:fun, :a, :ia]
        kargs1 = [:fun, :a, :ia, :sa1]
    elseif AN == 2 || AN == -2
        FN = AN == 2 ? 2 : 1
        imparams1d = [:(fun::Functor{$FN}), :(a::ContiguousArrOrNum), :(ia::Int), :(sa1::Int), 
                                            :(b::ContiguousArrOrNum), :(ib::Int), :(sb1::Int)]
        imparams2d = [:(fun::Functor{$FN}), :(a::ContiguousArrOrNum), :(ia::Int), :(sa1::Int), :(sa2::Int), 
                                            :(b::ContiguousArrOrNum), :(ib::Int), :(sb1::Int), :(sb2::Int)]
        imargs1d = [:fun, :(parent(a)), :ia, :sa1, 
                          :(parent(b)), :ib, :sb1]
        imargs2d = [:fun, :(parent(a)), :ia, :sa1, :sa2, 
                          :(parent(b)), :ib, :sb1, :sb2]
        eviewargs = [:fun, :(ellipview(a, i)), :(ellipview(b, i))]
        getoffsets = :(ia = offset(a) + 1; 
                       ib = offset(b) + 1)
        getstrides1 = :(sa1 = stride(a, 1)::Int; 
                        sb1 = stride(b, 1)::Int)
        getstrides2 = :(sa1 = stride(a, 1)::Int; sa2 = stride(a, 2)::Int; 
                        sb1 = stride(b, 1)::Int; sb2 = stride(b, 2)::Int)
        contcol = :(sa1 == 1 && sb1 == 1)
        nextcol = :(ia += sa2; ib += sb2)
        pkargs = [:fun, :(parent(a)), :ia, :(parent(b)), :ib]
        pkargs1 = [:fun, :(parent(a)), :ia, :sa1, :(parent(b)), :ib, :sb1]
        kargs = [:fun, :a, :ia, :b, :ib]
        kargs1 = [:fun, :a, :ia, :sa1, :b, :ib, :sb1]
    elseif AN == 3
        imparams1d = [:(fun::Functor{3}), :(a::ContiguousArrOrNum), :(ia::Int), :(sa1::Int), 
                                          :(b::ContiguousArrOrNum), :(ib::Int), :(sb1::Int), 
                                          :(c::ContiguousArrOrNum), :(ic::Int), :(sc1::Int)]
        imparams2d = [:(fun::Functor{3}), :(a::ContiguousArrOrNum), :(ia::Int), :(sa1::Int), :(sa2::Int), 
                                          :(b::ContiguousArrOrNum), :(ib::Int), :(sb1::Int), :(sb2::Int), 
                                          :(c::ContiguousArrOrNum), :(ic::Int), :(sc1::Int), :(sc2::Int)]
        imargs1d = [:fun, :(parent(a)), :ia, :sa1, 
                          :(parent(b)), :ib, :sb1, 
                          :(parent(c)), :ic, :sc1]
        imargs2d = [:fun, :(parent(a)), :ia, :sa1, :sa2, 
                          :(parent(b)), :ib, :sb1, :sb2, 
                          :(parent(c)), :ic, :sc1, :sc2]
        eviewargs = [:fun, :(ellipview(a, i)), :(ellipview(b, i)), :(ellipview(c, i))]
        getoffsets = :(ia = offset(a) + 1; 
                       ib = offset(b) + 1; 
                       ic = offset(c) + 1)
        getstrides1 = :(sa1 = stride(a, 1)::Int; 
                        sb1 = stride(b, 1)::Int;
                        sc1 = stride(c, 1)::Int)
        getstrides2 = :(sa1 = stride(a, 1)::Int; sa2 = stride(a, 2)::Int; 
                        sb1 = stride(b, 1)::Int; sb2 = stride(b, 2)::Int; 
                        sc1 = stride(c, 1)::Int; sc2 = stride(c, 2)::Int)
        contcol = :(sa1 == 1 && sb1 == 1 && sc1 == 1)
        nextcol = :(ia += sa2; ib += sb2; ic += sc2)
        pkargs = [:fun, :(parent(a)), :ia, :(parent(b)), :ib, :(parent(c)), :ic]
        pkargs1 = [:fun, :(parent(a)), :ia, :sa1, :(parent(b)), :ib, :sb1, :(parent(c)), :ic, :sc1]
        kargs = [:fun, :a, :ia, :b, :ib, :c, :ic]
        kargs1 = [:fun, :a, :ia, :sa1, :b, :ib, :sb1, :c, :ic, :sc1]
    else
        error("AN = $(AN) is unsupported.")
    end

    return CodegenHelperEx(imparams1d, 
                           imparams2d, 
                           imargs1d, 
                           imargs2d,
                           eviewargs, 
                           getoffsets, 
                           getstrides1, 
                           getstrides2, 
                           contcol, 
                           nextcol, 
                           pkargs, 
                           pkargs1,
                           kargs, 
                           kargs1)
end

