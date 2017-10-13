%> @file
%> @brief Detects excessive power in an upper frequency range.
%======================================================================
%> @brief Detects portions of data where the upper frequency range exceeds
%> a minimum power threshold.
%> @param data Signal data as a column vector.
%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c block_len_sec Calculate average power over consecutive windows of this duration in seconds
%> @li @c min_freq_hz Minimum frequency to begin power calculation from
%> @note Upper frequency is determined by nyquist rate (i.e. half sample rate).
%> @li @c merge_within_blocks Number of consecutive blocks to merge detections within.
%> @li @c power_threshold Threshold to exceed (uV) for artifact detection.
%>
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c new_data Copy of input data.
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. one per row).
%> @li @c paramStruct Unused.
function detectStruct = detection_artifact_power(data,params,stageStruct)
    % Author Hyatt Moore IV
    % created 4/19/2013
    
    % modified 9/15/2014 - streamline default parameter behavior.
    
    % initialize default parameters
    defaultParams.block_len_sec = 5;
    defaultParams.min_freq_hz = 5;
    defaultParams.power_threshold = 1000;
    defaultParams.merge_within_blocks = 3;  %number of blocks to merge between
    
    % return default parameters if no input arguments are provided.
    if(nargin==0)
        detectStruct = defaultParams;
    else
        
        if(nargin<2 || isempty(params))
            
            pfile =  strcat(mfilename('fullpath'),'.plist');
            
            if(exist(pfile,'file'))
                %load it
                params = plist.loadXMLPlist(pfile);
            else
                %make it and save it for the future
                params = defaultParams;
                plist.saveXMLPlist(pfile,params);
            end
        end
        
        
        PSD_settings.FFT_window_sec = params.block_len_sec;
        PSD_settings.interval = params.block_len_sec; %repeat every block, no overlapping
        PSD_settings.removemean = 1;
        PSD_settings.wintype = 'rectwin';
        PSD_settings.spectrum_type = 'power';
        
        
        samplerate = params.samplerate;
        
        block_len = params.block_len_sec*samplerate;
        
        
        %calculate the Power at specified frequency
        [power, freqs, ~] = calcPSD(data,samplerate,PSD_settings);
        
        freqs_of_interest = freqs>params.min_freq_hz;
        power = power(:,freqs_of_interest);
        
        artifacts = find(sum(power,2)>params.power_threshold);
        artifacts = [(artifacts-1)*block_len+1,artifacts*block_len];
        
        merge_within_samples = params.merge_within_blocks*block_len;
        buffer_samples = floor(merge_within_samples/2);
        
        artifacts = CLASS_events.buffer_then_merge_nearby_events(artifacts,merge_within_samples,buffer_samples,numel(data));
        %     artifacts = CLASS_events.merge_nearby_events(artifacts,merge_within_samples);
        
        detectStruct.new_data = data;
        detectStruct.new_events = artifacts;
        detectStruct.paramStruct = [];
    end
end


