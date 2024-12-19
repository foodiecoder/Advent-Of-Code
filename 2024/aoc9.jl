
# Reference: https://github.com/fmarotta/AoC/blob/main/2024/day9/run.jl
using Test

struct DiskFile
    file_id::Int # -1 for free space
    size::Int
end

const InputType = Vector{DiskFile}
const SolutionType = Int

function read_puzzle(filename)::InputType
    nums = parse.(Int, split(readline(filename), ""))
    disk = InputType(undef, length(nums))
    @inbounds for i in 1:2:length(nums)
        disk[i] = DiskFile((i - 1) ÷ 2, nums[i])
        disk[i+1] = DiskFile(-1, nums[i+1])
    end
    return disk
end

# Create three arrays: provides better cache locality than struct array access, further improvement needed!
function extract_arrays!(disk::InputType)
    n = (length(disk) + 1) ÷ 2
    file_capacity = [d.size for d in disk[1:2:end]]
    space_capacity = [d.size for d in disk[2:2:end]]
    file_id = collect(0:n-1)
    return file_capacity, space_capacity, file_id
end


function part1(disk::InputType)::SolutionType
    file_capacity, space_capacity, file_id = extract_arrays!(disk)
    checksum = 0
    pos = 0
    i = 1
    j = length(file_id)

    while true
        @inbounds while file_capacity[i] > 0
            checksum += file_id[i] * pos
            pos += 1
            file_capacity[i] -= 1
        end

        @inbounds while space_capacity[i] > 0
            while j > 0 && file_capacity[j] <= 0
                j -= 1
            end
            if j < i
                return checksum
            end
            checksum += file_id[j] * pos
            pos += 1
            file_capacity[j] -= 1
            space_capacity[i] -= 1
        end
        i += 1
    end
    return checksum
end

function part2(disk::InputType)::SolutionType
    file_capacity, space_capacity, file_id = extract_arrays!(disk)
    checksum = 0
    pos = 0
    already_moved = falses(length(file_id))
    i = 1

    while i <= length(file_capacity)
        @inbounds while file_capacity[i] > 0
            if already_moved[i]
                pos += file_capacity[i]
                break
            end
            checksum += file_id[i] * pos
            pos += 1
            file_capacity[i] -= 1
        end

        @inbounds while i <= length(space_capacity) && space_capacity[i] > 0
            j = length(file_id)
            while j > i && (already_moved[j] || file_capacity[j] > space_capacity[i])
                j -= 1
            end
            if j == i
                pos += space_capacity[i]
                break
            end
            already_moved[j] = true
            for _ in 1:file_capacity[j]
                checksum += file_id[j] * pos
                pos += 1
                space_capacity[i] -= 1
            end
        end
        i += 1
    end
    return checksum
end

function run_tests()
    @testset "Disk Fragmentation" begin
        input = "2333133121414131402"
        disk = read_puzzle(IOBuffer(input))
        @test part1(disk) == 1928
        @test part2(disk) == 2858
    end
end

function main(filename::String)
    @time begin
        disk = read_puzzle(filename)
        println("Part 1: ", part1(disk))
        println("Part 2: ", part2(disk))
    end
end

# 0.025859 seconds (91 allocations: 2.523 MiB)

if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
    isempty(ARGS) || main(ARGS[1])
end
