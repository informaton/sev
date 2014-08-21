%> @file filter_movsum
%> @brief Moving summer filter.
%======================================================================
%> @brief Finite impulse response moving summer filter.
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - order = 10  (filter order; number of taps in the filter)
%> - abs = 0     (1 if the result should be all positive values (absolute
%> %value)
%> @retval The filtered signal.
% written by Hyatt Moore IV, April 20, 2012
% Modified 8/21/2014
function filtsig = filter_movsum(srcData, params)
% Moving summer

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin<2 || isempty(params))
    pfile =  strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.order=10;
        params.abs = 0;
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
