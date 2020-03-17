using RedPitayaDAQServer
using PyPlot
using ProgressMeter

rp = RedPitaya("rp-f04972.local")

dec = 64
modulus = 4800
base_frequency = 125000000
samples_per_period = div(modulus, dec) # 10 fold averaging
periods_per_frame = 1300*10

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
numSlowDACChan(rp, 1)
setSlowDACLUT(rp, collect(range(0,1,length=periods_per_frame)))

modeDAC(rp, "RASTERIZED")
for (i,val) in enumerate([4800,4864,4800,4800])
  modulusDAC(rp, 1, i, val)
  modulusFactorDAC(rp, 1, i, 1)
end

amplitudeDAC(rp, 1, 1, 4000)
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1
masterTrigger(rp, false)
ramWriterMode(rp, "TRIGGERED")

startADC(rp)
masterTrigger(rp, true)

sleep(1.0)
# About 4 minutes
numFrames = 200
currFr = enableSlowDAC(rp, true, numFrames, 0.0, 1.0)

@showprogress 1 "Acquisition..." for l=1:numFrames
  uCurrentPeriod = readData(rp, currFr+l-1, 1)

  lostSteps = numLostStepsSlowADC(rp)
  if lostSteps > 0
    error("WE LOST $lostSteps SLOW DAC STEPS!")
  end
end
