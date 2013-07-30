function detectStruct = detection_artifact_brunner(data,varargin)
% Based on the 1996 paper by Brunner titled, "Muscle artifacts in the sleep
% EEG: automated detection and effect on all-night EEG power spectra"
% The method using a moving median filter with adaptive thresholds as
% determined by the surrounding time windows of different lengths.  The
% paper settled on a threshold of 4 times the median value for a surround 3
% minute window.  Three minutes was picked in this case because epochs were
% scored in 60 second blocks for the study done in 1996.  

% Implemented by  Hyat Moore IV
% modified 3/1/2013 - remove global references and use varargin

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
        
        params.long_window_sec = 180;
        params.short_window_sec = 4;
        params.threshold_scale = 4;
        plist.saveXMLPlist(pfile,params);
        
    end
end

params.wintype = 'rectwin';



samplerate = params.samplerate;

PSD_settings.removemean = true;
PSD_settings.interval = params.short_window_sec;
PSD_settings.FFT_window_sec=params.short_window_sec;
PSD_settings.wintype = params.wintype;

channel_psd = calcPSD(data,samplerate,PSD_settings);

% channel_psd = calcPSD(channel_obj.data,params.short_window_sec,params.short_window_sec,channel_obj.sample_rate);

%obtain the frequency band/range of interest
spectrum = [26.25 32];
spectrum_ind = round(spectrum/(samplerate/size(channel_psd,2)));
spectrum_ind(1) = max(1,spectrum_ind(1)); %do not want 0 index
spectrum_ind = spectrum_ind(1):spectrum_ind(2);

spectrum_psd = sum(channel_psd(:,spectrum_ind),2);
median_vals = moving_median_filter(spectrum_psd,round(params.long_window_sec/params.short_window_sec));



new_evt_ind = find(spectrum_psd>median_vals(:)*params.threshold_scale);
new_evt_ind = (new_evt_ind-1)*params.short_window_sec*samplerate+1;

detectStruct.new_events = [new_evt_ind(:), new_evt_ind(:)+params.short_window_sec*samplerate-1];
detectStruct.new_data = data;
detectStruct.paramStruct = [];
