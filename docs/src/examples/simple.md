# Simple Example

In the first example we connect to a single RedPitaya and generate a sinus signal of frequency 10 kHz on DAC channel 1 and receive the same signal on the ADC channel 1. To run this example connect the RedPitaya in the following way.

![RedPitaya](../assets/simpleExample.png)

Note that while the example only plots the first channel of the RedPitaya, both channels are transmitted to the clients.

## Julia Client

This and all other examples are located in the ```examples``` [directory](https://github.com/tknopp/RedPitayaDAQServer/tree/master/src/examples/julia).

````@eval
# Adapted from https://github.com/JuliaDocs/Documenter.jl/issues/499
using Markdown
Markdown.parse("""
```julia
$(open(f->read(f, String), "../../../src/examples/julia/simple.jl"))
```
""")
````

![Simple Example Results](../assets/simple.png)


## Python Client

This example is located in the ```python examples``` [directory](https://github.com/tknopp/RedPitayaDAQServer/tree/master/src/examples/python). The python examples use a very reduced Python
client class that is located [here](https://github.com/tknopp/RedPitayaDAQServer/tree/master/src/examples/python/RedPitayaDAQServer.py). The Python client only wraps the low-level socket communication.

````@eval
using Markdown
Markdown.parse("""
```python
$(open(f->read(f, String), "../../../src/examples/python/simple.py"))
```
""")
````