%> @file nfilter_plm_mid_threshold
%> @brief Calculates a middle amplitude threshold for detecting leg movements from an EMG.  It is derived from the input signal's calculated noise floor
%======================================================================
%> @brief Returns the middle threshold derived using input signal to
%> calculate noise floor.  Useful for debugging and generating plots.
%> @param srcData Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - average_power_window_sec = 20;
%> - threshold_low_uV = 2;
%> - threshold_high_uV = 8;
%> - noisefloor_uV_to_turnoff_detection = 50;
%> - use_summer = 1;
%> - summer_order = 2;
%> - samplerate = 100;
%> @retval filtsig The nonlinear filtered signal. 
%> @note This is a wrapper for getNoisefloor().
%> written by Hyatt Moore IV, April 26, 2013
%> Modified 8/21/2014
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = nlfilter_plm_mid_threshold(srcData,params)
%returns the middle threshold derived using input signal to calculate noise floor
% this is primarily for showing good plots in my thesis.
% written by Hyatt Moore, IV
% April 26, 2013


% initialize default parameters
defaultParams.average_power_window_sec = 20;
defaultParams.threshold_low_uV = 2;
defaultParams.threshold_high_uV = 8;
defaultParams.noisefloor_uV_to_turnoff_detection = 50;
defaultParams.use_summer = 1;
defaultParams.summer_order = 2;
defaultParams.samplerate = 100;
% return default parameters if no input arguments are provided.
if(nargin==0)
    filtsig = defaultParams;
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
    
    [variable_threshold_low_uv, variable_threshold_high_uv, ~] = getNoisefloor(srcData, params, params.samplerate);
    filtsig = (variable_threshold_low_uv+variable_threshold_high_uv)/2;
end
