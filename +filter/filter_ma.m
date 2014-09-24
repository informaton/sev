%> @file fir_ma
%> @brief Finite impulse response moving average filter
%======================================================================
%> @brief Moving average filter.
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c order = 100  (filter order; number of taps in the filter)
%> - @c abs = 0     (1 if the result should be all positive values (absolute
%> %value)
%> @retval filtsig The filtered signal. 
% Moving averager
%> written by Hyatt Moore IV, April 20, 2012
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = filter_ma(sigData, params)

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
    %get root mean square
    if(params.abs)
        sigData = abs(sigData);
    end
    
    delay = floor((params.order)/2);
    b = ones(params.order,1);
    filtsig = filter(b,1,sigData)/params.order;
    
    %account for the delay...
    filtsig = [filtsig((delay+1):end); zeros(delay,1)];
end
