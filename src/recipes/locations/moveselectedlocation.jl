using Makie
using ...ImageSequenceAnnotationRecipes: Location, Selected, AbstractInteraction, Hotkey, Event
using ...ImageSequenceAnnotationRecipes
using Base: @kwdef

export MoveSelectedLocation

# TODO: Document <07-05-22> 
@kwdef struct MoveSelectedLocation <: AbstractInteraction
    plot::LocationsLayer
    hotkey::Hotkey
    priority::Integer = 1
    includekeyboard::Bool = false
    includemouse::Bool = true
end

ImageSequenceAnnotationRecipes.condition(x::MoveSelectedLocation, _::Event) = x.plot.visible[] == true && !isnothing(x.plot[:selected][])

function ImageSequenceAnnotationRecipes.execute(x::MoveSelectedLocation)
    mp = mouseposition(x.plot.parent)
    x.plot[:locations][][x.plot[:selected][].idx].point = mp
    notify(x.plot[:locations])
    return Consume(true)
end
