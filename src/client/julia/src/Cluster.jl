export RedPitayaCluster, master, numChan

import Base: length, iterate, getindex, firstindex, lastindex

"""
    RedPitayaCluster

Struct representing a cluster of `RedPitaya`s. Such a cluster should share a common clock and master trigger.

The structure implements the indexing and iterable interfaces.
"""
struct RedPitayaCluster
  rp::Vector{RedPitaya}
end

"""
    RedPitayaCluster(hosts::Vector{String} [, port = 5025])

Construct a `RedPitayaCluster`.

During the construction the first host is labelled the master RedPitaya of a cluster and all RedPitayas
are set to using the `EXTERNAL` trigger mode.

See also [`RedPitaya`](@ref), [`master`](@ref).

# Examples
```julia
julia> rpc = RedPitayaCluster(["192.168.1.100", "192.168.1.101"]);

julia> rp = master(rpc)

julia> rp == rpc[1]
true
```
"""
function RedPitayaCluster(hosts::Vector{String}, port::Int64=5025, dataPort::Int64=5026; triggerMode_="EXTERNAL")
  # the first RP is the master
  rps = RedPitaya[ RedPitaya(host, port, dataPort, i==1) for (i,host) in enumerate(hosts) ]

  @sync for rp in rps
    @async triggerMode!(rp, triggerMode_)
  end

  return RedPitayaCluster(rps)
end

"""
    length(rpc::RedPitayaCluster)

Return the number of `RedPitaya`s in cluster `rpc`.
"""
length(rpc::RedPitayaCluster) = length(rpc.rp)
"""
    numChan(rpc::RedPitayaCluster)

Return the number of ADC channel in cluser `rpc`.
"""
numChan(rpc::RedPitayaCluster) = 2*length(rpc)
"""
    master(rpc::RedPitayaCluster)

Return the master `RedPitaya` of the cluster.
"""
master(rpc::RedPitayaCluster) = rpc.rp[1]

# Indexing Interface
function getindex(rpc::RedPitayaCluster, index::Integer)
  1 <= index <= length(rpc) || throw(BoundsError(rpc.rp, index))
  return rpc.rp[index]
end
firstindex(rpc::RedPitayaCluster) = start_(rpc)
lastindex(rpc::RedPitayaCluster) = length(rpc)

# Iterable Interface
start_(rpc::RedPitayaCluster) = 1
next_(rpc::RedPitayaCluster,state) = (rpc[state],state+1)
done_(rpc::RedPitayaCluster,state) = state > length(rpc)
iterate(rpc::RedPitayaCluster, s=start_(rpc)) = done_(rpc, s) ? nothing : next_(rpc, s)

batchIndices(f::Function, rpc::RedPitaya, args...) = error("Function $(string(f)) is not supported in cluster batch or has incorrect parameters.")
batchTransformArgs(::Function, rpc::RedPitayaCluster, idx, args...) = args

function RPInfo(rpc::RedPitayaCluster)
  return RPInfo([RPPerformance([]) for i = 1:length(rpc)])
end

for op in [:currentFrame, :currentPeriod, :currentWP, :periodsPerFrame, :samplesPerPeriod, :decimation, :keepAliveReset,
           :triggerMode, :samplesPerStep, :serverMode, :masterTrigger,
           :counterTrigger_enabled, :counterTrigger_enabled!, :counterTrigger_presamples,
           :counterTrigger_presamples!, :counterTrigger_isArmed, :counterTrigger_arm!,
           :counterTrigger_reset, :counterTrigger_reset!, :counterTrigger_lastCounter,
           :counterTrigger_referenceCounter, :counterTrigger_referenceCounter!]

  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster)

    As with single RedPitaya, but applied to only the master.
    """
    $op(rpc::RedPitayaCluster) = $op(master(rpc))
    batchIndices(::typeof($op), rpc::RedPitayaCluster) = 1
  end
end

for op in [:periodsPerFrame!, :samplesPerPeriod!, :decimation!, :triggerMode!, :samplesPerStep!,
           :keepAliveReset!, :serverMode!]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, value)

    As with single RedPitaya, but applied to all RedPitayas in a cluster.
    """
    function $op(rpc::RedPitayaCluster, value)
      result = [false for i = 1:length(rpc)]
      @sync for (i, rp) in enumerate(rpc)
        @async result[i] = $op(rp, value)
      end
      return result
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster, value) = collect(1:length(rpc))
  end
end

for op in [:clearSequence!, :sequence!]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster)

    As with single RedPitaya, but applied to all RedPitayas in a cluster.
    """
    function $op(rpc::RedPitayaCluster)
      result = [false for i = 1:length(rpc)]
      @sync for (i, rp) in enumerate(rpc)
        @async result[i] = $op(rp)
      end
      return result
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster) = collect(1:length(rpc))
  end
end

for op in [:disconnect, :connect]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster)

    As with single RedPitaya, but applied to all RedPitayas in a cluster.
    """
    function $op(rpc::RedPitayaCluster)
      @sync for rp in rpc
        @async $op(rp)
      end
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster) = collect(1:length(rpc))
  end
end

"""
    masterTrigger(rpc::RedPitayaCluster, val::Bool)

Set the master trigger of the cluster to `val`.

For `val` equals to true this is the same as calling the function on the RedPitaya returned by `master(rpc)`.
If `val` is false then the keepAliveReset is set to true for all RedPitayas in the cluster
before the master trigger is disabled. Afterwards the keepAliveReset is set to false again.

See also [`master`](@ref), [`keepAliveReset!`](@ref).
"""
function masterTrigger!(rpc::RedPitayaCluster, val::Bool)
    if val
        masterTrigger!(master(rpc), val)
    else
        keepAliveReset!(rpc, true)
        masterTrigger!(master(rpc), false)
        keepAliveReset!(rpc, false)
    end
    return masterTrigger(rpc)
end


for op in [:signalTypeDAC, :amplitudeDAC, :frequencyDAC, :phaseDAC]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, chan::Integer, component::Integer)

    As with single RedPitaya. The `chan` index refers to the total channel available in a cluster, two per `RedPitaya`.
    For example channel `4` would refer to the second channel of the second `RedPitaya`.
    """
    function $op(rpc::RedPitayaCluster, chan::Integer, component::Integer)
      idxRP = div(chan-1, 2) + 1
      chanRP = mod1(chan, 2)
      return $op(rpc[idxRP], chanRP, component)
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster, chan, component) = [div(chan -1, 2) + 1]
    batchTransformArgs(::typeof($op), rpc::RedPitayaCluster, idx, chan, component) = (mod1(chan, 2), component)
  end
end
for op in [:signalTypeDAC!, :amplitudeDAC!, :frequencyDAC!, :phaseDAC!]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, chan::Integer, component::Integer, value)

    As with single RedPitaya. The `chan` index refers to the total channel available in a cluster, two per `RedPitaya`.
    For example channel `4` would refer to the second channel of the second `RedPitaya`.
    """
    function $op(rpc::RedPitayaCluster, chan::Integer, component::Integer, value)
      idxRP = div(chan-1, 2) + 1
      chanRP = mod1(chan, 2)
      return $op(rpc[idxRP], chanRP, component, value)
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster, chan, component, value) = [div(chan -1, 2) + 1]
    batchTransformArgs(::typeof($op), rpc::RedPitayaCluster, idx, chan, component, value) = (mod1(chan, 2), component, value)
  end
end

for op in [:offsetDAC, :rampingDAC, :enableRamping, :enableRampDown]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, chan::Integer)

    As with single RedPitaya. The `chan` index refers to the total channel available in a cluster, two per `RedPitaya`.
    For example channel `4` would refer to the second channel of the second `RedPitaya`.
    """
    function $op(rpc::RedPitayaCluster, chan::Integer)
      idxRP = div(chan-1, 2) + 1
      chanRP = mod1(chan, 2)
      return $op(rpc[idxRP], chanRP)
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster, chan) = [div(chan -1, 2) + 1]
    batchTransformArgs(::typeof($op), rpc::RedPitayaCluster, idx, chan) = (mod1(chan, 2))
  end
end
for op in [:offsetDAC!, :rampingDAC!, :enableRamping!, :enableRampDown!]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, chan::Integer, value)

    As with single RedPitaya. The `chan` index refers to the total channel available in a cluster, two per `RedPitaya`.
    For example channel `4` would refer to the second channel of the second `RedPitaya`.
    """
    function $op(rpc::RedPitayaCluster, chan::Integer, value)
      idxRP = div(chan-1, 2) + 1
      chanRP = mod1(chan, 2)
      return $op(rpc[idxRP], chanRP, value)
    end
    batchIndices(::typeof($op), rpc::RedPitayaCluster, chan, value) = [div(chan -1, 2) + 1]
    batchTransformArgs(::typeof($op), rpc::RedPitayaCluster, idx, chan, value) = (mod1(chan, 2), value)
  end
end

for op in [:waveformDAC!, :scaleWaveformDAC!]
  @eval begin
    function $op(rpc::RedPitayaCluster, channel::Integer, value)
      idxRP = div(channel-1, 2) + 1
      chan = mod1(channel, 2)
      return $op(rpc[idxRP], chan, value)
    end
  end
end

function rampingStatus(rpc::RedPitayaCluster)
  result = Array{RampingStatus}(undef, length(rpc))
  @sync for (d, rp) in enumerate(rpc)
    @async result[d] = rampingStatus(rp)
  end
  return result
end
batchIndices(::typeof(rampingStatus), rpc::RedPitayaCluster) = collect(1:length(rpc))

for op in [:rampDownDone, :rampUpDone]
  @eval begin
    function $op(rpc::RedPitayaCluster)
      result = [false for i = 1:length(rpc)]
      @sync for (d, rp) in enumerate(rpc)
        @async result[d] = $op(rp)
      end
      return all(result)
    end
  end
end

"""
    execute!(rpc::RedPitayaCluster, batch::ScpiBatch)

Executes all commands of the given batch. Returns an array of the results in the order of the commands.

Each element of the result array is again an array containing the return values of the RedPitayas.
An element of an inner array is `nothing` if the command has no return value.
"""
function execute!(rpc::RedPitayaCluster, batch::ScpiBatch)
  # Send cmd after cmd to each "affected" RedPitaya
  cmds = [Vector{String}() for i =1:length(rpc)]
  for (f, args) in batch.cmds
    indices = batchIndices(f, rpc, args...)
    for idx in indices
      push!(cmds[idx], scpiCommand(f, batchTransformArgs(f, rpc, idx, args...)...))
    end
  end
  @sync for (i, cmd) in enumerate(cmds)
    @async begin
      if !isempty(cmd)
        cmdStr = join(cmd, rpc[i].delim)
        send(rpc[i], cmdStr)
        Sockets.quickack(rpc[i].socket, true)
      end
    end
  end
  results = []
  # Retrieve results from each "affected" RedPitaya for each cmd
  for (f, args) in batch.cmds
    result = Array{Union{Nothing, scpiReturn(f)}}(nothing, length(rpc))
    indices = batchIndices(f, rpc, args...)
    @sync for idx in indices
      @async begin
        if !isnothing(scpiReturn(f))
          ret = parseReturn(f, receive(rpc[idx], getTimeout()))
          Sockets.quickack(rpc[idx].socket, true)
          result[idx] = ret
        end
      end
    end
    push!(results, result)
  end
  return results
end

"""
    execute!(f::Function, rp::Union{RedPitaya, RedPitayaCluster})

Open a `ScpiBatch` and evaluate the function `f`. If no exception was thrown, execute the opened batch.

See also [`ScpiBatch`](@ref), [`push!`](@ref), [`@add_batch`](@ref)
# Examples
```julia
julia>  execute!(rp) do b
          @add_batch b serverMode!(rp, CONFIGURATION)
          @add_batch b amplitudeDAC!(rp, 1, 1, 0.2)
        end
```
"""
function execute!(f::Function, rp::Union{RedPitaya, RedPitayaCluster})
  scpiBatch = ScpiBatch()
  try
    f(scpiBatch)
  catch ex
    rethrow()
  end
  return execute!(rp, scpiBatch)
end