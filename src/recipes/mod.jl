module Recipes
include("locationslayers.jl")
using .LocationsLayers
export locationslayer, locationslayer!, LocationsLayer

include("imagesequences.jl")
using .ImageSequences
export imagesequence, imagesequence!, ImageSequence

end
