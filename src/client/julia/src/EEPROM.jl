export calibDACOffset, calibDACOffset!, calibADCScale, calibADCScale!, calibADCOffset, calibADCOffset!, updateCalib!, calibDACScale!, calibDACScale, calibFlags, calibDACLowerLimit, calibDACLowerLimit!, calibDACUpperLimit, calibDACUpperLimit!, calibDACLimit!

"""
    calibDACOffset!(rp::RedPitaya, channel::Integer, val)

Store calibration DAC offset `val` for given channel into the RedPitayas EEPROM. 
This value is used by the server to offset the output voltage. Absolute value has to be smaller than 1.0 V. 
"""
function calibDACOffset!(rp::RedPitaya, channel::Integer, val)
  if abs(val) > 1.0
    error("Absolute value of $val is larger than 1.0 V!")
  end
  return query(rp, scpiCommand(calibDACOffset!, channel, val), scpiReturn(calibDACOffset!))
end
scpiCommand(::typeof(calibDACOffset!), channel::Integer, val) = string("RP:CALib:DAC:CH", Int(channel) - 1, ":OFF $(Float32(val))")
scpiReturn(::typeof(calibDACOffset!)) = Bool

"""
    calibDACOffset(rp::RedPitaya, channel::Integer)

Retrieve the calibration DAC offset for given channel from the RedPitayas EEPROM 
"""
calibDACOffset(rp::RedPitaya, channel::Integer) = query(rp, scpiCommand(calibDACOffset, channel), scpiReturn(calibDACOffset))
scpiCommand(::typeof(calibDACOffset), channel::Integer) = string("RP:CALib:DAC:CH", Int(channel) - 1, ":OFF?")
scpiReturn(::typeof(calibDACOffset)) = Float64

"""
    calibDACScale(rp::RedPitaya, channel::Integer)

Store calibration DAC scale `val` for given channel into the RedPitayas EEPROM.
This value is used by the server to scale the output voltage.
"""
function calibDACScale!(rp::RedPitaya, channel::Integer, val)
  return query(rp, scpiCommand(calibDACScale!, channel, val), scpiReturn(calibDACScale!))
end
scpiCommand(::typeof(calibDACScale!), channel::Integer, val) = string("RP:CALib:DAC:CH", Int(channel) - 1, ":SCA $(Float32(val))")
scpiReturn(::typeof(calibDACScale!)) = Bool

"""
    calibDACScale(rp::RedPitaya, channel::Integer)

Retrieve the calibration DAC scale for given channel from the RedPitayas EEPROM.
"""
calibDACScale(rp::RedPitaya, channel::Integer) = query(rp, scpiCommand(calibDACScale, channel), scpiReturn(calibDACScale))
scpiCommand(::typeof(calibDACScale), channel::Integer) = string("RP:CALib:DAC:CH", Int(channel) - 1, ":SCA?")
scpiReturn(::typeof(calibDACScale)) = Float64

"""
    calibDACLowerLimit!(rp::RedPitaya, channel::Integer)

Store calibration DAC lower limit `val` for given channel into the RedPitayas EEPROM.
This value is used by the server to limit the output voltage.
"""
function calibDACLowerLimit!(rp::RedPitaya, channel::Integer, val)
  return query(rp, scpiCommand(calibDACLowerLimit!, channel, val), scpiReturn(calibDACLowerLimit!))
end
scpiCommand(::typeof(calibDACLowerLimit!), channel::Integer, val) = string("RP:CALib:DAC:CH", Int(channel) - 1, ":LIM:LOW $(Float32(val))")
scpiReturn(::typeof(calibDACLowerLimit!)) = Bool

"""
    calibDACLowerLimit(rp::RedPitaya, channel::Integer)

Retrieve the calibration DAC lower limit for given channel from the RedPitayas EEPROM.
"""
calibDACLowerLimit(rp::RedPitaya, channel::Integer) = query(rp, scpiCommand(calibDACLowerLimit, channel), scpiReturn(calibDACLowerLimit))
scpiCommand(::typeof(calibDACLowerLimit), channel::Integer) = string("RP:CALib:DAC:CH", Int(channel) - 1, ":LIM:LOW?")
scpiReturn(::typeof(calibDACLowerLimit)) = Float64

"""
    calibDACUpperLimit!(rp::RedPitaya, channel::Integer)

Store calibration DAC upper limit `val` for given channel into the RedPitayas EEPROM.
This value is used by the server to limit the output voltage.
"""
function calibDACUpperLimit!(rp::RedPitaya, channel::Integer, val)
  return query(rp, scpiCommand(calibDACUpperLimit!, channel, val), scpiReturn(calibDACUpperLimit!))
end
scpiCommand(::typeof(calibDACUpperLimit!), channel::Integer, val) = string("RP:CALib:DAC:CH", Int(channel) - 1, ":LIM:UP $(Float32(val))")
scpiReturn(::typeof(calibDACUpperLimit!)) = Bool

"""
    calibDACUpperLimit(rp::RedPitaya, channel::Integer)

Retrieve the calibration DAC upper limit for given channel from the RedPitayas EEPROM.
"""
calibDACUpperLimit(rp::RedPitaya, channel::Integer) = query(rp, scpiCommand(calibDACUpperLimit, channel), scpiReturn(calibDACUpperLimit))
scpiCommand(::typeof(calibDACUpperLimit), channel::Integer) = string("RP:CALib:DAC:CH", Int(channel) - 1, ":LIM:UP?")
scpiReturn(::typeof(calibDACUpperLimit)) = Float64

"""
    calibDACLimit!(rp::RedPitaya, channel, val)

Applies `val` with a positive sign as the upper and with a negative sign as the lower calibration DAC limit.

See also [calibDACUpperLimit!](@ref), [calibDACLowerLimit!](@ref)
"""
function calibDACLimit!(rp::RedPitaya, channel::Integer, val)
  val = abs(val)
  result = calibDACLowerLimit!(rp, channel, -val)
  result &= calibDACUpperLimit!(rp, channel, val)
  return result
end

"""
    calibADCOffset!(rp::RedPitaya, channel::Integer, val)

Store calibration ADC offset `val` for given channel into the RedPitayas EEPROM.
Absolute value has to be smaller than 1.0 V.

See also [convertSamplesToPeriods!](@ref),[convertSamplesToFrames](@ref).
"""
function calibADCOffset!(rp::RedPitaya, channel::Integer, val)
  if abs(val) > 1.0
    error("Absolute value of $val is larger than 1.0 V!")
  end
  rp.calib[2, channel] = Float32(val)
  return query(rp, scpiCommand(calibADCOffset!, channel, val), scpiReturn(calibADCOffset!))
end
scpiCommand(::typeof(calibADCOffset!), channel::Integer, val) = string("RP:CALib:ADC:CH", Int(channel) - 1, ":OFF $(Float32(val))")
scpiReturn(::typeof(calibADCOffset!)) = Bool

"""
    calibADCOffset(rp::RedPitaya, channel::Integer)

Retrieve the calibration ADC offset for given channel from the RedPitayas EEPROM.

See also [convertSamplesToPeriods!](@ref),[convertSamplesToFrames](@ref).
"""
calibADCOffset(rp::RedPitaya, channel::Integer) = query(rp, scpiCommand(calibADCOffset, channel), scpiReturn(calibADCOffset))
scpiCommand(::typeof(calibADCOffset), channel::Integer) = string("RP:CALib:ADC:CH", Int(channel) - 1, ":OFF?")
scpiReturn(::typeof(calibADCOffset)) = Float64

"""
    calibADCScale(rp::RedPitaya, channel::Integer)

Store calibration ADC scale `val` for given channel into the RedPitayas EEPROM.
See also [convertSamplesToPeriods!](@ref),[convertSamplesToFrames](@ref).
"""
function calibADCScale!(rp::RedPitaya, channel::Integer, val)
  rp.calib[1, channel] = Float32(val)
  return query(rp, scpiCommand(calibADCScale!, channel::Integer, val), scpiReturn(calibADCScale!))
end
scpiCommand(::typeof(calibADCScale!), channel, val) = string("RP:CALib:ADC:CH", Int(channel) - 1, ":SCA $(Float32(val))")
scpiReturn(::typeof(calibADCScale!)) = Bool

"""
    calibADCScale(rp::RedPitaya, channel::Integer)

Retrieve the calibration ADC scale for given channel from the RedPitayas EEPROM.

See also [convertSamplesToPeriods!](@ref),[convertSamplesToFrames](@ref).
"""
calibADCScale(rp::RedPitaya, channel::Integer) = query(rp, scpiCommand(calibADCScale, channel), scpiReturn(calibADCScale))
scpiCommand(::typeof(calibADCScale), channel::Integer) = string("RP:CALib:ADC:CH", Int(channel) - 1, ":SCA?")
scpiReturn(::typeof(calibADCScale)) = Float64

calibFlags(rp::RedPitaya) = query(rp, scpiCommand(calibFlags), scpiReturn(calibFlags))
scpiCommand(::typeof(calibFlags)) = "RP:CALib:FLAGs"
scpiReturn(::typeof(calibFlags)) = Int64

"""
    updateCalib!(rp::RedPitaya)

Update the cached calibration values.

See also [calibADCScale](@ref), [calibADCOffset](@ref).
"""
function updateCalib!(rp::RedPitaya)
  rp.calib[1, 1] = calibADCScale(rp, 1)
  rp.calib[2, 1] = calibADCOffset(rp, 1)
  rp.calib[1, 2] = calibADCScale(rp, 2)
  rp.calib[2, 2] = calibADCOffset(rp, 2)
end