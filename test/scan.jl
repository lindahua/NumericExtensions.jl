# Unit testing for scanning functions

using NumericFuns
using NumericExtensions
using Base.Test

# verification function

function safe_scan(x, f)
    y = similar(x)
    y[1] = x[1]
    for i = 2:length(x)
        y[i] = f(y[i-1], x[i])
    end
    y
end

function safe_scan(x, f, dim)
    @assert ndims(x) <= 3
    y = similar(x)
    siz = size(x)
    if dim == 1
        n = prod(siz[2:end])
        for j=1:n
            y[:,j] = safe_scan(x[:,j], f)
        end
    elseif dim == 2
        @assert ndims(x) >= 2
        if ndims(x) == 2
            m = siz[1]
            for i=1:m
                y[i,:] = safe_scan(x[i,:], f)
            end
        else
            for k=1:siz[3]
                y[:,:,k] = safe_scan(x[:,:,k], f, 2)
            end
        end

    elseif dim == 3
        @assert ndims(x) == 3
        y[:,:,1] = x[:,:,1]
        for k=2:siz[3]
            y[:,:,k] = f(y[:,:,k-1], x[:,:,k])
        end

    else
        error("dim > 3 is not supported in safe_scan.")
    end
    y
end

# data 

x1 = randn(6)
y1 = randn(6)
z1 = randn(6)

x2 = randn(5, 6)
y2 = randn(5, 6)
z2 = randn(5, 6)

x3 = randn(3, 4, 5)
y3 = randn(3, 4, 5)
z3 = randn(3, 4, 5)

# vector scan

r = safe_scan(x1, +)

@test size(cumsum(x1)) == size(x1)
@test_approx_eq cumsum(x1) r

x1c = copy(x1)
@test cumsum!(x1c) === x1c
@test_approx_eq x1c r

dst = zeros(size(x1))
cumsum!(dst, x1)
@test_approx_eq dst r

@test_approx_eq cummax(x1) safe_scan(x1, max)
@test_approx_eq cummin(x1) safe_scan(x1, min)

@test_approx_eq cumsum(Abs2Fun(), x1) safe_scan(abs2(x1), +)
@test_approx_eq cumsum(Multiply(), x1, y1) safe_scan(x1 .* y1, +)
@test_approx_eq cumsum(FMA(), x1, y1, z1) safe_scan(x1 + y1 .* z1, +)

dst = zeros(size(x1))
cumsum!(dst, Abs2Fun(), x1) 
@test_approx_eq dst safe_scan(abs2(x1), +)

# scan along dimensions

@test size(cumsum(x1, 1)) == size(x1)
@test size(cumsum(x2, 1)) == size(x2)
@test size(cumsum(x2, 2)) == size(x2)
@test size(cumsum(x3, 1)) == size(x3)
@test size(cumsum(x3, 2)) == size(x3)
@test size(cumsum(x3, 3)) == size(x3)

@test_approx_eq cumsum(x1, 1) safe_scan(x1, +, 1)
@test_approx_eq cumsum(x2, 1) safe_scan(x2, +, 1)
@test_approx_eq cumsum(x2, 2) safe_scan(x2, +, 2)
@test_approx_eq cumsum(x3, 1) safe_scan(x3, +, 1)
@test_approx_eq cumsum(x3, 2) safe_scan(x3, +, 2)
@test_approx_eq cumsum(x3, 3) safe_scan(x3, +, 3)

@test_approx_eq cummax(x1, 1) safe_scan(x1, max, 1)
@test_approx_eq cummax(x2, 1) safe_scan(x2, max, 1)
@test_approx_eq cummax(x2, 2) safe_scan(x2, max, 2)
@test_approx_eq cummax(x3, 1) safe_scan(x3, max, 1)
@test_approx_eq cummax(x3, 2) safe_scan(x3, max, 2)
@test_approx_eq cummax(x3, 3) safe_scan(x3, max, 3)

@test_approx_eq cummin(x1, 1) safe_scan(x1, min, 1)
@test_approx_eq cummin(x2, 1) safe_scan(x2, min, 1)
@test_approx_eq cummin(x2, 2) safe_scan(x2, min, 2)
@test_approx_eq cummin(x3, 1) safe_scan(x3, min, 1)
@test_approx_eq cummin(x3, 2) safe_scan(x3, min, 2)
@test_approx_eq cummin(x3, 3) safe_scan(x3, min, 3)

@test_approx_eq cumsum(Abs2Fun(), x1, 1) safe_scan(abs2(x1), +, 1)
@test_approx_eq cumsum(Abs2Fun(), x2, 1) safe_scan(abs2(x2), +, 1)
@test_approx_eq cumsum(Abs2Fun(), x2, 2) safe_scan(abs2(x2), +, 2)
@test_approx_eq cumsum(Abs2Fun(), x3, 1) safe_scan(abs2(x3), +, 1)
@test_approx_eq cumsum(Abs2Fun(), x3, 2) safe_scan(abs2(x3), +, 2)
@test_approx_eq cumsum(Abs2Fun(), x3, 3) safe_scan(abs2(x3), +, 3)

@test_approx_eq cumsum(Multiply(), x1, y1, 1) safe_scan(x1 .* y1, +, 1)
@test_approx_eq cumsum(Multiply(), x2, y2, 1) safe_scan(x2 .* y2, +, 1)
@test_approx_eq cumsum(Multiply(), x2, y2, 2) safe_scan(x2 .* y2, +, 2)
@test_approx_eq cumsum(Multiply(), x3, y3, 1) safe_scan(x3 .* y3, +, 1)
@test_approx_eq cumsum(Multiply(), x3, y3, 2) safe_scan(x3 .* y3, +, 2)
@test_approx_eq cumsum(Multiply(), x3, y3, 3) safe_scan(x3 .* y3, +, 3)

x1c = copy(x1); cumsum!(x1c, 1)
@test_approx_eq x1c cumsum(x1, 1)

x2c = copy(x2); cumsum!(x2c, 1)
@test_approx_eq x2c cumsum(x2, 1)

x2c = copy(x2); cumsum!(x2c, 2)
@test_approx_eq x2c cumsum(x2, 2)

x3c = copy(x3); cumsum!(x3c, 1)
@test_approx_eq x3c cumsum(x3, 1)

x3c = copy(x3); cumsum!(x3c, 2)
@test_approx_eq x3c cumsum(x3, 2)

x3c = copy(x3); cumsum!(x3c, 3)
@test_approx_eq x3c cumsum(x3, 3)

dst = similar(x2)
cumsum!(dst, Abs2Fun(), x2, 1)
@test_approx_eq dst cumsum(abs2(x2), 1)

