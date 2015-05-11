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
        %> @playlist
        %> @retval edfPathStruct Struct with fields describing the .edf
        %> files found in the path specified (after filtering with playlist
        %> when provided and it exists).
        %> - @c edf_filename_list 
        %> - @c edf_fullfilename_list 
        %> - @c edf_megabyte_count
        %> - @c statusString
        %> - @c firstHDR
        % ======================================================================
        function edfPathStruct = checkPathForEDFs(edfPath,playlist)
            %looks in the path for EDFs

            edfPathStruct.edf_filename_list = [];
            edfPathStruct.edf_fullfilename_list = [];
            edfPathStruct.edf_megabyte_count = [];
            edfPathStruct.statusString = [];
            edfPathStruct.firstHDR = [];
            
            if(nargin<1 || isempty(edfPath))
                edfPath = pwd;
            end
            if(nargin<2)
                playlist = []; %CLASS_batch.getPlaylist(handles);                
            end
            if(~exist(edfPath,'file'))
                edfPathStruct.statusString = 'Directory does not exist. ';
                num_edfs = 0;
                num_edfs_all = 0;                
            else
                [edfPathStruct.edf_filename_list, edfPathStruct.edf_fullfilename_list] = getFilenamesi(edfPath,'edf');
                
                num_edfs_all = numel(edfPathStruct.edf_filename_list);
                
                if(~isempty(playlist))
                    [edfPathStruct.edf_filename_list, filtered_intersect_indices] = CLASS_batch.filterPlaylist(edfPathStruct.edf_filename_list,playlist);
                    edfPathStruct.edf_fullfilename_list = edfPathStruct.edf_fullfilename_list(filtered_intersect_indices);
                end
                num_edfs = numel(edfPathStruct.edf_filename_list);
                total_bytes = 0;
                for e=1:num_edfs
                    tmpF = dir(edfPathStruct.edf_fullfilename_list{e});
                    total_bytes = total_bytes+tmpF.bytes;
                end
                
                total_megabytes = total_bytes/1E6;
                if(~isempty(playlist))
                    edfPathStruct.statusString = [num2str(num_edfs),' EDF files (',num2str(total_megabytes,'%0.2f'),' MB) found in the current play list. '];
                else
                    edfPathStruct.statusString = [num2str(num_edfs),' EDF files (',num2str(total_megabytes,'%0.2f'),' MB) found in the current directory. '];
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
        function [playList, filenameOfPlayList] = getPlaylist(directoryOfPlayList, filenameOfPlayList)
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
        function [filtered_filename_list, filtered_intersect_indices] = filterPlaylist(filename_list,file_filter_list)            
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
        %> @retval Nx1 struct (one entry per non-header row parsed of .inf file)
        %> with the following fields
        %------------------------------------------------------------------%
        function exportMethodsStruct = getExportMethods(exportInfFullFilename)
            exportMethodsStruct = CLASS_code.parseExportInfFile(exportInfFullFilename);
        end
        
    end %End static methods
    
end  % End class definition

