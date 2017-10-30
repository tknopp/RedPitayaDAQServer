classdef RedPitaya < handle
    %REDPITAYA Provides access to the DAQ functions of the Red Pitaya
    %   All functions which are exposed via SCPI on the server have their
    %   counterpart in this class. This enables the usage of the data
    %   acquisition tools without the need for writing the SCPI commands by
    %   hand.
    
    properties(SetAccess = private)
        host
        port = 5025
        dataPort = 5026
        delim = '\n'
        socket
        dataSocket
        decimation = 16
        samplesPerPeriod
        periodsPerFrame
        isConnected = false
    end
    
    methods
        function RP = RedPitaya(host, port, dataPort)
            if isstring(host) || ischar(host)
                RP.host = host;
            else
                error('Please provide a valid hostname as a string or char array.');
            end
            
            if nargin > 1
                if isinteger(port)
                    RP.port = port;
                else
                    error('Please provide a valid port as an integer.');
                end
            else
                RP.port = 5025;
            end
            
            if nargin > 2
                if isinteger(dataPort)
                    RP.dataPort = dataPort;
                else
                    error('Please provide a valid data port as an integer.');
                end
            else
                RP.dataPort = 5026;
            end
        end
        
        function connect(RP)
        % CONNECT  Connect to the Red Pitaya
        %
        %   See also DISCONNECT.
            
            if ~RP.isConnected
                % Connect to SCPI server
                RP.socket = tcpip(RP.host, RP.port);
                fopen(RP.socket);
                
                % Request a data connection
                RP.send("RP:ADC:ACQCONNect")
                
                % Connect to data port
                RP.dataSocket = tcpip(RP.host, RP.dataPort);
                fopen(RP.dataSocket);
                
                % Set status to 'connected'
                RP.isConnected = true;
            end
        end
        
        function disconnect(RP)
        % DISCONNECT  Disconnect from the Red Pitaya
        %
        %   See also CONNECT.
        
            if RP.isConnected
                % Close sockets
                fclose(RP.dataSocket);
                fclose(RP.socket);

                % Set status to 'disconnected'
                RP.isConnected = false;
            end
        end
        
        function send(RP, command)
        % SEND  Send a command to the RedPitaya
        %
        %   See also RECEIVE, QUERY.
            
            fprintf(RP.socket, strcat(command, RP.delim));
        end
        
        function data = receive(RP)
        % SEND  Receive a value from the RedPitaya
        %
        %   See also SEND, QUERY.
            
            data = fscanf(RP.socket, strcat('%c', RP.delim));
        end
        
        function data = query(RP, command)
        % SEND  Send a command and then receive a value from the RedPitaya
        %
        %   See also SEND, RECEIVE.
        
            RP.send(command);
            data = RP.receive();
        end
        
        %% Data acquisition
        
        
        %% API functions
        
        
        
        
        
        function data = GetXADCValueVolt(RP, channel)
            data = RP.query(sprintf('RP:XADC:CHannel%d?', channel));
        end
    end
    
end

