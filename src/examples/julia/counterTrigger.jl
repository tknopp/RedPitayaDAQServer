using RedPitayaDAQServer
using CairoMakie
using Statistics
using Base.Threads

# For this example, the ports DIO7_P and DIO2_N have to be connected by a jumper cable.

# Obtain the URL of the RedPitaya
include("config.jl")

# Establish connection to the RedPitaya
rp = RedPitaya(URLs[1])

# Set server in CONFIGURATION mode, s.t. we can prepare our signal generation + acquisition
serverMode!(rp, CONFIGURATION) # or serverMode!(rp, "CONFIGURATION")

counterTrigger_reset!(rp)
counterTrigger_sourceType!(rp, COUNTER_TRIGGER_DIO)
counterTrigger_sourceChannel!(rp, DIO7_P)
DIODirection!(rp, DIO7_P, DIO_IN)
DIODirection!(rp, DIO2_N, DIO_OUT)
counterTrigger_enabled!(rp, true)

# This simulates a mechanical rotation with a 1 bit encoder which should be synchronized with the data acquisition
function rotationSimulation(timer)
    DIO!(rp, DIO2_N, true)
    sleep(0.1)
    DIO!(rp, DIO2_N, false)
end

timerInterval = 3
t = Timer(rotationSimulation, 0.05, interval=timerInterval)

@info "Determining average rotation time (in clock cycles)"
N = 5
counterValue = zeros(N)
i = 1
savedCounter = 0
outlierFactor = 2
while i <= N
  lastCounter = counterTrigger_lastCounter(rp)

  if lastCounter > timerInterval*1e9/8*outlierFactor || lastCounter < timerInterval*1e9/4/outlierFactor
    continue
  end

  if lastCounter != savedCounter
    global savedCounter = lastCounter
    counterValue[i] = savedCounter
    @info savedCounter
    global i += 1
  end
  
  sleep(0.1)
end

meanCounter = mean(counterValue)
@info "The average rotation time is $(meanCounter*8/1e9) s with a standard deviation of $(std(counterValue)*8/1e6) ms."

counterTrigger_referenceCounter!(rp, round(Int64, meanCounter))
counterTrigger_presamples!(rp, 50000000)

dec = 100
modulus = 5000
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 2

# ADC Configuration
# These commands are only allowed in CONFIGURATION mode
decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)
triggerMode!(rp, INTERNAL) # or triggerMode!(rp, "INTERNAL")

# DAC Configuration
# These commands are allowed during an acquisition
frequencyDAC!(rp, 1, 1, base_frequency / modulus)
signalTypeDAC!(rp, 1 , 1, SINE) # or signalTypeDAC!(rp, 1, "SINE")
amplitudeDAC!(rp, 1, 1, 0.5)
offsetDAC!(rp, 1, 0)
phaseDAC!(rp, 1, 1, 0.0)

# Start signal generation + acquisition
# The trigger can only be set in ACQUISITION mode
serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)
counterTrigger_arm!(rp)

# Transmit the first frame
uFirstPeriod = readFrames(rp, 0, 1)

sleep(0.1)

# Transmit the current frame
fr = currentFrame(rp)
# Dimensions of frames are [samples channel, period, frame]
uCurrentPeriod = readFrames(rp, fr, 1)
sleep(0.2)

uLastPeriod = readFrames(rp, currentFrame(rp), 1)

# Stop signal generation + acquisition
masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)

counterTrigger_enabled!(rp, false)

close(t)

plot = lines(vec(uFirstPeriod[:,1,:,:]), label = "first period")
lines!(plot.axis, vec(uCurrentPeriod[:,1,:,:]), label = "current period")
lines!(plot.axis, vec(uLastPeriod[:,1,:,:]), label = "last period")
axislegend(plot.axis)
save(joinpath(@__DIR__(), "images", "counterTrigger.png"), plot)
plot
#==
0: enable
1: trigger_arm
2: trigger_reset
3: trigger (trigger_out)
4: trigger_armed
5: DIO7_P
6: source_select[4]
7: triggerState
==#
