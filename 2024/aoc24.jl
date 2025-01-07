# Reference: https://github.com/p88h/aoc2024/blob/main/src/day24.zig
using Test

logic_gate(op::Symbol, l::Bool, r::Bool) = op == :AND ? l && r : op == :OR ? l || r : op == :XOR ? l ⊻ r : error("Undefined operation: $op")

mutable struct Gate
    label::String
    op::Symbol
    left::Union{Nothing,Int}
    right::Union{Nothing,Int}
    value::Union{Nothing,Bool}
end

struct Context
    gates::Vector{Gate}
    gmap::Dict{String,Int}
end

function parse_input(file::String)::Context
    gates, gmap = Vector{Gate}(), Dict{String,Int}()
    get_or_create_gate(label) = haskey(gmap, label) ? gmap[label] : (push!(gates, Gate(label, :UNDEF, nothing, nothing, nothing)); gmap[label] = length(gates))

    for line in readlines(file)
        if occursin(":", line)
            label, value = split(line, ":")
            gates[get_or_create_gate(strip(label))] = Gate(strip(label), :VALUE, nothing, nothing, strip(value) == "1")
        elseif occursin("->", line)
            parts, inputs = split(line, "->"), split(strip(split(line, "->")[1]))
            gates[get_or_create_gate(strip(parts[2]))] = Gate(strip(parts[2]), Symbol(inputs[2]), get_or_create_gate(inputs[1]), get_or_create_gate(inputs[3]), nothing)
        end
    end
    Context(gates, gmap)
end

# Evaluate a gate recursively, caching results
function eval_gate!(ctx::Context, idx::Int)::Bool
    gate = ctx.gates[idx]
    gate.value !== nothing && return gate.value
    gate.op == :VALUE && return gate.value === nothing ? false : gate.value
    gate.value = logic_gate(gate.op, gate.left !== nothing ? eval_gate!(ctx, gate.left) : false, gate.right !== nothing ? eval_gate!(ctx, gate.right) : false)
end

# Collect outputs for "z-index" gates and compute binary result
function part1(ctx::Context)::Int
    z_gates = [(parse(Int, label[2:end]), idx) for (label, idx) in ctx.gmap if startswith(label, "z")]
    sort!(z_gates, by=first, rev=true)
    foldl((acc, (_, idx)) -> (acc << 1) | (eval_gate!(ctx, idx) ? 1 : 0), z_gates; init=0)
end

# Count connections for each gate
function count_connections(ctx::Context)::Dict{String,Int}
    connections = Dict{String,Int}()
    for gate in ctx.gates
        gate.left !== nothing && (connections[ctx.gates[gate.left].label] = get(connections, ctx.gates[gate.left].label, 0) + 1)
        gate.right !== nothing && (connections[ctx.gates[gate.right].label] = get(connections, ctx.gates[gate.right].label, 0) + 1)
    end
    connections
end

# Identify "bad gates" based on specific rules
function is_bad_gate(ctx::Context, gate::Gate, connections::Dict{String,Int})::Bool
    is_value_input(label) = startswith(label, 'x') || startswith(label, 'y')
    gate.op == :VALUE && return false
    startswith(gate.label, 'z') && return parse(Int, gate.label[2:end]) < 45 && gate.op != :XOR
    if gate.left !== nothing && gate.right !== nothing
        left_label, right_label = ctx.gates[gate.left].label, ctx.gates[gate.right].label
        if is_value_input(left_label) && is_value_input(right_label)
            return gate.op == :AND ? (left_label == "x00" || left_label == "y00" ? connections[gate.label] != 2 : connections[gate.label] != 1) :
                   gate.op == :XOR ? connections[gate.label] != 2 : false
        end
    end
    gate.op == :XOR && !(gate.left !== nothing && gate.right !== nothing && is_value_input(ctx.gates[gate.left].label) && is_value_input(ctx.gates[gate.right].label))
end

function part2(ctx::Context; use_new_logic::Bool=true)::String
    if use_new_logic
        # New logic for Part 2 (identifying swapped wires)
        expected_outputs = Dict{String,String}()
        for i in 0:5
            x_label = "x$(lpad(i, 2, '0'))"
            y_label = "y$(lpad(i, 2, '0'))"
            z_label = "z$(lpad(i, 2, '0'))"
            expected_outputs["$x_label AND $y_label"] = z_label
        end

        # Actual mapping of inputs to outputs
        actual_outputs = Dict{String,String}()
        for gate in ctx.gates
            if gate.op == :AND
                left_label = ctx.gates[gate.left].label
                right_label = ctx.gates[gate.right].label
                actual_outputs["$left_label AND $right_label"] = gate.label
            end
        end

        # Identify swapped gates
        swapped_gates = Set{String}()
        for (key, expected_z) in expected_outputs
            actual_z = get(actual_outputs, key, "")
            if actual_z != expected_z
                push!(swapped_gates, expected_z)
                push!(swapped_gates, actual_z)
            end
        end

        # Return sorted list of swapped gates
        return join(sort(collect(swapped_gates)), ",")
    else
        # Original logic for Part 2 (bad gates based on connections)
        connections = count_connections(ctx)
        bad_gates = [gate.label for gate in ctx.gates if is_bad_gate(ctx, gate, connections)]
        return join(sort(bad_gates), ",")
    end
end

# Reset circuit for re-evaluation
function reset_circuit!(ctx::Context)
    for gate in ctx.gates
        gate.op != :VALUE && (gate.value = nothing)
    end
end

function run_tests()
    @testset "Circuit Tests" begin
        mktempdir() do tmpdir
            test_input = """
                x00: 0
                x01: 1
                x02: 0
                x03: 1
                x04: 0
                x05: 1
                y00: 0
                y01: 0
                y02: 1
                y03: 1
                y04: 0
                y05: 1

                x00 AND y00 -> z05
                x01 AND y01 -> z02
                x02 AND y02 -> z01
                x03 AND y03 -> z03
                x04 AND y04 -> z04
                x05 AND y05 -> z00
                """
            input_file = joinpath(tmpdir, "test1.txt")
            write(input_file, test_input)
            ctx = parse_input(input_file)
            reset_circuit!(ctx)
            p1 = part1(ctx)
            @test p1 == 9
            reset_circuit!(ctx)
            p2 = part2(ctx)
            @test p2 == "z00,z01,z02,z05"
        end
    end
end

function main(file::String)
    @time begin
        ctx = parse_input(file)
        reset_circuit!(ctx)
        p1 = part1(ctx)
        reset_circuit!(ctx)
        p2 = part2(ctx, use_new_logic=false)
        println("Part 1 Result: ", p1)
        println("Part 2 Result: ", p2)
    end
end

#0.001966 seconds (4.91 k allocations: 387.898 KiB)

if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
    isempty(ARGS) || main(ARGS[1])
end
