using Test

struct Node
    name::String
    is_t::Bool
    Node(s::AbstractString) = new(s, startswith(s, 't'))
end

# Use BitMatrix for adjacency
struct Graph
    nodes::Vector{Node}
    adj::BitMatrix
    node_map::Dict{String,Int}
end

function build_graph(io::IO)
    # First pass: collect unique nodes
    nodes = Set{String}()
    edges = Tuple{String,String}[]
    for line in eachline(io)
        u, v = strip.(split(line, '-'))
        push!(nodes, u, v)
        push!(edges, (u, v))
    end

    # Create node mapping and sorted nodes
    sorted_nodes = sort!(collect(nodes))
    node_map = Dict(n => i for (i, n) in enumerate(sorted_nodes))
    nodes_vec = [Node(n) for n in sorted_nodes]

    # Build adjacency matrix
    n = length(nodes_vec)
    adj = falses(n, n)
    for (u, v) in edges
        i, j = node_map[u], node_map[v]
        @inbounds adj[i, j] = adj[j, i] = true
    end

    Graph(nodes_vec, adj, node_map)
end

@inline function count_t_triangles(g::Graph)
    count = 0
    n = length(g.nodes)

    @inbounds for i in 1:n
        for j in (i+1):n
            !g.adj[i, j] && continue
            for k in (j+1):n
                (!g.adj[i, k] || !g.adj[j, k]) && continue
                # Found a triangle (i,j,k)
                ni, nj, nk = g.nodes[i], g.nodes[j], g.nodes[k]
                if ni.is_t || nj.is_t || nk.is_t
                    count += 1
                end
            end
        end
    end
    count
end

function find_max_clique(g::Graph)
    n = length(g.nodes)
    max_clique = BitVector(undef, n)
    current = BitVector(undef, n)
    candidates = BitVector(undef, n)
    excluded = BitVector(undef, n)
    max_size = Ref(0)

    function bron_kerbosch!(R::BitVector, P::BitVector, X::BitVector)
        if !any(P) && !any(X)
            size = count(R)
            if size > max_size[]
                max_size[] = size
                copy!(max_clique, R)
            end
            return
        end

        pivot_idx = 1
        max_connections = 0
        @inbounds for i in 1:n
            P[i] || continue
            connections = count(j -> P[j] && g.adj[i, j], 1:n)
            if connections > max_connections
                max_connections = connections
                pivot_idx = i
            end
        end

        @inbounds for i in 1:n
            !P[i] && continue
            g.adj[pivot_idx, i] && continue

            R[i] = true
            old_P = copy(P)
            old_X = copy(X)

            @inbounds for j in 1:n
                P[j] &= g.adj[i, j]
                X[j] &= g.adj[i, j]
            end

            bron_kerbosch!(R, P, X)

            R[i] = false
            copy!(P, old_P)
            copy!(X, old_X)
            P[i] = false
            X[i] = true
        end
    end

    fill!(current, false)
    fill!(candidates, true)
    fill!(excluded, false)

    bron_kerbosch!(current, candidates, excluded)

    result = String[]
    @inbounds for i in 1:n
        max_clique[i] && push!(result, g.nodes[i].name)
    end
    sort!(result)
    join(result, ",")
end

function solve_network_puzzle(io::IO)
    graph = build_graph(io)
    return count_t_triangles(graph), find_max_clique(graph)
end

function run_tests()
    @testset "Network Puzzle" begin
        test_input = """
            kh-tc
            qp-kh
            de-cg
            ka-co
            yn-aq
            qp-ub
            cg-tb
            vc-aq
            tb-ka
            wh-tc
            yn-cg
            kh-ub
            ta-co
            de-co
            tc-td
            tb-wq
            wh-td
            ta-ka
            td-qp
            aq-cg
            wq-ub
            ub-vc
            de-ta
            wq-aq
            wq-vc
            wh-yn
            ka-de
            kh-ta
            co-tc
            wh-qp
            tb-vc
            td-yn
        """
        t_count, password = solve_network_puzzle(IOBuffer(test_input))
        @test t_count == 7
        @test !isempty(password)
    end
end

function main(filename::String)
    open(filename) do f
        t_count, password = @time solve_network_puzzle(f)
        println("Part 1 - Triangles with 't': $t_count")
        println("Part 2 - LAN Party Password: $password")
    end
end

# 0.023121 seconds (46.59 k allocations: 2.558 MiB)

if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
    isempty(ARGS) || main(ARGS[1])
end
