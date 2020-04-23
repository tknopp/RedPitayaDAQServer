export RedPitayaCluster, master, readDataPeriods, numChan, readDataSlow

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

function currentFrame(rpc::RedPitayaCluster)
  currentFrames = currentFrame(rpc.rp[1]) #[ currentFrame(rp) for rp in rpc.rp ]
  @debug "Current frame: $currentFrames"
  #return minimum(currentFrames)
  return currentFrames
end

function currentPeriod(rpc::RedPitayaCluster)
  currentPeriods = currentPeriod(rpc.rp[1])  #[ currentPeriod(rp) for rp in rpc.rp ]
  @debug "Current period: $currentPeriods"
  #return minimum(currentPeriods)
  return currentPeriods
end

for op in [:periodsPerFrame,  :samplesPerPeriod, :decimation, :keepAliveReset,
           :triggerMode, :slowDACPeriodsPerFrame]
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
  wp = currentWP(rpc.rp[1])
  for rp in rpc.rp
    startADC(rp, wp)
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

for op in [:amplitudeDAC,  :frequencyDAC, :phaseDAC, :modulusFactorDAC, :modulusDAC]
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

for op in [:signalTypeDAC,  :DCSignDAC]
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
end

#"STANDARD" or "RASTERIZED"
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

# High level read. numFrames can adress a future frame. Data is read in
# chunks
function readData(rpc::RedPitayaCluster, startFrame, numFrames, numBlockAverages=1, numPeriodsPerPatch=1)
  numSampPerPeriod = master(rpc).samplesPerPeriod
  numSamp = numSampPerPeriod * numFrames
  numPeriods = master(rpc).periodsPerFrame
  numSampPerFrame = numSampPerPeriod * numPeriods

  if rem(numSampPerPeriod,numBlockAverages) != 0
    error("block averages has to be a divider of numSampPerPeriod")
  end

  numTrueSampPerPeriod = div(numSampPerPeriod,numBlockAverages*numPeriodsPerPatch)

  data = zeros(Float32, numTrueSampPerPeriod, numChan(rpc), numPeriods*numPeriodsPerPatch, numFrames)
  wpRead = startFrame
  l=1

  numFramesInMemoryBuffer = bufferSize(master(rpc)) / numSampPerFrame #numSamp
  @debug "numFramesInMemoryBuffer = $numFramesInMemoryBuffer"

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

    if wpWrite - numFramesInMemoryBuffer >= wpRead
      error("WARNING: We have lost data !!!!!!!!!!")
    end

    @debug "Read from $wpRead until $(wpRead+chunk-1), WpWrite $(wpWrite), chunk=$(chunk)"

    for (d,rp) in enumerate(rpc.rp)
     # @sync  @async begin
        u = readData_(rp, Int64(wpRead), Int64(chunk))
        utmp1 = reshape(u,2,numTrueSampPerPeriod,numBlockAverages,
                            size(u,3)*numPeriodsPerPatch,size(u,4))
        utmp2 = numBlockAverages > 1 ? mean(utmp1,dims=3) : utmp1

        data[:,2*d-1,:,l:(l+chunk-1)] = utmp2[1,:,1,:,:]
        data[:,2*d,:,l:(l+chunk-1)] = utmp2[2,:,1,:,:]
     #  end
    end

    l += chunk
    wpRead += chunk
  end

  return data
end

function readDataPeriods(rpc::RedPitayaCluster, startPeriod, numPeriods, numBlockAverages=1)
  numSampPerPeriod = master(rpc).samplesPerPeriod
  numSamp = numSampPerPeriod * numPeriods

  if rem(numSampPerPeriod,numBlockAverages) != 0
    error("block averages has to be a divider of numSampPerPeriod")
  end

  numAveragedSampPerPeriod = div(numSampPerPeriod,numBlockAverages)

  data = zeros(Float32, numAveragedSampPerPeriod, numChan(rpc), numPeriods)
  wpRead = startPeriod
  l=1

  # This is a wild guess for a good chunk size
  chunkSize = max(1,  round(Int, 1000000 / numSampPerPeriod)  )
  println("chunkSize = $chunkSize; numPeriods = $numPeriods")
  while l<=numPeriods
    wpWrite = currentPeriod(rpc)
    while wpRead >= wpWrite # Wait that startPeriod is reached
      wpWrite = currentPeriod(rpc)
      @debug wpWrite
    end
    chunk = min(wpWrite-wpRead,chunkSize) # Determine how many periods to read
    @debug chunk
    if l+chunk > numPeriods
      chunk = numPeriods - l + 1
    end

    @debug "Read from $wpRead until $(wpRead+chunk-1), WpWrite $(wpWrite), chunk=$(chunk)"

    for (d,rp) in enumerate(rpc.rp)
    # @sync   @async begin
        u = readDataPeriods_(rp, Int64(wpRead), Int64(chunk))

        utmp1 = reshape(u,2,numAveragedSampPerPeriod,numBlockAverages,size(u,3))
        utmp2 = numBlockAverages > 1 ? mean(utmp1,dims=3) : utmp1

        data[:,2*d-1,l:(l+chunk-1)] = utmp2[1,:,1,:]
        data[:,2*d,l:(l+chunk-1)] = utmp2[2,:,1,:]
    #  end
    end

    l += chunk
    wpRead += chunk
  end

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
