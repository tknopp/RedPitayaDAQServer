export counterSamplesPerStep, counterSamplesPerStep!

"""
    counterSamplesPerStep(rp::RedPitaya)

Return the number of samples per sequence step.
"""
counterSamplesPerStep(rp::RedPitaya) = query(rp, scpiCommand(counterSamplesPerStep), scpiReturn(counterSamplesPerStep))
scpiCommand(::typeof(counterSamplesPerStep)) = "RP:COU:SAMP?"
scpiReturn(::typeof(counterSamplesPerStep)) = Int64

"""
    counterSamplesPerStep!(rp::RedPitaya, value::Integer)

Set the number of samples per sequence step. Return `true` if the command was successful.
"""
function counterSamplesPerStep!(rp::RedPitaya, value::Integer)
  return query(rp, scpiCommand(counterSamplesPerStep!, value), scpiReturn(counterSamplesPerStep!))
end
scpiCommand(::typeof(counterSamplesPerStep!), value) = string("RP:COU:SAMP ", value)
scpiReturn(::typeof(counterSamplesPerStep!)) = Bool