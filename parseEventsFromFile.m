function cellOfevents_class = parseEventsFromFile(filename,CHANNEL_INDICES,CHANNEL_NAMES,t0,fs)
%function cellOfevents_class = parseEventsFromFile(filename,CHANNEL_INDICES,CHANNEL_NAMES,t0,fs)
%parseEventsFromFile parses events found in the file named filename and
%returns cellOfevents_class 
%cellOfevents_class is a cell with the same dimension as CHANNEL_INDICES and
%CHANNEL_NAMES

% Hyatt Moore IV (< June, 2013)

% % uncomment the following for debugging
% fclose('all');
% CHANNEL_INDICES = [3,5];
% CHANNEL_NAMES = {'Break','Bone'};
% t0 =[ 2003           4           1          22          38          25];
% fs = 100;
% filename = '/Users/hyatt4/Documents/Sleep Project/A Training Set/A0097_4 174733.evt.txt';

fid = fopen(filename,'r');

%textscan output is a cell array of the following - number of rows
 %coincide with the number of events recorded in the file
%  {1} = day
%  {2} = hour
%  {3} = minute
%  {4} = second
%  {5} = duration
%  {6} = type (message/string)
%  {7} = CHANNEL_INDICES number (char)
%  {8} = reference (double)

% events_from_file= textscan(fid,'%*n %*n %n %n:%n:%n %n %[^0123456789\t] %c-%d8%*s %*s','commentstyle','#','headerlines',1);
events_from_file= textscan(fid,'%*n %*n %n %n:%n:%n %n %[^0123456789\t] %c-%d8%*s %*s','commentstyle','#','headerlines',1);

fclose(fid);

ascii_offset = 48;
events_from_file{7}=events_from_file{7}-ascii_offset;

t0_sec = time2sec([t0(4) t0(5) t0(6)]);

cellOfevents_class = cell(numel(CHANNEL_INDICES),1);

for channel_counter = 1:numel(CHANNEL_INDICES)

    cur_channel_indices = events_from_file{7}==CHANNEL_INDICES(channel_counter);

    %process start and stop indices from start time, duration, and t0 ...
    %create a table of indices for the comment to be used...
    start_sec = time2sec([events_from_file{2}(cur_channel_indices)+24*(events_from_file{1}(cur_channel_indices)-1),...
        events_from_file{3}(cur_channel_indices), events_from_file{4}(cur_channel_indices)]);
 
    start_indices = floor((start_sec-t0_sec)*fs+1);
    stop_indices = start_indices+floor(events_from_file{5}(cur_channel_indices)*fs);

    cellOfevents_class{channel_counter} = events_class(CHANNEL_INDICES(channel_counter),...
        CHANNEL_NAMES{channel_counter},fs,[start_indices, stop_indices],...
        events_from_file{6}(cur_channel_indices));

end


%see file reference material at the bottom of this file to help understand
%what is going on with the pattern matching here... also type 'help regexp'

% %% sub functions
function sec = time2sec(time)
%time is a nx3 vector containing hh, min, sec in that order
%the vector is converted to a single scalar value representing the seconds
%of that time
sec = 3600*time(:,1)+60*time(:,2)+time(:,3);


%referece
% 
% function [time, duration, CHANNEL_INDICES] = parseArtifactLine(art_line)
% %returns the time and duration fields (in seconds) found in the artifact line
% %note: regexp may be a better way to go in the future
% [seq,R] = strtok(art_line); %T = Sequence
% [number,R] = strtok(R); %T = Number
% [dayCount,R] = strtok(R); %dayCount = 1 for first day, and increments by one thereafter
% [time,R] = strtok(R); %time = start time
% 
% %use a regular expression to pull out the hour, min, and second fields
% timePat = '(?<hh>\d+):(?<min>\d+):(?<sec>\d+(.)?\d*)';
% time = regexp(time,timePat,'names');
% time = time2sec([str2num(time.hh)+24*(str2num(dayCount)-1), str2num(time.min), str2num(time.sec)]);
% [duration,R] = strtok(R);
% duration = str2num(duration);
% [type,R] = strtok(R);
% [CHANNEL_INDICES,R] = strtok(R); 
% 
% %SEQUENCE	NUMBER	START	DURATION	TYPE	CHANNEL_INDICES%
% % 1	1	01 21:27:33.000	5.000	Muscular	6--1
% % 1	2	01 21:27:33.000	16.000	Muscular	5--1
% % 1	3	01 21:27:33.900	0.300	Ocular Blink	0-0
% % 1	4	01 21:27:41.000	8.000	Muscular	6--1
% 
