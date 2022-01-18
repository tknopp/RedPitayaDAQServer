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

stopADC(rp)
masterTrigger(rp, false)
clearSequence(rp)

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
slowDACStepsPerFrame(rp, slow_dac_periods_per_frame)

fig = figure(1)
clf()

amplitudeDAC(rp, 1, 1, 0.1) 
#First sequence
lut1 = [0.2]
seq1 = ConstantSequence(lut1, nothing, slow_dac_periods_per_frame, 2, computeRamping(master(rp), frame_period * 1, 0.5))

#Second sequence
lut2 = collect(range(0,0.7,length=slow_dac_periods_per_frame))
seq2 = ArbitrarySequence(lut2, nothing, slow_dac_periods_per_frame, 2, computeRamping(master(rp), 0.0, 0.0))

# Prepare both
appendSequence(master(rp), seq1)
appendSequence(master(rp), seq2)
success = prepareSequence(master(rp))
startADC(rp)
masterTrigger(rp, true)
sleep(0.1)

uCurrentFrame = readFrames(rp, 0, 7)
stopADC(rp)
masterTrigger(rp, false)
clearSequence(rp)

plot(vec(uCurrentFrame[:, 1, :, :]))
title("Two sequences")
fig