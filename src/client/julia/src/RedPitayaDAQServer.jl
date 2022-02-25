module RedPitayaDAQServer

# package code goes here

using Base: UInt16
using Sockets
import Sockets: send, connect

using Statistics
using LinearAlgebra

import Base: reset, iterate, length

export RedPitaya, send, receive, query, start, stop, disconnect, ServerMode, serverMode, serverMode!, CONFIGURATION, MEASUREMENT, TRANSMISSION, getLog

"""
    RedPitaya

Struct representing a connection to a RedPitayaDAQServer.

Contains the sockets used for communication and connection related metadata. Also contains fields for 
client specific concepts such as periods, frames and calibration values. 
"""
mutable struct RedPitaya
  host::String
  port::Int64
  dataPort::Int64
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
    send(rp::RedPitaya, cmd::String)

Send a command to the RedPitaya. Appends delimiter.
"""
function send(rp::RedPitaya,cmd::String)
  @debug "send command: " cmd
  write(rp.socket,cmd*rp.delim)
end

const _timeout = 5.0

"""
    receive(rp::RedPitaya)

Receive a String from the RedPitaya command socket. Reads until a whole line is received
"""
function receive(rp::RedPitaya)
  return readline(rp.socket)[1:end]
end

function receive(rp::RedPitaya, timeout::Number,  N=100)
  t = @async receive(rp)
  for i=1:N
    if istaskdone(t)
      return fetch(t)
    end
    sleep(timeout / N )
  end
  @async Base.throwto(t, EOFError())
  error("Receive ran into timeout on RP $(rp.host)!")
  return t
end

"""
    query(rp::RedPitaya, cmd [, timeout = 5.0, N = 100])

Send a query to the RedPitaya command socket. Return reply as String.

Waits for `timeout` seconds and checks every `timeout/N` seconds.

See also [receive](@ref).
"""
function query(rp::RedPitaya, cmd::String, timeout::Number=_timeout,  N=100)
  send(rp,cmd)
  receive(rp, timeout, N)
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
    Sockets.connect(s, host, port)
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
    rp.socket = connect(rp.host, rp.port, _timeout)
    rp.dataSocket = connect(rp.host, rp.dataPort, _timeout)
    rp.isConnected = true
    updateCalib!(rp)
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

"""
    ServerMode

Represent the different modes the server can be in. Valid values are `CONFIGURATION`, `MEASUREMENT` and `TRANSMISSION`.

See also [`serverMode`](@ref), [`serverMode!`](@ref).
"""
@enum ServerMode CONFIGURATION MEASUREMENT TRANSMISSION

"""
    serverMode(rp::RedPitaya)

Return the mode of the server.

# Examples
```julia
julia> serverMode!(rp, MEASUREMENT);
true

julia> serverMode(rp)
MEASUREMENT
```
"""
function serverMode(rp::RedPitaya)
  return stringToEnum(ServerMode, strip(query(rp, scpiCommand(serverMode)), '\"'))
end
scpiCommand(::typeof(serverMode)) = "RP:MODe?"
scpiReturn(::typeof(serverMode)) = ServerMode
parseReturn(::typeof(ServerMode), ret) = stringToEnum(ServerMode, strip(ret, '\"'))

"""
    serverMode!(rp::RedPitaya, mode::ServerMode)

Set the mode of the server. Valid values are "`CONFIGURATION`" and "`MEASUREMENT`".

# Examples
```julia
julia> serverMode!(rp, MEASUREMENT);
true

julia> serverMode(rp)
MEASUREMENT
```
"""
function serverMode!(rp::RedPitaya, mode::String)
  return serverMode!(rp, stringToEnum(ServerMode, mode))
end
"""
    serverMode!(rp::RedPitaya, mode::ServerMode)

Set the mode of the server.

# Examples
```julia
julia> serverMode!(rp, MEASUREMENT);
true

julia> serverMode(rp)
MEASUREMENT
```
"""
function serverMode!(rp::RedPitaya, mode::ServerMode)
  return query(rp, scpiCommand(serverMode!, mode), scpiReturn(serverMode!))
end
scpiCommand(::typeof(serverMode!), mode) = string("RP:MODe ", string(mode))
scpiReturn(::typeof(serverMode!)) = Bool

include("DAC.jl")
include("ADC.jl")
include("Cluster.jl")
include("SlowIO.jl")
include("EEPROM.jl")

function destroy(rp::RedPitaya)
  disconnect(rp)
  rp.destroyed = true
end

"""
    RedPitaya(ip [, port = 5025, dataPort=5026, isMaster = false])

Construct a `RedPitaya`.

During the construction the connection
is established and the calibration values are loaded from the RedPitayas EEPROM.
Throws an error if a timeout occurs while attempting to connect.

# Examples
```julia
julia> rp = RedPitaya("192.168.1.100");

julia> decimation!(rp, 8)
true

julia> decimation(rp)
8
```
"""
function RedPitaya(host::String, port::Int64=5025, dataPort::Int64=5026, isMaster::Bool=true)

  rp = RedPitaya(host, port, dataPort, "\n", TCPSocket(), TCPSocket(), 1, 1, 1, false, isMaster, false, zeros(Float32, 2, 2))

  connect(rp)

  finalizer(d -> destroy(d), rp)
  return rp
end

scpiCommand(f::Function, args...) = error("Function $(string(f)) does not support scpiCommand")
scpiReturn(f::Function) = typeof(nothing)
parseReturn(f::Function, ret) = parse(scpiReturn(f), ret)

function batch(rp::RedPitaya, cmds::Vector{Pair{Function, Vector{Any}}})
  for (f, args) in cmds
    send(rp, scpiCommand(f, args...))
  end
  result = []
  for (f, _) in cmds
    T = scpiReturn(f)
    if T != Nothing
      ret = receive(rp, _timeout)
      push!(result, parseReturn(f, ret))
    end
  end
  return result
end


end # module
