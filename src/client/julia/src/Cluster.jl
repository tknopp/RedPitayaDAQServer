export RedPitayaCluster, master, readDataPeriods, numChan, readDataSlow, readFrames, readPeriods

import Base: length

struct RedPitayaCluster
  rp::Vector{RedPitaya}
end

#TODO: set first RP to master
function RedPitayaCluster(hosts::Vector{String}, port=5025)
  # the first RP is the master
  rps = RedPitaya[ RedPitaya(host, port, i==1) for (i,host) in enumerate(hosts) ]

  for rp in rps
    triggerMode(rp, "EXTERNAL")
  end

  return RedPitayaCluster(rps)
end

length(rpc::RedPitayaCluster) = length(rpc.rp)
numChan(rpc::RedPitayaCluster) = 2*length(rpc)
master(rpc::RedPitayaCluster) = rpc.rp[1]

const _currentFrame = Ref(0)

function currentFrame(rpc::RedPitayaCluster)
  _currentFrame[] = currentFrame(rpc.rp[1]) #[ currentFrame(rp) for rp in rpc.rp ]
  @debug "Current frame: $(_currentFrame[])"
  #return minimum(currentFrames)
  return _currentFrame[]
end

function currentPeriod(rpc::RedPitayaCluster)
  currentPeriods = currentPeriod(rpc.rp[1])  #[ currentPeriod(rp) for rp in rpc.rp ]
  @debug "Current period: $currentPeriods"
  #return minimum(currentPeriods)
  return currentPeriods
end

function currentWP(rpc::RedPitayaCluster)
  return currentWP(master(rpc))
end

for op in [:periodsPerFrame, :samplesPerPeriod, :decimation, :keepAliveReset,
           :triggerMode, :slowDACStepsPerRotation, :samplesPerSlowDACStep]
  @eval $op(rpc::RedPitayaCluster) = $op(master(rpc))
  @eval begin
    function $op(rpc::RedPitayaCluster, value)
      for rp in rpc.rp
        $op(rp, value)
      end
    end
  end
end

for op in [:connectADC, :stopADC, :disconnect, :connect]
  @eval begin
    function $op(rpc::RedPitayaCluster)
      for rp in rpc.rp
        $op(rp)
      end
    end
  end
end

function startADC(rpc::RedPitayaCluster)
  for rp in rpc.rp
    startADC(rp)
  end
end

function masterTrigger(rpc::RedPitayaCluster, val::Bool)
    if val
        masterTrigger(master(rpc), val)
    else
        keepAliveReset(rpc, true)
        masterTrigger(master(rpc), false)
        keepAliveReset(rpc, false)
    end
end
masterTrigger(rpc::RedPitayaCluster) = masterTrigger(master(rpc))
bufferSize(rpc::RedPitayaCluster) = bufferSize(master(rpc))

# "TRIGGERED" or "CONTINUOUS"
function ramWriterMode(rpc::RedPitayaCluster, mode::String)
  for rp in rpc.rp
    ramWriterMode(rp, mode)
  end
end

for op in [:amplitudeDAC, :amplitudeDACNext, :frequencyDAC, :phaseDAC, :modulusFactorDAC, :modulusDAC]
  @eval function $op(rpc::RedPitayaCluster, chan::Integer, component::Integer)
    idxRP = div(chan-1, 2) + 1
    chanRP = mod1(chan, 2)
    return $op(rpc.rp[idxRP], chanRP, component)
  end
  @eval function $op(rpc::RedPitayaCluster, chan::Integer, component::Integer, value)
    idxRP = div(chan-1, 2) + 1
    chanRP = mod1(chan, 2)
    return $op(rpc.rp[idxRP], chanRP, component, value)
  end
end

for op in [:signalTypeDAC,  :DCSignDAC, :jumpSharpnessDAC]
  @eval function $op(rpc::RedPitayaCluster, chan::Integer)
    idxRP = div(chan-1, 2) + 1
    chanRP = mod1(chan, 2)
    return $op(rpc.rp[idxRP], chanRP)
  end
  @eval function $op(rpc::RedPitayaCluster, chan::Integer, value)
    idxRP = div(chan-1, 2) + 1
    chanRP = mod1(chan, 2)
    return $op(rpc.rp[idxRP], chanRP, value)
  end
end

function setSlowDAC(rpc::RedPitayaCluster, chan, value)
  idxRP = div(chan-1, 2) + 1
  chanRP = mod(chan-1, 2)
  setSlowDAC(rpc.rp[idxRP], chanRP, value)
end

function getSlowADC(rpc::RedPitayaCluster, chan::Integer)
  idxRP = div(chan-1, 2) + 1
  chanRP = mod(chan-1, 2)
  getSlowADC(rpc.rp[idxRP], chanRP)
end

function numSlowADCChan(rpc::RedPitayaCluster)
  tmp = [ numSlowADCChan(rp) for rp in rpc.rp]
  return sum(tmp)
end

function numSlowADCChan(rpc::RedPitayaCluster, num)
  for rp in rpc.rp
    numSlowADCChan(rp, num)
  end
  return
end

function passPDMToFastDAC(rpc::RedPitayaCluster, val::Vector{Bool})
  for (d,rp) in enumerate(rpc.rp)
    passPDMToFastDAC(rp, val[d])
  end
end

function passPDMToFastDAC(rpc::RedPitayaCluster)
  return [ passPDMToFastDAC(rp) for rp in rpc.rp]
end

modeDAC(rpc::RedPitayaCluster) = modeDAC(master(rpc))

function modeDAC(rpc::RedPitayaCluster, mode::String)
  for rp in rpc.rp
    modeDAC(rp, mode)
  end
end

function enableSlowDAC(rpc::RedPitayaCluster, enable::Bool, numFrames::Int64=0,
                       ffRampUpTime::Float64=0.4, ffRampUpFraction::Float64=0.8)
  # We just use the first rp currently
  #res = [enableSlowDAC(rp, enable) for rp in rpc.rp]
  #return maximum(res)
  return enableSlowDAC(rpc.rp[1], enable, numFrames, ffRampUpTime, ffRampUpFraction)
end

function slowDACInterpolation(rpc::RedPitayaCluster, enable::Bool)
  for rp in rpc.rp
    slowDACInterpolation(rp, enable)
  end
end

function startPipelinedData(rpc::RedPitayaCluster, reqWP::Int64, numSamples::Int64, chunkSize::Int64)
  for rp in rpc.rp
    startPipelinedData(rp, reqWP, numSamples, chunkSize)
  end
end

function readPipelinedSamples(rpc::RedPitayaCluster, wpStart::Int64, numOfRequestedSamples::Int64; chunkSize::Int64 = 25000, collectPerformance=false)
  numOfReceivedSamples = 0
  index = 1
  rawData = zeros(Int16, numChan(rpc), numOfRequestedSamples)
  performances = [RPPerformance([]) for i = 1:length(rpc)]

  startPipelinedData(rpc, wpStart, numOfRequestedSamples, chunkSize)
  while numOfReceivedSamples < numOfRequestedSamples
    wpRead = wpStart + numOfReceivedSamples
    chunk = min(numOfRequestedSamples - numOfReceivedSamples, chunkSize)
    collectSamples!(rpc, wpRead, chunk, rawData, performances, index, pipelined=true, collectPerformance = collectPerformance)
    index += chunk
    numOfReceivedSamples += chunk
  end
  return (rawData, ReadOverview(performances))

end

function readSamples(rpc::RedPitayaCluster, wpStart::Int64, numOfRequestedSamples::Int64; chunkSize::Int64 = 25000, collectPerformance=false)
  numOfReceivedSamples = 0
  index = 1
  rawData = zeros(Int16, numChan(rpc), numOfRequestedSamples)
  performances = [RPPerformance([]) for i = 1:length(rpc)]
  while numOfReceivedSamples < numOfRequestedSamples
    wpRead = wpStart + numOfReceivedSamples
    wpWrite = currentWP(rpc)
    
    # Wait for data to be written
    while wpRead >= wpWrite
      wpWrite = currentWP(rpc)
      @debug wpWrite
    end

    # Collect data
    chunk = min(numOfRequestedSamples - numOfReceivedSamples, chunkSize)
    if (wpRead + chunk > wpWrite)
      chunk = wpWrite - wpRead
    end
    collectSamples!(rpc, wpRead, chunk, rawData, performances, index, collectPerformance = collectPerformance)
    index += chunk
    numOfReceivedSamples += chunk
  end
  return (rawData, ReadOverview(performances))
end

function collectSamples!(rpc::RedPitayaCluster, wpRead::Int64, chunk::Int64, rawData, performances, index; pipelined=false, collectPerformance=false)
  done = zeros(Bool, length(rpc.rp))
  iterationDone = Condition()
  timeoutHappened = false
  collectFunction = readDetailedSamples_
  if pipelined
    collectFunction = readSamplesChunk_
  end
  @async for (d, rp) in enumerate(rpc.rp)
    (u, perf) = collectFunction(rp, Int64(wpRead), Int64(chunk))
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
    if collectPerformance
      push!(performances[d].data, perf)
    end

    done[d] = true
    if (all(done))
      notify(iterationDone)
    end
  end

  # Setup Timeout
  timeout = 10
  t = Timer(timeout)
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


# High level read. numFrames can adress a future frame. Data is read in
# chunks
function readFrames(rpc::RedPitayaCluster, startFrame, numFrames, numBlockAverages=1, numPeriodsPerPatch=1; collectPerformance=false, chunkSize = 50000)
  numSampPerPeriod = master(rpc).samplesPerPeriod
  numSamp = numSampPerPeriod * numFrames
  numPeriods = master(rpc).periodsPerFrame
  numSampPerFrame = numSampPerPeriod * numPeriods

  if rem(numSampPerPeriod,numBlockAverages) != 0
    error("block averages has to be a divider of numSampPerPeriod")
  end

  numTrueSampPerPeriod = div(numSampPerPeriod,numBlockAverages*numPeriodsPerPatch)

  data = zeros(Float32, numTrueSampPerPeriod, numChan(rpc), numPeriods*numPeriodsPerPatch, numFrames)
  wpStart = startFrame * numSampPerFrame
  numOfRequestedSamples = numFrames * numSampPerFrame

  # rawSamples Int16 numofChan(rpc) x numOfRequestedSamples
  (rawSamples, overview) = readPipelinedSamples(rpc, Int64(wpStart), Int64(numOfRequestedSamples), chunkSize = chunkSize, collectPerformance = collectPerformance)
  
  # Reshape/Avg Data
  temp = reshape(rawSamples, numChan(rpc), numSampPerPeriod, numPeriods, numFrames)
  for (d, rp) in enumerate(rpc.rp)
    u = temp[2*d-1:2*d, :, :, :]
    utmp1 = reshape(u,2,numTrueSampPerPeriod,numBlockAverages, size(u,3)*numPeriodsPerPatch,size(u,4))
    utmp2 = numBlockAverages > 1 ? mean(utmp1,dims=3) : utmp1
    data[:,2*d-1,:,:] = utmp2[1,:,1,:,:]
    data[:,2*d,:,:] = utmp2[2,:,1,:,:]
  end

  return (data, overview)
end

function readPeriods(rpc::RedPitayaCluster, startPeriod, numPeriods, numBlockAverages=1; collectPerformance=false, chunkSize = 50000)
  numSampPerPeriod = master(rpc).samplesPerPeriod

  if rem(numSampPerPeriod,numBlockAverages) != 0
    error("block averages has to be a divider of numSampPerPeriod")
  end

  numAveragedSampPerPeriod = div(numSampPerPeriod,numBlockAverages)

  data = zeros(Float32, numAveragedSampPerPeriod, numChan(rpc), numPeriods)
  wpStart = startPeriod * numSampPerPeriod
  numOfRequestedSamples = numPeriods * numSampPerPeriod

  # rawSamples Int16 numofChan(rpc) x numOfRequestedSamples
  (rawSamples, overview) = readSamples(rpc, Int64(wpStart), Int64(numOfRequestedSamples), chunkSize = chunkSize, collectPerformance = collectPerformance)

  # Reshape/Avg Data
  temp = reshape(rawSamples, numChan(rpc), numSampPerPeriod, numPeriods)
  for (d, rp) in enumerate(rpc.rp)
    u = temp[2*d-1:2*d, :, :, :]
    utmp1 = reshape(u,2,numAveragedSampPerPeriod,numBlockAverages, size(u,3))
    utmp2 = numBlockAverages > 1 ? mean(utmp1,dims=3) : utmp1
    data[:,2*d-1,:] = utmp2[1,:,1,:]
    data[:,2*d,:] = utmp2[2,:,1,:]
  end
  
  return (data, overview)
end


function readData(rpc::RedPitayaCluster, startFrame, numFrames, numBlockAverages=1, numPeriodsPerPatch=1; chunkSize = 50000)
  (data, overview) = readFrames(rpc, startFrame, numFrames, numBlockAverages, numPeriodsPerPatch, collectPerformance = false, chunkSize = chunkSize)
  return data
end

function readDataPeriods(rpc::RedPitayaCluster, startPeriod, numPeriods, numBlockAverages=1; chunkSize = 50000)
  (data, overview) = readPeriods(rpc, startPeriod, numPeriods, numBlockAverages, collectPerformance = false, chunkSize = chunkSize)
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
    for (d,rp) in enumerate(rpc.rp)
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
