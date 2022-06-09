export SignalType, SINE, SQUARE, TRIANGLE, SAWTOOTH, DACPerformanceData, DACConfig, passPDMToFastDAC, passPDMToFastDAC!,
amplitudeDAC, amplitudeDAC!,offsetDAC, offsetDAC!,
frequencyDAC, frequencyDAC!, phaseDAC, phaseDAC!,
jumpSharpnessDAC, jumpSharpnessDAC!, signalTypeDAC, signalTypeDAC!, numSeqChan, numSeqChan!, samplesPerStep, samplesPerStep!,
prepareSteps!, stepsPerFrame!, 
rampingDAC!, rampingDAC, enableRamping!, enableRamping, enableRampDown, enableRampDown!, RampingState, RampingStatus, rampingStatus, rampDownDone, rampUpDone

"""
    SignalType

Represent the different types of signals the fast DAC can have. Valid values are `SINE`, `SQUARE`, `TRIANGLE` and `SAWTOOTH`.

See [`signalTypeDAC`](@ref), [`signalTypeDAC!`](@ref).
"""
@enum SignalType SINE SQUARE TRIANGLE SAWTOOTH
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
    new(Array{Union{Float64, Nothing}}(nothing, 2,4), Array{Union{Float64, Nothing}}(nothing, 2), 
    Array{Union{Float64, Nothing}}(nothing, 2,4), Array{Union{Float64, Nothing}}(nothing, 2,4), 
    Array{Union{String, Nothing}}(nothing, 2), Array{Union{Float64, Nothing}}(nothing, 2))
  end
end

function passPDMToFastDAC!(rp::RedPitaya, val::Bool)
  valStr = val ? "ON" : "OFF"
  return query(rp, string("RP:DAC:PASStofast ", valStr), Bool)
end
scpiCommand(::typeof(passPDMToFastDAC!), val::Bool) = scpiCommand(passPDMToFastDAC!, val ? "ON" : "OFF")
scpiCommand(::typeof(passPDMToFastDAC!), val::String) = string("RP:DAC:PASStofast ", val)
scpiReturn(::typeof(passPDMToFastDAC!)) = Bool

passPDMToFastDAC(rp::RedPitaya) = occursin("ON", query(rp, scpiCommand(passPDMToFastDAC)))
scpiCommand(::typeof(passPDMToFastDAC)) = "RP:DAC:PASStofast?"
scpiReturn(::typeof(passPDMToFastDAC)) = String
parseReturn(::typeof(passPDMToFastDAC), ret) = occursin("ON", ret)

"""
    amplitudeDAC(rp::RedPitaya, channel, component)

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
scpiCommand(::typeof(amplitudeDAC), channel, component) = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":AMP?")
scpiReturn(::typeof(amplitudeDAC)) = Float64

"""
    amplitudeDAC!(rp::RedPitaya, channel, component, value)

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
scpiCommand(::typeof(amplitudeDAC!), channel, component, value) = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":AMP ", Float64(value))
scpiReturn(::typeof(amplitudeDAC!)) = Bool
function amplitudeDACSeq!(rp::RedPitaya, channel, component, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = scpiCommand(amplitudeDACSeq!, channel, component, value)
  return query(rp, command, Bool)
end
scpiCommand(::typeof(amplitudeDACSeq!), channel, component, value) = string("RP:DAC:SEQ:CH", Int(channel)-1, ":COMP", Int(component)-1, ":AMP ", Float64(value))
scpiReturn(::typeof(amplitudeDACSeq!)) = Bool
function amplitudeDACSeq!(config::DACConfig, channel, component, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  config.amplitudes[channel, component] = value
end

"""
    offsetDAC(rp::RedPitaya, channel)

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
scpiCommand(::typeof(offsetDAC), channel) = string("RP:DAC:CH", Int(channel)-1, ":OFF?")
scpiReturn(::typeof(offsetDAC)) = Float64
"""
    offsetDAC!(rp::RedPitaya, channel, value)

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
scpiCommand(::typeof(offsetDAC!), channel, value) = string("RP:DAC:CH", Int(channel)-1, ":OFF ", Float64(value))
scpiReturn(::typeof(offsetDAC!)) = Bool
function offsetDACSeq!(rp::RedPitaya, channel, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = scpiCommand(offsetDACSeq!, channel, value)
  return query(rp, command, Bool)
end
scpiCommand(::typeof(offsetDACSeq!), channel, value) = string("RP:DAC:SEQ:CH", Int(channel)-1, ":OFF ", Float64(value))
scpiReturn(::typeof(offsetDACSeq!)) = Bool
function offsetDACSeq!(config::DACConfig, channel, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  config.offsets[channel] = value
end

"""
    frequencyDAC(rp::RedPitaya, channel, component)

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
scpiCommand(::typeof(frequencyDAC), channel, component) = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":FREQ?")
scpiReturn(::typeof(frequencyDAC)) = Float64
"""
    frequencyDAC!(rp::RedPitaya, channel, component, value)

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
scpiCommand(::typeof(frequencyDAC!), channel, component, value) = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":FREQ ", Float64(value))
scpiReturn(::typeof(frequencyDAC!)) = Bool

function frequencyDACSeq!(rp::RedPitaya, channel, component, value)
  command = scpiCommand(frequencyDACSeq!, channel, component, value)
  return query(rp, command, Bool)
end
scpiCommand(::typeof(frequencyDACSeq!), channel, component, value) = string("RP:DAC:SEQ:CH", Int(channel)-1, ":COMP", Int(component)-1, ":FREQ ", Float64(value))
scpiReturn(::typeof(frequencyDACSeq!)) = Bool
function frequencyDACSeq!(config::DACConfig, channel, component, value)
  config.frequencies[channel, component] = value
end

"""
    phaseDAC(rp::RedPitaya, channel, component)

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
scpiCommand(::typeof(phaseDAC), channel, component) = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":PHA?")
scpiReturn(::typeof(phaseDAC)) = Float64
"""
    phaseDAC!(rp::RedPitaya, channel, component, value)

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
scpiCommand(::typeof(phaseDAC!), channel, component, value) = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":PHA ", Float64(value))
scpiReturn(::typeof(phaseDAC!)) = Bool 

function phaseDACSeq!(rp::RedPitaya, channel, component, value)
  command = scpiCommand(phaseDACSeq!, channel, component, value)
  return query(rp, command, Bool)
end
scpiCommand(::typeof(phaseDACSeq!), channel, component, value) = string("RP:DAC:SEQ:CH", Int(channel)-1, ":COMP", Int(component)-1, ":PHA ", Float64(value))
scpiReturn(::typeof(phaseDACSeq!)) = Bool
function phaseDACSeq!(config::DACConfig, channel, component, value)
  config.phases[channel, component] = value
end

"""
    jumpSharpnessDAC(rp::RedPitaya, channel, value)

Return the jumpSharpness of composite waveform for `channel`.

See [`jumpSharpnessDAC!`](@ref).

# Examples
```julia
julia> jumpSharpnessDAC!(rp, 1, 0.01);
true

julia> jumpSharpnessDAC(rp, 1)
0.01
```
"""
function jumpSharpnessDAC(rp::RedPitaya, channel, component)
  return query(rp, scpiCommand(jumpSharpnessDAC, channel, component), scpiReturn(jumpSharpnessDAC))
end
scpiCommand(::typeof(jumpSharpnessDAC), channel, component) = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1,":JUMPsharpness?")
scpiReturn(::typeof(jumpSharpnessDAC)) = Float64
"""
    jumpSharpnessDAC!(rp::RedPitaya, channel, value)

Set the jumpSharpness of composite waveform for `channel`. Return `true` if the command was successful.

See [`jumpSharpnessDAC`](@ref).

# Examples
```julia
julia> jumpSharpnessDAC!(rp, 1, 0.01);
true

julia> jumpSharpnessDAC(rp, 1)
0.01
```
"""
function jumpSharpnessDAC!(rp::RedPitaya, channel, component, value)
  return query(rp, scpiCommand(jumpSharpnessDAC!, channel, component, value), scpiReturn(jumpSharpnessDAC!))
end
scpiCommand(::typeof(jumpSharpnessDAC!), channel, component, value) = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":JUMPsharpness ", Float64(value))
scpiReturn(::typeof(jumpSharpnessDAC!)) = Bool

function jumpSharpnessDACSeq!(rp::RedPitaya, channel, value)
  return query(rp, scpiCommand(jumpSharpnessDACSeq!, channel, value), scpiReturn(jumpSharpnessDACSeq!))
end
scpiCommand(::typeof(jumpSharpnessDACSeq!), channel, value) = string("RP:DAC:SEQ:CH", Int(channel)-1, ":JUMPsharpness ", Float64(value))
scpiReturn(::typeof(jumpSharpnessDACSeq!)) = Float64
function jumpSharpnessDACSeq!(config::DACConfig, channel, value)
  config.jumpSharpness[channel] = value
end

"""
    signalTypeDAC!(rp::RedPitaya, channel, value)

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
scpiCommand(::typeof(signalTypeDAC), channel, component) = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":SIGnaltype?")
scpiReturn(::typeof(signalTypeDAC)) = SignalType
parseReturn(::typeof(signalTypeDAC), ret) = stringToEnum(SignalType, strip(ret, '\"'))


function signalTypeDAC!(rp::RedPitaya, channel, component, sigType::String)
  return signalTypeDAC!(rp, channel, component, stringToEnum(SignalType, sigType))
end
"""
    signalTypeDAC!(rp::RedPitaya, channel, value)

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
scpiCommand(::typeof(signalTypeDAC!), channel, component, sigType) = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":SIGnaltype ", string(sigType))
scpiReturn(::typeof(signalTypeDAC!)) = Bool

function signalTypeDACSeq!(rp::RedPitaya, channel, sigType::String)
  return signalTypeDACSeq!(rp, channel, stringToEnum(SignalType, sigType))
end
function signalTypeDACSeq!(rp::RedPitaya, channel, sigType::SignalType)
  return query(rp, scpiCommand(signalTypeDACSeq!, channel, sigType), scpiReturn(signalTypeDACSeq!))
end
scpiCommand(::typeof(signalTypeDACSeq!), channel, sigType) = string("RP:DAC:SEQ:CH", Int(channel)-1, ":SIGnaltype ", string(sigType))
scpiReturn(::typeof(signalTypeDACSeq!)) = Bool
function signalTypeDACSeq!(config::DACConfig, channel, sigType::String)
  config.signalTypes[channel] = sigType
end


function rampingDAC!(rp::RedPitaya, channel, value)
  command = scpiCommand(rampingDAC!, channel, value)
  return query(rp, command, scpiReturn(rampingDAC!))
end
scpiCommand(::typeof(rampingDAC!), channel, value) = string("RP:DAC:CH", Int(channel)-1, ":RAMP ", Float64(value))
scpiReturn(::typeof(rampingDAC!)) = Bool

function rampingDAC(rp::RedPitaya, channel)
  command = scpiCommand(rampingDAC, channel)
  return query(rp, command, scpiReturn(rampingDAC))
end
scpiCommand(::typeof(rampingDAC), channel) = string("RP:DAC:CH", Int(channel)-1, ":RAMP?")
scpiReturn(::typeof(rampingDAC)) = Float64

function enableRamping!(rp::RedPitaya, channel, value)
  return query(rp, scpiCommand(enableRamping!, channel, value), scpiReturn(enableRamping!))
end
scpiCommand(::typeof(enableRamping!), channel, val::Bool) = scpiCommand(enableRamping!, channel, val ? "ON" : "OFF")
scpiCommand(::typeof(enableRamping!), channel, val::String) = string("RP:DAC:CH", Int(channel)-1, ":RAMPing:ENaBle ", val)
scpiReturn(::typeof(enableRamping!)) = Bool

enableRamping(rp::RedPitaya, channel) = occursin("ON", query(rp, scpiCommand(enableRamping, channel)))
scpiCommand(::typeof(enableRamping), channel) = string("RP:DAC:CH", Int(channel)-1, ":RAMPing:ENaBle?")
scpiReturn(::typeof(enableRamping)) = String
parseReturn(::typeof(enableRamping), ret) = occursin("ON", ret)

function enableRampDown!(rp::RedPitaya, channel, value)
  return query(rp, scpiCommand(enableRampDown!, channel, value), scpiReturn(enableRampDown!))
end
scpiCommand(::typeof(enableRampDown!), channel, val::Bool) = scpiCommand(enableRampDown!, channel, val ? "ON" : "OFF")
scpiCommand(::typeof(enableRampDown!), channel, val::String) = string("RP:DAC:CH", Int(channel)-1, ":RAMPing:DoWN ", val)
scpiReturn(::typeof(enableRampDown!)) = Bool

enableRampDown(rp::RedPitaya, channel) = occursin("ON", query(rp, scpiCommand(enableRampDown, channel)))
scpiCommand(::typeof(enableRampDown), channel) = string("RP:DAC:CH", Int(channel)-1, ":RAMPing:DoWN?")
scpiReturn(::typeof(enableRampDown)) = String
parseReturn(::typeof(enableRampDown), ret) = occursin("ON", ret)

function rampingStatus(rp::RedPitaya)
  status = query(rp, scpiCommand(rampingStatus), scpiReturn(rampingStatus))
  result = RampingStatus(status & 1, (status >> 4) & 1,
      RampingState((status >> 1) & 0x7), RampingState((status >> 5) & 0x7))
  return result
end
scpiCommand(::typeof(rampingStatus)) = "RP:DAC:RAMPing:STATus?"
scpiReturn(::typeof(rampingStatus)) = UInt8
function parseReturn(::typeof(rampingStatus), ret)
  status = parse(UInt8, ret)
  result = RampingStatus(status & 1, (status >> 4) & 1,
      RampingState((status >> 1) & 0x7), RampingState((status >> 5) & 0x7))
  return result
end

function rampDownDone(rp::RedPitaya)
  done = false
  status = rampingStatus(rp)
  done = (!status.enableCh1 || status.stateCh1 == DONE) && (!status.enableCh2 || status.stateCh2 == DONE)
end

function rampUpDone(rp::RedPitaya)
  done = false
  status = rampingStatus(rp)
  done = (!status.enableCh1 || status.stateCh1 != UP) && (!status.enableCh2 || status.stateCh2 != UP)
end