[filename,pathname] = uigetfile('datalog*', 'sensor datafile');

data=ReadPhoneSensorData([pathname,filename]);

if ~isempty(data.acc)
    figure(1);
    plot(data.acc(:,1),data.acc(:,2),data.acc(:,1),data.acc(:,3),data.acc(:,1),data.acc(:,4));
    len=length(data.acc(:,1));
    frequency=len/data.acc(len,1)*1000;
    buf=sprintf('Accelerometer (%3.1f Hz)',frequency);
    title(buf);
end

if ~isempty(data.gyro)
    figure(2);
    plot(data.gyro(:,1),data.gyro(:,2),data.gyro(:,1),data.gyro(:,3),data.gyro(:,1),data.gyro(:,4));
    len=length(data.gyro(:,1));
    frequency=len/data.gyro(len,1)*1000;
    buf=sprintf('Gyroscope (%3.1f Hz)',frequency);
    title(buf);
end

if ~isempty(data.orien)
    figure(3);
    plot(data.orien(:,1),data.orien(:,2),data.orien(:,1),data.orien(:,3),data.orien(:,1),data.orien(:,4));
    len=length(data.orien(:,1));
    frequency=len/data.orien(len,1)*1000;
    buf=sprintf('Orientation (%3.1f Hz)',frequency);
    title(buf);
end