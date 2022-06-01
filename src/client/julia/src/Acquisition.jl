export SampleChunk, startPipelinedData, readPipelinedSamples, readFrames, readPeriods, convertSamplesToFrames, convertSamplesToFrames!, convertSamplesToPeriods!
"""
    SampleChunk

Struct containing a matrix of samples and associated `PerformanceData`

# Fields
- `samples::Matrix{Int16}`: `n`x`m` matrix containing `m` samples for `n` channel
- `performance::Vector{PerformanceData}`: `PerformanceData` object for each RedPitaya that transmitted samples
"""
struct SampleChunk
  samples::Matrix{Int16}
  performance::Vector{PerformanceData}
end

"""
    startPipelinedData(rpu::Union{RedPitayaCluster, RedPitayaClusterView}, reqWP::Int64, numSamples::Int64, chunkSize::Int64)

Instruct all `RedPitaya`s to send `numSamples` samples from writepointer `reqWP` in chunks of `chunkSize`.

See [`readPipelinedSamples`](@ref)
"""
function startPipelinedData(rpu::Union{RedPitayaCluster,RedPitayaClusterView}, reqWP::Int64, numSamples::Int64, chunkSize::Int64)
  @sync for rp in rpu
    @async startPipelinedData(rp, reqWP, numSamples, chunkSize)
  end
end

"""
    readPipelinedSamples(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, wpStart::Int64, numOfRequestedSamples::Int64; chunkSize::Int64 = 25000, rpInfo=nothing)

Request and receive `numOfRequestedSamples` samples from `wpStart` on in a pipelined fashion. Return a matrix of samples.

If `rpInfo` is set to a `RPInfo`, the `PerformanceData` sent after every `chunkSize` samples will be pushed into `rpInfo`.
"""
function readPipelinedSamples(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, wpStart::Int64, numOfRequestedSamples::Int64; chunkSize::Int64 = 25000, rpInfo=nothing)
  numOfReceivedSamples = 0
  index = 1
  rawData = zeros(Int16, numChan(rpu), numOfRequestedSamples)
  chunkBuffer = zeros(Int16, chunkSize * 2, length(rpu))

  startPipelinedData(rpu, wpStart, numOfRequestedSamples, chunkSize)
  while numOfReceivedSamples < numOfRequestedSamples
    wpRead = wpStart + numOfReceivedSamples
    chunk = min(numOfRequestedSamples - numOfReceivedSamples, chunkSize)
    collectSamples!(rpu, wpRead, chunk, rawData, chunkBuffer, index, rpInfo=rpInfo)
    index += chunk
    numOfReceivedSamples += chunk
  end
  return rawData

end


function collectSamples!(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, wpRead::Int64, chunk::Int64, rawData::Matrix{Int16}, chunkBuffer, index; rpInfo=nothing)
  done = zeros(Bool, length(rpu))
  iterationDone = Condition()
  timeoutHappened = false

  for (d, rp) in enumerate(rpu)
    @async begin
      buffer = view(chunkBuffer, 1:(2 * chunk), d)
      (u, perf) = readSamplesChunk_(rp, Int64(wpRead), Int64(chunk), buffer)
      samples = reshape(u, 2, chunk)
      rawData[2*d-1, index:(index + chunk - 1)] = samples[1, :]
      rawData[2*d, index:(index + chunk - 1)] = samples[2, :]

      # Status
      if perf.status.overwritten
        @error "RP $d: Requested data from $wpRead until $(wpRead+chunk) was overwritten"
      end
      if perf.status.corrupted
        @error "RP $d: Requested data from $wpRead until $(wpRead+chunk) might have been corrupted"
      end

      # Performance
      if !isnothing(rpInfo)
        push!(rpInfo.performances[d].data, perf)
      end

      done[d] = true
      if (all(done))
        notify(iterationDone)
      end
    end
  end

  # Setup Timeout
  t = Timer(_timeout)
  @async begin
    wait(t)
    notify(iterationDone)
    timeoutHappened = true
  end

  wait(iterationDone)
  close(t)
  if timeoutHappened
    error("Timout reached when reading from sockets")
  end

end

"""
    readPipelinedSamples(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, wpStart::Int64, numOfRequestedSamples::Int64, channel::Channel; chunkSize::Int64 = 25000)

Request and receive `numOfRequestedSamples` samples from `wpStart` on in a pipelined fashion. The samples and associated `PerformanceData` are pushed into `channel` as a `SampleChunk`.

See [`SampleChunk`](@ref).
"""
function readPipelinedSamples(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, wpStart::Int64, numOfRequestedSamples::Int64, channel::Channel; chunkSize::Int64 = 25000)
  numOfReceivedSamples = 0
  chunkBuffer = zeros(Int16, chunkSize * 2, length(rpu))

  startPipelinedData(rpu, wpStart, numOfRequestedSamples, chunkSize)
  while numOfReceivedSamples < numOfRequestedSamples
    wpRead = wpStart + numOfReceivedSamples
    chunk = min(numOfRequestedSamples - numOfReceivedSamples, chunkSize)
    collectSamples!(rpu, wpRead, chunk, channel, chunkBuffer)
    numOfReceivedSamples += chunk
  end

end

function collectSamples!(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, wpRead::Int64, chunk::Int64, channel::Channel, chunkBuffer)
  done = zeros(Bool, length(rpu))
  iterationDone = Condition()
  timeoutHappened = false
  result = zeros(Int16, numChan(rpu), chunk)
  performances = Vector{PerformanceData}(undef, length(rpu))


  for (d, rp) in enumerate(rpu)
    @async begin
      buffer = view(chunkBuffer, 1:(2 * chunk), d)
      (u, perf) = readSamplesChunk_(rp, Int64(wpRead), Int64(chunk), buffer)
      samples = reshape(u, 2, chunk)
      result[2*d-1, :] = samples[1, :]
      result[2*d, :] = samples[2, :]
      performances[d] = perf

      done[d] = true
      if (all(done))
        notify(iterationDone)
      end
    end
  end

  # Setup Timeout
  t = Timer(_timeout)
  @async begin
    wait(t)
    notify(iterationDone)
    timeoutHappened = true
  end

  wait(iterationDone)
  close(t)
  if timeoutHappened
    @show done
    error("Timout reached when reading from sockets")
  end

  put!(channel, SampleChunk(result, performances))

end

"""
    readFrames(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, startFrame, numFrames, numBlockAverages=1, numPeriodsPerPatch=1; rpInfo=nothing, chunkSize = 50000, useCalibration = false)

Request and receive `numFrames` frames from `startFrame` on.

See [`readPipelinedSamples`](@ref), [`convertSamplesToFrames`](@ref), [`samplesPerPeriod`](@ref), [`periodsPerFrame`](@ref), [`updateCalib!`](@ref).

# Arguments
- `rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}`: `RedPitaya`s to receive samples from.
- `startFrame`: frame from which to start transmitting
- `numFrames`: number of frames to read
- `numBlockAverages=1`: see `convertSamplesToFrames`
- `numPeriodsPerPatch=1`: see `convertSamplesToFrames`
- `chunkSize=50000`: see `readPipelinedSamples`
- `rpInfo=nothing`: see `readPipelinedSamples`
- `useCalibration`: convert from Int16 samples to Float32 values based on `RedPitaya`s calibration
"""
function readFrames(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, startFrame, numFrames, numBlockAverages=1, numPeriodsPerPatch=1; rpInfo=nothing, chunkSize = 50000, useCalibration = false)
  numSampPerPeriod = samplesPerPeriod(rpu)
  numPeriods = periodsPerFrame(rpu)
  numSampPerFrame = numSampPerPeriod * numPeriods

  if rem(numSampPerPeriod,numBlockAverages) != 0
    error("block averages has to be a divider of numSampPerPeriod")
  end

  wpStart = startFrame * numSampPerFrame
  numOfRequestedSamples = numFrames * numSampPerFrame

  # rawSamples Int16 numofChan(rpc) x numOfRequestedSamples
  rawSamples = readPipelinedSamples(rpu, Int64(wpStart), Int64(numOfRequestedSamples), chunkSize = chunkSize, rpInfo = rpInfo)

  # Reshape/Avg Data
  if useCalibration
    data = convertSamplesToFrames(rpu, rawSamples, numChan(rpu), numSampPerPeriod, numPeriods, numFrames, numBlockAverages, numPeriodsPerPatch)
  else
    data = convertSamplesToFrames(rawSamples, numChan(rpu), numSampPerPeriod, numPeriods, numFrames, numBlockAverages, numPeriodsPerPatch)
  end

  return data
end

function convertSamplesToFrames(rpu::Union{RedPitaya, RedPitayaCluster, RedPitayaClusterView}, samples, numChan, numSampPerPeriod, numPeriods, numFrames, numBlockAverages=1, numPeriodsPerPatch=1)
  frames = convertSamplesToFrames(samples, numChan, numSampPerPeriod, numPeriods, numFrames, numBlockAverages, numPeriodsPerPatch)
  calibs = [x.calib for x in rpu]
  calib = hcat(calibs...)
  for d = 1:size(frames, 2)
    frames[:, d, :, :] .*= calib[1, d]
    frames[:, d, :, :] .+= calib[2, d]
  end
  return frames
end

function convertSamplesToFrames(samples, numChan, numSampPerPeriod, numPeriods, numFrames, numBlockAverages=1, numPeriodsPerPatch=1)
  if rem(numSampPerPeriod,numBlockAverages) != 0
    error("block averages has to be a divider of numSampPerPeriod")
  end
  numTrueSampPerPeriod = div(numSampPerPeriod,numBlockAverages*numPeriodsPerPatch)
  frames = zeros(Float32, numTrueSampPerPeriod, numChan, numPeriods*numPeriodsPerPatch, numFrames)
  convertSamplesToFrames!(samples, frames, numChan, numSampPerPeriod, numPeriods, numFrames, numTrueSampPerPeriod, numBlockAverages, numPeriodsPerPatch)
  return frames
end

function convertSamplesToFrames!(rpu::Union{RedPitaya, RedPitayaCluster, RedPitayaClusterView}, samples, frames, numChan, numSampPerPeriod, numPeriods, numFrames, numTrueSampPerPeriod, numBlockAverages=1, numPeriodsPerPatch=1)
  convertSamplesToFrames!(samples, frames, numChan, numSampPerPeriod, numPeriods, numFrames, numTrueSampPerPeriod, numBlockAverages, numPeriodsPerPatch)
  calibs = [x.calib for x in rpu]
  calib = hcat(calibs...)
  for d = 1:size(frames, 2)
    frames[:, d, :, :] .*= calib[1, d]
    frames[:, d, :, :] .+= calib[2, d]
  end
end

function convertSamplesToFrames!(samples, frames, numChan, numSampPerPeriod, numPeriods, numFrames, numTrueSampPerPeriod, numBlockAverages=1, numPeriodsPerPatch=1)
  temp = reshape(samples, numChan, numSampPerPeriod, numPeriods, numFrames)
  for d = 1:div(numChan,2)
    u = temp[2*d-1:2*d, :, :, :]
    utmp1 = reshape(u,2,numTrueSampPerPeriod,numBlockAverages, size(u,3)*numPeriodsPerPatch,size(u,4))
    utmp2 = numBlockAverages > 1 ? mean(utmp1,dims=3) : utmp1
    frames[:,2*d-1,:,:] = utmp2[1,:,1,:,:]
    frames[:,2*d,:,:] = utmp2[2,:,1,:,:]
  end
end

"""
    readPeriods(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, startPeriod, numPeriods, numBlockAverages=1, numPeriodsPerPatch=1; rpInfo=nothing, chunkSize = 50000, useCalibration = false)

Request and receive `numPeriods` Periods from `startPeriod` on.

See [`readPipelinedSamples`](@ref), [`convertSamplesToPeriods!`](@ref), [`samplesPerPeriod`](@ref).

# Arguments
- `rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}`: `RedPitaya`s to receive samples from.
- `startPeriod`: period from which to start transmitting
- `numPeriods`: number of periods to read
- `numBlockAverages=1`: see `convertSamplesToPeriods`
- `chunkSize=50000`: see `readPipelinedSamples`
- `rpInfo=nothing`: see `readPipelinedSamples`
- `useCalibration`: convert samples based on `RedPitaya`s calibration
"""
function readPeriods(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, startPeriod, numPeriods, numBlockAverages=1; rpInfo=nothing, chunkSize = 50000, useCalibration = false)
  numSampPerPeriod = samplesPerPeriod(rpu)

  if rem(numSampPerPeriod,numBlockAverages) != 0
    error("block averages has to be a divider of numSampPerPeriod")
  end

  numAveragedSampPerPeriod = div(numSampPerPeriod,numBlockAverages)

  data = zeros(Float32, numAveragedSampPerPeriod, numChan(rpu), numPeriods)
  wpStart = startPeriod * numSampPerPeriod
  numOfRequestedSamples = numPeriods * numSampPerPeriod

  # rawSamples Int16 numofChan(rpc) x numOfRequestedSamples
  rawSamples = readPipelinedSamples(rpu, Int64(wpStart), Int64(numOfRequestedSamples), chunkSize = chunkSize, rpInfo = rpInfo)

  # Reshape/Avg Data
  if useCalibration
    convertSamplesToPeriods!(rpu, rawSamples, data, numChan(rpu), numSampPerPeriod, numPeriods, numBlockAverages)
  else
    convertSamplesToPeriods!(rawSamples, data, numChan(rpu), numSampPerPeriod, numPeriods, numBlockAverages)
  end
  return data
end

function convertSamplesToPeriods!(rpu::Union{RedPitaya, RedPitayaCluster, RedPitayaClusterView}, samples, periods, numChan, numSampPerPeriod, numPeriods, numBlockAverages=1)
  convertSamplesToPeriods!(samples, periods, numChan, numSampPerPeriod, numPeriods, numBlockAverages)
  calibs = [x.calib for x in rpu]
  calib = hcat(calibs...)
  for d = 1:size(periods, 2)
    periods[:, d, :] .*= calib[1, d]
    periods[:, d, :] .+= calib[2, d]
  end
  return periods

end
function convertSamplesToPeriods!(samples, periods, numChan, numSampPerPeriod, numPeriods, numBlockAverages=1)
  temp = reshape(samples, numChan, numSampPerPeriod, numPeriods)
  for d = 1:div(numChan,2)
    u = temp[2*d-1:2*d, :, :]
    utmp1 = reshape(u,2,div(numSampPerPeriod,numBlockAverages), numBlockAverages, size(u,3))
    utmp2 = numBlockAverages > 1 ? mean(utmp1,dims=3) : utmp1
    periods[:,2*d-1,:] = utmp2[1,:,1,:]
    periods[:,2*d,:] = utmp2[2,:,1,:]
  end
end