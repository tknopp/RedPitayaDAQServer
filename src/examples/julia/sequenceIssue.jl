using RedPitayaDAQServer
using CairoMakie

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitaya(URLs[1])
serverMode!(rp, CONFIGURATION)


dec = 128
base_frequency = 125000000

samples_per_step = 40 #30*16
steps_per_frame = 4
numSamples = steps_per_frame * samples_per_step

decimation!(rp, dec)
samplesPerPeriod!(rp, 1)
periodsPerFrame!(rp, numSamples)
samplesPerStep!(rp, samples_per_step)
triggerMode!(rp, INTERNAL)


amplitudeDAC!(rp, 1, 1, 0.0)
amplitudeDAC!(rp, 2, 1, 0.0 )

clearSequence!(rp)

# Climbing offset for first channel, fixed offset for second channel
seqChan!(rp, 6)
lutB = collect(ones(steps_per_frame))
lutB[1:2:end] .= 0.0
lut = collect(cat(-lutB,-lutB*0.3, 0*lutB,0*lutB,0*lutB,0*lutB,dims=2)')
#lut = collect(cat(-lutB,dims=2)')#,lutB,lutB,lutB,lutB,dims=2)')

lutEnableDACA = ones(Bool, steps_per_frame)

#enableLUT = collect( cat(lutEnableDACA,lutEnableDACA,lutEnableDACA,lutEnableDACA,lutEnableDACA,lutEnableDACA,dims=2)' )
enableLUT = collect( cat(lutEnableDACA,lutEnableDACA,lutEnableDACA,lutEnableDACA,lutEnableDACA,lutEnableDACA,dims=2)' )
#enableLUT = collect( cat(lutEnableDACA,dims=2)') #,lutEnableDACA,lutEnableDACA,lutEnableDACA,lutEnableDACA,dims=2)' )

seq = SimpleSequence(lut, 300, enableLUT)
sequence!(rp, seq)

serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)

uCurrentPeriod = readFrames(rp, 1, 3)

masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)

plot = lines(vec(uCurrentPeriod[:,1,:,1]), label = "Rx1")
lines!(plot.axis, vec(uCurrentPeriod[:,2,:,1]), label = "Rx2")
lines!(plot.axis, vec(uCurrentPeriod[:,1,:,2]), label = "Rx1_2")
lines!(plot.axis, vec(uCurrentPeriod[:,2,:,2]), label = "Rx2_2")
axislegend(plot.axis)
save(joinpath(@__DIR__(), "images", "sequenceIssue.png"), plot)
plot