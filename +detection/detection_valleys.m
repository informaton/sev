%> @file detection_valleys.cpp
%> Generic valley detection algorithm.
%> @brief Find valleys in a signal, by calling detection_peaks with the
%input data flipped/multiplied by -1 
%> @note Written 1/29/2016 copyright Hyatt Moore IV

function detectStruct = detection_valleys(data, params, ~)

defaultParams.merge_within_sec = 0.05;
defaultParams.min_dur_sec = 0.05;

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
    
    detectStruct = detection.detection_peaks(-data, params);
end
 
end
