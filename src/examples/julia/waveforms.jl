using RedPitayaDAQServer
using PyPlot

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitaya(URLs[1])
serverMode!(rp, CONFIGURATION)

dec = 32
modulus = 12480
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 2
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

signals = zeros(4*N)

figure(1)
clf()

color = ["g", "b", "orange", "k"]
for (i,name) in enumerate(["SINE", "TRIANGLE", "SAWTOOTH"])
  # Set different waveforms
  signalTypeDAC!(rp, 1, 1, name)
  serverMode!(rp, ACQUISITION)
  masterTrigger!(rp, false)
  masterTrigger!(rp, true)
  local fr = 1
  local uFirstPeriod = readFrames(rp, fr, 1)
  subplot(2,2,i)
  masterTrigger!(rp, false)
  serverMode!(rp, CONFIGURATION)
  plot(vec(uFirstPeriod[:,1,:,:]),color[i])
  title(name)
end

# Fourth component of each channel is used for arbitrary waveforms
frequencyDAC!(rp,1, 4, base_frequency / modulus)
amplitudeDAC!(rp, 1, 1, 0.0)
wave = ArbitraryWaveform(0, 6*pi) do x
  if x < pi
    0.0
  elseif x < 2*pi
    0.5 * (x-pi)/pi
  elseif x <= 4*pi
    0.5 + 0.2*sin(2*(x-2*pi))
  elseif x <= 5*pi
    0.5 - (0.5*(x-4*pi)/pi)
  else
    0.0
  end
end
waveformDAC!(rp, 1, wave)
serverMode!(rp, ACQUISITION)
masterTrigger!(rp, false)
masterTrigger!(rp, true)
fr = 1
uFirstPeriod = readFrames(rp, fr, 1)
subplot(2,2,4)
masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)
plot(vec(uFirstPeriod[:,1,:,:]),"k")
title("Arbitrary")

subplots_adjust(left=0.08, bottom=0.05, right=0.98, top=0.95, wspace=0.3, hspace=0.35)
savefig("images/waveforms.png")
