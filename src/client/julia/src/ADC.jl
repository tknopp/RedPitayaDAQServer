export decimation, samplesPerPeriod, periodsPerFrame, masterTrigger, currentFrame,
     currentPeriod, ramWriterMode, connectADC, startADC, stopADC, readData,
     numSlowDACChan, setSlowDACLUT, enableSlowDAC, currentWP, slowDACInterpolation,
     numSlowADCChan, numLostStepsSlowADC, bufferSize, keepAliveReset, triggerMode,
     slowDACPeriodsPerFrame, enableDACLUT


decimation(rp::RedPitaya) = query(rp,"RP:ADC:DECimation?", Int64)
function decimation(rp::RedPitaya, dec)
  rp.decimation = Int64(dec)
  send(rp, string("RP:ADC:DECimation ", rp.decimation))
end

samplesPerPeriod(rp::RedPitaya) = query(rp,"RP:ADC:PERiod?", Int64)
function samplesPerPeriod(rp::RedPitaya, value)
  rp.samplesPerPeriod = Int64(value)
  send(rp, string("RP:ADC:PERiod ", rp.samplesPerPeriod))
end

numSlowDACChan(rp::RedPitaya) = query(rp,"RP:ADC:SlowDAC?", Int64)
function numSlowDACChan(rp::RedPitaya, value)
  if value <= 0 || value > 4
    error("Num slow DAC channels needs to be between 1 and 4!")
  end
  send(rp, string("RP:ADC:SlowDAC ", Int64(value)))
end

function setSlowDACLUT(rp::RedPitaya, lut::Array)
  lutFloat32 = map(Float32, lut)
  send(rp, string("RP:ADC:SlowDACLUT"))
  @debug "Writing slow DAC LUT"
  write(rp.dataSocket, lutFloat32)
end

function enableDACLUT(rp::RedPitaya, lut::Array)
  lutBool = map(Bool, lut)
  send(rp, string("RP:ADC:EnableDACLUT"))
  @debug "Writing enable DAC LUT"
  write(rp.dataSocket, lutBool)
end

function enableSlowDAC(rp::RedPitaya, enable::Bool, numFrames::Int64=0,
            ffRampUpTime::Float64=0.4, ffRampUpFraction::Float64=0.8)
  enableI = Int32(enable)
  return query(rp, string("RP:ADC:SlowDACEnable ", enableI,
              ",", numFrames, ",", ffRampUpTime, ",", ffRampUpFraction), Int64)
end

function slowDACInterpolation(rp::RedPitaya, enable::Bool)
  enableI = Int32(enable)
  send(rp, string("RP:ADC:SlowDACInterpolation ", enableI))
end

numSlowADCChan(rp::RedPitaya) = query(rp,"RP:ADC:SlowADC?", Int64)
function numSlowADCChan(rp::RedPitaya, value)
  send(rp, string("RP:ADC:SlowADC ", Int64(value)))
end

numLostStepsSlowADC(rp::RedPitaya) = query(rp,"RP:ADC:SlowDACLostSteps?", Int64)

periodsPerFrame(rp::RedPitaya) = query(rp,"RP:ADC:FRAme?", Int64)
function periodsPerFrame(rp::RedPitaya, value)
  rp.periodsPerFrame = Int64(value)
  send(rp, string("RP:ADC:FRAme ", rp.periodsPerFrame))
end

slowDACPeriodsPerFrame(rp::RedPitaya) = query(rp,"RP:ADC:SlowDACPeriodsPerFrame?", Int64)
function slowDACPeriodsPerFrame(rp::RedPitaya, value)
  send(rp, string("RP:ADC:SlowDACPeriodsPerFrame ", value))
end

currentFrame(rp::RedPitaya) = query(rp,"RP:ADC:FRAMES:CURRENT?", Int64)
currentPeriod(rp::RedPitaya) = query(rp,"RP:ADC:PERIODS:CURRENT?", Int64)
currentWP(rp::RedPitaya) = query(rp,"RP:ADC:WP:CURRENT?", Int64)
bufferSize(rp::RedPitaya) = query(rp,"RP:ADC:BUFFER:SIZE?", Int64)

function masterTrigger(rp::RedPitaya, val::Bool)
  valStr = val ? "ON" : "OFF"
  send(rp, string("RP:MasterTrigger ", valStr))
end
masterTrigger(rp::RedPitaya) = occursin("ON", query(rp,"RP:MasterTrigger?"))

function keepAliveReset(rp::RedPitaya, val::Bool)
  valStr = val ? "ON" : "OFF"
  send(rp, string("RP:KeepAliveReset ", valStr))
end
keepAliveReset(rp::RedPitaya) = occursin("ON", query(rp,"RP:KeepAliveReset?"))


# "TRIGGERED" or "CONTINUOUS"
function ramWriterMode(rp::RedPitaya, mode::String)
  send(rp, string("RP:RamWriterMode ", mode))
end

# "INTERNAL" or "EXTERNAL"
function triggerMode(rp::RedPitaya, mode::String)
  send(rp, string("RP:Trigger:Mode ", mode))
end

connectADC(rp::RedPitaya) = send(rp, "RP:ADC:ACQCONNect")
startADC(rp::RedPitaya, wp::Integer = currentWP(rp)) = send(rp, "RP:ADC:ACQSTATUS ON,$wp")
stopADC(rp::RedPitaya) = send(rp, "RP:ADC:ACQSTATUS OFF,0")

# Low level read. One has to take care that the numFrames are available
function readData_(rp::RedPitaya, startFrame, numFrames)
  numSampPerPeriod = rp.samplesPerPeriod
  numPeriods = rp.periodsPerFrame
  numSampPerFrame = numSampPerPeriod * numPeriods

  command = string("RP:ADC:FRAMES:DATA ",Int64(startFrame),",",Int64(numFrames))
  send(rp, command)

  @debug "read data ..."
  u = read!(rp.dataSocket, Array{Int16}(undef, 2 * numFrames * numSampPerFrame))
  @debug "read data!"
  return reshape(u, 2, rp.samplesPerPeriod, numPeriods, numFrames)
end

# Low level read. One has to take care that the numFrames are available
function readDataPeriods_(rp::RedPitaya, startPeriod, numPeriods)
  command = string("RP:ADC:PERiods:DATa ",Int64(startPeriod),",",Int64(numPeriods))
  send(rp, command)

  @debug "read data ..."
  u = read!(rp.dataSocket, Array{Int16}(undef, 2 * numPeriods * rp.samplesPerPeriod))
  @debug "read data!"
  return reshape(u, 2, rp.samplesPerPeriod, numPeriods)
end

# High level read. numFrames can adress a future frame. Data is read in
# chunks
function readData(rp::RedPitaya, startFrame, numFrames, numBlockAverages=1, numPeriodsPerPatch=1)
  dec = rp.decimation
  numSampPerPeriod = rp.samplesPerPeriod
  numSamp = numSampPerPeriod * numFrames
  numPeriods = rp.periodsPerFrame
  numSampPerFrame = numSampPerPeriod * numPeriods

  if rem(numSampPerPeriod,numBlockAverages) != 0
    error("block averages has to be a divider of numSampPerPeriod")
  end

  numTrueSampPerPeriod = div(numSampPerPeriod,numBlockAverages*numPeriodsPerPatch)


  data = zeros(Float32, numTrueSampPerPeriod, 2, numPeriods*numPeriodsPerPatch, numFrames)
  wpRead = startFrame
  l=1

  numFramesInMemoryBuffer = bufferSize(rp) / numSampPerFrame
  @debug "numFramesInMemoryBuffer = $numFramesInMemoryBuffer"

  # This is a wild guess for a good chunk size
  chunkSize = max(1,  round(Int, 1000000 / numSampPerFrame)  )
  @debug "chunkSize = $chunkSize"
  while l<=numFrames
    wpWrite = currentFrame(rp)
    while wpRead >= wpWrite # Wait that startFrame is reached
      wpWrite = currentFrame(rp)
      @debug wpWrite
    end
    chunk = min(wpWrite-wpRead,chunkSize) # Determine how many frames to read
    @debug chunk
    if l+chunk > numFrames
      chunk = numFrames - l + 1
    end

    if wpWrite - numFramesInMemoryBuffer > wpRead
      @error "WARNING: We have lost data !!!!!!!!!!"
    end

    @debug "Read from $wpRead until $(wpRead+chunk-1), WpWrite $(wpWrite), chunk=$(chunk)"


    u = readData_(rp, Int64(wpRead), Int64(chunk))
    utmp1 = reshape(u,2,numTrueSampPerPeriod,numBlockAverages,size(u,3)*numPeriodsPerPatch,size(u,4))
    utmp2 = numBlockAverages > 1 ? mean(utmp1,dims=3) : utmp1

    data[:,1,:,l:(l+chunk-1)] = utmp2[1,:,1,:,:]
    data[:,2,:,l:(l+chunk-1)] = utmp2[2,:,1,:,:]

    l += chunk
    wpRead += chunk
  end

  return data
end


# Low level read. One has to take care that the numFrames are available
function readDataSlow_(rp::RedPitaya, startFrame, numFrames)
  numPeriods = rp.periodsPerFrame
  numChan = numSlowADCChan(rp)

  command = string("RP:ADC:SLOW:FRAMES:DATA ",Int64(startFrame),",",Int64(numFrames))
  #send(rp, command)

  @debug "read data ..."
  #u = read!(rp.dataSocket, Array{Float32}(undef, numChan * numFrames * numPeriods))
  @debug "read data!"
  #return reshape(u, numChan, numPeriods, numFrames)
  return zeros(Float32, numChan, numPeriods, numFrames)
end
