using Test

const Position = Tuple{Int,Int}
const DirectedPosition = Tuple{Int,Int,Int,Int}
const INITIAL_DIR = (-1, 0)
const TURN_RIGHT = ((0, 1), (1, 0), (0, -1), (-1, 0))
const DIR_IDX = Dict(TURN_RIGHT[i] => i for i in 1:4)

@inline turn_right(dir) = TURN_RIGHT[mod1(DIR_IDX[dir] + 1, 4)]
@inline next_pos(pos, dir) = map(+, pos, dir)
@inline is_wall(grid, pos) = @inbounds grid[pos...] == '#'
@inline in_bounds(grid, pos) = checkbounds(Bool, grid, pos...)

function parse_grid(input::String)
    rows = split(strip(input), '\n')
    grid = Matrix{Char}(undef, length(rows), length(first(rows)))
    start_pos = Ref{Position}()

    for (i, row) in enumerate(rows)
        for (j, c) in enumerate(row)
            @inbounds grid[i, j] = c
            c == '^' && (start_pos[] = (i, j))
        end
    end
    grid[start_pos[]...] = '.'
    (grid, start_pos[])
end

function walk_path(grid, start::Position)
    seen = Set{Position}()
    pos, dir = start, INITIAL_DIR

    while in_bounds(grid, next_pos(pos, dir))
        push!(seen, pos)
        next = next_pos(pos, dir)
        dir = is_wall(grid, next) ? turn_right(dir) : dir
        pos = is_wall(grid, next) ? pos : next
    end
    push!(seen, pos)
    seen
end

function check_loop(grid, start::Position, obstacle::Position)
    seen = Set{DirectedPosition}()
    pos, dir = start, INITIAL_DIR

    while in_bounds(grid, next_pos(pos, dir))
        curr = (pos..., dir...)
        curr ∈ seen && return length(seen) > 1
        push!(seen, curr)

        next = next_pos(pos, dir)
        dir = (next == obstacle || is_wall(grid, next)) ? turn_right(dir) : dir
        pos = (next == obstacle || is_wall(grid, next)) ? pos : next
    end
    false
end

function solve_patrol(input::String, part2=false)
    grid, start = parse_grid(input)
    initial_path = walk_path(grid, start)

    if !part2
        return length(initial_path)
    end

    # approach for part2
    valid_positions = filter(pos -> !is_wall(grid, pos) && pos != start, initial_path)
    sum(pos -> check_loop(grid, start, pos), valid_positions)
end

# Main execution
main(file_path::String) =
    let input = read(file_path, String)
        println("Part 1: ", solve_patrol(input))
        println("Part 2: ", solve_patrol(input, true))
    end

#@time main() 1.872415 seconds (123.10 k allocations: 2.569 GiB, 12.97% gc time)

# Test cases
run_tests() =
    let test_input = """
        ....#.....
        .........#
        ..........
        ..#.......
        .......#..
        ..........
        .#..^.....
        ........#.
        #.........
        ......#..."""

        test_input2 = """
        ....#.....
        ....+---+#
        ....|...|.
        ..#.|...|.
        ..+-+-+#|.
        ..|.|.|.|.
        .#+-^-+-+.
        .+----++#.
        #+----++..
        ......#O.."""

        @testset "Patrol Tests" begin
            @test solve_patrol(test_input) == 41
            @test solve_patrol(test_input2, true) == 6
        end
    end


if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("Provide an input file path or 'test' as argument")
    if ARGS[1] == "test"
        using Test
        run_tests()
    else
        main(ARGS[1])
    end
end
