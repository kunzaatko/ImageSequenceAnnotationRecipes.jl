using ImageSequenceAnnotationRecipes
using Documenter

DocMeta.setdocmeta!(ImageSequenceAnnotationRecipes, :DocTestSetup, :(using ImageSequenceAnnotationRecipes); recursive=true)

makedocs(;
    modules=[ImageSequenceAnnotationRecipes],
    authors="Martin Kunz <martinkunz@email.cz> and contributors",
    repo="https://github.com/kunzaatko/ImageSequenceAnnotationRecipes.jl/blob/{commit}{path}#{line}",
    sitename="ImageSequenceAnnotationRecipes.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://kunzaatko.github.io/ImageSequenceAnnotationRecipes.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/kunzaatko/ImageSequenceAnnotationRecipes.jl",
    devbranch="trunk",
)
