using Makie
using ...ANT: Location, Selected, AbstractInteraction, Hotkey, Event
using ...ANT
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

ANT.condition(x::MoveSelectedLocation, _::Event) = x.plot.visible[] == true && !isnothing(x.plot[:selected][])

function ANT.execute(x::MoveSelectedLocation)
    mp = mouseposition(x.plot.parent)
    x.plot[:locations][][x.plot[:selected][].idx].point = mp
    notify(x.plot[:locations])
    return Consume(true)
end
