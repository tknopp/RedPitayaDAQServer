using RedPitayaDAQServer
using PyPlot

include("config.jl")

# Alternative RedPitayaClusterView(URLs, [1, 3])
rpcv = RedPitayaClusterView(URLs, [true, false, true])

dec = 64
modulus = 4800
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 3

decimation(rpcv, dec)
samplesPerPeriod(rpcv, samples_per_period)
periodsPerFrame(rpcv, periods_per_frame)

# Cluster is configured as before, channel indices refer directly to channels in the cluster
modeDAC(rpcv, "STANDARD")
frequencyDAC(rpcv, 1, 1, base_frequency / modulus)
frequencyDAC(rpcv, 3, 1, base_frequency / modulus)
frequencyDAC(rpcv, 5, 1, base_frequency / modulus)


println(" frequency = $(frequencyDAC(rpcv,1,1))")
amplitudeDAC(rpcv, 1, 1, 0.5)
phaseDAC(rpcv, 1, 1, 0.0 ) #
signalTypeDAC(rpcv, 1, "SINE")

amplitudeDAC(rpcv, 3, 1, 0.5)
phaseDAC(rpcv, 3, 1, 0.0 )
signalTypeDAC(rpcv, 3, "SINE")

amplitudeDAC(rpcv, 5, 1, 0.5)
phaseDAC(rpcv, 5, 1, 0.0 )
signalTypeDAC(rpcv, 5, "SINE")


triggerMode(rpcv, "EXTERNAL")
ramWriterMode(rpcv, "TRIGGERED")
masterTrigger(rpcv, false)

startADC(rpcv)
masterTrigger(rpcv, true)

sleep(1.0)

# ClusterView only reads from selected RedPitayas
uCurrentPeriod = readData(rpcv, currentFrame(rpcv), 1)

fig = figure(1)
clf()
subplot(1,2,1)
plot(vec(uCurrentPeriod[:,1,:,:]))
# Channels from result can be mapped to channels in the cluster
PyPlot.title("Cluster channel $(translateViewToClusterChannel(rpcv,1))")
subplot(1,2,2)
plot(vec(uCurrentPeriod[:,3,:,:]))
PyPlot.title("Cluster channel $(translateViewToClusterChannel(rpcv,3))")