using Makie
using ...ANT: AbstractInteraction, Hotkey, Event
using ...ANT
using Base: @kwdef

export RemoveSelectedLocation

# TODO: Document <07-05-22> 
# TODO: Make this more generic with using Any instead of symbol 
@kwdef struct RemoveSelectedLocation <: AbstractInteraction
    plot::LocationsLayer
    hotkey::Hotkey
    removeselection::Bool = true
    priority::Integer = 1
    includekeyboard::Bool = true
    includemouse::Bool = false
end

# NOTE: selected !isnothing should imply that locations is not empty <kunzaatko> 
ANT.condition(x::RemoveSelectedLocation, _::Event) = x.plot.visible[] == true && !isnothing(x.plot[:selected][])

# FIX: Use plot.converted? <07-05-22> 
function ANT.execute(x::RemoveSelectedLocation) 
    popat!(x.plot[:locations][], x.plot[:selected][].idx)
    notify(x.plot[:locations])
    # TODO: What to do when `removeselection` is false <07-05-22, kunzaatko> 
    if x.removeselection
        x.plot[:selected][] = nothing
    end
    return Consume(true)
end
