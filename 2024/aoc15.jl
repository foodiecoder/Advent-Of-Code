# Reference: https://github.com/fmarotta/AoC/blob/main/2024/day15/run.jl

using Test

const dirs = CartesianIndex.([(-1, 0), (0, 1), (1, 0), (0, -1)])
const mov2dir = Dict('^' => dirs[1], '>' => dirs[2], 'v' => dirs[3], '<' => dirs[4])

function read_puzzle(input::String)
    input = read(input, String)
    parts = split(input, "\n\n")
    room = parts[1]
    moves = length(parts) > 1 ? parts[2] : ""
    lines = split(room, "\n")
    m = [lines[i][j] for i in eachindex(lines), j in eachindex(lines[1])]
    moves = replace(moves, r"[\s\n]" => "")
    start = findfirst(==('@'), m)
    m[start] = '.'
    return m, start, moves
end

function find_connected_group(m, pos, dir)
    group = Set{CartesianIndex{2}}()
    stack = [pos]

    while !isempty(stack)
        current = pop!(stack)
        current in group && continue
        !checkbounds(Bool, m, current) && continue

        if m[current] == '['
            push!(group, current)
            next = current + dirs[2]  # Right connection
            if checkbounds(Bool, m, next) && m[next] == ']'
                push!(group, next)
                push!(stack, current + dir)  # Forward connection
                push!(stack, next + dir)     # Forward from right piece
            end
        elseif m[current] == ']'
            push!(group, current)
            prev = current + dirs[4]  # Left connection
            if checkbounds(Bool, m, prev) && m[prev] == '['
                push!(group, prev)
                push!(stack, current + dir)  # Forward connection
                push!(stack, prev + dir)     # Forward from left piece
            end
        end
    end
    return group
end

function can_move_group(m, group, dir)
    for pos in group
        next = pos + dir
        if !checkbounds(Bool, m, next) || m[next] == '#'
            return false
        end
        if m[next] in ('[', ']') && !(next in group)
            return false
        end
    end
    return true
end

function simulate_robot(m, cur, moves, is_part2)
    for mov in moves
        dir = mov2dir[mov]
        next = cur + dir

        if m[next] == '.'
            cur = next
            continue
        end

        if !is_part2 && m[next] == 'O'
            push_pos = next + dir
            while checkbounds(Bool, m, push_pos) && m[push_pos] == 'O'
                push_pos += dir
            end
            if checkbounds(Bool, m, push_pos) && m[push_pos] == '.'
                while push_pos != next
                    m[push_pos], m[push_pos-dir] = m[push_pos-dir], m[push_pos]
                    push_pos -= dir
                end
                cur = next
            end
        elseif is_part2 && m[next] in ('[', ']')
            group = find_connected_group(m, next, dir)
            if !isempty(group) && can_move_group(m, group, dir)
                # Store current state and move pieces
                moves_to_make = [(pos, m[pos]) for pos in group]
                for (pos, _) in moves_to_make
                    m[pos] = '.'
                end
                for (pos, type) in moves_to_make
                    m[pos+dir] = type
                end
                cur = next
            end
        end
    end

    total = 0
    for col in 2:size(m, 2)-1, row in 2:size(m, 1)-1
        if is_part2
            if m[row, col] == '[' && col < size(m, 2) && m[row, col+1] == ']'
                total += 100 * (row - 1) + (col - 1)
            end
        else
            if m[row, col] == 'O'
                total += 100 * (row - 1) + (col - 1)
            end
        end
    end
    return total
end

function expand_map(m)
    newcols = []
    for col in eachcol(m)
        push!(newcols, replace(col, 'O' => '['))
        push!(newcols, replace(col, 'O' => ']'))
    end
    reduce(hcat, newcols)
end

function predict_gps(input::String)
    m, start, moves = read_puzzle(input)
    part1 = simulate_robot(copy(m), start, moves, false)
    expanded_m = expand_map(m)
    expanded_start = CartesianIndex(start[1], 2start[2] - 1)
    part2 = simulate_robot(expanded_m, expanded_start, moves, true)
    return part1, part2
end

function run_tests()
    @testset "Predict GPS" begin
        mktempdir() do tmpdir
            test_input = """
            ##########
            #..O..O.O#
            #......O.#
            #.OO..O.O#
            #..O@..O.#
            #O#..O...#
            #O..O..O.#
            #.OO.O.OO#
            #....O...#
            ##########

            <vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
            vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
            ><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
            <<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
            ^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
            ^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
            >^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
            <><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
            ^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
            v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
            """
            input_file = joinpath(tmpdir, "test1.txt")
            write(input_file, test_input)
            part1, part2 = predict_gps(input_file)
            @test part1 == 10092
            @test part2 == 9021
        end
    end
end

function main(input::String)
    @time begin
        #input = read(input, String)
        part1, part2 = predict_gps(input)
        println("Part 1: $part1\nPart 2: $part2")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    using Test
    run_tests()
    isempty(ARGS) || main(ARGS[1])
end

# 0.002928 seconds (20.97 k allocations: 3.027 MiB)

