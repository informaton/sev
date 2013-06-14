function filtsig = nlfilter_plm_lower_threshold(src_index,optional_params)
%returns the lower threshold derived using input signal to calculate noise floor
% this is primarily for showing good plots in my thesis.
% written by Hyatt Moore, IV
% April 26, 2013

global CHANNELS_CONTAINER;

if(numel(src_index)>20)
    data = src_index;
    params = optional_params;
else
    data = CHANNELS_CONTAINER.getData(src_index);
    % sample_rate = CHANNELS_CONTAINER.getSamplerate(src_index);
    
    % this allows direct input of parameters from outside function calls, which
    %can be particularly useful in the batch job mode
    if(nargin==2 && ~isempty(optional_params))
        params = optional_params;
    else
        pfile = strcat(mfilename('fullpath'),'.plist');
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future
            params.average_power_window_sec = 20;
            params.threshold_low_uV = 2;
            params.threshold_high_uV = 8;
            params.samplerate = 100;
            params.noisefloor_uV_to_turnoff_detection = 50;
            params.summer_order = 2;
            params.use_summer = 1;            
            plist.saveXMLPlist(pfile,params);
        end
    end
end

[variable_threshold_low_uv, variable_threshold_high_uv, clean_data] = getNoisefloor(data, params, params.samplerate);
filtsig = variable_threshold_low_uv;
