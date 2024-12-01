using StatsBase
using DelimitedFiles

function calculate_total_distance(left_list::AbstractVector{Int}, right_list::AbstractVector{Int})
    sort!(left_list)
    sort!(right_list)
    return sum(abs.(left_list .- right_list))
end

function calculate_similarity_score(left_list::AbstractVector{Int}, right_list::AbstractVector{Int})
    right_frequency = countmap(right_list)

    return sum(num * get(right_frequency, num, 0) for num in left_list)
end

function read_and_calculate(filename::String)
    data = readdlm(filename, Int)

    # split into left and right lists
    left_list, right_list = view(data, :, 1), view(data, :, 2)

    total_distance = calculate_total_distance(left_list, right_list)
    similarity_score = calculate_similarity_score(left_list, right_list)

    return total_distance, similarity_score
end

function main()
    filename = "data/input.txt"
    total_distance, similarity_score = @btime read_and_calculate($filename)
    println("Total Distance: ", total_distance)
    println("Similarity Score: ", similarity_score)
end

main()
