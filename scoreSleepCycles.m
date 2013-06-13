function varargout = scoreSleepCycles(sleepfile)
%stage the NREM-REM sleep cycles from a given sleep file or vector of stages
%if input is a filename, then it is parsed for the sleep vector and an
%addititional column is added to the file containing the sleep cycle for
%each sleep stage entry
%if the input is a vector then the output is a vector of the same length
%with corresponding sleep cycles

%written by Hyatt Moore IV (< June, 2013)

if(nargin==0)
    sleepfile = '/Volumes/Macintosh HD 2/Data/_PLM/A0001_4 165907.STA';
end

if(ischar(sleepfile) && exist(sleepfile,'file'))
    FileData = load(sleepfile,'-ASCII'); %for ASCII file type loading
    stages = FileData(:,2); %grab the sleep stages
else
    FileData = [];
    stages = sleepfile;
end;

sleepCycles = zeros(size(stages));

numStages= numel(stages);

NREM_count = 0;
REM_count = 0;
wake_count = 0;


longestRunningREM = 0;
longestRunningNREM = 0;
longestRunningWake = 0;
runningREM_count = 0;
runningNREM_count = 0;
runningWake_count = 0;
changeCycle = false;
lastREM_index = 0;
% lastWake_index = 0;
% lastNREM_index = 0;
%transitions from cycles should occur around wake
%after a long period of time
%after REM cycle

curCycle = 0;
lastCycle_index = find(stages~=7&stages~=0,1);
if(lastCycle_index==1)
    lastCycle_index = 0;
    lastWake_index = 0;
else
    sleepCycles(1:lastCycle_index)=curCycle;
    lastWake_index = max(lastCycle_index-1,0);
end

curCycle=1;
start_index = lastCycle_index + 1;
for s=start_index:numStages-1
    if(stages(s)==0||stages(s)==7)        
        runningREM_count = 0;
        runningNREM_count = 0;
        wake_count = wake_count+1;
        runningWake_count = runningWake_count+1;
        
        if(runningWake_count>longestRunningWake)
            longestRunningWake = runningWake_count;
        end        
        lastWake_index = s;        
    else        
        if(stages(s)==5)
            REM_count = REM_count+1;
            runningWake_count = 0;
            runningNREM_count = 0;
            runningREM_count = runningREM_count+1;
            if(runningREM_count>longestRunningREM)
                longestRunningREM = runningREM_count;
            end
            lastREM_index = s;
        else
            NREM_count = NREM_count+1;
            runningWake_count = 0;
            runningREM_count = 0;            
            runningNREM_count = runningNREM_count+1;
            if(runningNREM_count>longestRunningNREM)
                longestRunningNREM = runningNREM_count;
            end
            lastNREM_index = s;
        end
    end
    if(stages(s)~=stages(s+1))
       if(lastWake_index == s)  %did we just leave wake?
           
           %if we are not going to be awake again in the next 30 minutes
           if(all(stages(s+1:min(s+30*2,numStages))~=0)&&all(stages(s+1:min(s+30*2,numStages))~=7)) %||(runningWake_count>5*2))
               %1. in NREM for more than 1 hour and awake for at least 2.5
               %minutes
               %2. awake for more than 15 minutes and has been asleep in
               %some form or another for more than an hour and a half with at least
               %30 minutes of continuous sleep
               %3. awake for at least 2.5 minutes AND longest REM section
               %greater than 10 minutes or REM greater than 20 minutes
               %4. REM count>25 minutes and NREM > 60 minutes and just awake
               %more than 1 minute
               %5. if it has been more than 3 hours since last cycle with less
               %than 2 hours of wake
               if((longestRunningNREM>120&&runningWake_count>5)||...
                       (longestRunningNREM>30*2&&runningWake_count>15*2 && NREM_count>90*2)||...
                       ((longestRunningREM>20||REM_count>20*2)&&runningWake_count>2*2)||...
                       (NREM_count>60*2&&REM_count>25*2&&runningWake_count>2*2)||...
                       ((s-lastCycle_index>60*2*3)&&(wake_count<60*2*2)&&runningWake_count>2*2)); %more than three hours since the last cycle and not more than two hours of it being wake
                   changeCycle = true;
               end
               
            %if we are not going to be awake again in the next 10 minutes
            %and have just been awake for 5 minutes or more and have been
            %asleep for more than two hours...
           elseif(NREM_count>120*2 && runningWake_count>5*2 && all(stages(s+1:min(s+10*2,numStages))~=0)&&all(stages(s+1:min(s+10*2,numStages))~=7)) %||(runningWake_count>5*2))
               changeCycle = true;
            %if we are not going to be awake again in the next 10 minutes
            %and have just been awake for 45 minutes or more and have been
            %asleep for more than two hours...
           elseif(NREM_count>90*2 && runningWake_count>45*2 && all(stages(s+1:min(s+10*2,numStages))~=0)&&all(stages(s+1:min(s+10*2,numStages))~=7)) %||(runningWake_count>5*2))
               changeCycle = true;
           end
       elseif(lastREM_index == s) %did we just finish REM?
           %if more than 10 minutes of REM or more than 1 hour of NREM 
           %AND not REM for at least another 30 minutes
           if((REM_count>10*2||NREM_count>(2*60)) && all(stages(s+1:min(s+30*2,numStages))~=5)) 
               changeCycle = true;
           end
       end
    end
    if(changeCycle)
        sleepCycles(lastCycle_index+1:s) = curCycle;
        REM_count = 0;
        NREM_count = 0;
        lastCycle_index = s;
        curCycle = curCycle+1;
        longestRunningREM = 0;
        longestRunningNREM = 0;
        longestRunningWake = 0;
        runningREM_count = 0;
        runningNREM_count = 0;
        runningWake_count = 0;
        changeCycle = false;
    end
end

sleepCycles(lastCycle_index+1:end) = curCycle;

if(nargout>0)
    varargout{1} = sleepCycles;
end
if(~isempty(FileData))
    [PATH,NAME,EXT] = fileparts(sleepfile);
    FileData(:,end+1) = sleepCycles;
%     save(fullfile(PATH,strcat(NAME,'.cycles',EXT)),'FileData','-ASCII')
end