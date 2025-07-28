export seqChan, seqChan!, samplesPerStep, samplesPerStep!, stepsPerFrame!, AbstractSequence, SimpleSequence, sequence!, clearSequence!, HoldBorderRampingSequence, StartUpSequence, SequenceLUT, SimpleRampingSequence, seqTiming

"""
  seqChan(rp::RedPitaya)

Return the number of sequence channel.
"""
seqChan(rp::RedPitaya) = query(rp, scpiCommand(seqChan), scpiReturn(seqChan))
scpiCommand(::typeof(seqChan)) = "RP:DAC:SEQ:CHan?"
scpiReturn(::typeof(seqChan)) = Int64

"""
    seqChan!(rp::RedPitaya, value)

Set the number of sequence channel. Valid values are between `1` and `6`. Return `true` if the command was successful.
"""
function seqChan!(rp::RedPitaya, value)
  if value <= 0 || value > 6
    error("Num sequence channels needs to be between 1 and 6!")
  end
  return query(rp, scpiCommand(seqChan!, value), scpiReturn(seqChan!))
end
scpiCommand(::typeof(seqChan!), value) = string("RP:DAC:SEQ:CHan ", Int64(value))
scpiReturn(::typeof(seqChan!)) =  Bool

"""
    samplesPerStep(rp::RedPitaya)

Return the number of samples per sequence step.
"""
samplesPerStep(rp::RedPitaya) = query(rp, scpiCommand(samplesPerStep), scpiReturn(samplesPerStep))
scpiCommand(::typeof(samplesPerStep)) = "RP:DAC:SEQ:SAMP?"
scpiReturn(::typeof(samplesPerStep)) = Int64

"""
    samplesPerStep!(rp::RedPitaya, value::Integer)

Set the number of samples per sequence step. Return `true` if the command was successful.
"""
function samplesPerStep!(rp::RedPitaya, value::Integer)
  return query(rp, scpiCommand(samplesPerStep!, value), scpiReturn(samplesPerStep!))
end
scpiCommand(::typeof(samplesPerStep!), value) = string("RP:DAC:SEQ:SAMP ", value)
scpiReturn(::typeof(samplesPerStep!)) = Bool

"""
    stepsPerFrame!(rp::RedPitaya, stepsPerFrame)

Set the number of samples per steps s.t. `stepsPerFrame` sequence steps in a frame.

See [`samplesPerPeriod!`](@ref), [`periodsPerFrame!`](@ref), [`samplesPerStep!`](@ref).
"""
function stepsPerFrame!(rp::RedPitaya, stepsPerFrame)
  samplesPerFrame = rp.periodsPerFrame * rp.samplesPerPeriod
  samplesPerStep = div(samplesPerFrame, stepsPerFrame)
  return samplesPerStep!(rp, samplesPerStep)
end

"""
    setSequence!(rp::RedPitaya)

Instruct the server to set the current configured sequence for the next acquisition.
"""
setSequence!(rp::RedPitaya) = query(rp, scpiCommand(setSequence!), scpiReturn(setSequence!))
scpiCommand(::typeof(setSequence!)) = "RP:DAC:SEQ:SET"
scpiReturn(::typeof(setSequence!)) = Bool

"""
    clearSequence!(rp::RedPitaya)

Instruct the server to remove all sequences from its list. Return `true` if the command was successful.
"""
clearSequence!(rp::RedPitaya) = query(rp, scpiCommand(clearSequence!), scpiReturn(clearSequence!))
scpiCommand(::typeof(clearSequence!)) = "RP:DAC:SEQ:CLEAR"
scpiReturn(::typeof(clearSequence!)) = Bool

# Helper function for sequences
struct SequenceLUT
  values::Array{Float32}
  repetitions::Int
  function SequenceLUT(values::Array{Float32}, repetitions)
    if repetitions < 0
      throw(ArgumentError("Number of repetitions cannot be a negative number"))
    end
    return new(values, repetitions)
  end
end
values(seq::SequenceLUT) = seq.values
repetitions(seq::SequenceLUT) = seq.repetitions
length(seq::SequenceLUT) = seq.repetitions * size(seq.values, 2)

"""
    AbstractSequence

Abstract struct of client-side representation of a sequence.
"""
abstract type AbstractSequence end

"""
    SimpleSequence <: AbstractSequence

Struct representing a sequence in which the server directly takes the values from the given LUT.
"""
struct SimpleSequence <: AbstractSequence
  lut::SequenceLUT
  enable::Union{Matrix{Bool}, Nothing}
  resync::Union{Matrix{Bool}, Nothing}
  """
    SimpleSequence(lut, repetitions, enable=nothing)

  Constructor for `SimpleSequence`.

  # Arguments
  - `lut::Array{Float32}`: `n`x`m` matrix containing `m` steps for `n` channel
  - `repetitions::Int32`: the number of times the sequence should be repeated
  - `emable::Union{Array{Bool}, Nothing}`: matrix containing enable flags
  """
  function SimpleSequence(lut::Matrix{Float32}, repetitions::Integer, enable::Union{Matrix{Bool}, Nothing}=nothing, resync::Union{Matrix{Bool}, Nothing} = nothing)
    if !isnothing(enable) && size(lut) != size(enable)
      throw(DimensionMismatch("Size of enable LUT does not match size of value LUT"))
    end
    return new(SequenceLUT(lut, repetitions), enable, resync)
  end
end
SimpleSequence(lut::Array{T}, repetitions::Integer, args...) where T <: Real = SimpleSequence(map(Float32, lut), repetitions, args...)
SimpleSequence(lut::Vector{T}, repetitions::Integer, args...) where T <: Real = SimpleSequence(reshape(lut, 1, :), repetitions, args...)

enableLUT(seq::SimpleSequence) = seq.enable
resyncLUT(seq::SimpleSequence) = seq.resync
valueLUT(seq::SimpleSequence) = seq.lut
rampUpLUT(seq::SimpleSequence) = nothing
rampDownLUT(seq::SimpleSequence) = nothing

abstract type RampingSequence <: AbstractSequence end

struct SimpleRampingSequence <: AbstractSequence 
  lut::SequenceLUT
  enable::Union{Array{Bool}, Nothing}
  resync::Union{Array{Bool}, Nothing}
  rampUp::SequenceLUT
  rampDown::SequenceLUT
  function SimpleRampingSequencee(lut::SequenceLUT, up::SequenceLUT, down::SequenceLUT, enable::Union{Array{Bool}, Nothing}=nothing, resync::Union{Array{Bool}, Nothing}=nothing)
    if !isnothing(enable) && size(values(lut)) != size(enable)
      throw(DimensionMismatch("Size of enable LUT does not match size of value LUT"))
    end
    return new(SequenceLUT(lut, repetitions), enable, resync, up, down)
  end
end

enableLUT(seq::SimpleRampingSequence) = seq.enable
resyncLUT(seq::SimpleRampingSequence) = seq.resync
valueLUT(seq::SimpleRampingSequence) = seq.lut
rampUpLUT(seq::SimpleRampingSequence) = nothing
rampDownLUT(seq::SimpleRampingSequence) = nothing

function timePerStep(rp::RedPitaya)
  dec = decimation(rp)
  perStep = samplesPerStep(rp)
  return perStep/(125e6/dec)
end

struct HoldBorderRampingSequence <: RampingSequence
  lut::SequenceLUT
  enable::Union{Array{Bool}, Nothing}
  resync::Union{Array{Bool}, Nothing}
  rampUp::SequenceLUT
  rampDown::SequenceLUT

  """
      HoldBorderRampingSequence(lut::Array{Float32}, repetitions::Integer, rampingSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing)

  Constructor for `HoldBorderRampingSequence`.

  # Arguments
  - `lut`,`repetitions`,`enable` are used the same as for a `SimpleSequence`
  - `rampingSteps` is the number of steps the first and last value of the given sequence are repeated before the sequence is started
  """
  function HoldBorderRampingSequence(lut::Array{Float32}, repetitions::Integer, rampingSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing, resync::Union{Array{Bool}, Nothing}=nothing)
    if !isnothing(enable) && size(lut) != size(enable)
      throw(DimensionMismatch("Size of enable LUT does not match size of value LUT"))
    end
    up = SequenceLUT(lut[:, 1], rampingSteps)
    down = SequenceLUT(lut[:, end], rampingSteps)
    return new(SequenceLUT(lut, repetitions), enable, resync, up, down)
  end
end

HoldBorderRampingSequence(lut::Array{T}, repetitions::Integer, rampingSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing) where T <: Real = HoldBorderRampingSequence(map(Float32, lut), repetitions, rampingSteps, enable)
HoldBorderRampingSequence(lut::Vector{T}, repetitions::Integer, rampingSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing) where T <: Real = HoldBorderRampingSequence(reshape(lut, 1, :), repetitions, rampingSteps, enable)

function HoldBorderRampingSequence(rp::RedPitaya, lut, repetitions, enable=nothing)
  rampTime = maximum([rampingDAC(rp,i) for i=1:2 if enableRamping(rp, i)])
  rampingSteps = Int64(ceil(rampTime/timePerStep(rp)))
  return HoldBorderRampingSequence(lut, repetitions, rampingSteps, enable)
end

enableLUT(seq::HoldBorderRampingSequence) = seq.enable
resyncLUT(seq::HoldBorderRampingSequence) = seq.resync
valueLUT(seq::HoldBorderRampingSequence) = seq.lut
rampUpLUT(seq::HoldBorderRampingSequence) = seq.rampUp
rampDownLUT(seq::HoldBorderRampingSequence) = seq.rampDown

struct ConstantRampingSequence <: RampingSequence
  lut::SequenceLUT
  enable::Union{Array{Bool}, Nothing}
  resync::Union{Array{Bool}, Nothing}
  ramping::SequenceLUT

  function ConstantRampingSequence(lut::Array{Float32}, repetitions::Integer, rampingValue::Float32, rampingSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing, resync::Union{Array{Bool}, Nothing}=nothing)
    if !isnothing(enable) && size(lut) != size(enable)
      throw(DimensionMismatch("Size of enable LUT does not match size of value LUT"))
    end
    rampingLut = SequenceLUT([rampingValue for i = 1:size(lut, 1)], rampingSteps)
    return new(SequenceLUT(lut, repetitions), enable, resync, rampingLut)
  end
end
ConstantRampingSequence(lut::Array{T}, repetitions::Integer, rampingValue::Real, rampingSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing) where T <: Real = ConstantRampingSequence(map(Float32, lut), repetitions, Float32(rampingValue), rampingSteps, enable)
ConstantRampingSequence(lut::Vector{Float32}, repetitions::Integer, rampingValue::Float32, rampingSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing) = ConstantRampingSequence(reshape(lut, 1, :), repetitions, rampingValue, rampingSteps, enable)
ConstantRampingSequence(lut::Vector{T}, repetitions::Integer, rampingValue::Real, rampingSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing) where T <: Real = ConstantRampingSequence(reshape(lut, 1, :), repetitions, rampingValue, rampingSteps, enable)

enableLUT(seq::ConstantRampingSequence) = seq.enable
resyncLUT(seq::ConstantRampingSequence) = seq.resync
valueLUT(seq::ConstantRampingSequence) = seq.lut
rampUpLUT(seq::ConstantRampingSequence) = seq.ramping
rampDownLUT(seq::ConstantRampingSequence) = seq.ramping

struct StartUpSequence <: RampingSequence
  lut::SequenceLUT
  enable::Union{Array{Bool}, Nothing}
  resync::Union{Array{Bool}, Nothing}
  rampUp::SequenceLUT
  rampDown::SequenceLUT
  function StartUpSequence(lut::Array{Float32}, repetitions::Integer, rampingSteps::Integer, startUpSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing, resync::Union{Array{Bool}, Nothing}=nothing)
    if !isnothing(enable) && size(lut) != size(enable)
      throw(DimensionMismatch("Size of enable LUT does not match size of value LUT"))
    end
    if rampingSteps < startUpSteps
      throw(DimensionMismatch("Ramping steps are smaller than start up steps"))
    end
    upLut = zeros(Float32, size(lut, 1), rampingSteps)
    if startUpSteps > 0
      for i = 0:startUpSteps-1
        upLut[:, end-i] = lut[:, end-(i%size(lut, 2))]
      end
      for i = 1:rampingSteps - startUpSteps
        upLut[:, i] = upLut[:, end-(startUpSteps-1)]
      end
    end
    up = SequenceLUT(upLut, 1)
    down = SequenceLUT(lut[:, end], rampingSteps)
    return new(SequenceLUT(lut, repetitions), enable, resync, up, down)
  end
end
StartUpSequence(lut::Array{T}, repetitions::Integer, rampingSteps::Integer, startUpSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing) where T <: Real = StartUpSequence(map(Float32, lut), repetitions, rampingSteps, startUpSteps, enable)
#StartUpSequence(lut::Vector{Float32}, repetitions::Integer, rampingSteps::Integer, startUpSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing) = StartUpSequence(reshape(lut, 1, :), repetitions, rampingSteps, startUpSteps, enable)
StartUpSequence(lut::Vector{T}, repetitions::Integer, rampingSteps::Integer, startUpSteps::Integer, enable::Union{Array{Bool}, Nothing}=nothing) where T <: Real = StartUpSequence(reshape(lut, 1, :), repetitions, rampingSteps, startUpSteps, enable)

enableLUT(seq::StartUpSequence) = seq.enable
resyncLUT(seq::StartUpSequence) = seq.resync
valueLUT(seq::StartUpSequence) = seq.lut
rampUpLUT(seq::StartUpSequence) = seq.rampUp
rampDownLUT(seq::StartUpSequence) = seq.rampDown

function computeRamping(dec, samplesPerStep, stepsPerSeq, rampTime, rampFraction)
  bandwidth = 125e6/dec
  samplesPerRotation = samplesPerStep * stepsPerSeq
  totalRotations = Int32(ceil(rampTime/(samplesPerRotation/bandwidth)))
  totalSteps = totalRotations * stepsPerSeq
  steps = Int32(ceil(rampTime * rampFraction/(samplesPerStep/bandwidth)))
  #@show samplesPerRotation totalRotations totalSteps steps rampTime rampFraction
  return (steps, totalSteps)
end
computeRamping(rp::RedPitaya, stepsPerSeq ,rampTime, rampFraction) = computeRamping(decimation(rp), samplesPerStep(rp), stepsPerSeq, rampTime, rampFraction)

"""
    sequence!(rp::RedPitaya, seq::AbstractSequence)

Transmit the client-side representation `seq` to the server and append it to the current list of sequences. Return `true` if the required commands were successful.
"""
function sequence!(rp::RedPitaya, seq::AbstractSequence)
  result = true
  result &= valueLUT!(rp, seq)
  result &= enableLUT!(rp, seq)
  result &= resyncLUT!(rp, seq)
  result &= rampUpLUT!(rp, seq)
  result &= rampDownLUT!(rp, seq)
  result &= setSequence!(rp)
  return result
end

function transmitLUT!(rp::RedPitaya, lut::Array{Float32}, cmd::String, repetitions::Integer)
  send(rp, string(cmd, " ", size(lut, 2), ",", repetitions))
  write(rp.dataSocket, lut)
  return parseErrorCodes(receive(rp), cmd)
end

valueLUT!(rp::RedPitaya, lut::AbstractSequence) = valueLUT!(rp, valueLUT(lut))
function valueLUT!(rp::RedPitaya, lut::SequenceLUT)
  lutFloat32 = map(Float32, values(lut))
  return transmitLUT!(rp, lutFloat32, "RP:DAC:SEQ:LUT", repetitions(lut))
end

rampUpLUT!(rp::RedPitaya, lut::AbstractSequence) = rampUpLUT!(rp, rampUpLUT(lut))
function rampUpLUT!(rp::RedPitaya, lut::SequenceLUT)
  lutFloat32 = map(Float32, values(lut))
  return transmitLUT!(rp, lutFloat32, "RP:DAC:SEQ:LUT:UP", repetitions(lut))
end

function rampUpLUT!(rp::RedPitaya, lut::Nothing)
  # NOP
  return true
end

rampDownLUT!(rp::RedPitaya, lut::AbstractSequence) = rampDownLUT!(rp, rampDownLUT(lut))
function rampDownLUT!(rp::RedPitaya, lut::SequenceLUT)
  lutFloat32 = map(Float32, values(lut))
  return transmitLUT!(rp, lutFloat32, "RP:DAC:SEQ:LUT:DOWN", repetitions(lut))
end

function rampDownLUT!(rp::RedPitaya, lut::Nothing)
  # NOP
  return true
end

enableLUT!(rp::RedPitaya, lut::AbstractSequence) = enableLUT!(rp, enableLUT(lut))
function enableLUT!(rp::RedPitaya, lut::Array)
  lutBool = map(Bool, lut)
  send(rp, string("RP:DAC:SEQ:LUT:ENaBle"))
  @debug "Writing enable DAC LUT"
  write(rp.dataSocket, lutBool)
  reply = receive(rp)
  return parseErrorCodes(reply, "RP:DAC:SEQ:LUT:ENaBle")
end

function enableLUT!(rp::RedPitaya, lut::Nothing)
  # NOP
  return true
end

resyncLUT!(rp::RedPitaya, lut::AbstractSequence) = resyncLUT!(rp, resyncLUT(lut))
function resyncLUT!(rp::RedPitaya, lut::Array)
  lutBool = map(Bool, lut)
  send(rp, string("RP:DAC:SEQ:LUT:ReSYNC"))
  @debug "Writing resync DAC LUT"
  write(rp.dataSocket, lutBool)
  reply = receive(rp)
  return parseErrorCodes(reply, "RP:DAC:SEQ:LUT:ReSYNC")
end

function resyncLUT!(rp::RedPitaya, lut::Nothing)
  # NOP
  return true
end

function seqTiming(seq::AbstractSequence)
  up = 0
  if !isnothing(rampUpLUT(seq)) 
    up = 0 + length(rampUpLUT(seq))
  end
  start = up
  down = length(valueLUT(seq)) + start
  finish = down
  if !isnothing(rampUpLUT(seq)) 
    finish = down + length(rampUpLUT(seq))
  end
  return (start=start, down=down, finish=finish)
end