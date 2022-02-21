using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

# Establish connection to the RedPitaya
rp = RedPitaya(URLs[1])

# Set server in CONFIGURATION mode, s.t. we can prepare our signal generation + acquisition
serverMode!(rp, CONFIGURATION) # or serverMode!(rp, "CONFIGURATION")

dec = 32
modulus = 12480
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 2

# ADC Configuration
# These commands are only allowed in CONFIGURATION mode
decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)
triggerMode!(rp, INTERNAL) # or triggerMode!(rp, "INTERNAL")

# DAC Configuration
# These commands are allowed during an acquisition
frequencyDAC!(rp, 1, 1, base_frequency / modulus)
signalTypeDAC!(rp, 1 , SINE) # or signalTypeDAC!(rp, 1, "SINE")
amplitudeDAC!(rp, 1, 1, 0.5)
offsetDAC!(rp, 1, 0)
phaseDAC!(rp, 1, 1, 0.0)

# Start signal generation + acquisition
# The trigger can only be set in ACQUISITION mode
serverMode!(rp, MEASUREMENT)
masterTrigger!(rp, true)

# Transmit the first frame
uFirstPeriod = readFrames(rp, 0, 1)

sleep(0.1)

# Transmit the current frame
fr = currentFrame(rp)
# Dimensions of frames are [samples channel, period, frame]
uCurrentPeriod = readFrames(rp, fr, 1)
sleep(0.2)

uLastPeriod = readFrames(rp, currentFrame(rp), 1)
# Stop signal generation + acquisition
masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)

figure(1)
clf()
# Frame dimensions are [samples, chan, periods, frames]
#plot(vec(uFirstPeriod[:,1,:,:]))
plot(vec(uCurrentPeriod[:,1,:,:]))
plot(vec(uLastPeriod[:,1,:,:]))
legend(("first period", "current period", "last period"))
savefig("images/simple.png")