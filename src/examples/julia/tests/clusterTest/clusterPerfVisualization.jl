using RedPitayaDAQServer
using PyPlot
using DataFrames
using Query
using CSV


function visualizeDeltaRead(testName, start, clusterSize, decimations=[64, 32, 16, 8]) 
    figure(1)
    clf()
    plotIndex = 1
    for rps = start:clusterSize
        for dec in decimations
            fileName = string(testName, "_detailed_rpc_$rps", "_dec_$dec")
            fullName = joinpath(@__DIR__, string(fileName, ".csv"))
            try 
                df = DataFrame(CSV.File(fullName))
                adcBufferSize  = (1 << 25)
                subplot(length(start:clusterSize), length(decimations), plotIndex)
                hlines([adcBufferSize / adcBufferSize], xmin=-10, xmax=110)
                for i = 1:rps
                    perf = @from r in df begin
                    @where r.rp == i
                    @select {r.wpRead, r.deltaRead, r.deltaSend}
                    @collect DataFrame
                    end
                    plot(perf.deltaRead / adcBufferSize)
                end
                plotIndex += 1
            catch e
                if !isa(e, ArgumentError)
                    throw(e)
                else 
                    println("$fullName does not exist")
                end
            end
        end
    end
    subplots_adjust(left=0.08, bottom=0.05, right=0.98, top=0.95, wspace=0.3, hspace=0.35)
    savefig(joinpath(@__DIR__, string(testName, "_deltaRead.png")))
    println("Created ", testName, "_deltaRead.png")
end

 

function visualizeWaitAndSend(testName, clusterSize, decimations=[64, 32, 16, 8])
    figure(1)
    clf()
    plotIndex = 1
    for dec in decimations
        for redPitayaIndex = 1:clusterSize
            fileName = string(testName, "_detailed_rpc_$clusterSize", "_dec_$dec")
            fullName = joinpath(@__DIR__, string(fileName, ".csv"))
            subplot(length(decimations), clusterSize, plotIndex)
            try 
                df = DataFrame(CSV.File(fullName))
                perf = @from r in df begin
                @where r.rp == redPitayaIndex
                @select {r.wpRead, r.deltaRead, r.deltaSend}
                @collect DataFrame
            end
                waitTime = zeros(UInt64, length(perf.wpRead))
                for i = 2:length(perf.wpRead)
                    wpLastRequestDone = perf.wpRead[i - 1] + perf.deltaRead[i - 1] + perf.deltaSend[i - 1]
                    wait = perf.wpRead[i] + perf.deltaRead[i] - wpLastRequestDone 
                    waitTime[i] = wait
                end
                plot(perf.deltaSend, label="Send")
                plot(waitTime, label="Wait")
                plotIndex += 1
            catch   e
                println(e)
            end
        end
    end
    subplots_adjust(left=0.08, bottom=0.05, right=0.98, top=0.95, wspace=0.3, hspace=0.35)
    resultFile = string(testName, "_sendAndWait_cluster_$clusterSize.png")
    savefig(joinpath(@__DIR__, resultFile))
    println("Created ", resultFile)
end