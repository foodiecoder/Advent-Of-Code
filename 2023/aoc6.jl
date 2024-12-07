function calculate_ways_to_win(time_given, distance)
    sqrt_det = sqrt(time_given^2 - 4distance)
    lower_bound = (time_given - sqrt_det) / 2
    upper_bound = (time_given + sqrt_det) / 2

    # find integer bounds, ensuring we exceed the record distance.
    lower_int = ceil(Int, lower_bound)
    upper_int = floor(Int, upper_bound)

    # adjust if the bounds exactly meet the record distance.
    if lower_int * (time_given - lower_int) <= distance
        lower_int += 1
    end
    if upper_int * (time_given - upper_int) <= distance
        upper_int -= 1
    end

    return upper_int - lower_int + 1
end

function solve_part1(times, distances)
    return prod(calculate_ways_to_win(t, d) for (t, d) in zip(times, distances))
end

function solve_part2(time_given, distance)
    return calculate_ways_to_win(time_given, distance)
end

function parse_input(raw_input)
    times_raw, dists_raw = match(r"Time: +([\d ]+)\nDistance: +([\d| ]+)", raw_input)
    times = parse.(Int, split(times_raw))
    distances = parse.(Int, split(dists_raw))
    return times, distances
end

function run_tests()
    example_input = """Time:      7  15   30
Distance:  9  40  200"""
    times, distances = parse_input(example_input)

    part1_result = solve_part1(times, distances)
    @assert part1_result == 288 "Part 1 example failed"

    big_time = parse(Int, join(string.(times)))
    big_dist = parse(Int, join(string.(distances)))
    part2_result = solve_part2(big_time, big_dist)
    @assert part2_result == 71503 "Part 2 example failed"

    println("All tests passed!")
end

function main(file_path::String)
    raw = readchomp(file_path)
    times, distances = parse_input(raw)

    part1 = solve_part1(times, distances)
    println("Part 1: ", part1)

    big_time = parse(Int, join(string.(times)))
    big_dist = parse(Int, join(string.(distances)))
    part2 = solve_part2(big_time, big_dist)
    println("Part 2: ", part2)
end

# 0.000443 seconds (93 allocations: 3.938 KiB) 0.000445 seconds (95 allocations: 4.016 KiB)

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("Provide an input file path or 'test' as argument")
    if ARGS[1] == "test"
        using Test
        run_tests()
    else
        main(ARGS[1])
    end
end
