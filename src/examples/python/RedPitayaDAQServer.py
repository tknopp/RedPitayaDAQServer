import socket
import time
import numpy as np
import select
import struct

class RedPitaya:
    _host = None
    _port = 5025
    _dataPort = 5026
    _delim = '\n'
    _socket = None
    _dataSocket = None
    
    def __init__(self, host, port = 5025, dataPort = 5026):
        self._host = host
        self._port = port
        self._dataPort = dataPort
        
        self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._socket.connect((self._host, self._port))
        self._dataSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._dataSocket.connect((self._host, self._dataPort))
    
    def send(self, command):
        # Flush input buffer
        input = [self._socket]
        while True:
            inputready, o, e = select.select(input,[],[], 0.0)
            if len(inputready) == 0:
                break
            for s in inputready:
                s.recv(1)
        
        self._socket.sendall((command + self._delim).encode())
    
    def receive(self):
        fileHandle = self._socket.makefile('r')
        data = fileHandle.readline().strip()
        
        # Strings start and end with '"' to mark them. Remove those.
        if data[0] == '"' and data[-1] == '"':
            data = data[1:-1]

        return data
    
    def query(self, command):
        self.send(command)
        return self.receive()
    
    ## Data acquisition
    
    def readSamples(self, startSamp, numSamples):
        chunksSize = 4096

        data = []
        expectedBytes = 2*2*numSamples
        receivedBytes = 0

        if chunksSize > expectedBytes:
          chunksSize = expectedBytes

        self.query("RP:ADC:DATA:PIPELINED? %d,%d,%d" % (startSamp, numSamples, chunksSize) )

        while receivedBytes < expectedBytes:
            receivedData = self._dataSocket.recv(chunksSize)
            receivedBytes += len(receivedData)
            data.append(receivedData)
        
        # Combine all packets into one array
        data = b''.join(data)

        # read away performance data
        self._dataSocket.recv(21)

        # Restructure bytearray to int16 array with little endian
        data = [item[0] for item in struct.iter_unpack('<h', data)]
        
        # Reshape to one row per ADC channel
        data = np.reshape(data, (2, numSamples), 'F')
        
        return data
