import socket
from decimal import Decimal
import time
import numpy as np
import select
import struct

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
            # Check for running acquisitions ad stop them
            if self.getAcquisitionStatus() == True:
                self.setAcquisitionStatus(False)
            
            if self.getMasterTrigger() == True:
                self.setMasterTrigger(False)
            
            # Wait a short time to make sure, that all burst transactions
            # are shut down. This prevents the blocking of the AXI bus
            time.sleep(0.1)
            
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
        
        print('Sending command: %s' % command)
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
        self.send('RP:ADC:FRAMES:DATA %.0f,%.0f' % (startFrame, numFrames))
        
        # Read specified amount of data
        print('Read data...')
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
    
    def readData(self, startFrame, numFrames):
        numSampPerFrame = self._samplesPerPeriod*self._periodsPerFrame
        
        data = np.zeros((2, self._samplesPerPeriod, self._periodsPerFrame, numFrames))
        
        wpRead = startFrame
        chunksRead = 0

        # This is a wild guess for a good chunk size
        chunkSize = max(1, round(1000000 / numSampPerFrame))
        print("chunkSize = %d\n\r" % chunkSize)
        while chunksRead < numFrames:
            wpWrite = self.getCurrentFrame()
            while wpRead >= wpWrite: # Wait that startFrame is reached
                wpWrite = self.getCurrentFrame()
                print("wpWrite=%d\n\r" % wpWrite)
            
            chunk = min(wpWrite-wpRead,chunkSize) # Determine how many frames to read
            print("chunk=%d\n\r" % chunk)
            
            if chunksRead+chunk > numFrames:
                chunk = numFrames-chunksRead

            print("Read from %.0f until %.0f, WpWrite %.0f, chunk=%.0f\n\r" % (wpRead, wpRead+chunk-1, wpWrite, chunk))

            u = self.readDataLowLevel(wpRead, chunk)

            data[:,:,:,chunksRead:(chunksRead+chunk)] = u

            chunksRead = chunksRead+chunk
            wpRead = wpRead+chunk
        
        return data
    
    ## API functions
    
    def getAmplitude(self, channel, component):
        data = self.query('RP:DAC:CHannel%d:COMPonent%d:AMPlitude?' % (channel, component))
        return Decimal(data)
    
    def setAmplitude(self, channel, component, amplitude):
        self.send('RP:DAC:CHannel%d:COMPonent%d:AMPlitude %d' % (channel, component, amplitude))
    
    def getFrequency(self, channel, component):
        data = self.query('RP:DAC:CHannel%d:COMPonent%d:FREQuency?' % (channel, component))
        return Decimal(data)
    
    def setFrequency(self, channel, component, frequency):
        self.send('RP:DAC:CHannel%d:COMPonent%d:FREQuency %f' % (channel, component, frequency))
    
    def getModulusFactor(self, channel, component):
        data = self.query('RP:DAC:CHannel%d:COMPonent%d:FACtor?' % (channel, component))
        return Decimal(data)
    
    def setModulusFactor(self, channel, component, factor):
        self.send('RP:DAC:CHannel%d:COMPonent%d:FACtor %d' % (channel, component, factor))
    
    def getPhase(self, channel, component):
        data = self.query('RP:DAC:CHannel%d:COMPonent%d:FACtor?' % (channel, component))
        return Decimal(data)
    
    def setPhase(self, channel, component, phase):
        self.send('RP:DAC:CHannel%d:COMPonent%d:PHAse %d' % (channel, component, phase))
    
    def getDACMode(self):
        data = self.query('RP:DAC:MODe?')
        return data.lower();
    
    def setDACMode(self, mode):
        if mode == 'rasterized':
            self.send('RP:DAC:MODe %s' % 'RASTERIZED')
        elif mode == 'standard':
            self.send('RP:DAC:MODe %s' % 'STANDARD')
        else:
            raise ValueError('Invalid DAC mode.')
    
    def getDACModulus(self, channel, component):
        data = self.query('RP:DAC:CHannel%d:COMPonent%d:MODulus?' % (channel, component))
        return Decimal(data)
    
    def reconfigureDACModulus(self, channel, component, modulus):
        self.send('RP:DAC:CHannel%d:COMPonent%d:MODulus %d' % (channel, component, modulus))
    
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
    
    def getPeriodsPerFrame(self):
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
    
    def getCurrentFrame(self):
        data = self.query('RP:ADC:FRAMES:CURRENT?')
        return Decimal(data)
    
    def startAcquisitionConnection(self):
        self.send('RP:ADC:ACQCONNect')
    
    def getAcquisitionStatus(self):
        data = self.query('RP:ADC:ACQSTATus?')
        
        if data == 'ON':
            status = True
        elif data == 'OFF':
            status = False
        else:
            raise ValueError('Invalid acquisition status returned')
            
        return status
    
    def setAcquisitionStatus(self, status):
        if status == True:
            self.send('RP:ADC:ACQSTATus %s' % 'ON')
        else:
            self.send('RP:ADC:ACQSTATus %s' % 'OFF')
    
    def getPDMNextValue(self, channel):
        data = self.query('RP:PDM:CHannel%d:NextValue?' % (channel))
        return Decimal(data)
    
    def setPDMNextValue(self, channel, nextValue):
        self.send('RP:PDM:CHannel%d:NextValue %d' % (channel, nextValue))
    
    def getPDMCurrentValue(self, channel):
        data = self.query('RP:PDM:CHannel%d:CurrentValue?' % channel)
        return Decimal(data)
    
    def getXADCValueVolt(self, channel):
        data = self.query('RP:XADC:CHannel%d?' % channel)
        return Decimal(data)
    
    def getWatchDogMode(self):
        data = self.query('RP:WatchDogMode?')
        
        if data == 'ON':
            mode = True
        elif data == 'OFF':
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
        if mode == 'continuous':
            self.send('RP:RamWriterMode %s' % 'CONTINUOUS')
        elif mode == 'triggered':
            self.send('RP:RamWriterMode %s' % 'TRIGGERED')
        else:
            raise ValueError('Invalid RAM writer mode.')
    
    def getMasterTrigger(self):
        data = self.query('RP:MasterTrigger?')
        
        if data == 'ON':
            status = True
        elif data == 'OFF':
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
        
        if data == 'ON':
            mode = True
        elif data == 'OFF':
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
    