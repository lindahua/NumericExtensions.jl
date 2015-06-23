# Scanning

#################################################
#
#   Scanning along a vector
#
#################################################

# inplace scanning

scan!(op::Functor{2}, r::ContiguousArray) = scan!(r, op, r)

cumsum!(r::ContiguousNumericArray) = scan!(Add(), r)
cummax!(r::ContiguousNumericArray) = scan!(MaxFun(), r)
cummin!(r::ContiguousNumericArray) = scan!(MinFun(), r)


macro code_scan(AN)

    h = codegen_helper(AN)
    aparams = h.contiguous_aparams
    args = h.args
    t1 = h.term(1)
    ti = h.term(:i)

    quote
        # generic scanning functions

        global _scan!
        function _scan!(s, r::AbstractArray, op::Functor{2}, $(aparams...))
            i = 1
            @inbounds r[1] = s

            for i = 2 : length(r)
                @inbounds vi = $(ti)
                s = evaluate(op, s, vi)
                @inbounds r[i] = s
            end
        end

        global scan!
        function scan!(r::AbstractArray, op::Functor{2}, $(aparams...))
            n = $(h.inputlen)
            if n > 0
                @inbounds s = $(t1)
                _scan!(s, r, op, $(args...))
            end
            return r
        end

        global scan
        function scan(op::Functor{2}, $(aparams...))
            shp = $(h.inputsize)
            n = prod(shp)
            if n > 0
                @inbounds s = $(t1)
                r = Array(typeof(s), shp)
                _scan!(s, r, op, $(args...))
                return r
            else
                Any[]
            end
        end

        # specific scanning functions
        global cumsum!, cummax!, cummin!
        cumsum!(r::AbstractArray, $(aparams...)) = scan!(r, Add(), $(args...))
        cummax!(r::AbstractArray, $(aparams...)) = scan!(r, MaxFun(), $(args...))
        cummin!(r::AbstractArray, $(aparams...)) = scan!(r, MinFun(), $(args...))

        global cumsum, cummax, cummin
        cumsum($(aparams...)) = scan(Add(), $(args...))
        cummax($(aparams...)) = scan(MaxFun(), $(args...))
        cummin($(aparams...)) = scan(MinFun(), $(args...))
    end
end

@code_scan 0
@code_scan 1
@code_scan 2
@code_scan 3



#################################################
#
#   Scanning along a specific dimension
#
#################################################

macro code_scandim(AN)

    h = codegen_helper(AN)
    aparams = h.contiguous_aparams
    args = h.args
    tidx = h.term(:idx)

    if AN == 0
        offset_args = [:(offset_view(a, ao, m, n))]
    else
        offset_args = [:fun, [:(offset_view($a, ao, m, n)) for a in args[2:end]]...]
    end

    quote
        # generic scanning functions

        global _scan_eachcol!
        function _scan_eachcol!(m::Int, n::Int, r::AbstractArray, op::Functor{2}, $(aparams...))
            o = 0
            for j = 1 : n
                idx = o + 1
                @inbounds s = $(tidx)
                @inbounds r[idx] = s

                for i = 2 : m
                    idx = o + i
                    @inbounds vi = $(tidx)
                    s = evaluate(op, s, vi)
                    @inbounds r[idx] = s
                end
                o += m
            end
        end

        global _scan_eachrow!
        function _scan_eachrow!(m::Int, n::Int, r::AbstractArray, op::Functor{2}, $(aparams...))
            o = 0
            for idx = 1 : m
                @inbounds r[idx] = $(tidx)
            end

            o = m
            for j = 2 : n
                for i = 1 : m
                    idx = o + i
                    @inbounds s = r[idx - m]
                    @inbounds vi = $(tidx)
                    s = evaluate(op, s, vi)
                    @inbounds r[idx] = s
                end
                o += m
            end
        end

        global _scan!
        function _scan!(r::ContiguousArray, op::Functor{2}, $(aparams...), dim::Int)
            if !isempty(r)
                shp = size(r)
                if dim == 1
                    m = shp[1]
                    n = succ_length(shp, 1)
                    _scan_eachcol!(m, n, r, op, $(args...))

                else
                    m = prec_length(shp, dim)
                    n = shp[dim]
                    k = succ_length(shp, dim)

                    if k == 1
                        _scan_eachrow!(m, n, r, op, $(args...))
                    else
                        mn = m * n
                        ro = 0
                        ao = 0
                        for l = 1 : k
                            _scan_eachrow!(m, n, offset_view(r, ro, m, n), op, $(offset_args...))
                            ro += mn
                            ao += mn
                        end
                    end
                end
            end
            return r
        end

        global scan!
        function scan!(r::ContiguousArray, op::Functor{2}, $(aparams...), dim::Int)
            shp = $(h.inputsize)
            size(r) == shp || error("Invalid argument dimensions.")
            _scan!(r, op, $(args...), dim)
        end

        global scan
        function scan(op::Functor{2}, $(aparams...), dim::Int)
            shp = $(h.inputsize)
            tt = $(h.termtype)
            rt = result_type(op, tt, tt)
            _scan!(Array(rt, shp), op, $(args...), dim)
        end


        # specific scanning functions
        global cumsum!, cummax!, cummin!
        cumsum!(r::AbstractArray, $(aparams...), dim::Int) = scan!(r, Add(), $(args...), dim)
        cummax!(r::AbstractArray, $(aparams...), dim::Int) = scan!(r, MaxFun(), $(args...), dim)
        cummin!(r::AbstractArray, $(aparams...), dim::Int) = scan!(r, MinFun(), $(args...), dim)

        global cumsum, cummax, cummin
        cumsum($(aparams...), dim::Int) = scan(Add(), $(args...), dim)
        cummax($(aparams...), dim::Int) = scan(MaxFun(), $(args...), dim)
        cummin($(aparams...), dim::Int) = scan(MinFun(), $(args...), dim)
    end
end

@code_scandim 0
@code_scandim 1
@code_scandim 2
@code_scandim 3

# inplace scanning

scan!(op::Functor{2}, r::ContiguousArray, dim::Int) = scan!(r, op, r, dim)

cumsum!{T<:Number}(r::ContiguousArray{T}, dim::Int) = scan!(Add(), r, dim)
cummax!{T<:Real}(r::ContiguousArray{T}, dim::Int) = scan!(MaxFun(), r, dim)
cummin!{T<:Real}(r::ContiguousArray{T}, dim::Int) = scan!(MinFun(), r, dim)

