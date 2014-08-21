%> @file nfilter_plm_upper_threshold
%> @brief Calculates an upper amplitude threshold derived from the input signal's calculated noise floor
%======================================================================
%> @brief Returns the upper threshold derived using input signal to
%> calculate noise floor.  Useful for debugging and generating plots.
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
function filtsig = nlfilter_plm_upper_threshold(srcData,params)
% returns the upper threshold derived using input signal to calculate noise floor
% this is primarily for showing good plots in my thesis.
% written by Hyatt Moore, IV
% April 26, 2013


    
% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin<2 || ~isempty(params))
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.average_power_window_sec = 20;
        params.threshold_low_uV = 2;
        params.threshold_high_uV = 8;
        params.noisefloor_uV_to_turnoff_detection = 50;
        params.use_summer = 1;
        params.summer_order = 2;
        params.samplerate = 100;
        plist.saveXMLPlist(pfile,params);
    end
end

[variable_threshold_low_uv, variable_threshold_high_uv, clean_data] = getNoisefloor(srcData, params, params.samplerate);
filtsig = variable_threshold_high_uv;
