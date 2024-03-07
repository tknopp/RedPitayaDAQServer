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
RedPitayaDAQServer.ServerMode
RedPitayaDAQServer.serverMode
RedPitayaDAQServer.serverMode!
RedPitayaDAQServer.ScpiBatch
RedPitayaDAQServer.@add_batch
RedPitayaDAQServer.execute!
RedPitayaDAQServer.push!(::ScpiBatch, ::Pair{K, T}) where {K<:Function, T<:Tuple}
RedPitayaDAQServer.pop!(::ScpiBatch)
RedPitayaDAQServer.clear!(::ScpiBatch)
RedPitayaDAQServer.RedPitayaCluster
RedPitayaDAQServer.RedPitayaCluster(::Vector{String}, ::Int64, ::Int64)
RedPitayaDAQServer.length(::RedPitayaCluster)
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
RedPitayaDAQServer.samplesPerPeriod
RedPitayaDAQServer.samplesPerPeriod!
RedPitayaDAQServer.periodsPerFrame
RedPitayaDAQServer.periodsPerFrame!
RedPitayaDAQServer.calibADCOffset
RedPitayaDAQServer.calibADCOffset!
RedPitayaDAQServer.calibADCScale
RedPitayaDAQServer.calibADCScale!
RedPitayaDAQServer.updateCalib!
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
RedPitayaDAQServer.SignalType
RedPitayaDAQServer.signalTypeDAC
RedPitayaDAQServer.signalTypeDAC!
RedPitayaDAQServer.seqChan
RedPitayaDAQServer.seqChan!
RedPitayaDAQServer.samplesPerStep
RedPitayaDAQServer.samplesPerStep!
RedPitayaDAQServer.stepsPerFrame!
RedPitayaDAQServer.clearSequence!
RedPitayaDAQServer.sequence!
RedPitayaDAQServer.calibDACOffset
RedPitayaDAQServer.calibDACOffset!
RedPitayaDAQServer.calibDACScale
RedPitayaDAQServer.calibDACScale!
RedPitayaDAQServer.calibDACUpperLimit!
RedPitayaDAQServer.calibDACLowerLimit!
```
## Measurement and Transmission
```@docs
RedPitayaDAQServer.masterTrigger
RedPitayaDAQServer.masterTrigger!
RedPitayaDAQServer.currentWP
RedPitayaDAQServer.currentFrame
RedPitayaDAQServer.currentPeriod
RedPitayaDAQServer.SampleChunk
RedPitayaDAQServer.PerformanceData
RedPitayaDAQServer.readSamples
RedPitayaDAQServer.readFrames
RedPitayaDAQServer.readPeriods
RedPitayaDAQServer.convertSamplesToFrames(::Union{RedPitaya, RedPitayaCluster, RedPitayaClusterView}, ::Any, ::Any, ::Any, ::Any, ::Any, ::Any, ::Any)
RedPitayaDAQServer.convertSamplesToPeriods!(::Union{RedPitaya, RedPitayaCluster, RedPitayaClusterView}, ::Any, ::Any, ::Any, ::Any, ::Any, ::Any)
```
## Slow IO
```@autodocs
Modules = [RedPitayaDAQServer]
Pages   = ["SlowIO.jl"]
```
## EEPROM and Calibration
```@autodocs
Modules = [RedPitayaDAQServer]
Pages   = ["EEPROM.jl"]
```
## Counter Trigger
```@autodocs
Modules = [RedPitayaDAQServer]
Pages   = ["CounterTrigger.jl"]
```
