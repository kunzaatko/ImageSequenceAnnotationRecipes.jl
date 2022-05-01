using GeometryBasics
import Base.:(==)
# TODO: Make this more generic with using Any instead of symbol 
mutable struct Location
    point::Point{2,Real}
    category::Union{Nothing,Symbol}
end

Location(point::Point) = Location(point, nothing)
==(a::Location, b::Location) = a.point == b.point && a.category == b.category

# TODO: Add posibility to have multiple points selected <27-04-22> 
const SelectedLocation = Union{Nothing,<:Integer}
