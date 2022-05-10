using Makie
using ...ANT: AbstractInteraction, Hotkey, Event
using ...ANT
using Base: @kwdef

@kwdef struct NextFrame <: AbstractInteraction
    plot::ImageSequence
    hotkey::Hotkey
    priority::Integer = 1
    includekeyboard::Bool = true
    includemouse::Bool = false
end

ANT.condition(x::NextFrame, _::Event) = x.plot.visible[] == true && x.plot[:frame][] != size(x.plot[:sequence][])[x.plot.dims[]]

function ANT.execute(x::NextFrame) 
    x.plot[:frame][]  = x.plot[:frame][] + 1
end

@kwdef struct PrevFrame <: AbstractInteraction
    plot::ImageSequence
    hotkey::Hotkey
    priority::Integer = 1
    includekeyboard::Bool = true
    includemouse::Bool = false
end

ANT.condition(x::PrevFrame, _::Event) = x.plot.visible[] == true && x.plot[:frame][] != 1

function ANT.execute(x::PrevFrame) 
    x.plot[:frame][] = x.plot[:frame][] - 1
end
