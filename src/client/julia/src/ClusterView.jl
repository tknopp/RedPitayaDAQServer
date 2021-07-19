export RedPitayaClusterView, master, readDataPeriods, numChan, readDataSlow, readFrames, readPeriods, readPipelinedSamples, startPipelinedData, collectSamples!, readData, readDataPeriods, modeDAC, translateViewToClusterChannel

import Base: length, iterate, getindex, firstindex, lastindex

struct RedPitayaClusterView
    rpc::RedPitayaCluster
    view::Vector{Integer}
end

function RedPitayaClusterView(rpc::RedPitayaCluster, selection::Vector{Bool})
    length(selection) == length(rpc) || throw(DimensionMismatch("Length of boolean vector must match length of cluster")) 
    view = findall(selection)
    return RedPitayaClusterView(rpc, view)
end

function RedPitayaClusterView(hosts::Vector{String}, selection, port=5025)
    rpc = RedPitayaCluster(hosts, port)
    return RedPitayaClusterView(rpc, selection)
end
  
length(rpcv::RedPitayaClusterView) = length(rpcv.view)
numChan(rpcv::RedPitayaClusterView) = 2 * length(rpcv.view)
master(rpcv::RedPitayaClusterView) = master(rpcv.rpc)
  
# Index
function getindex(rpcv::RedPitayaClusterView, index::Integer)
    1 <= index <= length(rpcv) || throw(BoundsError(rpcv.view, index))
    viewIndex = rpcv.view[index]
    1 <= viewIndex <= length(rpcv.rpc) || throw(BoundsError(rpcv.rpc, viewIndex))
    return rpcv.rpc[viewIndex]
end
firstindex(rpcv::RedPitayaClusterView) = start_(rpcv)
lastindex(rpcv::RedPitayaClusterView) = length(rpcv.view)

# Iterate
start_(rpcv::RedPitayaClusterView) = 1
next_(rpcv::RedPitayaClusterView, state) = (rpcv[state], state + 1)
done_(rpcv::RedPitayaClusterView, state) = state > length(rpcv)
iterate(rpcv::RedPitayaClusterView, s=start_(rpcv)) = done_(rpcv, s) ? nothing : next_(rpcv, s)


# Pass function calls on to RedPitayaCluster
for op in [:currentFrame, :currentPeriod, :currentWP, :connectADC, :startADC, :stopADC, :bufferSize]
    @eval $op(rpcv::RedPitayaClusterView) = $op(rpcv.rpc)
end

for op in [:periodsPerFrame, :samplesPerPeriod, :decimation, :keepAliveReset,
    :triggerMode, :slowDACStepsPerSequence, :samplesPerSlowDACStep,
    :slowDACStepsPerFrame, :ramWriterMode, :numSlowADCChan, :numSlowDACChan,
    :passPDMToFastDAC, :modeDAC, :masterTrigger]
    @eval $op(rpcv::RedPitayaClusterView) = $op(master(rpcv))
    @eval $op(rpcv::RedPitayaClusterView, value) = $op(rpcv.rpc, value)
end

for op in [:amplitudeDAC, :amplitudeDACNext, :frequencyDAC, :phaseDAC, :modulusFactorDAC, :modulusDAC]
    @eval $op(rpcv::RedPitayaClusterView, chan::Integer, component::Integer) = $op(rpcv.rpc, chan, component)
    @eval $op(rpcv::RedPitayaClusterView, chan::Integer, component::Integer, value) = $op(rpcv.rpc, chan, component, value)
end

for op in [:signalTypeDAC,  :DCSignDAC, :jumpSharpnessDAC, :setSlowDAC, :getSlowDAC, :offsetDAC]
    @eval $op(rpcv::RedPitayaClusterView, chan::Integer) = $op(rpcv.rpc, chan)
    @eval $op(rpcv::RedPitayaClusterView, chan::Integer, value) = $op(rpcv.rpc, chan, value) 
end

function enableSlowDAC(rpcv::RedPitayaClusterView, enable::Bool, numFrames::Int64=0,
    ffRampUpTime::Float64=0.4, ffRampUpFraction::Float64=0.8)
    enableSlowDAC(rpcv.rpc, enable, numFrames, ffRampUpTime, ffRampUpFraction)
end

slowDACInterpolation(rpcv::RedPitayaClusterView, enable::Bool) = slowDACInterpolation(rpcv.rpc, enable)

# Returns the channel number in the cluster for a given channel number in the view
function translateViewToClusterChannel(rpcv::RedPitayaClusterView, chan)
    view = rpcv.view 
    idxInView = div(chan -1, 2) + 1
    chanRP = mod1(chan, 2)
    return 2*(view[idxInView] - 1) + chanRP
end

# Helper functions for readData functions in Cluster.jl
function startPipelinedData(rpcv::RedPitayaClusterView, reqWP::Int64, numSamples::Int64, chunkSize::Int64)
    for rp in rpcv
        startPipelinedData(rp, reqWP, numSamples, chunkSize)
    end
end
