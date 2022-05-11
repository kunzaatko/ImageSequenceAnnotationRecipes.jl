using Makie
using ...ImageSequenceAnnotationRecipes: Location, Selected, AbstractInteraction, Hotkey, Event
using ...ImageSequenceAnnotationRecipes
using LinearAlgebra
using Base: @kwdef

export SelectLocation

# TODO: Document <07-05-22> 
@kwdef struct SelectLocation <: AbstractInteraction
    plot::LocationsLayer
    hotkey::Hotkey
    priority::Integer = 1
    movemouse::Bool = true
    measure::Function = norm
    range::Real = 4
    includekeyboard::Bool = false
    includemouse::Bool = true
end

# TODO: Make the method on the plot type instead <07-05-22> 
function closest(x::SelectLocation)
    mp = round.(mouseposition(x.plot.parent))
    @debug "Mouse position $mp"
    @debug "Location points $(getfield.(x.plot[:locations][], :point))"
    dists = x.measure.(map(x -> convert(Vector, x) .- mp, getfield.(x.plot[:locations][], :point)))
    amin = argmin(dists)
    return amin, dists[amin]
end

ImageSequenceAnnotationRecipes.condition(x::SelectLocation, _::Event) = x.plot.visible[] == true && length(x.plot[:locations][]) > 0 && closest(x)[2] <= x.range

function ImageSequenceAnnotationRecipes.execute(x::SelectLocation)
    x.plot[:selected][] = closest(x)[1]
    if x.movemouse
        new_mousepos = x.plot[:locations][][x.plot[:selected][].idx].point
        x.plot.parent.events.mouseposition[] = (new_mousepos[1], new_mousepos[2])
    end
end
