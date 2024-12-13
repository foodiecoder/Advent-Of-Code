# Reference: https://www.reddit.com/r/adventofcode/comments/1hd4wda/comment/m1tqn1k/
using JuMP
using HiGHS
using Test

function parse_line(line, regex)
    m = match(regex, line)
    m === nothing ? nothing : [parse(Int, x) for x in m.captures]
end

function ParseInput(FileName)
    FileLines = open(FileName) do f
        readlines(f)
    end
    ButtonRegex = r"Button [AB]: X\+(\d+), Y\+(\d+)"
    PrizeRegex = r"Prize: X=(\d+), Y=(\d+)"

    Part1_Problems = Vector{Vector{Vector{Int}}}()
    Part2_Problems = Vector{Vector{Vector{BigInt}}}()

    for i in 1:4:length(FileLines)-2
        AMatch = match(ButtonRegex, FileLines[i])
        BMatch = match(ButtonRegex, FileLines[i+1])
        PrizeMatch = match(PrizeRegex, FileLines[i+2])

        if AMatch !== nothing && BMatch !== nothing && PrizeMatch !== nothing
            # Create problem for Part 1
            NewProblem = [
                parse.(Int, [AMatch.captures[1], AMatch.captures[2]]),
                parse.(Int, [BMatch.captures[1], BMatch.captures[2]]),
                parse.(Int, [PrizeMatch.captures[1], PrizeMatch.captures[2]])
            ]
            push!(Part1_Problems, copy(NewProblem))

            # Convert to BigInt and modify for Part 2
            BigProblem = [
                BigInt.(NewProblem[1]),
                BigInt.(NewProblem[2]),
                BigInt.(NewProblem[3]) .+ [BigInt(10_000_000_000_000), BigInt(10_000_000_000_000)]
            ]
            push!(Part2_Problems, BigProblem)
        end
    end
    Part1_Problems, Part2_Problems
end

function SolveClaw(A::Vector{T}, B::Vector{T}, Prize::Vector{T}, ACost=3, BCost=1) where {T<:Integer}
    model = Model(HiGHS.Optimizer)
    set_silent(model)
    @variable(model, x, Int)
    @variable(model, y, Int)
    @constraint(model, c1, A[1] * x + B[1] * y == Prize[1])
    @constraint(model, c2, A[2] * x + B[2] * y == Prize[2])
    @objective(model, Min, ACost * x + BCost * y)
    optimize!(model)
    x = round(Int, value(x))
    y = round(Int, value(y))
    return A[1] * x + B[1] * y == Prize[1] && A[2] * x + B[2] * y == Prize[2], ACost * x + BCost * y
end

function Solve(PuzzleInput)
    TotalTokens = 0
    for (A, B, Prize) in PuzzleInput
        (IsSolved, Tokens) = SolveClaw(A, B, Prize)
        TotalTokens += IsSolved ? Tokens : 0
    end
    TotalTokens
end

function main(file_path::String)
    @time begin
        problems = ParseInput(file_path)
        part1 = Solve(problems[1])
        part2 = Solve(problems[2])
        println("Part 1: ", part1)
        println("Part 2: ", part2)
    end
end

function run_tests()
    @testset "Claw machine test" begin
        mktempdir() do tmpdir
            test_input = """Button A: X+94, Y+34
                Button B: X+22, Y+67
                Prize: X=8400, Y=5400

                Button A: X+26, Y+66
                Button B: X+67, Y+21
                Prize: X=12748, Y=12176

                Button A: X+17, Y+86
                Button B: X+84, Y+37
                Prize: X=7870, Y=6450

                Button A: X+69, Y+23
                Button B: X+27, Y+71
                Prize: X=18641, Y=10279"""
            input_file = joinpath(tmpdir, "test1.txt")
            write(input_file, test_input)

            problems = ParseInput(input_file)
            println("Part 1: ", Solve(problems[1]))
            println("Part 2: ", Solve(problems[2]))
            @test Solve(problems[1]) == 480
            @test Solve(problems[2]) == 875318608908
        end
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

