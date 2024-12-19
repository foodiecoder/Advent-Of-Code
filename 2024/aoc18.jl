# Reference: https://www.reddit.com/r/adventofcode/comments/1hguacy/comment/m2m8d61/

using DataStructures: Queue, enqueue!, dequeue!
using Test

const dirs = CartesianIndex.([(-1, 0), (0, 1), (1, 0), (0, -1)])

function read_puzzle(file)
    coords = []
    for l in eachline(file)
        col, row = parse.(Int, eachsplit(l, ","))
        push!(coords, CartesianIndex(row + 1, col + 1))
    end
    coords
end

# BFS algorithm to find the shortest path
function part1(open_matrix, size=(71, 71))
    q = Queue{CartesianIndex{2}}()
    enqueue!(q, CartesianIndex(1, 1))

    visited = falses(size)
    visited[CartesianIndex(1, 1)] = true

    dist = zeros(Int, size)

    while !isempty(q)
        cur = dequeue!(q)

        if cur == CartesianIndex(size)
            return dist[cur]
        end

        for dir in dirs
            next = cur + dir
            if checkbounds(Bool, open_matrix, next) && open_matrix[next] && !visited[next]
                visited[next] = true
                dist[next] = dist[cur] + 1
                enqueue!(q, next)
            end
        end
    end
    return Inf
end

# Reserved approach
function part2(coords, size=(71, 71))
    all_open = trues(size)
    for i in 1:length(coords)
        all_open[coords[i]] = false
        d = part1(all_open, size)
        if d == Inf
            return join(reverse(Tuple(coords[i]) .- 1), ",")
        end
    end
end

function run_tests()
    # Convert tuples to CartesianIndices
    test_input = [CartesianIndex(row + 1, col + 1) for (col, row) in [
        (5, 4), (4, 2), (4, 5), (3, 0), (2, 1), (6, 3), (2, 4), (1, 5), (0, 6),
        (3, 3), (2, 6), (5, 1), (1, 2), (5, 5), (2, 5), (6, 5), (1, 4), (0, 4),
        (6, 4), (1, 1), (6, 1), (1, 0), (0, 5), (1, 6), (2, 0)
    ]]

    size = (7, 7)  # Memory space size from 0 to 6 for the test case

    # Test with first 12 coordinates
    open_matrix = trues(size)
    for c in test_input[1:12]
        open_matrix[c] = false
    end
    @test part1(open_matrix, size) == 22

    # Test full coordinate list
    result = part2(test_input, size)
    @test result == "6,1"

    println("All tests passed!")
end

function main(filename::String)
    @time begin
        coords = read_puzzle(filename)
        size = (71, 71)

        # Create initial open_matrix for part1
        open_matrix_part1 = trues(size)
        for c in coords[1:1024]
            open_matrix_part1[c] = false
        end
        part1(open_matrix_part1, size) |> println

        part2(coords, size) |> println
    end
end

# 0.692759 seconds (4.04 M allocations: 335.689 MiB, 7.99% gc time)

if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
    isempty(ARGS) || main(ARGS[1])
end

