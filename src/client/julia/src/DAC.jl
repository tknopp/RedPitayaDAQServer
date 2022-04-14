export SignalType, SINE, SQUARE, TRIANGLE, SAWTOOTH, DACPerformanceData, DACConfig, passPDMToFastDAC, passPDMToFastDAC!,
amplitudeDAC, amplitudeDAC!, amplitudeDACSeq!, offsetDAC, offsetDAC!, offsetDACSeq!,
frequencyDAC, frequencyDAC!, frequencyDACSeq!, phaseDAC, phaseDAC!, phaseDACSeq!,
jumpSharpnessDAC, jumpSharpnessDAC!, jumpSharpnessDACSeq!, signalTypeDAC, signalTypeDAC!, signalTypeDACSeq!,
configureFastDACSeq!, numSeqChan, numSeqChan!,samplesPerStep, samplesPerStep!,
stepsPerRepetition, stepsPerRepetition!, prepareSteps!, stepsPerFrame!, 
rampingDAC!, enableRamping!, enableRamping, ramping!, rampUp!, rampDown!, rampingSteps, rampingSteps!, rampingTotalSteps, rampingTotalSteps!,
rampUpSteps, rampUpSteps!, rampUpTotalSteps, rampUpTotalSteps!, rampDownSteps, rampDownSteps!, rampDownTotalSteps, rampDownTotalSteps!, 
popSequence!, clearSequences!, appendSequence!, prepareSequences!, AbstractSequence, ArbitrarySequence, enableLUT,
fastDACConfig, resetAfterSequence!

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
scpiCommand(::typeof(passPDMToFastDAC!), valStr::String) = string("RP:DAC:PASStofast ", valStr)
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
  return query(rp, command, Bool)
end
scpiCommand(::typeof(rampingDAC!), channel, value) = string("RP:DAC:CH", Int(channel)-1, ":RAMP ", Float64(value))
scpiReturn(::typeof(rampingDAC!)) = Bool

function enableRamping!(rp::RedPitaya, value)
  return query(rp, scpiCommand(enableRamping!, value), scpiReturn(enableRamping!))
end
scpiCommand(::typeof(enableRamping!), val::Bool) = scpiCommand(enableRamping!, val ? "ON" : "OFF")
scpiCommand(::typeof(enableRamping!), valStr) = string("RP:DAC:RAMP:ENB ", valStr)
scpiReturn(::typeof(enableRamping!)) = Bool

enableRamping(rp::RedPitaya) = occursin("ON", query(rp, scpiCommand(enableRamping)))
scpiCommand(::typeof(enableRamping)) = "RP:DAC:RAMPing:ENaBle?"
scpiReturn(::typeof(enableRamping)) = String
parseReturn(::typeof(enableRamping), ret) = occursin("ON", ret)

function configureFastDACSeq!(rp::RedPitaya, config::DACConfig)
  result = true
  for ch = 1:2
    
    for cmp = 1:4
      amplitude = config.amplitudes[ch, cmp]
      if !isnothing(amplitude) 
       result &= amplitudeDACSeq!(rp, ch, cmp, amplitude)
      end
      frequency = config.frequencies[ch, cmp]
      if !isnothing(frequency)
        result &= frequencyDACSeq!(rp, ch, cmp, frequency)
      end
      phase = config.phases[ch, cmp]
      if !isnothing(phase)
        result &= phaseDACSeq!(rp, ch, cmp, phase)
      end
    end

    offset = config.offsets[ch]
    if !isnothing(offset)
      result &= offsetDACSeq!(rp, ch, offset)
    end
    signalType = config.signalTypes[ch]
    if !isnothing(signalType)
      result &= signalTypeDACSeq!(rp, ch, signalType)
    end
  end
  return result
end

function configureFastDACSeq!(batch::ScpiBatch, config::DACConfig)
  for ch = 1:2
    for cmp = 1:4
      amplitude = config.amplitudes[ch, cmp]
      isnothing(amplitude) ||  push!(batch, amplitudeDACSeq! => (ch, cmp, amplitude))
      
      frequency = config.frequencies[ch, cmp]
      isnothing(frequency) || push!(batch, frequencyDACSeq! => (ch, cmp, frequency))
      
      phase = config.phases[ch, cmp]
      isnothing(phase) || push!(batch, phaseDACSeq! => (ch, cmp, phase))
    end

    offset = config.offsets[ch]
    isnothing(offset) || push!(batch, offsetDACSeq! => (ch, offset))
    
    signalType = config.signalTypes[ch]
    isnothing(signalType) || push!(batch, signalTypeDACSeq! => (ch, signalType))
  end
end

function readDACPerformanceData(rp::RedPitaya)
  perf = read!(rp.dataSocket, Array{UInt8}(undef, 4))
  return DACPerformanceData(perf[1], perf[2], perf[3], perf[4])
end

"""
  numSeqChan(rp::RedPitaya)

Return the number of sequence channel.
"""
numSeqChan(rp::RedPitaya) = query(rp, scpiCommand(numSeqChan), scpiReturn(numSeqChan))
scpiCommand(::typeof(numSeqChan)) = "RP:DAC:SEQ:CHan?"
scpiReturn(::typeof(numSeqChan)) = Int64
"""
    numSeqChan(rp::RedPitaya, value)

Set the number of sequence channel. Valid values are between `1` and `4`. Return `true` if the command was successful.
"""
function numSeqChan!(rp::RedPitaya, value)
  if value <= 0 || value > 4
    error("Num sequence channels needs to be between 1 and 4!")
  end
  return query(rp, scpiCommand(numSeqChan!, value), scpiReturn(numSeqChan!))
end
scpiCommand(::typeof(numSeqChan!), value) = string("RP:DAC:SEQ:CHan ", Int64(value))
scpiReturn(::typeof(numSeqChan!)) =  Bool

function setValueLUT!(rp::RedPitaya, lut::Array, type::String="ARBITRARY")
  send(rp, string("RP:DAC:SEQ:LUT:", type))
  @debug "Writing arbitrary LUT"
  lutFloat32 = map(Float32, lut)
  @show lutFloat32
  write(rp.dataSocket, lutFloat32)
  reply = receive(rp)
  return parse(Bool, reply)
end

function setValueLUT!(rp::RedPitaya, lut::Nothing, type::String="ARBITRARY")
  send(rp, string("RP:DAC:SEQ:LUT:", type))
  @debug "Writing arbitrary LUT"
  reply = receive(rp)
  return parse(Bool, reply)
end

function enableDACLUT!(rp::RedPitaya, lut::Array)
  lutBool = map(Bool, lut)
  send(rp, string("RP:DAC:SEQ:LUT:ENaBle"))
  @debug "Writing enable DAC LUT"
  write(rp.dataSocket, lutBool)
  reply = receive(rp)
  return parse(Bool, reply)
end

"""
    samplesPerStep(rp::RedPitaya)

Return the number of samples per sequence step.
"""
samplesPerStep(rp::RedPitaya) = query(rp, scpiCommand(samplesPerStep), scpiReturn(samplesPerStep))
scpiCommand(::typeof(samplesPerStep)) = "RP:DAC:SEQ:SAMP?"
scpiReturn(::typeof(samplesPerStep)) = Int64 
"""
    samplesPerStep!(rp::RedPitaya, value::Integer)

Set the number of samples per sequence step. Return `true` if the command was successful.
"""
function samplesPerStep!(rp::RedPitaya, value::Integer)
  return query(rp, scpiCommand(samplesPerStep!, value), scpiReturn(samplesPerStep!))
end
scpiCommand(::typeof(samplesPerStep!), value) = string("RP:DAC:SEQ:SAMP ", value)
scpiReturn(::typeof(samplesPerStep!)) = Bool
"""
    stepsPerRepetition(rp::RedPitaya)

Return the number of steps per sequence repetitions.
"""
stepsPerRepetition(rp::RedPitaya) = query(rp, scpiCommand(stepsPerRepetition), scpiReturn(stepsPerRepetition))
scpiCommand(::typeof(stepsPerRepetition)) = "RP:DAC:SEQ:STEPs:REPetition?"
scpiReturn(::typeof(stepsPerRepetition)) = Int64
"""
    stepsPerRepetition!(rp::RedPitaya)

Set the number of steps per sequence repetitions. Return `true` if the command was successful.
"""
function stepsPerRepetition!(rp::RedPitaya, value)
  return query(rp, scpiCommand(stepsPerRepetition!, value), scpiReturn(stepsPerRepetition!))
end
scpiCommand(::typeof(stepsPerRepetition!), value) = string("RP:DAC:SEQ:STEPs:REPetition ", value)
scpiReturn(::typeof(stepsPerRepetition!)) = Bool

function prepareSteps!(rp::RedPitaya, samplesPerStep, stepsPerSequence, numOfChan)
  numSlowDACChan!(rp, numOfChan)
  samplesPerStep!(rp, samplesPerStep)
  stepsPerSequence!(rp, stepsPerSequence)
end

"""
    stepsPerFrame!(rp::RedPitaya, stepsPerFrame)

Set the number of samples per steps s.t. `stepsPerFrame` sequence steps in a frame.

See [`samplesPerPeriod!`](@ref), [`periodsPerFrame!`](@ref), [`samplesPerStep!`](@ref).
"""
function stepsPerFrame!(rp::RedPitaya, stepsPerFrame)
  samplesPerFrame = rp.periodsPerFrame * rp.samplesPerPeriod
  samplesPerStep = div(samplesPerFrame, stepsPerFrame)
  return samplesPerStep!(rp, samplesPerStep) # Sets PDMClockDivider
end

ramping!(rp::RedPitaya, rampSteps::Int32, rampTotalSteps::Int32) = query(rp, scpiCommand(ramping!, rampSteps, rampTotalSteps), scpiReturn(ramping!))
scpiCommand(::typeof(ramping!), rampSteps::Int32, rampTotalSteps::Int32) = string("RP:DAC:SEQ:RaMPing ", rampSteps, ",", rampTotalSteps)
scpiReturn(::typeof(ramping!)) = Bool
rampUp!(rp::RedPitaya, rampUpSteps::Int32, rampUpTotalSteps::Int32) = query(rp, scpiCommand(rampUp!, rampUpSteps, rampUpTotalSteps), scpiReturn(rampUp!))
scpiCommand(::typeof(rampUp!), rampUpSteps::Int32, rampUpTotalSteps::Int32) = string("RP:DAC:SEQ:RaMPing:UP ", rampUpSteps, ",", rampUpTotalSteps)
scpiReturn(::typeof(rampUp!)) = Bool
rampDown!(rp::RedPitaya, rampDownSteps::Int32, rampDownTotalSteps::Int32) = query(rp, scpiCommand(rampDown!, rampDownSteps, rampDownTotalSteps), scpiReturn(rampDown!))
scpiCommand(::typeof(rampDown!), rampDownSteps::Int32, rampDownTotalSteps::Int32) = string("RP:DAC:SEQ:RaMPing:DOWn ", rampDownSteps, ",", rampDownTotalSteps) 
scpiReturn(::typeof(rampDown!)) = Bool

rampingSteps(rp::RedPitaya) = query(rp, scpiCommand(rampingSteps), scpiReturn(rampingSteps))
scpiCommand(::typeof(rampingSteps)) = "RP:DAC:SEQ:RaMPing:STEPs?"
scpiReturn(::typeof(rampingSteps)) = Int32
rampingSteps!(rp::RedPitaya, value::Int32) = query(rp, scpiCommand(rampingSteps!, value), scpiReturn(rampingSteps!))
scpiCommand(::typeof(rampingSteps!), value::Int32) = string("RP:DAC:SEQ:RaMPing:STEPs ", value)
scpiReturn(::typeof(rampingSteps!)) = Bool
rampingTotalSteps(rp::RedPitaya) = query(rp, scpiCommand(rampingTotalSteps), scpiReturn(rampingTotalSteps))
scpiCommand(::typeof(rampingTotalSteps)) = "RP:DAC:SEQ:RaMPing:TOTAL?"
scpiReturn(::typeof(rampingTotalSteps)) = Int32
rampingTotalSteps!(rp::RedPitaya, value::Int32) = query(rp, scpiCommand(rampingTotalSteps!, value), scpiReturn(rampingTotalSteps!))
scpiCommand(::typeof(rampingTotalSteps!), value::Int32) = string("RP:DAC:SEQ:RaMPing:TOTAL ", value)
scpiReturn(::typeof(rampingTotalSteps!)) = Bool

rampUpSteps(rp::RedPitaya) = query(rp, scpiCommand(rampUpSteps), scpiReturn(rampUpSteps))
scpiCommand(::typeof(rampUpSteps)) = "RP:DAC:SEQ:RaMPing:UP:STEPs?"
scpiReturn(::typeof(rampUpSteps)) = Int32
rampUpSteps!(rp::RedPitaya, value::Int32) = query(rp, scpiCommand(rampUpSteps!, value), scpiReturn(rampUpSteps!))
scpiCommand(::typeof(rampUpSteps!), value::Int32) = string("RP:DAC:SEQ:RaMPing:UP:STEPs ", value)
scpiReturn(::typeof(rampUpSteps!)) = Bool
rampUpTotalSteps(rp::RedPitaya) = query(rp, scpiCommand(rampUpTotalSteps), scpiReturn(rampUpTotalSteps))
scpiCommand(::typeof(rampUpTotalSteps)) = "RP:DAC:SEQ:RaMPing:UP:TOTAL?"
scpiReturn(::typeof(rampUpTotalSteps)) = Int32
rampUpTotalSteps!(rp::RedPitaya, value::Int32) = query(rp, scpiCommand(rampUpTotalSteps!, value), scpiReturn(rampUpTotalSteps!))
scpiCommand(::typeof(rampUpTotalSteps!), value::Int32) = string("RP:DAC:SEQ:RaMPing:UP:TOTAL ", value)
scpiReturn(::typeof(rampUpTotalSteps!)) = Bool

rampDownSteps(rp::RedPitaya) = query(rp, scpiCommand(rampDownSteps), scpiReturn(rampDownSteps))
scpiCommand(::typeof(rampDownSteps)) = "RP:DAC:SEQ:RaMPing:DOWN:STEPs?"
scpiReturn(::typeof(rampDownSteps)) = Int32
rampDownSteps!(rp::RedPitaya, value::Int32) = query(rp, scpiCommand(rampDownSteps!, value), scpiReturn(rampDownSteps!))
scpiCommand(::typeof(rampDownSteps!), value::Int32) = string("RP:DAC:SEQ:RaMPing:DOWN:STEPs ", value)
scpiReturn(::typeof(rampDownSteps!)) = Bool
rampDownTotalSteps(rp::RedPitaya) = query(rp, scpiCommand(rampDownTotalSteps), scpiReturn(rampDownTotalSteps))
scpiCommand(::typeof(rampDownTotalSteps)) = "RP:DAC:SEQ:RaMPing:DOWN:TOTAL?"
scpiReturn(::typeof(rampDownTotalSteps)) = Int32
rampDownTotalSteps!(rp::RedPitaya, value::Int32) = query(rp, scpiCommand(rampDownTotalSteps!, value), scpiReturn(rampDownTotalSteps!))
scpiCommand(::typeof(rampDownTotalSteps!), value::Int32) = string("RP:DAC:SEQ:RaMPing:DOWN:TOTAL ", value)
scpiReturn(::typeof(rampDownTotalSteps!)) = Bool

function resetAfterSequence!(rp::RedPitaya, val::Bool)
  return query(rp, scpiCommand(resetAfterSequence!, val), scpiReturn(resetAfterSequence!))
end
scpiCommand(::typeof(resetAfterSequence!), val::Bool) = scpiCommand(resetAfterSequence!, val ? "ON" : "OFF")
scpiCommand(::typeof(resetAfterSequence!), valStr::String) = string("RP:DAC:SEQ:RESETafter ", valStr)
scpiReturn(::typeof(resetAfterSequence!)) = Bool
resetAfterSequence(rp::RedPitaya) = occursin("ON", query(rp, scpiCommand(resetAfterSequence)))
scpiCommand(::typeof(resetAfterSequence)) = "RP:DAC:SEQ:RESETafter?"
scpiReturn(::typeof(resetAfterSequence)) = String
parseReturn(::typeof(resetAfterSequence), ret) = occursin("ON", ret)

sequenceRepetitions(rp::RedPitaya) = query(rp, scpiCommand(sequenceRepetitions), scpiReturn(sequenceRepetitions))
scpiCommand(::typeof(sequenceRepetitions)) = "RP:DAC:SEQ:REPetitions?"
scpiReturn(::typeof(sequenceRepetitions)) = Int32
function sequenceRepetitions!(rp::RedPitaya, value::Int)
  return query(rp, scpiCommand(sequenceRepetitions!, value), scpiReturn(sequenceRepetitions!))
end
scpiCommand(::typeof(sequenceRepetitions!), value) = string("RP:DAC:SEQ:REPetitions ", value)
scpiReturn(::typeof(sequenceRepetitions!)) = Bool

appendSequence!(rp::RedPitaya) = query(rp, scpiCommand(appendSequence!), scpiReturn(appendSequence!))
scpiCommand(::typeof(appendSequence!)) = "RP:DAC:SEQ:APPend"
scpiReturn(::typeof(appendSequence!)) = Bool

"""
    popSequence!(rp::RedPitaya)

Instruct the server to remove the last added sequence from its list. Return `true` if the command was successful.
"""
popSequence!(rp::RedPitaya) = query(rp, scpiCommand(popSequence!), scpiReturn(popSequence!))
scpiCommand(::typeof(popSequence!)) = "RP:DAC:SEQ:POP"
scpiReturn(::typeof(popSequence!)) = Bool

"""
    clearSequences!(rp::RedPitaya)

Instruct the server to remove all sequences from its list. Return `true` if the command was successful.
"""
clearSequences!(rp::RedPitaya) = query(rp, scpiCommand(clearSequences!), scpiReturn(clearSequences!))
scpiCommand(::typeof(clearSequences!)) = "RP:DAC:SEQ:CLEAR"
scpiReturn(::typeof(clearSequences!)) = Bool

"""
    prepareSequences!(rp::RedPitaya)

Instruct the server to prepare the currently added sequences.
Return `true` if the command was successful.
"""
prepareSequences!(rp::RedPitaya) = query(rp, scpiCommand(prepareSequences!), scpiReturn(prepareSequences!))
scpiCommand(::typeof(prepareSequences!)) = "RP:DAC:SEQ:PREPare"
scpiReturn(::typeof(prepareSequences!)) = Bool

# Helper function for sequences
"""
    AbstractSequence

Abstract struct of client-side representation of a sequence.

See [`appendSequence!`](@ref), [`prepareSequence!`](@ref), [`ArbitrarySequence`](@ref).
"""
abstract type AbstractSequence end
"""
    ArbitrarySequence <: AbstractSequence

Struct representing a sequence in which the server directly takes the values from the given LUT.
"""
mutable struct ArbitrarySequence <: AbstractSequence
  lut::Array{Float32}
  enable::Union{Array{Bool}, Nothing}
  stepsPerRepetition::Int
  repetitions::Int
  rampUpSteps::Int32
  rampUpTotalSteps::Int32
  rampDownSteps::Int32
  rampDownTotalSteps::Int32
  fastDAC::DACConfig
  resetAfter::Bool
end
"""
    ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, upSteps, upTotalSteps, downSteps, rampDownTotalSteps, reset=false)

Constructor for `ArbitrarySequence`.

# Arguments
- `lut::Array{Float32}`: `n`x`m` matrix containing `m` steps for `n` channel
- `emable::Union{Array{Bool}, Nothing}`: matrix containing enable flags
- `repetitions::Int32`: the number of times the sequence should be repeated
- `upSteps::Int32`: the number of steps the ramping factor should be increasing to 1.0
- `upTotalSteps::Int32`: the total number of steps spent in the ramp up phase
- `downSteps::Int32` the number of steps the ramping factor should be decreasing to 0.0
- `downTotalSteps::Int32`: the total number of steps spent in the ramp down phase
- `reset::Bool`: flag if the phase should be reset after this sequence is done
"""
ArbitrarySequence(lut, enable, repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, reset=false) = ArbitrarySequence(lut, enable, length(size(lut)) == 1 ? size(lut, 1) : size(lut, 2), repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, DACConfig(), reset)
"""
    ArbitrarySequence(lut, enable, repetitions, steps, totalSteps, reset=false)

Alternative constructor where `upSteps`, `downSteps` is set to `steps` and `upTotalSteps` and `downTotalSteps` is set to `totalSteps`.
"""
ArbitrarySequence(lut, enable, repetitions, steps, totalSteps, reset=false) = ArbitrarySequence(lut, enable, repetitions, steps, totalSteps, steps, totalSteps, DACConfig(), reset)
"""
    ArbitrarySequence(lut, enable, repetitions, steps, totalSteps, reset=false)

Alternative constructor where `upSteps`, `downSteps` is set to `steps` and `upTotalSteps` and `downTotalSteps` is set to `totalSteps`.
"""
ArbitrarySequence(lut, enable, repetitions, (steps, totalSteps)::Tuple, reset=false) = ArbitrarySequence(lut, enable, repetitions, steps, totalSteps, steps, totalSteps, DACConfig(), reset)
"""
    ArbitrarySequence(lut, enable, repetitions, (upSteps, upTotalSteps)::Tuple, (downSteps, downTotalSteps)::Tuple, reset=false)

Alternative constructor where the steps can be given as two tuples.
"""
ArbitrarySequence(lut, enable, repetitions, (upSteps, upTotalSteps)::Tuple, (downSteps, downTotalSteps)::Tuple, reset=false) = ArbitrarySequence(lut, enable, repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, DACConfig(), reset)


stepsPerRepetition(seq::ArbitrarySequence) = seq.stepsPerRepetition
rampUpSteps(seq::ArbitrarySequence) = seq.rampUpSteps
rampUpTotalSteps(seq::ArbitrarySequence) = seq.rampUpTotalSteps
rampDownSteps(seq::ArbitrarySequence) = seq.rampDownSteps
rampDownTotalSteps(seq::ArbitrarySequence) = seq.rampDownTotalSteps
repetitions(seq::ArbitrarySequence) = seq.repetitions
enableLUT(seq::ArbitrarySequence) = seq.enable
fastDACConfig(seq::ArbitrarySequence) = seq.fastDAC
resetAfterSequence(seq::ArbitrarySequence) = seq.resetAfter

mutable struct ConstantSequence <: AbstractSequence
  lut::Array{Float32}
  enable::Union{Array{Bool}, Nothing}
  stepsPerRepetition::Int
  repetitions::Int
  rampUpSteps::Int32
  rampUpTotalSteps::Int32
  rampDownSteps::Int32
  rampDownTotalSteps::Int32
  fastDAC::DACConfig
  resetAfter::Bool
end
ConstantSequence(lut, enable, stepsPerRepetition, repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, reset=false) = ConstantSequence(lut, enable, stepsPerRepetition, repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, DACConfig(), reset)
ConstantSequence(lut, enable, stepsPerRepetition, repetitions, steps, totalSteps, reset=false) = ConstantSequence(lut, enable, stepsPerRepetition, repetitions, steps, totalSteps, steps, totalSteps, DACConfig(), reset)
ConstantSequence(lut, enable, stepsPerRepetition, repetitions, (steps, totalSteps)::Tuple, reset=false) = ConstantSequence(lut, enable, stepsPerRepetition, repetitions, steps, totalSteps, steps, totalSteps, DACConfig(), reset)
ConstantSequence(lut, enable, stepsPerRepetition, repetitions, (upSteps, upTotalSteps)::Tuple, (downSteps, downTotalSteps)::Tuple, reset=false) = ConstantSequence(lut, enable, stepsPerRepetition, repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, DACConfig(), reset)


stepsPerRepetition(seq::ConstantSequence) = seq.stepsPerRepetition
rampUpSteps(seq::ConstantSequence) = seq.rampUpSteps
rampUpTotalSteps(seq::ConstantSequence) = seq.rampUpTotalSteps
rampDownSteps(seq::ConstantSequence) = seq.rampDownSteps
rampDownTotalSteps(seq::ConstantSequence) = seq.rampDownTotalSteps
repetitions(seq::ConstantSequence) = seq.repetitions
enableLUT(seq::ConstantSequence) = seq.enable
fastDACConfig(seq::ConstantSequence) = seq.fastDAC
resetAfterSequence(seq::ConstantSequence) = seq.resetAfter

mutable struct PauseSequence <: AbstractSequence
  enable::Union{Array{Bool}, Nothing}
  stepsPerRepetition::Int
  repetitions::Int
  fastDAC::DACConfig
  resetAfter::Bool
end
PauseSequence(enable, stepsPerRepetition, repetitions, reset=false) = PauseSequence(enable, stepsPerRepetition, repetitions, DACConfig(), reset)

stepsPerRepetition(seq::PauseSequence) = seq.stepsPerRepetition
rampUpSteps(seq::PauseSequence) = Int32(0)
rampUpTotalSteps(seq::PauseSequence) = Int32(0)
rampDownSteps(seq::PauseSequence) = Int32(0)
rampDownTotalSteps(seq::PauseSequence) = Int32(0)
repetitions(seq::PauseSequence) = seq.repetitions
enableLUT(seq::PauseSequence) = seq.enable
fastDACConfig(seq::PauseSequence) = seq.fastDAC
resetAfterSequence(seq::PauseSequence) = seq.resetAfter

mutable struct RangeSequence <: AbstractSequence
  lut::Array{Float32}
  enable::Union{Array{Bool}, Nothing}
  stepsPerRepetition::Int
  repetitions::Int
  rampUpSteps::Int32
  rampUpTotalSteps::Int32
  rampDownSteps::Int32
  rampDownTotalSteps::Int32
  fastDAC::DACConfig
  resetAfter::Bool
end
RangeSequence(lut, enable, stepsPerRepetition, repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, reset=false) = RangeSequence(lut, enable, stepsPerRepetition, repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, DACConfig(), reset)
RangeSequence(lut, enable, stepsPerRepetition, repetitions, steps, totalSteps, reset=false) = RangeSequence(lut, enable, stepsPerRepetition, repetitions, steps, totalSteps, steps, totalSteps, DACConfig(), reset)
RangeSequence(lut, enable, stepsPerRepetition, repetitions, (steps, totalSteps)::Tuple, reset=false) = RangeSequence(lut, enable, stepsPerRepetition, repetitions, steps, totalSteps, steps, totalSteps, DACConfig(), reset)
RangeSequence(lut, enable, stepsPerRepetition, repetitions, (upSteps, upTotalSteps)::Tuple, (downSteps, downTotalSteps)::Tuple, reset=false) = RangeSequence(lut, enable, stepsPerRepetition, repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, DACConfig(), reset)

stepsPerRepetition(seq::RangeSequence) = seq.stepsPerRepetition
rampUpSteps(seq::RangeSequence) = seq.rampUpSteps
rampUpTotalSteps(seq::RangeSequence) = seq.rampUpTotalSteps
rampDownSteps(seq::RangeSequence) = seq.rampDownSteps
rampDownTotalSteps(seq::RangeSequence) = seq.rampDownTotalSteps
repetitions(seq::RangeSequence) = seq.repetitions
enableLUT(seq::RangeSequence) = seq.enable
fastDACConfig(seq::RangeSequence) = seq.fastDAC
resetAfterSequence(seq::RangeSequence) = seq.resetAfter

setLUT!(rp::RedPitaya, seq::AbstractSequence) = error("Sequence did not implement setLUT!")

function setLUT!(rp::RedPitaya, seq::ArbitrarySequence)
  setValueLUT!(rp, seq.lut, "ARBITRARY")
end

function setLUT!(rp::RedPitaya, seq::ConstantSequence)
  setValueLUT!(rp, seq.lut, "CONSTANT")
end

function setLUT!(rp::RedPitaya, seq::PauseSequence)
  setValueLUT!(rp, nothing, "PAUSE")
end

function setLUT!(rp::RedPitaya, seq::RangeSequence) 
  setValueLUT!(rp, seq.lut, "RANGE")
end

function computeRamping(dec, samplesPerStep, stepsPerSeq, rampTime, rampFraction)
  bandwidth = 125e6/dec
  samplesPerRotation = samplesPerStep * stepsPerSeq
  totalRotations = Int32(ceil(rampTime/(samplesPerRotation/bandwidth)))
  totalSteps = totalRotations * stepsPerSeq
  steps = Int32(ceil(rampTime * rampFraction/(samplesPerStep/bandwidth)))
  #@show samplesPerRotation totalRotations totalSteps steps rampTime rampFraction
  return (steps, totalSteps)
end
computeRamping(rp::RedPitaya, stepsPerSeq ,rampTime, rampFraction) = computeRamping(decimation(rp), samplesPerStep(rp), stepsPerSeq, rampTime, rampFraction)

"""
    appendSequence!(rp::RedPitaya, seq::AbstractSequence)

Transmit the client-side representation `seq` to the server and append it to the current list of sequences. Return `true` if the required commands were successful.

See [`prepareSequence!`](@ref), [`clearSequences!`](@ref).
"""
function appendSequence!(rp::RedPitaya, seq::AbstractSequence)
  batch = ScpiBatch()
  push!(batch, stepsPerRepetition! => stepsPerRepetition(seq))
  push!(batch, rampUp! => (rampUpSteps(seq), rampUpTotalSteps(seq)))
  push!(batch, rampDown! => (rampDownSteps(seq), rampDownTotalSteps(seq)))
  push!(batch, sequenceRepetitions! => repetitions(seq))
  push!(batch, resetAfterSequence! => resetAfterSequence(seq))
  configureFastDACSeq!(batch, fastDACConfig(seq))
  result = all(execute!(rp, batch))
  setLUT!(rp, seq)
  enable = enableLUT(seq)
  if !isnothing(enable)
    result &= enableDACLUT!(rp, enable)
  end
  result &= appendSequence!(rp)
  return result
end

"""
    length(seq::AbstractSequence)

Return the number of steps a sequence will take.
"""
function length(seq::AbstractSequence)
  result = stepsPerRepetition(seq) * repetitions(seq) + rampUpTotalSteps(seq) + rampDownTotalSteps(seq)
  result = resetAfterSequence(seq) ? result + 1 : result
  return result
end

"""
    start(seq::AbstractSequence)

Return the number of steps after which a sequence leaves the ramp up phase.
"""
function start(seq::AbstractSequence)
  return rampUpTotalSteps(seq)
end