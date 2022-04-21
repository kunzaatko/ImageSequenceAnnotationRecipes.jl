using ANT
using Test
using GeometryBasics: Point

@testset "ANT.jl" begin
    @testset "Location" begin
        @test Location(5, Point(5, 5)) == Location(5, Point(5, 5), nothing)
    end
end
