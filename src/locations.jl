# TODO: Make this a separate module <28-04-22> 
# TODO: Test notifying the plots input arguments <27-04-22> 
import Makie: convert_arguments, Scatter
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
        scatter_attributes = (; markerspace = SceneSpace),
        visible = true
    )
end

argument_names(::Type{<:LocationsLayer}) = (:layeroffset, :selected, :locations)

# FIX: When the depth and height are greater that 0, this throws an error <18-04-22> 
function Makie.plot!(
    loc_layer::LocationsLayer{<:Tuple{<:Integer,SelectedLocation,<:AbstractVector{Location}}})

    layeroffset = loc_layer[1]
    selected = loc_layer[2]
    locations = loc_layer[3]

    attributes_dict = @lift begin
        # NOTE: These are all the attributes of a scatter plot that could be a Vector with a value
        # for each point of the scatterplot <kunzaatko> 
        fallback_attributes = Dict(:color => HSL(60, 0.5,0.9), :markersize => 2, :marker => :hexagon, :markersize => 1., :rotations => 0.0, :strokecolor => HSL(0.,0.,0.))
        fallback_attributes = haskey($(loc_layer.annotation_attributes), :fallback) ? merge(fallback_attributes, $(loc_layer.annotation_attributes)[:fallback]) : fallback_attributes
        res = Dict(:fallback => fallback_attributes)
        for (k, v) in $(loc_layer.annotation_attributes)
            res[k] = merge(fallback_attributes, v)
        end
        res
    end

    function get_attributes(loc::Location, idx::Integer)
        category = loc.category
        base_attributes = category in keys(attributes_dict[]) ? attributes_dict[][category] : attributes_dict[][:fallback]
        attributes = loc_layer.offset_conversion_function[](copy(base_attributes); offset = layeroffset[])
        if selected[] == idx
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
                append!(plt_attributes[k][], Vector(undef, loc_len - attrs_len))
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

    points = Observable{Vector{Point{2,Real}}}(getfield.(locations[], :point)) # initial values of locations
    plt_attributes = Attributes(Dict((k, Vector(undef, 0)) for k in keys(attributes_dict[][:fallback]))) # undefined vectors to pass as attributes
    set_attributes!(plt_attributes, locations[])

    plt = scatter!(loc_layer, points; plt_attributes..., loc_layer.scatter_attributes..., visible = loc_layer.visible)

    function on_locations(locations)
        @debug "Running `on_locations`"
        empty!(points[])
        append!(points[], getfield.(locations, :point))
        set_attributes!(plt.attributes, locations)
        notify_attributes(plt.attributes)
        notify(points)
    end
    on(on_locations, locations)

    function set_all_attributes(_, _, _)
        @debug "Running `set_all_attributes`"
        set_attributes!(plt.attributes, locations[])
        notify_attributes(plt.attributes)
    end
    onany(set_all_attributes, loc_layer.offset_conversion_function, loc_layer.annotation_attributes, layeroffset)

    function on_selected(selected, _)
        @debug "Running `on_selected`"
        if selected !== nothing
            set_attributes!(plt.attributes, locations[][selected], selected)
        end
    end
    onany(on_selected, selected, loc_layer.selected_conversion_function)

    # FIX: Every time one of `locations`, `layeroffset` or `selected` is inspected, the listeners
    # are called. This leads to them being called even when they are not needed. <kunzaatko> 
    # TODO: Ask on discourse <27-04-22> 

    return loc_layer
end
