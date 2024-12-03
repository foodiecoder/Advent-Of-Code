using Test

# Core processing
function process_mul_instructions(file_path::String, handle_conditions::Bool=false)
    content = read(file_path, String)

    # regular expression to match valid mul instructions
    mul_regex = handle_conditions ?
                r"mul\(\d{1,3},\d{1,3}\)|do\(\)|don't\(\)" :
                r"mul\(\d{1,3},\d{1,3}\)"

    total_sum = 0
    mul_enabled = true

    # process each valid match
    for m in eachmatch(mul_regex, content)
        instruction = m.match
        if startswith(instruction, "mul")
            if mul_enabled
                numbers = chopprefix(instruction, "mul(") |> x -> chop(x)
                x, y = split(numbers, ',')
                total_sum += parse(Int, x) * parse(Int, y)
            end
        elseif handle_conditions
            mul_enabled = instruction == "do()"
        end
    end

    return total_sum
end

# Main function to run both tasks
function main(file_path::String)
    try
        task1_result = process_mul_instructions(file_path)
        println("Task 1 (Basic Multiplication): ", task1_result)

        task2_result = process_mul_instructions(file_path, true)
        println("Task 2 (Conditional Multiplication): ", task2_result)
    catch e
        println("Error processing file: ", e)
    end
end

# Tests
function run_tests()
    @testset "Multiplication Processing Tests" begin
        test_input1 = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"
        test_input2 = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"

        # write test inputs to temporary files
        test_file1 = tempname()
        test_file2 = tempname()
        write(test_file1, test_input1)
        write(test_file2, test_input2)

        # test Task 1
        @test process_mul_instructions(test_file1) == 161  # 2*4 + 11*8 + 8*5

        # test Task 2
        @test process_mul_instructions(test_file2, true) == 48  # 2*4 + 8*5

        # simple test cases
        simple_test = tempname()
        write(simple_test, "mul(44,46)")
        @test process_mul_instructions(simple_test) == 2024

        # Cleanup
        rm.([test_file1, test_file2, simple_test])
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) > 0
        if ARGS[1] == "test"
            using Test
            run_tests()
        else
            main(ARGS[1])
        end
    else
        println("Please provide an input file path or 'test' as argument")
    end
end

#@btime main("2024/data/input3.txt"); 964.258 μs (8599 allocations: 612.98 KiB)


