module ANT
using Makie, Images, DataStructures
include("locations.jl")

export annotationtool, HOTKEYS

# FIX: This type should be specified strictly so that it can be relied on <06-04-22> 
# TODO: Annotation hotkeys should include numbers... How to add them? <07-04-22> 
HOTKEYS = Dict{Symbol,Any}(
    :prev_frame => (Keyboard.left | Keyboard.h),
    :next_frame => (Keyboard.right | Keyboard.l),
    :add_loc => (Keyboard.a | Keyboard.i),
    :del_loc => Keyboard.d,
    :select_loc => Keyboard.s,
    :annotation => [Keyboard.q, Keyboard.w, Keyboard.e, Keyboard.r, Keyboard.t])

# TODO: Add posibility to drag image into figure with Union{..., Nothing} on im and Event
# dropped_files <04-04-22> 
# TODO: previous input insertion <04-04-22> 
"""
    annotationtool(im_seq::AbstractArray{<:Colorant,3}; args...)

The only required argument is `im_seq` which is a sequence of images represented by a 3-dimensional array where the first 2 axes are spacial and the 3rd is the sequence dimension.
"""
function annotationtool(
    im::AbstractArray{<:Colorant,3};
    hotkeys = HOTKEYS,
    categories = Symbol.(["1", "2", "3", "4"]), # NOTE: Will be determined if the data is passed in
    locations_attrs = (;)
)

    #  Scene setup {{{
    fig = Figure()

    # AXES
    mainimage_ax = Makie.Axis(fig[1, 1], aspect = size(im)[1] / size(im)[2], limits = ((0, size(im)[1]), (0, size(im)[2])))
    frameslider_pos = fig[2, 1]

    # TODO: Add minimap to left top corner of mainimage_ax, that will show all the things as in the
    # true image but smaller.. including the locations <06-04-22> 

    # State Observables
    frameslider = Slider(frameslider_pos, range = 1:size(im)[3])
    curframe = frameslider.value
    Label(frameslider_pos, lift(idx -> "$(idx)/$(size(im)[3])", curframe), tellwidth = false)
    # }}}

    # A collection of plots associated with the frame -> when the frame changes, previous frame
    # associated plots are made invisible and the plots for the current frame are shown
    frameplots = Vector{Dict{Symbol,AbstractPlot}}(undef, size(im)[3])
    for i in 1:length(frameplots)
        frameplots[i] = Dict{Symbol,AbstractPlot}()
    end

    # TODO: Should be done with PriorityObservable
    curplots = @lift frameplots[$curframe]
    on(curplots) do plots
        # TODO: Should be split into more Priority Ons that
        # 1. One that creates the plot if it does not exist -> Bigger priority
        # 2. One that shows the plots that are neccesarry to show 
        # 3. One that restores the limits <kunzaatko> 
        for (_, plot) in plots
            # @debug "Making $plot visible on frame $(curframe[])"
            plot.visible = true
        end
    end

    on(curplots) do plots
        if !haskey(plots, :image) # image for this frame is not yet created
            lims = mainimage_ax.finallimits[] # limits to be restored on frame change
            plots[:image] = image!(mainimage_ax, im[:, :, curframe[]], interpolate = false, inspectable = false)
            limits!(mainimage_ax, lims)
        end
    end

    # NOTE: In theory only one should suffice here, but sometimes the slider is too fast and the
    # later image is pushed before the previous is made invisible. Anything additional is used as an error
    # margin for the async `on` functions to avoid bugs due to access races. <06-04-22> 
    visitedframes = CircularBuffer(3)

    # On change of frame
    on(curframe) do frame
        foreach(f -> begin # make the previous plots invisible
                if f != frame # NOTE: Checked here, because it is possible to land on the same frame and notifying `curframe` using the slider
                    for (_, plot) in frameplots[f]
                        plot.visible = false
                    end
                end
            end, visitedframes)
        push!(visitedframes, frame)
    end

    # Global hotkey events
    on(events(fig).keyboardbutton) do event
        if event.action in (Keyboard.press, Keyboard.repeat)
            if ispressed(fig, hotkeys[:prev_frame])
                set_close_to!(frameslider, curframe[] - 1)
            end
            if ispressed(fig, hotkeys[:next_frame])
                set_close_to!(frameslider, curframe[] + 1)
            end
        end
        return Consume(false)
    end

    # TODO: Add lifts for current frame locs and selected_loc <18-04-22> 
    # Collected data
    selected_loc = Vector{Observable{Selected}}(undef, size(im)[3])
    for i in 1:length(selected_loc)
        selected_loc[i] = Observable(Selected(nothing))
    end

    locs = Vector{Vector{Location}}(Vector(undef, size(im)[3]))
    for i in 1:length(locs)
        locs[i] = Vector{Location}(undef, 0)
    end
    locs = locs |> Observable

    olocs = [Observable(OffsetVector(locs[], -i)) for i in 1:size(im)[3]]

    on(curplots) do plots
        if !haskey(plots, :locations) # image for this frame is not yet created
            lims = mainimage_ax.finallimits[] # limits to be restored on frame change
            plots[:locations] = locations!(mainimage_ax, selected_loc[curframe[]], olocs[curframe[]]; locations_attrs...)
            limits!(mainimage_ax, lims)
        else
            notify(olocs[curframe[]])
        end
    end
    notify(curframe)

    # TODO: How to represent tracks? <06-04-22> 
    # tracks = Observable{Vector{Vector}}()

    function add_loc(location)
        push!(locs[][curframe[]], location)
        selected_loc[curframe[]][].idx = length(locs[][curframe[]])
        notify(olocs[curframe[]])
    end

    # Adding locations
    on(events(mainimage_ax.scene).mousebutton, priority = 2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if ispressed(mainimage_ax.scene, hotkeys[:add_loc])
                # Add location
                location = Location(curframe[], mouseposition(mainimage_ax.scene))
                @debug "Adding location on frame $(curframe[]) with value $location"
                add_loc(location)
                return Consume(true)
            else
                for (category, annotation_key) in zip(categories, hotkeys[:annotation])
                    if ispressed(mainimage_ax.scene, annotation_key)
                        # Add location with category
                        location = Location(curframe[], mouseposition(mainimage_ax.scene), category)
                        @debug "Adding location on frame $(curframe[]) with value $location"
                        add_loc(location)
                        return Consume(true)
                    end
                end
            end
        end
        return Consume(false)
    end

    function sel_loc(; measurefunc = norm)
        xy = round.(Makie.mouseposition(mainimage_ax.scene))
        curloc_pos = getfield.(locs[][curframe[]], :point)

        @debug "`sel_loc`" curloc_pos xy
        distances = measurefunc.(curloc_pos .- xy)
        @debug "`sel_loc`" distances
        selected_loc[curframe[]][].idx = argmin(distances)
        notify(selected_loc[curframe[]])
    end

    # Selecting locations
    on(events(mainimage_ax.scene).mousebutton, priority = 2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if ispressed(mainimage_ax.scene, hotkeys[:select_loc])
                sel_loc()
            end
        end
    end

    # Changing category of selected
    on(events(fig).keyboardbutton, priority = 1) do event
        if event.action == Keyboard.release
            for (category, annotation_keys) in zip(categories, hotkeys[:annotation])
                if any(ispressed(mainimage_ax.scene, annotation_keys)) && selected_loc[curframe[]][].idx !== nothing
                    @debug "Changing category on frame $(curframe[]) for location $(locs[][curframe[]][selected_loc[curframe[]][].idx]) to $category"
                    locs[][curframe[]][selected_loc[curframe[]][].idx].category = category
                    @debug "Location changed on frame $(curframe[]) to $(locs[][curframe[]][selected_loc[curframe[]][].idx])"
                    notify(olocs[curframe[]])

                    return Consume(true)
                end
            end
        end
        return Consume(false)
    end

    # TODO: Position with minimap <04-04-22> 
    # TODO: TickBox for color change and tracks from prev image <04-04-22> 
    # TODO: Exporting the final data collected into tables <04-04-22> 
    # TODO: DataInspector <04-04-22> 

    DataInspector(fig)
    display(fig)
end

# TODO: Method for image with the filename instead of passing the image <06-04-22> 

end
