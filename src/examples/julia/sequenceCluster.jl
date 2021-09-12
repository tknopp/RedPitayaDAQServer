using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitayaCluster(URLs[1:3])

dec = 8
modulus = 4800
base_frequency = 125000000
periods_per_step = 10
samples_per_period = div(modulus, dec)#*periods_per_step
periods_per_frame = 100 # about 0.5 s frame length
frame_period = dec*samples_per_period*periods_per_frame / base_frequency

slow_dac_steps_per_frame = div(periods_per_frame, periods_per_step)

stopADC(rp)
masterTrigger(rp, false)
clearSequence(rp)

decimation(rp, dec)
samplesPerPeriod(rp, samples_per_period)
periodsPerFrame(rp, periods_per_frame)
passPDMToFastDAC(rp, [true, true, false])
slowDACStepsPerFrame(rp, slow_dac_steps_per_frame)

numSlowDACChan(master(rp), 1)
numSlowDACChan(rp[2], 1)
lut = collect(range(0,0.3,length=slow_dac_steps_per_frame))

lutEnableDACA = ones(Bool, slow_dac_steps_per_frame)
lutEnableDACA[1:2:end] .= false
lutEnableDACB = ones(Bool, slow_dac_steps_per_frame)
lutEnableDACB[2:2:end] .= false

modeDAC(rp, "STANDARD")
frequencyDAC(rp,1,1, base_frequency / modulus)
frequencyDAC(rp,3, 1, base_frequency / modulus)


freq = frequencyDAC(rp,1,1)
jumpSharpnessDAC(rp, 1, 0.01) # controls the sharpness of the jump for the square
signalTypeDAC(rp, 1 , "SQUARE")
phaseDAC(rp, 1, 1, 0.0 ) # Phase has to be given in between 0 and 1
freq = frequencyDAC(rp,3,1)
jumpSharpnessDAC(rp, 3, 0.01) # controls the sharpness of the jump for the square
signalTypeDAC(rp, 3 , "SQUARE")
phaseDAC(rp, 3, 1, 0.0 ) # Phase has to be given in between 0 and 1
amplitudeDAC(rp, 1, 1, 0.1) 
amplitudeDAC(rp, 3, 1, 0.1) 
offsetDAC(rp, 1, -0.01)
offsetDAC(rp, 3, -0.025)


ramWriterMode(rp, "TRIGGERED")
triggerMode(rp, "EXTERNAL")

seq1 = ArbitrarySequence(lut, lutEnableDACA, slow_dac_steps_per_frame, 1, 0.0, 0.0)
appendSequence(rp, 1, seq1)
seq2 = ArbitrarySequence(lut, lutEnableDACB, slow_dac_steps_per_frame, 1, 0.0, 0.0)
appendSequence(rp, 2, seq2)
success = prepareSequence(rp)

startADC(rp)
masterTrigger(rp, true)

uCurrentPeriod = readData(rp, 0, 1)

fig = figure(1)
clf()
plot(vec(uCurrentPeriod[:,1,:,:]))
plot(vec(uCurrentPeriod[:,3,:,:]))
legend(("Rx1", "Rx2"))

stopADC(rp)
masterTrigger(rp, false)
clearSequence(rp)

fig