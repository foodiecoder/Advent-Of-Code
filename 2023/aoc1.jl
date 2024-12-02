using Test

# Main code functions
function get_digit(s::AbstractString, i::Int, digit_map::Dict{String,Int})
    c = s[i]
    isdigit(c) && return c - '0'
    for (word, num) in digit_map
        if i + length(word) - 1 <= length(s) && @view(s[i:i+length(word)-1]) == word
            return num
        end
    end
    return nothing
end

function find_first_last_digits(line::String, digit_map::Dict{String,Int}=Dict{String,Int}())
    n = length(line)
    first_digit = last_digit = 0

    # Find first digit
    for i in 1:n
        digit = get_digit(line, i, digit_map)
        if !isnothing(digit)
            first_digit = digit
            break
        end
    end

    # Find last digit
    for i in n:-1:1
        digit = get_digit(line, i, digit_map)
        if !isnothing(digit)
            last_digit = digit
            break
        end
    end

    return 10 * first_digit + last_digit
end

function read_and_calculate(filename::String)
    input = readlines(filename)
    part1 = sum(line -> find_first_last_digits(line), input)

    digit_map = Dict(
        "one" => 1, "two" => 2, "three" => 3, "four" => 4, "five" => 5,
        "six" => 6, "seven" => 7, "eight" => 8, "nine" => 9
    )

    part2 = sum(line -> find_first_last_digits(line, digit_map), input)
    return part1, part2
end

# Main function
function main()
    filename = "2023/data/input1.txt"
    part1, part2 = read_and_calculate(filename)
    println("Part 1: ", part1)
    println("Part 2: ", part2)
end


# Test section
if abspath(PROGRAM_FILE) == @__FILE__
    @testset "Trebuchet Tests" begin
        digit_map = Dict(
            "one" => 1, "two" => 2, "three" => 3, "four" => 4, "five" => 5,
            "six" => 6, "seven" => 7, "eight" => 8, "nine" => 9
        )

        @testset "get_digit" begin
            @test get_digit("123", 1, digit_map) == 1
            @test get_digit("one23", 1, digit_map) == 1
            @test get_digit("two34", 1, digit_map) == 2
            @test isnothing(get_digit("abc", 1, digit_map))
        end

        @testset "find_first_last_digits" begin
            # Part 1 tests
            @test find_first_last_digits("1abc2") == 12
            @test find_first_last_digits("pqr3stu8vwx") == 38
            @test find_first_last_digits("treb7uchet") == 77

            # Part 2 tests
            @test find_first_last_digits("two1nine", digit_map) == 29
            @test find_first_last_digits("eightwothree", digit_map) == 83
            @test find_first_last_digits("abcone2threexyz", digit_map) == 13
        end

        @testset "Edge Cases" begin
            @test find_first_last_digits("") == 0
            @test find_first_last_digits("abc") == 0
            @test find_first_last_digits("5") == 55
            @test find_first_last_digits("oneight", digit_map) == 18
        end

        @testset "File Processing" begin
            # Create temporary test files
            test_file1 = "test_input1.txt"
            test_content1 = """
            1abc2
            pqr3stu8vwx
            a1b2c3d4e5f
            treb7uchet
            """
            write(test_file1, test_content1)

            test_file2 = "test_input2.txt"
            test_content2 = """
            two1nine
            eightwothree
            abcone2threexyz
            xtwone3four
            4nineeightseven2
            zoneight234
            7pqrstsixteen
            """
            write(test_file2, test_content2)

            try
                # Test file 1 (numbers only)
                part1_1, part2_1 = read_and_calculate(test_file1)
                @test part1_1 == 142  # Sum of 12 + 38 + 15 + 77

                # Test file 2 (mixed numbers and words)
                part1_2, part2_2 = read_and_calculate(test_file2)
                @test part2_2 == 281  # Expected sum for part 2
            finally
                rm(test_file1)
                rm(test_file2)
            end
        end

        @testset "Complex Patterns" begin
            @test find_first_last_digits("onetwothreefourfivesixseveneightnine", digit_map) == 19
            @test find_first_last_digits("nine8sevenoneight", digit_map) == 98
            @test find_first_last_digits("1two3four5six7eight9", digit_map) == 19
            @test find_first_last_digits("mixedonethreefive2seven", digit_map) == 17
        end

        @testset "Overlapping Numbers" begin
            @test find_first_last_digits("oneight", digit_map) == 18
            @test find_first_last_digits("twone", digit_map) == 21
            @test find_first_last_digits("eightwo", digit_map) == 82
            @test find_first_last_digits("nineight", digit_map) == 98
            @test find_first_last_digits("sevenineight", digit_map) == 78
        end

        @testset "Special Cases" begin
            @test find_first_last_digits("one1one", digit_map) == 11
            @test find_first_last_digits("two2two", digit_map) == 22
            @test find_first_last_digits("three3three", digit_map) == 33
            @test find_first_last_digits("", digit_map) == 0
            @test find_first_last_digits("nodigits", digit_map) == 0
            @test find_first_last_digits("ONE", digit_map) == 0  # Case sensitivity
        end

        @testset "Performance" begin
            # Create a large input file
            large_file = "large_test_input.txt"
            large_content = join(repeat(["1two3four5six7eight9\n"], 1000))
            write(large_file, large_content)

            try
                # Test performance with large input
                @time begin
                    part1, part2 = read_and_calculate(large_file)
                    @test part1 == 19000  # (19 * 1000)
                    @test part2 == 19000  # (19 * 1000)
                end
            finally
                rm(large_file)
            end
        end

        @testset "Error Handling" begin
            @test_throws SystemError read_and_calculate("nonexistent_file.txt")
            @test isnothing(get_digit("abc", 1, digit_map))
            @test isnothing(get_digit("ONE", 1, digit_map))
        end
    end  # End of main testset

    @testset "Benchmark Tests" begin
        # Test performance characteristics
        test_file = "benchmark_test.txt"

        # Create test data with various sizes
        function create_test_data(n::Int)
            patterns = [
                "1abc2\n",
                "two1nine\n",
                "abcone2threexyz\n",
                "xtwone3four\n",
                "4nineeightseven2\n",
                "zoneight234\n",
                "7pqrstsixteen\n"
            ]
            return join(repeat(patterns, n))
        end

        sizes = [10, 100, 1000]
        times = Float64[]

        for size in sizes
            content = create_test_data(size)
            write(test_file, content)

            try
                time = @elapsed read_and_calculate(test_file)
                push!(times, time)

                # Basic performance assertions
                @test time < 1.0  # Should process within 1 second
                if size > 10
                    # Check for roughly linear scaling
                    @test times[end] / times[end-1] < size * 1.5
                end
            finally
                rm(test_file)
            end
        end
    end
end

# Only run main if not being tested
if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) > 0 && ARGS[1] == "test"
        # Run tests
        using Test
        @testset "All Tests" begin
            include(@__FILE__)
        end
    else
        # Run main program
        main()
    end
end

# Helper function to run specific test groups
function run_specific_tests(test_groups::Vector{String})
    for group in test_groups
        @testset "$group" begin
            if group == "basic"
                @testset "Basic Tests" begin
                    digit_map = Dict(
                        "one" => 1, "two" => 2, "three" => 3, "four" => 4, "five" => 5,
                        "six" => 6, "seven" => 7, "eight" => 8, "nine" => 9
                    )
                    @test get_digit("123", 1, digit_map) == 1
                    @test find_first_last_digits("1abc2") == 12
                end
            elseif group == "edge"
                @testset "Edge Cases" begin
                    @test find_first_last_digits("") == 0
                    @test find_first_last_digits("abc") == 0
                end
            elseif group == "performance"
                @testset "Performance Tests" begin
                    @time read_and_calculate("test_input.txt")
                end
            end
        end
    end
end

"""
Usage:
    - Run main program: julia script.jl
    - Run all tests: julia script.jl test
    - Run specific tests: julia script.jl test basic edge performance
"""
if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) >= 1
        if ARGS[1] == "test"
            if length(ARGS) == 1
                # Run all tests
                using Test
                @testset "All Tests" begin
                    include(@__FILE__)
                end
            else
                # Run specific test groups
                run_specific_tests(ARGS[2:end])
            end
        else
            println("Invalid argument. Use 'test' to run tests.")
        end
    else
        # Run main program
        main()
    end
end

