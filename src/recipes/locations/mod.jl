module LocationsLayers
using ....ImageSequenceAnnotationRecipes: Location, Selected

include("recipe.jl")

# Interactions
include("addlocation.jl")
include("removelocation.jl")
include("selectlocation.jl")
include("changecategory.jl")
include("draglocation.jl")
include("scrollcategories.jl")
include("moveselectedlocation.jl")

end
