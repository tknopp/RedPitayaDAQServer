export TriggerMode,
  INTERNAL,
  EXTERNAL,
  ADCPerformanceData,
  RPStatus,
  PerformanceData,
  RPPerformance,
  RPInfo,
  decimation,
  decimation!,
  numChan,
  samplesPerPeriod,
  samplesPerPeriod!,
  periodsPerFrame,
  periodsPerFrame!,
  currentWP,
  currentPeriod,
  currentFrame,
  masterTrigger,
  masterTrigger!,
  keepAliveReset,
  keepAliveReset!,
  triggerMode,
  triggerMode!,
  overwritten,
  corrupted,
  serverStatus,
  performanceData,
  readSamples,
  startPipelinedData,
  stopTransmission,
  triggerPropagation,
  triggerPropagation!

"""
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

function RPStatus(statusRaw::Integer)
  return RPStatus(
    (statusRaw >> 0) & 1,
    (statusRaw >> 1) & 1,
    (statusRaw >> 2) & 1,
    (statusRaw >> 3) & 1,
    (statusRaw >> 4) & 1,
  )
end

"""
Holds the performance data that is used for monitoring.
"""
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

RPInfo() = RPInfo([RPPerformance([])])

function dataRate(chunkSize, deltaSend, decimation; unit = "Mbits")
  bitsPerSample = (chunkSize * 4 * 8) / deltaSend # 4 bytes per samples
  freq = div(125e6, decimation)
  bitsPerSec = bitsPerSample * freq
  return bitsPerSec / 1e6 #TODO unit conversion
end

function dataRate(adc::ADCPerformanceData, decimation; unit = "Mbits")
  return dataRate(adc.chunkSize, adc.deltaSend, decimation)
end

"""
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
Return the number of ADC channel of a RedPitaya.
"""
numChan(rp::RedPitaya) = 2

"""
Return the number of samples per period.

# Example

```julia
julia> samplesPerPeriod!(rp, 256)
true

julia> samplesPerPeriod(rp)
256
```
"""
samplesPerPeriod(rp::RedPitaya) = rp.samplesPerPeriod
"""
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
Return the number of periods per frame.

# Example

```julia
julia> periodsPerFrame!(rp, 16)

julia> periodsPerFrame(rp)
16
```
"""
periodsPerFrame(rp::RedPitaya) = rp.periodsPerFrame
"""
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
Return the current frame of the RedPitaya based on the current writepointer, samples per period and periods per frame.

See also [`currentWP`](@ref), [`samplesPerPeriod`](@ref), [`periodsPerFrame`](@ref).
"""
currentFrame(rp::RedPitaya) = Int64(floor(currentWP(rp) / (rp.samplesPerPeriod * rp.periodsPerFrame)))

"""
Return the current period of the RedPitaya based on the current writepointer and samples per period.

See also [`currentWP`](@ref), [`samplesPerPeriod`](@ref).
"""
currentPeriod(rp::RedPitaya) = Int64(floor(currentWP(rp) / (rp.samplesPerPeriod)))

"""
Return the current writepointer of the RedPitaya.
"""
currentWP(rp::RedPitaya) = query(rp, scpiCommand(currentWP), scpiReturn(currentWP))
scpiCommand(::typeof(currentWP)) = "RP:ADC:WP?"
scpiReturn(::typeof(currentWP)) = Int64

bufferSize(rp::RedPitaya) = query(rp, scpiCommand(bufferSize), scpiReturn(bufferSize))
scpiCommand(::typeof(bufferSize)) = "RP:ADC:BUFFER:SIZE?"
scpiReturn(::typeof(bufferSize)) = Int64

"""
Set the master trigger of the RedPitaya to `val`. Return `true` if the command was successful.

# Example

```julia
julia> masterTrigger!(rp, true)
true

julia>masterTrigger(rp)
true
```
"""
masterTrigger!(rp::RedPitaya, val) = query(rp, scpiCommand(masterTrigger!, val), scpiReturn(masterTrigger!))
scpiCommand(::typeof(masterTrigger!), val::Bool) = scpiCommand(masterTrigger!, val ? "ON" : "OFF")
scpiCommand(::typeof(masterTrigger!), val::String) = string("RP:TRIGger ", val)
scpiReturn(::typeof(masterTrigger!)) = Bool
"""
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
Set the keepAliveReset to `val`.
"""
function keepAliveReset!(rp::RedPitaya, val::Bool)
  return query(rp, scpiCommand(keepAliveReset!, val), scpiReturn(keepAliveReset!))
end
scpiCommand(::typeof(keepAliveReset!), val::Bool) = scpiCommand(keepAliveReset!, val ? "ON" : "OFF")
scpiCommand(::typeof(keepAliveReset!), val::String) = string("RP:TRIGger:ALiVe ", val)
scpiReturn(::typeof(keepAliveReset!)) = Bool
"""
Determine whether the keepAliveReset is set.
"""
keepAliveReset(rp::RedPitaya) = occursin("ON", query(rp, scpiCommand(keepAliveReset)))
scpiCommand(::typeof(keepAliveReset)) = "RP:TRIGger?"
scpiReturn(::typeof(keepAliveReset)) = String
parseReturn(::typeof(keepAliveReset), ret) = occursin("ON", ret)

# "INTERNAL" or "EXTERNAL"
"""
Set the trigger mode of the RedPitaya. Return `true` if the command was successful.
"""
triggerMode!(rp::RedPitaya, mode::String) = triggerMode!(rp, stringToEnum(TriggerMode, mode))
"""
Set the trigger mode of the RedPitaya. Return `true` if the command was successful.
"""
function triggerMode!(rp::RedPitaya, mode::TriggerMode)
  return query(rp, scpiCommand(triggerMode!, mode), scpiReturn(triggerMode!))
end
scpiCommand(::typeof(triggerMode!), mode) = string("RP:TRIGger:MODe ", string(mode))
scpiReturn(::typeof(triggerMode!)) = Bool

triggerMode(rp::RedPitaya) = stringToEnum(TriggerMode, strip(query(rp, "RP:TRIGger:MODe?"), '\"'))
scpiCommand(::typeof(triggerMode)) = "RP:TRIGger:MODe?"
scpiReturn(::typeof(triggerMode)) = TriggerMode
parseReturn(::typeof(triggerMode), ret) = stringToEnum(TriggerMode, strip(ret, '\"'))

"""
Set the trigger propagation of the RedPitaya to `val`. Return `true` if the command was successful.

# Example

```julia
julia> triggerPropagation!(rp, true)
true

julia>triggerPropagation(rp)
true
```
"""
function triggerPropagation!(rp::RedPitaya, val)
  return query(rp, scpiCommand(triggerPropagation!, val), scpiReturn(triggerPropagation!))
end
scpiCommand(::typeof(triggerPropagation!), val::Bool) = scpiCommand(triggerPropagation!, val ? "ON" : "OFF")
scpiCommand(::typeof(triggerPropagation!), val::String) = string("RP:TRIGger:PROP ", val)
scpiReturn(::typeof(triggerPropagation!)) = Bool
"""
Determine whether the trigger propagation is set.

# Example

```julia
julia> triggerPropagation!(rp, true)

julia>triggerPropagation(rp)
true
```
"""
triggerPropagation(rp::RedPitaya) = occursin("ON", query(rp, scpiCommand(triggerPropagation)))
scpiCommand(::typeof(triggerPropagation)) = "RP:TRIGger:PROP?"
scpiReturn(::typeof(triggerPropagation)) = String
parseReturn(::typeof(triggerPropagation), ret) = occursin("ON", ret)

overwritten(rp::RedPitaya) = query(rp, scpiCommand(overwritten), scpiReturn(overwritten))
scpiCommand(::typeof(overwritten)) = "RP:STATus:OVERwritten?"
scpiReturn(::typeof(overwritten)) = Bool
corrupted(rp::RedPitaya) = query(rp, scpiCommand(corrupted), scpiReturn(corrupted))
scpiCommand(::typeof(corrupted)) = "RP:STATus:CORRupted?"
scpiReturn(::typeof(corrupted)) = Bool

serverStatus(rp::RedPitaya) = query(rp, scpiCommand(serverStatus), scpiReturn(serverStatus))
scpiCommand(::typeof(serverStatus)) = "RP:STATus?"
scpiReturn(::typeof(serverStatus)) = RPStatus
parseReturn(::typeof(serverStatus), ret) = RPStatus(parse(Int64, ret))

function readServerStatus(rp::RedPitaya)
  statusRaw = read!(rp.dataSocket, Array{Int8}(undef, 1))[1]
  return RPStatus(statusRaw)
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

function readChunkMetaData(rp::RedPitaya, reqWP, numSamples)
  status = readServerStatus(rp)
  (adc, dac) = readPerformanceData(rp, numSamples)
  return PerformanceData(UInt64(reqWP), adc, dac, status)
end

readSamples!(rp::RedPitaya, data::AbstractArray{Int16}) = read!(rp.dataSocket, data)

# Low level read, reads samples, error and perf. Values need to be already requested
function readSamplesChunk_(rp::RedPitaya, reqWP::Int64, numSamples::Int64)
  buffer = Array{Int16}(undef, 2 * numSamples)
  readSamples!(rp, buffer)
  meta = readChunkMetaData(rp, reqWP, numSamples)
  return (buffer, meta)
end

function readSamplesChunk_(rp::RedPitaya, reqWP::Int64, buffer::AbstractArray{Int16})
  numSamples = div(length(buffer), 2)
  readSamples!(rp, buffer)
  meta = readChunkMetaData(rp, reqWP, numSamples)
  return (buffer, meta)
end

"""
Instruct the `RedPitaya` to send `numSamples` samples from writepointer `reqWP` in chunks of `chunkSize`.
"""
function startPipelinedData(rp::RedPitaya, reqWP::Int64, numSamples::Int64, chunkSize::Int64)
  command = string("RP:ADC:DATA:PIPELINED? ", reqWP, ",", numSamples, ",", chunkSize)
  sending = query(rp, command, Bool)

  if !sending
    error("RedPitaya $(rp.host) can not start sample pipeline.")
  end
end

stopTransmission(rp::RedPitaya) = query(rp, scpiCommand(stopTransmission), scpiReturn(stopTransmission))
scpiCommand(::typeof(stopTransmission)) = "RP:ADC:DATa:SToP?"
scpiReturn(::typeof(stopTransmission)) = Bool
