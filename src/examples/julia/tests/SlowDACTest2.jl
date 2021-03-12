using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("../config.jl")

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
slowDACStepsPerRotation(rp, periods_per_frame)
passPDMToFastDAC(master(rp), true)
numSlowDACChan(master(rp), 1)
lut = collect(range(0,0.7,length=periods_per_frame))
setSlowDACLUT(master(rp), lut)

modeDAC(rp, "STANDARD")
frequencyDAC(rp, 1, 1, base_frequency / modulus)

println(" frequency = $(frequencyDAC(rp,1,1))")
amplitudeDACNext(rp, 1, 1, 0.2)
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1
ramWriterMode(rp, "TRIGGERED")
triggerMode(rp, "INTERNAL")

numTrials = 10
rpInfo = RPInfo(rp)

signals = zeros(samples_per_period*periods_per_frame * 4, 2, numTrials)
for i=1:numTrials
    @info "measure trial $i"
    masterTrigger(rp, false)
    startADC(rp)
    masterTrigger(rp, true)
    local currFr = enableSlowDAC(rp, true, 1, 0.000000768, 0.5)
    data = readFrames(rp, currFr -2, 4, rpInfo = rpInfo)
    #data = readData(rp, currFr - 2, 4, rpInfo = rpInfo)
    signals[:,1,i] .= vec(data[:,1,:,:])
    signals[:,2,i] .= vec(data[:,2,:,:])
    stopADC(rp)
end

fig = figure(1)
clf()
subplot(2,1,1)
for i=1:numTrials
  plot(vec(signals[:,1,i]))
end
subplot(2,1,2)
for i=1:numTrials
  plot(vec(signals[:,2,i]))
end