using RedPitayaDAQServer
using PyPlot

rp = RedPitaya("rp-f04972.local")

dec = 64
modulus = 4800
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 3

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)

modeDAC(rp, "RASTERIZED")
for (i,val) in enumerate([4800,4864,4800,4800])
  modulusDAC(rp, 1, i, val)
  modulusFactorDAC(rp, 1, i, 1)
end

println(" frequency = $(frequencyDAC(rp,1,1))")
amplitudeDAC(rp, 1, 1, 4000)
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1
masterTrigger(rp, false)
ramWriterMode(rp, "TRIGGERED")

startADC(rp)
masterTrigger(rp, true)

sleep(0.1)

fr = currentFrame(rp)
@show fr
uFirstPeriod = readData(rp, 0, 1)
uCurrentPeriod = readData(rp, fr, 1)

figure(1)
clf()
plot(vec(uFirstPeriod[:,1,:,:]))
plot(vec(uCurrentPeriod[:,1,:,:]))
legend(("first period", "current period"))
