%> @file nfilter_plm_upper_threshold
%> @brief Returns the cleaned data returned after two noise floor passes of the input data.
%======================================================================
%> @brief  Returns the cleaned data returned after a two noise floor passes of the input data.  Useful for debugging and generating plots.
%> @param srcData Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c average_power_window_sec = 20;
%> - @c threshold_low_uV = 2;
%> - @c threshold_high_uV = 8;
%> - @c noisefloor_uV_to_turnoff_detection = 50;
%> - @c use_summer = 1;
%> - @c summer_order = 2;
%> - @c samplerate = 100;
%> @retval filtsig The nonlinear filtered signal. 
%> @note This is a wrapper for getNoisefloor().
%> written by Hyatt Moore IV, April 26, 2013
%> Modified 8/21/2014
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = nlfilter_plm_noisefloor_passed(srcData,params)
%returns the cleaned data returned after a noise floor pass of the input data.
% this is primarily for showing good plots in my thesis.
% written by Hyatt Moore, IV
% April 26, 2013

defaultParams.average_power_window_sec = 20;
defaultParams.threshold_low_uV = 2;
defaultParams.threshold_high_uV = 8;
defaultParams.samplerate = 100;
defaultParams.noisefloor_uV_to_turnoff_detection = 50;
defaultParams.summer_order = 2;
defaultParams.use_summer = 1;
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
end
