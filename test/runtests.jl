using ImageSequenceAnnotationRecipes
using ImageSequenceAnnotationRecipes.Recipes
using ImageSequenceAnnotationRecipes: AttributeModifiers as AM
using ColorTypes
using Test
using Makie
using GLMakie
using GeometryBasics: Point

@testset "ImageSequenceAnnotationRecipes.jl" begin
    @testset "Location" begin
        @test Location(Point(5, 5)) == Location(Point(5, 5), nothing)
    end

    @testset "Hotkey" begin
        @test typeof(Keyboard.a) <: ImageSequenceAnnotationRecipes.Hotkey
        @test typeof(Mouse.right) <: ImageSequenceAnnotationRecipes.Hotkey
        @test typeof(Keyboard.a | Keyboard.b) <: ImageSequenceAnnotationRecipes.Hotkey
        @test typeof(Keyboard.a | Mouse.right) <: ImageSequenceAnnotationRecipes.Hotkey
        @test typeof(Keyboard.a & Mouse.right) <: ImageSequenceAnnotationRecipes.Hotkey
        @test typeof(Keyboard.a & Keyboard.b) <: ImageSequenceAnnotationRecipes.Hotkey
        @test typeof(Keyboard.a & !Keyboard.b) <: ImageSequenceAnnotationRecipes.Hotkey
        @test typeof((Keyboard.left_alt | Keyboard.right_alt) & Keyboard.a) <: ImageSequenceAnnotationRecipes.Hotkey
    end


    @testset "Locations" begin
        @testset "LocationsLayers" begin
            locslen = 10
            locscats = [:a, :b, :c, nothing]
            locs = [Location(p, c) for (p, c) in zip(rand(Point2, locslen), rand(locscats, locslen))]
            _, _, loclay = locationslayer(0, nothing, locs)
            @test typeof(loclay) <: LocationsLayer
        end
    end

    @testset "Attributes" begin
        @testset "ColorModifiers" begin
            ColorAttributeType = Union{<:Colorant,Symbol}

            # NOTE: Test parsing and working of color modifiers in the ideal setup (all keys present) <kunzaatko> 
            for f in [
                AM.dim!,
                AM.saturate!,
                AM.dim_color!,
                AM.dim_strokecolor!,
                AM.saturate_color!,
                AM.saturate_strokecolor!,
                AM.darken!,
                AM.lighten!,
                AM.darken_color!,
                AM.lighten_color!,
                AM.darken_strokecolor!,
                AM.lighten_strokecolor!,
                AM.decrease_transparency!,
                AM.increase_transparency!,
                AM.decrease_transparency_color!,
                AM.increase_transparency_color!,
                AM.decrease_transparency_strokecolor!,
                AM.increase_transparency_strokecolor!,]
                at = Attributes(; color = :blue, strokecolor = :red)
                f(at)
                @test all(typeof.(to_value.(getproperty.(at, [:color, :strokecolor]))) .<: ColorAttributeType)
            end

            # NOTE: Testing whether the general color modifiers act even when a key is missing <kunzaatko> 
            for f in [
                AM.dim!,
                AM.saturate!,
                AM.darken!,
                AM.lighten!,
                AM.decrease_transparency!,
                AM.increase_transparency!,
            ]
                at = Attributes(; color = RGBf(0.1, 0.1, 0.1))
                f(at)
                @test !haskey(at, :strokecolor)
                @test typeof(to_value(at[:color])) <: ColorAttributeType
            end

            # NOTE: Testing that the specific color modifiers fail when key is missing <kunzaatko> 
            for f in [
                AM.dim_color!,
                AM.dim_strokecolor!,
                AM.saturate_color!,
                AM.saturate_strokecolor!,
                AM.darken_color!,
                AM.lighten_color!,
                AM.darken_strokecolor!,
                AM.lighten_strokecolor!,
                AM.decrease_transparency_color!,
                AM.increase_transparency_color!,
                AM.decrease_transparency_strokecolor!,
                AM.increase_transparency_strokecolor!,
            ]
                at = Attributes(;)
                @test all(haskey.(at, [:strokecolor, :color]) .== false)
                @test_throws AssertionError f(at)
            end

            # NOTE: Testing whether modifiers that are opposite undo eachother <kunzaatko> 
            for (keys, fs) in [
                ([:color, :strokecolor], (AM.dim!,
                    AM.saturate!)),
                ([:color], (AM.dim_color!,
                    AM.saturate_color!)),
                ([:strokecolor], (AM.dim_strokecolor!,
                    AM.saturate_strokecolor!)),
            ]
                col = RGBf(0.5, 0.5, 0.5)
                at = Attributes(; color = col, strokecolor = col)
                foreach(fs) do f
                    f(at)
                end
                if length(keys) > 1
                    @assert typeof(at[:color][]) == typeof(at[:strokecolor][])
                end
                col = convert(typeof(at[keys[1]][]), col)
                @test all(isapprox.(to_value.(getproperty.(at, keys)), col, atol = 0.01))
            end

            # FIX: Works only for dim! and saturate! <kunzaatko> 
            for (keys, fs) in [
                ([:color, :strokecolor], (AM.darken!,
                    AM.lighten!)),
                ([:color, :strokecolor], (AM.decrease_transparency!,
                    AM.increase_transparency!)),
                ([:color], (AM.darken_color!,
                    AM.lighten_color!)),
                ([:strokecolor], (AM.darken_strokecolor!,
                    AM.lighten_strokecolor!)),
                ([:color], (AM.decrease_transparency_color!,
                    AM.increase_transparency_color!)),
                ([:strokecolor], (AM.decrease_transparency_strokecolor!,
                    AM.increase_transparency_strokecolor!))
            ]
                col = RGBf(0.5, 0.5, 0.5)
                at = Attributes(; color = col, strokecolor = col)
                foreach(fs) do f
                    f(at)
                end
                if length(keys) > 1
                    @assert typeof(at[:color][]) == typeof(at[:strokecolor][])
                end
                col = convert(typeof(at[keys[1]][]), col)
                @test_broken all(isapprox.(to_value.(getproperty.(at, keys)), col, atol = 0.01))
            end


        end

        @testset "OtherModifiers" begin
            at = Attributes(; marker = :circle, markersize = 4)
            AM.marker!(at, :diamond)
            @test at[:marker][] == :diamond
            for f in (AM.increase_markersize!, AM.decrease_markersize!)
                prevsize = at[:markersize][]
                f(at)
                @test prevsize != at[:markersize][]
            end
        end
    end





    #     ImSeqInts.execute(nf)
    #     @test x[] == 2
    #     pf = ImSeqInts.PrevFrame(Keyboard.j, (x))
    #     ImSeqInts.execute(pf)
    #     @test x[] == 1
    # end

end
