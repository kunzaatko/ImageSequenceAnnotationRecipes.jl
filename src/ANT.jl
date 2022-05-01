module ANT
using Makie, Images, DataStructures, GeometryBasics
include("locations.jl")

export annotationtool, GUI_HOTKEYS, ANNOTATION_HOTKEYS

# TODO: Allow to define full HOTKEY including the mouseclick. This would be useful for example with
# using 'middle_mouse_button' for selection
GUI_HOTKEYS = Dict{Symbol,Any}(
    :prev_frame => (Keyboard.left | Keyboard.h),
    :next_frame => (Keyboard.right | Keyboard.l),
    :home => Keyboard.home,
    :del_loc => Keyboard.d,
    :sel_loc => Keyboard.s,
)

ANNOTATION_HOTKEYS = [
    (Keyboard.a | Keyboard._0 | Keyboard.i),
    (Keyboard.q | Keyboard._1),
    (Keyboard.w | Keyboard._2),
    (Keyboard.e | Keyboard._3),
    (Keyboard.r | Keyboard._4),
    Keyboard._5,
    Keyboard._6,
    Keyboard._7,
    Keyboard._8,
    Keyboard._9]


# TODO: Add posibility to drag image into figure with Union{..., Nothing} on im and Event
# dropped_files <04-04-22> 
# TODO: previous input insertion <04-04-22> 
# TODO: Make supplying the figure to draw on possible <21-04-22> 
# TODO: Make the package a library. Split functionality into functions providing separate features
# and make it more composable. <28-04-22> 
"""
    annotationtool(im_seq::AbstractArray{<:Colorant,3}; args...)

The only required argument is `im_seq` which is a sequence of images represented by a 3-dimensional array where the first 2 axes are spacial and the 3rd is the sequence dimension.
"""
function annotationtool(
    # Image sequence
    im::AbstractArray{<:Colorant,3};
    # Keys mapped to base functions
    gui_hotkeys::Dict{Symbol,Any} = GUI_HOTKEYS,
    # Annotation symbols, that are mapped to keytriggers
    annotation_hotkeys::Dict{Union{Symbol,Nothing},Any} = Dict(zip(pushfirst!(Vector{Union{Symbol,Nothing}}(Symbol.(1:9)), nothing), ANNOTATION_HOTKEYS)), # NOTE: Will be determined if the data is passed in
    # Attributes to pass to locations
    locations_attrs = (;),
    location_depth = 0,
    location_heigh = 0
)

    #  Scene setup {{{
    fig = Figure()

    # AXES
    baselimits = HyperRectangle(0.0, 0.0, Real.(size(im)[1:2])...)
    mainimage_ax = Makie.Axis(fig[1, 1], aspect = size(im)[1] / size(im)[2], limits = ((0, size(im)[1]), (0, size(im)[2])))
    frameslider_pos = fig[2, 1]

    # TODO: Add minimap to left top corner of mainimage_ax, that will show all the things as in the
    # true image but smaller.. including the locations <06-04-22> 

    # State Observables
    frameslider = Slider(frameslider_pos, range = 1:size(im)[3])
    curframe = frameslider.value
    Label(frameslider_pos, lift(idx -> "$(idx)/$(size(im)[3])", curframe), tellwidth = false)
    # }}}

    change_visibility(plot; value::Bool) = begin
        @assert haskey(plot, :visible) "Plot does not have `:visible` attribute"
        plot.visible = value
    end

    visible(plot) = change_visibility(plot, value = true)
    not_visible(plot) = change_visibility(plot, value = false)
    visible(plots::AbstractVector) = visible.(plots)
    not_visible(plots::AbstractVector) = not_visible.(plots)

    # A collection of plots associated with the frame -> when the frame changes, previous frame
    # associated plots are made invisible and the plots for the current frame are shown
    frameplots = Vector{Dict{Symbol,AbstractPlot}}(undef, size(im)[3])
    for i in 1:length(frameplots)
        frameplots[i] = Dict{Symbol,AbstractPlot}()
        frameplots[i][:image] = image!(mainimage_ax, im[:, :, i], interpolate = false, inspectable = false, depth_shift = 0.0, visible = false)
    end

    # TODO: Should be done with PriorityObservable
    curplots = @lift frameplots[$curframe]
    on(curplots) do plots
        for (_, plot) in plots
            @debug "Making $plot visible on frame $(curframe[])"
            visible(plot)
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
                        not_visible(plot)
                    end
                end
            end, visitedframes)
        push!(visitedframes, frame)
    end

    # Global hotkey events
    on(events(fig).keyboardbutton) do event
        if event.action in (Keyboard.press, Keyboard.repeat)
            if ispressed(fig, gui_hotkeys[:prev_frame])
                set_close_to!(frameslider, curframe[] - 1)
            end
            if ispressed(fig, gui_hotkeys[:next_frame])
                set_close_to!(frameslider, curframe[] + 1)
            end
            if ispressed(fig, gui_hotkeys[:home])
                limits!(mainimage_ax, baselimits)
            end
        end
        return Consume(false)
    end


    # TODO: Add lifts for current frame locs and selected_loc <18-04-22> 
    # Collected data
    selected_loc = Vector{Observable{SelectedLocation}}(undef, size(im)[3])
    for i in 1:length(selected_loc)
        selected_loc[i] = 1 |> Observable{SelectedLocation}
    end

    locs = Vector{Observable{Vector{Location}}}(Vector(undef, size(im)[3]))
    for i in 1:length(locs)
        locs[i] = Location[] |> Observable
    end

    locations_reminder = nothing
    on(curplots) do plots
        if !haskey(plots, :locations) # image for this frame is not yet created
            if length(locs[curframe[]][]) == 0
                locations_reminder = on(locs[curframe[]], weak = true) do locs
                    @debug "In `locations_reminder` for frame $(curframe[])"
                    notify(curplots)
                end
                # TODO: This should be included rather in the logic of the LocationsLayer @recipe
                # because it should be possible to plot an empty locations vector <28-04-22> 
                @debug "Registering `locations_reminder` for frame $(curframe[])"
                return # NOTE: Otherwise GLMakie backend throws stack overflow exception
            else
                @debug "Removing `locations_reminder` for frame $(curframe[])"
                locations_reminder = nothing
            end
            lims = mainimage_ax.finallimits[] # limits to be restored on frame change
            plots[:locations] = locationslayer!(mainimage_ax, 0, selected_loc[curframe[]], locs[curframe[]]; locations_attrs...)
            limits!(mainimage_ax, lims)
        end
    end
    notify(curframe)

    # TODO: How to represent tracks? <06-04-22> 
    # tracks = Observable{Vector{Vector}}()

    function add_loc(location)
        push!(locs[curframe[]][], location)
        selected_loc[curframe[]][] = length(locs[curframe[]][])
        notify(locs[curframe[]])
    end

    for (category, hotkey) in annotation_hotkeys
        # Adding locations
        on(events(mainimage_ax.scene).mousebutton, priority = 2) do mouse_event
            if mouse_event.button == Mouse.left && mouse_event.action == Mouse.press && ispressed(mainimage_ax.scene, hotkey)
                location = Location(curframe[], mouseposition(mainimage_ax.scene), category)
                @debug "Adding location on frame $(curframe[]) with value $location"
                add_loc(location)
                return Consume(true)
            end
        end

        # Changing category of selected
        on(events(mainimage_ax.scene).keyboardbutton, priority = 1) do keyboard_event
            if keyboard_event.action == Keyboard.press && ispressed(mainimage_ax.scene, hotkey & (Keyboard.right_alt | Keyboard.left_alt))
                selected_loc[curframe[]][] !== nothing
                @debug "Changing category on frame $(curframe[]) for location $(locs[curframe[]][][selected_loc[curframe[]][]]) to $category"
                locs[curframe[]][][selected_loc[curframe[]][]].category = category
                @debug "Location changed on frame $(curframe[]) to $(locs[curframe[]][][selected_loc[curframe[]][]])"
                notify(locs[curframe[]])
                return Consume(true)
            end
            return Consume(false)
        end
    end

    function sel_loc(; measurefunc = norm)
        xy = round.(Makie.mouseposition(mainimage_ax.scene))
        curloc_pos = getfield.(locs[curframe[]][], :point)

        @debug "`sel_loc`" curloc_pos xy
        distances = measurefunc.(curloc_pos .- xy)
        @debug "`sel_loc`" distances
        selected_loc[curframe[]][] = argmin(distances)
        notify(selected_loc[curframe[]])
    end

    # Selecting locations
    on(events(mainimage_ax.scene).mousebutton, priority = 2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if ispressed(mainimage_ax.scene, gui_hotkeys[:sel_loc])
                sel_loc()
                return Consume(true)
            end
        end
    end


    # TODO: Position with minimap <04-04-22> 
    # TODO: TickBox for color change and tracks from prev image <04-04-22> 
    # TODO: Exporting the final data collected into tables <04-04-22> 

    # FIX: DataInspector throws an error when called. `DimensionMismatch("arrays could not be broadcast to a common size")` <27-04-22>
    # DataInspector(fig) 
    display(fig)
end

annotationtool(
    im::AbstractArray{<:Colorant,3},
    categories::Vector{Symbol};
    args...
) = annotationtool(im; annotation_hotkeys = Dict(zip(pushfirst!(Vector{Union{Symbol,Nothing}}(categories), nothing), ANNOTATION_HOTKEYS)), args...)

# TODO: Method for image with the filename instead of passing the image <06-04-22> 

end
