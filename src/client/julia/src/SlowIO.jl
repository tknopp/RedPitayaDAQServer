export slowDAC!
"""
Set the value of the slow DAC channel `channel` to the value `val`. Return `true` if the command was successful.

# Example

```julia
julia> slowDAC!(rp, 1, 500)
true
```
"""
slowDAC!(rp::RedPitaya, channel, val) = query(rp, scpiCommand(slowDAC!, channel, val), scpiReturn(slowDAC!))
function scpiCommand(::typeof(slowDAC!), channel::Int64, val::Int64)
  return string("RP:PDM:CHannel", channel, ":NextValueVolt ", val)
end
scpiReturn(::typeof(slowDAC!)) = Bool

export slowDACClockDivider!
"""
Set the clock divider of the slow DAC.

# Example

```julia
julia> slowDACClockDivider!(rp, 8)

julia>slowDACClockDivider(rp)
8
```
"""
function slowDACClockDivider!(rp::RedPitaya, val)
  return query(rp, scpiCommand(slowDACClockDivider!, val), scpiReturn(slowDACClockDivider!))
end
scpiCommand(::typeof(slowDACClockDivider!), val::Int32) = string("RP:PDM:ClockDivider ", val)
scpiReturn(::typeof(slowDACClockDivider!)) = Bool

export slowDACClockDivider
"""
Get the clock divider of the slow DAC.

# Example

```julia
julia> slowDACClockDivider!(rp, 8)

julia>slowDACClockDivider(rp)
8
```
"""
function slowDACClockDivider(rp::RedPitaya)
  return query(rp, scpiCommand(slowDACClockDivider), scpiReturn(slowDACClockDivider))
end
scpiCommand(::typeof(slowDACClockDivider)) = "RP:PDM:ClockDivider?"
scpiReturn(::typeof(slowDACClockDivider)) = Int32

export slowDAC!
"""
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
Represent the different DIO directions. Valid value are `DIO_IN` and `DIO_OUT`.

See [`DIODirection`](@ref), [`DIODirection!`](@ref).
"""
@enum DIODirectionType DIO_IN DIO_OUT

export DIOPins, DIO7_P, DIO7_N, DIO6_P, DIO6_N, DIO5_N, DIO4_N, DIO3_N, DIO2_N
"""
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
Check if a given string is an allowed value for the DIO pin names.

See [`DIOPins`](@ref).
"""
isValidDIOPin(pin::String) = pin in string.(instances(DIOPins))

export DIODirection!
"""
Set the direction of DIO pin `pin` to the value `direction`.

# Example

```julia
julia> DIODirection!(rp, DIO7_P, DIO_OUT)

julia>DIODirection(rp, DIO7_P)
DIO_OUT
```
"""
function DIODirection!(rp::RedPitaya, pin, direction)
  return query(rp, scpiCommand(DIODirection!, pin, direction), scpiReturn(DIODirection!))
end
function scpiCommand(::typeof(DIODirection!), pin::DIOPins, direction::DIODirectionType)
  return string("RP:DIO:", DIOPinToCommand(pin), ":DIR ", (direction == DIO_IN ? "IN" : "OUT"))
end
scpiReturn(::typeof(DIODirection!)) = Bool

export DIODirection
"""
Get the direction of DIO pin `pin`.

# Example

```julia
julia> DIODirection!(rp, DIO7_P, DIO_OUT)

julia>DIODirection(rp, DIO7_P)
DIO_OUT
```
"""
function DIODirection(rp::RedPitaya, pin)
  return parseReturn(DIODirection, query(rp, scpiCommand(DIODirection, pin), scpiReturn(DIODirection)))
end
scpiCommand(::typeof(DIODirection), pin) = scpiCommand(DIODirection, stringToEnum(DIOPins, pin))
scpiCommand(::typeof(DIODirection), pin::DIOPins) = string("RP:DIO:", DIOPinToCommand(pin), ":DIR?")
scpiReturn(::typeof(DIODirection)) = String
parseReturn(::typeof(DIODirection), ret) = stringToEnum(DIODirectionType, "DIO_" * ret)

export DIO!
"""
Set the value of DIO pin `pin` to the value `val`.

# Example

```julia
julia> DIO!(rp, DIO7_P, true)
true
```
"""
DIO!(rp::RedPitaya, pin, val) = query(rp, scpiCommand(DIO!, pin, val), scpiReturn(DIO!))
function scpiCommand(::typeof(DIO!), pin::DIOPins, val::Bool)
  return string("RP:DIO:", DIOPinToCommand(pin), " ", (val ? "ON" : "OFF"))
end
scpiReturn(::typeof(DIO!)) = Bool

export DIO
"""
Get the value of DIO pin `pin`.

# Example

```julia
julia > DIO(rp, DIO7_P)
true
```
"""
DIO(rp::RedPitaya, pin) = parseReturn(DIO, query(rp, scpiCommand(DIO, pin), scpiReturn(DIO)))
scpiCommand(::typeof(DIO), pin) = string("RP:DIO:", DIOPinToCommand(pin), "?")
scpiReturn(::typeof(DIO)) = String
parseReturn(::typeof(DIO), ret) = occursin("ON", ret)
