export seqChan, seqChan!, samplesPerStep, samplesPerStep!, stepsPerFrame!, AbstractSequence, SimpleSequence, sequence!, prepareSequence!, clearSequence!

"""
  numSeqChan(rp::RedPitaya)

Return the number of sequence channel.
"""
seqChan(rp::RedPitaya) = query(rp, scpiCommand(seqChan), scpiReturn(seqChan))
scpiCommand(::typeof(seqChan)) = "RP:DAC:SEQ:CHan?"
scpiReturn(::typeof(seqChan)) = Int64
"""
    numSeqChan(rp::RedPitaya, value)

Set the number of sequence channel. Valid values are between `1` and `4`. Return `true` if the command was successful.
"""
function seqChan!(rp::RedPitaya, value)
  if value <= 0 || value > 4
    error("Num sequence channels needs to be between 1 and 4!")
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
  return samplesPerStep!(rp, samplesPerStep) # Sets PDMClockDivider
end

"""
    setSequence!(rp::RedPitaya)

Instruct the server to set the current configured sequence for the next acquisition.
"""
setSequence!(rp::RedPitaya) = query(rp, scpiCommand(setSequence!), scpiReturn(setSequence!))
scpiCommand(::typeof(setSequence!)) = "RP:DAC:SEQ:SET"
scpiReturn(::typeof(setSequence!)) = Bool

"""
    clearSequences!(rp::RedPitaya)

Instruct the server to remove all sequences from its list. Return `true` if the command was successful.
"""
clearSequence!(rp::RedPitaya) = query(rp, scpiCommand(clearSequence!), scpiReturn(clearSequence!))
scpiCommand(::typeof(clearSequence!)) = "RP:DAC:SEQ:CLEAR"
scpiReturn(::typeof(clearSequence!)) = Bool

"""
    prepareSequences!(rp::RedPitaya)

Instruct the server to prepare the currently added sequences.
Return `true` if the command was successful.
"""
prepareSequence!(rp::RedPitaya) = query(rp, scpiCommand(prepareSequence!), scpiReturn(prepareSequence!))
scpiCommand(::typeof(prepareSequence!)) = "RP:DAC:SEQ:PREPare"
scpiReturn(::typeof(prepareSequence!)) = Bool

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

"""
    AbstractSequence

Abstract struct of client-side representation of a sequence.

See [`appendSequence!`](@ref), [`prepareSequence!`](@ref), [`ArbitrarySequence`](@ref).
"""
abstract type AbstractSequence end
"""
    SimpleSequence <: AbstractSequence

Struct representing a sequence in which the server directly takes the values from the given LUT.
"""
struct SimpleSequence <: AbstractSequence
  lut::SequenceLUT
  enable::Union{Array{Bool}, Nothing}
  """
    SimpleSequence(lut, repetitions, enable=nothing)

  Constructor for `SimpleSequence`.

  # Arguments
  - `lut::Array{Float32}`: `n`x`m` matrix containing `m` steps for `n` channel
  - `repetitions::Int32`: the number of times the sequence should be repeated
  - `emable::Union{Array{Bool}, Nothing}`: matrix containing enable flags
  """
  function SimpleSequence(lut::Array{Float32}, repetitions::Integer, enable::Union{Array{Bool}, Nothing}=nothing)
    if !isnothing(enable) && size(lut) != size(enable)
      throw(DimensionMismatch("Size of enable LUT does not match size of value LUT"))
    end
    return new(SequenceLUT(lut, repetitions), enable)
  end
end
SimpleSequence(lut::Array, repetitions::Integer, enable=nothing) = SimpleSequence(map(Float32, lut), repetitions, enable)
SimpleSequence(lut::Vector, repetitions::Integer, enable=nothing) = SimpleSequence(reshape(lut, 1, :), repetitions, enable)

enableLUT(seq::SimpleSequence) = seq.enable
valueLUT(seq::SimpleSequence) = seq.lut
rampUpLUT(seq::SimpleSequence) = nothing
rampDownLUT(seq::SimpleSequence) = nothing


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

See [`prepareSequence!`](@ref), [`clearSequences!`](@ref).
"""
function sequence!(rp::RedPitaya, seq::AbstractSequence)
  result = true
  result &= valueLUT!(rp, valueLUT(seq))
  result &= enableLUT!(rp, enableLUT(seq))
  result &= rampUpLUT!(rp, rampUpLUT(seq))
  result &= rampDownLUT!(rp, rampDownLUT(seq))
  result &= setSequence!(rp)
  return result
end

function transmitLUT!(rp::RedPitaya, lut::Array{Float32}, cmd::String, repetitions::Integer)
  send(rp, string(cmd, " ", size(lut, 2), ",", repetitions))
  write(rp.dataSocket, lut)
  return parse(Bool, receive(rp))
end

function valueLUT!(rp::RedPitaya, lut::SequenceLUT)
  lutFloat32 = map(Float32, values(lut))
  return transmitLUT!(rp, lutFloat32, "RP:DAC:SEQ:LUT", repetitions(lut))
end

function rampUpLUT!(rp::RedPitaya, lut::SequenceLUT)
  lutFloat32 = map(Float32, values(lut))
  return transmitLUT!(rp, lutFloat32, "RP:DAC:SEQ:LUT:UP", repetitions(lut))
end

function rampUpLUT!(rp::RedPitaya, lut::Nothing)
  # NOP
  return true
end

function rampDownLUT!(rp::RedPitaya, lut::SequenceLUT)
  lutFloat32 = map(Float32, values(lut))
  return transmitLUT!(rp, lutFloat32, "RP:DAC:SEQ:LUT:DOWN", repetitions(lut))
end

function rampDownLUT!(rp::RedPitaya, lut::Nothing)
  # NOP
  return true
end

function enableLUT!(rp::RedPitaya, lut::Array)
  lutBool = map(Bool, lut)
  send(rp, string("RP:DAC:SEQ:LUT:ENaBle"))
  @debug "Writing enable DAC LUT"
  write(rp.dataSocket, lutBool)
  reply = receive(rp)
  return parse(Bool, reply)
end

function enableLUT!(rp::RedPitaya, lut::Nothing)
  # NOP
  return true
end

"""
    length(seq::AbstractSequence)

Return the number of steps a sequence will take.
"""
function length(seq::AbstractSequence)
  result = stepsPerRepetition(seq) * repetitions(seq) + rampUpTotalSteps(seq) + rampDownTotalSteps(seq)
  result = resetAfterSequence(seq) ? result + 1 : result
  return result
end

"""
    start(seq::AbstractSequence)

Return the number of steps after which a sequence leaves the ramp up phase.
"""
function start(seq::AbstractSequence)
  lut = rampUpLUT(seq)
  if isnothing(lut)
    return 0
  end
  return size(values(lut), 2) * repetitions(lut)
end