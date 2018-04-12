using RedPitayaDAQServer
using GR

rp = RedPitaya("rp-f04972.local")

dec = 16
modulus = 4800
frequency = 25000
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 1

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)

modeDAC(rp, "RASTERIZED")
for (i,val) in enumerate([4800,4864,4800,4800])
  modulusDAC(rp, 1, i, val)
  modulusFactorDAC(rp, 1, i, 1)
end

println(" frequency = $(frequencyDAC(rp,1,1))")
#send(rp, "RP:DAC:CH0:COMP0:FREQ $(frequency)")
amplitudeDAC(rp, 1, 1, 4000)
phaseDAC(rp, 1, 1, 0 ) # Phase has to be given in between 0 and 1
masterTrigger(rp, false)
ramWriterMode(rp, "TRIGGERED")

sleep(1.0)
# Low Level
#u = RedPitayaDAQServer.readData_(rp, currentFrame(rp), 1)
# High Level
#u = readData(rp, currentFrame(rp), 1)
u = readData(rp, 0, 1)

plot(vec(u[:,1,:,:]))

disconnect(rp)
