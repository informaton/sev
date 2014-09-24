%> @file filter_qma
%> @brief Quick moving average filter
%======================================================================
%> @brief Quick moving average filter.  Calls a compiled c function which
%> can handle the moving average faster than matlab's current
%> implementation.
%> @param data Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c order = 100  (filter order; number of taps in the filter)
%> - @c abs = 0     (1 if the result should be all positive values (absolute
% %value)
%> @retval filtsig The filtered signal.
%> @note written by Hyatt Moore IV, April 20, 2012
%> @note modified: 8/21/2014 - changed input checking for optional_params.
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = filter_qma(data, params)
        
% initialize default parameters
defaultParams.order=10;
defaultParams.abs=0;

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
    
    
    filtsig=filter.filter_movavg(data, params.order);
    
    %get root mean square
    if(params.abs)
        filtsig = abs(filtsig);
    end
end