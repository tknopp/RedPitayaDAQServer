using RedPitayaDAQServer
using PyPlot

rp = RedPitayaCluster(["192.168.20.39"])

dec = 32
modulus = 4800
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 10

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)

modeDAC(rp, "STANDARD")

frequencyDAC(rp, 1, 1, base_frequency / modulus)
println(" frequency = $(frequencyDAC(rp,1,1))")

signalTypeDAC(rp, 1 , "SINE")

amplitudeDAC(rp, 1, 1, 0.5)
offsetDAC(master(rp), 1, 0)
phaseDAC(rp, 1, 1, 0.0 )

ramWriterMode(rp, "TRIGGERED")
triggerMode(rp, "INTERNAL")
masterTrigger(rp, false)
startADC(rp)
masterTrigger(rp, true)
uFirstFrame = readFrames(rp, 0, 1)
sleep(0.1)
fr = currentFrame(rp)
@show fr

uCurrentFrame = readFrames(rp, fr, 1)

figure(1)
clf()
plot(vec(uFirstFrame[:,1,:,:]))
plot(vec(uCurrentFrame[:,1,:,:]))
legend(("first frame", "current frame"))