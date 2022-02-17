using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitaya(URLs[1])
serverMode!(rp, CONFIGURATION)

dec = 64
modulus = 12500
base_frequency = 125000000
periods_per_step = 5
samples_per_period = div(modulus, dec)
periods_per_frame = 50 # about 0.5 s frame length
frame_period = dec*samples_per_period*periods_per_frame / base_frequency
steps_per_frame = div(50, periods_per_step)

decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)

frequencyDAC!(rp,1,1, base_frequency / modulus)
signalTypeDAC!(rp, 1 , "SINE")
amplitudeDAC!(rp, 1, 1, 0.2)
phaseDAC!(rp, 1, 1, 0.0 )
triggerMode!(rp, INTERNAL)

# Sequence Configuration
clearSequences!(rp)
passPDMToFastDAC!(rp, true) # if set the sequence will be output in DAC-out
stepsPerFrame!(rp, steps_per_frame)
numSeqChan!(rp, 1)
lut = collect(range(0.1,0.7,length=steps_per_frame))
seq = ArbitrarySequence(lut, nothing, 2, 0, 0, 0, 0)
appendSequence!(rp, seq)
prepareSequences!(rp)

serverMode!(rp, MEASUREMENT)
masterTrigger!(rp, true)

sleep(0.1)
samples_per_step = (samples_per_period * periods_per_frame)/steps_per_frame
uCurrentFrame = readFrames(rp, div(start(seq)*samples_per_step, samples_per_period * periods_per_frame), 2)

fig = figure(1)
clf()
plot(vec(uCurrentFrame[:,1,:,:]))
plot(vec(uCurrentFrame[:,2,:,:]))
legend(("Rx1", "Rx2"))

masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)

savefig("images/sequence.png")