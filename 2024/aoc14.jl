using Test

const MAX_QUEUE_SIZE = 10_000
const QUEUE = Vector{NTuple{2,Int}}(undef, MAX_QUEUE_SIZE)
const DIRS = [(0, -1), (1, 0), (0, 1), (-1, 0)]

function parse_input(input::String)
    n = count('\n', input) + 1
    positions = Matrix{Int}(undef, 2, n)
    velocities = Matrix{Int}(undef, 2, n)

    pos_pattern = r"(-?\d+),(-?\d+)"
    vel_pattern = r"v=(-?\d+),(-?\d+)"

    i = 1
    for line in eachline(IOBuffer(input))
        pos_match = match(pos_pattern, line)
        vel_match = match(vel_pattern, line)

        @inbounds positions[1, i] = parse(Int, pos_match[1])
        @inbounds positions[2, i] = parse(Int, pos_match[2])
        @inbounds velocities[1, i] = parse(Int, vel_match[1])
        @inbounds velocities[2, i] = parse(Int, vel_match[2])
        i += 1
    end
    positions, velocities
end

@inline function count_quadrants!(positions::Matrix{Int}, room::NTuple{2,Int}, quads::Vector{Int})
    fill!(quads, 0)
    rx, ry = room .÷ 2
    @inbounds for i in 1:size(positions, 2)
        px, py = positions[1, i], positions[2, i]
        quad_idx = if px < rx
            py < ry ? 1 : 3
        else
            py < ry ? 4 : 2
        end
        quads[quad_idx] += 1
    end
    prod(quads)
end

function find_components!(positions::Matrix{Int}, room::NTuple{2,Int},
    visited::BitArray{2}, occupied::BitArray{2},
    queue::Vector{NTuple{2,Int}})
    fill!(visited, false)
    fill!(occupied, false)
    empty!(queue)

    # Fill occupied BitArray
    @inbounds for i in 1:size(positions, 2)
        occupied[positions[1, i]+1, positions[2, i]+1] = true
    end

    # BFS
    start_pos = (2, 2)  # (1,1) with 1-based indexing
    visited[start_pos...] = true
    push!(queue, (1, 1))
    queue_pos = 1
    queue_len = 1

    @inbounds while queue_pos ≤ queue_len
        cur = queue[queue_pos]
        queue_pos += 1

        for dir in DIRS
            next = (cur[1] + dir[1], cur[2] + dir[2])
            next_idx = (next[1] + 1, next[2] + 1)

            if 0 ≤ next[1] < room[1] && 0 ≤ next[2] < room[2] &&
               !visited[next_idx...] && !occupied[next_idx...]
                visited[next_idx...] = true
                queue_len += 1
                queue[queue_len] = next
            end
        end
    end

    outside = count(visited)
    inside = prod(room) - count(occupied) - outside
    min(inside, outside) > 50
end

function simulate!(positions::Matrix{Int}, velocities::Matrix{Int}, room::NTuple{2,Int})
    n_robots = size(positions, 2)
    quads = zeros(Int, 4)
    visited = falses(room...)  # BitArray
    occupied = falses(room...) # BitArray
    queue = resize!(QUEUE, MAX_QUEUE_SIZE)
    part1 = 0

    @inbounds for t in 1:prod(room)
        # SIMD-friendly update
        @simd for i in 1:n_robots
            positions[1, i] = mod(positions[1, i] + velocities[1, i], room[1])
            positions[2, i] = mod(positions[2, i] + velocities[2, i], room[2])
        end

        if t == 100
            part1 = count_quadrants!(positions, room, quads)
        end

        if find_components!(positions, room, visited, occupied, queue)
            return part1, t
        end
    end

    part1, 0
end

function solve(input::String)
    positions, velocities = parse_input(input)
    room = (101, 103)
    simulate!(positions, velocities, room)
end

function run_tests()
    @testset "Restroom Robot Safety Test" begin
        test_input = """
        p=0,4 v=3,-3
        p=6,3 v=-1,-3
        p=10,3 v=-1,2
        p=2,0 v=2,-1
        p=0,0 v=1,3
        p=3,0 v=-2,-2
        p=7,6 v=-1,-3
        p=3,0 v=-1,-2
        p=9,3 v=2,3
        p=7,3 v=-1,2
        p=2,4 v=2,-3
        p=9,5 v=-3,-3"""
        part1, part2 = solve(test_input)
        @test part1 == 21
    end
end

function main(file_path::String)
    input = read(file_path, String)
    @time begin
        part1, part2 = solve(input)
        println("Result: $part1, $part2")
    end
end

#main("2024/data/input14.txt"); # 0.848516 seconds (8.71 k allocations: 373.180 KiB)

if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
    isempty(ARGS) || main(ARGS[1])
end


#=
Key optimizations in this final version:

1. Used BitArrays instead of Sets for visited and occupied
2. Pre-allocated static QUEUE with constant size
3. Used SIMD-friendly loops with @simd
4. Implemented custom queue management in find_components! to avoid allocations
5. Used more efficient patterns matching in parse_input
6. Minimized array creation and copying
7. Used in-place operations wherever possible
8. Optimized memory layout with Matrix{Int} instead of Vector{Vector}
9. Added bounds checking elimination with @inbounds
10. Used constant folding with const declarations
11. Improved spatial locality in data structures


This version should show significantly reduced allocation size and GC time compared to previous versions. The main improvements come from:
- Using BitArrays for set operations
- Static pre-allocation of large data structures
- In-place operations
- Efficient queue management
- SIMD optimization
- Memory layout optimization

# reference: https://www.reddit.com/r/adventofcode/comments/1hdvhvu/comment/m1zk5yf/

"Print a matrix"
function pm(m, sep=" ")
    println.(join.(eachrow(m), sep))
    nothing
end

const dirs = [(-1, 0), (0, 1), (1, 0), (0, -1)]

function read_puzzle(file)
    p = []
    v = []
    for l in eachline(file)
        px, py, vx, vy = match(r"p=(-?\d+),(-?\d+) v=(-?\d+),(-?\d+)", l)
        push!(p, [parse(Int, px), parse(Int, py)])
        push!(v, (parse(Int, vx), parse(Int, vy)))
    end
    p, v
end

function count_quadrants(p, room)
    quads = zeros(Int, 4)
    for robot in p
        if robot[1] < room[1] ÷ 2 && robot[2] < room[2] ÷ 2
            quads[1] += 1
        elseif robot[1] > room[1] ÷ 2 && robot[2] > room[2] ÷ 2
            quads[2] += 1
        elseif robot[1] < room[1] ÷ 2 && robot[2] > room[2] ÷ 2
            quads[3] += 1
        elseif robot[1] > room[1] ÷ 2 && robot[2] < room[2] ÷ 2
            quads[4] += 1
        end
    end
    prod(quads)
end

function components(p, room)
    occupied = Set(Tuple.(p))
    Q = [(1, 1)]
    visited = Set(Q)
    while length(Q) > 0
        cur = popfirst!(Q)
        for dir in dirs
            if all(0 .<= cur .+ dir .< room) && !(cur .+ dir in visited) && !(cur .+ dir in occupied)
                push!(visited, cur .+ dir)
                push!(Q, cur .+ dir)
            end
        end
    end
    outside = length(visited)
    inside = prod(room) - length(occupied) - length(visited)
    if min(inside, outside) > 50
        m = fill('.', room)
        for robot in p
            m[(robot .+ 1)...] = '#'
        end
        pm(permutedims(m), "")
        return true
    end
    return false
end

function simulate!(p, v)
    room = (101, 103)
    for t in 1:prod(room)
        for robot in eachindex(p)
            @. p[robot] += v[robot]
            @. p[robot] = mod(p[robot], room)
        end
        if t == 100
            p1 = count_quadrants(p, room)
            println("Part 1: $p1")
        end
        if components(p, room)
            print("Is this a Christmas tree? [y/N]")
            if startswith(readline(), "y")
                println("Part 2: $t")
                break
            end
        end
    end
end

p, v = read_puzzle(ARGS[1])
#p, v = read_puzzle(open("2024/data/input14.txt"))
@time simulate!(p, v)
=#
