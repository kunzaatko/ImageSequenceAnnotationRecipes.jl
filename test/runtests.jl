using ANT
using Test
using GeometryBasics: Point

@testset "ANT.jl" begin
    @testset "Location" begin
        @test Location(Point(5, 5)) == Location(Point(5, 5), nothing)
    end
end
