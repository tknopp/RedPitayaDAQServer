# Batch Example

In this example we recreate the first [example](simple.md) using the batch functionality offered by the Julia client. Note that all commands are still executed in order from the RedPitayas perspective, only the client communication is more efficient within a batch.

To run this example connect the RedPitaya in the following way.

![RedPitaya](../assets/simpleExample.png)

It is also possible to update the signal type during the acquisition without going back to the `CONFIGURATION` mode.

## Julia Client

This and all other examples are located in the ```examples``` [directory](https://github.com/tknopp/RedPitayaDAQServer/tree/master/src/examples/julia)

````@eval
# Adapted from https://github.com/JuliaDocs/Documenter.jl/issues/499
using Markdown
Markdown.parse("""
```julia
$(open(f->read(f, String), "../../../src/examples/julia/batch.jl"))
```
""")
````

![Batch Example Results](../assets/simple.png)
