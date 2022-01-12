module RedPitayaDAQServer

# package code goes here

using Base: UInt16
using Sockets
import Sockets: send, connect

using Statistics
using LinearAlgebra

import Base: reset, iterate, length

export RedPitaya, send, receive, query, start, stop, disconnect, getLog

"""
    RedPitaya(ip [, port = 5025, isMaster = false])

Create a `RedPitaya` (i.e. a connection to a RedPitayaDAQServer server) which is the central structure of
the Julia client library.

Used to communicate with the server and manage the connection and metadata. During the construction the connection
is established and the calibration values are loaded from the RedPitayas EEPROM.
Throws an error if a timeout occurs while attempting to connect.

# Examples
```julia
julia> rp = RedPitaya("192.168.1.100");

julia> decimation(rp, 8)

julia> decimation(rp)
8
```
"""
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
  calib::Array{Float32}
end

# Iterable Interface

length(rp::RedPitaya) = 1
iterate(rp::RedPitaya, state=1) = state > 1 ? nothing : (rp, state + 1)

"""
    send(rp, cmd)

Send a command to the RedPitaya
"""
function send(rp::RedPitaya,cmd::String)
  @debug "send command: " cmd
  write(rp.socket,cmd*rp.delim)
end

const _timeout = 5.0

"""
    receive(rp)

Receive a String from the RedPitaya command socket. Reads until a whole line is received
"""
function receive(rp::RedPitaya)
  return readline(rp.socket)[1:end]
end

"""
    query(rp::RedPitaya, cmd [, timeout = 5.0, N = 100])

Send a query to the RedPitaya command socket. Return reply as String.

Waits for `timeout` seconds and checks every `timeout/N` seconds.

See also [receive](@ref).
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
    query(rp::RedPitaya, cmd, T::Type [timeout = 5.0, N = 100])

Send a query to the RedPitaya. Parse reply as `T`.

Waits for `timeout` seconds and checks every `timeout/N` seconds.
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
    rp.dataSocket = connect(rp.host, 5026, _timeout)
    rp.isConnected = true
    updateCalib(rp)
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

function stringToEnum(enumType::Type{T}, value::AbstractString) where {T <: Enum}
  stringInstances = string.(instances(enumType))
  # If lowercase is not sufficient one could try Unicode.normalize with casefolding
  index = findfirst(isequal(lowercase(value)), lowercase.(stringInstances))
  if isnothing(index)
    throw(ArgumentError("$value cannot be resolved to an instance of $(typeof(enumType)). Possible instances are: " * join(stringInstances, ", ", " and ")))
  end
  return instances(enumType)[index]
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

  rp = RedPitaya(host,"\n", TCPSocket(), TCPSocket(), 1, 1, 1, false, isMaster, false, zeros(Float32, 2, 2))

  connect(rp)

  #rp.decimation = decimation(rp)
  #rp.samplesPerPeriod = samplesPerPeriod(rp)
  #rp.periodsPerFrame = periodsPerFrame(rp)

  finalizer(d -> destroy(d), rp)
  return rp
end

end # module
