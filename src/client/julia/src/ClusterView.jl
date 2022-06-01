export RedPitayaClusterView, master, readDataPeriods, numChan, readDataSlow, readFrames, readPeriods, readPipelinedSamples, startPipelinedData, collectSamples!, readData, readDataPeriods, modeDAC, viewToCluster, clusterToView

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

# Returns the channel number in the cluster for a given channel number in the view
function viewToCluster(rpcv::RedPitayaClusterView, chan::Integer)
    view = rpcv.view 
    idxInView = div(chan -1, 2) + 1
    chanRP = mod1(chan, 2)
    return 2*(view[idxInView] - 1) + chanRP
end

function clusterToView(rpcv::RedPitayaClusterView, chan::Integer)
    for (i, v) in enumerate(rpcv.view)
        if 2*v-1 == chan
            return 2*i -1
        elseif 2*v == chan
            return 2*i
        end
    end
    return nothing
end

function currentWP(rpcv::RedPitayaClusterView)
    return currentWP(rpcv.rpc)
end
