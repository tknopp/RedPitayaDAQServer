using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitayaCluster([URLs[1]])

dec = 64
modulus = 4800
base_frequency = 125000000
periods_per_step = 5
samples_per_period = div(modulus, dec)
periods_per_frame = 50 # about 0.5 s frame length
frame_period = dec*samples_per_period*periods_per_frame / base_frequency
slow_dac_periods_per_frame = div(50, periods_per_step)

stopADC(rp)
masterTrigger(rp, false)
clearSequence(rp)


decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
passPDMToFastDAC(master(rp), true)

modeDAC(rp, "STANDARD")
frequencyDAC(rp,1,1, base_frequency / modulus)
masterTrigger(rp, false)

freq = frequencyDAC(rp,1,1)
println(" frequency = $(freq)")
signalTypeDAC(rp, 1 , "SINE")
amplitudeDAC(rp, 1, 1, 0.2)
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1

ramWriterMode(rp, "TRIGGERED")
triggerMode(rp, "INTERNAL")

slowDACStepsPerFrame(rp, slow_dac_periods_per_frame)
numSlowDACChan(master(rp), 1)


lut = collect(range(0,0.7,length=slow_dac_periods_per_frame))
seq1 = ArbitrarySequence(lut, nothing, slow_dac_periods_per_frame, 2, computeRamping(master(rp), frame_period * 2, 0.5))
appendSequence(master(rp), seq1)
seq2 = ArbitrarySequence(lut, nothing, slow_dac_periods_per_frame, 2, computeRamping(master(rp), frame_period * 4, 0.5), (0, 0))
appendSequence(master(rp), seq2)
seq3 = ArbitrarySequence(lut, nothing, slow_dac_periods_per_frame, 2, computeRamping(master(rp), 0.5, 0.5))
appendSequence(master(rp), seq3)
prepareSequence(master(rp))

masterTrigger(rp, false)
startADC(rp)
masterTrigger(rp, true)

sleep(0.1)
samples_per_step = (samples_per_period * periods_per_frame)/slow_dac_periods_per_frame
samples_per_frame = samples_per_period * periods_per_frame
firstSequence = readFrames(rp, div((0 + start(seq1)) * samples_per_step, samples_per_frame), 2)
secondSequence = readFrames(rp, div((length(seq1) + start(seq2)) * samples_per_step, samples_per_frame), 2)
thirdSequence = readFrames(rp, div((length(seq1) + length(seq2) + start(seq3)) * samples_per_step, samples_per_frame), 2)

fig = figure(1)
clf()
subplot(3, 1, 1)
plot(vec(firstSequence[:,1,:,:]))
subplot(3, 1, 2)
plot(vec(secondSequence[:,1,:,:]))
subplot(3, 1, 3)
plot(vec(thirdSequence[:,1,:,:]))

stopADC(rp)
masterTrigger(rp, false)
clearSequence(rp)

fig