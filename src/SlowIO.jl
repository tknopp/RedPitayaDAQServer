export setSlowDAC, getSlowADC, slowDACClockDivider

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
