using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitaya(URLs[1])
serverMode!(rp, CONFIGURATION)

dec = 32
modulus = 12500
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 10
N = samples_per_period * periods_per_frame

decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)
triggerMode!(rp, INTERNAL)

frequencyDAC!(rp,1,1, base_frequency / modulus)
amplitudeDAC!(rp, 1, 1, 0.5)
offsetDAC!(rp, 1, 0.1)
phaseDAC!(rp, 1, 1, 0.0 )
# Controls the sharpness of the jump for the square
jumpSharpnessDAC!(rp, 1, 0.01)


signals = zeros(4*N)

figure(1)
clf()

color = ["g", "b", "orange", "k"]
for (i,name) in enumerate(["SINE", "SQUARE", "TRIANGLE", "SAWTOOTH"])
  # Set different waveforms
  signalTypeDAC!(rp, 1 , name)
  serverMode!(rp, MEASUREMENT)
  masterTrigger!(rp, false)
  masterTrigger!(rp, true)
  local fr = 1
  local uFirstPeriod = readFrames(rp, fr, 1) # read 2nd frame
  subplot(2,2,i)
  masterTrigger!(rp, false)
  serverMode!(rp, CONFIGURATION)
  plot(vec(uFirstPeriod[:,1,:,:]),color[i])
  title(name)
end
subplots_adjust(left=0.08, bottom=0.05, right=0.98, top=0.95, wspace=0.3, hspace=0.35)
savefig("images/waveforms.png")
