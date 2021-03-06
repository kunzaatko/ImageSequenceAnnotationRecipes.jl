using Makie
using ...ImageSequenceAnnotationRecipes: AbstractInteraction, Hotkey, Event
using ...ImageSequenceAnnotationRecipes
using Base: @kwdef

export ChangeLocationCategory

# TODO: Document <07-05-22> 
# TODO: This should be made more generic with allowing Any for category <07-05-22> 
@kwdef struct ChangeLocationCategory <: AbstractInteraction
    plot::LocationsLayer
    hotkey::Hotkey
    category::Union{Symbol, Nothing} = nothing
    priority::Integer = 1
    includekeyboard::Bool = true
    includemouse::Bool = false
end

ImageSequenceAnnotationRecipes.condition(x::ChangeLocationCategory, _::Event) = !isnothing(x.plot[:selected][])

# FIX: Use plot.converted? <07-05-22> 
function ImageSequenceAnnotationRecipes.execute(x::ChangeLocationCategory) 
    x.plot[:locations][][x.plot[:selected][].idx].category = x.category
    notify(x.plot[:locations])
end
