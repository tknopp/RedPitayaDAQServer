from common import *

print("Simple Python Example")

host = "192.168.178.52"
rp = RedPitaya(host)

# Set server in CONFIGURATION mode, s.t. we can prepare our signal generation + acquisition
ret = rp.query("RP:MODe CONFIGURATION")

dec = 32
modulus = 12480
base_frequency = 125000000
samples_per_period = int((modulus / dec)) 
periods_per_frame = 2

# ADC Configuration
# These commands are only allowed in CONFIGURATION mode
ret = rp.query("RP:ADC:DECimation %d" % dec)
ret = rp.query("RP:TRIGger:MODe %s" % "INTERNAL")

# DAC Configuration
# These commands are allowed during an acquisition
ret = rp.query("RP:DAC:CH0:COMP0:FREQ %f" % (base_frequency / modulus))
ret = rp.query("RP:DAC:CH0:SIGnaltype SINE")
ret = rp.query("RP:DAC:CH0:COMP0:AMP %f" % (0.5))
ret = rp.query("RP:DAC:CH0:OFF %f" % (0.0))
ret = rp.query("RP:DAC:CH0:COMP0:PHA %f" % (0.0))

# Start signal generation + acquisition
# The trigger can only be set in ACQUISITION mode
ret = rp.query("RP:MODe ACQUISITION")
ret = rp.query("RP:TRIGger ON")





