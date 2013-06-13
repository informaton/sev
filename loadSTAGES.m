function STAGES = loadSTAGES(stages_filename,num_epochs)
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

%load stages information
if(exist(stages_filename,'file'))
    stages = load(stages_filename,'-ASCII'); %for ASCII file type loading
    STAGES.line = stages(:,2); %grab the sleep stages
    if(nargin>1 && ~isempty(num_epochs) && floor(num_epochs)>0)
        STAGES.line = STAGES.line(1:floor(num_epochs));
    end
else
    if(nargin<2)
        mfile =  strcat(mfilename('fullpath'),'.m');
        fprintf('failed on %s\n',mfile);
    else
        STAGES.line = repmat(7,num_epochs,1);
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