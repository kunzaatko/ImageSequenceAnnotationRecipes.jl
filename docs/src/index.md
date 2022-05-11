```@meta
CurrentModule = ImageSequenceAnnotationRecipes
```

# ImageSequenceAnnotationRecipes

[ImageSequenceAnnotationRecipes](https://github.com/kunzaatko/ImageSequenceAnnotationRecipes.jl) is a tool for annotating sequences of
images by points with categories. It is based on [`Makie`](https://makie.juliaplots.org/stable/) and works with
interactive backends of [`Makie`](https://makie.juliaplots.org/stable/) which at the moment consist of
[`GLMakie`](https://makie.juliaplots.org/stable/documentation/backends/glmakie/) and [`WGLMakie`](https://makie.juliaplots.org/stable/documentation/backends/wglmakie/).

!!! note "`Makie` backend"
    Neither of `GLMakie` and `WGLMakie` are pulled in as dependencies for this package. You need to
    add them separately by
    ```@repl
    ]add GLMakie # or WGLMakie
    ```

# Basic usage

The only function that the package exposes is [`annotationtool(im_seq; args...)`](@ref). The
simplest way to use this function when you have an image sequence loaded is

<!-- TODO: This could be interactive... Can use the same approach as Makie in its documentation <18-04-22> -->
```@repl
using Images # hide
im_seq = load("./assets/test_image_seq.tiff") # hide
im_seq .-= minimum(im_seq); im_seq ./= maximum(im_seq); # hide
using ImageSequenceAnnotationRecipes
using GLMakie # or WGLMakie
annotationtool(im_seq)
save("basic_usage.png", current_figure()) # hide
```

![Basic usage](basic_usage.png)

```@index
```

```@autodocs
Modules = [ImageSequenceAnnotationRecipes]
```
