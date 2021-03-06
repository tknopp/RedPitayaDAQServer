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
        slowPeriodsPerFrame
        printStatus = false
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
                
                % Initialize RedPitaya with FPGA image
                RP.init();
                
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
            if RP.printStatus
                fprintf('Sending command: %s\n\r', command);
            end
            fprintf(RP.socket, strcat(command, RP.delim));
        end
        
        function data = receive(RP)
        % RECEIVE  Receive a value from the RedPitaya
        %
        %   See also SEND, QUERY.
            
            data = fscanf(RP.socket, strcat('%c', RP.delim));
        end
        
        function data = query(RP, command)
        % QUERY  Send a command and then receive a value from the RedPitaya
        %
        %   See also SEND, RECEIVE.
        
            RP.send(command);
            data = RP.receive();
        end
        
        function setPrintStatus(RP, printStatus)
        % SETPRINTSTATUS  Set flag for printing status messages
        
            RP.printStatus = printStatus;
        end
        
        %% Data acquisition
        
        function data = readDataLowLevel(RP, startFrame, numFrames)
            % Initiate transaction
            RP.initiateReadingFrameData(startFrame, numFrames);
            
            % Read specified amount of data
            if RP.printStatus
                fprintf('Read data...\n\r');
            end
            numSampPerFrame = RP.samplesPerPeriod*RP.periodsPerFrame;
            data = int16(fread(RP.dataSocket, 2*numSampPerFrame*numFrames, 'int16'));
            
            % Correct endianness
            data = swapbytes(data);
            
            if RP.printStatus
                fprintf('Read data!\n\r');
            end
            
            % Reshape to one row per ADC channel
            data = reshape(data, 2, RP.samplesPerPeriod, RP.periodsPerFrame, numFrames);
        end
        
        function data = readData(RP, startFrame, numFrames, numBlockAverages)
            if nargin < 4
                numBlockAverages = 1;
            end
            
            numSamp = RP.samplesPerPeriod*numFrames;
            numSampPerFrame = RP.samplesPerPeriod*RP.periodsPerFrame;
            
            if mod(RP.samplesPerPeriod, numBlockAverages) ~= 0
                error(sprintf("Block averages has to be a divider of numSampPerPeriod. This is not true with samplesPerPeriod=%d and numBlockAverages=%d.", RP.samplesPerPeriod, numBlockAverages));
            end
            
            numAveragedSampPerPeriod = RP.samplesPerPeriod/numBlockAverages;
            
            data = int16(zeros(numAveragedSampPerPeriod, 2, RP.periodsPerFrame, numFrames));
            
            wpRead = startFrame;
            chunksRead = 1;
            
            numFramesInMemoryBuffer = RP.getBufferSize()/numSamp;
            if RP.printStatus
                fprintf("numFramesInMemoryBuffer = %d\n\r", numFramesInMemoryBuffer);
            end

            % This is a wild guess for a good chunk size
            chunkSize = max(1, round(1000000 / numSampPerFrame));
            if RP.printStatus
                fprintf("chunkSize = %d\n\r", chunkSize);
            end
            while chunksRead<=numFrames
                wpWrite = RP.getCurrentFrame();
                while wpRead >= wpWrite % Wait that startFrame is reached
                    wpWrite = RP.getCurrentFrame();
                    if RP.printStatus
                        fprintf("wpWrite=%d\n\r", wpWrite);
                    end
                end
                
                chunk = min(wpWrite-wpRead, chunkSize); % Determine how many frames to read
                if RP.printStatus
                    fprintf("chunk=%d\n\r", chunk);
                end
                
                if chunksRead+chunk > numFrames
                    chunk = numFrames-chunksRead+1;
                end
                
                if wpWrite - numFramesInMemoryBuffer > wpRead
                    fprintf("WARNING: We have lost data!");
                end

                if RP.printStatus
                    fprintf("Read from %.0f until %.0f, WpWrite %.0f, chunk=%.0f\n\r", wpRead, wpRead+chunk-1, wpWrite, chunk);
                end
                
                u = RP.readDataLowLevel(wpRead, chunk);

                %data(:,:,:,l:(l+chunk-1)) = u;
                
                size(u)
                
                utmp1 = reshape(u, 2, numAveragedSampPerPeriod, numBlockAverages, size(u,3), size(u,4));
                if numBlockAverages > 1
                    utmp2 = mean(utmp1, 3);
                else
                    utmp2 = utmp1;
                end
                
                size(u)

                data(:,1,:,chunksRead:(chunksRead+chunk-1)) = utmp2(1,:,1,:,:);
                data(:,2,:,chunksRead:(chunksRead+chunk-1)) = utmp2(2,:,1,:,:);

                chunksRead = chunksRead+chunk;
                wpRead = wpRead+chunk;
            end
        end
        
        
        %% API functions
        
        function init(RP)
            RP.send(sprintf('RP:Init'));
        end
        
        function data = getAmplitude(RP, channel, component)
            data = RP.query(sprintf('RP:DAC:CHannel%d:COMPonent%d:AMPlitude?', channel, component));
            data = str2double(data);
        end
        
        function setAmplitude(RP, channel, component, amplitude)
            RP.send(sprintf('RP:DAC:CHannel%d:COMPonent%d:AMPlitude %d', channel, component, amplitude));
        end
        
        function data = getOffset(RP, channel)
            data = RP.query(sprintf('RP:DAC:CHannel%d:OFFset?', channel, component));
            data = str2int(data);
        end
        
        function setOffset(RP, channel, offset)
            if offset > 8191
                error("Offset value is larger than 8191!")
            end
            RP.send(sprintf('RP:DAC:CHannel%d:OFFset %d', channel, offset));
        end
        
        function data = getFrequency(RP, channel, component)
            data = RP.query(sprintf('RP:DAC:CHannel%d:COMPonent%d:FREQuency?', channel, component));
            data = str2double(data);
        end
        
        function setFrequency(RP, channel, component, frequency)
            RP.send(sprintf('RP:DAC:CHannel%d:COMPonent%d:FREQuency %f', channel, component, frequency));
        end
        
        function data = getPhase(RP, channel, component)
            data = RP.query(sprintf('RP:DAC:CHannel%d:COMPonent%d:PHAse?', channel, component));
            data = str2double(data);
        end
        
        function setPhase(RP, channel, component, phase)
            RP.send(sprintf('RP:DAC:CHannel%d:COMPonent%d:PHAse %d', channel, component, phase));
        end
        
        function data = getSignalType(RP, channel)
            data = RP.query(sprintf('RP:DAC:CHannel%d:SIGnaltype?', channel));
            data = lower(data);
        end
        
        function setSignalType(RP, channel, signalType)
            if strcmpi(signalType, 'sine')
                RP.send(sprintf('RP:DAC:CHannel%d:SIGnaltype %s', channel, 'SINE'));
            elseif strcmpi(signalType, 'square')
                RP.send(sprintf('RP:DAC:CHannel%d:SIGnaltype %s', channel, 'SQUARE'));
            elseif strcmpi(signalType, 'triangle')
                RP.send(sprintf('RP:DAC:CHannel%d:SIGnaltype %s', channel, 'TRIANGLE'));
            elseif strcmpi(signalType, 'sawtooth')
                RP.send(sprintf('RP:DAC:CHannel%d:SIGnaltype %s', channel, 'SAWTOOTH'));
            else
                error('Invalid signal type.');
            end
        end
        
        function data = getJumpSharpness(RP, channel)
            data = RP.query(sprintf('RP:DAC:CHannel%d:JumpSharpness?', channel));
            data = str2double(data);
        end
        
        function setJumpSharpness(RP, channel, jumpSharpness)
            RP.send(sprintf('RP:DAC:CHannel%d:JumpSharpness? %f', channel, jumpSharpness));
        end
        
        function data = getNumSlowADCChannels(RP)
            data = RP.query(sprintf('RP:ADC:SlowADC?'));
            data = str2double(data);
        end
        
        function setNumSlowADCChannels(RP, numSlowADCChannels)
            RP.send(sprintf('RP:ADC:SlowADC %d', numSlowADCChannels));
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
        
        function data = getCurrentPeriod(RP)
            data = RP.query(sprintf('RP:ADC:PERIODS:CURRENT?'));
            data = str2double(data);
        end
        
        function initiateReadingPeriodData(RP, startPeriod, numPeriods)
            RP.send(sprintf('RP:ADC:PERiods:DATa %d, %d', startPeriod, numPeriods));
        end
        
        function data = getNumSlowDACChannels(RP)
            data = RP.query(sprintf('RP:ADC:SlowDAC?'));
            data = str2double(data);
        end
        
        function setNumSlowDACChannels(RP, numSlowDACChannels)
            RP.send(sprintf('RP:ADC:SlowDAC %d', numSlowDACChannels));
        end
        
        function setSlowDACLUT(RP, LUT)
            RP.send(sprintf('RP:ADC:SlowDACLUT'));
            
            %% TODO
            %write(rp.dataSocket, lutFloat32)
        end
        
        %% TODO: Explain values
        function enableSlowDAC(RP, enable, numFrames, rampUpTime, rampUpFraction)
            if nargin < 3
                numFrames = 0;
            end
            
            if nargin < 4
                rampUpTime = 0.4;
            end
            
            if nargin < 5
                rampUpFraction = 0.8;
            end
            
            RP.send(sprintf('RP:ADC:SlowDACEnable %d, %d, %f, %f', enable, numFrames, rampUpTime, rampUpFraction));
        end
        
        function enableSlowDACInterpolation(RP, enable)
            RP.send(sprintf('RP:ADC:SlowDACInterpolation %d', enable));
        end
        
        function data = getLostStepsSlowADC(RP)
            data = RP.query(sprintf('RP:ADC:SlowDACLostSteps?'));
            data = str2double(data);
        end
        
        function data = getPeriodsPerFrame(RP)
            
            % Cache data to prevent too many requests
            if isempty(RP.samplesPerPeriod)
                data = RP.query(sprintf('RP:ADC:FRAme?'));
                data = str2double(data);
                RP.periodsPerFrame = data;
            else
                data = RP.periodsPerFrame;
            end
        end
        
        function setPeriodsPerFrame(RP, periodsPerFrame)
            RP.send(sprintf('RP:ADC:FRAme %d', periodsPerFrame));
            RP.periodsPerFrame = periodsPerFrame;
        end
        
        function data = getSlowPeriodsPerFrame(RP)
            
            % Cache data to prevent too many requests
            if isempty(RP.slowPeriodsPerFrame)
                data = RP.query(sprintf('RP:ADC:SlowDACPeriodsPerFrame?'));
                data = str2double(data);
                RP.slowPeriodsPerFrame = data;
            else
                data = RP.slowPeriodsPerFrame;
            end
        end
        
        function setSlowPeriodsPerFrame(RP, slowPeriodsPerFrame)
            RP.send(sprintf('RP:ADC:SlowDACPeriodsPerFrame %d', slowPeriodsPerFrame));
            RP.slowSamplesPerPeriod = slowPeriodsPerFrame;
        end
        
        function data = getCurrentFrame(RP)
            data = RP.query(sprintf('RP:ADC:FRAMES:CURRENT?'));
            data = str2double(data);
        end
        
        function data = getCurrentWritePointer(RP)
            data = RP.query(sprintf('RP:ADC:WP:CURRENT?'));
            data = str2double(data);
        end

        function initiateReadingFrameData(RP, startFrame, numFrames)
            RP.send(sprintf('RP:ADC:FRAMES:DATA %d, %d', startFrame, numFrames));
        end
        
        function data = getBufferSize(RP)
            data = RP.query(sprintf('RP:ADC:BUFfer:Size?'));
            data = str2double(data);
        end
       
        function initiateReadingSlowData(RP, startFrame, numFrames)
            RP.send(sprintf('RP:ADC:SLOW:FRAMES:DATA %d, %d', startFrame, numFrames));
        end
        
        function startAcquisitionConnection(RP)
            RP.send(sprintf('RP:ADC:ACQCONNect'));
        end
        
        function data = getAcquisitionStatus(RP)
            data = RP.query(sprintf('RP:ADC:ACQSTATus?'));
            data = lower(data);
        end
        
        function setAcquisitionStatus(RP, status, writePointer)
            if strcmpi(status, 'on')
                RP.send(sprintf('RP:ADC:ACQSTATus %s,%d', 'ON', writePointer));
            elseif strcmpi(status, 'off')
                RP.send(sprintf('RP:ADC:ACQSTATus %s,%d', 'OFF', writePointer));
            else
                error('Invalid acquisition status.');
            end
        end
        
        function data = getSlowDACClockDivider(RP)
            data = RP.query(sprintf('RP:PDM:ClockDivider?'));
            data = str2double(data);
        end
        
        function setSlowDACClockDivider(RP, divider)
            RP.send(sprintf('RP:PDM:ClockDivider %d', divider));
        end

        function data = getPDMNextValue(RP, channel)
            data = RP.query(sprintf('RP:PDM:CHannel%d:NextValue?', channel));
            data = str2double(data);
        end
        
        function setPDMNextValue(RP, channel, nextValue)
            RP.send(sprintf('RP:PDM:CHannel%d:NextValue %d', channel, nextValue));
        end
        
        function setPDMNextValueVolt(RP, channel, nextValueVolt)
            RP.send(sprintf('RP:PDM:CHannel%d:NextValueVolt %f', channel, nextValueVolt));
        end
        
        function data = getXADCValueVolt(RP, channel)
            data = RP.query(sprintf('RP:XADC:CHannel%d?', channel));
            data = str2double(data);
        end
        
%         function data = getDIOOutput(RP, pin)
%             data = RP.query(sprintf('RP:DIO:PIN%d?', pin));
%             data = lower(data);
%         end
        
%         function setDIOOutput(RP, pin, value)
%             if strcmp(value, 'on')
%                 RP.send(sprintf('RP:DIO:PIN%d %s', pin, 'ON'));
%             elseif strcmp(value, 'off')
%                 RP.send(sprintf('RP:DIO:PIN%d %s', pin, 'OFF'));
%             else
%                 error('Invalid DIO output.');
%             end
%         end
        
        function mode = getWatchDogMode(RP)
            data = RP.query(sprintf('RP:WatchDogMode?'));
            if strcmpi(data, 'ON')
                mode = true;
            elseif strcmpi(data, 'OFF')
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
            if strcmpi(mode, 'continuous')
                RP.send(sprintf('RP:RamWriterMode %s', 'CONTINUOUS'));
            elseif strcmpi(mode, 'triggered')
                RP.send(sprintf('RP:RamWriterMode %s', 'TRIGGERED'));
            else
                error('Invalid RAM writer mode.');
            end
        end
        
        function mode = getKeepAliveReset(RP)
            data = RP.query(sprintf('RP:KeepAliveReset?'));
            if strcmpi(data, 'ON')
                mode = true;
            elseif strcmpi(data, 'OFF')
                mode = false;
            else
                error('Invalid keep alive reset mode returned');
            end
        end
        
        function setKeepAliveReset(RP, mode)
            if mode == true
                RP.send(sprintf('RP:KeepAliveReset %s', 'ON'));
            else
                RP.send(sprintf('RP:KeepAliveReset %s', 'OFF'));
            end
        end
        
        function data = getTriggerMode(RP)
            data = RP.query(sprintf('RP:Trigger:Mode?'));
            data = lower(data);
        end
        
        function setTriggerMode(RP, mode)
            if strcmpi(mode, 'internal')
                RP.send(sprintf('RP:Trigger:Mode %s', 'INTERNAL'));
            elseif strcmpi(mode, 'external')
                RP.send(sprintf('RP:Trigger:Mode %s', 'EXTERNAL'));
            else
                error('Invalid trigger mode.');
            end
        end
        
        function data = getMasterTrigger(RP)
            data = RP.query(sprintf('RP:MasterTrigger?'));
            data = lower(data);
        end
        
        function setMasterTrigger(RP, mode)
            if strcmpi(mode, 'on')
                RP.send(sprintf('RP:MasterTrigger %s', 'ON'));
            elseif strcmpi(mode, 'off')
                RP.send(sprintf('RP:MasterTrigger %s', 'OFF'));
            else
                error('Invalid master trigger mode');
            end
        end
        
        function mode = getInstantResetMode(RP)
            data = RP.query(sprintf('RP:InstantResetMode?'));
            if strcmpi(data, 'on')
                mode = true;
            elseif strcmpi(data, 'off')
                mode = false;
            else
                error('Invalid instant reset mode returned');
            end
        end
        
        function setInstantResetMode(RP, mode)
            if strcmpi(mode, 'on')
                RP.send(sprintf('RP:InstantResetMode %s', 'ON'));
            elseif strcmpi(mode, 'off')
                RP.send(sprintf('RP:InstantResetMode %s', 'OFF'));
            else
                error('Invalid instant reset mode');
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

