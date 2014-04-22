function STAGES = loadSTAGES(stages_filename,num_epochs,default_unknown_stage)
%stages_filename is the filename of an ASCII tab-delimited file whose
%second column contains a vector of scored sleep stages for each epoch of
%a sleep study.
%returns the STAGES struct which has the following fields
%.line = the second column of stages_filename - the scored sleep stages
%.count = the number of stages for each one
%.cycle - the nrem/rem cycle
%.firstNonWake - index of first non-Wake(0) and non-unknown(7) staged epoch

%Author: Hyatt Moore IV
%Written: 9.26.2012
% modified before 12.3.2012 to include scoreSleepCycles(.);
% modified 1/16/2013 - added .firstNonWake
% modified 2/2/2013 - added .standard_epoch_sec = 30
%                           .study_duration_in_seconds
% modified 5.1.2013 - added .filename = stages_filename;

if(nargin<3)
    default_unknown_stage = 7;
end

%load stages information
if(exist(stages_filename,'file'))
    stages = load(stages_filename,'-ASCII'); %for ASCII file type loading
    
    if(nargin>1 && ~isempty(num_epochs) && floor(num_epochs)>0)
        if(num_epochs~=size(stages,1))
            STAGES.epochs = stages(:,1);
            STAGES.line = repmat(default_unknown_stage,max([num_epochs;size(stages,1);STAGES.epochs(:)]),1);
            STAGES.line(STAGES.epochs) = stages(:,2);
        else            
            %this cuts things off at thebackend, where we assume th
            %disconnect between num_epochs expected and num epochs found
            %has occurred. However, logically, there is no guarantee that
            %the disconnect did not occur anywhere else (e.g. at the
            %beginning, or sporadically throughout)
            STAGES.line = stages(1:floor(num_epochs),2); 
        end
    else
        STAGES.line = stages(:,2); %grab the sleep stages
    end
    
else

    if(nargin<2)
        mfile =  strcat(mfilename('fullpath'),'.m');
        fprintf('failed on %s\n',mfile);
    else
        STAGES.line = repmat(default_unknown_stage,num_epochs,1);
    end
end;

if(nargin<2)
    num_epochs = numel(STAGES.line);
end
%calculate number of epochs in each stage
STAGES.count = zeros(8,1);
for k = 0:numel(STAGES.count)-1
    STAGES.count(k+1) = sum(STAGES.line==k);
end
%this may be unnecessary when the user does not care about sleep cycles.
% STAGES.cycles = scoreSleepCycles(STAGES.line);
STAGES.cycles = scoreSleepCycles_ver_REMweight(STAGES.line);

firstNonWake = 1;
while( firstNonWake<=numel(STAGES.line) && (STAGES.line(firstNonWake)==7||STAGES.line(firstNonWake)==0))
    firstNonWake = firstNonWake+1;
end
STAGES.firstNonWake = firstNonWake;
if(num_epochs~=numel(STAGES.line))
    fprintf(1,'%s contains %u stages, but shows it should have %u\n',stages_filename,numel(STAGES.line),num_epochs);
end

STAGES.filename = stages_filename;
STAGES.standard_epoch_sec = 30;
STAGES.study_duration_in_seconds = STAGES.standard_epoch_sec*numel(STAGES.line);