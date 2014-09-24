%> @file nlfilter_std.m
%> @brief Non linear moving standard deviation filter.
%======================================================================
%> @brief Moving standard deviation filter.
%> @param Vector of sample data to filter.
%> @param Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c win_length_sec Number of seconds to calculate standard devation from.
%> @retval Non linear filtered signal.
%> @note written by Hyatt Moore IV, on or before June 16, 2012.
%> @note modified 8/21/2014
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function mstd = nlfilter_std(srcData,params)
%returns the moving std for a specified window length (win_length)
%mstd is a vector of length length(s).  win_length can be odd or even

% initialize default parameters

defaultParams.win_length_sec = 0.15; 
% return default parameters if no input arguments are provided.
if(nargin==0)
    mstd = defaultParams;
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
    
    
    % moving standard deviation =
    % moving variance filter =
    %
    % var(x) = mean(x^2)-mean(x)^2;
    % std(x) = sqrt(var(x));
    moving_win_len = ceil(params.win_length_sec*params.samplerate);
    params.order = moving_win_len;
    params.rms = 0;
    mstd = sqrt(filter.filter_ma(srcData.^2,params)-filter.filter_ma(srcData,params).^2);
end