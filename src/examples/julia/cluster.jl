using RedPitayaDAQServer
using Plots

pyplot()
default(show = true)

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitayaCluster([URLs[1], URLs[2]])

dec = 64
modulus = 4800
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 3

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)

modeDAC(rp, "STANDARD")
frequencyDAC(rp, 1, 1, base_frequency / modulus)
frequencyDAC(rp, 3, 1, base_frequency / modulus)

println(" frequency = $(frequencyDAC(rp,1,1))")
amplitudeDAC(rp, 1, 1, 0.8)
amplitudeDAC(rp, 3, 1, 0.8)
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1
phaseDAC(rp, 1, 1, pi)

triggerMode(rp, "EXTERNAL")
ramWriterMode(rp, "TRIGGERED")
masterTrigger(rp, false)

startADC(rp)
masterTrigger(rp, true)

sleep(1.0)

uFirstPeriod = readData(rp, 0, 1)
uCurrentPeriod = readData(rp, currentFrame(rp), 1)
#RedPitayaDAQServer.disconnect(rp)


plot(vec(uFirstPeriod[:,1,:,:]))
#plot!(vec(uCurrentPeriod[:,1,:,:]))
plot!(vec(uFirstPeriod[:,3,:,:]))
#plot!(vec(uCurrentPeriod[:,3,:,:]))