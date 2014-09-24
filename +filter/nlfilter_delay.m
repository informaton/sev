%> @file nfilter_delay
%> @brief Delay or advance a signal.  Advance is done by using a negative
%> delay value.
%======================================================================
%> @brief Delay or advance (negative delay) filter.
%> @param srcData Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c samples2delay = 100 (non integer values will be rounded).
%> @note  y(n)=x(n-k) %input negative values to advance
%> @retval filtsig The delayed signal. 
%> written by Hyatt Moore IV on September 13, 2012
%> Modified 8/21/2014
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = nlfilter_delay(srcData, params)
% delay or advance

% initialize default parameters

defaultParams.samples2delay = 0; %input negative values to advance...
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
end
