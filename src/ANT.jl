module ANT
using Makie, Images, DataStructures
export annotationtool, HOTKEYS
HOTKEYS = Dict{Symbol,Any}(:prev_frame => [Keyboard.left, Keyboard.h], :next_frame => [Keyboard.right, Keyboard.l], :add_loc => [Keyboard.a], :del_loc => [Keyboard.d],
    :annotation => [[Keyboard.q], [Keyboard.w], [Keyboard.e], [Keyboard.r], [Keyboard.t]])

function annotationtool(im::AbstractArray{<:Colorant,3}; hotkeys = HOTKEYS, colors = COLORS, 
    categories = [Symbol("1"), Symbol("2"), Symbol("3"), Symbol("4"), Symbol("5"), Symbol("6")])
    fig = Figure()

    # AXES
    mainimage_ax = Makie.Axis(fig[1, 1], aspect = size(im)[1] / size(im)[2], limits = ((0, size(im)[1]), (0, size(im)[2])))
    frameslider_pos = fig[2, 1]

    # State Observables
    frameslider = Slider(frameslider_pos, range = 1:size(im)[3])
    curframe = frameslider.value
    Label(frameslider_pos, lift(idx -> "$(idx)/$(size(im)[3])", curframe), tellwidth = false )

    frameplots = Vector{Observable{Dict{Symbol,AbstractPlot}}}(undef, size(im)[3])
    for i in 1:length(frameplots)
        frameplots[i] = Observable(Dict{Symbol,AbstractPlot}())
    end

    curplots = @lift frameplots[$curframe][]
    on(curplots) do plots
        if !haskey(plots, :image) # image for this frame is not yet created
            lims = mainimage_ax.finallimits[] # limits to be restored on frame change
            plots[:image] = image!(mainimage_ax, im[:, :, curframe[]], interpolate = false, inspectable = false)
            limits!(mainimage_ax, lims)
        end
        for (_, plot) in plots
            plot.visible = true
        end
    end

    # NOTE: In theory only one should suffice here, but sometimes the slider is too fast and the
    # later image is pushed before the previous is made invisible. Anything additional is used as an error
    # margin for the async `on` functions to avoid bugs due to access races. <06-04-22> 
    visitedframes = CircularBuffer(3)

    # On change of frame
    on(curframe) do frame
        # {{{
        # NOTE: Making the previous plots invisible <04-04-22> 
        foreach(f -> begin
                if f != frame
                    for (_, plot) in frameplots[f][]
                        plot.visible = false
                    end
                end
            end, visitedframes)
        push!(visitedframes, frame)
        # }}}
    end
    notify(curframe)

    # Global hotkey events
    on(events(fig).keyboardbutton) do event
        # {{{
        if event.action in (Keyboard.press, Keyboard.repeat)
            for key in hotkeys[:prev_frame]
                event.key == key && set_close_to!(frameslider, curframe[] - 1)
            end
            for key in hotkeys[:next_frame]
                event.key == key && set_close_to!(frameslider, curframe[] + 1)
            end
        end
        return Consume(false)
        # }}}
    end

    display(fig)
end
end
