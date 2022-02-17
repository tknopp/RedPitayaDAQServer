# Continous Signal Acquisition Example

As is mentioned in the [Acquisition](../acquisition.md) section, the transmission rate of the server heavily depends on the available network and the way a client processes the samples. This example shows how one can write a thread dedicated to just receiving samples and one (or more) threads dedicated to processing samples. As the example contains no visualization, there is no need for a specific RedPitaya setup.

## Julia Client

This and all other examples are located in the ```examples``` [directory](https://github.com/tknopp/RedPitayaDAQServer/tree/master/src/examples/julia)

````@eval
# Adapted from https://github.com/JuliaDocs/Documenter.jl/issues/499
using Markdown
Markdown.parse("""
```julia
$(open(f->read(f, String), "../../../src/examples/julia/producerConsumer.jl"))
```
""")
````
