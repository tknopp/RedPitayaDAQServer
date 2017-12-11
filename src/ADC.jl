export decimation, samplesPerPeriod, periodsPerFrame, masterTrigger, currentFrame,
     currentPeriod, ramWriterMode, connectADC, startADC, stopADC, readData,
     numSlowDACChan, setSlowDACLUT


decimation(rp::RedPitaya) = query(rp,"RP:ADC:DECimation?", Int64)
function decimation(rp::RedPitaya, dec)
  rp.decimation = Int64(dec)
  send(rp, string("RP:ADC:DECimation ", rp.decimation))
end

samplesPerPeriod(rp::RedPitaya) = query(rp,"RP:ADC:PERiod?", Int64)
function samplesPerPeriod(rp::RedPitaya, value)
  rp.samplesPerPeriod = Int64(value)
  send(rp, string("RP:ADC:PERiod ", rp.samplesPerPeriod))
end

numSlowDACChan(rp::RedPitaya) = query(rp,"RP:ADC:SlowDAC?", Int64)
function numSlowDACChan(rp::RedPitaya, value)
  send(rp, string("RP:ADC:SlowDAC ", Int64(value)))
end

function setSlowDACLUT(rp::RedPitaya, lut::Array)
  lutStr = join([string(",", lut[l]) for l=2:length(lut)])
  send(rp, string("RP:ADC:SlowDACLUT ", lut[1], lutStr))
end

periodsPerFrame(rp::RedPitaya) = query(rp,"RP:ADC:FRAme?", Int64)
function periodsPerFrame(rp::RedPitaya, value)
  rp.periodsPerFrame = Int64(value)
  send(rp, string("RP:ADC:FRAme ", rp.periodsPerFrame))
end

currentFrame(rp::RedPitaya) = query(rp,"RP:ADC:FRAMES:CURRENT?", Int64)
currentPeriod(rp::RedPitaya) = query(rp,"RP:ADC:PERIODS:CURRENT?", Int64)

function masterTrigger(rp::RedPitaya, val::Bool)
  valStr = val ? "ON" : "OFF"
  send(rp, string("RP:MasterTrigger ", valStr))
end

# "TRIGGERED" or "CONTINUOUS"
function ramWriterMode(rp::RedPitaya, mode::String)
  send(rp, string("RP:RamWriterMode ", mode))
end

connectADC(rp::RedPitaya) = query(rp, "RP:ADC:ACQCONNect")
startADC(rp::RedPitaya) = send(rp, "RP:ADC:ACQSTATUS ON")
stopADC(rp::RedPitaya) = send(rp, "RP:ADC:ACQSTATUS OFF")

# Low level read. One has to take care that the numFrames are available
function readData_(rp::RedPitaya, startFrame, numFrames)
  numSampPerPeriod = rp.samplesPerPeriod
  numSamp = numSampPerPeriod * numFrames
  numPeriods = rp.periodsPerFrame
  numSampPerFrame = numSampPerPeriod * numPeriods

  command = string("RP:ADC:FRAMES:DATA ",Int64(startFrame),",",Int64(numFrames))
  println(command)
  send(rp, command)

  println("read data ...")
  u = read(rp.dataSocket, Int16, 2 * numFrames * numSampPerFrame)
  println("read data!")
  return reshape(u, 2, rp.samplesPerPeriod, numPeriods, numFrames)
end

# High level read. numFrames can adress a future frame. Data is read in
# chunks
function readData(rp::RedPitaya, startFrame, numFrames)
  dec = rp.decimation
  numSampPerPeriod = rp.samplesPerPeriod
  numSamp = numSampPerPeriod * numFrames
  numPeriods = rp.periodsPerFrame
  numSampPerFrame = numSampPerPeriod * numPeriods

  data = zeros(Int16, 2, numSampPerPeriod, numPeriods, numFrames)
  wpRead = startFrame
  l=1

  # This is a wild guess for a good chunk size
  chunkSize = max(1,  round(Int, 1000000 / numSampPerFrame)  )
  println("chunkSize = $chunkSize")
  while l<=numFrames
    wpWrite = currentFrame(rp)
    while wpRead >= wpWrite # Wait that startFrame is reached
      wpWrite = currentFrame(rp)
      println(wpWrite)
    end
    chunk = min(wpWrite-wpRead,chunkSize) # Determine how many frames to read
    println(chunk)
    if l+chunk > numFrames
      chunk = numFrames - l + 1
    end

    println("Read from $wpRead until $(wpRead+chunk-1), WpWrite $(wpWrite), chunk=$(chunk)")

    u = readData_(rp, Int64(wpRead), Int64(chunk))

    data[:,:,:,l:(l+chunk-1)] = u

    l += chunk
    wpRead += chunk
  end

  return data
end
