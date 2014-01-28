# Normal evaluation and normalization

#################################################
#
# 	Vector norms
#
#################################################

function vnorm(x::ContiguousRealArray, p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? sumabs(x) :
	p == 2 ? sqrt(sumsq(x)) :	
	isinf(p) ? maxabs(x) :
	sum(FixAbsPow(p), x) .^ inv(p)
end

vnorm(x::ContiguousRealArray) = vnorm(x, 2)

function vnorm!(dst::ContiguousRealArray, x::ContiguousRealArray, p::Real, dims::DimSpec)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? sumabs!(dst, x, dims) :
	p == 2 ? map1!(SqrtFun(), sumsq!(dst, x, dims)) :	
	isinf(p) ? maxabs!(dst, x, dims) :
	map1!(FixAbsPow(inv(p)), sum!(dst, FixAbsPow(p), x, dims))
end

function vnorm(x::ContiguousRealArray, p::Real, dims::DimSpec) 
	tt = promote_type(fptype(eltype(x)), fptype(typeof(p)))
	r = Array(tt, reduced_shape(size(x), dims))
	vnorm!(r, x, p, dims)
end

# vnormdiff

function vnormdiff(x::ContiguousRealArray, y::ContiguousArrOrNum, p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? sumabsdiff(x, y) :
	p == 2 ? sqrt(sumsqdiff(x, y)) :	
	isinf(p) ? maxabsdiff(x, y) :
	sumfdiff(FixAbsPow(p), x, y) .^ inv(p)
end

vnormdiff(x::ContiguousRealArray, y::ContiguousArrOrNum) = vnormdiff(x, y, 2)

function vnormdiff!(dst::ContiguousRealArray, x::ContiguousRealArray, y::ContiguousArrOrNum, p::Real, dims::DimSpec)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? sumabsdiff!(dst, x, y, dims) :
	p == 2 ? map1!(SqrtFun(), sumsqdiff!(dst, x, y, dims)) :	
	isinf(p) ? maxabsdiff!(dst, x, y, dims) :
	map1!(FixAbsPow(inv(p)), sumfdiff!(dst, FixAbsPow(p), x, y, dims))
end

function vnormdiff(x::ContiguousRealArray, y::ContiguousRealArray, p::Real, dims::DimSpec) 
	tt = promote_type(fptype(promote_type(eltype(x), eltype(y))), fptype(typeof(p)))
	r = Array(tt, reduced_shape(size(x), dims))
	vnormdiff!(r, x, y, p, dims)
end


#################################################
#
# 	Normalization
#
#################################################

# normalize an array as a whole

function normalize!(dst::ContiguousRealArray, x::ContiguousRealArray, p::Real)
	return map!(Multiply(), dst, x, inv(vnorm(x, p)))
end
normalize!(x::ContiguousRealArray, p::Real) = normalize!(x, x, p)
normalize(x::ContiguousRealArray, p::Real) = x * inv(vnorm(x, p))

# normalize along specific dimension

function normalize!(dst::ContiguousRealArray, x::ContiguousRealArray, p::Real, d::Int)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	if length(dst) != length(x)
		throw(ArgumentError("Inconsistent argument dimensions!"))
	end

	if d == 1
		siz = size(x)
		m = siz[1]
		n = succ_length(siz, 1)

		if p == 1
			for j = 1:n			
				xj = view(x, :, j)
				yj = view(dst, :, j)
				map!(Multiply(), yj, xj, inv(sumabs(xj)))
			end
		elseif p == 2
			for j = 1:n
				xj = view(x, :, j)
				yj = view(dst, :, j)
				map!(Multiply(), yj, xj, inv(sqrt(sumsq(xj))))
			end
		elseif isinf(p)
			for j = 1:n
				xj = view(x, :, j)
				yj = view(dst, :, j)
				map!(Multiply(), yj, xj, inv(maxabs(xj)))
			end
		else
			for j = 1:n
				xj = view(x, :, j)
				yj = view(dst, :, j)
				u = sum(FixAbsPow(p), xj) .^ inv(p)
				map!(Multiply(), yj, xj, inv(u))
			end
		end

	else
		broadcast!(.*, dst, x, rcp!(vnorm(x, p, d)))
	end
	dst
end

normalize!(x::ContiguousRealArray, p::Real, d::Int) = normalize!(x, x, p, d)
normalize(x::ContiguousRealArray, p::Real, d::Int) = normalize!(similar(x), x, p, d)

