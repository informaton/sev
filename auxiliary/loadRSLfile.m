function rslStruct = loadRSLfile(rsl_filename)
%this function takes a Philips Respironics Alice formatted event file
%(.rsl) and returns a SEV event struct. 
%
%assume samping rate of 100;
%rslStruct has the following fields
%  .Epoch = 30 second epoch that the start_sample falls in.
%  Start_time %string time in HH:MM:SS format
%  Duration_sec %duration of the event in seconds
%   start_stop_matrix = [Start_sample, Stop_sample]
%   Stage - empty
%   label - string label of the type of event loaded...
%
%Author: Hyatt Moore IV, Stanford University
%Date created: 8/22/2012

sample_rate = 100; %100 samples per second


fclose all;
% clc;


% [path,name,ext] = fileparts(rsl_filename);

fid = fopen(rsl_filename,'r');
fseek(fid,0,'bof');

hdr = fread(fid,7,'uint8')';
fseek(fid,7,'bof');

xy=fread(fid,[19,6],'uint8')'; %unknown groupings of 19...

%[74] holds the number of events stored in this file...
%[89:90;108:109;570:571;636:637;702:703;768:769;834:835] same incremental
%difference between consecutive studies...

fseek(fid,121,'bof');
patientData = fread(fid,146,'uint8=>char')';  %birthdate, name, gender
versionInfo = fread(fid,142,'uint8')';

[267, 408]; %unknown %another +B file, unknown...
fseek(fid,273,'bof');

%file start and stop information
start_sec_from_unix_epoch = fread(fid,1,'uint32');
stop_sec_from_unix_epoch = fread(fid,1,'uint32');
start_datenum = datenum(1970,1,1,0,0,start_sec_from_unix_epoch);

datestr(start_datenum,'HH:MM:SS');

%the next section comes in 66 byte chunks
fseek(fid,409,'bof');
eventID = fread(fid,1,'uint8')'; %20 for LM events
eventLabel = fread(fid,60)';

fseek(fid,469,'bof');fread(fid,[66,14],'uint8')';
%these are the channel labels, etc...

ftell(fid);
fseek(fid,1393,'bof');
fstart = ftell(fid);
%events to hold is

fseek(fid,0,'eof');
fend = ftell(fid);
fseek(fid,fstart,'bof');
numEvents = (fend-fstart)/23;

evtStruct.unknownDate = [];
evtStruct.ID = [];
evtStruct.startSecond =[];
evtStruct.durationInHalfSeconds =[];
evtStruct.type = [];
evtStruct.unknownFinish = [];
evtStruct.startTime = [];
%  Duration_sec
%   Start_sample
%   Stop_sample
%   Epoch
%   Stage
duration_seconds = zeros(numEvents,1);
Start_sample = zeros(numEvents,1);
Stop_sample = zeros(numEvents,1);
Epoch = zeros(numEvents,1);
start_time = cell(numEvents,1);
evtStruct = repmat(evtStruct,numEvents,1);
label = cell(numEvents,1);

%repeat the following for the number of events that we have....
fprintf(1,'Type\tElapsedStart\tDuration\n');
for k=1:numEvents
    fread(fid,1,'uint8'); %get the 10, or \n
    evtStruct(k).unknownDate = fread(fid,1,'uint32'); %get the date?
    evtStruct(k).ID = fread(fid,1,'uint16'); %get the event ID
    evtStruct(k).elapsedHalfSeconds = fread(fid,1,'uint32');  %number of 1/2 seconds elapsed from start
    evtStruct(k).durationInHalfSeconds = fread(fid,1,'uint32'); %duration as 0.5-s chunks
    evtStruct(k).type = fread(fid,1,'uint32'); %LM type?
    evtStruct(k).unknownFinish = fread(fid,1,'uint32'); %unknown
    
    start_datenum = datenum(1970,1,1,0,0,start_sec_from_unix_epoch+evtStruct(k).elapsedHalfSeconds/2);
    start_time{k} = datestr(start_datenum,'HH:MM:SS');

    if(evtStruct(k).ID==20)
        label{k} = 'LM_AASM2007';
    elseif(evtStruct(k).ID==50)
        label{k} = 'LM_maybe';
    else
        label{k} = 'unknown';
    end;
    duration_seconds(k) = evtStruct(k).durationInHalfSeconds*0.5;
    Start_sample(k) = evtStruct(k).elapsedHalfSeconds/2*sample_rate;
    Stop_sample(k) =  Start_sample(k)+duration_seconds(k)*sample_rate;
    Epoch(k) = ceil(Start_sample(k)/30/sample_rate); %1st sample is in epoch 1

    fprintf(1,'%s\t%s\t%0.1f\n',label{k},start_time{k},evtStruct(k).durationInHalfSeconds*0.5);
end

rslStruct.label = label;
rslStruct.duration_seconds = duration_seconds;
rslStruct.start_stop_matrix = [Start_sample,Stop_sample];
rslStruct.epoch = Epoch;
rslStruct.stage = zeros(numEvents,1);
rslStruct.start_time = start_time;
fclose(fid);