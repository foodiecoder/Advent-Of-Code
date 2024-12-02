using Test

function is_safe_report(levels::Vector{Int}, with_dampener::Bool=false)
    length(levels) < 2 && return false

    function _check_levels(levels)
        increasing = decreasing = true
        for i in 1:length(levels)-1
            diff = abs(levels[i] - levels[i+1])
            if diff < 1 || diff > 3
                return false
            end
            # check if the levels are all increasing or decreasing
            increasing = all(levels[i] < levels[i+1] for i in 1:length(levels)-1)
            decreasing = all(levels[i] > levels[i+1] for i in 1:length(levels)-1)
        end
        return increasing || decreasing
    end

    if _check_levels(levels)
        return true
    end

    if with_dampener
        for i in 1:length(levels)
            candidate = [levels[1:i-1]; levels[i+1:end]]
            if _check_levels(candidate)
                return true
            end
        end
    end

    return false
end


function count_safe_reports(filename::String, use_dampener::Bool=false)
    safe_count = 0
    open(filename, "r") do file
        for line in eachline(file)
            # Skip empty lines or handle as needed
            isempty(strip(line)) && continue

            # Split the line into numbers, convert to integers
            levels = map(x -> parse(Int, x), split(line))

            # Only process lines with at least 2 numbers
            if length(levels) >= 2 && is_safe_report(levels, use_dampener)
                safe_count += 1
            end
        end
    end
    return safe_count
end


function main()
    if length(ARGS) == 0
        error("Please provide the input file name.")
    end
    filename = ARGS[1]
    println("Number of safe reports without dampener: ", count_safe_reports(ARGS[1])) # 707.872 μs (5015 allocations: 397.57 KiB)
    println("Number of safe reports with dampener: ", count_safe_reports(ARGS[1], true)) # 1.238 ms (29706 allocations: 1.47 MiB)
end

# Test cases
@testset "Safety Checks" begin
    @test is_safe_report([7, 6, 4, 2, 1]) == true
    @test is_safe_report([1, 2, 7, 8, 9]) == false
    @test is_safe_report([1, 3, 2, 4, 5], true) == true  # Safe with dampener
    @test is_safe_report([8, 6, 4, 4, 1], true) == true  # Safe with dampener
    @test is_safe_report([1, 3, 6, 7, 9]) == true
end

@testset "Count Safe Reports" begin
    test_input = "test_input.txt"
    write(
        test_input,
        """7 6 4 2 1
1 2 7 8 9
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9"""
    )

    @test count_safe_reports(test_input) == 2
    @test count_safe_reports(test_input, true) == 4
    rm(test_input)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) > 0 && ARGS[1] == "test"
        include(@__FILE__)
    else
        main()
    end
end