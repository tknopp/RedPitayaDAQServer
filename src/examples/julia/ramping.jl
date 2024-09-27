using RedPitayaDAQServer
using CairoMakie

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitaya(URLs[1])

serverMode!(rp, CONFIGURATION)

dec = 32
modulus = 12480
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 2

decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)
triggerMode!(rp, INTERNAL)
frequencyDAC!(rp, 1, 1, base_frequency / modulus)
signalTypeDAC!(rp, 1 , 1, SINE)
amplitudeDAC!(rp, 1, 1, 0.5)
offsetDAC!(rp, 1, 0)
phaseDAC!(rp, 1, 1, 0.0)

# Ramping
# Ramping commands can be specified for each channel individually
enableRamping!(rp, 1, true)
rampingDAC!(rp, 1, 10/(base_frequency/modulus)) # Ramp for 10 Periods = 5 Frames


# Start signal generation + acquisition
# Ramp Up starts with trigger start
serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)

uFirstPeriod = readFrames(rp, 0, 6)

sleep(0.5)
uCurrentPeriod = readFrames(rp, currentFrame(rp), 6)

# Start ramp down asynchronously
# Note that we might not see the actual ramping in this example, see seqRamping.jl for that
enableRampDown!(rp, 1, true)

uLastPeriod = readFrames(rp, currentFrame(rp), 6)

# Resetting the trigger also removes the ramp down flag
masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)
enableRamping!(rp, 1, false)

# Frame dimensions are [samples, chan, periods, frames]
plot = lines(vec(uCurrentPeriod[:,1,:,:]), label = "regular")
lines!(plot.axis, vec(uFirstPeriod[:,1,:,:]), label = "start")
lines!(plot.axis, vec(uLastPeriod[:,1,:,:]), label = "end")
axislegend(plot.axis)
save(joinpath(@__DIR__(), "images", "asyncRamping.png"), plot)
plot