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
    socket = connect(host,port)
    #return new("\r\n", socket)
    return new(host,"\n", socket)
  end
end

"""
Send a command to the RedPitaya
"""
function send(rp::RedPitaya,cmd::String)
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

function test()

  rp = RedPitaya("192.168.1.9",5025)

  decimation = 16
  frequency = 25000
  base_frequency = 125000000
  samples_per_period_base = base_frequency/frequency
  samples_per_period = samples_per_period_base/decimation

  samples_per_period = samples_per_period*2
  periods_per_frame = 1

  send(rp, "RP:ADC:PERiod $(samples_per_period)")
  send(rp, "RP:ADC:FRAme $(periods_per_frame)")
  send(rp, "RP:ADC:DECimation $(decimation)")
  #send(rp, "RP:DAC:CH0:COMP0:FREQ $(frequency)")
  send(rp, "RP:DAC:CH0:COMP0:AMP 400");
  send(rp, "RP:MasterTrigger OFF");
  send(rp, "RP:RamWriterMode TRIGGERED");
  send(rp, "RP:ADC:ACQCONNect");


  socket = connect(rp.host,5026)

  # Communicating with instrument object, cli.
  send(rp, "RP:ADC:ACQSTATUS ON")
  send(rp, "RP:MasterTrigger ON")

  send(rp, "RP:ADC:FRAMES:CURRENT?")


  ###currect_frame = str2num(char(strtrim(string(query(cli, 'RP:ADC:FRAMES:CURRENT?\n')))));
  ###fprintf(cli, 'RP:ADC:FRAMES:DATA %d,1\n', currect_frame);

  #data = int32(zeros(1, samples_per_period*periods_per_frame));
  ###data = int32(fread(con, 300*samples_per_period*periods_per_frame, 'int32'));

  ###currect_frame = str2num(char(strtrim(string(query(cli, 'RP:ADC:FRAMES:CURRENT?\n')))))

  send(rp, "RP:MasterTrigger OFF");

  ###close(socket)



end


include("Commands.jl")

end # module
