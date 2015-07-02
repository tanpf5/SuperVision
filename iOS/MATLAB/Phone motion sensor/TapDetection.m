% [filename,pathname] = uigetfile('datalog*', 'sensor datafile');
% 
% data=ReadPhoneSensorData([pathname,filename]);
 data = ReadPhoneSensorData('/Users/Tanp/Documents/MATLAB/Phone motion sensor/Tap Phone/tan_12');
% data = ReadPhoneSensorData('/Users/Tanp/Documents/MATLAB/Phone motion sensor/Tap Phone/datalog_20150430_092420');

if ~isempty(data.acc)
    figure(1);
%     plot(data.acc(:,3));
    len=length(data.acc(:,1));
    aa = data.acc(len,1);
    %frequency=len/(data.acc(len,1)-data.acc(1,1))*1000;
    frequency=20;
    buf=sprintf('Accelerometer (%3.1f Hz)',frequency);
    title(buf);
end
tap_res = TapDetectionBySensor(data.acc(:,3),frequency,0.015,0.02,4);

if ~isempty(data.gyro)
    figure(2);
%     plot(data.gyro(:,1),data.gyro(:,2));
    len=length(data.gyro(:,1));
    %frequency=len/data.gyro(len,1)*1000;
    frequency=20;
    buf=sprintf('Gyroscope (%3.1f Hz)',frequency);
    title(buf);
end

tap_res = TapDetectionBySensor(data.gyro(:,2),frequency,0.03,0.05,3);
