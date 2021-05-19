module RedPitayaDAQServer

# package code goes here

using Sockets
import Sockets: send, connect

using Statistics
using LinearAlgebra

import Base: reset, iterate, length

export RedPitaya, send, receive, query, start, stop, disconnect, getLog

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

"""
Receive a String from the RedPitaya
"""
function receive(rp::RedPitaya)
  return readline(rp.socket)[1:end] 
end

"""
Perform a query with the RedPitaya. Return String
"""
function query(rp::RedPitaya, cmd::String, timeout::Number=2.0,  N=100)
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
function query(rp::RedPitaya,cmd::String,T::Type)
  a = query(rp,cmd)
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

const _timeout = 1.0

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
include("EEPROM.jl")

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

end # module
