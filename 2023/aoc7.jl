#=
Original source:
https://git.devin.gay/devin/advent-of-code/src/branch/main/2023/aoc7.jl]
=#

using Test

const char2strength = Dict(zip("23456789TJQKA", 1:13))
@enum Type HighCard OnePair TwoPair ThreeOfAKind FullHouse FourOfAKind FiveOfAKind

abstract type Hand end
struct Hand1 <: Hand
    strengths::NTuple{5,Int}
end
struct Hand2 <: Hand
    strengths::NTuple{5,Int}
end

const jack2joker_lookup = [1:9; 0; 11:13]

function hand_type(strengths::NTuple{5,Int}, joker_val::Int=0)
    counts = zeros(Int, 13)
    num_jokers = count(==(joker_val), strengths)
    for s in strengths
        s ≠ joker_val && (counts[s] += 1)
    end

    max_count = maximum(counts) + num_jokers

    if max_count == 5
        return FiveOfAKind
    elseif max_count == 4
        return FourOfAKind
    elseif max_count == 3
        return count(>(0), counts) == 2 ? FullHouse : ThreeOfAKind
    elseif max_count == 2
        return count(>(0), counts) == 3 ? TwoPair : OnePair
    else
        return HighCard
    end
end

handsType(h::Hand1) = hand_type(h.strengths)
handsType(h::Hand2) = hand_type(h.strengths, char2strength['J'])

function Base.cmp(h1::T, h2::T) where {T<:Hand}
    type_cmp = cmp(handsType(h1), handsType(h2))
    type_cmp ≠ 0 && return type_cmp

    lookup = T == Hand2 ? jack2joker_lookup : (1:13)
    for (s1, s2) in zip(h1.strengths, h2.strengths)
        strength_cmp = cmp(lookup[s1], lookup[s2])
        strength_cmp ≠ 0 && return strength_cmp
    end
    return 0
end

Base.isless(h1::Hand, h2::Hand) = cmp(h1, h2) < 0

function solve(filename)
    hands_bids = map(eachline(filename)) do line
        hand_raw, bid_raw = split(line)
        hand = Tuple(char2strength[c] for c in hand_raw)
        bid = parse(Int, bid_raw)
        (hand, bid)
    end

    score(hand_type, sorted_hands) = sum(i * bid for (i, (_, bid)) in enumerate(sorted_hands))

    part1 = score(Hand1, sort(hands_bids, by=x -> Hand1(x[1])))
    part2 = score(Hand2, sort(hands_bids, by=x -> Hand2(x[1])))

    return part1, part2
end

function run_tests()
    @testset "Joker rule testing" begin
        example_data = [
            "32T3K 765",
            "T55J5 684",
            "KK677 28",
            "KTJJT 220",
            "QQQJA 483",
        ]

        # Create a temporary file for testing
        mktemp() do path, io
            for line in example_data
                println(io, line)
            end
            close(io)

            part1, part2 = solve(path)
            @test part1 == 6440
            @test part2 == 5905
        end
    end
end

function main(file_path::String)
    part1, part2 = solve(file_path)
    println("Part 1: $part1")
    println("Part 2: $part2")
end

#0.005713 seconds (103.95 k allocations: 8.085 MiB, 29.35% gc time)

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("Provide an input file path or 'test' as argument")
    if ARGS[1] == "test"
        using Test
        run_tests()
    else
        main(ARGS[1])
    end
end


