using RedPitayaDAQServer
using CairoMakie
using FFTW
# obtain the URL of the RedPitaya
include("config.jl")

# Establish connection to the RedPitaya
rp = RedPitaya(URLs[1])

serverMode!(rp, CONFIGURATION)

dec = 32
modulus = 4800
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 5

# ADC Configuration
decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)
triggerMode!(rp, INTERNAL) # or triggerMode!(rp, "INTERNAL")

# DAC Configuration
frequencyDAC!(rp, 1, 1, base_frequency / modulus)
signalTypeDAC!(rp, 1, 1, SINE)
amplitudeDAC!(rp, 1, 1, 0.5)
offsetDAC!(rp, 1, 0)
phaseDAC!(rp, 1, 1, 0.0)

### Frequency component above the receive bandwidth, should not be visible in the spectrum
frequencyDAC!(rp, 1, 2, base_frequency/modulus*101)
signalTypeDAC!(rp, 1, 2, SINE)
amplitudeDAC!(rp, 1, 2, 0.2)
phaseDAC!(rp, 1, 2, 0.0)

### Frequency component at edge of passband
frequencyDAC!(rp, 1, 3, base_frequency/modulus*60)
signalTypeDAC!(rp, 1, 3, SINE)
amplitudeDAC!(rp, 1, 3, 0.1)
phaseDAC!(rp, 1, 3, 0.0)

# Start signal generation + acquisition

# Enable Anti-Aliasing FIR Filter
firEnabled!(rp, true)
serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)

sleep(0.1)

# Transmit the current frame
fr = currentFrame(rp)
# Dimensions of frames are [samples channel, period, frame]
uFIREnabled = readFrames(rp, fr, 1, correct_filter_delay=true, useCalibration=true)

masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)

# Disable Anti-Aliasing FIR Filter
firEnabled!(rp, false)

serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)

sleep(0.1)

# Transmit the current frame
fr = currentFrame(rp)
# Dimensions of frames are [samples channel, period, frame]
uFIRDisabled = readFrames(rp, fr, 1, correct_filter_delay=true, useCalibration=true)

masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)


# Frame dimensions are [samples, chan, periods, frames]
fig = Figure()
ax1 = Axis(fig[1,1])
lines!(ax1, vec(uFIREnabled[:,1,:,:]), label = "FIR Enabled")
lines!(ax1, vec(uFIRDisabled[:,1,:,:]), label = "FIR disabled")
axislegend(ax1)

ax2 = Axis(fig[1,2], yscale=log10)
lines!(ax2, abs.(rfft(vec(uFIREnabled[:,1,:,:])))/(samples_per_period*periods_per_frame/2), label = "FIR Enabled")
lines!(ax2, abs.(rfft(vec(uFIRDisabled[:,1,:,:])))/(samples_per_period*periods_per_frame/2), label = "FIR disabled")
annotation!(ax2, (50*periods_per_frame,0.001), text="Aliasing")
annotation!(ax2, (60*periods_per_frame,0.1), text="Unwanted \nAmplitude Drop \nin Passband")
#axislegend(ax2)
save(joinpath(@__DIR__(), "images", "FIREnable.png"), fig)
fig