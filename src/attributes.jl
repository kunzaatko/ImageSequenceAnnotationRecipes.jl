module AttributeModifiers
using ColorTypes
# TODO: Make these more constructable 
function dim!(x::Dict, factor = 0.5)
    col = HSLA(x[:color])
    x[:color] = HSLA(col.h, min(col.s * factor, 1.0), getfield.(col, [:l, :alpha])...)
end
saturate!(x::Dict, factor = 0.5) = dim!(x, 1 / factor)

function darken!(x::Dict, factor = 0.5)
    col = HSLA(x[:color])
    x[:color] = HSLA(getfield.(col, [:h, :s])..., min(col.l * factor, 1), col.alpha)
end
lighten!(x::Dict, factor = 0.5) = darken!(x, 1 / factor)

function marker!(x::Dict, marker)
    # TODO: Should convert to unifiing marker type. Same as color. <02-05-22> 
    x[:marker] = marker
end

function reduce_marker_size!(x::Dict, factor = 2.0)
    x[:markersize] = x[:markersize] / factor
end
increase_marker_size!(x::Dict, factor = 2.0) = reduce_marker_size!(x, 1 / factor)

function increase_transparency!(x::Dict, factor = 0.5)
    x[:color] = RGBA(getfield.(x[:color], [:r, :g, :b])..., min(max(x[:color].alpha * factor, 0), 1))
end
reduce_transparency!(x::Dict, factor = 0.5) = increase_transparency!(x, 1 / factor)
end
