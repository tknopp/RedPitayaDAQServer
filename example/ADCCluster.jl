using RedPitayaDAQServer
using GR

#rp = RedPitayaCluster(["192.168.1.9"])
rp = RedPitayaCluster(["10.167.6.172"])
connectADC(rp)

dec = 16
modulus = 4800
frequency = 25000
base_frequency = 125000000
#samples_per_period_base = base_frequency/frequency
samples_per_period = div(modulus, dec) #samples_per_period_base/dec

#samples_per_period = samples_per_period*2
periods_per_frame = 1

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)

modeDAC(rp, "RASTERIZED")
modulusDAC(rp, 1, 1, 1, 4800)
modulusFactorDAC(rp, 1, 1, 1, 1)

println(frequencyDAC(rp,1,1,1))
#send(rp, "RP:DAC:CH0:COMP0:FREQ $(frequency)")
amplitudeDAC(rp, 1, 1, 1, 4000)
phaseDAC(rp, 1, 1, 1, 0 ) # Phase has to be given in between 0 and 1
masterTrigger(rp, false)
ramWriterMode(rp, "TRIGGERED")

startADC(rp)
masterTrigger(rp, true)

sleep(1.0)
# Low Level
#u = RedPitayaDAQServer.readData_(rp, currentFrame(rp), 1)
# High Level
println(decimation(rp))

u = readData(rp, currentFrame(rp), 1)

plot(vec(u[1,:,1,:,:]))

disconnect(rp)
