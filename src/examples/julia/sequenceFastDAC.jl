using RedPitayaDAQServer
using PyPlot
using ThreadPools

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
slow_dac_periods_per_frame = div(20, periods_per_step)

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
passPDMToFastDAC(master(rp), true)

modeDAC(rp, "STANDARD")
ramWriterMode(rp, "TRIGGERED")
triggerMode(rp, "EXTERNAL")

# Sequence
# Global Settings
slowDACStepsPerFrame(rp, slow_dac_periods_per_frame) # This sets PDMClockDivider, but it can also be set directly and with slowDACStepsPerSequence
numSlowDACChan(master(rp), 1)
# Per Sequence settings
lut = collect(range(0,0.7,length=slow_dac_periods_per_frame))
seq = ArbitrarySequence(lut, nothing, slow_dac_periods_per_frame, 1, 0, 0)
config = fastDACConfig(seq)
frequencyDAC(config,1,1, base_frequency / modulus)
signalTypeDAC(config, 1 , "SINE")
amplitudeDAC(config, 1, 1, 0.2)
phaseDAC(config, 1, 1, 0.0 )
appendSequence(master(rp), seq)

seq2 = ConstantSequence([-0.2], nothing, slow_dac_periods_per_frame, 1, 0, 0)
config2 = fastDACConfig(seq2)
# Only updates values
amplitudeDAC(config2, 1, 1, 0.8)
appendSequence(master(rp), seq2)

seq3 = ConstantSequence([-0.2], nothing , slow_dac_periods_per_frame, 1, 0, 0)
config3 = fastDACConfig(seq3)
amplitudeDAC(config3, 1, 1, 0.4)
appendSequence(master(rp), seq3)
success = prepareSequence(master(rp))

masterTrigger(rp, false)
startADC(rp)
masterTrigger(rp, true)

sleep(0.1)

uCurrentFrame = readFrames(rp, 0, 3)
stopADC(rp)
masterTrigger(rp, false)
clearSequence(rp)

fig = figure(1)
clf()
plot(vec(uCurrentFrame[:,1,:,:]))
plot(vec(uCurrentFrame[:,2,:,:]))
legend(("Rx1"))
fig