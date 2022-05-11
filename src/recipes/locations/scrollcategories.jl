using Makie
using ...ANT: Location, Selected, AbstractInteraction, Hotkey, Event
using ...ANT
using DataStructures
using Base: @kwdef

export ScrollCategories

# TODO: Document <07-05-22> 
# TODO: Make this more generic with using Any instead of symbol 
@kwdef struct ScrollCategories <: AbstractInteraction
    plot::LocationsLayer
    hotkey::Hotkey
    categories::AbstractVector{Union{Nothing,Symbol}} = [nothing]
    priority::Integer = 1
    includekeyboard::Bool = false
    includemouse::Bool = true
end

ANT.condition(x::ScrollCategories) = x.plot.visible[] == true && !isnothing(x.plot[:selected][])

function ANT.register(x::ScrollCategories)
    on(events(x.plot.parent).scroll, priority = x.priority) do (_, dy)
        if ispressed(x.plot.parent, x.hotkey) && ANT.condition(x)
            @debug "Running ScrollCategories"
            selected_location = x.plot[:locations][][x.plot[:selected][].idx]
            if !(selected_location.category in x.categories)
                selected_location.category = x.categories[1]
            else
                idx = findfirst(cat -> cat == selected_location.category, x.categories) - 1
                selected_location.category = x.categories[convert(Integer, mod(idx + dy, length(x.categories)) + 1)]
            end
            notify(x.plot[:locations])
            return Consume(true)
        end
    end
end
