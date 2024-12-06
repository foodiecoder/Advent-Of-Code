#=
using Graphs

function parse_input(input::String)
    rules_str, updates_str = split(strip(input), "\n\n")

    # Parse rules
    rules = Dict{Int,Set{Int}}()
    for rule in split(rules_str, "\n")
        before, after = parse.(Int, split(rule, "|"))
        if !haskey(rules, before)
            rules[before] = Set{Int}()
        end
        push!(rules[before], after)
    end

    # Parse updates
    updates = [[parse(Int, x) for x in split(update, ',')]
               for update in split(updates_str, "\n") if !isempty(update)]

    return rules, updates
end

function is_valid_order(pages::Vector{Int}, rules::Dict{Int,Set{Int}})
    page_positions = Dict(page => i for (i, page) in enumerate(pages))

    for (before, afters) in rules
        if haskey(page_positions, before)
            for after in afters
                if haskey(page_positions, after)
                    if page_positions[before] > page_positions[after]
                        return false
                    end
                end
            end
        end
    end
    return true
end

function part1(input::String)
    rules, updates = parse_input(input)
    result = 0

    for update in updates
        if is_valid_order(update, rules)
            middle_idx = div(length(update), 2) + 1
            result += update[middle_idx]
        end
    end

    return result
end

function create_graph(pages::Set{Int}, rules::Dict{Int,Set{Int}})
    n = maximum(pages)
    g = SimpleDiGraph(n)

    for (before, afters) in rules
        if before in pages
            for after in afters
                if after in pages
                    add_edge!(g, before, after)
                end
            end
        end
    end

    return g
end

function part2(input::String)
    rules, updates = parse_input(input)
    result = 0

    for update in updates
        if !is_valid_order(update, rules)
            pages = Set(update)
            g = create_graph(pages, rules)
            ordered = topological_sort(g)

            # Filter ordered to only include pages from the update
            ordered = filter(x -> x in pages, ordered)

            if length(ordered) == length(pages)
                middle_idx = div(length(ordered), 2) + 1
                result += ordered[middle_idx]
            end
        end
    end

    return result
end

# Main execution
function main(file_path::String)
    input = read(file_path, String)
    println("Part 1: ", part1(input))
    println("Part 2: ", part2(input))
end

@time main("2024/data/input5.txt") # 0.008185 seconds (58.81 k allocations: 5.249 MiB)
=#

using Graphs
using Test

function solve(input::String)
    rules, updates = split(strip(input), "\n\n")
    # create dependency matrix
    deps = let pairs = [parse.(Int, split(r, '|')) for r in split(rules, '\n')]
        n = maximum(maximum.(pairs))
        foldl(pairs; init=zeros(Int, n, n)) do m, (x, y)
            m[x, y] = 1
            m
        end
    end

    updates = filter!(!isempty, [parse.(Int, split(u, ',')) for u in split(updates, '\n')])

    # helper functions
    middle(x) = x[div(length(x) + 1, 2)]
    is_valid(u) = all(i -> deps[u[i+1], u[i]] == 0, 1:length(u)-1)

    # process invalid updates
    function order_update(update)
        g = SimpleDiGraph(100)  # Ensure graph is large enough
        # Add all vertices first
        for v in update
            add_vertex!(g)
        end

        # add edges based on dependencies
        for i in 1:length(update)
            for j in 1:length(update)
                if i != j && deps[update[j], update[i]] == 1
                    add_edge!(g, update[i], update[j])
                end
            end
        end

        try
            sorted = topological_sort(g)
            # map back to original numbers and filter
            ordered = filter(∈(update), sorted)
            return middle(ordered)
        catch
            # If there's a cycle, return the middle of original sequence
            return middle(update)
        end
    end

    # Return results
    valid_updates = filter(is_valid, updates)
    invalid_updates = filter(!is_valid, updates)

    (
        sum(middle, valid_updates),
        sum(order_update, invalid_updates)
    )
end

function main(file_path::String)
    input = read(file_path, String)
    valid_sum, invalid_sum = solve(input)
    println("Task 1: Sum of middle page numbers for valid updates = $valid_sum")
    println("Task 2: Sum of middle page numbers for invalid updates after ordering = $invalid_sum")
end

@time main("2024/data/input5.txt") # 0.003331 seconds (48.89 k allocations: 4.575 MiB)

# Tests
function run_tests()

    @testset "Printing Order Tests" begin
        test_input = """
        47|53
        97|13
        97|61
        97|47
        75|29
        61|13
        75|53
        29|13
        97|29
        53|29
        61|53
        97|53
        61|29
        47|13
        75|47
        97|75
        47|61
        75|61
        47|29
        75|13
        53|13

        75,47,61,53,29
        97,61,53,29,13
        75,29,13
        75,97,47,61,53
        61,13,29
        97,13,75,29,47
        """
        valid_sum, invalid_sum = solve(test_input)
        @test valid_sum == 143
        @test invalid_sum == 123
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
