using RedPitayaDAQServer
using Test
using Aqua

@testset "RedPitayaDAQServer" begin
  @testset "Aqua" begin
    Aqua.test_all(RedPitayaDAQServer)
  end
end