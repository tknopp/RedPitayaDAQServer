using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitaya(URLs[1])

dec = 64
modulus = 4800
base_frequency = 125000000
periods_per_step = 1
samples_per_period = div(modulus, dec)*periods_per_step
periods_per_frame = div(20, periods_per_step) # about 0.5 s frame length

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
passPDMToFastDAC(rp, true)
slowDACPeriodsPerFrame(rp, periods_per_frame)
numSlowDACChan(rp, 1)
lut = collect(range(0,0.7,length=periods_per_frame))
setSlowDACLUT(rp, lut)

modeDAC(rp, "STANDARD")
frequencyDAC(rp, 1, 1, base_frequency / modulus)

println(" frequency = $(frequencyDAC(rp,1,1))")
amplitudeDACNext(rp, 1, 1, 0.2)
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1
ramWriterMode(rp, "TRIGGERED")
triggerMode(rp, "INTERNAL")

numTrials = 10

signals = zeros(samples_per_period*periods_per_frame, 2, numTrials)

for i=1:numTrials
    @info "measure trial $i"
    masterTrigger(rp, false)
    startADC(rp, 0)
    masterTrigger(rp, true)
    local currFr = enableSlowDAC(rp, true, 1, 0.5, 1.0)
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
