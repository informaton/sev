%> @file nfilter_min_past
%> @brief Nonlinear filter that returns the minimum value obtained in the past neighborhood 
% defined in the range [n-params.win_size+1, n] where n is the current
% sample point in the signal.
%======================================================================
%> @brief Nonlinear filter that returns the minimum value obtained in the past neighborhood 
% defined in the range [n-params.win_size+1, n] where n is the current
% sample point in the signal.
%> @param srcData Vector of sample data to filter.
%> @param params Structure of field/value parameter pairs that to adjust filter's behavior.
%> - win_size = 20; %e.g. look 10 beats into the past...
%> @retval filtsig The nonlinear filtered signal. 
%> written by Hyatt Moore IV, April 21, 2012
%> Modified 8/21/2014
%> @note modified 9/24/2014 - streamline default parameter behavior.
%> Calling method with no parameters returns the default params struct for
%> this method.
function filtsig = nlfilter_min_past(srcData, params)
% nonlinear filter that returns the minimum value obtained in the past neighborhood 
% defined in the range [n-params.win_size+1, n] where n is the current
% sample point in the signal
% written by Hyatt Moore IV, April 21, 2012

% initialize default parameters
defaultParams.win_size = 10;
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
    [minVal,minInd] = min(srcData(1:win_size));
    filtsig(1:win_size)=minVal;
    lastInd = 1;
    
    for k=win_size+1:numel(filtsig)
        lastInd = lastInd+1;
        if(minInd<lastInd)
            [minVal,minInd] = min(srcData(lastInd:k));
            minInd = (lastInd-1)+minInd;
        else
            if(srcData(k)<=minVal)
                minInd = k;
                minVal = srcData(k);
            end
        end
        filtsig(k)=minVal;
    end
    
    lastInd = 1;
    
    %this is 1.6 seconds slower than the above method (8.8 vs 10.4)
    for k=win_size+1:numel(filtsig)
        lastInd = lastInd+1;
        filtsig(k) = min(srcData(lastInd:k));
    end
end