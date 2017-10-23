using RedPitayaDAQServer
using GR

#rp = RedPitaya("192.168.1.9")
rp = RedPitaya("10.167.6.172")

dec = 16
frequency = 25000
base_frequency = 125000000
samples_per_period_base = base_frequency/frequency
samples_per_period = samples_per_period_base/dec

samples_per_period = samples_per_period*2
periods_per_frame = 1

samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
decimation(rp, dec)
#send(rp, "RP:DAC:CH0:COMP0:FREQ $(frequency)")
amplitudeDAC(rp, 1, 1, 400)
#phaseDAC(rp, 1, 1, 90.0/180*pi) # Does not work
masterTrigger(rp, false)
ramWriterMode(rp, "TRIGGERED")
connectADC(rp)
startADC(rp)
masterTrigger(rp, true)

sleep(1.0)
# Low Level
#u = RedPitayaDAQServer.readData_(rp, currentFrame(rp), 1)
# High Level
u = readData(rp, currentFrame(rp), 10)

plot(vec(u[1,:,:]))

disconnect(rp)
