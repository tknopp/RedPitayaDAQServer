using RedPitayaDAQServer
using Statistics
using DataFrames
using CSV

include("../../config.jl")


baseFrequency = 125000000

function configureCluster(rpc::RedPitayaCluster, dec, modulus=4800, periods_per_frame=10)
    samples_per_period = div(modulus, dec)
    decimation(rpc, dec)
    samplesPerPeriod(rpc, samples_per_period)
    periodsPerFrame(rpc, periods_per_frame)
    modeDAC(rpc, "STANDARD")
    triggerMode(rpc, "EXTERNAL")
    ramWriterMode(rpc, "TRIGGERED")
    
    for rp in rpc.rp
        frequencyDAC(rp, 1, 1, baseFrequency/modulus)
        amplitudeDACNext(rp, 1, 1, 0.5)
        phaseDAC(rp, 1, 1, 0.0 ) 
        signalTypeDAC(rp, 2 , "SINE")
    
        frequencyDAC(rp, 2, 1, baseFrequency/modulus)
        amplitudeDACNext(rp, 2, 1, 0.5)
        phaseDAC(rp, 2, 1, 0.0 ) 
        signalTypeDAC(rp, 2 , "SINE")
    end
end

function readXFullBuffers(rpc::RedPitayaCluster, rpInfo::RPInfo, x)
    adcBufferSize = (1 << 25)
    totalSamples = adcBufferSize * x
    println("ADC Start")
    masterTrigger(rpc, false)
    startADC(rpc)
    masterTrigger(rpc, true)
    readPipelinedSamples(rpc, 0, totalSamples, rpInfo=rpInfo, chunkSize = Int64(ceil(totalSamples/100)))
    stopADC(rpc)
    masterTrigger(rpc, false)
    println("ADC End")
    return totalSamples
end

function managedToReadAllSamples(rpInfo::RPInfo)
    for perf in rpInfo.performances
        for chunkPerf in perf.data
            if chunkPerf.status.overwritten || chunkPerf.status.corrupted
                return false
            end
        end
    end
    return true
end

struct LongTermResults
    readInit::Float64
    readMin::Float64
    readMax::Float64
    readMean::Float64
    readMedian::Float64
    readSTD::Float64
end

function longTermTestChunks(rpc, testTimeInSeconds=60, chunkTimeInSeconds=30)
    
    secondsRead = 0
    dec = decimation(rpc)
    numberOfChunks = Int64(ceil(testTimeInSeconds / chunkTimeInSeconds))
    println("Continously reading for $testTimeInSeconds sec. in groups of $chunkTimeInSeconds seconds")
    rpInfo = RPInfo(rpc)
    println("ADC Start")
    masterTrigger(rpc, false)
    startADC(rpc)
    masterTrigger(rpc, true)
    # frameStart = enableSlowDAC(rp, true, test_frames, 0.5, 1.0)
    println("Start reading samples")
    samplesRead = 0
    for i = 1:numberOfChunks
        currentChunk = min(testTimeInSeconds - secondsRead, chunkTimeInSeconds)
        samplesInChunk = Int64(ceil(currentChunk * (baseFrequency/dec)))
        println("Chunk $i started")
        @time readPipelinedSamples(rpc, samplesRead,  samplesInChunk, rpInfo = rpInfo, chunkSize = 10066330)
        samplesRead += samplesInChunk
        secondsRead += currentChunk
        println("Chunk $i ended")
    end
    println("End reading samples")
    stopADC(rpc)
    println("ADC Stop")
    
    println("Computing Stats")
    results = LongTermResults[]
    adcBufferSize = (1 << 25)
    for (rp, perf) in enumerate(rpInfo.performances)
        deltaReads = [perf.data[i].adc.deltaRead / (adcBufferSize) for i = 1:length(perf.data)]
        init = deltaReads[1]
        readMean = mean(deltaReads)
        readMedian = median(deltaReads)
        readVariance = var(deltaReads)
        readStd = std(deltaReads)
        readMin = minimum(deltaReads)
        readMax = maximum(deltaReads)
        result = LongTermResults(init, readMin, readMax, readMean, readMedian, readStd)
        push!(results, result)
        println("DeltaRead Stats for RedPitaya $rp:")
        println("Init: $init")
        println("Min $readMin, Max $readMax")
        println("Mean $readMean, Median $readMedian")
        println("Standard Deviation $readStd")
    end
    return results
end

function persistRPInfo(fileName, rpInfo::RPInfo)
    df = DataFrame(rp = Int[], wpRead = Int[], deltaRead = Int[], deltaSend = Int[])
    for (i, perf) in enumerate(rpInfo.performances)
        # Somewhat inefficient
        for perfData in perf.data
            push!(df, (i, perfData.wpRead, perfData.adc.deltaRead, perfData.adc.deltaSend))
        end
    end
    CSV.write(string(fileName, ".csv"), df)
end

function persistLongTermResults(fileName, results::Array{LongTermResults,1})
    df = DataFrame(rp = Int[], readInit = Float64[], readMin = Float64[], readMax = Float64[], readMean = Float64[], readMedian = Float64[], readSTD = Float64[])
    for (i, result) in enumerate(results)
        push!(df, (i, result.readInit, result.readMin, result.readMax, result.readMean, result.readMedian, result.readSTD))
    end
    CSV.write(string(fileName, ".csv"), df)
end

function fullyTestCluster(connectionStrings, start=1, longTermTimeInSeconds= 60, testName="test"; availableBytes=2147483648)
    # Init Test, see if connections works, first compile of functions
    clusterTestValid = true
    try
        println("Testing if Cluster is valid")
        rpc = RedPitayaCluster(connectionStrings)
        configureCluster(rpc, 64)
        readXFullBuffers(rpc, RPInfo(rpc), 1)
        println()
    catch e
        println("Cluster Valid Test failed")
        println(e)
        clusterTestValid = false
    end

    if clusterTestValid
        # Detailed Test
        println("Detailed Tests")
        decToTest = [64, 32, 16, 8]
        workingCombinations = Pair{Int64, Int64}[]
        for dec in decToTest
            for i = start:length(connectionStrings)
                println("Detailed Test: Dec $dec and $i RedPitayas")
                rpc = RedPitayaCluster(collect(Iterators.take(connectionStrings, i)))
                configureCluster(rpc, dec)
                println("Configured RedPitayas")
                rpInfo = RPInfo(rpc)
                samplesRead = readXFullBuffers(rpc, rpInfo, 3)
                println("Finishing Test")
                persistRPInfo(joinpath(@__DIR__, string(testName, "_detailed_rpc_",i, "_dec_", dec)), rpInfo)
                if managedToReadAllSamples(rpInfo)
                    push!(workingCombinations, Pair(dec, i))
                else
                    println("Samples were lost")
                end
            end
        end

        println("")
        println("Long Term Tests")
        for p in workingCombinations
            dec = p.first
            i = p.second
            println("Long Term Test: Dec $dec and $i RedPitayas")
            rpc = RedPitayaCluster(collect(Iterators.take(connectionStrings, i)))
            configureCluster(rpc, dec)
            println("Configured RedPitayas")

            bytesPerRedPitaya = availableBytes / i
            samplesPerRedPitaya = bytesPerRedPitaya / 4
            timePerChunk =  Int64(ceil(samplesPerRedPitaya / (baseFrequency/dec)))
            timePerChunk = min(longTermTimeInSeconds, timePerChunk)

            results = longTermTestChunks(rpc, longTermTimeInSeconds, timePerChunk)
            
            println("Finishing Test")
            persistLongTermResults(joinpath(@__DIR__, string(testName, "_long_rpc_",i, "_dec_", dec)), results)
        end

    end
end