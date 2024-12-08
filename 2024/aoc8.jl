using DataStructures
using Test

struct Point
    x::Int
    y::Int
end

Base.:+(p1::Point, p2::Point) = Point(p1.x + p2.x, p1.y + p2.y)
Base.:-(p1::Point, p2::Point) = Point(p1.x - p2.x, p1.y - p2.y)

mutable struct SpatialIndex
    grid::Dict{Tuple{Int,Int},Char}
    bounds::Tuple{Int,Int}
end

function SpatialIndex()
    SpatialIndex(Dict{Tuple{Int,Int},Char}(), (0, 0))
end

function is_valid_position(index::SpatialIndex, p::Point)
    1 ≤ p.x ≤ index.bounds[1] && 1 ≤ p.y ≤ index.bounds[2]
end

function mark_antinode!(index::SpatialIndex, p::Point)
    if is_valid_position(index, p)
        index.grid[(p.x, p.y)] = '#'
    end
end

# Stream process input file and collect antenna positions
function read_antenna_positions(filepath::String)
    antenna_dict = DefaultDict{Char,Vector{Point}}(() -> Point[])
    rows = 0
    cols = 0

    open(filepath, "r") do file
        for (row, line) in enumerate(eachline(file))
            rows = row
            cols = length(line)
            for (col, char) in enumerate(line)
                if isletter(char) || isdigit(char)
                    push!(antenna_dict[char], Point(row, col))
                end
            end
        end
    end

    return Dict(antenna_dict), (rows, cols)
end

# Process antenna pairs and mark antinodes
function process_antenna_pairs!(spatial_index::SpatialIndex, antenna_positions::Dict, task::Int)
    if task == 2
        for (char, positions) in antenna_positions
            if length(positions) > 1
                for pos in positions
                    mark_antinode!(spatial_index, pos)
                end
                for i in eachindex(positions)
                    for j in 1:i-1
                        pos1 = positions[i]
                        pos2 = positions[j]
                        dp = pos2 - pos1

                        n1 = pos2
                        n2 = pos1

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
        end
    else
        for (char, positions) in antenna_positions
            for i in eachindex(positions)
                for j in 1:i-1
                    antinodes = [positions[j] + (positions[j] - positions[i]), positions[i] - (positions[j] - positions[i])]
                    for antinode in antinodes
                        mark_antinode!(spatial_index, antinode)
                    end
                end
            end
        end
    end
end

function count_antinodes(filepath::String, task::Int)
    spatial_index = SpatialIndex()
    antenna_positions, bounds = read_antenna_positions(filepath)
    spatial_index.bounds = bounds
    process_antenna_pairs!(spatial_index, antenna_positions, task)
    return count(v -> v == '#', values(spatial_index.grid))
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

#0.000899 seconds (813 allocations: 207.312 KiB)

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("Provide an input file path or 'test' as argument")
    if ARGS[1] == "test"
        using Test
        run_tests()
    else
        main(ARGS[1])
    end
end
