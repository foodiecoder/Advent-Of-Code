using Test
# Evaluate for Task 1 (+ and * only)
function evaluate_task1(nums::Vector{Int}, i::Int, n::Int)::Int
    result = nums[1]
    temp = i
    for j in 1:n
        op = (temp >> (j - 1)) & 1
        next = nums[j+1]
        result = op == 0 ? result + next : result * next
    end
    result
end

# Evaluate for Task 2 (+, *, and ||)
function evaluate_task2(nums::Vector{Int}, i::Int, n::Int)::Int
    result = nums[1]
    temp = i
    for j in 1:n
        op = temp % 3
        temp ÷= 3
        next = nums[j+1]
        result = op == 0 ? result + next :
                 op == 1 ? result * next :
                 #parse(Int, string(result, next)) # string concatenation
                 result * 10^(ndigits(next)) + next # no string allocation
    end
    result
end

# Solver for both tasks
function solve_equations(input::AbstractString, task::Int)::Int
    sum = 0
    for line in (isfile(input) ? eachline(input) : split(input, '\n'))
        isempty(line) && continue
        target_str, nums_str = split(line, ": ")
        target = parse(Int, target_str)
        nums = parse.(Int, split(nums_str))
        n = length(nums) - 1

        # Choose evaluation based on task
        if task == 1
            for i in 0:2^n-1
                evaluate_task1(nums, i, n) == target && (sum += target; break)
            end
        else
            for i in 0:3^n-1
                evaluate_task2(nums, i, n) == target && (sum += target; break)
            end
        end
    end
    sum
end

function run_tests()
    @testset "Task 1 Tests" begin
        test_cases1 = Dict(
            "190: 10 19" => 190,
            "3267: 81 40 27" => 3267,
            "292: 11 6 16 20" => 292
        )
        for (input, expected) in test_cases1
            @test solve_equations(input, 1) == expected
        end
    end

    @testset "Task 2 Tests" begin
        test_cases2 = Dict(
            "156: 15 6" => 156,
            "7290: 6 8 6 15" => 7290,
            "192: 17 8 14" => 192
        )
        for (input, expected) in test_cases2
            @test solve_equations(input, 2) == expected
        end
    end
end

function main(file_path::String)
    task1 = solve_equations(file_path, 1)
    task2 = solve_equations(file_path, 2)

    println("Task 1 Result: ", task1)
    println("Task 2 Result: ", task2)
end

#@time main();
# parse(String concatenation)->11.409254 seconds (306.20 M allocations: 9.131 GiB, 6.41% gc time)
# Integer arithmetic(mathematical operations)->0.906755 seconds (26.35 k allocations: 2.348 MiB)

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("Provide an input file path or 'test' as argument")
    if ARGS[1] == "test"
        using Test
        run_tests()
    else
        main(ARGS[1])
    end
end

