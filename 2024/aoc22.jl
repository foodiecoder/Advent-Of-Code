# Reference: https://github.com/fmarotta/AoC/blob/main/2024/day22/run.jl

using Test

const MODULO = 2^24
const NUM_ITERATIONS = 2000

@inline function evolve(sn::Int)::Int
    n = sn << 6
    sn = xor(n, sn) % MODULO
    n = sn >> 5
    sn = xor(n, sn) % MODULO
    n = sn << 11
    xor(n, sn) % MODULO
end

function parse_market(io::IO)::Vector{Int}
    parse.(Int, readlines(io))
end

function calculate_price_changes!(sn::Int, prices::Vector{Int}, changes::Vector{Int})::Int
    prev = sn % 10
    @inbounds for i in eachindex(prices)
        sn = evolve(sn)
        curr = sn % 10
        prices[i] = curr
        changes[i] = curr - prev
        prev = curr
    end
    sn
end

function part1(numbers::Vector{Int})::Int
    result = 0
    @inbounds for sn in numbers
        current = sn
        for _ in 1:NUM_ITERATIONS
            current = evolve(current)
        end
        result += current
    end
    result
end

#=
function find_max_bananas(prices::Vector{Int}, changes::Vector{Int}, sequences::Dict{Int,Int})
    seen = Set{Int}()

    @inbounds for j in 1:NUM_ITERATIONS-3
        # Create a unique key for the sequence using bit manipulation
        # Since changes are small integers (-9 to 9), we can pack them efficiently
        key = (changes[j] + 10) << 24 |
              (changes[j+1] + 10) << 16 |
              (changes[j+2] + 10) << 8 |
              (changes[j+3] + 10)

        if key ∉ seen
            push!(seen, key)
            sequences[key] = get(sequences, key, 0) + prices[j+3]
        end
    end
end

function part2(numbers::Vector{Int})::Int
    sequences = Dict{Int,Int}()
    prices = zeros(Int, NUM_ITERATIONS)
    changes = zeros(Int, NUM_ITERATIONS)

    for sn in numbers
        calculate_price_changes!(sn, prices, changes)
        find_max_bananas(prices, changes, sequences)
    end

    maximum(values(sequences))
end # 0.368851 seconds (44.48 k allocations: 97.241 MiB, 20.72% gc time)
=#

function find_max_bananas(prices::Vector{Int}, changes::Vector{Int}, max_values::Vector{Int}, seen::BitVector)
    fill!(seen, false)  # Reset seen flags

    @inbounds for j in 1:NUM_ITERATIONS-3
        # Since changes are differences between digits 0-9, range is -9 to 9
        # Shift to 0-18 range and use base-19 encoding for unique key
        k1, k2, k3, k4 = changes[j] + 9, changes[j+1] + 9, changes[j+2] + 9, changes[j+3] + 9
        key = 1 + k1 + k2 * 19 + k3 * 361 + k4 * 6859  # 19^0, 19^1, 19^2, 19^3

        if !seen[key]
            seen[key] = true
            max_values[key] += prices[j+3]
        end
    end
end

function part2(numbers::Vector{Int})::Int
    max_size = 19^4 + 1  # Since each position can have 19 possible values (-9..9) + 1
    max_values = zeros(Int, max_size)
    seen = falses(max_size)  # Pre-allocated BitVector
    prices = zeros(Int, NUM_ITERATIONS)
    changes = zeros(Int, NUM_ITERATIONS)

    for sn in numbers
        calculate_price_changes!(sn, prices, changes)
        find_max_bananas(prices, changes, max_values, seen)
    end

    maximum(max_values)
end

function solve(io::IO)::Tuple{Int,Int}
    numbers = parse_market(io)
    (part1(numbers), part2(numbers))
end

# Simple testing
function run_tests()
    @testset "Monkey Market" begin
        test_input = """
        1
        10
        100
        2024
        """
        @test solve(IOBuffer(test_input)) == (37327623, 24)
    end
end

function main(filename::String)
    @time begin
        io = open(filename)
        p1, p2 = solve(io)
        println("Part 1: ", p1)
        println("Part 2: ", p2)
    end
end

# 0.072942 seconds (4.10 k allocations: 1.194 MiB)

if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
    isempty(ARGS) || main(ARGS[1])
end

