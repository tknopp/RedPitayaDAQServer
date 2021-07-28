export decimation, masterTrigger, currentFrame, ramWriterMode, connectADC, startADC, stopADC, samplesPerPeriod, periodsPerFrame, 
     currentWP, slowDACInterpolation, bufferSize, keepAliveReset, triggerMode,
     ADCPerformanceData, RPPerformance, RPStatus, RPInfo, startPipelinedData, PerformanceData, numChan, dataRate

struct ADCPerformanceData
  deltaRead::UInt64
  deltaSend::UInt64
  chunkSize::UInt64
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

function dataRate(chunkSize, deltaSend, decimation; unit="Mbits")
  bitsPerSample = (chunkSize * 4 * 8) / deltaSend # 4 bytes per samples
  freq = div(125e6, decimation)
  bitsPerSec = bitsPerSample * freq 
  return bitsPerSec/1e6 #TODO unit conversion
end


function dataRate(adc::ADCPerformanceData, decimation; unit ="Mbits")
  return dataRate(adc.chunkSize, adc.deltaSend, decimation)
end

decimation(rp::RedPitaya) = query(rp,"RP:ADC:DECimation?", Int64)
function decimation(rp::RedPitaya, dec)
  rp.decimation = Int64(dec)
  send(rp, string("RP:ADC:DECimation ", rp.decimation))
end

numChan(rp::RedPitaya) = 2

function slowDACInterpolation(rp::RedPitaya, enable::Bool)
  enableI = Int32(enable)
  send(rp, string("RP:ADC:SlowDACInterpolation ", enableI))
end

numSlowADCChan(rp::RedPitaya) = query(rp,"RP:ADC:SlowADC?", Int64)
function numSlowADCChan(rp::RedPitaya, value)
  send(rp, string("RP:ADC:SlowADC ", Int64(value)))
end

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

function performanceData(rp::RedPitaya, numSamples = 0)
  send(rp, "RP:PERF?")
  return readPerformanceData(rp, numSamples)
end

function readPerformanceData(rp::RedPitaya, numSamples = 0)
  adc = readADCPerformanceData(rp, numSamples)
  dac = readDACPerformanceData(rp)
  return (adc, dac)
end

function readADCPerformanceData(rp::RedPitaya, numSamples = 0)
  perf = read!(rp.dataSocket, Array{UInt64}(undef, 2))
  return ADCPerformanceData(perf[1], perf[2], numSamples)
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
  if isnothing(into)
    into = Array{Int16}(undef, 2 * Int64(numSamples))
  end
  data = read!(rp.dataSocket, into)
  status = readServerStatus(rp)
  (adc, dac) = readPerformanceData(rp, numSamples)
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
