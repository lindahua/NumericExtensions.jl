# Helpers for benchmark

type BenchmarkTable
    name::ASCIIString

    colnames::Vector{ASCIIString}
    rownames::Vector{ASCIIString}

    colmap::Dict{ASCIIString, Int}
    rowmap::Dict{ASCIIString, Int}
    rows::Vector{Vector{Float64}}

    function BenchmarkTable(name::ASCIIString, colnames::Vector{ASCIIString})
        colmap = Dict{ASCIIString, Int}([colnames[i] => i for i in 1 : length(colnames)])
        new(name, colnames, ASCIIString[], 
            colmap, Dict{ASCIIString, Int}(), Array(Vector{Float64}, 0))
    end
end

nrows(tab::BenchmarkTable) = length(tab.rownames)
ncolumns(tab::BenchmarkTable) = length(tab.colnames)

getindex(tab::BenchmarkTable, i::Int, j::Int) = tab.rows[i][j]
row(tab::BenchmarkTable, i::Int) = tab.rows[i]

function add_row!(tab::BenchmarkTable, rowname::ASCIIString, row::Vector{Float64})
    if haskey(tab.rowmap, rowname)
        error("The rowname $rowname has existed.")
    end
    nc = ncolumns(tab)
    if length(row) != nc
        error("Invalid row length.")
    end

    nr = nrows(tab)
    push!(tab.rownames, rowname)
    tab.rowmap[rowname] = nr + 1

    push!(tab.rows, row)
    tab
end

function _leftalign_string(s::ASCIIString, len::Int)
    slen = length(s)
    slen < len ? string(s, repeat(" ", len - slen)) :
    slen > len ? s[1:len] : s
end

function _rightalign_string(s::ASCIIString, len::Int)
    slen = length(s)
    slen < len ? string(repeat(" ", len - slen), s) :
    slen > len ? s[1:len] : s
end

function Base.show(io::IO, tab::BenchmarkTable)
    println(io, "BenchmarkTable: $(tab.name)")

    # compute lengths
    lr = maximum([length(x) for x in tab.rownames])
    lc = maximum([length(x) for x in tab.colnames])
    lc = max(lc, 8)

    m = nrows(tab)
    n = ncolumns(tab)

    # print headers
    hlen = lr + (lc + 3) * n + 3
    println(io, repeat("=", hlen))
    print(io, repeat(" ", lr + 2))
    print(io, "| ")

    for cname in tab.colnames
        print(io, _leftalign_string(cname, lc))
        print(io, " | ")
    end
    println(io)
    println(io, repeat("-", hlen))

    # print rows
    for i in 1 : m
        rname = tab.rownames[i]
        row = tab.rows[i]

        print(io, _leftalign_string(rname, lr))
        print(io, "  | ")
        for j in 1 : n
            vs = @sprintf("%8.4f", row[j])
            print(io, _rightalign_string(vs, lc))
            print(io, " | ")
        end
        println(io)
    end
    println(io, repeat("-", hlen))
end


