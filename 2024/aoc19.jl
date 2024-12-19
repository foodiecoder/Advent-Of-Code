using Test

function count_ways(design::SubString{String}, idx::Int, patterns::Vector{SubString{String}}, memo::Dict{Int,Int})::Int
    # Check memoized results for current position
    haskey(memo, idx) && return memo[idx]

    # Base case: reached end of string
    idx > length(design) && return 1

    ways = 0
    design_len = length(design)

    # Try matching patterns at current position
    @inbounds for pattern in patterns
        plen = length(pattern)
        end_idx = idx + plen - 1

        # Skip if pattern is too long
        end_idx > design_len && continue

        # Check if pattern matches at current position
        matches = true
        @inbounds for i in 0:(plen-1)
            if design[idx+i] != pattern[i+1]
                matches = false
                break
            end
        end

        matches && (ways += count_ways(design, idx + plen, patterns, memo))
    end

    memo[idx] = ways
    return ways
end

function solve_towel_patterns(input_file::String)::Tuple{Int,Int}
    patterns = SubString{String}[]
    designs = SubString{String}[]

    # Preallocate buffers
    open(input_file) do f
        pattern_line = readline(f)
        sizehint!(patterns, count(==(','), pattern_line) + 1)
        append!(patterns, (SubString(p) for p in split(pattern_line, ", ")))

        # Read designs
        for line in eachline(f)
            isempty(strip(line)) && continue
            push!(designs, SubString(line))
        end
    end

    possible_count = 0
    total_ways = 0
    memo = Dict{Int,Int}()

    # Process each design
    @inbounds for design in designs
        empty!(memo)
        ways = count_ways(design, 1, patterns, memo)
        if ways > 0
            possible_count += 1
            total_ways += ways
        end
    end

    return possible_count, total_ways
end

function run_tests()
    @testset "Towel Patterns Solver" begin
        mktempdir() do tmpdir
            test_input = """
                    r, wr, b, g, bwu, rb, gb, br

                    brwrr
                    bggr
                    gbbr
                    rrbgbr
                    ubwu
                    bwurrg
                    brgr
                    bbrgwb
                    """
            input_file = joinpath(tmpdir, "test1.txt")
            write(input_file, test_input)
            part1, part2 = solve_towel_patterns(input_file)
            @test part1 == 6
            @test part2 == 16
        end
    end
end

function main(filename::String)
    @time begin
        part1, part2 = solve_towel_patterns(filename)
        println("Part 1: $part1")
        println("Part 2: $part2")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
    isempty(ARGS) || main(ARGS[1])
end

