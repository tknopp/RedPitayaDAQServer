# An example for using the server to acquire some data.
# Connect OUT1 with IN1!

import os
import sys
import math
import time
import matplotlib.pyplot as plt
import numpy as np

# Add the client object to the path
sys.path.insert(0, os.path.join(os.getcwd(), '..', '..', 'client', 'python'))
from redpitaya import RedPitaya

# Connect to the Red Pitaya
rp = RedPitaya('rp-f00806.local')
rp.connect()

# Define acquisition parameters
dec = 8
modulus = 4800
base_frequency = 125000000
samples_per_period = math.floor(modulus/dec)
periods_per_frame = 1

# Set acquisition parameters
rp.setDecimation(dec)
rp.setSamplesPerPeriod(samples_per_period)
rp.setPeriodsPerFrame(periods_per_frame)

rp.setDACMode("rasterized")
rp.reconfigureDACModulus(0, 0, 4800)
rp.setModulusFactor(0, 0, 1)

print('DAC frequency is %fHz.' % rp.getFrequency(0, 0))
rp.setAmplitude(0, 0, 7000)
rp.setPhase(0, 0, 0.33)
rp.setMasterTrigger(False)
rp.setRamWriterMode("triggered")

time.sleep(0.1)

rp.setAcquisitionStatus(True)
rp.setMasterTrigger(True)

# Wait for valid frames
while (rp.getCurrentFrame() == -1):
    time.sleep(0.01)

startFrame = rp.getCurrentFrame()
u = rp.readData(startFrame, 11)

rp.setAcquisitionStatus(False)
rp.setMasterTrigger(False)
rp.disconnect()

# TODO: I shouldn't be too stupid for using reshape
u_reshaped = []
for j in range(0, u.shape[3]-1):
    for i in range(0, samples_per_period-1):
        u_reshaped.append(u[0,i,0,j])

plt.plot(u_reshaped)
plt.show()

if __name__ == '__main__':
    pass