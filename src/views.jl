# Efficient consecutive view of an array

offset_view(a::Array, i::Int, len::Int) = pointer_to_array(pointer(a, i), len)
offset_view(a::Array, i::Int, siz::NTuple{Int}) = pointer_to_array(pointer(a, i), siz)

# size helper

total_ncolumns(a::Vector) = 1
total_ncolumns(a::Matrix) = size(a, 2)
total_ncolumns{T}(a::Array{T,3}) = size(a, 2) * size(a, 3)
total_ncolumns(a::Array) = prod(size(a)[2:])

total_npages(a::VecOrMat) = 1
total_npages{T}(a::Array{T,3}) = size(a, 3)
total_npages{T}(a::Array{T,4}) = size(a, 3) * size(a, 4)


# a consecutive range

view(a::Array, ::Colon) = vec(a)

function view(a::Array, rgn::Range1)
	len = length(rgn)
	if !(1 <= rgn[1] && rgn[len] <= length(a))
		error("View range out of bound.")
	end
	offset_view(a, rgn[1], len)
end


function view(a::Array, ::Colon, j::Int)
	m = size(a, 1)
	n::Int = total_ncolumns(a)

	if !(1 <= j <= n)
		error("Column index out of bound.")
	end
	
	offset_view(a, m * (j - 1) + 1, m)
end

function view(a::Array, ::Colon, j0::Int, j1::Int)
	m = size(a, 1)
	n = size(a, 2)
	np::Int = total_npages(a)
	if !(1 <= j0 <= n && 1 <= j1 <= np)
		error("Column indices out of bound.")
	end
	
	offset_view(a, m * ((j0 - 1) + n * (j1 - 1)) + 1, m)
end

function view(a::Array, rgn::Range1{Int}, j::Int)
	m = size(a, 1)
	n::Int = total_ncolumns(a)

	if !(1 <= rgn[1] && rgn[end] <= m && 1 <= j <= n)
		error("Row range or column index out of bound.")
	end
	
	offset_view(a, m * (j - 1) + rgn[1], length(rgn))
end

function view(a::Array, rgn::Range1{Int}, j0::Int, j1::Int)
	m = size(a, 1)
	n = size(a, 2)
	np::Int = total_npages(a)
	if !(1 <= rgn[1] && rgn[end] <= m && 1 <= j0 <= n && 1 <= j1 <= np)
		error("Row range or column index out of bound.")
	end
	
	offset_view(a, m * ((j0 - 1) + n * (j1 - 1)) + rgn[1], length(rgn))
end


function view(a::Array, ::Colon, ::Colon)
	pointer_to_array(pointer(a), (size(a, 1), total_ncolumns(a)))
end

function view(a::Array, ::Colon, rgn::Range1{Int})
	m = size(a, 1)
	n::Int = total_ncolumns(a)

	if !(1 <= rgn[1] && rgn[end] <= n)
		error("Column range out of bound.")
	end
	offset_view(a, m * (rgn[1] - 1) + 1, (m, length(rgn)))
end

function view(a::Array, ::Colon, ::Colon, k::Int)
	np::Int = total_npages(a)
	if !(1 <= k <= np)
		error("Page index out of bound.")
	end

	m = size(a, 1)
	n = size(a, 2)
	offset_view(a, m * n * (k - 1) + 1, (m, n))
end

function view(a::Array, ::Colon, rgn::Range1{Int}, k::Int)
	m = size(a, 1)
	n = size(a, 2)
	np = total_npages(a)

	if !(1 <= rgn[1] && rgn[end] <= n && 1 <= k <= np)
		error("Column range or page index out of bound.")
	end
	offset_view(a, m * ((rgn[1] - 1) + n * (k - 1)) + 1, (m, length(rgn)))
end


