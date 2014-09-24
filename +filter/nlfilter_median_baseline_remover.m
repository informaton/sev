%> @file nlfilter_median_baseline_remover
%> @brief Non linear median baseline removal filter.
%> Returns the moving median for a specified window length over
%> the signal vector sig.  Returned signal is a vector with the same length as sig. 
%======================================================================
%> @brief Non linear moving median filter.
%> Returns the moving median for a specified window length (order) over
%> the signal vector sig.  Returned signal is a vector with the same length as sig. 
%> @param data Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c order = 100  (filter order; window length to calculate median from)
%> - @c abs = 1     (1 if the result should be all positive values (absolute
% %value)
%> @retval filtsig The nonlinear filtered signal. 
%> note written by Hyatt Moore IV, March 17, 2014
%> note updated August 21, 2014 - commenting
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = nlfilter_median_baseline_remover(data, params)
% Median baseline removal filter
% written by Hyatt Moore IV, March 17, 2014

% initialize default parameters
defaultParams.order = 100;
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
    
    
    filtsig=filter.nlfilter_median(data, params);
    filtsig = data-filtsig;
    
    if(params.abs)
        filtsig = abs(filtsig);
    end
end