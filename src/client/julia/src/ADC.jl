export TriggerMode, INTERNAL, EXTERNAL, ADCPerformanceData, RPStatus, PerformanceData, RPPerformance, RPInfo,
decimation, decimation!, numChan, samplesPerPeriod, samplesPerPeriod!, periodsPerFrame, periodsPerFrame!,
currentWP, currentPeriod, currentFrame, masterTrigger, masterTrigger!, keepAliveReset, keepAliveReset!,
triggerMode, triggerMode!, startADC, stopADC, overwritten, corrupted, serverStatus, performanceData,
startPipelinedData

"""
    TriggerMode

Represent the different trigger modes the FPGA image can have. Valid value are `INTERNAL` and `EXTERNAL`.

See [`triggerMode`](@ref), [`triggerMode!`](@ref).
"""
@enum TriggerMode INTERNAL EXTERNAL
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

"""
    decimation(rp::RedPitaya)

Return the decimation of the RedPitaya.

# Examples
```julia
julia> decimation!(rp, 8)
true

julia> decimation(rp)
8
```
"""
decimation(rp::RedPitaya) = query(rp, scpiCommand(decimation), scpiReturn(decimation))
scpiCommand(::typeof(decimation)) = "RP:ADC:DECimation?"
scpiReturn(::typeof(decimation)) = Int64
"""
    decimation!(rp::RedPitaya, dec)

Set the decimation of the RedPitaya. Return `true` if the command was successful.

# Examples
```julia
julia> decimation!(rp, 8)
true

julia> decimation(rp)
8
```
"""
function decimation!(rp::RedPitaya, dec)
  rp.decimation = Int64(dec)
  return query(rp, scpiCommand(decimation!, rp.decimation), scpiReturn(decimation!))
end
scpiCommand(::typeof(decimation!), dec) = string("RP:ADC:DECimation ", dec)
scpiReturn(::typeof(decimation!)) = Bool
"""
    numChan(rp::RedPitaya)

Return the number of ADC channel of a RedPitaya.
"""
numChan(rp::RedPitaya) = 2

"""
    samplesPerPeriod(rp::RedPitaya)

Return the number of samples per period.

# Example
```julia
julia> samplesPerPeriod!(rp, 256)
true

julia> samplesPerPeriod(rp)
256

```
"""
function samplesPerPeriod(rp::RedPitaya) 
  return rp.samplesPerPeriod
end
"""
    samplesPerPeriod!(rp::RedPitaya, value)
  
Set the number of samples per period.

# Example
```julia
julia> samplesPerPeriod!(rp, 256)
true

julia> samplesPerPeriod(rp)
256

```
"""
function samplesPerPeriod!(rp::RedPitaya, value)
  rp.samplesPerPeriod = value
  return true
end

"""
    periodsPerFrame(rp::RedPitaya)
  
Return the number of periods per frame.

# Example
```julia
julia> periodsPerFrame!(rp, 16)

julia> periodsPerFrame(rp)
16

```
"""
function periodsPerFrame(rp::RedPitaya) 
  return rp.periodsPerFrame
end
"""
    periodsPerFrame(rp::RedPitaya, value)
  
Set the number of periods per frame.

# Example
```julia
julia> periodsPerFrame!(rp, 16)

julia> periodsPerFrame(rp)
16

```
"""
function periodsPerFrame!(rp::RedPitaya, value)
  rp.periodsPerFrame = value
  return true
end

"""
    currentFrame(rp::RedPitaya)

Return the current frame of the RedPitaya based on the current writepointer, samples per period and periods per frame.

See also [`currentWP`](@ref), [`samplesPerPeriod`](@ref), [`periodsPerFrame`](@ref).
"""
function currentFrame(rp::RedPitaya)
  return Int64(floor(currentWP(rp) / (rp.samplesPerPeriod * rp.periodsPerFrame)))
end

"""
    currentPeriod(rp::RedPitaya)

Return the current period of the RedPitaya based on the current writepointer and samples per period.

See also [`currentWP`](@ref), [`samplesPerPeriod`](@ref).
"""
function currentPeriod(rp::RedPitaya) 
  return Int64(floor(currentWP(rp) / (rp.samplesPerPeriod)))
end

"""
    currentWP(rp::RedPitaya)

Return the current writepointer of the RedPitaya.
"""
currentWP(rp::RedPitaya) = query(rp, scpiCommand(currentWP), scpiReturn(currentWP))
scpiCommand(::typeof(currentWP)) = "RP:ADC:WP?"
scpiReturn(::typeof(currentWP)) = Int64
bufferSize(rp::RedPitaya) = query(rp,"RP:ADC:BUFFER:SIZE?", Int64)

"""
    masterTrigger!(rp::RedPitaya, val::Bool)

Set the master trigger of the RedPitaya to `val`. Return `true` if the command was successful.

# Example
```julia
julia> masterTrigger!(rp, true)
true

julia>masterTrigger(rp)
true
```
"""
function masterTrigger!(rp::RedPitaya, val)
  return query(rp, scpiCommand(masterTrigger!, val), scpiReturn(masterTrigger!))
end
scpiCommand(::typeof(masterTrigger!), val::Bool) = scpiCommand(masterTrigger!, val ? "ON" : "OFF")
scpiCommand(::typeof(masterTrigger!), valStr) = string("RP:TRIGger ", valStr)
scpiReturn(::typeof(masterTrigger!)) = Bool
"""
    masterTrigger(rp::RedPitaya)

Determine whether the master trigger is set.
# Example
```julia
julia> masterTrigger!(rp, true)

julia>masterTrigger(rp)
true
```
"""
masterTrigger(rp::RedPitaya) = occursin("ON", query(rp, scpiCommand(masterTrigger)))
scpiCommand(::typeof(masterTrigger)) = "RP:TRIGger?"
scpiReturn(::typeof(masterTrigger)) = String
parseReturn(::typeof(masterTrigger), ret) = occursin("ON", ret)

"""
    keepAliveReset!(rp::RedPitaya, val::Bool)

Set the keepAliveReset to `val`.
"""
function keepAliveReset!(rp::RedPitaya, val::Bool)
  return query(rp, scpiCommand(keepAliveReset!, val), scpiReturn(keepAliveReset!))
end
scpiCommand(::typeof(keepAliveReset!), val::Bool) = scpiCommand(keepAliveReset!, val ? "ON" : "OFF")
scpiCommand(::typeof(keepAliveReset!)) = string("RP:TRIGger:ALiVe ", valStr)
scpiReturn(::typeof(keepAliveReset!)) = Bool
"""
    keepAliveReset(rp::RedPitaya)

Determine whether the keepAliveReset is set.
"""
keepAliveReset(rp::RedPitaya) = occursin("ON", query(rp, scpiCommand(keepAliveReset)))
scpiCommand(::typeof(keepAliveReset)) = "RP:TRIGger?"
scpiReturn(::typeof(keepAliveReset)) = String
parseReturn(::typeof(keepAliveReset), ret) = occursin("ON", ret)


# "INTERNAL" or "EXTERNAL"
"""
    triggerMode!(rp::RedPitaya, mode::String)

Set the trigger mode of the RedPitaya. Return `true` if the command was successful.
"""
function triggerMode!(rp::RedPitaya, mode::String)
  return triggerMode!(rp, stringToEnum(TriggerMode, mode))
end
"""
    triggerMode!(rp::RedPitaya, mode::String)

Set the trigger mode of the RedPitaya. Return `true` if the command was successful.
"""
function triggerMode!(rp::RedPitaya, mode::TriggerMode)
  return query(rp, scpiCommand(triggerMode!, mode), scpiReturn(triggerMode!))
end
scpiCommand(::typeof(triggerMode!), mode) = string("RP:TRIGger:MODe ", string(mode))
scpiReturn(::typeof(triggerMode!)) = Bool

function triggerMode(rp::RedPitaya)
  return stringToEnum(TriggerMode, strip(query(rp, "RP:TRIGger:MODe?"), '\"'))
end
scpiCommand(::typeof(triggerMode)) = "RP:TRIGger:MODe?"
scpiReturn(::typeof(triggerMode)) = TriggerMode
parseReturn(::typeof(triggerMode), ret) = stringToEnum(TriggerMode, strip(ret, '\"'))

overwritten(rp::RedPitaya) = query(rp, "RP:STATus:OVERwritten?", Bool)
#scpiCommand(::typeof()) = 
#scpiReturn(::typeof()) = 
corrupted(rp::RedPitaya) = query(rp, "RP:STATus:CORRupted?", Bool)
#scpiCommand(::typeof()) = 
#scpiReturn(::typeof()) = 

function serverStatus(rp::RedPitaya) 
  send(rp, "RP:STATus?")
  return readServerStatus(rp)
end

function readServerStatus(rp::RedPitaya)
  statusRaw = read!(rp.dataSocket, Array{Int8}(undef, 1))[1]
  status = RPStatus(
   (statusRaw >> 0) & 1, # overwritten
   (statusRaw >> 1) & 1, # corrupted
   (statusRaw >> 2) & 1, # stepsLost
   (statusRaw >> 3) & 1, # adcEnabled
   (statusRaw >> 4) & 1) # dacEnabled
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

"""
    startPipelinedData(rp::RedPitaya, reqWP, numSamples, chunkSize)

Instruct the `RedPitaya` to send `numSamples` samples from writepointer `reqWP` in chunks of `chunkSize`.
"""
function startPipelinedData(rp::RedPitaya, reqWP::Int64, numSamples::Int64, chunkSize::Int64)
  command = string("RP:ADC:DATA:PIPELINED? ", reqWP, ",", numSamples, ",", chunkSize)
  send(rp, command)
end