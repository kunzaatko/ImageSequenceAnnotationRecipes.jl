using ANT
using Documenter

DocMeta.setdocmeta!(ANT, :DocTestSetup, :(using ANT); recursive=true)

makedocs(;
    modules=[ANT],
    authors="Martin Kunz <martinkunz@email.cz> and contributors",
    repo="https://github.com/kunzaatko/ANT.jl/blob/{commit}{path}#{line}",
    sitename="ANT.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://kunzaatko.github.io/ANT.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/kunzaatko/ANT.jl",
    devbranch="trunk",
)
