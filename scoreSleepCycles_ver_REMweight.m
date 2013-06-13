function varargout = scoreSleepCycles_ver_REMweight(sleepStageInput)
%stage the NREM-REM sleep cycles from a given sleep file or vector of stages
%if input is a filename, then it is parsed for the sleep vector and an
%addititional column is added to the file containing the sleep cycle for
%each sleep stage entry
%if the input is a vector then the output is a vector of the same length
%with corresponding sleep cycles
%
% score cycles using a REM weight.  REM weight is set to 100 at each REM
% staged epoch, and reduced by 10 for following wake stages, and 25 for
% following NREM stages.  A REM score less than 0 results in a new cycle
% which begins on the epoch after the last REM epoch ended. 


%written by Hyatt Moore IV (< June, 2013)

if(nargin==0)
    sleepStageInput = '/Volumes/Macintosh HD 2/Data/_PLM/A0001_4 165907.STA';
end

if(ischar(sleepStageInput) && exist(sleepStageInput,'file'))
    FileData = load(sleepStageInput,'-ASCII'); %for ASCII file type loading
    stages = FileData(:,2); %grab the sleep stages
else
    FileData = [];
    stages = sleepStageInput;
end;

sleepCycles = zeros(size(stages));

numStages= numel(stages);

REM_weight = 0;
lastREM_index = [];


%initialize beginning cycle 0, prior to any sleep.  
curCycle = 0;
start_index = find(stages~=7&stages~=0,1);
stop_index = numStages;

if(start_index>1)
    sleepCycles(1:start_index)=curCycle;
end

curCycle=1;
wake_delta = 10;
nrem_delta = 25;
rem_delta = 300;
cycle_start_index = start_index;
for s=start_index:stop_index
    if(stages(s) == 5)
        lastREM_index = s;
        REM_weight = rem_delta;
    else
        if(~isempty(lastREM_index))
            if(stages(s)==0||stages(s)==7)
                REM_weight = REM_weight - wake_delta;
            else 
                REM_weight = REM_weight - nrem_delta;
            end
            if(REM_weight < 0)
                %change cycle
                sleepCycles(cycle_start_index:lastREM_index) = curCycle;
                cycle_start_index = lastREM_index+1;
                lastREM_index = [];
                REM_weight = 0;
                curCycle = curCycle+1;
            end
        end
    end
end

%wrap up the last cycle otherwise...
if(sleepCycles(s)~=curCycle)
    sleepCycles(cycle_start_index:s) = curCycle;
end

if(nargout>0)
    varargout{1} = sleepCycles;
end
if(~isempty(FileData))
    [PATH,NAME,EXT] = fileparts(sleepStageInput);
    FileData(:,end+1) = sleepCycles;
%     save(fullfile(PATH,strcat(NAME,'.cycles',EXT)),'FileData','-ASCII')
end