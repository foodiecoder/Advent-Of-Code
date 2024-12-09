using StaticArrays
using Test

const Point = SVector{2,Int}

struct SpatialIndex
    grid::BitMatrix
    bounds::Tuple{Int,Int}
end

# Constructor
function SpatialIndex()
    SpatialIndex(BitMatrix(undef, 0, 0), (0, 0))
end

function is_valid_position(index::SpatialIndex, p::Point)
    1 ≤ p[1] ≤ index.bounds[1] && 1 ≤ p[2] ≤ index.bounds[2]
end

function mark_antinode!(index::SpatialIndex, p::Point)
    if is_valid_position(index, p)
        @inbounds index.grid[p[1], p[2]] = true
    end
end

function read_antenna_positions(filepath::String)
    antenna_dict = Dict{Char,Vector{Point}}()
    lines = readlines(filepath)
    rows, cols = length(lines), length(first(lines))

    for (row, line) in enumerate(lines)
        for (col, char) in enumerate(line)
            if isletter(char) || isdigit(char)
                points = get!(Vector{Point}, antenna_dict, char)
                push!(points, Point(row, col))
            end
        end
    end

    return antenna_dict, (rows, cols)
end

function process_antenna_pairs!(spatial_index::SpatialIndex, antenna_positions::Dict, task::Int)
    if task == 2
        for (_, positions) in antenna_positions
            len = length(positions)
            len < 2 && continue

            @inbounds for i in 1:len
                mark_antinode!(spatial_index, positions[i])
                for j in 1:i-1
                    pos1, pos2 = positions[i], positions[j]
                    dp = pos2 - pos1

                    n1, n2 = pos2, pos1
                    while is_valid_position(spatial_index, n1)
                        mark_antinode!(spatial_index, n1)
                        n1 = n1 + dp
                    end
                    while is_valid_position(spatial_index, n2)
                        mark_antinode!(spatial_index, n2)
                        n2 = n2 - dp
                    end
                end
            end
        end
    else
        for (_, positions) in antenna_positions
            len = length(positions)
            len < 2 && continue

            @inbounds for i in 1:len
                for j in 1:i-1
                    pos1, pos2 = positions[i], positions[j]
                    diff = pos2 - pos1
                    mark_antinode!(spatial_index, pos2 + diff)
                    mark_antinode!(spatial_index, pos1 - diff)
                end
            end
        end
    end
end

function count_antinodes(filepath::String, task::Int)
    antenna_positions, bounds = read_antenna_positions(filepath)
    spatial_index = SpatialIndex(falses(bounds...), bounds)
    process_antenna_pairs!(spatial_index, antenna_positions, task)
    return count(spatial_index.grid)
end

function run_tests()
    test_cases = [
        (
            """
            ......#....#
            ...#....0...
            ....#0....#.
            ..#....0....
            ....0....#..
            .#....A.....
            ...#........
            #......#....
            ........A...
            .........A..
            ..........#.
            ..........#.
            """,
            1,
            14
        ),
        (
            """
            ##....#....#
            .#.#....0...
            ..#.#0....#.
            ..##...0....
            ....0....#..
            .#...#A....#
            ...#..#.....
            #....#.#....
            ..#.....A...
            ....#....A..
            .#........#.
            ...#......##
            """,
            2,
            34
        )
    ]

    for (i, (test_input, task, expected_output)) in enumerate(test_cases)
        print("Running test case $i: ")
        tmp_file, tmp_io = mktemp()
        write(tmp_io, test_input)
        close(tmp_io)
        actual_output = count_antinodes(tmp_file, task)
        println("Expected output: $expected_output, Actual output: $actual_output")
        if actual_output != expected_output
            println("Test case $i failed.")
        else
            println("Test case $i passed.")
        end
        rm(tmp_file)
    end
end

run_tests()

function main(file_path::String)
    println("Task1: total unique antinodes: ", count_antinodes(file_path, 1))
    println("Task2: total unique antinodes: ", count_antinodes(file_path, 2))
end

# 0.000557 seconds (520 allocations: 46.969 KiB)
if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("Provide an input file path or 'test' as argument")
    if ARGS[1] == "test"
        using Test
        run_tests()
    else
        main(ARGS[1])
    end
end

#=
`BitMatrix` >. instead of Dict for grid storage
`StaticArrays` >. Point type
`Dict` >. preallocate for alphabet letters(26)
`enumerate()` >. file reading not with enumerate(eachline(file))
`readlines` >. reading entire file at once
`@inbound` >. array access
=#
