function [t, comments, uniqueSources, uniqueSourcesCount] = parseArtifactsFromFile(file1,CHANNEL,t0,fs)
%parses a text file whose format is SEQUENCE	NUMBER	START	DURATION
%TYPE	CHANNEL
% 1	1	01 21:27:33.000	5.000	Muscular	6--1
%and extracts the beginning and ending times of each artifact in the file.
%these times are converted into start and stop sample points if the start
%time (t0) is specified along with the sampling frequency (fs). CHANNEL is
%the channel to be compared in each file
%t is a Nx2 matrix of start stop indices for N events found in channel
%CHANNEL of file file1.
%t0 is [year month day hour min sec] formatted vector
%if CHANNEL is a vector of channels then t will correspondingly grow in
%dimension and becomes a cell array 
%comments are the comments found in the file for each value (typically
%'muscular activity' or 'spindle a' - also as an arrray for greater than
%one channel.  To recover for multiple channels use the following
% channel1 = t{1}; comments_channel1 = comments{1};
% channel2 = t{2]; comments_channel2 = comments{2};
% uniqueSources is a cell vector containing all of the unique strings that were found as sources in the file
% when the following format was used in the comments section of the file: [source].[type].[message] 
% uniqueSourcesCount is the number of unique sources found for each channel
% and is an Nx1 vector if there are N channels.
%
%t - start and stop indices for the events listed in the file... (based on
%durtion and start parameters from the text file)
%
%comments - string in the format [source].[type].[message] as found from
%the events file (e.g. 'Artifact' or 'Can.spindle.A')
%
%uniqueSources - cell array of string labels found as description sources
%(i.e. see comments) for each channel.
%
%uniqueSourcesCount - cell array containing the number of unique sources
%found in each channel

% Hyatt Moore IV (< June, 2013)


%see file reference material at the bottom of this file to help understand
%what is going on with the pattern matching here... also type 'help regexp'
% pat = '\d+\s+\d+\s+(?<dayCount>\d+)\s+(?<hh>\d+):(?<min>\d+):(?<sec>\d+(\.)?\d*)\s+(?<duration>\d+(\.)?\d*)\s+((?<comment_source>.+)\.(?<comment_method>.+)\.(?<comment_message>.+))|(?<comment>.+)\s+(?<channel>\d+)\-(\-\d+|\d+).*';
pat = '\d+\s+\d+\s+(?<dayCount>\d+)\s+(?<hh>\d+):(?<min>\d+):(?<sec>\d+(\.)?\d*)\s+(?<duration>\d+(\.)?\d*)\s+(?<comment>.+)\s+(?<channel>\d+)\-(\-\d+|\d+).*';
commentPat = '(?<source>[^.]+)\.(?<type>[^.]+)\.(?<message>.*)'; %this is source.method.comment

numChan = numel(CHANNEL);
tmpChannel = '';
for k=1:numChan
    tmpChannel = strvcat(tmpChannel,num2str(CHANNEL(k)));
end;
CHANNEL = tmpChannel;
fid1 = fopen(file1,'r');
t0_sec = time2sec([t0(4) t0(5) t0(6)]);
file1_open = true;
%strip the headers
% fgetl(fid1);
% if(numChan>1)
t = cell(numChan,1,2); %zeros(numChan,1,2);
comments = cell(numChan,1,1);

default_source = '{unknown}';
default_label = [default_source '.event.'];
uniqueSources = cell(numChan,1);
uniqueSourcesCount = zeros(numChan,1);
while(file1_open)
    time1 = fgetl(fid1);
    if(~ischar(time1))
        file1_open = false;
    else
        p = regexp(time1,pat,'names');
        if(~isempty(p))
            for k=1:numChan
                if(p.channel == CHANNEL(k))
                    t1_sec = time2sec([str2double(p.hh)+24*(str2double(p.dayCount)-1), str2double(p.min), str2double(p.sec)]);
                    %                 ind(k) = ind(k)+1;
                    t{k} = [t{k};[floor((t1_sec-t0_sec)*fs+1) floor((t1_sec-t0_sec+str2double(p.duration))*fs)]];
                    
                    %check to see if there is a unique source...
                    cp = regexp(p.comment,commentPat,'names');
                    if(isempty(cp))
                        p.comment = [default_label p.comment]; %i.e. '{unknown}.event.(p.comment)'
                        clear cp;
                        cp.source = default_source;
                    end;
                    if(isempty(find(strcmp(uniqueSources(k,:),cp.source), 1)))
                        uniqueSourcesCount(k) = uniqueSourcesCount(k)+1;
                        uniqueSources{k,uniqueSourcesCount(k)}=cp.source;
                        %this has a problem of growing inside the
                        %loop, and also that the cell array will
                        %likely have a lot of empty parts in the
                        %second portion.
                    end;
                    
                    comments{k} = strvcat(comments{k},p.comment);

                    break; %done with this for loop because only have one channel per line
                end;
            end;
        end;
    end;
end;

if(numChan==1)
    t=t{1};
    comments = comments{1};
end;

% else
%     ind = 0;
%     t = zeros(1,2);
% 
%     while(file1_open)
%         time1 = fgetl(fid1);
%         if(~ischar(time1))
%             file1_open = false;
%         else
%     
%             %old way of doing this, which worked, but only handled one channel at a
%             %time - 0.5 seconds faster if just one channel used...
%             [t1, d1,channel] = parseArtifactLine(time1);
%             if(channel == CHANNEL) %make sure we are looking at the correct channel
%                 ind = ind+1;
%                 t(ind,:) = [floor((t1-t0_sec)*fs+1) floor((t1-t0_sec+d1)*fs)];
%             end;
%         end;
% 
%     end;
%     comments = 0;
% 
% end;
%handle each comparison case separately - old way

fclose(fid1);

function [time, duration, channel] = parseArtifactLine(art_line)
%returns the time and duration fields (in seconds) found in the artifact line
%note: regexp may be a better way to go in the future
[seq,R] = strtok(art_line); %T = Sequence
[number,R] = strtok(R); %T = Number
[dayCount,R] = strtok(R); %dayCount = 1 for first day, and increments by one thereafter
[time,R] = strtok(R); %time = start time

%use a regular expression to pull out the hour, min, and second fields
timePat = '(?<hh>\d+):(?<min>\d+):(?<sec>\d+(.)?\d*)';
time = regexp(time,timePat,'names');
time = time2sec([str2num(time.hh)+24*(str2num(dayCount)-1), str2num(time.min), str2num(time.sec)]);
[duration,R] = strtok(R);
duration = str2num(duration);
[type,R] = strtok(R);
[channel,R] = strtok(R); 

%SEQUENCE	NUMBER	START	DURATION	TYPE	CHANNEL%
% 1	1	01 21:27:33.000	5.000	Muscular	6--1
% 1	2	01 21:27:33.000	16.000	Muscular	5--1
% 1	3	01 21:27:33.900	0.300	Ocular Blink	0-0
% 1	4	01 21:27:41.000	8.000	Muscular	6--1

%% sub functions
function sec = time2sec(time)
%time is a 3x1 vector containing hh, min, sec in that order
%the vector is converted to a single scalar value representing the seconds
%of that time
sec = 3600*time(1)+60*time(2)+time(3);

function timeStr = sec2time(sec)
%converts time given in seconds to a string that gives the time in hours,
%minutes, and seconds
timeStr = sprintf('%02i:%02i:%02i',floor(mod(sec/3600,24)),floor(mod(sec/60,60)),floor(mod(sec,60)));
%minutes could also  be = floor(mod(mod(sec,3600)/60,60));
