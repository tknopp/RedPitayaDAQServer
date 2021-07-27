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
numSlowDACChan(master(rp), 1)

fig = figure(1)
clf()

amplitudeDAC(rp, 1, 1, 0.1) 
#First sequence
lut = [0.2]
rampUp(master(rp), frame_period * 2, 0.5)
sequenceRepetitions(master(rp), 1)
slowDACStepsPerFrame(rp, slow_dac_periods_per_frame)
setConstantLUT(master(rp), lut)
appendSequence(master(rp))

#Second sequence
lut = collect(range(0,0.7,length=slow_dac_periods_per_frame))
rampUp(master(rp), 0.0, 0.0)
sequenceRepetitions(master(rp), 2)
slowDACStepsPerFrame(rp, slow_dac_periods_per_frame)
setArbitraryLUT(master(rp), lut)
appendSequence(master(rp))

# Prepare both
success = prepareSequence(master(rp))
startADC(rp)
masterTrigger(rp, true)
sleep(0.1)

uCurrentFrame = readFrames(rp, 0, 7)
stopADC(rp)
masterTrigger(rp, false)


plot(vec(uCurrentFrame[:, 1, :, :]))
title("Ramping")
fig