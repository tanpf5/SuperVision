%data = ReadPhoneSensorData('/Users/Tanp/Documents/MATLAB/Graph/left-right');
 data = ReadPhoneSensorData('/Users/Tanp/Documents/MATLAB/Phone motion sensor/Tap Phone/tan_11');
if ~isempty(data.gyro)
    figure(1);
    plot(data.gyro(:,4));
end

a=[0.0315399170 0.0308532715 0.0299682617];
fprintf('%f',std(a));

