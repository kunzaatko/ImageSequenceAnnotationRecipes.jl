using Makie
using ...ANT: AbstractInteraction, Hotkey, Event
using ...ANT
using LinearAlgebra
using Base: @kwdef

export DragLocation

# TODO: Add dragging interaction when holding the mousebutton <kunzaatko> 

# TODO: Document <07-05-22> 
@kwdef struct DragLocation <: AbstractInteraction
    plot::LocationsLayer
    hotkey::Hotkey
    priority::Integer = 1
    measure::Function = norm
    range::Real = 4
    includekeyboard::Bool = true
    includemouse::Bool = false
end

# TODO: Make the method on the plot type instead <07-05-22> 
function closest(x::DragLocation)
    mp = round.(mouseposition(x.plot.parent))
    dists = (x.measure).(getfield.(x.plot[:locations][], :point) .- mp)
    amin = argmin(dists)
    return amin, dists[amin]
end

ANT.condition(x::DragLocation) = x.plot.visible[] == true && closest(x)[2] <= x.range

# TODO: This should be implemented in a way so that it is asynchronous (in video about events there
# was something similar)
# TODO: Test  
function ANT.register(x::DragLocation)
    on(events(x.plot.parent).mouseposition) do mp
        mb = events(x.plot.parent).mousebutton[]
        if ispressed(x.plot.parent, x.hotkey) && condition(x) && (mb.action == Mouse.press || mb.action == Mouse.repeat)
            x.plot[:locations][][x.plot[:selected][]].point = mp
            notify(x.plot[:locations])
        end
    end
end
