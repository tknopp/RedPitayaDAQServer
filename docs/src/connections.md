# Connections

An overview of the extension connectors (see also [here](http://redpitaya.readthedocs.io/en/latest/developerGuide/125-14/extent.html)) is given in the following image

![Connectors](./assets/Extension_connector.png)

The project uses most but not all connections that are used in the original RedPitaya image. From the connector E2 only the analog inputs and outputs are used. From the connector E1 several pins are reserved for the following purposes:
* `DIO0_P` for the ADC and DAC trigger. Connect it with the master's `DIO5_P` to distribute the trigger signal to all RedPitayas in a [cluster](cluster.md). As long as the input is high, the DACs and ADCs are running.
* `DIO1_P` is the input for the watchdog (see configuration register section for further details)
* `DIO2_P` is used to acknowledge a received watchdog signal.
* `DIO3_P` can be set to high, to stop all DACs instantly.
* `DIO4_P` outputs a high for 10 ms after a 100 ms pause on low to provide an alive signal.
* `DIO5_P` can be set to high via the configuration register to provide the mutual trigger signal.
* `DIO7_P`, `DIO7_N`, `DIO6_P`, `DIO6_N`, `DIO5_N`, `DIO4_N`, `DIO3_N`, `DIO2_N` can be used as arbitrary outputs set via the server.
* `DIO0_N` and `DIO1_N` are used for the clock selection in a cluster.
