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

for op in [:currentFrame, :currentPeriod, :currentWP, :periodsPerFrame, :samplesPerPeriod, :decimation, :keepAliveReset, :sequenceRepetitions,
           :triggerMode, :samplesPerStep, :stepsPerFrame, :serverMode, :masterTrigger]

  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster)

    As with single RedPitaya, but applied to only the master.
    """
    $op(rpc::RedPitayaCluster) = $op(master(rpc))
    batchIndices(::typeof($op), rpc::RedPitayaCluster) = 1
  end
end

for op in [:periodsPerFrame!, :samplesPerPeriod!, :decimation!, :triggerMode!, :samplesPerStep!, :stepsPerFrame!,
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

for op in [:clearSequence!, :sequence!, :prepareSequences!]
  @eval begin
    @doc """
        $($op)(rpc::RedPitayaCluster, value)

    As with single RedPitaya, but applied to all RedPitayas in a cluster.
    """
    function $op(rpc::RedPitayaCluster)
      result = [false for i = 1:length(rpc)]
      @sync for (i, rp) in enumerate(rpc)
        @async result[i] = $op(rp)
      end
      return result
    end
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

function passPDMToFastDAC!(rpc::RedPitayaCluster, val::Vector{Bool})
  result = [false for i=1:length(rpc)]
  @sync for (d,rp) in enumerate(rpc)
    @async result[d] = passPDMToFastDAC!(rp, val[d])
  end
end
batchIndices(::typeof(passPDMToFastDAC!), rpc::RedPitayaCluster, val) = collect(1:length(rpc))
batchTransformArgs(::typeof(passPDMToFastDAC!), rpc::RedPitayaCluster, idx, val::Vector{Bool}) = (val[idx])

function passPDMToFastDAC(rpc::RedPitayaCluster)
  result = [false for rp in rpc]
  @sync for (d, rp) in enumerate(rpc)
    @async result[d] = passPDMToFastDAC(rp)
  end
  return result
end
batchIndices(::typeof(passPDMToFastDAC), rpc::RedPitayaCluster) = collect(1:length(rpc))

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
  for (f, args) in batch.cmds
    indices = batchIndices(f, rpc, args...)
    @sync for idx in indices
      @async send(rpc[idx], scpiCommand(f, batchTransformArgs(f, rpc, idx, args...)...))
    end
  end
  results = []
  # Retrieve results from each "affected" RedPitaya for each cmd
  for (f, args) in batch.cmds
    result = Array{Any}(nothing, length(rpc))
    indices = batchIndices(f, rpc, args...)
    @sync for idx in indices
      @async begin
        if !isnothing(scpiReturn(f))
          ret = parseReturn(f, receive(rpc[idx], _timeout))
          result[idx] = ret
        end
      end
    end
    push!(results, result)
  end
  return results
end
