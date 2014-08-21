%> @file filter_qma
%> @brief Quick moving average filter
%======================================================================
%> @brief Quick moving average filter.  Calls a compiled c function which
%> can handle the moving average faster than matlab's current
%> implementation.
%> @param Vector of sample data to filter.
%> @param Structure of field/value parameter pairs that to adjust filter's behavior.
%> - order = 100  (filter order; number of taps in the filter)
%> - abs = 0     (1 if the result should be all positive values (absolute
% %value)
%> @retval The filtered signal.
%> @note written by Hyatt Moore IV, April 20, 2012
%> @note modified: 8/21/2014 - changed input checking for optional_params.
function filtsig = filter_qma(data, params)

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin<2  || isempty(params))
    pfile = strcat(mfilename('fullpath'),'.plist');    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.order=10;
        params.abs=0;
        plist.saveXMLPlist(pfile,params);
    end
end

filtsig=filter.filter_movavg(data, params.order);

%get root mean square
if(params.abs)
   filtsig = abs(filtsig); 
end