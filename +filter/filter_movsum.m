%> @file filter_movsum.cpp
%> @brief Moving summer filter.
%======================================================================
%> @brief Finite impulse response moving summer filter.
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c order = 10  (filter order; number of taps in the filter)
%> - @c abs = 0     (1 if the result should be all positive values (absolute value)
%> @retval filtsig The filtered signal.
%> written by Hyatt Moore IV, April 20, 2012
%> Modified 8/21/2014
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = filter_movsum(srcData, params)
% Moving summer

% initialize default parameters
defaultParams.order=10;
defaultParams.abs = 0;
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
        
    delay = floor((params.order)/2);
    b = ones(params.order,1);
    filtsig = filter(b,1,srcData);
    %account for the delay...for detection algorithms
    filtsig = [filtsig((delay+1):end); zeros(delay,1)];
    
    %get absolute value
    if(params.abs)
        filtsig = abs(filtsig);
    end
end
