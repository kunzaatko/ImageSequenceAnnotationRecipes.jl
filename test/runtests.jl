using ImageSequenceAnnotationRecipes
# using ANT: Recipes.ImageSequenceInteractions as ImSeqInts
using Test
using Makie
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


    # TODO: test in a different way  
    # @testset "ImageSequenceInteractions" begin
    #     x = 1 |> Observable
    #     nf = ImSeqInts.NextFrame(Keyboard.k, (x))
    #     ImSeqInts.execute(nf)
    #     @test x[] == 2
    #     pf = ImSeqInts.PrevFrame(Keyboard.j, (x))
    #     ImSeqInts.execute(pf)
    #     @test x[] == 1
    # end

end
