using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitayaCluster([URLs[1]])

dec = 64
modulus = 4864
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 5

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
passPDMToFastDAC(master(rp), true)

modeDAC(rp, "STANDARD")
ramWriterMode(rp, "TRIGGERED")
triggerMode(rp, "EXTERNAL")


masterTrigger(rp, false)

frequencyDAC(rp, 1, 1, base_frequency / 4864)
signalTypeDAC(rp, 1 , "SINE")
amplitudeDAC(rp, 1, 1, 0.9)
offsetDAC(master(rp), 1, 0)
phaseDAC(rp, 1, 1, 0.0 )

samplesPerSlowDACStep(rp, div(4800, dec))
numSlowDACChan(master(rp), 1)
seq1 = PauseSequence(nothing, periods_per_frame, 1, true)
seq2 = PauseSequence(nothing, periods_per_frame, 1, true)
seq3 = PauseSequence(nothing, periods_per_frame, 1, true)
seq4 = PauseSequence(nothing, periods_per_frame, 1, true)
seq5 = PauseSequence(nothing, periods_per_frame, 1)
appendSequence(master(rp), seq1)
appendSequence(master(rp), seq2)
appendSequence(master(rp), seq3)
appendSequence(master(rp), seq4)
appendSequence(master(rp), seq5)
prepareSequence(master(rp))


startADC(rp)
masterTrigger(rp, true)




samples1 = readPipelinedSamples(rp, 0, 5 * div(4800, dec))
samples2 = readPipelinedSamples(rp, (length(seq1) + start(seq2)) * div(4800, dec), 5 * div(4800, dec))
samples3 = readPipelinedSamples(rp, (length(seq1) + length(seq2) + start(seq3)) * div(4800, dec), 5 * div(4800, dec))
samples4 = readPipelinedSamples(rp, (length(seq1) + length(seq2) + length(seq3) + start(seq4)) * div(4800, dec), 5 * div(4800, dec))
samples5 = readPipelinedSamples(rp, (length(seq1) + length(seq2) + length(seq3) + length(seq4) + start(seq5)) * div(4800, dec), 5 * div(4800, dec))
samplesAll = readPipelinedSamples(rp, 0, (length(seq1) + length(seq2) + length(seq3) + length(seq4) + length(seq5)) * div(4800, dec))
stopADC(rp)
masterTrigger(rp, false)

fig = figure(1)
clf()
subplot(3, 1, 1)
plot(vec(samples1[1, :]))
plot(vec(samples2[1, :]))
subplot(3, 1, 2)
#plot(vec(samples1[1, :]))
plot(vec(samples2[1, :]))
#subplot(6, 1, 3)
plot(vec(samples3[1, :]))
#subplot(6, 1, 4)
plot(vec(samples4[1, :]))
#subplot(6, 1, 5)
plot(vec(samples5[1, :]))
subplot(3, 1, 3)
plot(vec(samplesAll[1, :]))
fig