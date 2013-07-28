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