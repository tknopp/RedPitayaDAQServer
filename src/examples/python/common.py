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
        self._host = host
        self._port = port
        self._dataPort = dataPort
        
        self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._socket.connect((self._host, self._port))
        self._dataSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._dataSocket.connect((self._host, self._dataPort))
    
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
    