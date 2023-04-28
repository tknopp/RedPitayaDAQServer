module RedPitayaDAQServer

# package code goes here

using Base: UInt16
using Sockets
import Sockets: send, connect

using Statistics
using LinearAlgebra
import LinearAlgebra: normalize

import Base: reset, iterate, length, push!, pop!

export RedPitaya, send, receive, query, disconnect, ServerMode, serverMode, serverMode!, CONFIGURATION, ACQUISITION, TRANSMISSION, getLog, ScpiBatch, execute!, clear!, @add_batch

# TODO: The update stuff increases load times quite a bit. Should we move this to a script?
# using ProgressMeter
# using Downloads
# using Scratch
# using GitHub
# using URIs
# using ZipFile

const _awgBufferSize = 16384

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
  awgs::Matrix{Float32}
end

# Iterable Interface

length(rp::RedPitaya) = 1
iterate(rp::RedPitaya, state=1) = state > 1 ? nothing : (rp, state + 1)

"""
    send(rp::RedPitaya, cmd::String)

Send a command to the RedPitaya. Appends delimiter.
"""
function send(rp::RedPitaya,cmd::String)
  @debug "RP $(rp.host) sent: $cmd"
  write(rp.socket,cmd*rp.delim)
end

const _timeout = Ref(5.0)
const _scaleWarning = 0.1

"""
    receive(rp::RedPitaya)

Receive a String from the RedPitaya command socket. Reads until a whole line is received
"""
function receive(rp::RedPitaya)
  return readline(rp.socket)[1:end]
end

function receive(rp::RedPitaya, ch::Channel)
  put!(ch, receive(rp))
end

"""
    receive(rp::RedPitaya, timeout::Number)

Receive a string from the RedPitaya command socket. Reads until a whole line is received or timeout seconds passed.
In the latter case an error is thrown.
"""
function receive(rp::RedPitaya, timeout::Number)
  ch = Channel()
  t = @async receive(rp, ch)
  result = nothing
  timeoutTimer = Timer(_ -> close(ch), timeout)
  try 
    result = take!(ch)
  catch e
    @async Base.throwto(t, EOFError())
    if e isa InvalidStateException
      error("Receive ran into timeout on RP $(rp.host)")
    else
      error("Unexpected state during receive on RP $(rp.host)")
    end
  finally
    close(timeoutTimer)
  end
  @debug "RP $(rp.host) received: $result"
  return result
end

"""
    query(rp::RedPitaya, cmd [, timeout = 5.0, N = 100])

Send a query to the RedPitaya command socket. Return reply as String.

Waits for `timeout` seconds and checks every `timeout/N` seconds.

See also [receive](@ref).
"""
function query(rp::RedPitaya, cmd::String, timeout::Number=getTimeout())
  send(rp, cmd)
  Sockets.quickack(rp.socket, true)
  receive(rp, timeout)
end

"""
    query(rp::RedPitaya, cmd, T::Type [timeout = 5.0, N = 100])

Send a query to the RedPitaya. Parse reply as `T`.

Waits for `timeout` seconds and checks every `timeout/N` seconds.
"""
function query(rp::RedPitaya, cmd::String, T::Type, timeout::Number=getTimeout())
  a = query(rp, cmd, timeout)
  if T == String
    return a[2:end-1] # Strings are wrapped like this: "\"OUT\""
  else
    parse(T, a)
  end
end

# connect with timeout implementation
function connectTimeout(host, port::Integer, timeout::Number)
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
      rp.socket = connectTimeout(rp.host, rp.port, getTimeout())
      rp.dataSocket = connectTimeout(rp.host, rp.dataPort, getTimeout())
      rp.isConnected = true
      updateCalib!(rp)
      temp = findall([calibDACScale(rp, 1) < _scaleWarning, calibDACScale(rp, 2) < _scaleWarning])
      if length(temp) > 0
        @warn "RP $(rp.host): Channels $(string(temp)) have a small DAC scale calibration value. If this is not intended use calibDACScale!(rp, i, 1.0) to set a default scale."
      end
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
    throw(ArgumentError("$value cannot be resolved to an instance of $(enumType). Possible instances are: " * join(stringInstances, ", ", " and ")))
  end
  return instances(enumType)[index]
end

"""
    ServerMode

Represent the different modes the server can be in. Valid values are `CONFIGURATION`, `ACQUISITION` and `TRANSMISSION`.

See also [`serverMode`](@ref), [`serverMode!`](@ref).
"""
@enum ServerMode CONFIGURATION ACQUISITION TRANSMISSION

"""
    serverMode(rp::RedPitaya)

Return the mode of the server.

# Examples
```julia
julia> serverMode!(rp, ACQUISITION);
true

julia> serverMode(rp)
ACQUISITION
```
"""
function serverMode(rp::RedPitaya)
  return stringToEnum(ServerMode, strip(query(rp, scpiCommand(serverMode)), '\"'))
end
scpiCommand(::typeof(serverMode)) = "RP:MODe?"
scpiReturn(::typeof(serverMode)) = ServerMode
parseReturn(::typeof(serverMode), ret) = stringToEnum(ServerMode, strip(ret, '\"'))

"""
    serverMode!(rp::RedPitaya, mode::ServerMode)

Set the mode of the server. Valid values are "`CONFIGURATION`" and "`ACQUISITION`".

# Examples
```julia
julia> serverMode!(rp, ACQUISITION);
true

julia> serverMode(rp)
ACQUISITION
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
julia> serverMode!(rp, ACQUISITION);
true

julia> serverMode(rp)
ACQUISITION
```
"""
function serverMode!(rp::RedPitaya, mode::ServerMode)
  return query(rp, scpiCommand(serverMode!, mode), scpiReturn(serverMode!))
end
scpiCommand(::typeof(serverMode!), mode) = string("RP:MODe ", string(mode))
scpiReturn(::typeof(serverMode!)) = Bool


"""
    ScpiBatch

Struct representing a batch of SCPI commands for a RedPitaya. Only commands that interact exclusively with the command socket should be used in a batch.
"""
struct ScpiBatch
  cmds::Vector{Pair{Function, Tuple}}
end
ScpiBatch() = ScpiBatch([])

"""
    push!(batch::ScpiBatch, cmd::Pair{K, T}) where {K<:Function, T<:Tuple}

Add the given function and arguments to the batch
# Examples
```julia
julia> batch = ScpiBatch() 

julia> push!(batch, amplitudeDAC! => (1, 1, 0.2))
```  
"""
push!(batch::ScpiBatch, cmd::Pair{K, T}) where {K<:Function, T<:Tuple} = push!(batch.cmds, cmd)
push!(batch::ScpiBatch, cmd::Pair{K, T}) where {K<:Function, T<:Any} = push!(batch, cmd.first => (cmd.second,))
"""
    pop!(batch::ScpiBatch)

Remove the last added command from the batch
"""
pop!(batch::ScpiBatch) = pop!(batch.cmds)

"""
    clear!(batch::ScpiBatch)

Remove all commands from the batch
"""
function clear!(batch::ScpiBatch)
  batch.cmds = []
end

"""
    execute!(rp::RedPitaya, batch::ScpiBatch)

Executes all commands of the given batch. Returns an array of the results in the order of the commands.
An element is `nothing` if the command has no return value.
"""
function execute!(rp::RedPitaya, batch::ScpiBatch)
  # Send everything first
  cmds = join([scpiCommand(f, args...) for (f, args) in batch.cmds], rp.delim)
  send(rp, cmds)
  # Then receive
  Sockets.quickack(rp.socket, true)
  result = Array{Any}(nothing, length(batch.cmds))
  for (i, (f, _)) in enumerate(batch.cmds)
    if !isnothing(scpiReturn(f))
      ret = receive(rp, getTimeout())
      Sockets.quickack(rp.socket, true) # quickack can be reset after tcp operations
      result[i] = parseReturn(f, ret)
    end
  end
  return result
end

"""
    @add_batch batch cmd

Append a usual RedPitaya function to the given batch instead of evaluating it directly.

See also [`ScpiBatch`](@ref), [`push!`](@ref), [`execute!`](@ref)

# Examples
```julia
julia>  execute!(rp) do b
          @add_batch b serverMode!(rp, CONFIGURATION)
        end
```
"""
macro add_batch(batch::Symbol, expr::Expr)
  if expr.head != :call
    throw(ArgumentError("$expr is not a function call"))
  end
  func = expr.args[1]
  tuple = Expr(:call)
  push!(tuple.args, :tuple)
  for arg in expr.args[3:end]
    push!(tuple.args, :($(esc(arg))))
  end
  return :(push!($(esc(batch)), $func => $tuple))
end


include("DAC.jl")
include("Sequence.jl")
include("ADC.jl")
include("Cluster.jl")
include("ClusterView.jl")
include("Acquisition.jl")
include("SlowIO.jl")
include("EEPROM.jl")
include("CounterTrigger.jl")
#include("Utility.jl")

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

  rp = RedPitaya(host, port, dataPort, "\n", TCPSocket(), TCPSocket(), 1, 1, 1, false, isMaster, false, zeros(Float32, 2, 2), zeros(Float32, _awgBufferSize, 2))

  connect(rp)

  finalizer(d -> destroy(d), rp)
  return rp
end

scpiCommand(f::Function, args...) = error("Function $(string(f)) does not support scpiCommand")
scpiReturn(f::Function) = typeof(nothing)
parseReturn(f::Function, ret) = parse(scpiReturn(f), ret)

export setTimeout
"""
    Set the global timeout used in all functions of the package
"""
setTimeout(_timeoutParam::T) where T <: Real = global _timeout[] = _timeoutParam

export getTimeout
"""
    Get the global timeout used in all functions of the package
"""
getTimeout() = _timeout[]


end # module
