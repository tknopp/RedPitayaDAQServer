export amplitudeDAC, frequencyDAC, phaseDAC, modeDAC,
       DCSignDAC, signalTypeDAC, offsetDAC, jumpSharpnessDAC, passPDMToFastDAC

function passPDMToFastDAC(rp::RedPitaya, val::Bool)
  valStr = val ? "ON" : "OFF"
  send(rp, string("RP:PassPDMToFastDAC ", valStr))
end
passPDMToFastDAC(rp::RedPitaya) = occursin("ON", query(rp,"RP:PassPDMToFastDAC?"))

# TODO: make this Float64
function amplitudeDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":AMP?")
  return query(rp, command, Int64)
end
function amplitudeDAC(rp::RedPitaya, channel, component, value)
  if value > 8191
    error("$value is larger than 8191!")
  end
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":AMP ", Int64(value))
  return send(rp, command)
end

function offsetDAC(rp::RedPitaya, channel)
  command = string("RP:DAC:CH", Int(channel)-1, ":OFF?")
  return query(rp, command, Int64)
end
function offsetDAC(rp::RedPitaya, channel, value)
  if value > 8191
    error("$value is larger than 8191!")
  end
  command = string("RP:DAC:CH", Int(channel)-1, ":OFF ", Int64(value))
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
