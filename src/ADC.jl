export decimation, samplesPerPeriod, periodsPerFrame, masterTrigger, currentFrame,
     ramWriterMode, connectADC, startADC, stopADC, readData


decimation(rp::RedPitaya) = query(rp,"RP:ADC:DECimation?", Int64)
decimation(rp::RedPitaya, dec) =
         send(rp, string("RP:ADC:DECimation ", Int64(dec)))

samplesPerPeriod(rp::RedPitaya) = query(rp,"RP:ADC:PERiod?", Int64)
samplesPerPeriod(rp::RedPitaya, dec) =
         send(rp, string("RP:ADC:PERiod ", Int64(dec)))

periodsPerFrame(rp::RedPitaya) = query(rp,"RP:ADC:FRAme?", Int64)
periodsPerFrame(rp::RedPitaya, dec) =
        send(rp, string("RP:ADC:FRAme ", Int64(dec)))

currentFrame(rp::RedPitaya) = query(rp,"RP:ADC:FRAMES:CURRENT?", Int64)

function masterTrigger(rp::RedPitaya, val::Bool)
  valStr = val ? "ON" : "OFF"
  send(rp, string("RP:MasterTrigger ", valStr))
end

# "TRIGGERED" or "CONTINUOUS"
function ramWriterMode(rp::RedPitaya, mode::String)
  send(rp, string("RP:RamWriterMode ", mode))
end

connectADC(rp::RedPitaya) = query(rp, "RP:ADC:ACQCONNect")
startADC(rp::RedPitaya) = send(rp, "RP:ADC:ACQSTATUS ON")
stopADC(rp::RedPitaya) = send(rp, "RP:ADC:ACQSTATUS OFF")

function readData(rp::RedPitaya, startFrame, numFrames)
  N = samplesPerPeriod(rp)
  command = string("RP:ADC:FRAMES:DATA ",Int64(startFrame),",",Int64(numFrames))
  send(rp, command)

  u = read(rp.dataSocket, Int16, 2 * numFrames * N)
  return reshape(u,2,N,numFrames)
end

###fprintf(cli, 'RP:ADC:FRAMES:DATA %d,1\n', currect_frame);

#data = int32(zeros(1, samples_per_period*periods_per_frame));
###data = int32(fread(con, 300*samples_per_period*periods_per_frame, 'int32'));
