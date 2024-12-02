using Pkg
function check_packages()
    required_packages = ["StatsBase", "DelimitedFiles"]
    for pkg in required_packages
        try
            @eval import $(Symbol(pkg))
        catch
            Pkg.add(pkg)
            @eval import $(Symbol(pkg))
        end
    end
end

# Call the function to check and install packages
check_packages()

using StatsBase
using DelimitedFiles
using Test

function calculate_total_distance(left_list::AbstractVector{Int}, right_list::AbstractVector{Int})
    sort!(left_list)
    sort!(right_list)
    return sum(abs.(left_list .- right_list))
end

function calculate_similarity_score(left_list::AbstractVector{Int}, right_list::AbstractVector{Int})
    if isempty(left_list) || isempty(right_list)
        return 0
    end

    right_frequency = countmap(right_list)
    return sum(num * get(right_frequency, num, 0) for num in left_list)
end

function read_and_calculate(filename::String)
    try
        data = readdlm(filename, Int)
    catch e
        if isa(e, SystemError)
            rethrow(e)
        else
            throw(SystemError("Error reading file: $e"))
        end
    end

    # split into left and right lists
    left_list, right_list = view(data, :, 1), view(data, :, 2)

    total_distance = calculate_total_distance(left_list, right_list)
    similarity_score = calculate_similarity_score(left_list, right_list)

    return total_distance, similarity_score
end

function main()
    filename = "data/input1.txt"
    total_distance, similarity_score = @btime read_and_calculate($filename)
    println("Total Distance: ", total_distance)
    println("Similarity Score: ", similarity_score)
end

# Test Function
if abspath(PROGRAM_FILE) == @__FILE__
    @testset "List Processing Tests" begin
        # Test calculate_total_distance
        @testset "Total Distance Calculation" begin
            @test calculate_total_distance([1, 2, 3], [2, 3, 4]) == 3
            @test calculate_total_distance([1, 1, 1], [2, 2, 2]) == 3
            @test calculate_total_distance([5, 3, 1], [2, 4, 6]) == 3
            @test calculate_total_distance(Int[], Int[]) == 0
            @test calculate_total_distance([1], [1]) == 0
        end

        # Test calculate_similarity_score
        @testset "Similarity Score Calculation" begin
            @test calculate_similarity_score([1, 2, 3], [1, 2, 3]) == 6
            @test calculate_similarity_score([1, 1, 1], [1, 1, 1]) == 9
            @test calculate_similarity_score([2, 2, 2], [1, 1, 1]) == 0
            @test calculate_similarity_score([1, 2], [2, 2]) == 4
        end

        # Test read_and_calculate with test file
        @testset "File Processing" begin
            # Create test file
            test_filename = "test_input.txt"
            test_data = [
                1 2
                3 4
                5 6
                2 2
                4 4
            ]
            writedlm(test_filename, test_data)
            try
                total_distance, similarity_score = read_and_calculate(test_filename)
                @test total_distance == 3  # Sum of absolute differences
                @test similarity_score == 12  # Sum of matching frequencies
            finally
                rm(test_filename)
            end
        end

        # Test edge cases
        @testset "Edge Cases" begin
            # Large numbers
            @test calculate_total_distance([1000000], [1000001]) == 1
            @test calculate_similarity_score([999999], [999999]) == 999999

            # Negative numbers
            @test calculate_total_distance([-1, -2], [-2, -1]) == 0
            @test calculate_similarity_score([-1, -2], [-1, -2]) == -3

            # Mixed positive and negative
            @test calculate_total_distance([-1, 1], [1, -1]) == 0
            @test calculate_similarity_score([-1, 1], [-1, 1]) == 0
        end
    end
end

# Main execution logic for tests
if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) >= 1
        if ARGS[1] == "test"
            using Test
            if length(ARGS) == 1
                # Run all tests
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
        main()
    end
end

