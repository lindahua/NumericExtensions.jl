# Reduction along specific dimensions
#
# This is going to be obsolete, the purpose of this remains here is for supporting foldl along dims
#

## auxiliary functions

import ArrayViews: parent, offset
offset_view(a::Number, ::Int, ::Int, ::Int) = a
offset_view(a::ContiguousArray, o::Int, m::Int) = ContiguousView(parent(a), offset(a) + o, (m,))
offset_view(a::ContiguousArray, o::Int, m::Int, n::Int) = ContiguousView(parent(a), offset(a) + o, (m, n))

#################################################
#
#    codegen facilities
#
#################################################

# reduction type dependent codes

type FoldlReduc end

extra_params(::FoldlReduc) = [:(op::Functor{2}), :(s::Number)]
extra_args(::FoldlReduc) = [:op, :s]

update_code(R::FoldlReduc, s, x) = :( @inbounds $s = evaluate(op, $s, $x) )

function emptyreduc_code(R::FoldlReduc, dst::Symbol, T::Symbol, n::Symbol)
    quote
        for i = 1 : $n
            @inbounds ($dst)[i] = s
        end
    end
end

reduce_result(R::FoldlReduc, ty) = ty

# core skeleton

function generate_reducedim_codes(AN::Int, accum::Symbol, reducty)

    # function names
    _accum_eachcol! = symbol("_$(accum)_eachcol!")
    _accum_eachrow! = symbol("_$(accum)_eachrow!")
    _accum = symbol("_$(accum)")
    _accum! = symbol("_$(accum)!")
    accum! = symbol("$(accum)!")    

    # code preparation
    h = codegen_helper(AN)
    aparams = h.contiguous_aparams
    exparams = extra_params(reducty)
    exargs = extra_args(reducty)

    if AN == 0
        offset_args = [:(offset_view(a, ao, m, n))]
    else
        offset_args = [:fun, [:(offset_view($a, ao, m, n)) for a in h.args[2:end]]...]
    end

    quote
        global $(_accum_eachcol!)
        function $(_accum_eachcol!){R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(exparams...), $(aparams...))
            offset = 0
            if m > 0
                for j = 1 : n
                    rj = ($_accum)(offset+1, offset+m, $(exargs...), $(h.args...))
                    @inbounds r[j] = rj
                    offset += m
                end
            else
                $(emptyreduc_code(reducty, :r, :R, :n))
            end 
        end
    
        global $(_accum_eachrow!)
        function $(_accum_eachrow!){R<:Number}(m::Int, n::Int, r::ContiguousArray{R}, $(exparams...), $(aparams...))
            if n > 0
                for i = 1 : m
                    @inbounds vi = $(h.term(:i))
                    @inbounds r[i] = vi
                end

                offset = m
                for j = 2 : n           
                    for i = 1 : m
                        idx = offset + i
                        @inbounds vi = $(h.term(:idx))
                        $(update_code(reducty, :(r[i]), :vi))
                    end
                    offset += m
                end
            else
                $(emptyreduc_code(reducty, :r, :R, :m))
            end
        end

        global $(_accum!)
        function $(_accum!)(r::ContiguousArray, $(exparams...), $(aparams...), dim::Int)
            shp = $(h.inputsize)
            
            if dim == 1
                m = shp[1]
                n = succ_length(shp, 1)
                $(_accum_eachcol!)(m, n, r, $(exargs...), $(h.args...))

            else
                m = prec_length(shp, dim)
                n = shp[dim]
                k = succ_length(shp, dim)

                if k == 1
                    $(_accum_eachrow!)(m, n, r, $(exargs...), $(h.args...))
                else
                    mn = m * n
                    ro = 0
                    ao = 0
                    for l = 1 : k
                        $(_accum_eachrow!)(m, n, offset_view(r, ro, m), $(exargs...), $(offset_args...))
                        ro += m
                        ao += mn
                    end
                end
            end
            return r
        end

        global $(accum!)
        function $(accum!)(r::ContiguousArray, $(exparams...), $(aparams...), dim::Int)
            rshp = Base.reduced_dims($(h.inputsize), dim)
            length(r) == prod(rshp) || error("Invalid argument dimensions.")
            $(_accum!)(r, $(exargs...), $(h.args...), dim)
        end

        global $(accum)
        function $(accum)($(exparams...), $(aparams...), dim::Int)
            rshp = Base.reduced_dims($(h.inputsize), dim)
            $(_accum!)(Array($(h.termtype), rshp), $(exargs...), $(h.args...), dim)
        end 
    end
end

macro code_reducedim(AN, fname, reducty)
    R = eval(reducty)
    esc(generate_reducedim_codes(AN, fname, R()))
end

#################################################
#
#   folding along dims
#
#################################################

macro code_foldldim(AN, fname)
    esc(generate_foldldim_codes(AN, fname))
end

@code_reducedim 0 foldl FoldlReduc
@code_reducedim 1 foldl FoldlReduc
@code_reducedim 2 foldl FoldlReduc
@code_reducedim 3 foldl FoldlReduc
@code_reducedim (-2) foldl_fdiff FoldlReduc

