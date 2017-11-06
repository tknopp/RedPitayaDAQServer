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
        isConnected = false
        decimation
        samplesPerPeriod
        periodsPerFrame
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
                RP.startAcquisitionConnection();
                
                % Connect to data port
                RP.dataSocket = tcpip(RP.host, RP.dataPort);
                RP.dataSocket.InputBufferSize = 2^20;
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
        
            flushinput(RP.socket)
            fprintf('Sending command: %s\n\r', command);
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
        
        function data = readDataLowLevel(RP, startFrame, numFrames)
            % Initiate transaction
            RP.send(sprintf('RP:ADC:FRAMES:DATA %.0f,%.0f', startFrame, numFrames));
            
            % Read specified amount of data
            fprintf('Read data...\n\r');
            numSampPerFrame = RP.samplesPerPeriod*RP.periodsPerFrame;
            data = fread(RP.dataSocket, 2*numSampPerFrame, 'int16');
            fprintf('Read data!\n\r');
            
            % Reshape to one row per ADC channel
            data = reshape(data, 2, numSampPerFrame);
        end
        
        function data = readData(RP, startFrame, numFrames)
            numSamp = RP.samplesPerPeriod*numFrames;
            numSampPerFrame = RP.samplesPerPeriod*RP.periodsPerFrame;
            
            data = int16(zeros(2, RP.samplesPerPeriod, RP.periodsPerFrame, numFrames));
            
            wpRead = startFrame;
            l = 1;

            % This is a wild guess for a good chunk size
            chunkSize = max(1, round(1000000 / numSampPerFrame));
            fprintf("chunkSize = %d\n\r", chunkSize);
            while l<=numFrames
                wpWrite = RP.getCurrentFrame();
                while wpRead >= wpWrite % Wait that startFrame is reached
                    wpWrite = RP.getCurrentFrame();
                    fprintf("wpWrite=%d\n\r", wpWrite);
                end
                
                chunk = min(wpWrite-wpRead,chunkSize); % Determine how many frames to read
                fprintf("chunk=%d\n\r", chunk);
                
                if l+chunk > numFrames
                    chunk = numFrames-l+1;
                end

                fprintf("Read from %.0f until %.0f, WpWrite %.0f, chunk=%.0f\n\r", wpRead, wpRead+chunk-1, wpWrite, chunk);

                u = RP.readDataLowLevel(wpRead, chunk);

                data(:,:,:,l:(l+chunk-1)) = u;

                l = l+chunk;
                wpRead = wpRead+chunk;
            end
        end
        
        
        %% API functions
        
        function data = getAmplitude(RP, channel, component)
            data = RP.query(sprintf('RP:DAC:CHannel%d:COMPonent%d:AMPlitude?', channel, component));
            data = str2double(data);
        end
        
        function setAmplitude(RP, channel, component, amplitude)
            RP.send(sprintf('RP:DAC:CHannel%d:COMPonent%d:AMPlitude %d', channel, component, amplitude));
        end
        
        function data = getFrequency(RP, channel, component)
            data = RP.query(sprintf('RP:DAC:CHannel%d:COMPonent%d:FREQuency?', channel, component));
            data = str2double(data);
        end
        
        function setFrequency(RP, channel, component, frequency)
            RP.send(sprintf('RP:DAC:CHannel%d:COMPonent%d:FREQuency %f', channel, component, frequency));
        end
        
        function data = getModulusFactor(RP, channel, component)
            data = RP.query(sprintf('RP:DAC:CHannel%d:COMPonent%d:FACtor?', channel, component));
            data = str2double(data);
        end
        
        function setModulusFactor(RP, channel, component, factor)
            RP.send(sprintf('RP:DAC:CHannel%d:COMPonent%d:FACtor %d', channel, component, factor));
        end
        
        function data = getPhase(RP, channel, component)
            data = RP.query(sprintf('RP:DAC:CHannel%d:COMPonent%d:FACtor?', channel, component));
            data = str2double(data);
        end
        
        function setPhase(RP, channel, component, phase)
            RP.send(sprintf('RP:DAC:CHannel%d:COMPonent%d:PHAse %d', channel, component, phase));
        end
        
        function data = getDACMode(RP)
            data = RP.query(sprintf('RP:DAC:MODe?'));
            data = lower(data);
        end
        
        function setDACMode(RP, mode)
            if mode == 'rasterized'
                RP.send(sprintf('RP:DAC:MODe %s', 'RASTERIZED'));
            elseif mode == 'standard'
                RP.send(sprintf('RP:DAC:MODe %s', 'STANDARD'));
            else
                error('Invalid DAC mode.');
            end
        end
        
        function data = getDACModulus(RP, channel, component)
            data = RP.query(sprintf('RP:DAC:CHannel%d:COMPonent%d:MODulus?', channel, component));
            data = str2double(data);
        end
        
        function reconfigureDACModulus(RP, channel, component, modulus)
            RP.send(sprintf('RP:DAC:CHannel%d:COMPonent%d:MODulus %d', channel, component, modulus));
        end
        
        function data = getDecimation(RP)
            if isempty(RP.decimation)
                data = RP.query(sprintf('RP:ADC:DECimation?'));
                data = str2double(data);
                RP.decimation = data;
            else
                data = RP.decimation;
            end
        end
        
        function setDecimation(RP, decimation)
            RP.send(sprintf('RP:ADC:DECimation %d', decimation));
            RP.decimation = decimation;
        end
        
        function data = getSamplesPerPeriod(RP)
            if isempty(RP.samplesPerPeriod)
                data = RP.query(sprintf('RP:ADC:PERiod?'));
                data = str2double(data);
                RP.samplesPerPeriod = data;
            else
                data = RP.samplesPerPeriod;
            end
        end
        
        function setSamplesPerPeriod(RP, samplesPerPeriod)
            RP.send(sprintf('RP:ADC:PERiod %d', samplesPerPeriod));
            RP.samplesPerPeriod = samplesPerPeriod;
        end
        
        function data = getPeriodsPerFrame(RP)
            if isempty(RP.samplesPerPeriod)
                data = RP.query(sprintf('RP:ADC:PERiod?'));
                data = str2double(data);
                RP.periodsPerFrame = data;
            else
                data = RP.periodsPerFrame;
            end
        end
        
        function setPeriodsPerFrame(RP, periodsPerFrame)
            RP.send(sprintf('RP:ADC:PERiod %d', periodsPerFrame));
            RP.periodsPerFrame = periodsPerFrame;
        end
        
        function data = getCurrentFrame(RP)
            data = RP.query(sprintf('RP:ADC:FRAMES:CURRENT?'));
            data = str2double(data);
        end
        
        function startAcquisitionConnection(RP)
            RP.send(sprintf('RP:ADC:ACQCONNect'));
        end
        
        function setAcquisitionStatus(RP, status)
            if status == true
                RP.send(sprintf('RP:ADC:ACQSTATus %s', 'ON'));
            else
                RP.send(sprintf('RP:ADC:ACQSTATus %s', 'OFF'));
            end
        end
        
        function data = getPDMNextValue(RP, channel)
            data = RP.query(sprintf('RP:PDM:CHannel%d:NextValue?', channel));
            data = str2double(data);
        end
        
        function setPDMNextValue(RP, channel, nextValue)
            RP.send(sprintf('RP:PDM:CHannel%d:NextValue %d', channel, nextValue));
        end
        
        function data = getPDMCurrentValue(RP, channel)
            data = RP.query(sprintf('RP:PDM:CHannel%d:CurrentValue?', channel));
            data = str2double(data);
        end
        
        function data = getXADCValueVolt(RP, channel)
            data = RP.query(sprintf('RP:XADC:CHannel%d?', channel));
            data = str2double(data);
        end
        
        function mode = getWatchDogMode(RP)
            data = RP.query(sprintf('RP:WatchDogMode?'));
            if data == 'ON'
                mode = true;
            elseif data == 'OFF'
                mode = false;
            else
                error('Invalid watchdog mode returned');
            end
        end
        
        function setWatchDogMode(RP, mode)
            if mode == true
                RP.send(sprintf('RP:WatchDogMode %s', 'ON'));
            else
                RP.send(sprintf('RP:WatchDogMode %s', 'OFF'));
            end
        end
        
        function data = getRamWriterMode(RP)
            data = RP.query(sprintf('RP:RamWriterMode?'));
            data = lower(data);
        end
        
        function setRamWriterMode(RP, mode)
            if mode == 'continuous'
                RP.send(sprintf('RP:RamWriterMode %s', 'CONTINUOUS'));
            elseif mode == 'triggered'
                RP.send(sprintf('RP:RamWriterMode %s', 'TRIGGERED'));
            else
                error('Invalid RAM writer mode.');
            end
        end
        
        function setMasterTrigger(RP, mode)
            if mode == true
                RP.send(sprintf('RP:MasterTrigger %s', 'ON'));
            else
                RP.send(sprintf('RP:MasterTrigger %s', 'OFF'));
            end
        end
        
        function mode = getInstantResetMode(RP)
            data = RP.query(sprintf('RP:InstantResetMode?'));
            if data == 'ON'
                mode = true;
            elseif data == 'OFF'
                mode = false;
            else
                error('Invalid instant reset mode returned');
            end
        end
        
        function setInstantResetMode(RP, mode)
            if mode == true
                RP.send(sprintf('RP:InstantResetMode %s', 'ON'));
            else
                RP.send(sprintf('RP:InstantResetMode %s', 'OFF'));
            end
        end
        
        function data = getPeripheralAResetN(RP)
            data = RP.query(sprintf('RP:PeripheralAResetN?'));
            data = boolean(data);
        end
        
        function data = getFourierSynthAResetN(RP)
            data = RP.query(sprintf('RP:FourierSynthAResetN?'));
            data = boolean(data);
        end
        
        function data = getPDMAResetN(RP)
            data = RP.query(sprintf('RP:PDMAResetN?'));
            data = boolean(data);
        end
        
        function data = getWriteToRAMAResetN(RP)
            data = RP.query(sprintf('RP:WriteToRAMAResetN?'));
            data = boolean(data);
        end
        
        function data = getXADCAResetN(RP)
            data = RP.query(sprintf('RP:XADCAResetN?'));
            data = boolean(data);
        end
        
        function data = getTriggerStatus(RP)
            data = RP.query(sprintf('RP:TriggerStatus?'));
            data = boolean(data);
        end
        
        function data = getWatchdogStatus(RP)
            data = RP.query(sprintf('RP:WatchdogStatus?'));
            data = boolean(data);
        end
        
        function data = getInstantResetStatus(RP)
            data = RP.query(sprintf('RP:InstantResetStatus?'));
            data = boolean(data);
        end
    end
end

