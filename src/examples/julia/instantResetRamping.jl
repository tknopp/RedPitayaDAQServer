using RedPitayaDAQServer
using CairoMakie

# obtain the URL of the RedPitaya
include("config.jl")

rp = RedPitaya(URLs[1])

serverMode!(rp, CONFIGURATION)

dec = 32
modulus = 12480*64
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 2

decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)
triggerMode!(rp, INTERNAL)
frequencyDAC!(rp, 1, 1, base_frequency / modulus)
signalTypeDAC!(rp, 1 , 1, SINE)
amplitudeDAC!(rp, 1, 1, 0.5)
offsetDAC!(rp, 1, 0)
phaseDAC!(rp, 1, 1, 0.0)

frequencyDAC!(rp, 2, 1, base_frequency / modulus)
signalTypeDAC!(rp, 2, 1, SINE)
amplitudeDAC!(rp, 2, 1, 0.4)
offsetDAC!(rp, 2, 0)
phaseDAC!(rp, 2, 1, pi/2)

# Enable the instant reset triggered by DIO3_P
enableInstantReset!(rp, true)
# Ramping
# Ramping commands can be specified for each channel individually
enableRamping!(rp, 1, true)
enableRamping!(rp, 2, true)

rampingDAC!(rp, 1, 100/(base_frequency/modulus)) # Ramp for 10 Periods = 5 Frames
rampingDAC!(rp, 2, 100/(base_frequency/modulus)) # Ramp for 10 Periods = 5 Frames


# Start signal generation + acquisition
# Ramp Up starts with trigger start
serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)

# Instant Reset
# Now one should connect the instant reset DIO3_P with 3.3 Volt (i.e. set it to high)
# and the result will be a ramp down that can be seen on an oscilloscope

while !instantResetTriggered(rp)
    @info "Instant Reset not triggered yet."
    sleep(1)
end
@info "Instant Reset is triggered!"

sleep(10)
# To run the script again, one needs to run
masterTrigger!(rp, false)

