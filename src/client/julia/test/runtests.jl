using RedPitayaDAQServer
using Test
using Aqua

@testset "RedPitayaDAQServer" begin
  @testset "Aqua" begin
    #@warn "Ambiguities and piracies are accepted for now"
    Aqua.test_all(RedPitayaDAQServer) # , ambiguities=false, piracy=false)
  end
end