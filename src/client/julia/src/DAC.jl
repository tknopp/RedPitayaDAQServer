export amplitudeDAC, frequencyDAC, phaseDAC, modeDAC,
       DCSignDAC, signalTypeDAC, offsetDAC, jumpSharpnessDAC, passPDMToFastDAC, DACConfig, configureFastDAC,
       waveforms, DACPerformanceData, computeRamping, rampUp, rampUpSteps, rampUpTotalSteps, sequenceRepetitions,
       prepareSlowDAC, stepsPerFrame, stepsPerRepetition!, samplesPerSlowDACStep,
       enableDACLUT, setArbitraryLUT, setConstantLUT, setPauseLUT, setRangeLUT, numSlowDACChan,
       appendSequence!, popSequence!, clearSequence!, prepareSequence!, resetAfterSequence,
       AbstractSequence, ArbitrarySequence, ConstantSequence, PauseSequence, RangeSequence, fastDACConfig

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

function getDACScpiPrefix(forSequence)
  prefix = "RP:DAC"
  if forSequence
    prefix = prefix * ":SEQ"
  end
  return prefix
end

function passPDMToFastDAC!(rp::RedPitaya, val::Bool)
  valStr = val ? "ON" : "OFF"
  send(rp, string("RP:DAC:PASStofast ", valStr))
end
passPDMToFastDAC(rp::RedPitaya) = occursin("ON", query(rp,"RP:DAC:PASStofast?"))

function amplitudeDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":AMP?")
  return query(rp, command, Float64)
end
function amplitudeDAC!(rp::RedPitaya, channel, component, value; forSequence=false)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":AMP ", Float64(value))
  return send(rp, command)
end
function amplitudeDAC!(config::DACConfig, channel, component, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  config.amplitudes[channel, component] = value
end

function offsetDAC(rp::RedPitaya, channel)
  command = string("RP:DAC:CH", Int(channel)-1, ":OFF?")
  return query(rp, command, Float64)
end
function offsetDAC!(rp::RedPitaya, channel, value; forSequence=false)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":OFF ", Float64(value))
  return send(rp, command)
end
function offsetDAC!(config::DACConfig, channel, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  config.offsets[channel] = value
end

function frequencyDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":FREQ?")
  return query(rp, command, Float64)
end
function frequencyDAC!(rp::RedPitaya, channel, component, value; forSequence=false)
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":FREQ ", Float64(value))
  send(rp, command)
end
function frequencyDAC!(config::DACConfig, channel, component, value)
  config.frequencies[channel, component] = value
end

function phaseDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":PHA?")
  return query(rp, command, Float64)
end
function phaseDAC!(rp::RedPitaya, channel, component, value; forSequence=false)
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":PHA ", Float64(value))
  send(rp, command)
end
function phaseDAC!(config::DACConfig, channel, component, value)
  config.phases[channel, component] = value
end

function jumpSharpnessDAC(rp::RedPitaya, channel)
  command = string("RP:DAC:CH", Int(channel)-1, ":JUMPsharpness?")
  return query(rp, command, Float64)
end
function jumpSharpnessDAC!(rp::RedPitaya, channel, value; forSequence=false)
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":JUMPsharpness ", Float64(value))
  send(rp, command)
end
function jumpSharpnessDAC!(config::DACConfig, channel, value)
  config.jumpSharpness[channel] = value
end

#"STANDARD" or "AWG" (not yet supported)
function modeDAC(rp::RedPitaya)
  modeDAC_(rp, 1)
  modeDAC_(rp, 2)
end
function modeDAC(rp::RedPitaya, mode::String)
  modeDAC_(rp, mode, 1)
  modeDAC_(rp, mode, 2)
end

function modeDAC_(rp::RedPitaya, channel=1)
  #return query(rp, "RP:DAC:CH", Int(channel)-1,":MODe?")[2:end-1]
  return query(rp, "RP:DAC:MODe?")[2:end-1]
end
function modeDAC_(rp::RedPitaya, mode::String, channel=1)
  #send(rp, string("RP:DAC:CH", Int(channel)-1, ":MODe ", mode))
  send(rp, string("RP:DAC:MODe ", mode))
end

function signalTypeDAC(rp::RedPitaya, channel)
  command = string("RP:DAC:CH", Int(channel)-1, ":SIGnaltype?")
  return stringToEnum(SignalType, query(rp, command))
end

function signalTypeDAC!(rp::RedPitaya, channel, sigType::String; forSequence=false)
  return signalTypeDAC!(rp, channel, stringToEnum(SignalType, sigType), forSequence = forSequence)
end
function signalTypeDAC!(rp::RedPitaya, channel, sigType::SignalType; forSequence=false)
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":SIGnaltype ", string(sigType))
  return send(rp, command)
end
function signalTypeDAC!(config::DACConfig, channel, sigType::String)
  config.signalTypes[channel] = sigType
end

function DCSignDAC(rp::RedPitaya, channel)
  command = string("RP:DAC:CH", Int(channel)-1, ":SIGn?")
  return query(rp, command, Int64) == "POSITIVE" ? 1 : -1
end

function DCSignDAC(rp::RedPitaya, channel, sign::Integer)
  command = string("RP:DAC:CH", Int(channel)-1, ":SIGn ",
             sign > 0 ? "POSITIVE" : "NEGATIVE")
  return send(rp, command)
end

function configureFastDAC!(rp::RedPitaya, config::DACConfig; forSequence = false)
  for ch = 1:2
    
    for cmp = 1:4
      amplitude = config.amplitudes[ch, cmp]
      isnothing(amplitude) || amplitudeDAC!(rp, ch, cmp, amplitude, forSequence = forSequence)
      frequency = config.frequencies[ch, cmp]
      isnothing(frequency) || frequencyDAC!(rp, ch, cmp, frequency, forSequence = forSequence)
      phase = config.phases[ch, cmp]
      isnothing(phase) || phaseDAC!(rp, ch, cmp, phase, forSequence = forSequence)
    end

    offset = config.offsets[ch]
    isnothing(offset) || offsetDAC!(rp, ch, offset, forSequence = forSequence)
    signalType = config.signalTypes[ch]
    isnothing(signalType) || signalTypeDAC!(rp, ch, signalType, forSequence = forSequence)

  end
end

function readDACPerformanceData(rp::RedPitaya)
  perf = read!(rp.dataSocket, Array{UInt8}(undef, 4))
  return DACPerformanceData(perf[1], perf[2], perf[3], perf[4])
end

numSeqChan(rp::RedPitaya) = query(rp,"RP:DAC:SEQ:CHan?", Int64)
function numSeqChan!(rp::RedPitaya, value)
  if value <= 0 || value > 4
    error("Num sequence channels needs to be between 1 and 4!")
  end
  send(rp, string("RP:DAC:SEQ:CHan ", Int64(value)))
end

function setValueLUT(rp::RedPitaya, lut::Union{Array, Nothing}, type::String="ARBITRARY")
  send(rp, string("RP:DAC:SEQ:LUT:", type))
  @debug "Writing arbitrary LUT"
  if !isnothing(lut)
    lutFloat32 = map(Float32, lut)
    write(rp.dataSocket, lutFloat32)
  end
end

function enableDACLUT(rp::RedPitaya, lut::Array)
  lutBool = map(Bool, lut)
  send(rp, string("RP:DAC:SEQ:LUT:ENaBle"))
  @debug "Writing enable DAC LUT"
  write(rp.dataSocket, lutBool)
end

samplesPerStep(rp::RedPitaya) = query(rp,"RP:DAC:SEQ:SAMP?", Int64)
function samplesPerStep!(rp::RedPitaya, value)
  send(rp, string("RP:DAC:SEQ:SAMP ", value))
end

stepsPerRepetition(rp::RedPitaya) = query(rp,"RP:DAC:SEQ:STEPs:REPetition?", Int64)
function stepsPerRepetition!(rp::RedPitaya, value)
  send(rp, string("RP:DAC:SEQ:STEPs:REPetition ", value))
end

function prepareSlowDAC!(rp::RedPitaya, samplesPerStep, stepsPerSequence, numOfChan)
  numSlowDACChan!(rp, numOfChan)
  samplesPerStep!(rp, samplesPerStep)
  stepsPerSequence!(rp, stepsPerSequence)
end

function stepsPerFrame!(rp::RedPitaya, stepsPerFrame)
  samplesPerFrame = rp.periodsPerFrame * rp.samplesPerPeriod
  samplesPerStep = div(samplesPerFrame, stepsPerFrame)
  samplesPerStep!(rp, samplesPerStep) # Sets PDMClockDivider
end

ramping!(rp::RedPitaya, rampSteps::Int32, rampTotalSteps::Int32) = send(rp, string("RP:DAC:SEQ:RaMPing ", rampSteps, ",", rampTotalSteps))
rampUp!(rp::RedPitaya, rampUpSteps::Int32, rampUpTotalSteps::Int32) = send(rp, string("RP:DAC:SEQ:RaMPing:UP ", rampUpSteps, ",", rampUpTotalSteps))
rampDown!(rp::RedPitaya, rampDownSteps::Int32, rampDownTotalSteps::Int32) = send(rp, string("RP:DAC:SEQ:RaMPing:DOWn ", rampDownSteps, ",", rampDownTotalSteps))

rampingSteps(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:STEPs?", Int32)
rampingSteps!(rp::RedPitaya, value::Int32) = send(rp, string("RP:DAC:SEQ:RaMPing:STEPs ", value))
rampingTotalSteps(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:TOTAL?", Int32)
rampingTotalSteps!(rp::RedPitaya, value::Int32) = send(rp, string("RP:DAC:SEQ:RaMPing:TOTAL ", value))

rampUpSteps(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:UP:STEPs?", Int32)
rampUpSteps!(rp::RedPitaya, value::Int32) = send(rp, string("RP:DAC:SEQ:RaMPing:UP:STEPs ", value))
rampUpTotalSteps(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:UP:TOTAL?", Int32)
rampUpTotalSteps!(rp::RedPitaya, value::Int32) = send(rp, string("RP:DAC:SEQ:RaMPing:UP:TOTAL ", value))

rampDownSteps(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:DOWN:STEPs?", Int32)
rampDownSteps!(rp::RedPitaya, value::Int32) = send(rp, string("RP:DAC:SEQ:RaMPing:DOWN:STEPs ", value))
rampDownTotalSteps(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:DOWN:TOTAL?", Int32)
rampDownTotalSteps!(rp::RedPitaya, value::Int32) = send(rp, string("RP:DAC:SEQ:RaMPing:DOWN:TOTAL ", value))

function resetAfterSequence!(rp::RedPitaya, val::Bool)
  valStr = val ? "ON" : "OFF"
  send(rp, string("RP:DAC:SEQ:RESETafter ", valStr))
end
resetAfterSequence(rp::RedPitaya) = occursin("ON", query(rp,"RP:DAC:SEQ:RESETafter?"))

sequenceRepetitions(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:REPetitions?", Int32)
function sequenceRepetitions!(rp::RedPitaya, value::Int)
  send(rp, string("RP:DAC:SEQ:REPetitions ", value))
end

appendSequence!(rp::RedPitaya) = send(rp, "RP:DAC:SEQ:APPend")
popSequence!(rp::RedPitaya) = send(rp, "RP:DAC:SEQ:POP")
clearSequence!(rp::RedPitaya) = send(rp, "RP:DAC:SEQ:CLEAR")
prepareSequence!(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:PREPare?", Bool)

# Helper function for sequences
abstract type AbstractSequence end

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
ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, upSteps, upTotalSteps, downSteps, rampDownTotalSteps, reset=false) = ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, upSteps, upTotalSteps, downSteps, rampDownTotalSteps, DACConfig(), reset)
ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, steps, totalSteps, reset=false) = ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, steps, totalSteps, steps, totalSteps, DACConfig(), reset)
ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, (steps, totalSteps)::Tuple, reset=false) = ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, steps, totalSteps, steps, totalSteps, DACConfig(), reset)
ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, (upSteps, upTotalSteps)::Tuple, (downSteps, downTotalSteps)::Tuple, reset=false) = ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, DACConfig(), reset)


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
  setValueLUT(rp, seq.lut, "ARBITRARY")
end

function setLUT!(rp::RedPitaya, seq::ConstantSequence)
  setValueLUT(rp, seq.lut, "CONSTANT")
end

function setLUT!(rp::RedPitaya, seq::PauseSequence)
  setValueLUT(rp, nothing, "PAUSE")
end

function setLUT!(rp::RedPitaya, seq::RangeSequence) 
  setValueLUT(rp, seq.lut, "RANGE")
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

function appendSequence!(rp::RedPitaya, seq::AbstractSequence)
  stepsPerRepetition!(rp, stepsPerRepetition(seq))
  rampUp(rp, rampUpSteps(seq), rampUpTotalSteps(seq))
  rampDown(rp, rampDownSteps(seq), rampDownTotalSteps(seq))
  sequenceRepetitions!(rp, repetitions(seq))
  setLUT(rp, seq)
  enable = enableLUT(seq)
  if !isnothing(enable)
    enableDACLUT(rp, enable)
  end
  configureFastDAC(rp, fastDACConfig(seq), forSequence = true)
  resetAfterSequence!(rp, resetAfterSequence(seq))
  appendSequence!(rp)
end

function length(seq::AbstractSequence)
  result = stepsPerRepetition(seq) * repetitions(seq) + rampUpTotalSteps(seq) + rampDownTotalSteps(seq)
  result = resetAfterSequence(seq) ? result + 1 : result
  return result
end

function start(seq::AbstractSequence)
  return rampUpTotalSteps(seq)
end