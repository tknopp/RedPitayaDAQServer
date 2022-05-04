export RedPitayaCluster, master, readDataPeriods, numChan, readDataSlow, readFrames, readPeriods, readPipelinedSamples, startPipelinedData, collectSamples!, readData, readDataPeriods, convertSamplesToFrames!, convertSamplesToFrames, SampleChunk, SampleBuffer

import Base: length, iterate, getindex, firstindex, lastindex

"""
    RedPitayaCluster

Struct representing a cluster of `RedPitaya`s. Such a cluster should share a common clock and master trigger.

The structure implements the indexing and iterable interfaces.
"""
struct RedPitayaCluster
  rp::Vector{RedPitaya}
end

"""
    RedPitayaCluster(hosts::Vector{String} [, port = 5025])

Construct a `RedPitayaCluster`.

During the construction the first host is labelled the master RedPitaya of a cluster and all RedPitayas
are set to using the `EXTERNAL` trigger mode.

See also [`RedPitaya`](@ref), [`master`](@ref).

# Examples
```julia
julia> rpc = RedPitayaCluster(["192.168.1.100", "192.168.1.101"]);

julia> rp = master(rpc)

julia> rp == rpc[1]
true
```
"""
function RedPitayaCluster(hosts::Vector{String}, port::Int64=5025, dataPort::Int64=5026; triggerMode_="EXTERNAL")
  # the first RP is the master
  rps = RedPitaya[ RedPitaya(host, port, dataPort, i==1) for (i,host) in enumerate(hosts) ]

  @sync for rp in rps
    @async triggerMode!(rp, triggerMode_)
  end

  return RedPitayaCluster(rps)
end

"""
    length(rpc::RedPitayaCluster)

Return the number of `RedPitaya`s in cluster `rpc`.
"""
length(rpc::RedPitayaCluster) = length(rpc.rp)
"""
    numChan(rpc::RedPitayaCluster)

Return the number of ADC channel in cluser `rpc`.
"""
numChan(rpc::RedPitayaCluster) = 2*length(rpc)
"""
    master(rpc::RedPitayaCluster)

Return the master `RedPitaya` of the cluster.
"""
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

batchIndices(f::Function, rpc::RedPitaya, args...) = error("Function $(string(f)) is not supported in cluster batch or has incorrect parameters.")
batchTransformArgs(::Function, rpc::RedPitayaCluster, idx, args...) = args

function RPInfo(rpc::RedPitayaCluster)
  return RPInfo([RPPerformance([]) for i = 1:length(rpc)])
end

for op in [:currentFrame, :currentPeriod, :currentWP, :periodsPerFrame, :samplesPerPeriod, :decimation, :keepAliveReset, :sequenceRepetitions,
           :triggerMode, :samplesPerStep, :stepsPerFrame, :serverMode, :masterTrigger]

  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster)

    As with single RedPitaya, but applied to only the master.
    """
    $op(rpc::RedPitayaCluster) = $op(master(rpc))
    batchIndices(::typeof($op), rpc::RedPitayaCluster) = 1
  end
end

for op in [:periodsPerFrame!, :samplesPerPeriod!, :decimation!, :triggerMode!, :samplesPerStep!, :stepsPerFrame!,
           :keepAliveReset!, :serverMode!]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, value)

    As with single RedPitaya, but applied to all RedPitayas in a cluster.
    """
    function $op(rpc::RedPitayaCluster, value)
      result = [false for i = 1:length(rpc)]
      @sync for (i, rp) in enumerate(rpc)
        @async result[i] = $op(rp, value)
      end
      return result
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster, value) = collect(1:length(rpc))
  end
end

for op in [:clearSequences!, :appendSequence!, :prepareSequences!]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, value)

    As with single RedPitaya, but applied to all RedPitayas in a cluster.
    """
    function $op(rpc::RedPitayaCluster)
      result = [false for i = 1:length(rpc)]
      @sync for (i, rp) in enumerate(rpc)
        @async result[i] = $op(rp)
      end
      return result
    end
  end
end

for op in [:disconnect, :connect]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster)

    As with single RedPitaya, but applied to all RedPitayas in a cluster.
    """
    function $op(rpc::RedPitayaCluster)
      @sync for rp in rpc
        @async $op(rp)
      end
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster) = collect(1:length(rpc))
  end
end

"""
    masterTrigger(rpc::RedPitayaCluster, val::Bool)

Set the master trigger of the cluster to `val`.

For `val` equals to true this is the same as calling the function on the RedPitaya returned by `master(rpc)`.
If `val` is false then the keepAliveReset is set to true for all RedPitayas in the cluster
before the master trigger is disabled. Afterwards the keepAliveReset is set to false again.

See also [`master`](@ref), [`keepAliveReset!`](@ref).
"""
function masterTrigger!(rpc::RedPitayaCluster, val::Bool)
    if val
        masterTrigger!(master(rpc), val)
    else
        keepAliveReset!(rpc, true)
        masterTrigger!(master(rpc), false)
        keepAliveReset!(rpc, false)
    end
    return masterTrigger(rpc)
end


for op in [:signalTypeDAC, :jumpSharpnessDAC, :amplitudeDAC, :frequencyDAC, :phaseDAC]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, chan::Integer, component::Integer)

    As with single RedPitaya. The `chan` index refers to the total channel available in a cluster, two per `RedPitaya`.
    For example channel `4` would refer to the second channel of the second `RedPitaya`.
    """
    function $op(rpc::RedPitayaCluster, chan::Integer, component::Integer)
      idxRP = div(chan-1, 2) + 1
      chanRP = mod1(chan, 2)
      return $op(rpc[idxRP], chanRP, component)
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster, chan, component) = [div(chan -1, 2) + 1]
    batchTransformArgs(::typeof($op), rpc::RedPitayaCluster, idx, chan, component) = [mod1(chan, 2), component]
  end
end
for op in [:signalTypeDAC!, :jumpSharpnessDAC!, :amplitudeDAC!, :frequencyDAC!, :phaseDAC!]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, chan::Integer, component::Integer, value)

    As with single RedPitaya. The `chan` index refers to the total channel available in a cluster, two per `RedPitaya`.
    For example channel `4` would refer to the second channel of the second `RedPitaya`.
    """
    function $op(rpc::RedPitayaCluster, chan::Integer, component::Integer, value)
      idxRP = div(chan-1, 2) + 1
      chanRP = mod1(chan, 2)
      return $op(rpc[idxRP], chanRP, component, value)
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster, chan, component, value) = [div(chan -1, 2) + 1]
    batchTransformArgs(::typeof($op), rpc::RedPitayaCluster, idx, chan, component, value) = [mod1(chan, 2), component, value]
  end
end

for op in [:jumpSharpnessDAC, :offsetDAC, :rampingDAC, :enableRamping, :enableRampDown]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, chan::Integer)

    As with single RedPitaya. The `chan` index refers to the total channel available in a cluster, two per `RedPitaya`.
    For example channel `4` would refer to the second channel of the second `RedPitaya`.
    """
    function $op(rpc::RedPitayaCluster, chan::Integer)
      idxRP = div(chan-1, 2) + 1
      chanRP = mod1(chan, 2)
      return $op(rpc[idxRP], chanRP)
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster, chan) = [div(chan -1, 2) + 1]
    batchTransformArgs(::typeof($op), rpc::RedPitayaCluster, idx, chan) = [mod1(chan, 2)]
  end
end
for op in [:offsetDAC!, :rampingDAC!, :enableRamping!, :enableRampDown!]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, chan::Integer, value)

    As with single RedPitaya. The `chan` index refers to the total channel available in a cluster, two per `RedPitaya`.
    For example channel `4` would refer to the second channel of the second `RedPitaya`.
    """
    function $op(rpc::RedPitayaCluster, chan::Integer, value)
      idxRP = div(chan-1, 2) + 1
      chanRP = mod1(chan, 2)
      return $op(rpc[idxRP], chanRP, value)
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster, chan, value) = [div(chan -1, 2) + 1]
    batchTransformArgs(::typeof($op), rpc::RedPitayaCluster, idx, chan, value) = [mod1(chan, 2), value]
  end
end

function passPDMToFastDAC!(rpc::RedPitayaCluster, val::Vector{Bool})
  result = [false for i=1:length(rpc)]
  @sync for (d,rp) in enumerate(rpc)
    @async result[d] = passPDMToFastDAC!(rp, val[d])
  end
end
batchIndices(::typeof(passPDMToFastDAC!), rpc::RedPitayaCluster, val) = collect(1:length(rpc))
batchTransformArgs(::typeof(passPDMToFastDAC!), rpc::RedPitayaCluster, idx, val::Vector{Bool}) = [val[idx]]


function passPDMToFastDAC(rpc::RedPitayaCluster)
  result = [false for rp in rpc]
  @sync for (d, rp) in enumerate(rpc)
    @async result[d] = passPDMToFastDAC(rp)
  end
  return result
end
batchIndices(::typeof(passPDMToFastDAC), rpc::RedPitayaCluster) = collect(1:length(rpc))

function rampingStatus(rpc::RedPitayaCluster)
  result = Array{RampingStatus}(undef, length(rpc))
  @sync for (d, rp) in enumerate(rpc)
    @async result[d] = rampingStatus(rp)
  end
  return result
end
batchIndices(::typeof(rampingStatus), rpc::RedPitayaCluster) = collect(1:length(rpc))

for op in [:rampDownDone, :rampUpDone]
  @eval begin
    function $op(rpc::RedPitayaCluster)
      result = [false for i = 1:length(rpc)]
      @sync for (d, rp) in enumerate(rpc)
        @async result[d] = $op(rp)
      end
      return all(result)    
    end
  end
end

computeRamping(rpc::RedPitayaCluster, stepsPerSeq, time, fraction) = computeRamping(master(rpc), stepsPerSeq, time, fraction)

include("ClusterView.jl")

"""
    execute!(rpc::RedPitayaCluster, batch::ScpiBatch)

Executes all commands of the given batch. Returns an array of the results in the order of the commands.

Each element of the result array is again an array containing the return values of the RedPitayas.
An element of an inner array is `nothing` if the command has no return value.
"""
function execute!(rpc::RedPitayaCluster, batch::ScpiBatch)
  # Send cmd after cmd to each "affected" RedPitaya
  for (f, args) in batch.cmds
    indices = batchIndices(f, rpc, args...)
    @sync for idx in indices
      @async send(rpc[idx], scpiCommand(f, batchTransformArgs(f, rpc, idx, args...)...))
    end
  end
  results = []
  # Retrieve results from each "affected" RedPitaya for each cmd
  for (f, args) in batch.cmds
    result = Array{Any}(nothing, length(rpc))
    indices = batchIndices(f, rpc, args...)
    @sync for idx in indices
      @async begin
        if !isnothing(scpiReturn(f))
          ret = parseReturn(f, receive(rpc[idx], _timeout))
          result[idx] = ret
        end
      end
    end
    push!(results, result)
  end
  return results
end

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
    @error "Timeout"
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
