using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitaya(URLs[1])
serverMode!(rp, CONFIGURATION)

dec = 8
modulus = 12480
base_frequency = 125000000
periods_per_step = 10
samples_per_period = div(modulus, dec)
periods_per_frame = 100
frame_period = dec*samples_per_period*periods_per_frame / base_frequency

steps_per_frame = div(periods_per_frame, periods_per_step)
decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)
stepsPerFrame!(rp, steps_per_frame)
triggerMode!(rp, INTERNAL)

# Square waveform on first channel
frequencyDAC!(rp,1,1, base_frequency / modulus)
signalTypeDAC!(rp, 1, 1, SINE)
phaseDAC!(rp, 1, 1, 0.0)
amplitudeDAC!(rp, 1, 1, 0.1)

# No waveform on second channel
amplitudeDAC!(rp, 2, 1, 0.0)

clearSequence!(rp)

# Climbing offset for first channel, fixed offset for second channel
seqChan!(rp, 2)
lutA = collect(range(0,0.3,length=steps_per_frame))
lutB = collect(ones(steps_per_frame))
lut = collect(cat(lutA,lutB*0.1,dims=2)')

# Alternate in disabling the DAC output of the channels from step to step
lutEnableDACA = ones(Bool, steps_per_frame)
lutEnableDACA[1:2:end] .= false
lutEnableDACB = ones(Bool, steps_per_frame)
lutEnableDACB[2:2:end] .= false
enableLUT = collect( cat(lutEnableDACA,lutEnableDACB,dims=2)' )

seq = SimpleSequence(lut, 1, enableLUT)
sequence!(rp, seq)

serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)

uCurrentPeriod = readFrames(rp, 0, 1)

masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)

fig = figure(1)
clf()
plot(vec(uCurrentPeriod[:,1,:,:]))
plot(vec(uCurrentPeriod[:,2,:,:]))
legend(("Rx1", "Rx2"))


savefig("images/sequenceMultiChannelWithOffsetAndEnable.png")