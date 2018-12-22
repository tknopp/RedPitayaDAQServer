export amplitudeDAC, frequencyDAC, modulusFactorDAC, phaseDAC, modeDAC, modulusDAC

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

function modulusFactorDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":FAC?")
  return query(rp, command, Int64)
end
function modulusFactorDAC(rp::RedPitaya, channel, component, value)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":FAC ", Int64(value))
  return send(rp, command)
end

function modulusDAC(rp::RedPitaya, channel, component)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP", Int(component)-1, ":MOD?")
  return query(rp, command, Int64)
end
function modulusDAC(rp::RedPitaya, channel, component, value)
  command = string("RP:DAC:CH", Int(channel)-1, ":COMP",
                   Int(component)-1, ":MOD ", Int64(value))
  return send(rp, command)
end

#"STANDARD" or "RASTERIZED"
function modeDAC(rp::RedPitaya, channel=1)
  #return query(rp, "RP:DAC:CH:", Int(channel)-1,"MODe?")[2:end-1]
  return query(rp, "RP:DAC:MODe?")[2:end-1]
end
function modeDAC(rp::RedPitaya, mode::String)
  #send(rp, string("RP:DAC:CH", 0,":MODe ", mode))
  #send(rp, string("RP:DAC:CH", 1,":MODe ", mode))
  send(rp, string("RP:DAC:MODe ", mode))
end
