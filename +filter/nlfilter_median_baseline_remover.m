%> @file nlfilter_median_baseline_remover
%> @brief Non linear median baseline removal filter.
%> Returns the moving median for a specified window length over
%> the signal vector sig.  Returned signal is a vector with the same length as sig. 
%======================================================================
%> @brief Non linear moving median filter.
%> Returns the moving median for a specified window length (order) over
%> the signal vector sig.  Returned signal is a vector with the same length as sig. 
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - order = 100  (filter order; window length to calculate median from)
%> - abs = 1     (1 if the result should be all positive values (absolute
% %value)
%> @retval The nonlinear filtered signal. 
% note written by Hyatt Moore IV, March 17, 2014
% note updated August 21, 2014 - commenting
function filtsig = nlfilter_median_baseline_remover(data, optional_params)
% Median baseline removal filter
% written by Hyatt Moore IV, March 17, 2014

% this allows direct input of parameters from outside function calls, which
% can be particularly useful in the batch job mode
if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.abs = 0;
        params.order=100;
        plist.saveXMLPlist(pfile,params);
    end
end

filtsig=filter.nlfilter_median(data, params);
filtsig = data-filtsig;

if(params.abs)
   filtsig = abs(filtsig); 
end