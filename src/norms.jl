# Normal evaluation and normalization

#################################################
#
# 	Vector norms
#
#################################################

function vnorm(x::ContiguousArray, p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? asum(x) :
	p == 2 ? sqrt(sqsum(x)) :	
	isinf(p) ? amax(x) :
	sum(FixAbsPow(p), x) .^ inv(p)
end

vnorm(x::ContiguousArray) = vnorm(x, 2)

function vnorm!(dst::ContiguousArray, x::ContiguousArray, p::Real, dims::DimSpec)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? asum!(dst, x, dims) :
	p == 2 ? map1!(Sqrt(), sqsum!(dst, x, dims)) :	
	isinf(p) ? amax!(dst, x, dims) :
	map1!(FixAbsPow(inv(p)), sum!(dst, FixAbsPow(p), x, dims))
end

function vnorm{Tx<:Number,Tp<:Real}(x::ContiguousArray{Tx}, p::Tp, dims::DimSpec) 
	tt = to_fptype(promote_type(Tx, Tp))
	r = Array(tt, reduced_size(size(x), dims))
	vnorm!(r, x, p, dims)
	r
end

# vdiffnorm

function vdiffnorm(x::ContiguousArray, y::ArrayOrNumber, p::Real)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? adiffsum(x, y) :
	p == 2 ? sqrt(sqdiffsum(x, y)) :	
	isinf(p) ? adiffmax(x, y) :
	sum_fdiff(FixAbsPow(p), x, y) .^ inv(p)
end

vdiffnorm(x::ContiguousArray, y::ArrayOrNumber) = vdiffnorm(x, y, 2)

function vdiffnorm!(dst::ContiguousArray, x::ContiguousArray, y::ArrayOrNumber, p::Real, dims::DimSpec)
	if !(p > 0)
		throw(ArgumentError("p must be positive."))
	end
	p == 1 ? adiffsum!(dst, x, y, dims) :
	p == 2 ? map1!(Sqrt(), sqdiffsum!(dst, x, y, dims)) :	
	isinf(p) ? adiffmax!(dst, x, y, dims) :
	map1!(FixAbsPow(inv(p)), sum_fdiff!(dst, FixAbsPow(p), x, y, dims))
end

function vdiffnorm{Tx<:Number,Ty<:Number,Tp<:Real}(x::ContiguousArray{Tx}, y::ContiguousArray{Ty}, p::Tp, dims::DimSpec) 
	tt = to_fptype(promote_type(promote_type(Tx, Ty), Tp))
	r = Array(tt, reduced_size(size(x), dims))
	vdiffnorm!(r, x, y, p, dims)
	r
end


#################################################
#
# 	Normalization
#
#################################################

# normalize an array as a whole

function normalize!{Td<:Real,Tx<:Real}(dst::ContiguousArray{Td}, x::ContiguousArray{Tx}, p::Real)
	return map!(Multiply(), dst, x, inv(vnorm(x, p)))
end
normalize!{Tx<:Real}(x::ContiguousArray{Tx}, p::Real) = normalize!(x, x, p)
normalize{Tx<:Real}(x::ContiguousArray{Tx}, p::Real) = x * inv(vnorm(x, p))

# normalize along specific dimension

function normalize!{Td<:Real,Tx<:Real}(dst::ContiguousArray{Td}, x::ContiguousArray{Tx}, p::Real, d::Int)
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
				xj = unsafe_view(x, :, j)
				yj = unsafe_view(dst, :, j)
				map!(Multiply(), yj, xj, inv(asum(xj)))
			end
		elseif p == 2
			for j = 1:n
				xj = unsafe_view(x, :, j)
				yj = unsafe_view(dst, :, j)
				map!(Multiply(), yj, xj, inv(sqrt(sqsum(xj))))
			end
		elseif isinf(p)
			for j = 1:n
				xj = unsafe_view(x, :, j)
				yj = unsafe_view(dst, :, j)
				map!(Multiply(), yj, xj, inv(amax(xj)))
			end
		else
			for j = 1:n
				xj = unsafe_view(x, :, j)
				yj = unsafe_view(dst, :, j)
				u = sum(FixAbsPow(p), xj) .^ inv(p)
				map!(Multiply(), yj, xj, inv(u))
			end
		end

	else
		broadcast!(.*, dst, x, rcp!(vnorm(x, p, d)))
	end
	dst
end

normalize!{Tx<:Real}(x::ContiguousArray{Tx}, p::Real, d::Int) = normalize!(x, x, p, d)
normalize{Tx<:Real}(x::ContiguousArray{Tx}, p::Real, d::Int) = normalize!(similar(x), x, p, d)

