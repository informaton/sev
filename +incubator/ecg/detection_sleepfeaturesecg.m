function detectStruct = detection_sleepfeaturesecg(...
    channel_cell_data,inputParams,stageStruct)
% Function template for SEV integration
%
% detectStruct = SleepFeaturesECG...
%                           (channel_cell_data,optional_params,stageStruct)
%
% SleepFeaturesECG extracts ECG features from the PSG channel 'A', which is 
% stored as channel_cell_data{1}. Channel 'A' is a 1xM vector with a
% sampling rate of inputParams.samplerate.
%
% channel_cell_data = A 1x1 cell containing the PSG channel.
%                   channel_cell_data{1} = PSG channel 1.
%
% inputParams - a structure whose fields can be used to directly set
%               SleepFeaturesECG parameters.
%               .samplerate - sample rate of PSG data in channel_cell_data
%                             Is provided by the SEV by default.  
%
% stageStruct - structure provided by the SEV with the following fields
%   .line = the second column of stages_filename - the scored sleep stages
%   .count = the number of stages for each one
%   .cycle - the nrem/rem cycle
%   .firstNonWake - index of first non-Wake(0) and non-unknown(7) staged 
%               epoch
%   .filename = absolute filename (i.e. path included) of the stage file
%               This can often be parsed to find event files or .EDF files
%               with the same naming convention
%   .standard_epoch_sec = Length of the each stage as originally scored
%                         (default is 30 seconds)
%   .study_duration_in_seconds = Length of the study in second
%
%
% This file may be freely used and adjusted for use with the SEV.
%
% Author: Emil Munk
% Created: 5/14/2013
%
% Updates (Date: Modification)



%Standard SEV classification setup.  If inputParams is empty, then
%previously stored inputParams is loaded from .plist file (i.e. xml) which
%is linked to the filename used for this function.
%can be particularly useful in the batch job mode
if(nargin>=2 && ~isempty(inputParams))
    params = inputParams;
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %         params.samplerate = 100; %provided by SEV;
        
        % The epoch length of the data
        params.standard_epoch_sec = 30;
        % Fixed sampling frequency for all inputs
        params.samplerate = 100;
        % Timespan to flag before events
        params.preflag_sec = 5;
        % Timespan to flag after events
        params.postflag_sec = 10;
        % Number of samples flagged before event
        % Save it
        plist.saveXMLPlist(pfile,params);
    end
end

% Events to be flagged
params.Flagged_events = {'LM','LMA','Obs_Apnea',...
    'Central_Apnea','OBS_Apnea','Mixed_Apnea','PLM',...
    'Obst_Apnea','RespA','OA','CA','PLME','Hypopnea','MA',...
    'Apnea','resp','plm','Central_Hypopnea','Obst__Hypopnea'};


params.preflag = ceil(...
    params.preflag_sec*params.samplerate);
% Number of samples flagged after event
params.postflag = ceil(...
    params.postflag_sec*params.samplerate);


samplerate = params.samplerate;  %pull the samplerate for direct use

if(~iscell(channel_cell_data))
    channel_cell_data = {channel_cell_data};
end

ECG = channel_cell_data{1};

%% Excluding events - PLEASE CHECK THIS SECTION!
[folder, patstudy, extension] = fileparts(stageStruct.filename);

% Finding events to be flagged
% Flagged_samples should become a binary vector marking with ones the
% samples that constitute events, or the amount of time, before or after
% events, specified by params.preflag and params.postflag, respectively.
% Go through each type of event marked for flagging in
% params.Flagged_events

% for ev = 1:numel(params.Flagged_events)
%     Flag_event_file = fullfile(folder, strcat(...
%         'evt.',patstudy,'.',params.Flagged_events(ev),'.txt') );
%     %Check to see if the file exists - I don't know if this is the best way
%     if exist(Flag_event_file,'file') 
%         % I don't know what this outputs - please check subsequent commands
%         Flag_event = loadEvtFile(Flag_event_file);
%         for fl = 1:size(Flag_event.Start_sample,1)
%             Flagged_samples(Flag_event.Start_sample(fl)-...
%                 params.preflag:Flag_event.Stop_sample(fl)+...
%                 params.postflag) = 1;
%         end
%     end
% end

Flagged_samples = zeros(length(ECG),1);

%% Creating HRV signal
QRS = detection.detect_QRS(ECG,params);
[HRV.HRV,RR] = QRS2HRV(QRS,params);

%% Converting samplerate of stages to 1 Hz

HRV.Stagesamples = zeros(length(ECG)/samplerate,1)*NaN;
for stn = 1:length(stageStruct.line)
    HRV.Stagesamples((stn-1)*params.standard_epoch_sec+1:stn*...
        params.standard_epoch_sec) = stageStruct.line(stn);
end

% Is the paramStruct allowed to have two levels of fields, eg.
% paramStruct.A.B = x? Or matrices, eg. paramStruct.A = [x y;z t]?
[paramStruct,HRV] = ExtractECGfeatures(HRV,RR,Flagged_samples, params);

%% Saving results
% HRV data, resampled to samplerate (becoming a step function)
data = repmat(HRV.HRV',samplerate,1);
detectStruct.new_data = reshape(data,1,numel(data));

%% Now put into detectStruct output struct
detectStruct.new_data = data;
detectStruct.new_events = [1 2];
detectStruct.paramStruct = paramStruct;
