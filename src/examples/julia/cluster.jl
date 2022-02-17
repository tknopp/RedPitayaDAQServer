using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

# Establish connection to two RedPitayas. First is treated as master
rpc = RedPitayaCluster([URLs[1], URLs[2]])
# Function calls that should affect the whole cluster are distributed to all RedPitayas
serverMode!(rpc, CONFIGURATION)

dec = 32
modulus = 12500
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 2

decimation!(rpc, dec)
samplesPerpceriod!(rpc, samples_per_period)
periodsPerFrame!(rpc, periods_per_frame)
# In a cluster setting RedPitayas should listen to the external triggered
triggerMode!(rpc, EXTERNAL)

# A cluster of size n is treated as having 2*n channels
# SCPI commands are distributed accordingly
frequencyDAC!(rpc, 1, 1, base_frequency / modulus)
frequencyDAC!(rpc, 3, 1, base_frequency / modulus)
# It is also possible to call functions directly on the RedPitayas in a cluster
# as long as the function only affects on RedPitaya
signalTypeDAC!(rpc[1], 1 , SINE)
signalTypeDAC!(rpc[2], 1 , SINE) # Same as signalTypeDAC!(rpc, 3, SINE)
amplitudeDAC!(rpc, 1, 1, 0.8)
amplitudeDAC!(rpc, 3, 1, 0.8)
phaseDAC!(rpc, 1, 1, 0.0) 
phaseDAC!(rpc, 3, 1, pi)

serverMode!(rpc, MEASUREMENT)
masterTrigger!(rpc, true)

uFirstPeriod = readFrames(rpc, 0, 1)
sleep(0.2)
uCurrentPeriod = readFrames(rpc, currentFrame(rpc), 1)

masterTrigger!(rpc, false)
serverMode!(rpc, CONFIGURATION)

figure(1)
clf()
subplot(2, 1, 1)
plot(vec(uFirstPeriod[:,1,:,:]))
plot(vec(uFirstPeriod[:,3,:,:]))
legend(("Channel 1", "Channel 3"))
plot(vec(uCurrentPeriod[:,1,:,:]))
plot(vec(uCurrentPeriod[:,3,:,:]))
legend(("Channel 1", "Channel 3"))
savefig("images/cluster.png")