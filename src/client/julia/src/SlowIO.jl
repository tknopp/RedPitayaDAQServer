export slowDAC!
"""
    slowDAC!(rp::RedPitaya, channel::Int64, val::Int64)

Set the value of the slow DAC channel `channel` to the value `val`. Return `true` if the command was successful.

# Example
```julia
julia> slowDAC!(rp, 1, 500)
true
```
"""
slowDAC!(rp::RedPitaya, channel, val) = query(rp, scpiCommand(slowDAC!, channel, val), scpiReturn(slowDAC!))
scpiCommand(::typeof(slowDAC!), channel::Int64, val::Int64) = string("RP:PDM:CHannel", channel, ":NextValueVolt ", val)
scpiReturn(::typeof(slowDAC!)) = Bool

export slowDACClockDivider!
"""
    slowDACClockDivider!(rp::RedPitaya, val::Int32)

Set the clock divider of the slow DAC.
# Example
```julia
julia> slowDACClockDivider!(rp, 8)

julia>slowDACClockDivider(rp)
8
```
"""
slowDACClockDivider!(rp::RedPitaya, val) = query(rp, scpiCommand(slowDACClockDivider!, val), scpiReturn(slowDACClockDivider!))
scpiCommand(::typeof(slowDACClockDivider!), val::Int32) = string("RP:PDM:ClockDivider ", val)
scpiReturn(::typeof(slowDACClockDivider!)) = Bool

export slowDACClockDivider
"""
    slowDACClockDivider(rp::RedPitaya)

Get the clock divider of the slow DAC.
# Example
```julia
julia> slowDACClockDivider!(rp, 8)

julia>slowDACClockDivider(rp)
8
```
"""
slowDACClockDivider(rp::RedPitaya) = query(rp, scpiCommand(slowDACClockDivider), scpiReturn(slowDACClockDivider))
scpiCommand(::typeof(slowDACClockDivider)) = "RP:PDM:ClockDivider?"
scpiReturn(::typeof(slowDACClockDivider)) = Int32

export slowDAC!
"""
slowADC(rp::RedPitaya, channel::Int64)

Get the value of the XADC channel `channel`.

# Example
```julia
julia> slowADC(rp, 1)
0.0
```
"""
slowADC(rp::RedPitaya, channel) = query(rp, scpiCommand(slowADC, channel), scpiReturn(slowADC))
scpiCommand(::typeof(slowADC), channel::Int64) = string("RP:XADC:CHannel", channel, "?")
scpiReturn(::typeof(slowADC)) = Float64

export DIODirectionType, DIO_IN, DIO_OUT
"""
    DIODirectionType

Represent the different DIO directions. Valid value are `DIO_IN` and `DIO_OUT`.

See [`DIODirection`](@ref), [`DIODirection!`](@ref).
"""
@enum DIODirectionType DIO_IN DIO_OUT

export DIOPins, DIO7_P, DIO7_N, DIO6_P, DIO6_N, DIO5_N, DIO4_N, DIO3_N, DIO2_N
"""
    DIOPins

Represent the different DIO pins. Valid value are `DIO7_P`, `DIO7_N`, `DIO6_P`,
`DIO6_N`, `DIO5_N`, `DIO4_N`, `DIO3_N` and `DIO2_N`.

See [`DIODirection`](@ref), [`DIODirection!`](@ref), [`DIO`](@ref), [`DIO`](@ref).
"""
@enum DIOPins begin
  DIO7_P
  DIO7_N
  DIO6_P
  DIO6_N
  DIO5_N
  DIO4_N
  DIO3_N
  DIO2_N
end

DIOPinToCommand(pin::DIOPins) = replace(join(split(string(pin), "_"), ":Side"), "DIO" => "PIN")

export isValidDIOPin
"""
isValidDIOPin(pin::String)

Check if a given string is an allowed value for the DIO pin names.

See [`DIOPins`](@ref).
"""
isValidDIOPin(pin::String) = pin in string.(instances(DIOPins))

export DIODirection!
"""
  DIODirection!(rp::RedPitaya, pin::DIOPins, direction::DIODirectionType)

Set the direction of DIO pin `pin` to the value `direction`.
# Example
```julia
julia> DIODirection!(rp, DIO7_P, DIO_OUT)

julia>DIODirection(rp, DIO7_P)
DIO_OUT
```
"""
DIODirection!(rp::RedPitaya, pin, direction) = query(rp, scpiCommand(DIODirection!, pin, direction), scpiReturn(DIODirection!))
scpiCommand(::typeof(DIODirection!), pin::DIOPins, direction::DIODirectionType) = string("RP:DIO:", DIOPinToCommand(pin), ":DIR ", (direction == DIO_IN ? "IN" : "OUT"))
scpiReturn(::typeof(DIODirection!)) = Bool

export DIODirection
"""
  DIODirection(rp::RedPitaya, pin::DIOPins)

Get the direction of DIO pin `pin`.
# Example
```julia
julia> DIODirection!(rp, DIO7_P, DIO_OUT)

julia>DIODirection(rp, DIO7_P)
DIO_OUT
```
"""
DIODirection(rp::RedPitaya, pin) = parseReturn(DIODirection, query(rp, scpiCommand(DIODirection, pin), scpiReturn(DIODirection)))
scpiCommand(::typeof(DIODirection), pin) = scpiCommand(DIODirection, stringToEnum(DIOPins, pin))
scpiCommand(::typeof(DIODirection), pin::DIOPins) = string("RP:DIO:", DIOPinToCommand(pin), ":DIR?")
scpiReturn(::typeof(DIODirection)) = String
parseReturn(::typeof(DIODirection), ret) = stringToEnum(DIODirectionType, "DIO_"*ret)

export DIO!
"""
DIO!(rp::RedPitaya, pin::DIOPins, val::Bool)

Set the value of DIO pin `pin` to the value `val`.
# Example
```julia
julia> DIO!(rp, DIO7_P, true)
true
```
"""
function DIO!(rp::RedPitaya, pin, val)
  if DIODirection(rp, pin) == DIO_IN
    @warn "The pin $pin is currently set as input. The value is applied anyways!"
  end
  return query(rp, scpiCommand(DIO!, pin, val), scpiReturn(DIO!))
end
scpiCommand(::typeof(DIO!), pin::DIOPins, val::Bool) = string("RP:DIO:", DIOPinToCommand(pin), " ", (val ? "ON" : "OFF"))
scpiReturn(::typeof(DIO!)) = Bool

export DIO
"""
  DIO(rp::RedPitaya, pin::DIOPins)

Get the value of DIO pin `pin`.
# Example
```julia
julia>DIO(rp, DIO7_P)
true
```
"""
function DIO(rp::RedPitaya, pin)
  if DIODirection(rp, pin) == DIO_OUT
    @warn "The pin $pin is currently set as output. The value is read anyways but might be wrong!"
  end
  return parseReturn(DIO, query(rp, scpiCommand(DIO, pin), scpiReturn(DIO)))
end
scpiCommand(::typeof(DIO), pin) = string("RP:DIO:", DIOPinToCommand(pin), "?")
scpiReturn(::typeof(DIO)) = String
parseReturn(::typeof(DIO), ret) = occursin("ON", ret)






export DIOHBridge!
"""
DIOHBridge!(rp::RedPitaya, pin::DIOPins, val::Bool)

Set the value of DIOHBridge pin `pin` to the value `val`.
# Example
```julia
julia> DIOHBridge!(rp, DIO7_P, true)
true
```
"""
function DIOHBridge!(rp::RedPitaya, pin, val)
  return query(rp, scpiCommand(DIOHBridge!, pin, val), scpiReturn(DIOHBridge!))
end
scpiCommand(::typeof(DIOHBridge!), pin::DIOPins, val::Bool) = string("RP:DIO:", DIOPinToCommand(pin), ":HBRIDGE ", (val ? "ON" : "OFF"))
scpiReturn(::typeof(DIOHBridge!)) = Bool

export DIOHBridge
"""
  DIOHBridge(rp::RedPitaya, pin::DIOPins)

Get the value of DIOHBridge pin `pin`.
# Example
```julia
julia>DIOHBridge(rp, DIO7_P)
true
```
"""
function DIOHBridge(rp::RedPitaya, pin)
  return parseReturn(DIOHBridge, query(rp, scpiCommand(DIOHBridge, pin), scpiReturn(DIOHBridge)))
end
scpiCommand(::typeof(DIOHBridge), pin) = string("RP:DIO:", DIOPinToCommand(pin), ":HBRIDGE?")
scpiReturn(::typeof(DIOHBridge)) = String
parseReturn(::typeof(DIOHBridge), ret) = occursin("ON", ret)