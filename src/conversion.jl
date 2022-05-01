module ArgumentConversion
using Observables
include("types.jl")
export convert_output_locations
function convert_input_locations(locations::AbstractVector{T}) where {T<:AbstractVector}
    locations
end
function convert_input_locations(locations::AbstractVector{AbstractMatrix})
    if all(getindex.(size.(locations), 2) .== 3)
        @assert all(typeof.(getindex.(locations, (:, [1, 2]))) .<: Real) "When converting a Matrix with sizes (_, 3) into locations, the first two elements of each matrix row must be numbers"
        return map(locations) do mat
            map(eachrow(mat)) do row
                Location(Point(row[[1, 2]]...), row[3])
            end
        end
    elseif all(getindex.(size.(locations), 2) .== 2)
        @assert all(typeof.(getindex.(locations, (:, 1))) .<: Point2) "When converting a Matrix with sizes (_, 2) into locations, the first element of each matrix row must be a point"
        return map(locations) do mat
            map(eachrow(mat)) do row
                Location(row[1], row[2])
            end
        end
    end
end

# FIX: This is quite blant and will not work if the type is not what I expect it to be <28-04-22> 
function convert_output_locations(locations::Ref)
    map(locations[]) do loclayer
        loclayer[]
    end
end
end
