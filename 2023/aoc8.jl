using Test

function parse_network(lines)
    Dict(split(l, " = ")[1] => Tuple(split(l[findall(r"\(.*\)", l)[1]][2:end-1], ", ")) for l in lines)
end

function solve_task1(instr::String, net::Dict)
    pos, steps = "AAA", 0
    while pos != "ZZZ"
        steps += 1
        pos = net[pos][instr[mod1(steps, length(instr))] == 'L' ? 1 : 2]
    end
    steps
end

function solve_task2(instr::String, net::Dict)
    function cycle_length(start)
        pos, steps = start, 0
        while !endswith(pos, 'Z')
            steps += 1
            pos = net[pos][instr[mod1(steps, length(instr))] == 'L' ? 1 : 2]
        end
        steps
    end
    lcm([cycle_length(n) for n in filter(n -> endswith(n, 'A'), keys(net))]...)
end

function process_file(path)
    lines = readlines(path)
    net = parse_network(lines[3:end])
    solve_task1(lines[1], net), solve_task2(lines[1], net)
end

function run_tests()
    @testset "Mapping Network" begin
        network_lines_task1 = [
            "AAA = (BBB, BBB)",
            "BBB = (AAA, ZZZ)",
            "ZZZ = (ZZZ, ZZZ)"
        ]
        @test solve_task1("LLR", parse_network(network_lines_task1)) == 6

        network_lines_task2 = [
            "11A = (11B, XXX)",
            "11B = (XXX, 11Z)",
            "11Z = (11B, XXX)",
            "22A = (22B, XXX)",
            "22B = (22C, 22C)",
            "22C = (22Z, 22Z)",
            "22Z = (22B, 22B)",
            "XXX = (XXX, XXX)"
        ]
        @test solve_task2("LR", parse_network(network_lines_task2)) == 6
    end
end

function main(file_path::String)
    task1, task2 = process_file(file_path)
    println("Task 1: ", task1)
    println("Task 2: ", task2)
end

#0.032676 seconds (31.03 k allocations: 1.799 MiB)

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("Provide an input file path or 'test' as argument")
    if ARGS[1] == "test"
        using Test
        run_tests()
    else
        main(ARGS[1])
    end
end
