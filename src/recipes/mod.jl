module Recipes
include("locations/mod.jl")
using .LocationsLayers
export locationslayer, locationslayer!, LocationsLayer

include("images/mod.jl")
using .ImageSequences
export imagesequence, imagesequence!, ImageSequence

end
