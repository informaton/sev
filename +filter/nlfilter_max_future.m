%> @file nfilter_max_future
%> @brief Nonlinear filter that returns the maximum value obtained in the neighborhood 
%> defined in the future range [n, n+params.win_size-1] where n is the current
%> sample point in the signal
%======================================================================
%> @brief Nonlinear filter that returns the maximum value obtained in the neighborhood 
%> defined in the future range [n, n+params.win_size-1] where n is the current
%> sample point in the signal
%> @param srcData Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - @c win_size = 20; %look 10 beats into the future...
%> @retval filtisg The nonlinear filtered signal. 
%> written by Hyatt Moore IV, April 21, 2012
%> Modified 8/21/2014
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = nlfilter_max_future(srcData, params)
% nonlinear filter that returns the maximum value obtained in the neighborhood 
% defined in the future range [n, n+params.win_size-1] where n is the current
% sample point in the signal

% initialize default parameters
defaultParams.win_size = 20;
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
    
    win_size = params.win_size;
    filtsig = srcData;
    futureInd = win_size;
    maxInd = 0;
    for k=1:numel(filtsig)-win_size
        if(maxInd<k)
            [maxVal,maxInd] = max(srcData(k:futureInd));
            maxInd = (futureInd-1)+maxInd;
        else
            if(srcData(futureInd)>=maxVal)
                maxInd = futureInd;
                maxVal = srcData(futureInd);
            end
        end
        filtsig(k)=maxVal;
        futureInd=futureInd+1;
    end
    filtsig(k:end)=max(srcData(k:end));  %or could just set = to maxVal...
end
