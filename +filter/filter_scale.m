%> @file filter_scale
%> @brief Single element finite impulse response bandpass filter (i.e. multiplication by a scalar value).
%======================================================================
%> @brief Scale signal by a scalar value.
%> @param sigData Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c scalar = 1
%> - @c make_absolute = 0
%> @retval filtsig The scaled signal.
%> @note written by Hyatt Moore IV, February 2, 2013
%> Modified 8/21/2014
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = filter_scale(sigData, params)
% scale signal by scalar value

% initialize default parameters
defaultParams.scalar=1;
defaultParams.make_absolute = 0;
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
    

    
    
    filtsig = sigData*params.scalar;
    %get root mean square
    if(params.make_absolute)
        filtsig = abs(filtsig);
    end
end
