# An example for using the server to acquire some data.
# Connect OUT1 with IN1!

import os
import sys
import math
import time
import matplotlib.pyplot as plt
import numpy as np
import logging

logging.basicConfig(level=logging.DEBUG)

# Add the client object to the path
sys.path.insert(0, os.path.join(os.getcwd(), '..', '..', 'client', 'python'))
from redpitaya import RedPitaya

# Connect to the Red Pitaya
rp = RedPitaya('192.168.2.19')
rp.connect()

# Define acquisition parameters
decimation = 8
frequency = 25000
base_frequency = 125000000
samples_per_period = math.floor(base_frequency/frequency)
periods_per_frame = 12

# Set acquisition parameters
rp.setDecimation(decimation)
rp.setSamplesPerPeriod(samples_per_period)
rp.setPeriodsPerFrame(periods_per_frame)
rp.setFrequency(0, 0, frequency)
rp.setSignalType(0, "sine")
rp.setAmplitude(0, 0, 7000)
rp.setOffset(0, 1000)
rp.setMasterTrigger(False)
rp.setRamWriterMode("triggered")
rp.setTriggerMode("internal");

rp.setAcquisitionStatus(True, rp.getCurrentWritePointer())
rp.setMasterTrigger(True)

u = rp.readData(0, 1, 1);

rp.setMasterTrigger(False)
rp.setAcquisitionStatus(False, 0)
rp.disconnect()

plt.plot(u[0,:,0,0])
plt.show()

if __name__ == '__main__':
    pass