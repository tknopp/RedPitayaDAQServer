using RedPitayaDAQServer
using CairoMakie

# obtain the URL of the RedPitaya
include("config.jl")

# Establish connection to the RedPitaya
rp = RedPitaya(URLs[1])

# Set server in CONFIGURATION mode, s.t. we can prepare our signal generation + acquisition
serverMode!(rp, CONFIGURATION) # or serverMode!(rp, "CONFIGURATION")

dec = 8
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
signalTypeDAC!(rp, 1 , 1, SINE) # or signalTypeDAC!(rp, 1, "SINE")
amplitudeDAC!(rp, 1, 1, 0.5)
offsetDAC!(rp, 1, 0)
phaseDAC!(rp, 1, 1, 0)

# Start signal generation + acquisition
# The trigger can only be set in ACQUISITION mode
serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)

# Transmit the first frame
uCorrected = readSamples(rp, 0, 45)
# Dimensions of frames are [samples channel, period, frame]
uUncorrected = readSamples(rp, 0, 45, correct_cic_delay = false, correct_fir_delay = false)

masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)

# Sample dimensions are [chan, samples]
plot = lines(vec(uCorrected[1, :]), label = "Corrected")
lines!(plot.axis, vec(uUncorrected[1, :]), label = "Uncorrected")
axislegend(plot.axis)
save(joinpath(@__DIR__(), "images", "delay.png"), plot)
plot