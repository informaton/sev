%> @file nfilter_plm_upper_threshold
%> @brief Returns the cleaned data returned after two noise floor passes of the input data.
%======================================================================
%> @brief  Returns the cleaned data returned after a two noise floor passes of the input data.  Useful for debugging and generating plots.
%> @param Vector of sample data to filter.
%> @param Structure of field/value parameter pairs that to adjust filter's behavior.
%> - average_power_window_sec = 20;
%> - threshold_low_uV = 2;
%> - threshold_high_uV = 8;
%> - noisefloor_uV_to_turnoff_detection = 50;
%> - use_summer = 1;
%> - summer_order = 2;
%> - samplerate = 100;
%> @retval The nonlinear filtered signal. 
%> @note This is a wrapper for getNoisefloor().
% written by Hyatt Moore IV, April 26, 2013
% Modified 8/21/2014
function filtsig = nlfilter_plm_noisefloor_passed(srcData,params)
%returns the cleaned data returned after a noise floor pass of the input data.
% this is primarily for showing good plots in my thesis.
% written by Hyatt Moore, IV
% April 26, 2013


    
% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin<2 || isempty(params))
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


%first pass

dur_samples_below_count = ceil(0.05*params.samplerate);

[variable_threshold_low_uv, variable_threshold_high_uv, clean_data] = getNoisefloor(srcData, params, params.samplerate);


new_events = variable_triplethresholdcrossings(clean_data, variable_threshold_high_uv,variable_threshold_low_uv,dur_samples_below_count);

%second pass - adjust the noise floor down to 1/2 the lower baseline threshold
% twopass = false;
% twopass= true;
% if(twopass)
if(~isempty(new_events))
    for k=1:size(new_events,1)
        srcData(new_events(k,1):new_events(k,2)) = variable_threshold_low_uv(new_events(k,1):new_events(k,2))/2;
    end
end
filtsig = srcData;
