using ANT
using Test
using Makie
using GeometryBasics: Point

@testset "ANT.jl" begin
    @testset "Location" begin
        @test Location(Point(5, 5)) == Location(Point(5, 5), nothing)
    end

    @testset "Hotkey" begin
        @test typeof(Keyboard.a) <: ANT.Hotkey
        @test typeof(Mouse.right) <: ANT.Hotkey
        @test typeof(Keyboard.a | Keyboard.b) <: ANT.Hotkey
        @test typeof(Keyboard.a | Mouse.right) <: ANT.Hotkey
        @test typeof(Keyboard.a & Mouse.right) <: ANT.Hotkey
        @test typeof(Keyboard.a & Keyboard.b) <: ANT.Hotkey
        @test typeof(Keyboard.a & !Keyboard.b) <: ANT.Hotkey
        @test typeof((Keyboard.left_alt | Keyboard.right_alt) & Keyboard.a) <: ANT.Hotkey
    end
end
