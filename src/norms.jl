# Normal evaluation and normalization

#################################################
#
#   Vector norms
#
#################################################

function vnorm(x::NumericArray, p::Real)
    p > 0 || throw(ArgumentError("p must be positive."))
    p == 1 ? sumabs(x) :
    p == 2 ? sqrt(sumsq(x)) :   
    isinf(p) ? maxabs(x) :
    sum(FixAbsPow(p), x) .^ inv(p)
end

vnorm(x::NumericArray) = vnorm(x, 2)

function vnorm!(dst::NumericArray, x::NumericArray, p::Real, dims::DimSpec)
    fill!(dst, zero(eltype(dst)))
    p > 0 || throw(ArgumentError("p must be positive."))
    p == 1 ? sumabs!(dst, x, dims) :
    p == 2 ? map1!(SqrtFun(), sumsq!(dst, x, dims)) :   
    isinf(p) ? maxabs!(dst, x, dims) :
    map1!(FixAbsPow(inv(p)), sum!(dst, FixAbsPow(p), x, dims))
end

function vnorm(x::NumericArray, p::Real, dims::DimSpec) 
    tt = promote_type(fptype(eltype(x)), fptype(typeof(p)))
    r = Array(tt, Base.reduced_dims(size(x), dims))
    vnorm!(r, x, p, dims)
end

# vnormdiff

function vnormdiff(x::DenseArrOrNum, y::DenseArrOrNum, p::Real)
    p > 0 || throw(ArgumentError("p must be positive."))
    p == 1 ? sumabsdiff(x, y) :
    p == 2 ? sqrt(sumsqdiff(x, y)) :    
    isinf(p) ? maxabsdiff(x, y) :
    sumfdiff(FixAbsPow(p), x, y) .^ inv(p)
end

vnormdiff(x::DenseArrOrNum, y::DenseArrOrNum) = vnormdiff(x, y, 2)

function vnormdiff!(dst::NumericArray, x::DenseArrOrNum, y::DenseArrOrNum, p::Real, dims::DimSpec)
    fill!(dst, zero(eltype(dst)))
    p > 0 || throw(ArgumentError("p must be positive."))
    p == 1 ? sumabsdiff!(dst, x, y, dims) :
    p == 2 ? map1!(SqrtFun(), sumsqdiff!(dst, x, y, dims)) :    
    isinf(p) ? maxabsdiff!(dst, x, y, dims) :
    map1!(FixAbsPow(inv(p)), sumfdiff!(dst, FixAbsPow(p), x, y, dims))
end

function vnormdiff(x::DenseArrOrNum, y::DenseArrOrNum, p::Real, dims::DimSpec) 
    tt = promote_type(fptype(promote_type(eltype(x), eltype(y))), fptype(typeof(p)))
    r = Array(tt, Base.reduced_dims(size(x), dims))
    vnormdiff!(r, x, y, p, dims)
end


#################################################
#
#   Normalization
#
#################################################

# normalize an array as a whole

function normalize!(dst::ContiguousRealArray, x::ContiguousRealArray, p::Real)
    return map!(Multiply(), dst, x, inv(vnorm(x, p)))
end
normalize!(x::ContiguousRealArray, p::Real) = normalize!(x, x, p)
normalize(x::ContiguousRealArray, p::Real) = x * inv(vnorm(x, p))

# normalize along specific dimension

function normalize!(dst::NumericArray, x::NumericArray, p::Real, dims::DimSpec)
    p > 0 || throw(ArgumentError("p must be positive."))
    length(dst) == length(x) || throw(ArgumentError("Inconsistent argument dimensions!"))

    if length(dims) == 1 && dims[1] == 1
        n = succ_length(size(x), 1)
        if p == 1
            for j = 1:n
                xj = view(x,:,j)
                map!(Multiply(), view(dst,:,j), xj, inv(sumabs(xj)))
            end
        elseif p == 2
            for j = 1:n
                xj = view(x,:,j)
                map!(Multiply(), view(dst,:,j), xj, inv(sqrt(sumsq(xj))))
            end
        elseif isinf(p)
            for j = 1:n
                xj = view(x,:,j)
                map!(Multiply(), view(dst,:,j), xj, inv(maxabs(xj)))
            end
        else
            for j = 1:n
                xj = view(x,:,j)
                u = sum(FixAbsPow(p), xj) .^ inv(p)
                map!(Multiply(), view(dst,:,j), xj, inv(u))
            end
        end

    elseif length(dims) == 2 && dims[1] == 1 && dims[2] == 2
        n = succ_length(size(x), 2)
        if p == 1
            for j = 1:n
                xj = view(x,:,:,j)
                map!(Multiply(), view(dst,:,:,j), xj, inv(sumabs(xj)))
            end
        elseif p == 2
            for j = 1:n
                xj = view(x,:,:,j)
                map!(Multiply(), view(dst,:,:,j), xj, inv(sqrt(sumsq(xj))))
            end
        elseif isinf(p)
            for j = 1:n
                xj = view(x,:,:,j)
                map!(Multiply(), view(dst,:,:,j), xj, inv(maxabs(xj)))
            end
        else
            for j = 1:n
                xj = view(x,:,:,j)
                u = sum(FixAbsPow(p), xj) .^ inv(p)
                map!(Multiply(), view(dst,:,:,j), xj, inv(u))
            end
        end

    else
        broadcast!(.*, dst, x, rcp!(vnorm(x, p, dims)))
    end
    dst
end

normalize!(x::ContiguousRealArray, p::Real, dims::DimSpec) = normalize!(x, x, p, dims)
normalize(x::ContiguousRealArray, p::Real, dims::DimSpec) = normalize!(similar(x), x, p, dims)

