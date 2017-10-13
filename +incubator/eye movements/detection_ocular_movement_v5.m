function detectStruct = detection_ocular_movement_v5(channel_cell_data,varargin)
%follows detection_ocular_movement1 criteria of finding the difference
%between EOG channels and applying a first pass threshold for candidate eye
%movements.  These candidate EMs are subsequently checked for their
%autocorrelation value which must pass a threshold to verify that they are
%in phase with one another and that not one of them is just "popping" or
%that there is some small difference between them though they are not in
%phase.  If xcorr threshold is met, then a third pass, similar to
%detection_ocular_movement_v4 is used to extend to a realistic EM duration
%source_indices(1) = ocular channel 1
%source_indices(2) = ocular channel 2

% written by Hyatt Moore IV
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
        params.diff_threshold_scale_factor = 2; %diff of EMs should be greater than this for EOG values on first pass
        params.xcorr_threshold = -0.5; %values should be negatively correlated between -0.5 and -1.0
        plist.saveXMLPlist(pfile,params);
    end
end

params.operation = 'mean';        

OCULAR1.data = channel_cell_data{1};
OCULAR2.data = channel_cell_data{2};
abs_of_eye_diff = abs(OCULAR1.data-OCULAR2.data); %should be large for synchronous eye movements

mean_of_eye = mean(abs_of_eye_diff);
%mean_of_eye = mean(abs_of_eye_sum) %almost identical here

% threshold_of_eye_movements = mean_of_eye_movements*2;
diff_threshold = mean_of_eye*params.diff_threshold_scale_factor; %30 uV was limit in paper "precise measures of REM"
first_pass = thresholdcrossings(abs_of_eye_diff, diff_threshold);

%second pass is the xcorr result...
second_pass = zeros(size(first_pass));
second_row = 0; %counter for this algorithm, keeps track of the values used.

for row=1:size(first_pass,1)
    range_ind = first_pass(row,1):first_pass(row,2);
    p = xcorr(OCULAR1.data(range_ind),OCULAR2.data(range_ind),0,'coeff');
    if(p<params.xcorr_threshold)
        second_row = second_row+1;
        second_pass(second_row,:)=first_pass(row,:);
    end
end

final_pass = second_pass(1:second_row,:);


detectStruct.new_events = final_pass;

detectStruct.new_data = OCULAR1.data;
detectStruct.paramStruct = [];

toc