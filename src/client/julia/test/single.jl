rp = RedPitaya(singleIP)

@testset "Acquisition.jl" begin end

@testset "ADC.jl" begin
  decimation!(rp, 8)
  @test decimation(rp) == 8
  decimation!(rp, 16)
  @test decimation(rp) == 16

  @test numChan(rp) == 2 # A single RP always has two ADC Channels

  samplesPerPeriod!(rp, 42)
  @test samplesPerPeriod(rp) == 42
  samplesPerPeriod!(rp, 625)
  @test samplesPerPeriod(rp) == 625

  periodsPerFrame!(rp, 42)
  @test samplesPerPeriod(rp) == 42
  periodsPerFrame!(rp, 1)
  @test periodsPerFrame(rp) == 1

  @test currentFrame(rp) == 0 # The aquisition is not running
  @test currentPeriod(rp) == 0 # The aquisition is not running
  @test currentWP(rp) == 0 # The aquisition is not running

  @error("TODO: Cont' here")
end
