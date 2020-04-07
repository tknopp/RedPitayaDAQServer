using RedPitayaDAQServer
using PyPlot

rp = RedPitaya("rp-f04972.local")

dec = 64
modulus = 4800
base_frequency = 125000000
periods_per_step = 1
samples_per_period = div(modulus, dec)*periods_per_step
periods_per_frame = div(10, periods_per_step) # about 0.5 s frame length

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
numSlowDACChan(rp, 1)
lut = collect(range(0,1,length=periods_per_frame))
#lut[1:2:end] .= 0
setSlowDACLUT(rp, lut)

modeDAC(rp, "RASTERIZED")
for (i,val) in enumerate([4800,4864,4800,4800])
  modulusDAC(rp, 1, i, val)
  modulusFactorDAC(rp, 1, i, 1)
end

println(" frequency = $(frequencyDAC(rp,1,1))")
amplitudeDAC(rp, 1, 1, 4000)
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1
ramWriterMode(rp, "TRIGGERED")

numTrials = 50



signals = zeros(samples_per_period*periods_per_frame, 2, numTrials)

for i=1:numTrials
    @info "measure trial $i"
    masterTrigger(rp, false)
    startADC(rp, 0)
    masterTrigger(rp, true)
    currFr = enableSlowDAC(rp, true, 1, 0.5, 1.0)
    data = readData(rp, currFr, 1)
    signals[:,1,i] .= vec(data[:,1,:,:])
    signals[:,2,i] .= vec(data[:,2,:,:])
    stopADC(rp)
end

figure(1)
clf()
subplot(2,1,1)
for i=1:numTrials
  plot(vec(signals[:,1,i]))
end
subplot(2,1,2)
for i=1:numTrials
  plot(vec(signals[:,2,i]))
end
