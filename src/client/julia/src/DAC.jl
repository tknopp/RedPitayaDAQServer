export SignalType,
  SINE,
  TRIANGLE,
  SAWTOOTH,
  DACPerformanceData,
  DACConfig,
  ArbitraryWaveform,
  waveformDAC!,
  scaleWaveformDAC!,
  amplitudeDAC,
  amplitudeDAC!,
  offsetDAC,
  offsetDAC!,
  normalize,
  frequencyDAC,
  frequencyDAC!,
  phaseDAC,
  phaseDAC!,
  signalTypeDAC,
  signalTypeDAC!,
  rampingDAC!,
  rampingDAC,
  enableRamping!,
  enableRamping,
  enableRampDown,
  enableRampDown!,
  RampingState,
  RampingStatus,
  rampingStatus,
  rampDownDone,
  rampUpDone

"""
Represent the different types of signals the fast DAC can have. Valid values are `SINE`, `TRIANGLE` and `SAWTOOTH`.

See [`signalTypeDAC`](@ref), [`signalTypeDAC!`](@ref).
"""
@enum SignalType SINE TRIANGLE SAWTOOTH

mutable struct ArbitraryWaveform <: AbstractArray{Float32, 1}
  samples::Vector{Float32}
  function ArbitraryWaveform(samples::Vector{Float32})
    return if length(samples) != _awgBufferSize
      error("Unexpected waveform length $(length(samples)), expected $_awgBufferSize")
    else
      new(samples)
    end
  end
end
Base.size(wave::ArbitraryWaveform) = size(wave.samples)
Base.IndexStyle(::Type{<:ArbitraryWaveform}) = IndexLinear()
Base.getindex(wave::ArbitraryWaveform, i::Int) = wave.samples[i]
Base.setindex!(wave::ArbitraryWaveform, v, i::Int) = wave.samples[i] = v
function ArbitraryWaveform(samples::Vector{T}) where {T <: AbstractFloat}
  return ArbitraryWaveform(convert(Vector{Float32}, samples))
end
function ArbitraryWaveform(f::Function, min = 0, max = _awgBufferSize)
  return ArbitraryWaveform([f(x) for x ∈ range(min, max; length = _awgBufferSize)])
end

function waveform!_(rp::RedPitaya, channel::Integer, wave::ArbitraryWaveform)
  send(rp, "RP:DAC:CH$(channel-1):AWG")
  write(rp.dataSocket, wave[1:end])
  return parse(Bool, receive(rp))
end

function waveformDAC!(rp::RedPitaya, channel::Integer, wave::ArbitraryWaveform)
  reply = waveform!_(rp, channel, wave)
  if reply
    rp.awgs[:, channel] = wave[1:end]
  end
  return reply
end
function scaleWaveformDAC!(rp::RedPitaya, channel::Integer, scale::Float64)
  return waveform!_(rp, channel, ArbitraryWaveform(scale .* rp.awgs[:, channel]))
end
function waveformDAC!(rp::RedPitaya, channel::Integer, samples::Vector{T}) where {T <: AbstractFloat}
  return waveformDAC!(rp, channel, ArbitraryWaveform(samples))
end
function waveformDAC!(rp::RedPitaya, channel::Integer, wave::Nothing)
  return waveformDAC!(rp, channel, ArbitraryWaveform(x -> Float32(0.0)))
end
function waveformDAC!(rp::RedPitaya, channel::Integer, signal::SignalType)
  wave = nothing
  if signal == SINE
    wave = ArbitraryWaveform(x -> sin(x), 0, 2 * pi)
  elseif TRIANGLE
    wave = ArbitraryWaveform(x -> 2 * abs(x / _awgBufferSize - floor(x / _awgBufferSize + 1 / 2)))
  elseif SAWTOOTH
    wave = ArbitraryWaveform(x -> 2 * (x / _awgBufferSize - 1 / 2))
  else
    error("Signal type $(string(signal)) not implemented yet")
  end
  return waveformDAC!(rp, channel, wave)
end
normalize(wave::ArbitraryWaveform) = ArbitraryWaveform(wave / maximum(abs.(wave)))

struct DACPerformanceData
  uDeltaControl::UInt8
  uDeltaSet::UInt8
  minDeltaControl::UInt8
  maxDeltaSet::UInt8
end

function readDACPerformanceData(rp::RedPitaya)
  perf = read!(rp.dataSocket, Array{UInt8}(undef, 4))
  return DACPerformanceData(perf[1], perf[2], perf[3], perf[4])
end

@enum RampingState NORMAL DONE UP DOWN
struct RampingStatus
  enableCh1::Union{Bool, Nothing}
  enableCh2::Union{Bool, Nothing}
  stateCh1::Union{RampingState, Nothing}
  stateCh2::Union{RampingState, Nothing}
end

struct DACConfig
  amplitudes::Array{Union{Float64, Nothing}}
  offsets::Array{Union{Float64, Nothing}}
  frequencies::Array{Union{Float64, Nothing}}
  phases::Array{Union{Float64, Nothing}}
  signalTypes::Array{Union{String, Nothing}}
  jumpSharpness::Array{Union{Float64, Nothing}}
  function DACConfig()
    return new(
      Array{Union{Float64, Nothing}}(nothing, 2, 4),
      Array{Union{Float64, Nothing}}(nothing, 2),
      Array{Union{Float64, Nothing}}(nothing, 2, 4),
      Array{Union{Float64, Nothing}}(nothing, 2, 4),
      Array{Union{String, Nothing}}(nothing, 2),
      Array{Union{Float64, Nothing}}(nothing, 2),
    )
  end
end

"""
Return the amplitude of composite waveform `component` for `channel`.

See [`amplitudeDAC!`](@ref).

# Examples

```julia
julia> amplitudeDAC!(rp, 1, 1, 0.5);
true

julia> amplitudeDAC(rp, 1, 1)
0.5
```
"""
function amplitudeDAC(rp::RedPitaya, channel, component)
  command = scpiCommand(amplitudeDAC, channel, component)
  return query(rp, command, Float64)
end
function scpiCommand(::typeof(amplitudeDAC), channel, component)
  return string("RP:DAC:CH", Int(channel) - 1, ":COMP", Int(component) - 1, ":AMP?")
end
scpiReturn(::typeof(amplitudeDAC)) = Float64

"""
Set the amplitude of composite waveform `component` for `channel`. Return `true` if the command was successful.

See [`amplitudeDAC`](@ref).

# Examples

```julia
julia> amplitudeDAC!(rp, 1, 1, 0.5);
true

julia> amplitudeDAC(rp, 1, 1)
0.5
```
"""
function amplitudeDAC!(rp::RedPitaya, channel, component, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = scpiCommand(amplitudeDAC!, channel, component, value)
  return query(rp, command, Bool)
end
function scpiCommand(::typeof(amplitudeDAC!), channel, component, value)
  return string("RP:DAC:CH", Int(channel) - 1, ":COMP", Int(component) - 1, ":AMP ", Float64(value))
end
scpiReturn(::typeof(amplitudeDAC!)) = Bool

"""
Return the offset for `channel`.

See [`offsetDAC!`](@ref).

# Examples

```julia
julia> offsetDAC!(rp, 1, 0.2);
true

julia> offsetDAC(rp, 1)
0.2
```
"""
function offsetDAC(rp::RedPitaya, channel)
  command = scpiCommand(offsetDAC, channel)
  return query(rp, command, Float64)
end
scpiCommand(::typeof(offsetDAC), channel) = string("RP:DAC:CH", Int(channel) - 1, ":OFF?")
scpiReturn(::typeof(offsetDAC)) = Float64
"""
Set the offset for `channel`. Return `true` if the command was successful.

See [`offsetDAC`](@ref).

# Examples

```julia
julia> offsetDAC!(rp, 1, 0.2);
true

julia> offsetDAC(rp, 1)
0.2
```
"""
function offsetDAC!(rp::RedPitaya, channel, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = scpiCommand(offsetDAC!, channel, value)
  return query(rp, command, Bool)
end
function scpiCommand(::typeof(offsetDAC!), channel, value)
  return string("RP:DAC:CH", Int(channel) - 1, ":OFF ", Float64(value))
end
scpiReturn(::typeof(offsetDAC!)) = Bool
function offsetDACSeq!(rp::RedPitaya, channel, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = scpiCommand(offsetDACSeq!, channel, value)
  return query(rp, command, Bool)
end
function scpiCommand(::typeof(offsetDACSeq!), channel, value)
  return string("RP:DAC:SEQ:CH", Int(channel) - 1, ":OFF ", Float64(value))
end
scpiReturn(::typeof(offsetDACSeq!)) = Bool
function offsetDACSeq!(config::DACConfig, channel, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  return config.offsets[channel] = value
end

"""
Return the frequency of composite waveform `component` for `channel`.

See [`frequencyDAC!`](@ref).

# Examples

```julia
julia> frequencyDAC!(rp, 1, 1, 2400);
true

julia> frequencyDAC(rp, 1, 1)
2400
```
"""
function frequencyDAC(rp::RedPitaya, channel, component)
  command = scpiCommand(frequencyDAC, channel, component)
  return query(rp, command, Float64)
end
function scpiCommand(::typeof(frequencyDAC), channel, component)
  return string("RP:DAC:CH", Int(channel) - 1, ":COMP", Int(component) - 1, ":FREQ?")
end
scpiReturn(::typeof(frequencyDAC)) = Float64
"""
Set the frequency of composite waveform `component` for `channel`. Return `true` if the command was successful.

See [`frequencyDAC`](@ref).

# Examples

```julia
julia> frequencyDAC!(rp, 1, 1, 2400);
true

julia> frequencyDAC(rp, 1, 1)
2400
```
"""
function frequencyDAC!(rp::RedPitaya, channel, component, value)
  command = scpiCommand(frequencyDAC!, channel, component, value)
  return query(rp, command, Bool)
end
function scpiCommand(::typeof(frequencyDAC!), channel, component, value)
  return string("RP:DAC:CH", Int(channel) - 1, ":COMP", Int(component) - 1, ":FREQ ", Float64(value))
end
scpiReturn(::typeof(frequencyDAC!)) = Bool

function frequencyDACSeq!(rp::RedPitaya, channel, component, value)
  command = scpiCommand(frequencyDACSeq!, channel, component, value)
  return query(rp, command, Bool)
end
function scpiCommand(::typeof(frequencyDACSeq!), channel, component, value)
  return string("RP:DAC:SEQ:CH", Int(channel) - 1, ":COMP", Int(component) - 1, ":FREQ ", Float64(value))
end
scpiReturn(::typeof(frequencyDACSeq!)) = Bool
function frequencyDACSeq!(config::DACConfig, channel, component, value)
  return config.frequencies[channel, component] = value
end

"""
Return the phase of composite waveform `component` for `channel`.

See [`phaseDAC!`](@ref).

# Examples

```julia
julia> phaseDAC!(rp, 1, 1, 0.0);
true

julia> phaseDAC(rp, 1, 0.0)
0.0
```
"""
function phaseDAC(rp::RedPitaya, channel, component)
  command = scpiCommand(phaseDAC, channel, component)
  return query(rp, command, scpiReturn(phaseDAC))
end
function scpiCommand(::typeof(phaseDAC), channel, component)
  return string("RP:DAC:CH", Int(channel) - 1, ":COMP", Int(component) - 1, ":PHA?")
end
scpiReturn(::typeof(phaseDAC)) = Float64
"""
Set the phase of composite waveform `component` for `channel`. Return `true` if the command was successful.

See [`phaseDAC`](@ref).

# Examples

```julia
julia> phaseDAC!(rp, 1, 1, 0.0);
true

julia> phaseDAC(rp, 1, 0.0)
0.0
```
"""
function phaseDAC!(rp::RedPitaya, channel, component, value)
  command = scpiCommand(phaseDAC!, channel, component, value)
  return query(rp, command, Bool)
end
function scpiCommand(::typeof(phaseDAC!), channel, component, value)
  return string("RP:DAC:CH", Int(channel) - 1, ":COMP", Int(component) - 1, ":PHA ", Float64(value))
end
scpiReturn(::typeof(phaseDAC!)) = Bool

function phaseDACSeq!(rp::RedPitaya, channel, component, value)
  command = scpiCommand(phaseDACSeq!, channel, component, value)
  return query(rp, command, Bool)
end
function scpiCommand(::typeof(phaseDACSeq!), channel, component, value)
  return string("RP:DAC:SEQ:CH", Int(channel) - 1, ":COMP", Int(component) - 1, ":PHA ", Float64(value))
end
scpiReturn(::typeof(phaseDACSeq!)) = Bool
phaseDACSeq!(config::DACConfig, channel, component, value) = config.phases[channel, component] = value

"""
Return the signalType of composite waveform for `channel`.

See [`signalTypeDAC!`](@ref).

# Examples

```julia
julia> signalTypeDAC!(rp, 1, SINE);
true

julia> signalTypeDAC(rp, 1)
SINE
```
"""
function signalTypeDAC(rp::RedPitaya, channel, component)
  command = scpiCommand(signalTypeDAC, channel, component)
  return stringToEnum(SignalType, strip(query(rp, command), '\"'))
end
function scpiCommand(::typeof(signalTypeDAC), channel, component)
  return string("RP:DAC:CH", Int(channel) - 1, ":COMP", Int(component) - 1, ":SIGnaltype?")
end
scpiReturn(::typeof(signalTypeDAC)) = SignalType
parseReturn(::typeof(signalTypeDAC), ret) = stringToEnum(SignalType, strip(ret, '\"'))

function signalTypeDAC!(rp::RedPitaya, channel, component, sigType::String)
  return signalTypeDAC!(rp, channel, component, stringToEnum(SignalType, sigType))
end
"""
Set the signalType of composite waveform for `channel`. Return `true` if the command was successful.

See [`signalTypeDAC`](@ref).

# Examples

```julia
julia> signalTypeDAC!(rp, 1, SINE);
true

julia> signalTypeDAC(rp, 1)
SINE
```
"""
function signalTypeDAC!(rp::RedPitaya, channel, component, sigType::SignalType)
  return query(rp, scpiCommand(signalTypeDAC!, channel, component, sigType), scpiReturn(signalTypeDAC!))
end
function scpiCommand(::typeof(signalTypeDAC!), channel, component, sigType)
  return string("RP:DAC:CH", Int(channel) - 1, ":COMP", Int(component) - 1, ":SIGnaltype ", string(sigType))
end
scpiReturn(::typeof(signalTypeDAC!)) = Bool

function rampingDAC!(rp::RedPitaya, channel, value)
  command = scpiCommand(rampingDAC!, channel, value)
  return query(rp, command, scpiReturn(rampingDAC!))
end
function scpiCommand(::typeof(rampingDAC!), channel, value)
  return string("RP:DAC:CH", Int(channel) - 1, ":RAMP ", Float64(value))
end
scpiReturn(::typeof(rampingDAC!)) = Bool

function rampingDAC(rp::RedPitaya, channel)
  command = scpiCommand(rampingDAC, channel)
  return query(rp, command, scpiReturn(rampingDAC))
end
scpiCommand(::typeof(rampingDAC), channel) = string("RP:DAC:CH", Int(channel) - 1, ":RAMP?")
scpiReturn(::typeof(rampingDAC)) = Float64

function enableRamping!(rp::RedPitaya, channel, value)
  return query(rp, scpiCommand(enableRamping!, channel, value), scpiReturn(enableRamping!))
end
function scpiCommand(::typeof(enableRamping!), channel, val::Bool)
  return scpiCommand(enableRamping!, channel, val ? "ON" : "OFF")
end
function scpiCommand(::typeof(enableRamping!), channel, val::String)
  return string("RP:DAC:CH", Int(channel) - 1, ":RAMPing:ENaBle ", val)
end
scpiReturn(::typeof(enableRamping!)) = Bool

enableRamping(rp::RedPitaya, channel) = occursin("ON", query(rp, scpiCommand(enableRamping, channel)))
scpiCommand(::typeof(enableRamping), channel) = string("RP:DAC:CH", Int(channel) - 1, ":RAMPing:ENaBle?")
scpiReturn(::typeof(enableRamping)) = String
parseReturn(::typeof(enableRamping), ret) = occursin("ON", ret)

function enableRampDown!(rp::RedPitaya, channel, value)
  return query(rp, scpiCommand(enableRampDown!, channel, value), scpiReturn(enableRampDown!))
end
function scpiCommand(::typeof(enableRampDown!), channel, val::Bool)
  return scpiCommand(enableRampDown!, channel, val ? "ON" : "OFF")
end
function scpiCommand(::typeof(enableRampDown!), channel, val::String)
  return string("RP:DAC:CH", Int(channel) - 1, ":RAMPing:DoWN ", val)
end
scpiReturn(::typeof(enableRampDown!)) = Bool

enableRampDown(rp::RedPitaya, channel) = occursin("ON", query(rp, scpiCommand(enableRampDown, channel)))
scpiCommand(::typeof(enableRampDown), channel) = string("RP:DAC:CH", Int(channel) - 1, ":RAMPing:DoWN?")
scpiReturn(::typeof(enableRampDown)) = String
parseReturn(::typeof(enableRampDown), ret) = occursin("ON", ret)

function rampingStatus(rp::RedPitaya)
  status = query(rp, scpiCommand(rampingStatus), scpiReturn(rampingStatus))
  result = RampingStatus(
    status & 1,
    (status >> 4) & 1,
    RampingState((status >> 1) & 0x7),
    RampingState((status >> 5) & 0x7),
  )
  return result
end
scpiCommand(::typeof(rampingStatus)) = "RP:DAC:RAMPing:STATus?"
scpiReturn(::typeof(rampingStatus)) = UInt8
function parseReturn(::typeof(rampingStatus), ret)
  status = parse(UInt8, ret)
  result = RampingStatus(
    status & 1,
    (status >> 4) & 1,
    RampingState((status >> 1) & 0x7),
    RampingState((status >> 5) & 0x7),
  )
  return result
end

function rampDownDone(rp::RedPitaya)
  done = false
  status = rampingStatus(rp)
  return done =
    (!status.enableCh1 || status.stateCh1 == DONE) && (!status.enableCh2 || status.stateCh2 == DONE)
end

function rampUpDone(rp::RedPitaya)
  done = false
  status = rampingStatus(rp)
  return done = (!status.enableCh1 || status.stateCh1 != UP) && (!status.enableCh2 || status.stateCh2 != UP)
end
