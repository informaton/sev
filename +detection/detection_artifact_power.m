function detectStruct = detection_artifact_power(data,varargin)
% Author Hyatt Moore IV
% created 4/19/2013

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future        
        params.block_len_sec = 5;
        params.min_freq_hz = 5;
        params.power_threshold = 1000;
        params.merge_within_blocks = 5;  %number of blocks to merge between
        plist.saveXMLPlist(pfile,params);
    end
end
PSD_settings.FFT_window_sec = params.block_len_sec;
PSD_settings.interval = params.block_len_sec; %repeat every block, no overlapping
PSD_settings.wintype = 'hamming';
PSD_settings.removemean = 1;

samplerate = params.samplerate;

block_len = params.block_len_sec*samplerate;


%calculate the Power at specified frequency
[power, freqs, ~] = calcPSD(data,samplerate,PSD_settings);

freqs_of_interest = freqs>params.min_freq_hz;
power = power(:,freqs_of_interest);

artifacts = find(sum(power,2)>params.power_threshold);
artifacts = [(artifacts-1)*block_len+1,artifacts*block_len];

merge_within_samples = params.merge_within_blocks*block_len;
[artifacts,merged_indices] = CLASS_events.merge_nearby_events(artifacts,merge_within_samples);

detectStruct.new_data = data;
detectStruct.new_events = artifacts;
detectStruct.paramStruct = [];
end


