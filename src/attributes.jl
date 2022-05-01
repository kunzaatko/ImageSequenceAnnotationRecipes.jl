module AttributeModifiers
using ColorTypes
# TODO: Make these more constructable 
function dim!(x::Dict, factor = 0.5)
    if typeof(x[:color]) <: Tuple{<:Colorant,<:Real}
        col = HSL(x[:color][1])
        x[:color] = (HSL(col.h, min(col.s * factor, 1.0), col.l), x[:color][2])
    elseif typeof(x[:color]) <: Colorant
        col = HSL(x[:color])
        x[:color] = HSL(col.h, min(col.s * factor, 1.0), col.l)
    else
        error("Unknown `:color` type")
    end
end
saturate!(x::Dict, factor = 0.5) = dim!(x, 1 / factor)

function darken!(x::Dict, factor = 0.5)
    if typeof(x[:color]) <: Tuple{<:Colorant,<:Real}
        col = HSL(x[:color][1])
        x[:color] = (HSL(col.h, col.s, min(col.l * factor, 1)), x[:color][2])
    elseif typeof(x[:color]) <: Colorant
        col = HSL(x[:color])
        x[:color] = HSL(col.h, col.s, min(col.l * factor, 1))
    else
        error("Unknown `:color` type")
    end
end

function marker!(x::Dict, marker)
    x[:marker] = marker
end

function reduce_marker_size!(x::Dict, factor = 2.0)
    x[:markersize] = x[:markersize] / factor
end
increase_marker_size!(x::Dict, factor = 2.0) = reduce_marker_size!(x, 1 / factor)

function increase_transparency!(x::Dict, factor = 0.5)
    if typeof(x[:color]) <: Tuple{<:Colorant,<:Real}
        x[:color] = (x[:color][1], min(max(x[:color][2] * factor, 0), 1))
    elseif typeof(x[:color]) <: Union{Colorant,Symbol}
        x[:color] = (x[:color], factor)
    end
end
reduce_transparency!(x::Dict, factor = 0.5) = increase_transparency!(x, 1 / factor)
end
