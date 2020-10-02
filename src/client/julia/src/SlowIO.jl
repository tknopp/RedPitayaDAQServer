export setSlowDAC, getSlowADC, slowDACClockDivider, DIO, DIODirection

function setSlowDAC(rp::RedPitaya, channel, value)
  command = string("RP:PDM:CHannel", Int64(channel), ":NextValueVolt ", value)
  send(rp, command)
end

function getSlowADC(rp::RedPitaya, channel)
  command = string("RP:XADC:CHannel", Int64(channel), "?")
  query(rp, command, Float64)
end


slowDACClockDivider(rp::RedPitaya) = query(rp,"RP:PDM:ClockDivider?", Int64)
function slowDACClockDivider(rp::RedPitaya, value)
  command = string("RP:PDM:ClockDivider ", Int32(value))
  send(rp, command)
end

function isValidPin(pin::String)
  pin in ["DIO7_P", "DIO7_N", "DIO6_P", "DIO6_N", "DIO5_N","DIO4_N","DIO3_N","DIO2_N"]
end

function DIODirection(rp::RedPitaya, pin::String, val::String)
  if !isValidPin(pin)
    error("RP pin $(pin) is not available!")
  end

  if val != "IN" && val != "OUT"
    error("value needs to be IN or OUT!")
  end

  send(rp, string("RP:DIO:DIR ", pin, ",", val))
  return
end



function DIO(rp::RedPitaya, pin::String, val::Bool)
  if !isValidPin(pin)
    error("RP pin $(pin) is not available!")
  end

  DIODirection(rp, pin, "OUT")

  valStr = val ? "ON" : "OFF"
  send(rp, string("RP:DIO ", pin, ",", valStr))
  return
end

function DIO(rp::RedPitaya, pin::String)
  if !isValidPin(pin)
    error("RP pin $(pin) is not available!")
  end

  DIODirection(rp, pin, "IN")

  return occursin("ON", query(rp,"RP:DIO? $(pin)"))
end