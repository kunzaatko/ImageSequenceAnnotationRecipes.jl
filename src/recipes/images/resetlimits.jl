using Makie
using ...ImageSequenceAnnotationRecipes: AbstractInteraction, Hotkey, Event
using ...ImageSequenceAnnotationRecipes
using Base: @kwdef

export ResetLimits

@kwdef struct ResetLimits <: AbstractInteraction
    plot::ImageSequence
    hotkey::Hotkey
    priority::Integer = 1
    includekeyboard::Bool = true
    includemouse::Bool = false
end

ImageSequenceAnnotationRecipes.condition(x::ResetLimits, _::Event) = x.plot.visible[] == true

function ImageSequenceAnnotationRecipes.execute(x::ResetLimits)
    xsize, ysize = size(x.plot[:sequence][])[1:2]
    # FIX: This may not be the acctuall axis that is desired <08-05-22> 
    limits!(current_axis(), BBox(1, xsize, 1, ysize))
end
