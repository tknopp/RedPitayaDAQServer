import socket
from decimal import Decimal
import time
import numpy as np
import select
import struct
import logging

class RedPitaya:
    """Provides access to the DAQ functions of the Red Pitaya
       All functions which are exposed via SCPI on the server have their
       counterpart in this class. This enables the usage of the data
       acquisition tools without the need for writing the SCPI commands by
       hand.
    """
    
    _host = None
    _port = 5025
    _dataPort = 5026
    _delim = '\n'
    _socket = None
    _dataSocket = None
    _isConnected = False
    _decimation = None
    _samplesPerPeriod = None
    _periodsPerFrame = None
    _slowPeriodsPerFrame = None
    
    def __init__(self, host, port = 5025, dataPort = 5026):
        if isinstance(host, str):
            self._host = host
        else:
            raise TypeError('Please provide a valid hostname as a string or char array.')
        
        if isinstance(port, int):
            self._port = port
        else:
            raise TypeError('Please provide a valid port as an integer.')
        
        if isinstance(dataPort, int):
            self._dataPort = dataPort
        else:
            raise TypeError('Please provide a valid data port as an integer.')
    
    def connect(self):
        """Connect to the Red Pitaya
        
           See also disconnect().
        """
        
        if not self._isConnected:
            # Connect to SCPI server
            self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self._socket.connect((self._host, self._port))
			
			# Initialize RedPitaya with FPGA image
            self.init();
            
            # Request a data connection
            self.startAcquisitionConnection()
            
            # Connect to data port
            self._dataSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self._dataSocket.connect((self._host, self._dataPort))
            
            # Set status to 'connected'
            self._isConnected = True
    
    def disconnect(self):
        """Disconnect from the Red Pitaya
        
           See also connect().
        """
    
        if self._isConnected:
            # Close sockets
            self._dataSocket.shutdown(socket.SHUT_RDWR)
            self._socket.shutdown(socket.SHUT_RDWR)
            self._dataSocket.close()
            self._socket.close()

            # Set status to 'disconnected'
            self._isConnected = False
    
    def send(self, command):
        """Send a command to the RedPitaya
        
           See also receive(), query().
        """
        
        # Prevent errors due to being too fast
        time.sleep(0.001)
    
        # Flush input buffer
        input = [self._socket]
        while True:
            inputready, o, e = select.select(input,[],[], 0.0)
            if len(inputready) == 0:
                break
            for s in inputready:
                s.recv(1)
        
        logging.debug('Sending command: %s' % command)
        self._socket.sendall((command + self._delim).encode())
    
    def receive(self):
        """Receive a value from the RedPitaya
        
           See also send(), query().
        """
        
        fileHandle = self._socket.makefile('r')
        data = fileHandle.readline().strip()
        
        # Strings start and end with '"' to mark them. Remove those.
        if data[0] == '"' and data[-1] == '"':
            data = data[1:-1]

        return data
    
    def query(self, command):
        """Send a command and then receive a value from the RedPitaya
        
           See also send(), receive().
        """
    
        self.send(command)
        return self.receive()
    
    ## Data acquisition
    
    def readDataLowLevel(self, startFrame, numFrames):
        # Initiate transaction
        self.initiateReadingFrameData(startFrame, numFrames);
        
        # Read specified amount of data
        logging.debug('Read data...')
        numSampPerFrame = self._samplesPerPeriod*self._periodsPerFrame
        
        data = []
        expectedBytes = 2*2*numSampPerFrame*numFrames
        receivedBytes = 0
        while receivedBytes < expectedBytes:
            receivedData = self._dataSocket.recv(4096)
            receivedBytes += len(receivedData)
            data.append(receivedData)
        
        # Combine all packets into one array
        data = b''.join(data)
        
        # Restructure bytearray to int16 array with little endian
        data = [item[0] for item in struct.iter_unpack('<h', data)]
        
        # Reshape to one row per ADC channel
        data = np.reshape(data, (2, self._samplesPerPeriod, self._periodsPerFrame, numFrames), 'F')
        
        return data
    
    def readData(self, startFrame, numFrames, numBlockAverages = 1):
        numSamp = self._samplesPerPeriod*numFrames
        numSampPerFrame = self._samplesPerPeriod*self._periodsPerFrame
		
        if not (self._samplesPerPeriod % numBlockAverages) == 0:
            raise TypeError('Block averages has to be a divider of numSampPerPeriod. This is not true with samplesPerPeriod=%.0f and numBlockAverages=%.0f.' % (RP.samplesPerPeriod, numBlockAverages))
        
        numAveragedSampPerPeriod = int(self._samplesPerPeriod/numBlockAverages);
        
        data = np.zeros((2, numAveragedSampPerPeriod, self._periodsPerFrame, numFrames))
        
        wpRead = startFrame
        chunksRead = 0

        # This is a wild guess for a good chunk size
        chunkSize = max(1, round(1000000 / numSampPerFrame))
        logging.debug("chunkSize = %d" % chunkSize)
        while chunksRead < numFrames:
            wpWrite = self.getCurrentFrame()
            while wpRead >= wpWrite: # Wait that startFrame is reached
                wpWrite = self.getCurrentFrame()
                logging.debug("wpWrite=%d" % wpWrite)
            
            chunk = int(min(wpWrite-wpRead, chunkSize)) # Determine how many frames to read
            logging.debug("chunk=%d" % chunk)
            
            if chunksRead+chunk > numFrames:
                chunk = numFrames-chunksRead

            logging.debug("Read from %.0f until %.0f, WpWrite %.0f, chunk=%.0f" % (wpRead, wpRead+chunk-1, wpWrite, chunk))

            u = self.readDataLowLevel(wpRead, chunk)
            
            if numBlockAverages > 1:
                utmp = np.reshape(u, (2, numAveragedSampPerPeriod, numBlockAverages, np.size(u, 2), np.size(u, 3)), 'F')
                utmp = np.mean(utmp, 2);
                data[:,:,:,chunksRead:(chunksRead+chunk)] = utmp
            else:
                data[:,:,:,chunksRead:(chunksRead+chunk)] = u

            chunksRead = chunksRead+chunk
            wpRead = wpRead+chunk
        
        return data
    
    ## API functions
	
    def init(self):
        self.send('RP:Init')
    
    def getAmplitude(self, channel, component):
        data = self.query('RP:DAC:CHannel%d:COMPonent%d:AMPlitude?' % (channel, component))
        return Decimal(data)
    
    def setAmplitude(self, channel, component, amplitude):
        if amplitude > 1.0:
            raise TypeError("Amplitude value is larger than 1.0V!")    # should really check amplitude+offset<1V
        self.send('RP:DAC:CHannel%d:COMPonent%d:AMPlitude %f' % (channel, component, amplitude))
		
    def getOffset(self, channel):
        data = self.query('RP:DAC:CHannel%d:OFFset?' % (channel))
        return Decimal(data)
    
    def setOffset(self, channel, offset):
        if offset > 1.0:
            raise TypeError("Offset value is larger than 1.0V!")    # should really check amplitude+offset<1V
        self.send('RP:DAC:CHannel%d:OFFset %d' % (channel, offset))
    
    def getFrequency(self, channel, component):
        data = self.query('RP:DAC:CHannel%d:COMPonent%d:FREQuency?' % (channel, component))
        return Decimal(data)
    
    def setFrequency(self, channel, component, frequency):
        self.send('RP:DAC:CHannel%d:COMPonent%d:FREQuency %f' % (channel, component, frequency))
    
    def getPhase(self, channel, component):
        data = self.query('RP:DAC:CHannel%d:COMPonent%d:FACtor?' % (channel, component))
        return Decimal(data)
    
    def setPhase(self, channel, component, phase):
        self.send('RP:DAC:CHannel%d:COMPonent%d:PHAse %f' % (channel, component, phase))
		
    def getSignalType(self, channel):
        data = self.query('RP:DAC:CHannel%d:SIGnaltype?' % (channel))
        return data
    
    def setSignalType(self, channel, signalType):
        if signalType.lower() == 'sine':
            self.send('RP:DAC:CHannel%d:SIGnaltype %s' % (channel, 'SINE'))
        elif signalType.lower() == 'square':
            self.send('RP:DAC:CHannel%d:SIGnaltype %s' % (channel, 'SQUARE'))
        elif signalType.lower() == 'triangle':
            self.send('RP:DAC:CHannel%d:SIGnaltype %s' % (channel, 'TRIANGLE'))
        elif signalType.lower() == 'sawtooth':
            self.send('RP:DAC:CHannel%d:SIGnaltype %s' % (channel, 'SAWTOOTH'))
        else:
            raise TypeError('Invalid signal type.');
			
    def getJumpSharpness(self, channel):
        data = self.query('RP:DAC:CHannel%d:JumpSharpness?' % (channel))
        return Decimal(data)
    
    def setJumpSharpness(self, channel, jumpSharpness):
        self.send('RP:DAC:CHannel%d:JumpSharpness %f' % (channel, jumpSharpness))
		
    def getNumSlowADCChannels(self):
        data = self.query('RP:ADC:SlowADC?')
        return Decimal(data)
    
    def setNumSlowADCChannels(self, numSlowADCChannels):
        self.send('RP:ADC:SlowADC %d' % (numSlowADCChannels))
    
    def getDecimation(self):
        if self._decimation is None:
            data = self.query('RP:ADC:DECimation?')
            data = Decimal(data)
            self._decimation = data
        else:
            data = self._decimation
            
        return data
    
    def setDecimation(self, _decimation):
        self.send('RP:ADC:DECimation %d' % _decimation)
        self._decimation = _decimation
    
    def getSamplesPerPeriod(self):
        if self._samplesPerPeriod is None:
            data = self.query('RP:ADC:PERiod?')
            data = Decimal(data)
            self._samplesPerPeriod = data
        else:
            data = self._samplesPerPeriod
        
        return data
    
    def setSamplesPerPeriod(self, _samplesPerPeriod):
        self.send('RP:ADC:PERiod %d' % _samplesPerPeriod)
        self._samplesPerPeriod = _samplesPerPeriod
		
    def getCurrentPeriod(self):
        data = self.query('RP:ADC:PERIODS:CURRENT?')
        return Decimal(data)
		
    def initiateReadingPeriodData(self, startPeriod, numPeriods):
        self.send('RP:ADC:PERiods:DATa %d, %d' % (startPeriod, numPeriods))
		
    def getNumSlowDACChannels(self):
        data = self.query('RP:ADC:SlowDAC?')
        return Decimal(data)
		
    def setNumSlowDACChannels(self, numSlowDACChannels):
        self.send('RP:ADC:SlowDAC %d' % numSlowDACChannels)

    def setSlowDACLUT(self, LUT):
        RP.send(sprintf('RP:ADC:SlowDACLUT'));
            
        # TODO
        #write(rp.dataSocket, lutFloat32)
	
	# TODO: Explain values
    def enableSlowDAC(self, enable, numFrames = 0, rampUpTime = 0.4, rampUpFraction = 0.8):
        self.send('RP:ADC:SlowDACEnable %d, %d, %f, %f' % (enable, numFrames, rampUpTime, rampUpFraction));
	
    def enableSlowDACInterpolation(self, enable):
        self.send('RP:ADC:SlowDACInterpolation %d' % (enable));
    
    def getLostStepsSlowADC(self):
        data = self.query('RP:ADC:SlowDACLostSteps?')
        return Decimal(data)
    
    def getPeriodsPerFrame(self):
	
		# Cache data to prevent too many requests
        if self._samplesPerPeriod is None:
            data = self.query('RP:ADC:FRAme?')
            data = Decimal(data)
            self._periodsPerFrame = data
        else:
            data = self._periodsPerFrame
            
        return data
    
    def setPeriodsPerFrame(self, _periodsPerFrame):
        self.send('RP:ADC:FRAme %d' % _periodsPerFrame)
        self._periodsPerFrame = _periodsPerFrame
		
    def getPeriodsPerFrame(self):
        # Cache data to prevent too many requests
        if self._slowPeriodsPerFrame is None:
            data = self.query('RP:ADC:SlowDACPeriodsPerFrame?')
            data = Decimal(data)
            self._slowPeriodsPerFrame = data
        else:
            data = self._slowPeriodsPerFrame
            
        return data
		
    def setSlowPeriodsPerFrame(self, slowPeriodsPerFrame):
        self.send('RP:ADC:SlowDACPeriodsPerFrame %d' % slowPeriodsPerFrame)
        self._periodsPerFrame = slowPeriodsPerFrame
    
    def getCurrentFrame(self):
        data = self.query('RP:ADC:FRAMES:CURRENT?')
        return Decimal(data)
		
    def getCurrentWritePointer(self):
        data = self.query('RP:ADC:WP:CURRENT?')
        return Decimal(data)
		
    def initiateReadingFrameData(self, startFrame, numFrames):
        self.send('RP:ADC:FRAMES:DATA %d, %d' % (startFrame, numFrames))
		
    def getBufferSize(self):
        data = self.query('RP:ADC:BUFfer:Size?')
        return Decimal(data)
		
    def initiateReadingSlowData(self, startFrame, numFrames):
        self.send('RP:ADC:SLOW:FRAMES:DATA %d, %d' % (startFrame, numFrames))
    
    def startAcquisitionConnection(self):
        self.send('RP:ADC:ACQCONNect')
    
    def getAcquisitionStatus(self):
        data = self.query('RP:ADC:ACQSTATus?')
        
        if data.lower() == 'on':
            status = True
        elif data.lower() == 'off':
            status = False
        else:
            raise ValueError('Invalid acquisition status returned')
            
        return status
    
    def setAcquisitionStatus(self, status, writePointer):
        if status == True:
            self.send('RP:ADC:ACQSTATus %s,%d' % ('ON', writePointer))
        else:
            self.send('RP:ADC:ACQSTATus %s,%d' % ('ON', writePointer))
			
    def getSlowDACClockDivider(self):
        data = self.query('RP:PDM:ClockDivider?')
        return Decimal(data)
    
    def setSlowDACClockDivider(self, divider):
        self.send('RP:PDM:ClockDivider %d' % (divider))
    
    def getPDMNextValue(self, channel):
        data = self.query('RP:PDM:CHannel%d:NextValue?' % (channel))
        return Decimal(data)
    
    def setPDMNextValue(self, channel, nextValue):
        self.send('RP:PDM:CHannel%d:NextValue %d' % (channel, nextValue))
		
    def setPDMNextValueVolt(self, channel, nextValueVolt):
        self.send('RP:PDM:CHannel%d:NextValueVolt %f' % (channel, nextValueVolt))
    
    def getXADCValueVolt(self, channel):
        data = self.query('RP:XADC:CHannel%d?' % channel)
        return Decimal(data)
    
    def getWatchDogMode(self):
        data = self.query('RP:WatchDogMode?')
        
        if data.lower() == 'on':
            mode = True
        elif data.lower() == 'off':
            mode = False
        else:
            raise ValueError('Invalid watchdog mode returned')
            
        return mode
    
    def setWatchDogMode(self, mode):
        if mode == True:
            self.send('RP:WatchDogMode %s' % 'ON')
        else:
            self.send('RP:WatchDogMode %s' % 'OFF')
            
    def getRamWriterMode(self):
        data = self.query('RP:RamWriterMode?')
        return data.lower()
    
    def setRamWriterMode(self, mode):
        if mode.lower() == 'continuous':
            self.send('RP:RamWriterMode %s' % 'CONTINUOUS')
        elif mode.lower() == 'triggered':
            self.send('RP:RamWriterMode %s' % 'TRIGGERED')
        else:
            raise ValueError('Invalid RAM writer mode.')
    
    def getKeepAliveReset(self):
        data = self.query('RP:KeepAliveReset?')
        
        if data.lower() == 'on':
            status = True
        elif data.lower() == 'off':
            status = False
        else:
            raise ValueError('Invalid keep alive reset status returned')
            
        return status
    
    def setKeepAliveReset(self, mode):
        if mode == True:
            self.send('RP:KeepAliveReset %s' % 'ON')
        else:
            self.send('RP:KeepAliveReset %s' % 'OFF')
    
    def getTriggerMode(self):
        data = self.query('RP:Trigger:Mode?')
        return data.lower()
    
    def setTriggerMode(self, mode):
        if mode.lower() == 'internal':
            self.send('RP:Trigger:Mode %s' % 'INTERNAL')
        elif mode.lower() == 'external':
            self.send('RP:Trigger:Mode %s' % 'EXTERNAL')
        else:
            raise ValueError('Invalid trigger mode.')
    
    def getMasterTrigger(self):
        data = self.query('RP:MasterTrigger?')
        
        if data.lower() == 'on':
            status = True
        elif data.lower() == 'off':
            status = False
        else:
            raise ValueError('Invalid master trigger status returned')
            
        return status
    
    def setMasterTrigger(self, mode):
        if mode == True:
            self.send('RP:MasterTrigger %s' % 'ON')
        else:
            self.send('RP:MasterTrigger %s' % 'OFF')
    
    def getInstantResetMode(self):
        data = self.query('RP:InstantResetMode?')
        
        if data.lower() == 'on':
            mode = True
        elif data.lower() == 'off':
            mode = False
        else:
            raise ValueError('Invalid instant reset mode returned')
            
        return mode
    
    def setInstantResetMode(self, mode):
        if mode == True:
            self.send('RP:InstantResetMode %s' % 'ON')
        else:
            self.send('RP:InstantResetMode %s' % 'OFF')
    
    def getPeripheralAResetN(self):
        data = self.query('RP:PeripheralAResetN?')
        
        if data == '1':
            return True
        else:
            return False
    
    def getFourierSynthAResetN(self):
        data = self.query('RP:FourierSynthAResetN?')
        
        if data == '1':
            return True
        else:
            return False
    
    def getPDMAResetN(self):
        data = self.query('RP:PDMAResetN?')
        
        if data == '1':
            return True
        else:
            return False
    
    def getWriteToRAMAResetN(self):
        data = self.query('RP:WriteToRAMAResetN?')
        
        if data == '1':
            return True
        else:
            return False
    
    def getXADCAResetN(self):
        data = self.query('RP:XADCAResetN?')
        
        if data == '1':
            return True
        else:
            return False
    
    def getTriggerStatus(self):
        data = self.query('RP:TriggerStatus?')
        
        if data == '1':
            return True
        else:
            return False
    
    def getWatchdogStatus(self):
        data = self.query('RP:WatchdogStatus?')
        
        if data == '1':
            return True
        else:
            return False
    
    def getInstantResetStatus(self):
        data = self.query('RP:InstantResetStatus?')
        
        if data == '1':
            return True
        else:
            return False
    
    def isValidPin(self, pin):
        if pin in ["DIO7_P", "DIO7_N", "DIO6_P", "DIO6_N", "DIO5_N","DIO4_N","DIO3_N","DIO2_N"]:
            return True
        else:
            return False

    def DIODirection(self, pin, val):
        if not self.isValidPin(pin):
            raise ValueError('RP pin is not available')
            return

        if (val != "IN" and val != "OUT"):
            error("value needs to be IN or OUT!")
            return

        command = "RP:DIO:DIR "+pin+","+ val
        self.send(command)
    
    def setDIO(self, pin, val):
        if not self.isValidPin(pin):
            raise ValueError('RP pin is not available')
            return

        self.DIODirection(pin, "OUT")
        command = "RP:DIO "+pin+","+val
        self.send(command)
            
    def getDIO(self,pin):
        if not self.isValidPin(pin):
            raise ValueError('RP pin is not available')
            return

        self.DIODirection(pin, "IN")
        command = "RP:DIO? "+pin
        return ( self.query(command))
