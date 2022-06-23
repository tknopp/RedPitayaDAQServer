using RedPitayaDAQServer
using ThreadPools
using PyPlot

include("config.jl")

# Note that this example is intended to be used with at least three threads (start Julia with option -t 3)

rp = RedPitaya(URLs[1])
if serverMode(rp) == ACQUISITION
    masterTrigger!(rp, false)
end

serverMode!(rp, CONFIGURATION)

# With a decimation of 8 a single RedPitay produces 500 Mbit/s of samples
# and samples exist within the buffer for around 2 seconds before being overwritten.
dec = 8
streamTime = 10
modulus = 12500
base_frequency = 125000000
samples_per_period = div(modulus, dec)
periods_per_frame = 2

samplesInStream = streamTime * (base_frequency/dec)
numFrames = div(samplesInStream, samples_per_period * periods_per_frame)

decimation!(rp, dec)
samplesPerPeriod!(rp, samples_per_period)
periodsPerFrame!(rp, periods_per_frame)
triggerMode!(rp, INTERNAL)

frequencyDAC!(rp, 1, 1, base_frequency / modulus)
signalTypeDAC!(rp, 1, 1, SINE)
amplitudeDAC!(rp, 1, 1, 0.5)
offsetDAC!(rp, 1, 0)
phaseDAC!(rp, 1, 1, 0.0 )

serverMode!(rp, ACQUISITION)
masterTrigger!(rp, true)

# Reading at such high data rates requires a client with a thread mostly focuesd on just receiving samples

# Reading the desired samples frame by frame introduces a large communication overhead as well as the constant conversion
# from samples to frames
#=
frames = []
readFrames = 0
while readFrames < numFrames
    frame = readFrames(rp, readFrames, 1)
    push!(frames, frame)
end
=#

# Reading all frames in one function call reduces communication overhead and requires only one conversion.
# However, with this approach a client application has to wait the whole duration before being able to use the frames
#=
frames = readFrames(rp, 0, numFrames)
=#

# One can use one thread dedicated to receiving just the samples (the producer) and one thread dedicated to performing computations on samples (the consumer).
# If the consumer is quick enough the producer should be able to receive samples continously, which allows the server to transmit continously.
# An example of such a pattern is shown in the following lines of code.
samples_per_frame = samples_per_period * periods_per_frame
channel = Channel{SampleChunk}(32)
# Start producer
@info "Start Producer"
producer = @tspawnat 2 readSamples(rp, 0, Int64(numFrames * samples_per_frame), channel)
# Associate life time of channel with execution time of producer
bind(channel, producer)
# Consumer
buffer = zeros(Float32, samples_per_period, 2, periods_per_frame, Int64(numFrames))
performance = Vector{Vector{PerformanceData}}()
consumer = @tspawnat 3 begin
    lostData = false
    sampleBuffer = nothing
    fr = 1
    to = 1
    @info "Start Consumer"
    while isopen(channel) || isready(channel)
        while isready(channel)
            chunk = take!(channel)

            # Collect samples
            samples = chunk.samples
            if !isnothing(sampleBuffer)
                sampleBuffer = hcat(sampleBuffer, samples)
            else
                sampleBuffer = samples
            end
            # Note that the chunk also contains status and performance values which can/should
            # be evaluated to see if data was lost
            perfs = chunk.performance
            for (i, p) in enumerate(perfs)
                if p.status.overwritten || p.status.corrupted
                    #@warn "RedPitaya $i lost data"
                    lostData = true
                end
            end
            perfs = chunk.performance
            push!(performance, perfs)          

            # Convert samples to frames if enough samples were transmitted
            frames = nothing
            framesInBuffer = div(size(sampleBuffer)[2], samples_per_frame)
            if framesInBuffer > 0
                samplesToConvert = view(sampleBuffer, :, 1:(samples_per_frame * framesInBuffer))
                frames = convertSamplesToFrames(rp, samplesToConvert, 2, samples_per_period, periods_per_frame, framesInBuffer)

                # Remove used samples
                samplesInBuffer = size(sampleBuffer)[2]
                if (samples_per_frame * framesInBuffer) + 1 <= samplesInBuffer
                    sampleBuffer = sampleBuffer[:, (samples_per_frame * framesInBuffer) + 1:samplesInBuffer]
                else
                    sampleBuffer = nothing
                end

                # Add frames to buffer (or perform other computations on them)
                to = fr + size(frames, 4) - 1
                buffer[:, :, :, fr:to] = frames
                fr = to + 1
            end
        end
        try 
            wait(channel)
        catch e
            # NOP
        end
    end
    @info "End Consumer"
    if lostData
        @info "Consumer lost data"
    end
    masterTrigger!(rp, false)
    serverMode!(rp, CONFIGURATION)
end