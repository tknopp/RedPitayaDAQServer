export calibDACOffset, calibADCScale, calibADCOffset

#=function eepromField(rp::RedPitaya, field::AbstractString, val::Integer)
  send(rp, "RP:CALib $field,$val")
end
eepromField(rp::RedPitaya, field::AbstractString) = query(rp, "RP:CALib? $field", Int64)

resetEEPROM(rp::RedPitaya) = send(rp, "RP:CALib:RESet")=#

function calibDACOffset(rp::RedPitaya, channel::Integer, val)
  if val > 1.0
    error("$val is larger than 1.0 V!")
  end
  command = string("RP:CALib:DAC:CH", Int(channel) - 1, ":OFF $(Float32(val))")
  return send(rp, command)
end
calibDACOffset(rp::RedPitaya, channel::Integer) = query(rp, string("RP:CALib:DAC:CH", Int(channel) - 1, ":OFF?"), Float64)

function calibADCOffset(rp::RedPitaya, channel::Integer, val)
  if val > 1.0
    error("$val is larger than 1.0 V!")
  end
  command = string("RP:CALib:ADC:CH", Int(channel) - 1, ":OFF $(Float32(val))")
  rp.calib[2, channel] = Float32(val)
  return send(rp, command)
end
calibADCOffset(rp::RedPitaya, channel::Integer) = query(rp, string("RP:CALib:ADC:CH", Int(channel) - 1, ":OFF?"), Float64)

function calibADCScale(rp::RedPitaya, channel::Integer, val)
  if val > 1.0
    error("$val is larger than 1.0 V!")
  end
  command = string("RP:CALib:ADC:CH", Int(channel) - 1, ":SCA $(Float32(val))")
  rp.calib[1, channel] = Float32(val)
  return send(rp, command)
end
calibADCScale(rp::RedPitaya, channel::Integer) = query(rp, string("RP:CALib:ADC:CH", Int(channel) - 1, ":SCA?"), Float64)