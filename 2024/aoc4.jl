using Test

function find_xmas(matrix)
    # Define all possible directions using CartesianIndices
    directions = filter(x -> x ≠ CartesianIndex(0, 0), CartesianIndices((-1:1, -1:1)))
    positions = CartesianIndices(size(matrix))

    # Function to check if XMAS exists starting from a position in a direction
    function check_xmas(pos, dir)
        try
            return all(i -> matrix[pos+(i-1)*dir] == "XMAS"[i], 1:4)
        catch
            return false
        end
    end

    # Count XMAS occurrences
    count = sum(
        pos -> sum(dir -> check_xmas(pos, dir) ? 1 : 0, directions),
        positions
    )

    return count
end


function find_xmas_x_pattern(matrix)
    rows, cols = size(matrix)
    positions = CartesianIndices((rows, cols))

    function check_pattern(pos)
        row, col = Tuple(pos)
        if row > 1 && row < rows && col > 1 && col < cols && matrix[pos] == 'A'
            tl = matrix[row-1, col-1]
            tr = matrix[row-1, col+1]
            bl = matrix[row+1, col-1]
            br = matrix[row+1, col+1]
            patterns = [(tl, tr, bl, br) == ('M', 'S', 'M', 'S'),
                (tl, tr, bl, br) == ('M', 'M', 'S', 'S'),
                (tl, tr, bl, br) == ('S', 'M', 'S', 'M'),
                (tl, tr, bl, br) == ('S', 'S', 'M', 'M')]
            return sum(patterns)
        end
        return 0
    end

    count = sum(check_pattern(pos) for pos in positions)
    return count
end # 0.050014 seconds (11.80 k allocations: 620.320 KiB)

function main(file_path::String)
    # Read input and convert to matrix
    input = readlines(file_path)
    #matrix = permutedims(reduce(hcat, collect.(input))) # 0.040038 seconds (2.15 k allocations: 320.055 KiB)
    matrix = (permutedims ∘ stack)(collect, input) # 0.038780 seconds (2.15 k allocations: 318.883 KiB)
    # Find and return the count of XMAS occurrences
    task1 = find_xmas(matrix)
    task2 = find_xmas_x_pattern(matrix)
    println("Number of XMAS occurrences: $task1")
    println("Number of XMAS-X occurrences: $task2")
end

# Tests
function run_tests()
    test_cases = [
        # Regular XMAS test
        ("""
        ..X...
        .SAMX.
        .A..A.
        XMAS.S
        .X....""", 2, 0),

        # X-MAS test
        ("""
        M.S
        .A.
        M.S""", 0, 1)
    ]

    @testset "Pattern Tests" begin
        for (input, expected_xmas) in test_cases
            matrix = (permutedims ∘ stack)(collect, input)
            xmas = find_xmas(matrix)
            @test xmas == expected_xmas
        end
    end
end

# Run everything
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


