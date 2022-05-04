module AttributeModifiers
using ColorTypes
# TODO: These should use Attributes instead <03-05-22> 
# TODO: Make these more constructable, perhaps with a macro that makes the calls to the acctual
# function with factor
function saturation_key!(x::Dict, factor::Real, key::Symbol)
    @assert factor > 0 "The `factor` argument be between 0 and 1"
    @assert key in [:color, :strokecolor]
    col = HSLA(x[key])
    x[key] = HSLA(col.h, min(col.s * factor, 1.0), getfield.(col, [:l, :alpha])...)
end
dim!(x::Dict, factor = 0.2) = foreach(key -> saturation_key!(x, 1 - factor, key), [:color, :strokecolor])
saturate!(x::Dict, factor = 0.2) = foreach(key -> saturation_key!(x, 1 + factor, key), [:color, :strokecolor])
dim_color!(x::Dict, factor = 0.2) = saturation_key!(x, 1 - factor, :color)
saturate_color!(x::Dict, factor = 0.2) = saturation_key!(x, 1 + factor, :color)
dim_strokecolor!(x::Dict, factor = 0.2) = saturation_key!(x, 1 - factor, :strokecolor)
saturate_strokecolor!(x::Dict, factor = 0.2) = saturation_key!(x, 1 + factor, :strokecolor)

function lightness_key!(x::Dict, factor::Real, key::Symbol)
    @assert factor > 0 "The `factor` argument be between 0 and 1"
    @assert key in [:color, :strokecolor]
    col = HSLA(x[key])
    x[key] = HSLA(getfield.(col, [:h, :s])..., min(col.l * factor, 1), col.alpha)
end
darken!(x::Dict, factor = 0.2) = foreach(key -> lightness_key!(x, 1 - factor, key), [:color, :strokecolor])
lighten!(x::Dict, factor = 0.2) = foreach(key -> lightness_key!(x, 1 + factor, key), [:color, :strokecolor])
darken_color!(x::Dict, factor = 0.2) = lightness_key!(x, 1 - factor, :color)
lighten_color!(x::Dict, factor = 0.2) = lightness_key!(x, 1 + factor, :color)
darken_strokecolor!(x::Dict, factor = 0.2) = lightness_key!(x, 1 - factor, :strokecolor)
lighten_strokecolor!(x::Dict, factor = 0.2) = lightness_key!(x, 1 + factor, :strokecolor)

function transparency_key!(x::Dict, factor::Real, key::Symbol)
    @assert factor > 0 "The `factor` argument be between 0 and 1"
    @assert key in [:color, :strokecolor]
    x[key] = RGBA(x[key])
    x[key] = RGBA(getfield.(x[key], [:r, :g, :b])..., min(x[key].alpha * factor, 1))
end
decrease_transparency!(x::Dict, factor = 0.2) = foreach(key -> transparency_key!(x, 1 + factor, key), [:color, :strokecolor])
increase_transparency!(x::Dict, factor = 0.2) = foreach(key -> transparency_key!(x, 1 - factor, key), [:color, :strokecolor])
decrease_transparency_color!(x::Dict, factor = 0.2) = transparency_key!(x, 1 + factor, :color)
increase_transparency_color!(x::Dict, factor = 0.2) = transparency_key!(x, 1 - factor, :color)
decrease_transparency_strokecolor!(x::Dict, factor = 0.2) = transparency_key!(x, 1 + factor, :strokecolor)
increase_transparency_strokecolor!(x::Dict, factor = 0.2) = transparency_key!(x, 1 - factor, :strokecolor)

function marker!(x::Dict, marker)
    # TODO: Should convert to unifiing marker type. Same as color. <02-05-22> 
    x[:marker] = marker
end

function markersize!(x::Dict, factor::Real)
    x[:markersize] = x[:markersize] * factor
end
decrease_markersize!(x::Dict, factor = 0.2) = markersize!(x, 1 - factor)
increase_markersize!(x::Dict, factor = 0.2) = markersize!(x, 1 + factor)
end
