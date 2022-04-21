import Makie: convert_arguments, Scatter
import Base.==
using OffsetArrays
using ColorSchemes
using GeometryBasics

export Location, Selected

mutable struct Location
    time::Integer
    point::Point{2,Real}
    category::Union{Nothing,Symbol}
end

Location(frame::Integer, p::Point) = Location(frame, p, nothing)

==(a::Location, b::Location) = a.time == b.time && a.point == b.point && a.category == b.category

Makie.convert_arguments(P::Type{<:Scatter}, locations::Vector{Location}) = convert_arguments(P, getfield.(locations, :point))
Makie.convert_arguments(P::Type{<:Scatter}, location::Location) = convert_arguments(P, location.point)

@recipe(Locations) do scene
    Attributes(
        # marker colorschemes -> below will be darker and above lighter by default
        colors = Dict{Union{Integer,Symbol},ColorScheme}(
            0 => ColorSchemes.tol_bu_rd, # default
            1 => ColorSchemes.Greens_9,
            2 => ColorSchemes.Purples_9,
            3 => ColorSchemes.Oranges_9,
            4 => ColorSchemes.Blues_9,
        ), # has to include the 0 key for the default colors of the location
        depth = 0,  # number of location layers to show below current layer
        height = 0, # number of location layers to show above current layer
        above_attributes = (; marker = :circle, markersize = 6),
        below_attributes = (; marker = :square, markersize = 6),
        base_attributes = (; marker = :cross, markersize = 9),
        selected_attributes = (; marker = :circle, markersize = 12),
        visible = true
    )
end

# TODO: Handle the colors in a different way so that the colors are muted in both directions the
# same way... Depth and height can then be distinguished by shape and size for example <11-04-22, kunzaatko> 

argument_names(::Type{<:Locations}) = (:selected, :locations,)

mutable struct Selected
    idx::Union{Nothing,<:Integer}
end
# FIX: When the depth and height are greater that 0, this throws an error <18-04-22> 
function Makie.plot!(
    locs::Locations{<:Tuple{Selected,OffsetVector{<:AbstractVector{Location}}}})

    selected = locs[1]
    locations = locs[2]

    points = Observable(OffsetVector(Observable(Location[])[], 0))
    categories = Observable(Symbol[])
    colors = Observable(OffsetVector(Observable(Colorant[])[], 0))
    point_selected = (; points = Observable{Vector{Point{2,Real}}}(Point[]), colors = Observable{Vector{Colorant}}(Vector(undef, 0)))
    points_notselected = (; points = Observable{Vector{Point{2,Real}}}(Point[]), colors = Observable{Vector{Colorant}}(Vector(undef, 0)))

    # PERF: This is not necessary to do for all of the updates on any of the variable changes. 
    # TODO: Should check for and filter the actions that really need to be made if this is too slow.  
    function on_updateplot(locations, selected, depth, height)
        # points
        start_index = max((-depth), (locations.offsets[1] + 1))
        end_index = min(height, (length(locations) - locations.offsets[1]))
        points = OffsetVector(map(l -> Observable(l), locations[start_index:end_index]), (-depth - 1)) |> Observable
        @debug "`on_updateplot` set points" points

        # categories
        categories = map(i -> filter(c -> c !== nothing, getfield.(i, :category)), locations) |> Iterators.flatten |> unique |> sort |> Observable
        @assert all(typeof.(categories[]) .== Symbol) "Category not of type symbol at $(typeof.(categories[]) .!= Symbol) where $(categories[][typeof.(categories[]) .!= Symbol])"
        @debug "`on_updateplot` set categories" categories

        # a dictionary, where every category has an assigned colorscheme -> that is later used for
        # geneteration of the layer colors for different categories
        # NOTE: no category, represented by nothing is represented by `:nothing` key in this dict <10-04-22> 
        cat_col_dict = lift(locs.colors, categories) do colors, categories
            # FIX: This will not work if there is not enough colors in the attributes <10-04-22> 
            idx = 0
            cat_or_ind = [
                begin
                    if haskey(colors, cat)
                        colors[cat]
                    else
                        idx += 1
                        idx
                    end
                end for cat in categories
            ]
            col_cat = zip(categories, map(c_or_i -> colors[c_or_i], cat_or_ind)) |> Dict{Symbol,ColorScheme}
            col_cat[:nothing] = colors[0]
            return col_cat
        end
        @debug "`on_updateplot` set cat_col_dict" cat_col_dict

        colors = lift(points, cat_col_dict) do points, cat_col
            layer_num = locs.depth[] + locs.height[] + 1
            layer_intensities = if layer_num > 1
                range(0.3, 1, length = layer_num)
            else
                [0.5]
            end
            @debug "Colors in `lift` with " layer_num layer_intensities
            colors = Vector{Observable{Vector{Colorant}}}(undef, layer_num)
            for (idx, (layer_intensity, layer)) in enumerate(zip(layer_intensities, points))
                @assert eltype(layer[]) == Location "eltype of layer is $(eltype(layer))"
                layer_categories = map(loc -> if loc.category !== nothing
                        loc.category
                    else
                        :nothing
                    end, layer[])
                @assert all(typeof.(layer_categories) .== Symbol) "Categories not defined correctly. Some type was not `Symbol`"
                @assert all(map(cat -> haskey(cat_col, cat), layer_categories)) "Not all categories have defined colors in `cat_col_dict`"
                colors[idx] = map(lcat -> get(cat_col[lcat], layer_intensity), layer_categories) |> Observable
                @assert eltype(colors[idx][]) <: Colorant "Not a good color $(eltype(colors[idx][]))"
            end
            colors = OffsetVector(colors, (-locs.depth[] - 1))
            @assert colors.offsets == points.offsets "colors offsets $(colors.offsets) are not equal to points offsets $(points.offsets)"
            @assert all(length(c[]) == length(p[]) for (c, p) in zip(colors, points)) "colors and points do not have equal lengths"
            @debug "setting color in `lift`" colors
            return colors
        end


        @debug "Running `on_selected` with selected" selected
        empty!(point_selected.points[])
        empty!(point_selected.colors[])
        info = 0
        while length(colors[][0][]) != length(points[][0][])
            sleep(1e-4)
            if info == 0
                @debug "Waiting for color update in `on_selected`"
            end
            info += 1
            if info == 400
                @debug "colors" colors[][0][] " with length" length(colors[][0][])
                @debug "points" points[][0][] " with length" length(points[][0][])
                return @error "color not the same length as points" colors[] points[]
            end
        end
        if info > 0
            @debug "Waited $info ms for color update"
        end
        if selected.idx !== nothing
            empty!(points_notselected.points[])
            empty!(points_notselected.colors[])
            push!(point_selected.points[], points[][0][][selected.idx].point)
            push!(point_selected.colors[], colors[][0][][selected.idx])
            notselected_indexes = collect(1:length(points[][0][]))
            popat!(notselected_indexes, selected.idx)
            append!(points_notselected.points[], getfield.(points[][0][][notselected_indexes], :point))
            append!(points_notselected.colors[], colors[][0][][notselected_indexes])
            notify(points_notselected.points)
            notify(points_notselected.colors)
        else
            points_notselected.points[] = getfield.(points[][0][], :point)
            points_notselected.colors[] = colors[][0][]
        end
        notify(point_selected.points)
        notify(point_selected.colors)
    end
    on_updateplot(locations[], selected[], locs.depth[], locs.height[]) # starting locations
    Makie.Observables.onany(on_updateplot, locations, selected, locs.depth, locs.height)


    # FIX: This will not work if the depth or height is changed <10-04-22> 
    if locs.depth[] > 0
        for (cs, ls) in zip(colors[][begin:-1], points[][begin:-1])
            scatter!(locs, ls; color = cs, locs.below_attributes..., visible = locs.visible)
        end
    end

    if locs.height[] > 0
        for (cs, ls) in zip(colors[][1:end], points[][1:end])
            scatter!(locs, ls; color = cs, locs.above_attributes..., visible = locs.visible)
        end
    end


    scatter!(locs, points_notselected.points; color = points_notselected.colors, locs.base_attributes..., visible = locs.visible)
    scatter!(locs, point_selected.points; color = point_selected.colors, locs.base_attributes..., locs.selected_attributes..., visible = locs.visible)

    locs
end


Makie.convert_arguments(P::Type{<:Locations}, selected::Union{Nothing,<:Integer}, locations::OffsetVector{<:AbstractVector{Location}}) = Makie.convert_arguments(P, Selected(selected), locations)
Makie.convert_arguments(P::Type{<:Locations}, selected::Union{Nothing,<:Integer}, locations::Vector{<:AbstractVector{Location}}, layer::Integer) = Makie.convert_arguments(P, Selected(selected), OffsetVector(locations, -layer))
Makie.convert_arguments(P::Type{<:Locations}, locations::Vector{<:AbstractVector{Location}}, layer::Integer) = Makie.convert_arguments(P, nothing, OffsetVector(locations, -layer))
Makie.convert_arguments(P::Type{<:Locations}, locations::OffsetVector{<:AbstractVector{Location}}) = Makie.convert_arguments(P, nothing, locations)
