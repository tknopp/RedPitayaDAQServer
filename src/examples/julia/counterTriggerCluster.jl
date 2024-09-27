using RedPitayaDAQServer
using CairoMakie
using Statistics
using Base.Threads

# For this example, the ports DIO7_P and DIO2_N have to be connected by a jumper cable.

# Obtain the URL of the RedPitaya
include("config.jl")

# Establish connection to the RedPitaya
rpc = RedPitayaCluster(URLs)

# Set server in CONFIGURATION mode, s.t. we can prepare our signal generation + acquisition
serverMode!(rpc, CONFIGURATION) # or serverMode!(rp, "CONFIGURATION")

counterTrigger_reset!(rpc)
counterTrigger_sourceType!(rpc, COUNTER_TRIGGER_DIO)
counterTrigger_sourceChannel!(rpc, DIO7_P)
DIODirection!(rpc[1], DIO7_P, DIO_IN)
DIODirection!(rpc[1], DIO2_N, DIO_OUT)
counterTrigger_enabled!(rpc, true)

# This simulates a mechanical rotation with a 1 bit encoder which should be synchronized with the data acquisition
function rotationSimulation(timer)
    DIO!(rpc[1], DIO2_N, true)
    sleep(0.1)
    DIO!(rpc[1], DIO2_N, false)
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
  lastCounter = counterTrigger_lastCounter(rpc)

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

counterTrigger_referenceCounter!(rpc, round(Int64, meanCounter))
counterTrigger_presamples!(rpc, 50000000)

dec = 100
modulus = 5000
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 2

# ADC Configuration
# These commands are only allowed in CONFIGURATION mode
decimation!(rpc, dec)
samplesPerPeriod!(rpc, samples_per_period)
periodsPerFrame!(rpc, periods_per_frame)
triggerMode!(rpc, INTERNAL) # or triggerMode!(rp, "INTERNAL")

# DAC Configuration
# These commands are allowed during an acquisition
frequencyDAC!(rpc, 1, 1, base_frequency / modulus)
signalTypeDAC!(rpc, 1 , 1, SINE) # or signalTypeDAC!(rp, 1, "SINE")
amplitudeDAC!(rpc, 1, 1, 0.5)
offsetDAC!(rpc, 1, 0)
phaseDAC!(rpc, 1, 1, 0.0)

# Start signal generation + acquisition
# The trigger can only be set in ACQUISITION mode
serverMode!(rpc, ACQUISITION)
masterTrigger!(rpc, true)
counterTrigger_arm!(rpc)

# Transmit the first frame
uFirstPeriod = readFrames(rpc, 0, 1)

sleep(0.1)

# Transmit the current frame
fr = currentFrame(rpc)
# Dimensions of frames are [samples channel, period, frame]
uCurrentPeriod = readFrames(rpc, fr, 1)
sleep(0.2)

uLastPeriod = readFrames(rpc, currentFrame(rpc), 1)

# Stop signal generation + acquisition
masterTrigger!(rpc, false)
serverMode!(rpc, CONFIGURATION)

counterTrigger_enabled!(rpc, false)

close(t)

chan = 3
# Frame dimensions are [samples, chan, periods, frames]
plot = lines(vec(uFirstPeriod[:,chan,:,:]), label = "first period")
lines!(plot.axis, vec(uCurrentPeriod[:,chan,:,:]), label = "current period")
lines!(plot.axis, vec(uLastPeriod[:,chan,:,:]), label = "last period")
axislegend(plot.axis)
save(joinpath(@__DIR__(), "images", "counterTriggerCluster.png"), plot)
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
