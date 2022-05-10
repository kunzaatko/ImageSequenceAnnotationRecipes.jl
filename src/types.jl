using GeometryBasics
using Makie
import Makie: convert_arguments
import Base: convert, ==, isnothing

# TODO: Make this more generic with using Any instead of symbol 
mutable struct Location
    point::Point{2,Real} # TODO: This argument should be parametrized <04-05-22, kunzaatko> 
    category::Union{Nothing,Symbol}
end

Location(point::Point) = Location(point, nothing)
==(a::Location, b::Location) = a.point == b.point && a.category == b.category

convert_arguments(P::Type{<:Scatter}, locations::Vector{Location}) = convert_arguments(P, getfield.(locations, :point))
convert_arguments(P::Type{<:Scatter}, location::Location) = convert_arguments(P, location.point)


"""
    struct Selected

A wrapper around Union{Nothing, <:Integer}. It defines an index that is selected in a plot with the possibility to select nothing.

!!! note "Use of `===`"
    If `s::Selected` is `nothing` you can not use the customary `s === nothing`. Instead you should use `s == nothing` which gives the right result or `isnothing(s)`.
    ```@repl
    s = Selected(nothing)
    @assert s == nothing
    @assert isnothing(s) 
    s === nothing # gives the wrong result
    ```
"""
struct Selected
    idx::Union{Nothing,<:Integer}
end
convert(::Type{Selected}, x::Integer) = Selected(x)
convert(::Type{Selected}, x::Nothing) = Selected(nothing)
convert(::Type{Integer}, x::Selected) = isnothing(x) && error("Cannot convert `Selected` that is nothing to Integer") || x.idx
==(x::Selected, y::Union{Integer,Nothing}) = x.idx == y
==(x::Selected, y::Selected) = x.idx == y.idx
isnothing(x::Selected) = typeof(x.idx) == Nothing

const Hotkey = Union{Makie.Keyboard.Button,Makie.Mouse.Button,Makie.BooleanOperator}
const Event = Union{Makie.KeyEvent,Makie.MouseButtonEvent}

abstract type AbstractInteraction end

# TODO: Documentation <07-05-22> 
condition(_::AbstractInteraction, _::Event) = true

# TODO: Documentation <07-05-22> 
execute(_::AbstractInteraction) = error("An interaction must have a `execute` function implemented")

# TODO: Documentation <kunzaatko> 
function register(x::AbstractInteraction)
    if x.includekeyboard
        on(events(x.plot.parent).keyboardbutton, priority = x.priority) do event
            if ispressed(x.plot.parent, x.hotkey) && condition(x, event)
                execute(x)
            end
        end
    end
    if x.includemouse
        on(events(x.plot.parent).mousebutton, priority = x.priority) do event
            if ispressed(x.plot.parent, x.hotkey) && condition(x, event)
                execute(x)
            end
        end
    end
end

