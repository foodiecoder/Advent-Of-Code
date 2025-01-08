using Test

@inline function is_compatible(lock, key)
    # If any position has both a lock pin and key pin, they're incompatible
    for idx in eachindex(lock, key)
        if lock[idx] == '#' && key[idx] == '#'
            return false
        end
    end
    return true
end

function count_compatible_pairs(locks, keys)
    count = 0
    for lock in locks
        for key in keys
            if is_compatible(lock, key)
                count += 1
            end
        end
    end
    return count
end

function parse_input(filepath)
    lines = readlines(filepath)
    locks = Vector{Matrix{Char}}()
    keys = Vector{Matrix{Char}}()
    current = Vector{String}()

    for line in lines
        if isempty(line) && !isempty(current)
            # Create matrix by collecting characters and transposing
            matrix = permutedims(reduce(hcat, collect.(current)))
            if current[1][1] == '.'
                push!(keys, matrix)
            else
                push!(locks, matrix)
            end
            current = String[]
            continue
        end
        !isempty(line) && push!(current, line)
    end

    # Handle last group
    if !isempty(current)
        # Create matrix by collecting characters and transposing
        matrix = permutedims(reduce(hcat, collect.(current)))
        if current[1][1] == '.'
            push!(keys, matrix)
        else
            push!(locks, matrix)
        end
    end

    return locks, keys
end

function run_tests()
    @testset "Key/lock Schematics Test" begin
        mktempdir() do tmpdir
            test_input = """
            #####
            .####
            .####
            .####
            .#.#.
            .#...
            .....

            #####
            ##.##
            .#.##
            ...##
            ...#.
            ...#.
            .....

            .....
            #....
            #....
            #...#
            #.#.#
            #.###
            #####

            .....
            .....
            #.#..
            ###..
            ###.#
            ###.#
            #####

            .....
            .....
            .....
            #....
            #.#..
            #.#.#
            #####
            """
            input_file = joinpath(tmpdir, "test1.txt")
            write(input_file, test_input)
            locks, keys = parse_input(input_file)
            @test count_compatible_pairs(locks, keys) == 3
        end
    end
end

function main(filepath)
    @time begin
        locks, keys = parse_input(filepath)
        result = count_compatible_pairs(locks, keys)
        println("Number of compatible lock-key pairs: ", result)
    end
end

# 0.004142 seconds (18.54 k allocations: 823.719 KiB)

if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
    isempty(ARGS) || main(ARGS[1])
end
