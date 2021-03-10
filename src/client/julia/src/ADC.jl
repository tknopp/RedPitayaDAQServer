export decimation, masterTrigger, currentFrame, ramWriterMode, connectADC, startADC, stopADC, readData, samplesPerPeriod, periodsPerFrame, 
     numSlowDACChan, setSlowDACLUT, enableSlowDAC, slowDACStepsPerRotation, samplesPerSlowDACStep, prepareSlowDAC,
     currentWP, slowDACInterpolation, numSlowADCChan, numLostStepsSlowADC, bufferSize, keepAliveReset, triggerMode,
     slowDACPeriodsPerFrame, enableDACLUT, ADCPerformanceData, RPPerformance, RPStatus, RPInfo, startPipelinedData, PerformanceData

struct ADCPerformanceData
  deltaRead::UInt64
  deltaSend::UInt64
end

struct RPStatus
  overwritten::Bool
  corrupted::Bool
  stepsLost::Bool
  adcEnabled::Bool
  dacEnabled::Bool
end

struct PerformanceData
  wpRead::UInt64
  adc::ADCPerformanceData
  dac::DACPerformanceData
  status::RPStatus
end

struct RPPerformance
  data::Vector{PerformanceData}
end

struct RPInfo
  performances::Vector{RPPerformance}
end

function RPInfo()
  return RPInfo([RPPerformance([])])
end

decimation(rp::RedPitaya) = query(rp,"RP:ADC:DECimation?", Int64)
function decimation(rp::RedPitaya, dec)
  rp.decimation = Int64(dec)
  send(rp, string("RP:ADC:DECimation ", rp.decimation))
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

function samplesPerPeriod(rp::RedPitaya) 
  return rp.samplesPerPeriod
end
function samplesPerPeriod(rp::RedPitaya, value)
  rp.samplesPerPeriod = value
  samplesPerSlowDACStep(rp, value)
end

function periodsPerFrame(rp::RedPitaya) 
  return rp.periodsPerFrame
end
function periodsPerFrame(rp::RedPitaya, value)
  rp.periodsPerFrame = value
  slowDACStepsPerRotation(rp, value)
end

samplesPerSlowDACStep(rp::RedPitaya) = query(rp,"RP:ADC:SlowDAC:SamplesPerStep?", Int64)
function samplesPerSlowDACStep(rp::RedPitaya, value)
  send(rp, string("RP:ADC:SlowDAC:SamplesPerStep ", value))
end

slowDACStepsPerRotation(rp::RedPitaya) = query(rp,"RP:ADC:SlowDAC:StepsPerRotation?", Int64)
function slowDACStepsPerRotation(rp::RedPitaya, value)
  send(rp, string("RP:ADC:SlowDAC:StepsPerRotation ", value))
end

function prepareSlowDAC(rp::RedPitaya, samplesPerStep, stepsPerRotation, numOfChan)
  numSlowDACChan(rp, numOfChan)
  samplesPerSlowDACStep(rp, samplesPerStep)
  slowDACStepsPerRotation(rp, stepsPerRotation)
end

function currentFrame(rp::RedPitaya)
  return Int64(floor(currentWP(rp) / (rp.samplesPerPeriod * rp.periodsPerFrame)))
end

function currentPeriod(rp::RedPitaya) 
  return Int64(floor(currentWP(rp) / (rp.samplesPerPeriod)))
end

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
function startADC(rp::RedPitaya)
  send(rp, "RP:ADC:ACQSTATUS ON")
end
stopADC(rp::RedPitaya) = send(rp, "RP:ADC:ACQSTATUS OFF")

wasOverwritten(rp::RedPitaya) = query(rp, "RP:STATus:OVERwritten?", Bool)
wasCorrupted(rp::RedPitaya) = query(rp, "RP:STATus:CORRupted?", Bool)

function serverStatus(rp::RedPitaya) 
  send(rp, "RP:STATus?")
  return readServerStatus(rp)
end

function readServerStatus(rp::RedPitaya)
  statusRaw = read!(rp.dataSocket, Array{Int8}(undef, 1))[1]
  status = RPStatus((statusRaw & 1) != 0, # overwritten
   (statusRaw & (1 << 1)) != 0, # corrupted
   (statusRaw & (1 << 2)) != 0, # stepsLost
   (statusRaw & (1 << 3)) != 0, # adcEnabled
   (statusRaw & (1 << 4)) != 0) # dacEnabled
  return status
end

function performanceData(rp::RedPitaya)
  send(rp, "RP:PERF?")
  return readPerformanceData(rp)
end

function readPerformanceData(rp::RedPitaya)
  adc = readADCPerformanceData(rp)
  dac = readDACPerformanceData(rp)
  return (adc, dac)
end

function readADCPerformanceData(rp::RedPitaya)
  perf = read!(rp.dataSocket, Array{UInt64}(undef, 2))
  return ADCPerformanceData(perf[1], perf[2])
end

# Low level read. One has to take care that the numFrames are available
function readSamples_(rp::RedPitaya, reqWP, numSamples)
  command = string("RP:ADC:DATA? ",Int64(reqWP),",",Int64(numSamples))
  send(rp, command)

  @debug "read data ..."
  u = read!(rp.dataSocket, Array{Int16}(undef, 2 * Int64(numSamples)))
  @debug "read data!"
  return u
end

# Low level read, reads samples, error and perf. Values need to be already requested
function readSamplesChunk_(rp::RedPitaya, reqWP::Int64, numSamples::Int64, into=nothing)
  @debug "read samples chunk ..."
  if into === nothing
    into = Array{Int16}(undef, 2 * Int64(numSamples))
  end
  data = read!(rp.dataSocket, into)
  status = readServerStatus(rp)
  (adc, dac) = readPerformanceData(rp)
  @debug "read samples chunk ..."
  perf = PerformanceData(UInt64(reqWP), adc, dac, status)
  return (data, perf)
end

# Low level read, that includes performance and error data
function readDetailedSamples_(rp::RedPitaya, reqWP::Int64, numSamples::Int64)
  command = string("RP:ADC:DATA:DETAILED? ",Int64(reqWP),",",Int64(numSamples))
  send(rp, command)
  return readSamplesChunk_(rp, reqWP, numSamples)
end


function readSamplesIntermediate_(rp::RedPitaya, reqWP::Int64, numSamples::Int64)
  data = readSamples_(rp, reqWP, numSamples)
  status = serverStatus(rp)
  (adc, dac) = performanceData(rp)
  perf = PerformanceData(UInt64(reqWP), adc, dac, status)
  return (data, perf)
end

function readSamplesOld_(rp::RedPitaya, reqWP::Int64, numSamples::Int64)
  data = readSamples_(rp, reqWP, numSamples)
  overwritten = wasOverwritten(rp)
  corrupted = wasCorrupted(rp)
  status = RPStatus(overwritten, corrupted, false, true, true)
  (adc, dac) = performanceData(rp)
  perf = PerformanceData(UInt64(reqWP), adc, dac, status)
  return (data, perf)
end

function startPipelinedData(rp::RedPitaya, reqWP::Int64, numSamples::Int64, chunkSize::Int64)
  command = string("RP:ADC:DATA:PIPELINED? ", reqWP, ",", numSamples, ",", chunkSize)
  send(rp, command)
end

# High level read. numFrames can adress a future frame. Data is read in
# chunks
function readData(rp::RedPitaya, startFrame, numFrames, numBlockAverages=1, numPeriodsPerPatch=1)
  dec = rp.decimation
  numSampPerPeriod = rp.samplesPerPeriod
  numSamp = numSampPerPeriod * numFrames # ??
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

    @debug "Read from $wpRead until $(wpRead+chunk-1), WpWrite $(wpWrite), chunk=$(chunk)"
    # Compute Server WP 
    reqWP = wpRead * numSampPerFrame
    numSamples = chunk * numSampPerFrame
    t = readSamples_(rp, Int64(reqWP), Int64(numSamples))
    u = reshape(t, 2, rp.samplesPerPeriod, numPeriods, chunk)
    utmp1 = reshape(u,2,numTrueSampPerPeriod,numBlockAverages,size(u,3)*numPeriodsPerPatch,size(u,4))
    utmp2 = numBlockAverages > 1 ? mean(utmp1,dims=3) : utmp1
    data[:,1,:,l:(l+chunk-1)] = utmp2[1,:,1,:,:]
    data[:,2,:,l:(l+chunk-1)] = utmp2[2,:,1,:,:]

    if wasOverwritten(rp)
      @error "Requested data from $wpRead until $(wpRead+chunk) was overwritten"
    end
    if wasCorrupted(rp)
      @error "Requested data from $wpRead until $(wpRead+chunk) might have been corrupted"
    end

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
