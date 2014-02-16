# vector kernels for mapping

function vecmap!(n::Int, dst::Array, idst::Int, fun::Functor{1}, a::Array, ia::Int)
    idst_end = idst + n
    @inbounds while idst < idst_end
        dst[idst] = evaluate(fun, a[ia])
        idst += 1
        ia += 1
    end
end

function vecmap!(n::Int, dst::Array, idst::Int, sdst::Int, fun::Functor{1}, a::Array, ia::Int, sa::Int)
    idst_end = idst + sdst * n
    @inbounds while idst < idst_end
        dst[idst] = evaluate(fun, a[ia])
        idst += sdst
        ia += sa
    end
end

function vecmap!(n::Int, dst::Array, idst::Int, fun::Functor{2}, a::ArrayOrNum, ia::Int, b::ArrayOrNum, ib::Int)
    idst_end = idst + n
    @inbounds while idst < idst_end
        dst[idst] = evaluate(fun, getvalue(a, ia), getvalue(b, ib))
        idst += 1
        ia += 1
        ib += 1
    end
end

function vecmap!(n::Int, dst::Array, idst::Int, sdst::Int, fun::Functor{2}, a::ArrayOrNum, ia::Int, sa::Int, 
                                                                            b::ArrayOrNum, ib::Int, sb::Int)
    idst_end = idst + sdst * n
    @inbounds while idst < idst_end
        dst[idst] = evaluate(fun, getvalue(a, ia), getvalue(b, ib))
        idst += sdst
        ia += sa
        ib += sb
    end
end

function vecmap!(n::Int, dst::Array, idst::Int, fun::Functor{3}, a::ArrayOrNum, ia::Int, 
                                                                 b::ArrayOrNum, ib::Int, 
                                                                 c::ArrayOrNum, ic::Int)
    idst_end = idst + n
    @inbounds while idst < idst_end
        dst[idst] = evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic))
        idst += 1
        ia += 1
        ib += 1
        ic += 1
    end
end

function vecmap!(n::Int, dst::Array, idst::Int, sdst::Int, fun::Functor{3}, a::ArrayOrNum, ia::Int, sa::Int, 
                                                                            b::ArrayOrNum, ib::Int, sb::Int, 
                                                                            c::ArrayOrNum, ic::Int, sc::Int)
    idst_end = idst + sdst * n
    @inbounds while idst < idst_end
        dst[idst] = evaluate(fun, getvalue(a, ia), getvalue(b, ib), getvalue(c, ic))
        idst += sdst
        ia += sa
        ib += sb
        ic += sc
    end
end

function vecmapdiff!(n::Int, dst::Array, idst::Int, fun::Functor{1}, a::ArrayOrNum, ia::Int, b::ArrayOrNum, ib::Int)
    idst_end = idst + n
    @inbounds while idst < idst_end
        dst[idst] = evaluate(fun, getvalue(a, ia) - getvalue(b, ib))
        idst += 1
        ia += 1
        ib += 1
    end
end

function vecmapdiff!(n::Int, dst::Array, idst::Int, sdst::Int, fun::Functor{1}, a::ArrayOrNum, ia::Int, sa::Int, 
                                                                                b::ArrayOrNum, ib::Int, sb::Int)
    idst_end = idst + sdst * n
    @inbounds while idst < idst_end
        dst[idst] = evaluate(fun, getvalue(a, ia) - getvalue(b, ib))
        idst += sdst
        ia += sa
        ib += sb
    end
end

