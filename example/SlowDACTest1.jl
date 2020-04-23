using RedPitayaDAQServer
using PyPlot
using ProgressMeter

#rp = RedPitayaCluster(["rp-f04972.local","rp-f044d6.local"])
rp = RedPitayaCluster(["rp-f04972.local"])

dec = 64
modulus = 4800
base_frequency = 125000000
periods_per_step = 50
samples_per_period = div(modulus, dec)*periods_per_step
periods_per_frame = div(13000, periods_per_step) # about 0.5 s frame length

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
slowDACPeriodsPerFrame(rp, periods_per_frame)
numSlowDACChan(master(rp), 2)
lut = collect(range(0,1,length=periods_per_frame))
setSlowDACLUT(master(rp), collect(repeat(lut,1,2)'))

modeDAC(rp, "STANDARD")
frequencyDAC(rp, 1, 1, base_frequency / modulus)

amplitudeDAC(rp, 1, 1, 4000)
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1
ramWriterMode(rp, "TRIGGERED")
triggerMode(rp, "INTERNAL")
masterTrigger(rp, false)
startADC(rp)
masterTrigger(rp, true)

sleep(1.0)
# About 4 minutes
numFrames = 200
currFr = enableSlowDAC(rp, true, numFrames, 0.0, 1.0)

@showprogress 1 "Acquisition..." for l=1:numFrames
  nextFr = currFr+l-1
  currFrame = currentFrame(rp)
  uCurrentPeriod = readData(rp, nextFr, 1)

  lostSteps = numLostStepsSlowADC(master(rp))
  if lostSteps > 0
    error("WE LOST $lostSteps SLOW DAC STEPS!")
  end
end
