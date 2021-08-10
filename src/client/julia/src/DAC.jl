export amplitudeDAC, frequencyDAC, phaseDAC, modeDAC,
       DCSignDAC, signalTypeDAC, offsetDAC, jumpSharpnessDAC, passPDMToFastDAC, DACConfig, configureFastDAC,
       waveforms, DACPerformanceData, rampUp, rampUpTime, rampUpFraction, sequenceRepetitions,
       prepareSlowDAC, slowDACStepsPerFrame, slowDACStepsPerSequence, samplesPerSlowDACStep,
       enableDACLUT, setArbitraryLUT, setConstantLUT, setPauseLUT, setRangeLUT, numSlowDACChan,
       appendSequence, popSequence, clearSequences, prepareSequence, numLostStepsSlowADC,
       AbstractSequence, ArbitrarySequence, ConstantSequence, PauseSequence, RangeSequence, fastDACConfig

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

function passPDMToFastDAC(rp::RedPitaya, val::Bool)
  valStr = val ? "ON" : "OFF"
  send(rp, string("RP:PassPDMToFastDAC ", valStr))
end
passPDMToFastDAC(rp::RedPitaya) = occursin("ON", query(rp,"RP:PassPDMToFastDAC?"))

function amplitudeDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":AMP?")
  return query(rp, command, Float64)
end
function amplitudeDAC(rp::RedPitaya, channel, component, value; forSequence=false)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":AMP ", Float64(value))
  return send(rp, command)
end
function amplitudeDAC(config::DACConfig, channel, component, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  config.amplitudes[channel, component] = value
end

function offsetDAC(rp::RedPitaya, channel)
  command = string("RP:DAC:CH", Int(channel)-1, ":OFF?")
  return query(rp, command, Float64)
end
function offsetDAC(rp::RedPitaya, channel, value; forSequence=false)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":OFF ", Float64(value))
  return send(rp, command)
end
function offsetDAC(config::DACConfig, channel, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  config.offsets[channel] = value
end

function frequencyDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":FREQ?")
  return query(rp, command, Float64)
end
function frequencyDAC(rp::RedPitaya, channel, component, value; forSequence=false)
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":FREQ ", Float64(value))
  send(rp, command)
end
function frequencyDAC(config::DACConfig, channel, component, value)
  config.frequencies[channel, component] = value
end

function phaseDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":PHA?")
  return query(rp, command, Float64)
end
function phaseDAC(rp::RedPitaya, channel, component, value; forSequence=false)
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":PHA ", Float64(value))
  send(rp, command)
end
function phaseDAC(config::DACConfig, channel, component, value)
  config.phases[channel, component] = value
end

function jumpSharpnessDAC(rp::RedPitaya, channel)
  command = string("RP:DAC:CH", Int(channel)-1, ":JumpSharpness?")
  return query(rp, command, Float64)
end
function jumpSharpnessDAC(rp::RedPitaya, channel, value; forSequence=false)
  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":JumpSharpness ", Float64(value))
  send(rp, command)
end
function jumpSharpnessDAC(config::DACConfig, channel, value)
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
  @show command
  return query(rp, command)
end

waveforms() = ["SINE","SQUARE","TRIANGLE","SAWTOOTH"]

function signalTypeDAC(rp::RedPitaya, channel, sigType::String; forSequence=false)
  if !(sigType in waveforms() )
    error("Signal type $sigType not supported!")
  end

  command = string(getDACScpiPrefix(forSequence), ":CH", Int(channel)-1, ":SIGnaltype ", sigType)
  return send(rp, command)
end
function signalTypeDAC(config::DACConfig, channel, sigType::String)
  if !(sigType in waveforms() )
    error("Signal type $sigType not supported!")
  end
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

function configureFastDAC(rp::RedPitaya, config::DACConfig; forSequence = false)
  for ch = 1:2
    
    for cmp = 1:4
      amplitude = config.amplitudes[ch, cmp]
      isnothing(amplitude) || amplitudeDAC(rp, ch, cmp, amplitude, forSequence = forSequence)
      frequency = config.frequencies[ch, cmp]
      isnothing(frequency) || frequencyDAC(rp, ch, cmp, frequency, forSequence = forSequence)
      phase = config.phases[ch, cmp]
      isnothing(phase) || phaseDAC(rp, ch, cmp, phase, forSequence = forSequence)
    end

    offset = config.offsets[ch]
    isnothing(offset) || offsetDAC(rp, ch, offset, forSequence = forSequence)
    signalType = config.signalTypes[ch]
    isnothing(signalType) || signalTypeDAC(rp, ch, signalType, forSequence = forSequence)

  end
end

function readDACPerformanceData(rp::RedPitaya)
  perf = read!(rp.dataSocket, Array{UInt8}(undef, 4))
  return DACPerformanceData(perf[1], perf[2], perf[3], perf[4])
end


numLostStepsSlowADC(rp::RedPitaya) = query(rp,"RP:DAC:SEQ:LostSteps?", Int64) # TODO slowADC vs slowDAC in name and string

numSlowDACChan(rp::RedPitaya) = query(rp,"RP:DAC:SEQ:CHan?", Int64)
function numSlowDACChan(rp::RedPitaya, value)
  if value <= 0 || value > 4
    error("Num slow DAC channels needs to be between 1 and 4!")
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

samplesPerSlowDACStep(rp::RedPitaya) = query(rp,"RP:DAC:SEQ:SAMPlesPerStep?", Int64)
function samplesPerSlowDACStep(rp::RedPitaya, value)
  send(rp, string("RP:DAC:SEQ:SAMPlesPerStep ", value))
end

slowDACStepsPerSequence(rp::RedPitaya) = query(rp,"RP:DAC:SEQ:STEPsPerSequence?", Int64)
function slowDACStepsPerSequence(rp::RedPitaya, value)
  send(rp, string("RP:DAC:SEQ:STEPsPerSequence ", value))
end

function prepareSlowDAC(rp::RedPitaya, samplesPerStep, stepsPerSequence, numOfChan)
  numSlowDACChan(rp, numOfChan)
  samplesPerSlowDACStep(rp, samplesPerStep)
  slowDACStepsPerSequence(rp, stepsPerSequence)
end

function slowDACStepsPerFrame(rp::RedPitaya, stepsPerFrame)
  samplesPerFrame = rp.periodsPerFrame * rp.samplesPerPeriod
  samplesPerStep = div(samplesPerFrame, stepsPerFrame)
  samplesPerSlowDACStep(rp, samplesPerStep) # Sets PDMClockDivider
  slowDACStepsPerSequence(rp, stepsPerFrame)  
end

function ramping(rp::RedPitaya, rampTime::Float64, rampFraction::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:UP ", rampTime, ",", rampFraction))
end

function rampUp(rp::RedPitaya, rampUpTime::Float64, rampUpFraction::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:UP ", rampUpTime, ",", rampUpFraction))
end

function rampDown(rp::RedPitaya, rampDownTime::Float64, rampDownFraction::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:DOWn ", rampDownTime, ",", rampDownFraction))
end

rampingTime(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:TIME?", Float64)
function rampingTime(rp::RedPitaya, value::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:TIME ", value))
end

rampingFraction(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:FRACtion?", Float64)
function rampingFraction(rp::RedPitaya, value::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:FRACtion ", value))
end

rampUpTime(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:UP:TIME?", Float64)
function rampUpTime(rp::RedPitaya, value::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:UP:TIME ", value))
end

rampUpFraction(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:UP:FRACtion?", Float64)
function rampUpFraction(rp::RedPitaya, value::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:UP:FRACtion ", value))
end

rampDownTime(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:DOWN:TIME?", Float64)
function rampDownTime(rp::RedPitaya, value::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:DOWN:TIME ", value))
end

rampDownFraction(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:DOWN:FRACtion?", Float64)
function rampDownFraction(rp::RedPitaya, value::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:DOWN:FRACtion ", value))
end

sequenceRepetitions(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:REPetitions?", Int32)
function sequenceRepetitions(rp::RedPitaya, value::Int)
  send(rp, string("RP:DAC:SEQ:REPetitions ", value))
end

appendSequence(rp::RedPitaya) = send(rp, "RP:DAC:SEQ:APPend")
popSequence(rp::RedPitaya) = send(rp, "RP:DAC:SEQ:POP")
clearSequences(rp::RedPitaya) = send(rp, "RP:DAC:SEQ:CLEAR")
prepareSequence(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:PREPare?", Bool)

# Helper function for sequences
abstract type AbstractSequence end

mutable struct ArbitrarySequence <: AbstractSequence
  lut::Array{Float32}
  enable::Union{Array{Bool}, Nothing}
  stepsPerRepetition::Int
  repetitions::Int
  rampUpTime::Float64
  rampUpFraction::Float64
  rampDownTime::Float64
  rampDownFraction::Float64
  fastDAC::DACConfig  
end

ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, rampingTime, rampingFraction) = ArbitrarySequence(lut, enable, stepsPerRepetition, repetitions, rampingTime, rampingFraction, rampingTime, rampingFraction, DACConfig())

stepsPerRepetition(seq::ArbitrarySequence) = seq.stepsPerRepetition
rampUpTime(seq::ArbitrarySequence) = seq.rampUpTime
rampUpFraction(seq::ArbitrarySequence) = seq.rampUpFraction
rampDownTime(seq::ArbitrarySequence) = seq.rampDownTime
rampDownFraction(seq::ArbitrarySequence) = seq.rampDownFraction
repetitions(seq::ArbitrarySequence) = seq.repetitions
enableLUT(seq::ArbitrarySequence) = seq.enable
fastDACConfig(seq::ArbitrarySequence) = seq.fastDAC

mutable struct ConstantSequence <: AbstractSequence
  lut::Array{Float32}
  enable::Union{Array{Bool}, Nothing}
  stepsPerRepetition::Int
  repetitions::Int
  rampUpTime::Float64
  rampUpFraction::Float64
  rampDownTime::Float64
  rampDownFraction::Float64
  fastDAC::DACConfig  
end

ConstantSequence(lut, enable, stepsPerRepetition, repetitions, rampingTime, rampingFraction) = ConstantSequence(lut, enable, stepsPerRepetition, repetitions, rampingTime, rampingFraction, rampingTime, rampingFraction, DACConfig())


stepsPerRepetition(seq::ConstantSequence) = seq.stepsPerRepetition
rampUpTime(seq::ConstantSequence) = seq.rampUpTime
rampUpFraction(seq::ConstantSequence) = seq.rampUpFraction
rampDownTime(seq::ConstantSequence) = seq.rampDownTime
rampDownFraction(seq::ConstantSequence) = seq.rampDownFraction
repetitions(seq::ConstantSequence) = seq.repetitions
enableLUT(seq::ConstantSequence) = seq.enable
fastDACConfig(seq::ConstantSequence) = seq.fastDAC

mutable struct PauseSequence <: AbstractSequence
  enable::Union{Array{Bool}, Nothing}
  stepsPerRepetition::Int
  repetitions::Int
  fastDAC::DACConfig  
end

PauseSequence(enable, stepsPerRepetition, repetitions) = PauseSequence(enable, stepsPerRepetition, repetitions, DACConfig())

stepsPerRepetition(seq::PauseSequence) = seq.stepsPerRepetition
rampUpTime(seq::PauseSequence) = 0.0
rampUpFraction(seq::PauseSequence) = 0.0
rampDownTime(seq::PauseSequence) = 0.0
rampDownFraction(seq::PauseSequence) = 0.0
repetitions(seq::PauseSequence) = seq.repetitions
enableLUT(seq::PauseSequence) = seq.enable
fastDACConfig(seq::PauseSequence) = seq.fastDAC

mutable struct RangeSequence <: AbstractSequence
  lut::Array{Float32}
  enable::Union{Array{Bool}, Nothing}
  stepsPerRepetition::Int
  repetitions::Int
  rampUpTime::Float64
  rampUpFraction::Float64
  rampDownTime::Float64
  rampDownFraction::Float64
  fastDAC::DACConfig  
end

RangeSequence(lut, enable, stepsPerRepetition, repetitions, rampingTime, rampingFraction) = RangeSequence(lut, enable, stepsPerRepetition, repetitions, rampingTime, rampingFraction, rampingTime, rampingFraction, DACConfig())

stepsPerRepetition(seq::RangeSequence) = seq.stepsPerRepetition
rampUpTime(seq::RangeSequence) = seq.rampUpTime
rampUpFraction(seq::RangeSequence) = seq.rampUpFraction
rampDownTime(seq::RangeSequence) = seq.rampDownTime
rampDownFraction(seq::RangeSequence) = seq.rampDownFraction
repetitions(seq::RangeSequence) = seq.repetitions
enableLUT(seq::RangeSequence) = seq.enable
fastDACConfig(seq::RangeSequence) = seq.fastDAC

setLUT(rp::RedPitaya, seq::AbstractSequence) = error("Sequence did not implement setLUT")

function setLUT(rp::RedPitaya, seq::ArbitrarySequence)
  setValueLUT(rp, seq.lut, "ARBITRARY")
end

function setLUT(rp::RedPitaya, seq::ConstantSequence)
  setValueLUT(rp, seq.lut, "CONSTANT")
end

function setLUT(rp::RedPitaya, seq::PauseSequence)
  setValueLUT(rp, nothing, "PAUSE")
end

function setLUT(rp::RedPitaya, seq::RangeSequence) 
  setValueLUT(rp, seq.lut, "RANGE")
end

function appendSequence(rp::RedPitaya, seq::AbstractSequence)
  slowDACStepsPerSequence(rp, stepsPerRepetition(seq))
  rampUp(rp, rampUpTime(seq), rampUpFraction(seq))
  rampDown(rp, rampDownTime(seq), rampDownFraction(seq))
  sequenceRepetitions(rp, repetitions(seq))
  setLUT(rp, seq)
  enable = enableLUT(seq)
  if !isnothing(enable)
    enableDACLUT(rp, enable)
  end
  configureFastDAC(rp, fastDACConfig(seq), forSequence = true)
  appendSequence(rp)
end