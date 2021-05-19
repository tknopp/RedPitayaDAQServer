export eepromField, resetEEPROM

function eepromField(rp::RedPitaya, field::AbstractString, val::Integer)
  send(rp, "RP:CALib $field,$val")
end
eepromField(rp::RedPitaya, field::AbstractString) = query(rp, "RP:CALib? $field", Int64)

resetEEPROM(rp::RedPitaya) = send(rp, "RP:CALib:RESet")