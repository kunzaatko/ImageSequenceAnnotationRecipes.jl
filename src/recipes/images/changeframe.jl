using Makie
using ...ImageSequenceAnnotationRecipes: AbstractInteraction, Hotkey, Event
using ...ImageSequenceAnnotationRecipes
using Base: @kwdef

@kwdef struct NextFrame <: AbstractInteraction
    plot::ImageSequence
    hotkey::Hotkey
    priority::Integer = 1
    includekeyboard::Bool = true
    includemouse::Bool = false
end

ImageSequenceAnnotationRecipes.condition(x::NextFrame, _::Event) = x.plot.visible[] == true && x.plot[:frame][] != size(x.plot[:sequence][])[x.plot.dims[]]

function ImageSequenceAnnotationRecipes.execute(x::NextFrame) 
    x.plot[:frame][]  = x.plot[:frame][] + 1
end

@kwdef struct PrevFrame <: AbstractInteraction
    plot::ImageSequence
    hotkey::Hotkey
    priority::Integer = 1
    includekeyboard::Bool = true
    includemouse::Bool = false
end

ImageSequenceAnnotationRecipes.condition(x::PrevFrame, _::Event) = x.plot.visible[] == true && x.plot[:frame][] != 1

function ImageSequenceAnnotationRecipes.execute(x::PrevFrame) 
    x.plot[:frame][] = x.plot[:frame][] - 1
end
