# TODO: Make this a separate module <28-04-22> 
# TODO: Test notifying the plots input arguments <27-04-22> 
import Makie: convert_arguments, Scatter
import MakieCore
using OffsetArrays
using ColorSchemes
using GeometryBasics

export Location, SelectedLocation, LocationsLayer

include("types.jl")

Makie.convert_arguments(P::Type{<:Scatter}, locations::Vector{Location}) = convert_arguments(P, getfield.(locations, :point))
Makie.convert_arguments(P::Type{<:Scatter}, location::Location) = convert_arguments(P, location.point)

include("attributes.jl")

@recipe(LocationsLayer) do scene
    Attributes(
        # A dictionary that represents which attributes to use for the different categories. Must
        # include `:fallback` key with a `NamedTuple` that includes all the keys that are used in
        # the '..._conversion_fuction's
        # NOTE: Using Dict, because NamedTuple type is immutable  
        annotation_attributes = Dict{Any,Dict{Symbol,Any}}(),
        # A function that will convert the attributes of the points based on the offset from the
        # reference layer. (Should include an `offset` keyword argument)
        offset_conversion_function = function (x::Dict; offset = 0)
            AttributeModifiers.increase_transparency!(x, 0.8^offset)
            return x
        end, #= TODO: =#
        # A function that will convert the attributes of the given point
        selected_conversion_function = function (x::Dict)
            AttributeModifiers.increase_marker_size!(x, 2)
            return x
        end, #= TODO: =#
        # Attributes that do not have a vector nature to be used for the scatter plot (in particular
        # visible )
        scatter_attributes = (; markerspace = SceneSpace, strokewidth = 2.0),
        visible = true
    )
end

# FIX: When changing selected from nothing to something. There is an error. It can be fixed with
# defining a new composite type where the field holds the value. <02-05-22> 
MakieCore.argument_names(::Type{<:LocationsLayer}, numargs::Integer) = numargs == 3 && (:layeroffset, :selected, :locations,)

function Makie.plot!(
    loc_layer::LocationsLayer{<:Tuple{<:Integer,SelectedLocation,<:AbstractVector{Location}}})

    attributes_dict = @lift begin
        # NOTE: These are all the attributes of a scatter plot that could be a Vector with a value
        # for each point of the scatterplot <kunzaatko> 
        # TODO: Use nord from ColorSchemes instead of defining this way. <02-05-22> 
        fallback_attributes = Dict(:color => RGBA{N0f8}(0.847, 0.871, 0.914, 1.0), :markersize => 2.0, :marker => :circle, :rotations => 0.0, :strokecolor => RGBA{N0f8}(0.231, 0.259, 0.322, 1.0))
        fallback_attributes = haskey($(loc_layer.annotation_attributes), :fallback) ? merge(fallback_attributes, $(loc_layer.annotation_attributes)[:fallback]) : fallback_attributes
        res = Dict(:fallback => fallback_attributes)
        for (k, v) in $(loc_layer.annotation_attributes)
            res[k] = merge(fallback_attributes, v)
        end
        res
    end

    @debug "Created attributes dict with values" attributes_dict

    function get_attributes(loc::Location, idx::Integer)
        category = loc.category
        base_attributes = category in keys(attributes_dict[]) ? attributes_dict[][category] : attributes_dict[][:fallback]
        attributes = loc_layer.offset_conversion_function[](copy(base_attributes); offset = loc_layer[:layeroffset][])
        if loc_layer[:selected][] == idx
            attributes = loc_layer.selected_conversion_function[](copy(attributes))
        end
        return attributes
    end

    # NOTE: Attributes themselves have to be notified <kunzaatko> 
    function set_attributes!(plt_attributes, loc::Location, idx::Integer)
        attributes = get_attributes(loc, idx)
        for (k, v) in attributes
            @assert k in keys(plt_attributes) && typeof(plt_attributes[k][]) <: AbstractVector "$k not in $(plt_attributes) or not a vector. Type is instead $(typeof(plt_attributes[k][]))"
            plt_attributes[k][][idx] = v
        end
    end

    function set_attributes!(plt_attributes, locs::AbstractVector{Location})
        loc_len = length(locs)
        for k in keys(attributes_dict[][:fallback])
            attrs_len = length(plt_attributes[k][])
            if attrs_len != loc_len
                fallback_attr_value = attributes_dict[][:fallback][k]
                append!(plt_attributes[k][], fill(fallback_attr_value, loc_len - attrs_len))
            end
        end
        for (idx, loc) in enumerate(locs)
            set_attributes!(plt_attributes, loc, idx)
        end
    end

    function notify_attributes(plt_attributes)
        for k in keys(attributes_dict[][:fallback])
            notify(plt_attributes[k])
        end
    end

    # FIX: Every time one of `locations`, `layeroffset` or `selected` is inspected, the listeners
    # are called. This leads to them being called even when they are not needed. <kunzaatko> 
    # TODO: Ask on discourse <27-04-22> 

    points = Point2[] |> Observable
    plt_attributes = Attributes(Dict(k => Observable(typeof(v)[]) for (k, v) in attributes_dict[][:fallback])) # undefined vectors to pass as attributes

    plt = scatter!(loc_layer, points; plt_attributes..., loc_layer.scatter_attributes..., visible = loc_layer.visible)

    function on_locations(locations)
        @debug "Running `on_locations`"
        empty!(points[])
        append!(points[], getfield.(locations, :point))
        set_attributes!(plt.attributes, locations)
        notify_attributes(plt.attributes)
        notify(points)
    end
    on(on_locations, loc_layer[:locations])

    function set_all_attributes(_, _, _)
        @debug "Running `set_all_attributes`"
        set_attributes!(plt.attributes, loc_layer[:locations][])
        notify_attributes(plt.attributes)
    end
    onany(set_all_attributes, loc_layer.offset_conversion_function, loc_layer.annotation_attributes, loc_layer[:layeroffset])

    function on_selected(selected, _)
        @debug "Running `on_selected`"
        if selected !== nothing
            set_attributes!(plt.attributes, loc_layer[:locations][][selected], selected)
        end
    end
    onany(on_selected, loc_layer[:selected], loc_layer.selected_conversion_function)

    on_locations(loc_layer[:locations][])

    return loc_layer
end
