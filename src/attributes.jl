module AttributeModifiers
using Makie: Attributes
using ColorTypes
# TODO: These should use Attributes instead <03-05-22> 
# TODO: Make these more constructable, perhaps with a macro that makes the calls to the acctual
# function with factor
function saturation_key!(x::Attributes, factor::Real, key::Symbol)
    @assert factor > 0 "The `factor` argument be between 0 and 1"
    @assert key in keys(x) "$key is not in attributes $x"
    col = parse(Color, x[key][])
    col = convert(HSLA, col)
    x[key] = HSLA(col.h, min(col.s * factor, 1.0), getfield.(col, [:l, :alpha])...)
end
dim!(x::Attributes, factor = 0.2, keys = [:color, :strokecolor]) = foreach(key ->haskey(x, key) && saturation_key!(x, 1 - factor, key), keys)
saturate!(x::Attributes, factor = 0.2, keys = [:color, :strokecolor]) = foreach(key -> haskey(x, key) && saturation_key!(x, 1 + factor, key), keys)
dim_color!(x::Attributes, factor = 0.2) = saturation_key!(x, 1 - factor, :color)
saturate_color!(x::Attributes, factor = 0.2) = saturation_key!(x, 1 + factor, :color)
dim_strokecolor!(x::Attributes, factor = 0.2) = saturation_key!(x, 1 - factor, :strokecolor)
saturate_strokecolor!(x::Attributes, factor = 0.2) = saturation_key!(x, 1 + factor, :strokecolor)

function lightness_key!(x::Attributes, factor::Real, key::Symbol)
    @assert factor > 0 "The `factor` argument be between 0 and 1"
    @assert key in keys(x) "$key is not in attributes $x"
    col = parse(Color, x[key][])
    col = convert(HSLA, col)
    x[key] = HSLA(getfield.(col, [:h, :s])..., min(col.l * factor, 1), col.alpha)
end
darken!(x::Attributes, factor = 0.2, keys = [:color, :strokecolor]) = foreach(key -> haskey(x, key) && lightness_key!(x, 1 - factor, key), keys)
lighten!(x::Attributes, factor = 0.2, keys = [:color, :strokecolor]) = foreach(key -> haskey(x, key) && lightness_key!(x, 1 + factor, key), keys)
darken_color!(x::Attributes, factor = 0.2) = lightness_key!(x, 1 - factor, :color)
lighten_color!(x::Attributes, factor = 0.2) = lightness_key!(x, 1 + factor, :color)
darken_strokecolor!(x::Attributes, factor = 0.2) = lightness_key!(x, 1 - factor, :strokecolor)
lighten_strokecolor!(x::Attributes, factor = 0.2) = lightness_key!(x, 1 + factor, :strokecolor)

function transparency_key!(x::Attributes, factor::Real, key::Symbol)
    @assert factor > 0 "The `factor` argument be between 0 and 1"
    @assert key in keys(x) "$key is not in attributes $x"
    col = parse(Color, x[key][])
    col = convert(RGBA, col)
    x[key] = RGBA(getfield.(col, [:r, :g, :b])..., min(col.alpha * factor, 1))
end
decrease_transparency!(x::Attributes, factor = 0.2, keys = [:color, :strokecolor]) = foreach(key -> haskey(x, key) && transparency_key!(x, 1 + factor, key), keys)
increase_transparency!(x::Attributes, factor = 0.2, keys = [:color, :strokecolor]) = foreach(key -> haskey(x, key) && transparency_key!(x, 1 - factor, key), keys)
decrease_transparency_color!(x::Attributes, factor = 0.2) = transparency_key!(x, 1 + factor, :color)
increase_transparency_color!(x::Attributes, factor = 0.2) = transparency_key!(x, 1 - factor, :color)
decrease_transparency_strokecolor!(x::Attributes, factor = 0.2) = transparency_key!(x, 1 + factor, :strokecolor)
increase_transparency_strokecolor!(x::Attributes, factor = 0.2) = transparency_key!(x, 1 - factor, :strokecolor)

function marker!(x::Attributes, marker)
    # TODO: Should convert to unifiing marker type. Same as color. <02-05-22> 
    @assert :marker in keys(x) "$key is not in attributes $x"
    x[:marker] = marker
end

function markersize!(x::Attributes, factor::Real)
    @assert :markersize in keys(x) "$key is not in attributes $x"
    x[:markersize] = x[:markersize][] * factor
end
decrease_markersize!(x::Attributes, factor = 0.2) = markersize!(x, 1 - factor)
increase_markersize!(x::Attributes, factor = 0.2) = markersize!(x, 1 + factor)
end
