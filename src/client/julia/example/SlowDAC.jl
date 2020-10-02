using RedPitayaDAQServer
using PyPlot

rp = RedPitaya("rp-f04972.local")
#rp = RedPitaya("192.168.178.46")

dec = 64
modulus = 4800
base_frequency = 125000000
periods_per_step = 5
samples_per_period = div(modulus, dec)*periods_per_step
periods_per_frame = div(50, periods_per_step) # about 0.5 s frame length
frame_period = dec*samples_per_period*periods_per_frame / base_frequency
slow_dac_periods_per_frame = periods_per_frame

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
passPDMToFastDAC(rp, true)

slowDACPeriodsPerFrame(rp, slow_dac_periods_per_frame)
numSlowDACChan(rp, 1)
lut = collect(range(0,0.7,length=slow_dac_periods_per_frame))
setSlowDACLUT(rp, lut)

modeDAC(rp, "STANDARD")
frequencyDAC(rp,1,1, base_frequency / modulus)

freq = frequencyDAC(rp,1,1)
println(" frequency = $(freq)")
signalTypeDAC(rp, 1 , "SINE")
amplitudeDACNext(rp, 1, 1, 0.2)
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1

ramWriterMode(rp, "TRIGGERED")
triggerMode(rp, "INTERNAL")
masterTrigger(rp, false)
startADC(rp)
masterTrigger(rp, true)

sleep(0.1)

currFr = enableSlowDAC(rp, true, 2, frame_period, 0.5)
uCurrentFrame = readData(rp, currFr, 2)

figure(1)
clf()
plot(vec(uCurrentFrame[:,1,:,:]))
plot(vec(uCurrentFrame[:,2,:,:]))
legend(("Rx1", "Rx2"))

stopADC(rp)
