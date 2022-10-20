export counterTrigger_enabled
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

export counterTrigger_enabled!
"""
counterTrigger_enabled!(rp::RedPitaya, val)

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

export counterTrigger_presamples
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

export counterTrigger_presamples!
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

export counterTrigger_isArmed
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

export counterTrigger_arm!
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

export counterTrigger_reset
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

export counterTrigger_reset!
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

export counterTrigger_lastCounter
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

export counterTrigger_referenceCounter
"""
    counterTrigger_referenceCounter(rp::RedPitaya)

Return the counter value that the counter trigger should trigger on.

# Examples
```julia
julia> counterTrigger_referenceCounter!(rp, 250)
true

julia> counterTrigger_referenceCounter(rp)
250
```
"""
counterTrigger_referenceCounter(rp::RedPitaya) = query(rp, scpiCommand(counterTrigger_referenceCounter), scpiReturn(counterTrigger_referenceCounter))
scpiCommand(::typeof(counterTrigger_referenceCounter)) = "RP:CounterTrigger:COUNTer:REFerence?"
scpiReturn(::typeof(counterTrigger_referenceCounter)) = Int64

export counterTrigger_referenceCounter!
"""
counterTrigger_referenceCounter!(rp::RedPitaya, presamples)

Set the number of samples that the counter trigger should trigger on.

# Examples
```julia
julia> counterTrigger_referenceCounter(rp, 250)
true

julia> counterTrigger_referenceCounter!(rp)
250
```
"""
counterTrigger_referenceCounter!(rp::RedPitaya, reference::T) where T <: Integer = query(rp, scpiCommand(counterTrigger_referenceCounter!, reference), scpiReturn(counterTrigger_referenceCounter!))
scpiCommand(::typeof(counterTrigger_referenceCounter!), reference) = string("RP:CounterTrigger:COUNTer:REFerence ", reference)
scpiReturn(::typeof(counterTrigger_referenceCounter!)) = Bool

export CounterTriggerSourceType, COUNTER_TRIGGER_DIO, COUNTER_TRIGGER_ADC
"""
    CounterTriggerSourceType

Represent the different counter trigger source types. Valid values are `COUNTER_TRIGGER_DIO` and `COUNTER_TRIGGER_ADC`.

See [`counterTrigger_sourceType`](@ref), [`counterTrigger_sourceType!`](@ref).
"""
@enum CounterTriggerSourceType COUNTER_TRIGGER_DIO COUNTER_TRIGGER_ADC

export counterTrigger_sourceType!
"""
    counterTrigger_sourceType!(rp::RedPitaya, sourceType::CounterTriggerSourceType)

Set the source type of the counter trigger to `sourceType`.

# Example
```julia
julia> counterTrigger_sourceType!(rp, COUNTER_TRIGGER_ADC)

julia>counterTrigger_sourceType(rp)
COUNTER_TRIGGER_ADC::CounterTriggerSourceType = 1
```
"""
counterTrigger_sourceType!(rp::RedPitaya, sourceType) = query(rp, scpiCommand(counterTrigger_sourceType!, sourceType), scpiReturn(counterTrigger_sourceType!))
scpiCommand(::typeof(counterTrigger_sourceType!), sourceType::CounterTriggerSourceType) = string("RP:CounterTrigger:SouRCe:TYPe ", (sourceType == COUNTER_TRIGGER_DIO ? "DIO" : "ADC"))
scpiReturn(::typeof(counterTrigger_sourceType!)) = Bool

export counterTrigger_sourceType
"""
    counterTrigger_sourceType(rp::RedPitaya)

Get the source type of the counter trigger.

# Example
```julia
julia> counterTrigger_sourceType!(rp, COUNTER_TRIGGER_ADC)

julia>counterTrigger_sourceType(rp)
COUNTER_TRIGGER_ADC::CounterTriggerSourceType = 1
```
"""
counterTrigger_sourceType(rp::RedPitaya) = parseReturn(counterTrigger_sourceType, query(rp, scpiCommand(counterTrigger_sourceType), scpiReturn(counterTrigger_sourceType)))
scpiCommand(::typeof(counterTrigger_sourceType)) = string("RP:CounterTrigger:SouRCe:TYPe?")
scpiReturn(::typeof(counterTrigger_sourceType)) = String
parseReturn(::typeof(counterTrigger_sourceType), ret) = stringToEnum(CounterTriggerSourceType, "COUNTER_TRIGGER_"*ret)

export CounterTriggerSourceADCChannel, COUNTER_TRIGGER_IN1, COUNTER_TRIGGER_IN2
"""
    CounterTriggerSourceADCChannel

Represent the different counter trigger ADC sources. Valid values are `COUNTER_TRIGGER_IN1` and `COUNTER_TRIGGER_IN2`.

See [`counterTrigger_sourceChannel`](@ref), [`counterTrigger_sourceChannel!`](@ref).
"""
@enum CounterTriggerSourceADCChannel COUNTER_TRIGGER_IN1 COUNTER_TRIGGER_IN2

export counterTrigger_sourceChannel!
"""
counterTrigger_sourceChannel!(rp::RedPitaya, sourceChannel::) //TODO

Set the source channel of the counter trigger to `sourceChannel`.

# Example
```julia
julia> counterTrigger_sourceChannel!(rp, COUNTER_TRIGGER_ADC)

julia>counterTrigger_sourceChannel(rp)
COUNTER_TRIGGER_ADC::CounterTriggerSourceType = 1 //TODO
```
"""
counterTrigger_sourceChannel!(rp::RedPitaya, sourceChannel) = query(rp, scpiCommand(counterTrigger_sourceChannel!, sourceChannel), scpiReturn(counterTrigger_sourceChannel!))
scpiCommand(::typeof(counterTrigger_sourceChannel!), sourceChannel::CounterTriggerSourceADCChannel) = string("RP:CounterTrigger:SouRCe:CHANnel ", (sourceChannel == COUNTER_TRIGGER_IN1 ? "IN1" : "IN2"))
scpiCommand(::typeof(counterTrigger_sourceChannel!), sourceChannel::DIOPins) = string("RP:CounterTrigger:SouRCe:CHANnel ", string(sourceChannel))
scpiReturn(::typeof(counterTrigger_sourceChannel!)) = Bool

export counterTrigger_sourceChannel
"""
counterTrigger_sourceChannel(rp::RedPitaya)

Get the source channel of the counter trigger.

# Example
```julia
julia> counterTrigger_sourceChannel!(rp, COUNTER_TRIGGER_IN2)

julia>counterTrigger_sourceChannel(rp)
COUNTER_TRIGGER_IN2::CounterTriggerSourceADCChannel = 2
```
"""
counterTrigger_sourceChannel(rp::RedPitaya) = parseReturn(counterTrigger_sourceChannel, query(rp, scpiCommand(counterTrigger_sourceChannel), scpiReturn(counterTrigger_sourceChannel)))
scpiCommand(::typeof(counterTrigger_sourceChannel)) = string("RP:CounterTrigger:SouRCe:CHANnel?")
scpiReturn(::typeof(counterTrigger_sourceChannel)) = String
parseReturn(::typeof(counterTrigger_sourceChannel), ret) = startswith(ret, "DIO") ? stringToEnum(DIOPins, ret) : stringToEnum(CounterTriggerSourceADCChannel, "COUNTER_TRIGGER_"*ret)