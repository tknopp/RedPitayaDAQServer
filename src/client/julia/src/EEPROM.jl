export calibDACOffset, calibADCScale, calibADCOffset, updateCalib

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

function updateCalib(rp::RedPitaya)
  rp.calib[1, 1] = calibADCScale(rp, 1)
  rp.calib[2, 1] = calibADCOffset(rp, 1)
  rp.calib[1, 2] = calibADCScale(rp, 2)
  rp.calib[2, 2] = calibADCOffset(rp, 2)
end