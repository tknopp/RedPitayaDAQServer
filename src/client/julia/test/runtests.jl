using RedPitayaDAQServer
using Test
using Aqua
using Sockets

@testset "RedPitayaDAQServer" begin
  @testset "Aqua" begin
    Aqua.test_all(RedPitayaDAQServer)
  end

  @testset "SingleRP" begin
    if !isfile("config.jl")
      @info "No config given for hardware-based tests. The tests will be skipped. If you want to run hardware-based tests, please create a file named `config.jl` in the `test` folder. The file should contain a variable named `singleIP` with a string giving the IP of the device under test."
    else
      include("config.jl")

      if @isdefined singleIP
        port = 5025
        try
          sock = Sockets.connect(singleIP, port)
          close(sock)

          include("single.jl")
        catch e
          @warn "No connection can be established to RP at `$singleIP:$port` for hardware-based tests. The tests will be skipped."
        end
      else
        @info "No IP for a single RP was given by specifying `singleIP` for hardware-based tests. The tests will be skipped."
      end
    end
  end
end