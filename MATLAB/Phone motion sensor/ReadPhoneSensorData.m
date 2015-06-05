
function phonedata=ReadPhoneSensorData(file)

phonedata=struct('acc',[],'gyro',[],'orien',[],'userlog',[]);

fid=fopen(file,'rt');

fseek(fid,0,'eof');
eof=ftell(fid);
fseek(fid,0,'bof');

disp(file);

ct1=1;
ct2=1;
ct3=1;
ct4=1;
while 1
    buf = fgetl(fid);
    if ~ischar(buf)                 % end of file
        break
    else
        sensor=sscanf(buf,'%3c,',1);
        [dataline, len]=sscanf(buf,'%*3c,%g, %g, %g, %g, %g',5);
        
        if (ct1+ct2+ct3+ct4)==4
            zerotime = dataline(1);         % time stamp at first line
            dataline(1) = 0;
        else
            dataline(1) = (dataline(1)-zerotime)/1000000;     % convert time stamp to time in ms
        end
        
        switch sensor
            case 'acc'
                phonedata.acc(ct1,:) = dataline;
                ct1=ct1+1;
            case 'gyr'
                phonedata.gyro(ct2,:) = dataline;
                ct2=ct2+1;
            case 'ori'
                phonedata.orien(ct3,:) = dataline;
                ct3=ct3+1;

        end
        
                
    end
end


end

