using RedPitayaDAQServer
using CairoMakie

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitaya(URLs[1])
serverMode!(rp, CONFIGURATION)

dec = 8
modulus = 128 
base_frequency = 125000000
periods_per_step = 1
samples_per_period = div(modulus, dec)
periods_per_frame = 1000
steps_per_frame = periods_per_frame 

time = collect(0:samples_per_period*periods_per_frame-1) ./ (base_frequency/dec)

decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)

freq = base_frequency / modulus / periods_per_frame

@info "Sampling Frequency: $(base_frequency / dec / 1e6) MS/s"
@info "Multiplexer Frequency: $(base_frequency / modulus / 1e6) MS/s"
@info "Effective Sampling Frequency: $(base_frequency / modulus / 1e3 / 8) kS/s"
@info "Tx Frequency: $freq Hz"

frequencyDAC!(rp,1,1, freq)
signalTypeDAC!(rp, 1 , 1, "SINE")
amplitudeDAC!(rp, 1, 1, 0.99)
phaseDAC!(rp, 1, 1, 0.0 )
frequencyDAC!(rp,2, 1, freq)
signalTypeDAC!(rp, 2 , 1, "SINE")
amplitudeDAC!(rp, 2, 1, 0.99*0)
phaseDAC!(rp, 2, 1, π/2*0 )
triggerMode!(rp, INTERNAL)

# Sequence Configuration
clearSequence!(rp)
stepsPerFrame!(rp, steps_per_frame)
seqChan!(rp, 1)
lut = collect(range(-0.5,0.5,length=steps_per_frame))*0
seq = SimpleSequence(lut, 1)
sequence!(rp, seq)

counterSamplesPerStep!(rp, modulus ÷ (dec) )

serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)

sleep(0.1)
uCurrentFrame = readFrames(rp, 0, 1)

masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)

fig = Figure(size = (1200, 600))
ax = Axis(fig[1, 1], title = "Multiplexer Test", xlabel = "Time [s]")
lines!(ax, time, vec(uCurrentFrame[:,1,:,:]), label = "Rx1")
lines!(ax, time, vec(uCurrentFrame[:,2,:,:]), label = "Rx2")
axislegend(ax)
#save(joinpath(@__DIR__(), "images", "sequence.png"), plot)
fig