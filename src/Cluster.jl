export RedPitayaCluster, master

import Base: length

mutable struct RedPitayaCluster
  rp::Vector{RedPitaya}
end

function RedPitayaCluster(hosts::Vector{String}, port=5025)
  rp = RedPitaya[ RedPitaya(host, port) for host in hosts ]

  return RedPitayaCluster(rp)
end

length(rpc::RedPitayaCluster) = length(rpc.rp)

master(rpc::RedPitayaCluster) = rpc.rp[1]

function currentFrame(rpc::RedPitayaCluster)
  currentFrames = [ currentFrame(rp) for rp in rpc.rp ]
  println("Current frame: $currentFrames")
  return minimum(currentFrames)
end

for op in [:periodsPerFrame,  :samplesPerPeriod, :decimation]
  @eval $op(rpc::RedPitayaCluster) = $op(master(rpc))
  @eval begin
    function $op(rpc::RedPitayaCluster, value)
      for rp in rpc.rp
        $op(rp, value)
      end
    end
  end
end

for op in [:connectADC,  :startADC, :stopADC, :disconnect]
  @eval begin
    function $op(rpc::RedPitayaCluster)
      for rp in rpc.rp
        $op(rp)
      end
    end
  end
end

masterTrigger(rpc::RedPitayaCluster, val::Bool) = masterTrigger(master(rpc), val)

# "TRIGGERED" or "CONTINUOUS"
function ramWriterMode(rpc::RedPitayaCluster, mode::String)
  for rp in rpc.rp
    ramWriterMode(rp, mode)
  end
end

for op in [:amplitudeDAC,  :frequencyDAC, :phaseDAC, :modulusFactorDAC]
  @eval begin $op(rpc::RedPitayaCluster, idxRP::Integer, channel::Integer, component::Integer) =
           $op(rpc.rp[idxRP], channel, component)
  end
  @eval begin $op(rpc::RedPitayaCluster, idxRP::Integer, channel::Integer, component::Integer, value) =
           $op(rpc.rp[idxRP], channel, component, value)
  end
end


#"STANDARD" or "RASTERIZED"
modeDAC(rpc::RedPitayaCluster) = modeDAC(master(rpc))

function modeDAC(rpc::RedPitayaCluster, mode::String)
  for rp in rpc.rp
    modeDAC(rp, mode)
  end
end





# High level read. numFrames can adress a future frame. Data is read in
# chunks
function readData(rpc::RedPitayaCluster, startFrame, numFrames)
  dec = master(rpc).decimation
  numSampPerPeriod = master(rpc).samplesPerPeriod
  numSamp = numSampPerPeriod * numFrames
  numPeriods = master(rpc).periodsPerFrame
  numSampPerFrame = numSampPerPeriod * numPeriods
  numRP = length(rpc)

  data = zeros(Int16, 2, numSampPerPeriod, numRP, numPeriods, numFrames)
  wpRead = startFrame
  l=1

  # This is a wild guess for a good chunk size
  chunkSize = max(1,  round(Int, 1000000 / numSampPerFrame)  )
  println("chunkSize = $chunkSize")
  while l<=numFrames
    wpWrite = currentFrame(rpc)
    while wpRead >= wpWrite # Wait that startFrame is reached
      wpWrite = currentFrame(rpc)
      println(wpWrite)
    end
    chunk = min(wpWrite-wpRead,chunkSize) # Determine how many frames to read
    println(chunk)
    if l+chunk > numFrames
      chunk = numFrames - l + 1
    end

    println("Read from $wpRead until $(wpRead+chunk-1), WpWrite $(wpWrite), chunk=$(chunk)")

    for (d,rp) in enumerate(rpc.rp)
      u = readData_(rp, Int64(wpRead), Int64(chunk))

      data[:,:,d,:,l:(l+chunk-1)] = u
    end

    l += chunk
    wpRead += chunk
  end

  return data
end
