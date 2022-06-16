using RedPitayaDAQServer
using PyPlot

include("config.jl")

rp = RedPitaya(URLs[1])

# All commands to the RedPitaya have a reply. Usually this reply is returned by the respective function.
# This means a function can only return upon receiving its reply.
# If a fast configuration of the RedPitaya is important and the commands don't depend on  the previous reply,
# then it is possible to first send all commands before reading all replies in the correct order.

# Here we show simple.jl but configure the RedPitaya in a "batch". We use do-syntax for the function and 
# macros to fill the batch, but it is also possible to do the same manually:
# batch = ScpiBatch()
# push!(batch, serverMode! => (CONFIGURATION))
# ...
# execute!(rp, batch)

# With the do-syntax we open a batch called "batch". This batch gets executed at the end of its block.
# With the @add_batch macro we add a usual command to the given batch to be executed in order
replies = execute!(rp) do batch
  dec = 32
  modulus = 12480
  base_frequency = 125000000
  samples_per_period = div(modulus, dec)
  periods_per_frame = 2

  # These two commands don't communicate with the RedPitaya
  samplesPerPeriod!(rp, samples_per_period)
  periodsPerFrame!(rp, periods_per_frame)

  @add_batch batch serverMode!(rp, CONFIGURATION)
  @add_batch batch decimation!(rp, dec)
  @add_batch batch triggerMode!(rp, INTERNAL)
  @add_batch batch frequencyDAC!(rp, 1, 1, base_frequency / modulus)
  @add_batch batch signalTypeDAC!(rp, 1, 1, SINE)
  @add_batch batch amplitudeDAC!(rp, 1, 1, 0.5)
  @add_batch batch offsetDAC!(rp, 1, 0)
  @add_batch batch phaseDAC!(rp, 1, 1, 0.0)
  @add_batch batch serverMode!(rp, ACQUISITION)
  @add_batch batch masterTrigger!(rp, true)
end

# All replies of the server could be accessed are returned and could be accessed with 
# replies = execute!(rp) do batch 
#   ...
# end
# replies[1]

# Commands that receive samples or transmit a LUT to the RedPitaya can not be executed in a batch
uFirstPeriod = readFrames(rp, 0, 2)
sleep(0.1)
fr = currentFrame(rp)
uCurrentPeriod = readFrames(rp, fr, 2)
sleep(0.2)
uLastPeriod = readFrames(rp, currentFrame(rp), 2)
masterTrigger!(rp, false)
serverMode!(rp, CONFIGURATION)

figure(1)
clf()
# Frame dimensions are [samples, chan, periods, frames]
plot(vec(uFirstPeriod[:,1,:,:]))
plot(vec(uCurrentPeriod[:,1,:,:]))
plot(vec(uLastPeriod[:,1,:,:]))
legend(("first period", "current period", "last period"))
savefig("images/batch.png")