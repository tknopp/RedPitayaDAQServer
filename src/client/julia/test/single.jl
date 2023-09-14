rp = RedPitaya(singleIP)

@testset "Acquisition.jl" begin end

@testset "ADC.jl" begin
  @test decimation!(rp, 8)
  @test decimation(rp) == 8
  @test decimation!(rp, 16)
  @test decimation(rp) == 16

  @test numChan(rp) == 2 # A single RP always has two ADC Channels

  samplesPerPeriod!(rp, 42)
  @test samplesPerPeriod(rp) == 42
  samplesPerPeriod!(rp, 625)
  @test samplesPerPeriod(rp) == 625

  @test periodsPerFrame!(rp, 42)
  @test samplesPerPeriod(rp) == 42
  @test periodsPerFrame!(rp, 1)
  @test periodsPerFrame(rp) == 1

  @test currentFrame(rp) == 0 # The aquisition is not running
  @test currentPeriod(rp) == 0 # The aquisition is not running
  @test currentWP(rp) == 0 # The aquisition is not running

  @test bufferSize(rp) == 2^24

  @test masterTrigger!(rp, true)
  @test masterTrigger(rp) == true
  #TODO: Test changes in wp
  @test masterTrigger!(rp, false)

  @test keepAliveReset!(rp, true)
  @test keepAliveReset(rp) == true
  @test keepAliveReset!(rp, false)
  @test keepAliveReset(rp) == false

  @test triggerMode!(rp, EXTERNAL)
  @test triggerMode(rp) == EXTERNAL
  @test triggerMode!(rp, INTERNAL)
  @test triggerMode(rp) == INTERNAL

  # We can only really test the trigger propagation in a cluster
  @test triggerPropagation!(rp, true)
  @test triggerPropagation(rp) == true
  @test triggerPropagation!(rp, false)
  @test triggerPropagation(rp) == false

  @warn " How do we test this?"
  @test overwritten(rp) == ""
  @test corrupted(rp) == ""
  @test serverStatus(rp) == ""
  @test readServerStatus(rp) = ""
  
  @warn " How do we test this?"
  # performanceData(rp, numSamples = 0)
  # readPerformanceData(rp, numSamples = 0)
  # readADCPerformanceData(rp, numSamples = 0)
  # readChunkMetaData(rp, reqWP, numSamples)
  # readSamples!(rp, data::AbstractArray{Int16})

  @warn " How do we test this?"
  # readSamplesChunk_(rp::RedPitaya, reqWP::Int64, numSamples::Int64)
  # readSamplesChunk_(rp::RedPitaya, reqWP::Int64, buffer::AbstractArray{Int16})
  # startPipelinedData(rp::RedPitaya, reqWP::Int64, numSamples::Int64, chunkSize::Int64)
  @test stopTransmission(rp) == true
end
@error("TODO: Cont' here")