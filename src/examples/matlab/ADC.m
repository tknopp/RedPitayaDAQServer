% An example for using the server to acquire some data.
% Connect OUT1 with IN1!

% Add the client object to the path
addpath('../../client/matlab/')

% Connect to the Red Pitaya
%rp = RedPitaya('rp-f00806.local');
rp = RedPitaya('192.168.2.19');
rp.connect();
rp.setPrintStatus(true);

% Define acquisition parameters
decimation = 8;
frequency = 25000;
base_frequency = 125000000;
samples_per_period = base_frequency/frequency;
periods_per_frame = 12;

% Set acquisition parameters
rp.setDecimation(decimation);
rp.setSamplesPerPeriod(samples_per_period);
rp.setPeriodsPerFrame(periods_per_frame);
rp.setFrequency(0, 0, frequency);
rp.setSignalType(0, "sine");
rp.setAmplitude(0, 0, 7000);
rp.setOffset(0, 1000);
rp.setMasterTrigger('off');
rp.setRamWriterMode('triggered');
rp.setTriggerMode("internal");

rp.setAcquisitionStatus('on', rp.getCurrentWritePointer());
rp.setMasterTrigger('on');

firstFrame = rp.readData(0, 1);

rp.setMasterTrigger('off');
rp.setAcquisitionStatus('off', 0);
rp.disconnect();

figure(1);
plot(firstFrame(:, 1, 1))