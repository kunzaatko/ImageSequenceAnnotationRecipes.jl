module ImageSequences
using Distributed
using DataStructures, Images
using Makie
import Makie: convert_arguments
import MakieCore: argument_names

export imagesequence, imagesequence!, ImageSequence

@recipe(ImageSequence) do scene
    Attributes(
        # Attributes to be used for the image plot. Including visible would break the mechanism for
        # showing the correct frame, so do not include `visible = true`.
        image_attributes = (; interpolate = false, inspectable = false),
        # The dimension that represents the slices
        dims = 3,
    )
end

argument_names(::Type{<:ImageSequence}, numargs::Integer) = numargs == 2 && (:frame, :sequence)

function Makie.plot!(
    im_sequence::ImageSequence{<:Tuple{Integer,<:AbstractArray{<:Colorant,3}}})

    if im_sequence.dims[] == 3
        frameim = @lift view($(im_sequence[:sequence]), :, :, $(im_sequence[:frame]))
    elseif im_sequence.dims[] == 2
        frameim = @lift view($(im_sequence[:sequence]), :, $(im_sequence[:frame]), :)
    elseif im_sequence.dims[] == 1
        frameim = @lift view($(im_sequence[:sequence]), $(im_sequence[:frame]), :, :)
    else
        error("Value of `dims` must be from 1 to 3. Instead is $(im_sequence.dims[]).")
    end

    image!(im_sequence, frameim; im_sequence.image_attributes...)

    return im_sequence
end

function convert_arguments(P::Type{<:ImageSequence}, frame::Integer, sequence_vec::AbstractVector{<:AbstractArray{<:Colorant,2}})
    im_sequence = cat(reshape.(sequence_vec, size(sequence_vec[1])..., 1)...; dims = 3)
    convert_arguments(P, frame, im_sequence)
end

end
