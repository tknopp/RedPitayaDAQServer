module RedPitayaDAQServer

# package code goes here

import Base: send, start, reset

export RedPitaya, receive, query, stop

type RedPitaya
  host::String
  delim::String
  socket::TCPSocket
  dataSocket::TCPSocket

  function RedPitaya(host, port=5025)
    socket = connect(host, port)
    #return new("\r\n", socket)
    dataSocket = connect(host, 5026)
    return new(host,"\n", socket, dataSocket)
  end
end

"""
Send a command to the RedPitaya
"""
function send(rp::RedPitaya,cmd::String)
  println("send command: ", cmd)
  write(rp.socket,cmd*rp.delim)
end

"""
Receive a String from the RedPitaya
"""
function receive(rp::RedPitaya)
  readline(rp.socket)[1:end] #-2
end

"""
Perform a query with the RedPitaya. Return String
"""
function query(rp::RedPitaya,cmd::String)
  send(rp,cmd)
  return receive(rp)
end

"""
Perform a query with the RedPitaya. Parse result as type T
"""
function query(rp::RedPitaya,cmd::String,T::Type)
  a = query(rp,cmd)
  return parse(T,a)
end


#=
{.pattern = "RP:DAC:CHannel#:COMPonent#:AMPlitude?", .callback = RP_DAC_GetAmplitude,},
 {.pattern = "RP:DAC:CHannel#:COMPonent#:AMPlitude", .callback = RP_DAC_SetAmplitude,},
 {.pattern = "RP:DAC:CHannel#:COMPonent#:FREQuency?", .callback = RP_DAC_GetFrequency,},
 {.pattern = "RP:DAC:CHannel#:COMPonent#:FREQuency", .callback = RP_DAC_SetFrequency,},
 {.pattern = "RP:DAC:CHannel#:COMPonent#:FACtor?", .callback = RP_DAC_GetModulusFactor,},
 {.pattern = "RP:DAC:CHannel#:COMPonent#:FACtor", .callback = RP_DAC_SetModulusFactor,},
 {.pattern = "RP:DAC:CHannel#:COMPonent#:PHAse?", .callback = RP_DAC_GetPhase,},
 {.pattern = "RP:DAC:CHannel#:COMPonent#:PHAse", .callback = RP_DAC_SetPhase,},
 {.pattern = "RP:DAC:MODe", .callback = RP_DAC_SetDACMode,},
 {.pattern = "RP:DAC:MODe?", .callback = RP_DAC_GetDACMode,},
 {.pattern = "RP:DAC:CHannel#:COMPonent#:MODulus", .callback = RP_DAC_ReconfigureDACModulus,},
 {.pattern = "RP:DAC:CHannel#:COMPonent#:MODulus?", .callback = RP_DAC_GetDACModulus,},
 {.pattern = "RP:ADC:DECimation", .callback = RP_ADC_SetDecimation,},
 {.pattern = "RP:ADC:DECimation?", .callback = RP_ADC_GetDecimation,},
 {.pattern = "RP:ADC:PERiod", .callback = RP_ADC_SetSamplesPerPeriod,},
 {.pattern = "RP:ADC:PERiod?", .callback = RP_ADC_GetSamplesPerPeriod,},
 {.pattern = "RP:ADC:FRAme", .callback = RP_ADC_SetPeriodsPerFrame,},
 {.pattern = "RP:ADC:FRAme?", .callback = RP_ADC_GetPeriodsPerFrame,},
 {.pattern = "RP:ADC:FRAmes:CURRent?", .callback = RP_ADC_GetCurrentFrame,},
 {.pattern = "RP:ADC:FRAmes:DATa", .callback = RP_ADC_GetFrames,},
 {.pattern = "RP:ADC:ACQCONNect", .callback = RP_ADC_StartAcquisitionConnection,},
 {.pattern = "RP:ADC:ACQSTATus", .callback = RP_ADC_SetAcquisitionStatus,},
 {.pattern = "RP:PDM:CHannel#:NextValue", .callback = RP_PDM_SetPDMNextValue,},
 {.pattern = "RP:PDM:CHannel#:NextValue?", .callback = RP_PDM_GetPDMNextValue,},
 {.pattern = "RP:PDM:CHannel#:CurrentValue?", .callback = RP_PDM_GetPDMCurrentValue,},
 {.pattern = "RP:XADC:CHannel#?", .callback = RP_XADC_GetXADCValueVolt,},
 {.pattern = "RP:WatchDogMode", .callback = RP_WatchdogMode,},
 {.pattern = "RP:RamWriterMode", .callback = RP_RAMWriterMode,},
 {.pattern = "RP:MasterTrigger", .callback = RP_MasterTrigger,},
 {.pattern = "RP:InstantResetMode", .callback = RP_InstantResetMode,},
 {.pattern = "RP:PeripheralAResetN?", .callback = RP_PeripheralAResetN,},
 {.pattern = "RP:FourierSynthAResetN?", .callback = RP_FourierSynthAResetN,},
 {.pattern = "RP:PDMAResetN?", .callback = RP_PDMAResetN,},
 {.pattern = "RP:WriteToRAMAResetN?", .callback = RP_WriteToRAMAResetN,},
 {.pattern = "RP:XADCAResetN?", .callback = RP_XADCAResetN,},
 {.pattern = "RP:TriggerStatus?", .callback = RP_TriggerStatus,},
 {.pattern = "RP:WatchdogStatus?", .callback = RP_WatchdogStatus,},
 {.pattern = "RP:InstantResetStatus?", .callback = RP_InstantResetStatus,},
 =#

include("ADC.jl")
include("DAC.jl")

end # module
