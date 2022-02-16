using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitaya(URLs[1])
serverMode!(rp, CONFIGURATION)

dec = 64
modulus = 4864
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 5

decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)
triggerMode!(rp, INTERNAL)

frequencyDAC!(rp, 1, 1, base_frequency / 4864)
signalTypeDAC!(rp, 1 , "SINE")
amplitudeDAC!(rp, 1, 1, 0.9)
offsetDAC!(rp, 1, 0)
phaseDAC!(rp, 1, 1, 0.0 )

clearSequences!(rp)
passPDMToFastDAC!(rp, true)
samplesPerStep!(rp, div(4800, dec)) # Samples per step out of "sync" with frequency
numSeqChan!(rp, 1)
# Reset phase after first 4 sequences
seq1 = RedPitayaDAQServer.PauseSequence(nothing, periods_per_frame, 1, true)
seq2 = RedPitayaDAQServer.PauseSequence(nothing, periods_per_frame, 1, true)
seq3 = RedPitayaDAQServer.PauseSequence(nothing, periods_per_frame, 1, true)
seq4 = RedPitayaDAQServer.PauseSequence(nothing, periods_per_frame, 1, true)
seq5 = RedPitayaDAQServer.PauseSequence(nothing, periods_per_frame, 1)
appendSequence!(rp, seq1)
appendSequence!(rp, seq2)
appendSequence!(rp, seq3)
appendSequence!(rp, seq4)
appendSequence!(rp, seq5)
prepareSequences!(rp)


serverMode!(rp, MEASUREMENT)
masterTrigger!(rp, true)




samples1 = readPipelinedSamples(rp, 0, 5 * div(4800, dec))
samples2 = readPipelinedSamples(rp, (length(seq1) + start(seq2)) * div(4800, dec), 5 * div(4800, dec))
samples3 = readPipelinedSamples(rp, (length(seq1) + length(seq2) + start(seq3)) * div(4800, dec), 5 * div(4800, dec))
samples4 = readPipelinedSamples(rp, (length(seq1) + length(seq2) + length(seq3) + start(seq4)) * div(4800, dec), 5 * div(4800, dec))
samples5 = readPipelinedSamples(rp, (length(seq1) + length(seq2) + length(seq3) + length(seq4) + start(seq5)) * div(4800, dec), 5 * div(4800, dec))
samplesAll = readPipelinedSamples(rp, 0, (length(seq1) + length(seq2) + length(seq3) + length(seq4) + length(seq5)) * div(4800, dec))

masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)


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