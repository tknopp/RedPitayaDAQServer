export eepromField, resetEEPROM, calibDACOffset

function eepromField(rp::RedPitaya, field::AbstractString, val::Integer)
  send(rp, "RP:CALib $field,$val")
end
eepromField(rp::RedPitaya, field::AbstractString) = query(rp, "RP:CALib? $field", Int64)

resetEEPROM(rp::RedPitaya) = send(rp, "RP:CALib:RESet")

function calibDACOffset(rp::RedPitaya, channel::Integer, val)
  if val > 1.0
    error("$val is larger than 1.0 V!")
  end
  command = string("RP:CALib:DAC:CH", Int(channel) - 1, ":OFF $(Float32(val))")
  return send(rp, command)
end
calibDACOffset(rp::RedPitaya, channel::Integer) = query(rp, string("RP:CALib:DAC:CH", Int(channel) - 1, ":OFF?"), Float64)