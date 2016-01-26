%> @file CLASS_batch.cpp
%> @brief CLASS_batch serves as the controller class for SEV's batch mode
%> operations which include (1) batch analysis (e.g. event classifications, artifact
%> detection and power spectral analysis) and (2) batch export.
%>
% ======================================================================
%> @brief The methods here are all static.  
%> @note Author: Hyatt Moore IV
%> @note Created 5/10/2015
% ======================================================================
classdef CLASS_batch < handle
    properties
        
    end % end properties
    
    methods
        
    end % End methods
    methods(Static)        
        % ======================================================================
        %> @brief checkPathForEDFs
        % ======================================================================
        %> @param  edfPath        
        %> @playlist
        %> @retval edfPathStruct Struct with fields describing the .edf
        %> files found in the path specified (after filtering with playlist
        %> when provided and it exists).
        %> - @c edf_filename_list 
        %> - @c edf_fullfilename_list
        %> - @c edfPath Same as input parameter edf path 
        %> - @c edf_megabyte_count
        %> - @c statusString
        %> - @c firstHDR
        % ======================================================================
        function edfPathStruct = checkPathForEDFs(edfPath,playlist)
            %looks in the path for EDFs

            edfPathStruct.edf_filename_list = [];
            edfPathStruct.edf_fullfilename_list = [];
            edfPathStruct.edfPathname = [];
            edfPathStruct.edf_megabyte_count = [];
            edfPathStruct.statusString = [];
            edfPathStruct.firstHDR = [];
            
            if(nargin<1 || isempty(edfPath))
                edfPath = pwd;
            end
            if(nargin<2)
                playlist = []; %CLASS_batch.getPlayList(handles);                
            end
            
            edfPathStruct.edfPathname = edfPath;
            
            if(~exist(edfPath,'file'))
                edfPathStruct.statusString = 'Directory does not exist. ';
                num_edfs = 0;
                num_edfs_all = 0;                
            else
                [edfPathStruct.edf_filename_list, edfPathStruct.edf_fullfilename_list] = getFilenamesi(edfPath,'edf');
                
                num_edfs_all = numel(edfPathStruct.edf_filename_list);
                
                if(~isempty(playlist))
                    [edfPathStruct.edf_filename_list, filtered_intersect_indices] = CLASS_batch.filterPlayList(edfPathStruct.edf_filename_list,playlist);
                    edfPathStruct.edf_fullfilename_list = edfPathStruct.edf_fullfilename_list(filtered_intersect_indices);
                end
                num_edfs = numel(edfPathStruct.edf_filename_list);
                total_bytes = 0;
                for e=1:num_edfs
                    tmpF = dir(edfPathStruct.edf_fullfilename_list{e});
                    total_bytes = total_bytes+tmpF.bytes;
                end
                

                edfPathStruct.edf_megabyte_count = total_bytes/1E6;
                
                if(total_bytes>1E9)
                    total_bytes = total_bytes/1E9;
                    byte_suffix = 'GB';
                else
                    total_bytes = total_bytes/1E6;
                    byte_suffix = 'MB';
                end
                
                if(~isempty(playlist))
                    edfPathStruct.statusString = [num2str(num_edfs),' EDF files (',num2str(total_bytes,'%0.1f'),' ',byte_suffix,') found in the current play list. '];
                else
                    edfPathStruct.statusString = [num2str(num_edfs),' EDF files (',num2str(total_bytes,'%0.1f'),' ',byte_suffix,') found in the current directory. '];
                end
            end;            
            
            if(num_edfs==0)
                
                if(num_edfs_all==0)
                    edfPathStruct.statusString = [statusString, 'Please choose a different directory'];
                    set(get(handles.bg_panel_playlist,'children'),'enable','off');
                    
                else
                    edfPathStruct.statusString = [statusString, 'Please select a different play list or use ''All'''];
                end
            else               
                first_edf_fullfilename = edfPathStruct.edf_fullfilename_list{1};
                edfPathStruct.firstHDR = loadEDF(first_edf_fullfilename);
                
            end;            
        end

        
        %------------------------------------------------------------------%
        %> @brief Returns a playlist of .EDF files to process as a subset from a directory
        %> .EDF files.  This is helpful when a selection has been
        %> identified for an experiment and the user does not want to copy
        %> all of the files to another directory just to batch process those
        %> only.
        %------------------------------------------------------------------%        
        %> @param List of filenames to filter through.
        %> @param The list of files that must be matched.
        %> @retval Nx1 cell of filenames that exist in both filename_list and
        %> file_filter_list.  A cell type.
        %> @retval Nx1 vector of indices such that filtered_filename_list =
        %> filename_list(filtered_intersect_indices)
        %------------------------------------------------------------------%
        function [playList, filenameOfPlayList] = getPlayList(directoryOfPlayList, filenameOfPlayList)
            if(nargin<2 || (nargin==2 && (strcmpi(filenameOfPlayList,'-gui') || isempty(filenameOfPlayList)) ))
                
                %make an educated guess regarding the file to be loaded
                fileGuess = directoryOfPlayList;
                
                [filenameOfPlayList, pathname, ~] = uigetfile({'*.ply','.EDF play list (*.ply)'},'Select batch mode play list',fileGuess,'MultiSelect','off');
                
                %did the user press cancel
                if(isnumeric(filenameOfPlayList) && ~filenameOfPlayList)
                    filenameOfPlayList = [];
                else
                    filenameOfPlayList = fullfile(pathname,filenameOfPlayList);
                end
            end
            
            if(exist(filenameOfPlayList,'file'))
                fid = fopen(filenameOfPlayList);
                data = textscan(fid,'%[^\r\n]');
                playList = data{1};
                fclose(fid);
            else
                playList = [];
            end
        end
        
        %------------------------------------------------------------------%
        %> @brief Returns the filenames common to both input arguments and the indices
        %> at which the intersection occurs for the first argument.
        %------------------------------------------------------------------%        
        %> @param List of filenames to filter through.
        %> @param The list of files that must be matched.
        %> @retval Nx1 cell of filenames that exist in both filename_list and
        %> file_filter_list.  A cell type.
        %> @retval Nx1 vector of indices such that filtered_filename_list =
        %> filename_list(filtered_intersect_indices)
        %------------------------------------------------------------------%
        function [filtered_filename_list, filtered_intersect_indices] = filterPlayList(filename_list,file_filter_list)            
            if(~isempty(file_filter_list))
                [filtered_filename_list,~,filtered_intersect_indices] = intersect(file_filter_list,filename_list);  %need to handle case sensitivity
            else
                filtered_filename_list = filename_list;  %i.e. nothing to filter
                filtered_intersect_indices = 1:numel(filtered_name_list);
            end
        end
        
        %------------------------------------------------------------------%
        %> @brief Parses an export information file (.inf) and returns 
        %> each rows values as a struct entry.
        %------------------------------------------------------------------%        
        %> @param Full filename (path and name) of the export information
        %> file to parse.
        %> @retval Struct with the following fields:
        %> - @c mfilename Nx1 cell of filenames of the export method
        %> - @c description Nx1 cell of descriptions for each export method.
        %> - @c settingsEditor Nx1 cell of the settings editor to use for each method.
        %> - @c settings Nx1 cell of the current/default settings found for
        %> each method.        
        %> @note N is the number of non-row headers parsed from the
        %> category information (.inf) file.
        %------------------------------------------------------------------%
        function exportMethodsStruct = getExportMethods(exportInfFullFilename)
            
            % This is a struct whose fields are cell values.
            if(nargin<1 || isempty(exportInfFullFilename))
                exportInfFullFilename = CLASS_codec.getMethodInformationFilename('export');
                
            end
            
            exportMethodsStruct = CLASS_codec.parseExportInfFile(exportInfFullFilename);
            if(~isempty(exportMethodsStruct))
                
                % import the package
                import('export.*');  
                exportMethodsStruct.settings = cell(size(exportMethodsStruct.mfilename));
                for e=1:numel(exportMethodsStruct.mfilename)
                    methodName = exportMethodsStruct.mfilename{e};
                    exportMethodsStruct.settings{e} = CLASS_codec.getMethodParameters(methodName,'export');
                end
            end
        end
        
        %------------------------------------------------------------------%
        %> @brief 
        %------------------------------------------------------------------%
        %> @param edfChannels
        %> @param methodStructs is an Nx1 struct describing the export methods to use.  Fields include:
        %> - @c mfilename Name of the method (no .m extension)
        %> - @c description
        %> - @c settingsEditor 
        %> @param Struct describing the edf's hypnogram.  See
        %> CLASS_code.loadSTAGES        
        %> @retval fileInfoStruct Struct with the following fields:
        %> - @c stages_filename
        %> - @c events_filename
        %> - @c edf_filename (edf filename sans pathname)
        %> - @c edf_header
        %> - @c edf_name 
        %> - @c num_epochs
        %------------------------------------------------------------------%
        function exportData = getExportData(edfChannels,methodStructs,stagesStruct,fileInfoStruct)
            numMethods = numel(methodStructs);
            exportData = cell(numMethods,1);

            for m=1:numMethods
                curMethod = methodStructs(m);
                exportData{m} = CLASS_batch.evaluateExportMethod(edfChannels,curMethod,stagesStruct,fileInfoStruct);
            end
        end


        %------------------------------------------------------------------%
        %> @brief 
        %------------------------------------------------------------------%
        %> @param edfChannels
        %> @param Struct describing the export methods to use.  Fields include:
        %> - @c         
        %> @param Struct describing the edf's hypnogram.  See
        %> CLASS_code.loadSTAGES        
        %> @retval Struct with the following fields:
        %> - @c 
        %------------------------------------------------------------------%
        function exportData = evaluateExportMethod(edfChannels,methodStruct,stagesStruct,fileInfoStruct)
            fullMethodName = CLASS_codec.getPackageMethodName(methodStruct.mfilename,'export');
            methodParameters = methodStruct.settings;
            exportData = feval(fullMethodName,edfChannels,methodParameters,stagesStruct,fileInfoStruct);
        end
        

        
        %------------------------------------------------------------------%
        %> @brief Creates a waitbar for batch processing.  
        %------------------------------------------------------------------%        
        %> @param Optional string to initialize waitbar message with. 
        %> @retval waitbarH Handle to the waitbar.
        %------------------------------------------------------------------%
        function waitbarH = createWaitbar(initializationString)
        
            if(nargin<1)
                initializationString ='';
            end
            %% prep the waitbarHandle and make it look nice
            waitbarH = waitbar(0,initializationString,'name','Batch Export','resize','on','createcancelbtn',@CLASS_batch.cancel_batch_Callback,'visible','off');
            
            waitbarMsgH = findall(waitbarH,'interpreter','tex');
            original_fontsize = mean(get(waitbarMsgH,'fontsize'));
            if(isnan(original_fontsize) || original_fontsize ==0)
                original_fontsize = 10;
            end
            
            new_fontsize = 14;
            
            set(waitbarMsgH,'interpreter','none','fontsize',new_fontsize);
            msgPos = get(waitbarMsgH,'position');
            msgPos(2) = msgPos(2)*new_fontsize/original_fontsize;
            set(waitbarMsgH,'position',msgPos);
            
            waitbarPos = get(waitbarH,'position');
            waitbarPos(4)=waitbarPos(4)*new_fontsize/original_fontsize;
            %         waitbarPos(3)=waitbarPos(3)*new_fontsize/original_fontsize;
            set(waitbarH,'position',waitbarPos);
            set(waitbarH,'visible','on');
        end
        
        %------------------------------------------------------------------%
        %> @brief Cancel callback for waitbar created with creatWaitbar method.
        %------------------------------------------------------------------%        
        %> @param hObject Handle to either the waitbar or it's cancel
        %> button.  If hObject is a handle to the waitbar then it is
        %> deleted as it being called from the waitbars closerequestfcn
        %> callback.  Otherwize, the waitbar's progress is set to 100%
        %> complete, the message changed to 'Cancelling!' and the user data
        %> for the waitbar is set to 'user_cancelled=true';
        %> @param unused (required by MATLAB callbacks)
        %------------------------------------------------------------------%
        function cancel_batch_Callback(hObject,~)
            % userdata = get(hObject,'userdata');
            user_cancelled = true;
            if(strcmpi(get(hObject,'type'),'figure'))
                delete(hObject);  % We are closing the figure out then
            else
                waitbarH = get(hObject,'parent');
                set(waitbarH,'userdata',user_cancelled);
                waitbar(1,waitbarH,'Cancelling!');
            end
        end
        
        
        
        %------------------------------------------------------------------%
        %> @brief Creates a dialog to show summary of batch process on close out.
        %------------------------------------------------------------------%
        %> @param Nx1 cell of filenames (strings)
        %> @param files_attempted Nx1 logical vector of files that were
        %> attempted in batch processing.
        %> @param files_completed Nx1 logical vector of files that 
        %> successfully completed batch processing.
        %> @param files_failed Nx1 logical vector of files that failed
        %> batch processing due to unknown errors.
        %> @param files_skipped Nx1 logical vector of files that were
        %> skipped in batch processing due to known errors.
        
        %> @retval dialogH Handle to the dialog figure created.  
        %> @param summaryText - text of summary output.
        %------------------------------------------------------------------%
        function [dialogH,summaryText] = showCloseOutMessage(filename_list,files_attempted,files_completed,files_failed,files_skipped,start_time)
            num_files_attempted = sum(files_attempted);
            num_files_completed = sum(files_completed);
            num_files_skipped = sum(files_skipped);
            num_files_failed = sum(files_failed);
            elapsed_time = datestr(now-start_time,'HH:MM:SS');
            
            summaryText = sprintf(['Batch process summary',...
                '\nFiles Attempted:\t%u',...
                '\nFiles Skipped:\t%u',...
                '\nFiles Failed:\t%u',...
                '\nFiles Completed:\t%u',...
                '\nTime elapsed:\t%s'],num_files_attempted,num_files_skipped,num_files_failed,num_files_completed,elapsed_time);

            
            if(num_files_attempted~=num_files_completed)
                skipped_filenames = filename_list(files_skipped|files_failed);
                [selections,clicked_ok]= listdlg('PromptString',summaryText,'Name','Batch Completed',...
                    'OKString','Copy to Clipboard','CancelString','Close','ListString',skipped_filenames);
                
                % send to clipboard as a one row vector
                if(clicked_ok)
                    %char(10) is newline
                    skipped_files = [char(skipped_filenames(selections)),repmat(char(10),numel(selections),1)];
                    skipped_files = skipped_files'; %filename length X number of files
                    
                    clipboard('copy',skipped_files(:)'); %make it a 1 row vector
                    disp([num2str(numel(selections)),' filenames copied to the clipboard.']);
                end;
            else
                dialogH = msgbox(summaryText,'Completed');
            end
            
            
        end
        
        
        
    end %End static methods
    
end  % End class definition

