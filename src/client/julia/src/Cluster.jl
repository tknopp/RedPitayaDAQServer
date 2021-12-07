export RedPitayaCluster, master, readDataPeriods, numChan, readDataSlow, readFrames, readPeriods, readPipelinedSamples, startPipelinedData, collectSamples!, readData, readDataPeriods, convertSamplesToFrames!, convertSamplesToFrames, SampleChunk

import Base: length, iterate, getindex, firstindex, lastindex

struct RedPitayaCluster
  rp::Vector{RedPitaya}
end

#TODO: set first RP to master
function RedPitayaCluster(hosts::Vector{String}, port=5025)
  # the first RP is the master
  rps = RedPitaya[ RedPitaya(host, port, i==1) for (i,host) in enumerate(hosts) ]

  @sync for rp in rps
    @async triggerMode(rp, "EXTERNAL")
  end

  return RedPitayaCluster(rps)
end

length(rpc::RedPitayaCluster) = length(rpc.rp)
numChan(rpc::RedPitayaCluster) = 2*length(rpc)
master(rpc::RedPitayaCluster) = rpc.rp[1]

# Indexing Interface
function getindex(rpc::RedPitayaCluster, index::Integer)
  1 <= index <= length(rpc) || throw(BoundsError(rpc.rp, index))
  return rpc.rp[index]
end
firstindex(rpc::RedPitayaCluster) = start_(rpc)
lastindex(rpc::RedPitayaCluster) = length(rpc)

# Iterable Interface
start_(rpc::RedPitayaCluster) = 1
next_(rpc::RedPitayaCluster,state) = (rpc[state],state+1)
done_(rpc::RedPitayaCluster,state) = state > length(rpc)
iterate(rpc::RedPitayaCluster, s=start_(rpc)) = done_(rpc, s) ? nothing : next_(rpc, s)

function RPInfo(rpc::RedPitayaCluster)
  return RPInfo([RPPerformance([]) for i = 1:length(rpc)])
end

const _currentFrame = Ref(0)

function currentFrame(rpc::RedPitayaCluster)
  _currentFrame[] = currentFrame(rpc[1]) #[ currentFrame(rp) for rp in rpc.rp ]
  @debug "Current frame: $(_currentFrame[])"
  #return minimum(currentFrames)
  return _currentFrame[]
end

function currentPeriod(rpc::RedPitayaCluster)
  currentPeriods = currentPeriod(rpc[1])  #[ currentPeriod(rp) for rp in rpc.rp ]
  @debug "Current period: $currentPeriods"
  #return minimum(currentPeriods)
  return currentPeriods
end

function currentWP(rpc::RedPitayaCluster)
  return currentWP(master(rpc))
end

for op in [:periodsPerFrame, :samplesPerPeriod, :decimation, :keepAliveReset, :sequenceRepetitions,
           :triggerMode, :samplesPerSlowDACStep, :slowDACStepsPerFrame,
           :rampUpTime, :rampUpFraction]
  @eval $op(rpc::RedPitayaCluster) = $op(master(rpc))
  @eval begin
    function $op(rpc::RedPitayaCluster, value)
      @sync for rp in rpc
        @async $op(rp, value)
      end
    end
  end
end

for op in [:connectADC, :stopADC, :disconnect, :connect, :clearSequence]
  @eval begin
    function $op(rpc::RedPitayaCluster)
      @sync for rp in rpc
        @async $op(rp)
      end
    end
  end
end

function startADC(rpc::RedPitayaCluster)
  @sync for rp in rpc
    @async startADC(rp)
  end
end

function masterTrigger(rpc::RedPitayaCluster, val::Bool)
    if val
        masterTrigger(master(rpc), val)
    else
        keepAliveReset(rpc, true)
        masterTrigger(master(rpc), false)
        ramWriterMode(rpc, "TRIGGERED")
        keepAliveReset(rpc, false)
    end
end
masterTrigger(rpc::RedPitayaCluster) = masterTrigger(master(rpc))
bufferSize(rpc::RedPitayaCluster) = bufferSize(master(rpc))

# "TRIGGERED" or "CONTINUOUS"
function ramWriterMode(rpc::RedPitayaCluster, mode::String)
  @sync for rp in rpc
    @async ramWriterMode(rp, mode)
  end
end

for op in [:amplitudeDAC, :amplitudeDACNext, :frequencyDAC, :phaseDAC, :modulusFactorDAC, :modulusDAC]
  @eval function $op(rpc::RedPitayaCluster, chan::Integer, component::Integer)
    idxRP = div(chan-1, 2) + 1
    chanRP = mod1(chan, 2)
    return $op(rpc[idxRP], chanRP, component)
  end
  @eval function $op(rpc::RedPitayaCluster, chan::Integer, component::Integer, value)
    idxRP = div(chan-1, 2) + 1
    chanRP = mod1(chan, 2)
    return $op(rpc[idxRP], chanRP, component, value)
  end
end

for op in [:signalTypeDAC,  :DCSignDAC, :jumpSharpnessDAC]
  @eval function $op(rpc::RedPitayaCluster, chan::Integer)
    idxRP = div(chan-1, 2) + 1
    chanRP = mod1(chan, 2)
    return $op(rpc[idxRP], chanRP)
  end
  @eval function $op(rpc::RedPitayaCluster, chan::Integer, value)
    idxRP = div(chan-1, 2) + 1
    chanRP = mod1(chan, 2)
    return $op(rpc[idxRP], chanRP, value)
  end
end

function setSlowDAC(rpc::RedPitayaCluster, chan, value)
  idxRP = div(chan-1, 2) + 1
  chanRP = mod1(chan, 2)
  setSlowDAC(rpc[idxRP], chanRP, value)
end

function getSlowADC(rpc::RedPitayaCluster, chan::Integer)
  idxRP = div(chan-1, 2) + 1
  chanRP = mod1(chan, 2)
  getSlowADC(rpc[idxRP], chanRP)
end

function offsetDAC(rpc::RedPitayaCluster, chan, value)
  idxRP = div(chan-1, 2) + 1
  chanRP = mod1(chan, 2)
  offsetDAC(rpc[idxRP], chanRP, value)
end

function offsetDAC(rpc::RedPitayaCluster, chan::Integer)
  idxRP = div(chan-1, 2) + 1
  chanRP = mod1(chan, 2)
  offsetDAC(rpc[idxRP], chanRP)
end

function numSlowADCChan(rpc::RedPitayaCluster)
  tmp = [0 for rp in rpc]
  @sync for (d, rp) in enumerate(rpc)
    @async tmp[d] = numSlowADCChan(rp)
  end
  return sum(tmp)
end

function numSlowADCChan(rpc::RedPitayaCluster, num)
  @sync for rp in rpc
    @async numSlowADCChan(rp, num)
  end
  return
end

function passPDMToFastDAC(rpc::RedPitayaCluster, val::Vector{Bool})
  @sync for (d,rp) in enumerate(rpc)
    @async passPDMToFastDAC(rp, val[d])
  end
end

function passPDMToFastDAC(rpc::RedPitayaCluster)
  result = [false for rp in rpc]
  @sync for (d, rp) in enumerate(rpc)
    @async result[d] = passPDMToFastDAC(rp)
  end
  return result
end

function appendSequence(rpc::RedPitayaCluster, seq::AbstractSequence)
  @sync for rp in rpc 
    @async appendSequence(rp, seq)
  end
end

function appendSequence(rpc::RedPitayaCluster, index, seq::AbstractSequence)
  appendSequence(rpc[index], seq)
end

function prepareSequence(rpc::RedPitayaCluster)
  success = [false for rp in rpc]
  @sync for (i, rp) in enumerate(rpc)
    @async success[i] = prepareSequence(rp)
  end
  all(success)
end

computeRamping(rpc::RedPitayaCluster, stepsPerSeq, time, fraction) = computeRamping(master(rpc), stepsPerSeq, time, fraction)

modeDAC(rpc::RedPitayaCluster) = modeDAC(master(rpc))

function modeDAC(rpc::RedPitayaCluster, mode::String)
  @sync for rp in rpc
    @async modeDAC(rp, mode)
  end
end

function slowDACInterpolation(rpc::RedPitayaCluster, enable::Bool)
  @sync for rp in rpc
    @async slowDACInterpolation(rp, enable)
  end
end

include("ClusterView.jl")

struct SampleChunk
  samples::Matrix{Int16}
  performance::Vector{PerformanceData}
end

function startPipelinedData(rpu::Union{RedPitayaCluster,RedPitayaClusterView}, reqWP::Int64, numSamples::Int64, chunkSize::Int64)
  @sync for rp in rpu
    @async startPipelinedData(rp, reqWP, numSamples, chunkSize)
  end
end

function readSamples(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, wpStart::Int64, numOfRequestedSamples::Int64; chunkSize::Int64 = 25000, rpInfo=nothing)
  numOfReceivedSamples = 0
  index = 1
  rawData = zeros(Int16, numChan(rpu), numOfRequestedSamples)
  chunkBuffer = zeros(Int16, chunkSize * 2, length(rpu))
  
  while numOfReceivedSamples < numOfRequestedSamples
    wpRead = wpStart + numOfReceivedSamples
    wpWrite = currentWP(rpu)
    chunk = min(numOfRequestedSamples - numOfReceivedSamples, chunkSize)

    
    # Wait for data to be written
    while wpRead + chunk >= wpWrite
      wpWrite = currentWP(rpu)
      @debug wpWrite
    end

    # Collect data
    collectSamples!(rpu, wpRead, chunk, rawData, chunkBuffer, index, rpInfo=rpInfo)
    index += chunk
    numOfReceivedSamples += chunk
  end
  return rawData
end

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
    error("Timout reached when reading from sockets")
  end

  put!(channel, SampleChunk(result, performances))

end

# High level read. numFrames can adress a future frame. Data is read in
# chunks
function readFrames(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, startFrame, numFrames, numBlockAverages=1, numPeriodsPerPatch=1; rpInfo=nothing, chunkSize = 50000)
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
  data = convertSamplesToFrames(rpu, rawSamples, numChan(rpu), numSampPerPeriod, numPeriods, numFrames, numBlockAverages, numPeriodsPerPatch)

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

function readPeriods(rpu::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, startPeriod, numPeriods, numBlockAverages=1; rpInfo=nothing, chunkSize = 50000)
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
  convertSamplesToPeriods!(rawSamples, data, numChan(rpu), numSampPerPeriod, numPeriods, numBlockAverages)

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
  return frames

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


function readData(rpc::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, startFrame, numFrames, numBlockAverages=1, numPeriodsPerPatch=1; chunkSize = 50000)
  data = readFrames(rpc, startFrame, numFrames, numBlockAverages, numPeriodsPerPatch, chunkSize = chunkSize)
  return data
end

function readDataPeriods(rpc::Union{RedPitaya,RedPitayaCluster, RedPitayaClusterView}, startPeriod, numPeriods, numBlockAverages=1; chunkSize = 50000)
  data = readPeriods(rpc, startPeriod, numPeriods, numBlockAverages, chunkSize = chunkSize)
  return data
end


# High level read. numFrames can adress a future frame.
function readDataSlow(rpc::RedPitayaCluster, startFrame, numFrames)
  numPeriods = master(rpc).periodsPerFrame
  numChanTotal = numSlowADCChan(rpc)
  numSampPerFrame = numPeriods * numChanTotal

  data = zeros(Float32, numChanTotal, numPeriods, numFrames)
  wpRead = startFrame
  l=1

  # This is a wild guess for a good chunk size
  chunkSize = max(1,  round(Int, 1000000 / numSampPerFrame)  )
  @debug "chunkSize = $chunkSize"
  while l<=numFrames
    wpWrite = currentFrame(rpc)
    while wpRead >= wpWrite # Wait that startFrame is reached
      wpWrite = currentFrame(rpc)
      @debug wpWrite
    end
    chunk = min(wpWrite-wpRead,chunkSize) # Determine how many frames to read
    @debug chunk
    if l+chunk > numFrames
      chunk = numFrames - l + 1
    end

    @debug "Read from $wpRead until $(wpRead+chunk-1), WpWrite $(wpWrite), chunk=$(chunk)"

    p = 1
    for (d,rp) in enumerate(rpc)
      u = readDataSlow_(rp, Int64(wpRead), Int64(chunk))
      numChan = size(u,1)

      #utmp1 = reshape(u, numChan, numBlockAverages,
      #                    div(size(u,2),numBlockAverages),size(u,3))
      #utmp2 = numBlockAverages > 1 ? mean(utmp1,dims=2) : utmp1

      data[p:(p+numChan-1),:,l:(l+chunk-1)] = u #utmp2[:,1,:,:]
      p += numChan
    end

    l += chunk
    wpRead += chunk
  end

  return data
end
