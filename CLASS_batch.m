%> @file CLASS_batch.m
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
        %> @retval edfPathStruct
        %> [edf_filename_list, edf_fullfilename_list, edf_megabyte_count]
        % ======================================================================
        function edfPathStruct = checkPathForEDFs(edfPath,playlist)
            %looks in the path for EDFs
            global GUI_TEMPLATE;
            edfPathStruct.edf_filename_list = ;
            edfPathStruct.edf_fullfilename_list = ;
            edfPathStruct.edf_megabyte_count = ;
            edfPathStruct.messasgeString = ;
            
            if(nargin<2)
                playlist = getPlaylist(handles);
            end
            if(~exist(edfPath,'file'))
                EDF_message = 'Directory does not exist. ';
                num_edfs = 0;
                num_edfs_all = 0;
                
            else
                [edf_filename_list, edf_fullfilename_list] = getFilenamesi(edfPath,'edf');
                
                num_edfs_all = numel(edf_filename_list);
                
                if(~isempty(playlist))
                    edf_filename_list = CLASS_batch.filterPlaylist(edf_filename_list,playlist);
                end
                num_edfs = numel(edf_filename_list);
                total_bytes = 0;
                for e=1:num_edfs
                    tmpF = dir(edf_fullfilename_list{e});
                    total_bytes = total_bytes+tmpF.bytes;
                end
                
                total_megabytes = total_bytes/1E6;
                if(~isempty(playlist))
                    EDF_message = [num2str(num_edfs),' EDF files (',num2str(total_megabytes,'%0.2f'),' MB) found in the current play list. '];
                else
                    EDF_message = [num2str(num_edfs),' EDF files (',num2str(total_megabytes,'%0.2f'),' MB) found in the current directory. '];
                end
            end;
            
            
            if(num_edfs==0)
                
                if(num_edfs_all==0)
                    EDF_message = [EDF_message, 'Please choose a different directory'];
                    set(get(handles.bg_panel_playlist,'children'),'enable','off');
                    
                else
                    EDF_message = [EDF_message, 'Please select a different play list or use ''All'''];
                end
                
                set(handles.push_start,'enable','off');
                EDF_labels = 'No Channels Available';
                set(get(handles.panel_exportMethods,'children'),'enable','off');
                
                
            else
                set(get(handles.panel_synth_CHANNEL,'children'),'enable','on');
                set(handles.edit_synth_CHANNEL_name,'enable','off');
                set(handles.push_start,'enable','on');
                
                set(get(handles.panel_exportMethods,'children'),'enable','on');
                
                %     set(get(handles.panel_psd,'children'),'enable','on');
                set(handles.pop_spectral_method,'enable','on');
                set(handles.push_add_psd,'enable','on');
                set(get(handles.panel_artifact,'children'),'enable','on');
                set(get(handles.bg_panel_playlist,'children'),'enable','on');
                set(handles.edit_selectPlayList,'enable','inactive');
                
                first_edf_filename = edf_file_list(1).name;
                HDR = loadEDF(fullfile(edfPath,first_edf_filename));
                EDF_labels = HDR.label;
            end;
            
            GUI_TEMPLATE.EDF.labels = EDF_labels;
            
            set(handles.text_edfs_to_process,'string',EDF_message);
            
            
        end

        % from batch export
        function playlist = getPlaylist(handles,ply_filename)
            if(nargin==2)
                if(strcmpi(ply_filename,'-gui'))
                    
                    %make an educated guess regarding the file to be loaded
                    fileGuess = get(handles.edit_selectPlayList,'string');
                    if(~exist(fileGuess,'file'))
                        fileGuess = get(handles.edit_edf_directory,'string');
                    end
                    
                    [ply_filename, pathname, ~] = uigetfile({'*.ply','.EDF play list (*.ply)'},'Select batch mode play list',fileGuess,'MultiSelect','off');
                    
                    %did the user press cancel
                    if(isnumeric(ply_filename) && ~ply_filename)
                        ply_filename = [];
                    else
                        ply_filename = fullfile(pathname,ply_filename);
                    end
                end
            else
                
                if(strcmpi('on',get(handles.radio_processList,'enable')) && get(handles.radio_processList,'value'))
                    ply_filename = get(handles.edit_selectPlayList,'string');
                else
                    ply_filename = [];  %just in case this is called unwantedly
                end
            end
            
            if(exist(ply_filename,'file'))
                fid = fopen(ply_filename);
                data = textscan(fid,'%[^\r\n]');
                playlist = data{1};
                fclose(fid);
            else
                playlist = [];
            end
            
            %update the gui
            if(isempty(playlist))
                set(handles.radio_processAll,'value',1);
                set(handles.edit_selectPlayList,'string','<click to select play list>');
            else
                set(handles.radio_processList,'value',1);
                set(handles.edit_selectPlayList,'string',ply_filename);
            end
            
        end
        
        
        % from batch export
        function filtered_file_struct = filterPlaylist(file_struct,file_filter_list)
            
            if(~isempty(file_filter_list))
                filename_cell = cell(numel(file_struct),1);
                [filename_cell{:}] = file_struct.name;
                [~,~,intersect_indices] = intersect(file_filter_list,filename_cell);  %need to handle case sensitivity
                filtered_file_struct = file_struct(intersect_indices);
            else
                filtered_file_struct = file_struct;  %i.e. nothing to filter
            end
        end
            
    end %End static methods
    
end  % End class definition

