
# Reference: https://www.reddit.com/r/adventofcode/comments/1hbm0al/comment/m1hjirm/

using Memoization
using Test

@memoize Dict function blink(stone::Int, depth::Int, mode::Symbol=:part1)::Int
    depth == 0 && return 1

    if stone == 0
        return blink(1, depth - 1, mode)
    else
        digits = ceil(Int, log10(stone + 1))
        if iseven(digits)
            n = 10^(digits >> 1)
            return blink(stone ÷ n, depth - 1, mode) + blink(stone % n, depth - 1, mode)
        else
            return blink(stone * 2024, depth - 1, mode)
        end
    end
end

function solve_stones(input_file::String)::Tuple{Int,Int}
    stones = input_file |> read |> String |> split .|> x -> parse(Int, x)

    part1 = sum(stone -> blink(stone, 25, :part1), stones)
    part2 = sum(stone -> blink(stone, 75, :part2), stones)

    (part1, part2)
end

function run_tests()
    @testset "Stone Blink Tests" begin
        mktempdir() do tmpdir
            test_input = "1 2024 1 0 9 9 2021976"
            input_file = joinpath(tmpdir, "test1.txt")
            write(input_file, test_input)

            part1, part2 = solve_stones(input_file)

            @test part1 == 189541
            @test part2 == 226596360258785
        end
    end
end

function main(file_path::String)
    @time begin
        part1, part2 = solve_stones(file_path)
        println("Stones after 25 blinks: $part1")
        println("Stones after 75 blinks: $part2")
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
