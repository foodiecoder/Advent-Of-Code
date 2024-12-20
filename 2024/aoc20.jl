using DataStructures
using Test

const DIRECTIONS = (CartesianIndex(-1, 0), CartesianIndex(1, 0), CartesianIndex(0, -1), CartesianIndex(0, 1))

function parse_map(file)
    lines = readlines(file)
    grid = Matrix{Char}(undef, length(lines), length(lines[1]))
    start = end_pos = CartesianIndex(0, 0)
    for (i, line) in enumerate(lines)
        for (j, char) in enumerate(line)
            grid[i, j] = char
            char == 'S' && (start = CartesianIndex(i, j))
            char == 'E' && (end_pos = CartesianIndex(i, j))
        end
    end
    grid, start, end_pos
end

function find_shortest_path(grid, start, end_pos)
    queue = Queue{CartesianIndex{2}}()
    enqueue!(queue, start)
    distances = fill(typemax(Int), size(grid))
    distances[start] = 0
    predecessors = fill(CartesianIndex(0, 0), size(grid))

    while !isempty(queue)
        current = dequeue!(queue)
        current == end_pos && break

        for dir in DIRECTIONS
            next = current + dir
            if checkbounds(Bool, grid, next) && grid[next] != '#' && distances[current] + 1 < distances[next]
                distances[next] = distances[current] + 1
                predecessors[next] = current
                enqueue!(queue, next)
            end
        end
    end

    path = [end_pos]
    while path[1] != start
        pushfirst!(path, predecessors[path[1]])
    end

    path, distances
end

function count_valid_cheats(path, distances)
    cheats_dist2 = 0
    cheats_dist20 = 0
    n = length(path)
    total_path_length = distances[path[end]] # total length of the path for test example

    for i in 1:n-1
        for j in i+2:n
            start_cheat, end_cheat = path[i], path[j]
            manhattan_dist = sum(abs, Tuple(end_cheat - start_cheat))
            time_saved = distances[end_cheat] - distances[start_cheat] - manhattan_dist

            #if time_saved >= 100
            if total_path_length - time_saved <= total_path_length - 100
                if manhattan_dist == 2
                    cheats_dist2 += 1
                end
                if manhattan_dist <= 20
                    cheats_dist20 += 1
                end
            end
        end
    end
    cheats_dist2, cheats_dist20
end

function solve_race_cheats(input)
    grid, start, end_pos = parse_map(input)
    path, distances = find_shortest_path(grid, start, end_pos)
    cheats_dist2, cheats_dist20 = count_valid_cheats(path, distances)
    println("Cheats with distance 2 saving at least 100 picoseconds: ", cheats_dist2)
    println("Cheats with distance ≤ 20 saving at least 100 picoseconds: ", cheats_dist20)
end

function run_tests()
    @testset "Race Track Cheating " begin
        test_input = """
        ###############
        #...#...#.....#
        #.#.#.#.#.###.#
        #S#...#.#.#...#
        #######.#.#.###
        #######.#.#...#
        #######.#.###.#
        ###..E#...#...#
        ###.#######.###
        #...###...#...#
        #.#####.#.###.#
        #.#...#.#.#...#
        #.#.#.#.#.#.###
        #...#...#...###
        ###############
        """
        grid, start, end_pos = parse_map(IOBuffer(test_input))
        path, distances = find_shortest_path(grid, start, end_pos)
        println("Total path length: ", distances[end_pos])
        cheats_dist2, cheats_dist20 = count_valid_cheats(path, distances)
        println("Cheats with distance 2 saving at least 100 picoseconds: ", cheats_dist2)
        println("Cheats with distance ≤ 20 saving at least 100 picoseconds: ", cheats_dist20)
        @test cheats_dist2 == 0
        @test cheats_dist20 == 0
    end
end

function main(filename::String)
    @time solve_race_cheats(filename)
end

# 0.154863 seconds (358 allocations: 1.393 MiB)

if abspath(@__FILE__) == @__FILE__
    run_tests()
    isempty(ARGS) || main(ARGS[1])
end
