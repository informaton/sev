%> @file
%> @brief Dummy detector for debugging and testing purposes only.
%======================================================================
%> @brief Identifies three events and the mean and max of the data over each.
%> @param data Signal data as a column vector.  
%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c threshold1 An unused parameter.
%> @li @c feature2 Unused.
%> @li @c feature3 Unused.
%>
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c new_data Copy of input data.
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c paramStruct Structure with following fields which are vectors
%> with the same numer of elements as rows of @c new_events.
%> @li @c pmean Mean of the data covered by event
%> @li @c pmax Maximum value of the data covered for each event.
function detectStruct = detection_dummy(data,params, stageStruct)

% modified 9/15/2014 - streamline default parameter behavior.

% initialize default parameters
defaultParams.threshold1 = 10.5;
defaultParams.feature2 = 10;
defaultParams.feature3 = 0.45;

% return default parameters if no input arguments are provided.
if(nargin==0)
    detectStruct = defaultParams;
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
    
    
    
    % samplerate = params.samplerate;
    
    detectStruct.new_data = data;
    detectStruct.new_events = [1, 300;
        1100, 1400;
        3001, 3700];
    
    pmean = [mean(data(1:300));
        mean(data(1100:1400));
        mean(data(3001:3700))];
    pmax = [max(data(1:300));
        max(data(1100:1400));
        max(data(3001:3700))];
    
    
    detectStruct.paramStruct.pmean = pmean;
    detectStruct.paramStruct.pmax = pmax;
end
end
