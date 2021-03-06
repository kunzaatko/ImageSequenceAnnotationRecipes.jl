using Makie
using Distributed
using StructArrays
import MakieCore: argument_names
import Makie: convert_arguments
using ColorTypes
using DataStructures
using ...AttributeModifiers
using ColorSchemes
export locationslayer, locationslayer!, LocationsLayer

function offset_conversion(x::Attributes; offset = 0)
    if offset > 0
        for _ in 1:offset
            AttributeModifiers.increase_transparency!(x)
            AttributeModifiers.lighten!(x)
            AttributeModifiers.decrease_markersize!(x)
        end
    elseif offset < 0
        for _ in offset:(-1)
            AttributeModifiers.increase_transparency!(x)
            AttributeModifiers.darken!(x)
            AttributeModifiers.decrease_markersize!(x)
        end
    end
end

function selected_conversion(x::Attributes)
    AttributeModifiers.increase_markersize!(x, 0.5)
    AttributeModifiers.saturate!(x)
    AttributeModifiers.lighten!(x)
    AttributeModifiers.decrease_transparency!(x)
end

@recipe(LocationsLayer) do scene
    Attributes(
        fallback_attributes = Attributes(:color => ColorSchemes.julia[4], :markersize => 2.0, :marker => :circle, :rotations => 0.0, :strokecolor => :black),
        # FIX: There is no need for this dict if there are only symbol attributes. This should be
        # handled by the parent attributes.
        # A dictionary that represents which attributes to use for the different categories.
        annotation_attributes = Dict{Any,Attributes}(),
        # A function that will convert the attributes of the points based on the offset from the
        # reference layer. (Should include an `offset` keyword argument)
        offset_conversion = offset_conversion,
        # A function that will convert the attributes of the given point
        selected_conversion = selected_conversion,
        # Attributes that do not have a vector nature to be used for the scatter plot
        scatter_attributes = (; strokewidth = 2.0, markerspace = :data),
        max_categories = 8,
        visible = true
    )
end

argument_names(::Type{<:LocationsLayer}, numargs::Integer) = numargs == 3 && (:offset, :selected, :locations)

function Makie.plot!(
    loc_layer::LocationsLayer{<:Tuple{Integer,Selected,AbstractVector{Location}}})

    # PERF: This makes the accessing of full vectors of properties much faster and therefore much faster
    # catergory index creations (especially for large vectors of locations) <kunzaatko> 
    locations_structvector = @lift StructVector($(loc_layer[:locations]))
    # Cached selected for when the restoring the previous selected to the normal state on change
    # NOTE: Changes on change of `loc_layer[:selected]` <kunzaatko> 
    selectedcache = loc_layer[:selected][]
    catbitarrays = lift(locations_structvector) do locs
        d = Dict(
            (cat !== nothing ? cat : :fallback) => (locs.category .== cat)
            for cat in unique(locs.category)
        )
        if !isnothing(selectedcache)
            selected_category = locs.category[selectedcache.idx]
            d[selected_category][selectedcache.idx] = 0
            d[:selected] = zeros(Bool, length(locs))
            d[:selected][selectedcache.idx] = true
        else
            d[:selected] = zeros(Bool, length(locs))
        end
        d
    end

    function convert_attributes(attrs::Attributes, offset::Integer, selected::Bool)
        loc_layer.offset_conversion[](attrs, offset = offset)
        selected && loc_layer.selected_conversion[](attrs)
    end

    # FIX: This is what merge! should do (#1939) <kunzaatko> 
    function set_attributes(attrs::Attributes, new::Attributes)
        for (k, v) in new
            attrs[k] = v[]
        end
    end

    # FIX: `merge` insonsistent. When #1939 resolved, can be fixed <kunzaatko> 
    get_base_attributes(category) = haskey(loc_layer.annotation_attributes[], category) ?
                                    merge(loc_layer.annotation_attributes[][category], loc_layer.fallback_attributes, loc_layer.scatter_attributes) : merge(loc_layer.fallback_attributes, loc_layer.scatter_attributes)

    loc_layer_cats = Dict{Any,NamedTuple{(:scatter, :positions, :base_attrs)}}()

    # NOTE: It is not possible to define more plots for the recipe after it finishes running. We
    # have to predefine some. <kunzaatko> 
    scatters = Vector(undef, loc_layer.max_categories[])
    scatters_task = @async for i in Base.OneTo(loc_layer.max_categories[])
        positions = Point2[] |> Observable
        scatter = scatter!(loc_layer, positions; loc_layer.fallback_attributes..., visible = loc_layer.visible)
        scatters[i] = (; scatter = scatter, positions = positions)
    end

    on(catbitarrays) do cbitarrays
        for (cat, idxs) in cbitarrays
            if !haskey(loc_layer_cats, cat) # create new entry
                wait(scatters_task)
                scatter, positions = pop!(scatters)
                base_attrs = get_base_attributes(cat)
                positions[] = locations_structvector[].point[idxs]
                @debug "Creating new scatter for category $cat with base attributes $base_attrs"
                loc_layer_cats[cat] = (; scatter = scatter, positions = positions, base_attrs = base_attrs)

                # convert the attributes
                new_attributes = copy(base_attrs)
                convert_attributes(new_attributes, loc_layer[:offset][], cat == :selected)
                set_attributes(scatter.attributes, new_attributes)

            else # update the points
                @debug "Updating category for category $cat"
                loc_layer_cats[cat][:positions][] = locations_structvector[].point[idxs]
            end
        end
    end

    function on_conversions(offset, _, _)
        for (cat, (scatter, _, base_attrs)) in loc_layer_cats
            new_attributes = copy(base_attrs)
            convert_attributes(new_attributes, offset, cat == :selected)
            set_attributes(scatter.attributes, new_attributes)
        end
    end
    onany(on_conversions, loc_layer[:offset], loc_layer.offset_conversion, loc_layer.selected_conversion)

    on(loc_layer[:selected]) do selected
        empty!(loc_layer_cats[:selected][:positions][])
        if !isnothing(selectedcache) # restore prev selected
            @debug "Updating locations on selectedcache $selectedcache"
            c, p = locations_structvector[].category[selectedcache.idx], locations_structvector[].point[selectedcache.idx]
            c = c === nothing ? :fallback : c
            catbitarrays.val[c][selectedcache.idx] = 1 # set without notify
            push!(loc_layer_cats[c][:positions][], p)
            notify(loc_layer_cats[c][:positions])
        end
        if !isnothing(selected)
            @debug "Updating locations on selected $selected"
            c, p = locations_structvector[].category[selected.idx], locations_structvector[].point[selected.idx]
            c = c === nothing ? :fallback : c
            catbitarrays.val[c][selected.idx] = 0 # set without notify
            push!(loc_layer_cats[:selected][:positions][], p)
            loc_layer_cats[c][:positions][] = locations_structvector[].point[catbitarrays[][c]]
        end
        notify(loc_layer_cats[:selected][:positions])
        selectedcache = selected
    end

    # Initial scatters (this is for making the additional scatter initializations @async)
    for (cat, idxs) in catbitarrays[]
        positions = locations_structvector[].point[idxs] |> Observable
        scatter = scatter!(loc_layer, positions; visible = loc_layer.visible)
        base_attrs = get_base_attributes(cat)
        loc_layer_cats[cat] = (; scatter = scatter, positions = positions, base_attrs = base_attrs)
    end
    on_conversions(loc_layer[:offset][], loc_layer.offset_conversion[], loc_layer.selected_conversion[])


    return loc_layer
end

convert_arguments(P::Type{<:LocationsLayer}, offset::Integer, selected::Union{Nothing,Integer}, locations::AbstractVector{Location}) = convert_arguments(P, offset, Selected(selected), locations)
