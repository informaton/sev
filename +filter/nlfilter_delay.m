%> @file nfilter_delay
%> @brief Delay or advance a signal.  Advance is done by using a negative
%> delay value.
%======================================================================
%> @brief Delay or advance (negative delay) filter.
%> @param Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - samples2delay = 100 (non integer values will be rounded).
%> @retval The delayed signal. 
%> @note  y(n)=x(n-k) %input negative values to advance
% written by Hyatt Moore IV on September 13, 2012
% Modified 8/21/2014
function filtsig = nlfilter_delay(srcData, params)
% delay or advance

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode
if(nargin<2 || isempty(params))
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.samples2delay=100;  %input negative values to advance...
        plist.saveXMLPlist(pfile,params);
    end
end

samples2delay = round(params.samples2delay);  %ensure we are dealing with integer values here

if(samples2delay>0)
    filtsig = [zeros(samples2delay,1);srcData(1:end-samples2delay)];
elseif(samples2delay<0)
    samples2delay = abs(samples2delay);
    filtsig = [srcData(samples2delay+1:end); zeros(samples2delay,1)];
else
    %do nothing - no shifting occurred
    filtsig = srcData;
end
