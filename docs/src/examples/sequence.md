# Sequence Example

In this example we generate a 10 kHz sine wave on DAC channel 1 and also construct a sequence with a climbing offset every 5 periods. We receive this signal on ADC channel 1. To run this example connect the RedPitaya in the following way.

![RedPitaya](../assets/simpleExample.png)

## Julia Client

This and all other examples are located in the ```examples``` [directory](https://github.com/tknopp/RedPitayaDAQServer/tree/master/src/examples/julia)

````@eval
# Adapted from https://github.com/JuliaDocs/Documenter.jl/issues/499
using Markdown
Markdown.parse("""
```julia
$(open(f->read(f, String), "../../../src/examples/julia/sequence.jl"))
```
""")
````

![Simple Example Results](../assets/sequence.png)
