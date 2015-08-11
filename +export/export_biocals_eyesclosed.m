%> @file
%> @brief 
%======================================================================
%> @brief 
%> @param data Nx1 cell of signal data (each cell has a vector of time
%> series data)
%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c 
%> @param stageStruct Struct with the following fields
%> @param fileInfoStruct
%> @retval exportStruct
%> as rows of @c new_events.  Each value contains the average power of the
%> signal during the corresponding detected event.
%> @note: Written by Hyatt Moore IV, 5/11/2015, Stanford, CA
function exportStruct = export_biocals_eyesclosed(data, params, stageStruct, fileInfoStruct)

        
        

% initialize default parameters
defaultParams.field1 = [];

% return default parameters if no input arguments are provided.
if(nargin==0)
    exportStruct = defaultParams;
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
    
    exportStruct.data = data;    
    exportStruct.paramStruct = [];
end
end