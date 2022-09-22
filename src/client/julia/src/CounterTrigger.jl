

"""
    counterTrigger_enabled(rp::RedPitaya)

Return whether the counter trigger is enabled or not.

# Examples
```julia
julia> counterTrigger_enabled!(rp, true)
true

julia> counterTrigger_enabled(rp)
true
```
"""
counterTrigger_enabled(rp::RedPitaya) = parseReturn(counterTrigger_enabled, query(rp, scpiCommand(counterTrigger_enabled)))
scpiCommand(::typeof(counterTrigger_enabled)) = "RP:CounterTrigger:ENable?"
scpiReturn(::typeof(counterTrigger_enabled)) = String
parseReturn(::typeof(counterTrigger_enabled), ret) = occursin("ON", ret)
"""
counterTrigger_enabled!(rp::RedPitaya, dec)

Set whether the counter trigger is enabled or not. Return `true` if the command was successful.

# Examples
```julia
julia> counterTrigger_enabled!(rp, true)
true

julia> counterTrigger_enabled(rp)
true
```
"""
function counterTrigger_enabled!(rp::RedPitaya, val::Bool)
  return query(rp, scpiCommand(counterTrigger_enabled!, val), scpiReturn(counterTrigger_enabled!))
end
scpiCommand(::typeof(counterTrigger_enabled!), val) = string("RP:CounterTrigger:ENable ", val ? "ON" : "OFF")
scpiReturn(::typeof(counterTrigger_enabled!)) = Bool

"""
    counterTrigger_presamples(rp::RedPitaya)

Return the number of samples that the counter trigger should trigger prior to reaching the reference counter.

# Examples
```julia
julia> counterTrigger_presamples!(rp, 50)
true

julia> counterTrigger_presamples(rp)
50
```
"""
counterTrigger_presamples(rp::RedPitaya) = query(rp, scpiCommand(counterTrigger_presamples), scpiReturn(counterTrigger_presamples))
scpiCommand(::typeof(counterTrigger_presamples)) = "RP:CounterTrigger:PREsamples?"
scpiReturn(::typeof(counterTrigger_presamples)) = Int64
"""
    counterTrigger_presamples!(rp::RedPitaya, presamples)

Set the number of samples that the counter trigger should trigger prior to reaching the reference counter.

# Examples
```julia
julia> counterTrigger_presamples!(rp, 50)
true

julia> counterTrigger_presamples(rp)
50
```
"""
function counterTrigger_presamples!(rp::RedPitaya, presamples::T) where T <: Integer
  return query(rp, scpiCommand(counterTrigger_presamples!, presamples), scpiReturn(counterTrigger_presamples!))
end
scpiCommand(::typeof(counterTrigger_presamples!), presamples) = string("RP:CounterTrigger:PREsamples ", presamples)
scpiReturn(::typeof(counterTrigger_presamples!)) = Bool

"""
    counterTrigger_isArmed(rp::RedPitaya)

Return whether the counter trigger is armed or not.

# Examples
```julia
julia> counterTrigger_arm!(rp, true)
true

julia> counterTrigger_isArmed(rp)
true
```
"""
counterTrigger_isArmed(rp::RedPitaya) = query(rp, scpiCommand(counterTrigger_isArmed), scpiReturn(counterTrigger_isArmed))
scpiCommand(::typeof(counterTrigger_isArmed)) = "RP:CounterTrigger:ARM?"
scpiReturn(::typeof(counterTrigger_isArmed)) = Bool
"""
    counterTrigger_arm!(rp::RedPitaya)

Set whether the counter trigger is armed or not. Return `true` if the command was successful.

# Examples
```julia
julia> counterTrigger_arm!(rp, true)
true

julia> counterTrigger_isArmed(rp)
true
```
"""
function counterTrigger_arm!(rp::RedPitaya)
  return query(rp, scpiCommand(counterTrigger_arm!), scpiReturn(counterTrigger_arm!))
end
scpiCommand(::typeof(counterTrigger_arm!)) = string("RP:CounterTrigger:ARM")
scpiReturn(::typeof(counterTrigger_arm!)) = Bool

"""
    counterTrigger_reset(rp::RedPitaya)

Return the reset status of the counter trigger.

# Example
```julia
julia> counterTrigger_reset!(rp, true)

julia>counterTrigger_reset(rp)
true
```
"""
counterTrigger_reset(rp::RedPitaya) = parseReturn(counterTrigger_reset, query(rp, scpiCommand(counterTrigger_reset)))
scpiCommand(::typeof(counterTrigger_reset)) = "RP:CounterTrigger:RESet?"
scpiReturn(::typeof(counterTrigger_reset)) = String
parseReturn(::typeof(counterTrigger_reset), ret) = occursin("ON", ret)
"""
    counterTrigger_reset!(rp::RedPitaya, val::Bool)

Set the reset of the counter trigger to `val`. Return `true` if the command was successful.

# Example
```julia
julia> counterTrigger_reset!(rp, true)
true

julia>counterTrigger_reset(rp)
true
```
"""
function counterTrigger_reset!(rp::RedPitaya, val)
  return query(rp, scpiCommand(counterTrigger_reset!, val), scpiReturn(counterTrigger_reset!))
end
scpiCommand(::typeof(counterTrigger_reset!), val::Bool) = scpiCommand(counterTrigger_reset!, val ? "ON" : "OFF")
scpiCommand(::typeof(counterTrigger_reset!), val::String) = string("RP:CounterTrigger:RESet ", val)
scpiReturn(::typeof(counterTrigger_reset!)) = Bool

"""
counterTrigger_lastCounter(rp::RedPitaya)

Return the number of samples that the counter trigger should trigger prior to reaching the reference counter.

# Examples
```julia
julia> counterTrigger_lastCounter(rp)
123456
```
"""
counterTrigger_lastCounter(rp::RedPitaya) = query(rp, scpiCommand(counterTrigger_lastCounter), scpiReturn(counterTrigger_lastCounter))
scpiCommand(::typeof(counterTrigger_lastCounter)) = "RP:CounterTrigger:COUNTer:LAst?"
scpiReturn(::typeof(counterTrigger_lastCounter)) = Int64

