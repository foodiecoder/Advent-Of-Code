using Test

const DIRS = ((0, -1), (0, 1), (-1, 0), (1, 0))

function solve_trails(grid, trailheads_rating=false)
    grid = convert(Matrix{Int8}, grid)
    R, C = size(grid)

    visited = BitArray(undef, R, C)
    path_cache = Dict{Tuple{Int8,Int8,UInt64},Int16}()
    ends = Set{Tuple{Int8,Int8}}()

    function traverse(r::Int8, c::Int8, path_bits::UInt64=UInt64(0))
        @inbounds val = grid[r, c]

        if trailheads_rating
            if val == 9
                return Int16(1)
            end

            pos_bit = UInt64(1) << ((c - 1) * R + (r - 1))
            key = (r, c, path_bits)

            haskey(path_cache, key) && return path_cache[key]

            count = Int16(0)
            @inbounds for (dr, dc) in DIRS
                nr, nc = r + dr, c + dc
                if 1 ≤ nr ≤ R && 1 ≤ nc ≤ C &&
                   grid[nr, nc] == val + 1 &&
                   (path_bits & (UInt64(1) << ((nc - 1) * R + (nr - 1)))) == 0
                    count += traverse(Int8(nr), Int8(nc), path_bits | pos_bit)
                end
            end
            path_cache[key] = count
            return count
        else
            if val == 9
                push!(ends, (r, c))
                return
            end
            @inbounds visited[r, c] = true

            @inbounds for (dr, dc) in DIRS
                nr, nc = r + dr, c + dc
                if 1 ≤ nr ≤ R && 1 ≤ nc ≤ C &&
                   !visited[nr, nc] && grid[nr, nc] == val + 1
                    traverse(Int8(nr), Int8(nc))
                end
            end
            @inbounds visited[r, c] = false
        end
    end

    total = 0
    @inbounds for r in 1:R, c in 1:C
        if grid[r, c] == 0
            if trailheads_rating
                empty!(path_cache)
                total += traverse(Int8(r), Int8(c))
            else
                empty!(ends)
                fill!(visited, false)
                traverse(Int8(r), Int8(c))
                total += length(ends)
            end
        end
    end
    return total
end

function run_tests()
    test_cases = [
        (
            """
            89010123
            78121874
            87430965
            96549874
            45678903
            32019012
            01329801
            10456732
            """,
            false,
            36
        ),
        (
            """
            89010123
            78121874
            87430965
            96549874
            45678903
            32019012
            01329801
            10456732
            """,
            true,
            81
        )
    ]

    for (i, (test_input, task, expected_output)) in enumerate(test_cases)
        println("Running test case $i:")
        # Convert the string input to a matrix of integers
        grid = parse_input(test_input)
        actual_output = solve_trails(grid, task)
        println("Expected output: $expected_output, Actual output: $actual_output")
        if actual_output == expected_output
            println("Test case $i passed.")
        else
            println("Test case $i failed.")
        end
    end
end

# Helper function to convert input string to matrix
function parse_input(test_input::String)
    lines = split(chomp(test_input), "\n")
    matrix = reduce(hcat, map(line -> parse.(Int, collect(line)), lines))
    return permutedims(matrix)
end

function main(file_path::String)
    grid = permutedims(reduce(hcat, map(line -> parse.(Int, collect(line)), split(readchomp(file_path), '\n'))))
    println("Part 1: ", solve_trails(grid))
    println("Part 2: ", solve_trails(grid, true))
end

# 0.001360 seconds (4.03 k allocations: 191.492 KiB)

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("Provide an input file path or 'test' as argument")
    if ARGS[1] == "test"
        using Test
        run_tests()
    else
        main(ARGS[1])
    end
end
