export setSlowDAC, getSlowADC

function setSlowDAC(rp::RedPitaya, channel, value)
  command = string("RP:PDM:CHannel", Int64(channel), ":NextValueVolt ", value)
  send(rp, command)
end

function getSlowADC(rp::RedPitaya, channel)
  command = string("RP:XADC:CHannel", Int64(channel), "?")
  query(rp, command, Float64)
end
