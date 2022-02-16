# Client
This page contains documentation of the public API of the Julia client. In the Julia
REPL one can access this documentation by entering the help mode with `?` and
then writing the function for which the documentation should be shown.
## Connection and Communication
```@docs
RedPitayaDAQServer.RedPitaya
RedPitayaDAQServer.RedPitaya(::String, ::Int64, ::Int64, ::Bool)
RedPitayaDAQServer.send(::RedPitaya, ::String)
RedPitayaDAQServer.query
RedPitayaDAQServer.receive
RedPitayaDAQServer.RedPitayaCluster
RedPitayaDAQServer.RedPitayaCluster(::Vector{String}, ::Int64, ::Int64)
RedPitayaDAQServer.master
```
## ADC Configuration
```@docs
RedPitayaDAQServer.TriggerMode
RedPitayaDAQServer.triggerMode
RedPitayaDAQServer.triggerMode!
RedPitayaDAQServer.keepAliveReset
RedPitayaDAQServer.keepAliveReset!
RedPitayaDAQServer.decimation
RedPitayaDAQServer.decimation!
RedPitayaDAQServer.numChan
RedPitayaDAQServer.samplesPerPeriod
RedPitayaDAQServer.samplesPerPeriod!
RedPitayaDAQServer.periodsPerFrame
RedPitayaDAQServer.periodsPerFrame!
```
## DAC Configuration
```@docs
RedPitayaDAQServer.amplitudeDAC
RedPitayaDAQServer.amplitudeDAC!
RedPitayaDAQServer.offsetDAC
RedPitayaDAQServer.offsetDAC!
RedPitayaDAQServer.frequencyDAC
RedPitayaDAQServer.frequencyDAC!
RedPitayaDAQServer.phaseDAC
RedPitayaDAQServer.phaseDAC!
RedPitayaDAQServer.jumpSharpnessDAC
RedPitayaDAQServer.jumpSharpnessDAC!
RedPitayaDAQServer.SignalType
RedPitayaDAQServer.signalTypeDAC
RedPitayaDAQServer.signalTypeDAC!
RedPitayaDAQServer.numSeqChan
RedPitayaDAQServer.numSeqChan!
RedPitayaDAQServer.samplesPerStep
RedPitayaDAQServer.samplesPerStep!
RedPitayaDAQServer.stepsPerFrame!
RedPitayaDAQServer.AbstractSequence
RedPitayaDAQServer.appendSequence!
RedPitayaDAQServer.prepareSequence!
RedPitayaDAQServer.clearSequences!
RedPitayaDAQServer.popSequence!
RedPitayaDAQServer.length(::AbstractSequence)
RedPitayaDAQServer.start
RedPitayaDAQServer.ArbitrarySequence
RedPitayaDAQServer.ArbitrarySequence(lut, enable, repetitions, upSteps, upTotalSteps, downSteps, downTotalSteps, reset)
```
## Measurement and Transmission
```@docs
RedPitayaDAQServer.ServerMode
RedPitayaDAQServer.serverMode
RedPitayaDAQServer.serverMode!
RedPitayaDAQServer.masterTrigger
RedPitayaDAQServer.masterTrigger!
RedPitayaDAQServer.currentWP
RedPitayaDAQServer.currentFrame
RedPitayaDAQServer.currentPeriod
RedPitayaDAQServer.SampleChunk
RedPitayaDAQServer.PerformanceData
RedPitayaDAQServer.readPipelinedSamples
RedPitayaDAQServer.readFrames
RedPitayaDAQServer.convertSamplesToFrames
RedPitayaDAQServer.calibDACOffset
RedPitayaDAQServer.calibDACOffset!
RedPitayaDAQServer.calibADCOffset
RedPitayaDAQServer.calibADCOffset!
RedPitayaDAQServer.calibADCScale
RedPitayaDAQServer.calibADCScale!
```