export amplitudeDAC, frequencyDAC, phaseDAC, modeDAC, amplitudeDACNext,
       DCSignDAC, signalTypeDAC, offsetDAC, jumpSharpnessDAC, passPDMToFastDAC,
       waveforms, DACPerformanceData, rampUp, rampUpTime, rampUpFraction, sequenceRepetitions,
       prepareSlowDAC, slowDACStepsPerFrame, slowDACStepsPerSequence, samplesPerSlowDACStep,
       enableDACLUT, setLookupLUT, setConstantLUT, setPauseLUT, setRangeLUT, numSlowDACChan,
       appendSequence, popSequence, clearSequences, prepareSequence, numLostStepsSlowADC

struct DACPerformanceData
  uDeltaControl::UInt8
  uDeltaSet::UInt8
  minDeltaControl::UInt8
  maxDeltaSet::UInt8
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
function amplitudeDAC(rp::RedPitaya, channel, component, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":AMP ", Float64(value))
  return send(rp, command)
end

function amplitudeDACNext(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":Next:AMP?")
  return query(rp, command, Float64)
end
function amplitudeDACNext(rp::RedPitaya, channel, component, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":Next:AMP ", Float64(value))
  return send(rp, command)
end

function offsetDAC(rp::RedPitaya, channel)
  command = string("RP:DAC:CH", Int(channel)-1, ":OFF?")
  return query(rp, command, Float64)
end
function offsetDAC(rp::RedPitaya, channel, value)
  if value > 1.0
    error("$value is larger than 1.0 V!")
  end
  command = string("RP:DAC:CH", Int(channel)-1, ":OFF ", Float64(value))
  return send(rp, command)
end

function frequencyDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":FREQ?")
  return query(rp, command, Float64)
end
function frequencyDAC(rp::RedPitaya, channel, component, value)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":FREQ ", Float64(value))
  send(rp, command)
end

function phaseDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":PHA?")
  return query(rp, command, Float64)
end
function phaseDAC(rp::RedPitaya, channel, component, value)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":PHA ", Float64(value))
  send(rp, command)
end

function jumpSharpnessDAC(rp::RedPitaya, channel)
  command = string("RP:DAC:CH", Int(channel)-1, ":JumpSharpness?")
  return query(rp, command, Float64)
end
function jumpSharpnessDAC(rp::RedPitaya, channel, value)
  command = string("RP:DAC:CH", Int(channel)-1, ":JumpSharpness ", Float64(value))
  send(rp, command)
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

function signalTypeDAC(rp::RedPitaya, channel, sigType::String)
  if !(sigType in ["SINE","SQUARE","TRIANGLE","SAWTOOTH"] )
    error("Signal type $sigType not supported!")
  end

  command = string("RP:DAC:CH", Int(channel)-1, ":SIGnaltype ", sigType)
  return send(rp, command)
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

function setLookupLUT(rp::RedPitaya, lut::Array)
  lutFloat32 = map(Float32, lut)
  send(rp, string("RP:DAC:SEQ:LUT:LOOKUP"))
  @debug "Writing slow DAC LUT"
  write(rp.dataSocket, lutFloat32)
end

function setConstantLUT(rp::RedPitaya, lut::Array)
  lutFloat32 = map(Float32, lut)
  send(rp, string("RP:DAC:SEQ:LUT:CONSTANT"))
  @debug "Writing slow DAC LUT"
  write(rp.dataSocket, lutFloat32)
end

function setPauseLUT(rp::RedPitaya)
  send(rp, string("RP:DAC:SEQ:LUT:PAUSE"))
end

function setRangeLUT(rp::RedPitaya, lut::Array)
  lutFloat32 = map(Float32, lut)
  send(rp, string("RP:DAC:SEQ:LUT:RANGE"))
  @debug "Writing slow DAC LUT"
  write(rp.dataSocket, lutFloat32)
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
  samplesPerSlowDACStep(rp, samplesPerStep)
  slowDACStepsPerSequence(rp, stepsPerFrame) # Sets PDMClockDivider
end

function rampUp(rp::RedPitaya, rampUpTime::Float64, rampUpFraction::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing ", rampUpTime, ",", rampUpFraction))
end

rampUpTime(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:TIME?", Float64)
function rampUpTime(rp::RedPitaya, value::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:TIME ", value))
end

rampUpFraction(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:RaMPing:FRACtion?", Float64)
function rampUpFraction(rp::RedPitaya, value::Float64)
  send(rp, string("RP:DAC:SEQ:RaMPing:FRACtion ", value))
end

sequenceRepetitions(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:REPetitions?", Int32)
function sequenceRepetitions(rp::RedPitaya, value::Int)
  send(rp, string("RP:DAC:SEQ:REPetitions ", value))
end

appendSequence(rp::RedPitaya) = send(rp, "RP:DAC:SEQ:APPend")
popSequence(rp::RedPitaya) = send(rp, "RP:DAC:SEQ:POP")
clearSequences(rp::RedPitaya) = send(rp, "RP:DAC:SEQ:CLEAR")
prepareSequence(rp::RedPitaya) = query(rp, "RP:DAC:SEQ:PREPare?", Bool)
