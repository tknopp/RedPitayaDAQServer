using RedPitayaDAQServer
using CairoMakie

# obtain the URL of the RedPitaya
include("config.jl")

# Establish connection to the RedPitaya
rp = RedPitaya(URLs[1])

# Set server in CONFIGURATION mode, s.t. we can prepare our signal generation + acquisition
serverMode!(rp, CONFIGURATION) # or serverMode!(rp, "CONFIGURATION")

dec = 32
base_frequency = 125000000
samples_per_period = 200
periods_per_frame = 1

# ADC Configuration
# These commands are only allowed in CONFIGURATION mode
decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)
triggerMode!(rp, INTERNAL) # or triggerMode!(rp, "INTERNAL")

stepsPerFrame!(rp, 2)
seqChan!(rp, 1)
seq = SimpleSequence([0.0, 0.5], 50)
sequence!(rp, seq)

# Start signal generation + acquisition
# The trigger can only be set in ACQUISITION mode

firEnabled!(rp, true)
serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)

# Dimensions of frames are [samples channel, period, frame]
uFIREnabled = readFrames(rp, 0, 1, correct_filter_delay=false, useCalibration=true)

masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)


firEnabled!(rp, false)
stepsPerFrame!(rp, 2)
seqChan!(rp, 1)
seq = SimpleSequence([0.0, 0.5], 50)
sequence!(rp, seq)

serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)


# Dimensions of frames are [samples channel, period, frame]
uFIRDisabled = readFrames(rp, 0, 1, correct_filter_delay=false, useCalibration=true)

masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)


# Frame dimensions are [samples, chan, periods, frames]
fig = Figure()
ax1 = Axis(fig[1,1])
scatterlines!(ax1, vec(uFIREnabled[:,1,:,:]), label = "FIR Enabled")
vlines!([RedPitayaDAQServer.correctFilterDelay(100,dec, fir_enabled=true)],color=1)
scatterlines!(ax1, vec(uFIRDisabled[:,1,:,:]), label = "FIR disabled")
vlines!([RedPitayaDAQServer.correctFilterDelay(100,dec, fir_enabled=false)], color=2)
axislegend(ax1, position=:rb)
#axislegend(ax2)
xlims!(ax1,(95,150))
save(joinpath(@__DIR__(), "images", "FIRDelay.png"), fig)
fig
#

