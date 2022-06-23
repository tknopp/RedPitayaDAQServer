using RedPitayaDAQServer
using PyPlot

include("config.jl")

rpc = RedPitayaCluster(URLs)
# Assumes 3 RedPitayas are connected
rpc = RedPitayaClusterView(rpc, [true, false, true])

dec = 64
modulus = 4800
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 3

serverMode!(rpc, CONFIGURATION)
decimation!(rpc, dec)
samplesPerPeriod!(rpc, samples_per_period)
periodsPerFrame!(rpc, periods_per_frame)

frequencyDAC!(rpc, 1, 1, base_frequency / modulus)
frequencyDAC!(rpc, 3, 1, base_frequency / modulus)
frequencyDAC!(rpc, 5, 1, base_frequency / modulus)


println(" frequency = $(frequencyDAC(rpc,1,1))")
amplitudeDAC!(rpc, 1, 1, 0.5)
phaseDAC!(rpc, 1, 1, 0.0 ) #
signalTypeDAC!(rpc, 1, 1, "SINE")

amplitudeDAC!(rpc, 3, 1, 0.5)
phaseDAC!(rpc, 3, 1, 0.0 )
signalTypeDAC!(rpc, 3, 1, "SINE")

amplitudeDAC!(rpc, 5, 1, 0.5)
phaseDAC!(rpc, 5, 1, 0.0 )
signalTypeDAC!(rpc, 5, 1, "SINE")


triggerMode!(rpc, "EXTERNAL")

serverMode!(rpc, ACQUISITION)
masterTrigger!(rpc, true)
sleep(1.0)

# ClusterView only reads from selected RedPitayas
uCurrentPeriod = readData(rpcv, currentFrame(rpc), 1)

fig = figure(1)
clf()
subplot(1,2,1)
plot(vec(uCurrentPeriod[:,1,:,:]))
# Channels from result can be mapped to channels in the cluster
PyPlot.title("Cluster channel $(viewToClusterChannel(rpcv,1))")
subplot(1,2,2)
plot(vec(uCurrentPeriod[:,3,:,:]))
PyPlot.title("Cluster channel $(viewToClusterChannel(rpcv,3))")