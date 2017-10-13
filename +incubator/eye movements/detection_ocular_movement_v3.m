function detectStruct = detection_ocular_movement_v3(channel_cell_data,varargin)
%differs from detection_ocular_movement_v2 functinon in that after retrieving the same
%results as v2, it then fits the data into fixed width bins.
%source_indices(1) = ocular channel 1
%source_indices(2) = ocular channel 2
%this version groups the detections into a set interval/chunk or block...
% modified 1/6/2013 - changed sample_rate to samplerate
% modified: 3/1/2013 - updates for channel_cell_data and varargin vice
% global variable and optional_params input

%this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    pfile =  strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
%         params.operation = 'mean';
        params.threshold_scale_factor = 3;
        params.bin_size_seconds = 0.5;
        plist.saveXMLPlist(pfile,params);
    end
end

params.operation = 'mean';

OCULAR1.data = channel_cell_data{1};
OCULAR2.data = channel_cell_data{2};
samplerate = params.samplerate;

abs_of_eye_diff = abs(OCULAR1.data-OCULAR2.data);
abs_of_eye_sum = abs(OCULAR1.data+OCULAR2.data);

mean_of_eye = mean(abs_of_eye_diff); %typically found around 10 uV

% threshold_of_eye_movements = mean_of_eye_movements*2;
threshold = mean_of_eye*params.threshold_scale_factor; %30 uV was limit in paper "precise measures of REM"

first_pass_indices = (abs_of_eye_diff>threshold)&(abs_of_eye_sum<(mean_of_eye/params.threshold_scale_factor));
second_pass = thresholdcrossings(first_pass_indices,0);


bin_size = params.bin_size_seconds*samplerate;  %just take one sample worth for now...

detectStruct.new_events = CLASS_events.fill_bins_with_events(second_pass,bin_size);

merge_distance = round(1/25*samplerate);
detectStruct.new_events = CLASS_events.merge_nearby_events(detectStruct.new_events,merge_distance);
    
detectStruct.new_data = abs_of_eye_sum;
detectStruct.paramStruct = [];

%This would benefit from having
%a minimum detection distance (0.5 secondsfor instance)
%setting the threshold /adjust it by a scalar value of some sort...
%adjusting distance to merge nearby (within some time frame?)
