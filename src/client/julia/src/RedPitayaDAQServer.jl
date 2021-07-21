module RedPitayaDAQServer

# package code goes here

using Base: UInt16
using Sockets
import Sockets: send, connect

using Statistics
using LinearAlgebra

import Base: reset, iterate, length

export RedPitaya, receive, query, start, stop, disconnect, getLog

mutable struct RedPitaya
  host::String
  delim::String
  socket::TCPSocket
  dataSocket::TCPSocket
  decimation::Int64
  samplesPerPeriod::Int64
  periodsPerFrame::Int64
  isConnected::Bool
  isMaster::Bool
  destroyed::Bool
end

# Iterable Interface

length(rp::RedPitaya) = 1
iterate(rp::RedPitaya, state=1) = state > 1 ? nothing : (rp, state + 1)

"""
Send a command to the RedPitaya
"""
function send(rp::RedPitaya,cmd::String)
  @debug "send command: " cmd
  write(rp.socket,cmd*rp.delim)
end

const _timeout = 5.0

"""
Receive a String from the RedPitaya
"""
function receive(rp::RedPitaya)
  return readline(rp.socket)[1:end]
end

"""
Perform a query with the RedPitaya. Return String
"""
function query(rp::RedPitaya, cmd::String, timeout::Number=_timeout,  N=100)
  send(rp,cmd)
  t = @async receive(rp)
  for i=1:N
    if istaskdone(t)
      return fetch(t)
    end
    sleep(timeout / N )
  end
  @async Base.throwto(t, EOFError())
  error("Receive ran into timeout on RP $(rp.host) on command $(cmd)!")
end

"""
Perform a query with the RedPitaya. Parse result as type T
"""
function query(rp::RedPitaya,cmd::String,T::Type, timeout::Number=_timeout, N::Number=100)
  a = query(rp,cmd, timeout, N)
  return parse(T,a)
end

# connect with timeout implementation
function Sockets.connect(host, port::Integer, timeout::Number)
  s = TCPSocket()
  t = Timer(_ -> close(s), timeout)
  try
    connect(s, host, port)
  catch e
    error("Could not connect to $(host) on port $(port) 
            since the operations was timed out after $(timeout) seconds!")
  finally
    close(t)
  end
  return s
end

function connect(rp::RedPitaya)
  if !rp.isConnected
    begin
    rp.socket = connect(rp.host, 5025, _timeout)
    send(rp, string("RP:Init"))
    connectADC(rp)
    rp.dataSocket = connect(rp.host, 5026, _timeout)
    rp.isConnected = true
    decimation(rp)
    end
  end
end

function disconnect(rp::RedPitaya)
  if rp.isConnected && !rp.destroyed
    @async begin
      close(rp.socket)
      close(rp.dataSocket)
      rp.isConnected = false
    end
  end
  return nothing
end

function getLog(rp::RedPitaya, log)
  command = "RP:LOG?"
  send(rp, command)
  chunk_size = 1024
  size = read(rp.dataSocket, Int64)
  recv = 0
  while (recv != size)
    buff = read(rp.dataSocket, min(chunk_size, size - recv))
    recv = recv + length(buff)
    write(log, buff)
  end
  close(log)
end

include("DAC.jl")
include("ADC.jl")
include("Cluster.jl")
include("SlowIO.jl")

function destroy(rp::RedPitaya)
  disconnect(rp)
  rp.destroyed = true
end

function RedPitaya(host, port=5025, isMaster=true)

  rp = RedPitaya(host,"\n", TCPSocket(), TCPSocket(), 1, 1, 1, false, isMaster, false)

  connect(rp)

  #rp.decimation = decimation(rp)
  #rp.samplesPerPeriod = samplesPerPeriod(rp)
  #rp.periodsPerFrame = periodsPerFrame(rp)

  finalizer(d -> destroy(d), rp)
  return rp
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



end # module