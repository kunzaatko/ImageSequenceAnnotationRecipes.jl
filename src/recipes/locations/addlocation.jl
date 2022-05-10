using Makie
using ...ANT: Location, Selected, AbstractInteraction, Hotkey, Event
using ...ANT
using Base: @kwdef

export AddLocation

# TODO: Document <07-05-22> 
# TODO: Make this more generic with using Any instead of symbol 
@kwdef struct AddLocation <: AbstractInteraction
    plot::LocationsLayer
    hotkey::Hotkey
    category::Union{Nothing, Symbol} = nothing
    selectadded::Bool = true
    priority::Integer = 1
    includekeyboard::Bool = true
    includemouse::Bool = false
end

ANT.condition(x::AddLocation, _::Event) = x.plot.visible[] == true

# FIX: Use plot.converted? <07-05-22> 
function ANT.execute(x::AddLocation) 
    push!(x.plot[:locations][], Location(mouseposition(x.plot.parent), x.category))
    notify(x.plot[:locations])
    if x.selectadded
        @debug x.plot[:locations][]
        x.plot[:selected][] = length(x.plot[:locations][])
    end
end
