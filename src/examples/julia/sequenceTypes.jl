using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitayaCluster([URLs[1]])

dec = 64
modulus = 4800
base_frequency = 125000000
periods_per_step = 5
samples_per_period = div(modulus, dec)
periods_per_frame = 50 # about 0.5 s frame length
frame_period = dec*samples_per_period*periods_per_frame / base_frequency
slow_dac_periods_per_frame = div(50, periods_per_step)

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
passPDMToFastDAC(master(rp), true)

modeDAC(rp, "STANDARD")
frequencyDAC(rp,1,1, base_frequency / modulus)

freq = frequencyDAC(rp,1,1)
println(" frequency = $(freq)")
signalTypeDAC(rp, 1 , "SINE")
amplitudeDAC(rp, 1, 1, 0.1)
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1

ramWriterMode(rp, "TRIGGERED")
triggerMode(rp, "EXTERNAL")

# Sequence
slowDACStepsPerFrame(rp, slow_dac_periods_per_frame)
numSlowDACChan(master(rp), 1)
rampUp(master(rp), 0.0, 0.0)
sequenceRepetitions(master(rp), 2)

sleep(0.5)

fig = figure(1)
clf()

masterTrigger(rp, false)

# Lookup Sequence
amplitudeDAC(rp, 1, 1, 0.1)
lut = collect(range(0,0.7,length=slow_dac_periods_per_frame))
setLookupLUT(master(rp), lut)
appendSequence(master(rp))
success = prepareSequence(master(rp))
startADC(rp)
masterTrigger(rp, true)
sleep(0.1)

uCurrentFrame = readFrames(rp, 0, 3)
subplot(2,2, 1)
plot(vec(uCurrentFrame[:, 1, :, :]))
title("Arbitrary")
stopADC(rp)
masterTrigger(rp, false)

sleep(0.1)
# Constant Sequence
amplitudeDAC(rp, 1, 1, 0.1) # Amplitude is set to zero after a sequence
lut = [0.2]
slowDACStepsPerFrame(rp, slow_dac_periods_per_frame)
numSlowDACChan(master(rp), 1)
rampUp(master(rp), 0.0, 0.0)
sequenceRepetitions(master(rp), 2)
setConstantLUT(master(rp), lut)
appendSequence(master(rp))
success = prepareSequence(master(rp))
startADC(rp)
masterTrigger(rp, true)
sleep(0.1)

uCurrentFrame = readFrames(rp, 0, 3)
subplot(2,2, 2)
plot(vec(uCurrentFrame[:, 1, :, :]))
title("Constant")
stopADC(rp)
masterTrigger(rp, false)

sleep(0.1)
# Pause Sequence
amplitudeDAC(rp, 1, 1, 0.1)
slowDACStepsPerFrame(rp, slow_dac_periods_per_frame)
numSlowDACChan(master(rp), 1)
rampUp(master(rp), 0.0, 0.0)
sequenceRepetitions(master(rp), 2)
setPauseLUT(master(rp))
appendSequence(master(rp))
success = prepareSequence(master(rp))
startADC(rp)
masterTrigger(rp, true)
sleep(0.1)

uCurrentFrame = readFrames(rp, 0, 3)
subplot(2,2, 3)
plot(vec(uCurrentFrame[:, 1, :, :]))
title("Pause")
stopADC(rp)
masterTrigger(rp, false)

sleep(0.1)
# Range Sequence
amplitudeDAC(rp, 1, 1, 0.1)
slowDACStepsPerFrame(rp, slow_dac_periods_per_frame)
numSlowDACChan(master(rp), 1)
rampUp(master(rp), 0.0, 0.0)
sequenceRepetitions(master(rp), 2)
setRangeLUT(master(rp), [-1.0, 2.0/slow_dac_periods_per_frame])
appendSequence(master(rp))
success = prepareSequence(master(rp))
startADC(rp)
masterTrigger(rp, true)
sleep(0.1)

uCurrentFrame = readFrames(rp, 0, 3)
subplot(2,2, 4)
plot(vec(uCurrentFrame[:, 1, :, :]))
title("Range")
stopADC(rp)
masterTrigger(rp, false)

fig