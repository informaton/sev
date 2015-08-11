%> @file CLASS_codec.m
%> @brief CLASS_codec encapuslates many of the coding and decoding 
%> functionality required by SEV's IO routines.  
% ======================================================================
%> @brief The methods here are all static.  
%> @note Author: Hyatt Moore IV
%> @note Created 9/29/2014 - Derived from CLASS_events_container static
%> methods.
% ======================================================================
classdef CLASS_codec < handle
    methods(Static)
        
        % ======================================================================
        %> @brief Loads staging data from hypnogram file, applies unknown
        %> staging label (Default = 7) as applicable, determines sleep
        %> cycle period, and extract first non wake epoch.
        % ======================================================================
        %> @param stages_filename is the filename of an ASCII tab-delimited file whose
        %> second column contains a vector of scored sleep stages for each epoch of
        %> a sleep study.
        %> @param num_epochs
        %> @param unknown_stage_label (Optional) Integer number to use for
        %> unclassified/unknown hypnogram stages.  Default is 7.
        %> @retval STAGES A struct with the following fields
        %> -@c line = the second column of stages_filename - the scored sleep stages
        %> -@c count = the number of stages for each one
        %> -@c cycle - the nrem/rem cycle
        %> -@c firstNonWake - index of first non-Wake(0) and non-unknown(7) staged epoch      
        %> @note Author: Hyatt Moore IV
        %> Written: 9.26.2012
        %> modified before 12.3.2012 to include scoreSleepCycles(.);
        %> modified 1/16/2013 - added .firstNonWake
        %> modified 2/2/2013 - added .standard_epoch_sec = 30
        %>                           .study_duration_in_seconds
        %> modified 5.1.2013 - added .filename = stages_filename;
        function STAGES = loadSTAGES(stages_filename,num_epochs,unknown_stage_label)
            
            if(nargin<3)
                default_unknown_stage = 7;
            else
                default_unknown_stage = unknown_stage_label;
            end
            
            if(~isempty(stages_filename))
                [~,~,ext] = fileparts(stages_filename);
            end
            %load stages information if the file exists and we know its
            %extension.
            if(exist(stages_filename,'file') && (strcmpi(ext,'.sta')||strcmpi(ext,'.evts')))
                
                if(strcmpi(ext,'.sta'))
                    stages = load(stages_filename,'-ASCII'); %for ASCII file type loading                    
                    
                    if(nargin>1 && ~isempty(num_epochs) && floor(num_epochs)>0)
                        if(num_epochs~=size(stages,1))
                            STAGES.epochs = stages(:,1);
                            STAGES.line = repmat(default_unknown_stage,max([num_epochs;size(stages,1);STAGES.epochs(:)]),1);
                            STAGES.line(STAGES.epochs) = stages(:,2);
                        else
                            %this cuts things off at the end, where we assume the
                            %disconnect between num_epochs expected and num epochs found
                            %has occurred. However, logically, there is no guarantee that
                            %the disconnect did not occur anywhere else (e.g. at the
                            %beginning, or sporadically throughout)
                            STAGES.line = stages(1:floor(num_epochs),2);
                        end
                    else
                        STAGES.line = stages(:,2); %grab the sleep stages
                    end
                elseif(strcmpi(ext,'.evts'))
                    [~,stageVec] = CLASS_codec.parseSSCevtsFile(stages_filename,default_unknown_stage);
                    STAGES.line = stageVec;
                    STAGES.epochs = 1:numel(STAGES.line);
                end                
            else                
                if(nargin<2)
                    mfile =  strcat(mfilename('fullpath'),'.m');
                    fprintf('failed on %s\n',mfile);
                else
                    STAGES.line = repmat(default_unknown_stage,num_epochs,1);
                end
            end;
            
            if(nargin<2)
                num_epochs = numel(STAGES.line);
            end
            %calculate number of epochs in each stage
            STAGES.count = zeros(8,1);
            for k = 0:numel(STAGES.count)-1
                STAGES.count(k+1) = sum(STAGES.line==k);
            end
            %this may be unnecessary when the user does not care about sleep cycles.
            % STAGES.cycles = scoreSleepCycles(STAGES.line);
            STAGES.cycles = scoreSleepCycles_ver_REMweight(STAGES.line);
            
            firstNonWake = 1;
            while( firstNonWake<=numel(STAGES.line) && (STAGES.line(firstNonWake)==7||STAGES.line(firstNonWake)==0))
                firstNonWake = firstNonWake+1;
            end
            STAGES.firstNonWake = firstNonWake;
            if(num_epochs~=numel(STAGES.line))
                fprintf(1,'%s contains %u stages, but shows it should have %u\n',stages_filename,numel(STAGES.line),num_epochs);
            end
            
            STAGES.filename = stages_filename;
            STAGES.standard_epoch_sec = 30;
            STAGES.study_duration_in_seconds = STAGES.standard_epoch_sec*numel(STAGES.line);
        end
        
        
        % ======================================================================
        %> @brief Retrieves SEV compatible hypnogram filename (with path)
        %> based on the input edf filename provided (With path).        
        % ======================================================================
        %> @param edf_fullfilename Filename of the EDF file to find matching hypnogram file for.
        %> @note The hypnogram file is expected to be in the same directory as edf_fullfilename
        %> and have a file extension of '.STA' or '.evts'
        %> @retval stages_filename Filename of the hypnogram with path.
        %> .STA is checked first, then .evts extension is checked if .STA is
        %> not found.  If neither staging file type is found (.STA or .EVTS)
        %> then stages_filename is returned as empty (i.e. [])
        %> @retval edf_name edf filename sans pathname.
        % ======================================================================
        function [stages_filename, edf_name] = getStagesFilenameFromEDF(edf_fullfilename)
            [edf_path,edf_name,edf_ext] = fileparts(edf_fullfilename);
            stages_filename = fullfile(edf_path,strcat(edf_name,'.STA'));
            
            if(~exist(stages_filename,'file'))
                stages_filename = fullfile(edf_path,strcat(edf_name,'.EVTS'));
                if(~exist(stages_filename,'file'))
                    stages_filename = [];
                end
            end  
            edf_name = strcat(edf_name,edf_ext);
        end
        
        % ======================================================================
        %> @brief Retrieves SEV compatible events filename (with path)
        %> based on the input edf filename provided (With path).        
        % ======================================================================
        %> @param edf_fullfilename Filename of the EDF file to find matching events file for.
        %> @note The events file is expected to be in the same directory as edf_fullfilename
        %> and have a file extension of '.SCO' or '.EVTS'
        %> @param events_filename Filename of the hypnogram with path.
        %> .STA is checked first, then .evts extension is checked if .STA is
        %> not found.  If neither staging file type is found (.STA or .EVTS)
        %> then stages_filename is returned as empty (i.e. [])
        %> @retval edf filename sans pathname.
        % ======================================================================
        function [events_filename, edf_name] = getEventsFilenameFromEDF(edf_fullfilename)
            [edf_path,edf_name,edf_ext] = fileparts(edf_fullfilename);
            events_filename = fullfile(edf_path,strcat(edf_name,'.SCO'));
            
            if(~exist(events_filename,'file'))
                events_filename = fullfile(edf_path,strcat(edf_name,'.EVTS'));
                if(~exist(events_filename,'file'))
                    events_filename = [];
                end
            end  
            edf_name = strcat(edf_name,edf_ext);
        end
                
        % =================================================================
        %> @brief Retrives a function call for files in directories with a '+'
        %> prefix.
        %------------------------------------------------------------------%
        %> @param Method's name (sans path and .m)
        %> @param Package name (string).  Supported values include
        %> - @c export
        %> - @c detection
        %> - @c filter
        %> @retval packageMethodName - Package.method name to call the method outside of its
        %> directory via its package.
        %> @retval fullFilename - Name of the .m file for the method with
        %> pathname.  Empty if no match is found.
        % =================================================================
        function [packageMethodName, fullFilename] = getPackageMethodName(methodName,packageName)
            candidateCategories = {'export','detection','filter'};
            rootPath = fileparts(mfilename('fullpath'));
            
            if(isempty(intersect(packageName, candidateCategories)))
                packageMethodName = [];
                fullFilename = [];
            else
                fullFilename = fullfile(rootPath,strcat('+',packageName),strcat(methodName,'.m'));
                if(exist(fullFilename,'file'))
                    packageMethodName = strcat(packageName,'.',methodName);
                else
                    packageMethodName = [];
                    fullFilename = [];
                end
            end
        end
        
       % =================================================================
        %> @brief Retrives the information file (.inf) for the package of interest.
        %> Information files describe methods used in a particular toolbox.
        %------------------------------------------------------------------%
        %> @param Package name (string).  Supported values include
        %> - @c export
        %> - @c detection
        %> - @c filter
        %> @retval methodInformationFile Full filename of the information
        %> file used to describe the toolbox associated with methodCategory.
        %> Information files describe methods used in a particular toolbox.
        %> Empty if no match is found.
        % =================================================================
        function methodInformationFilename = getMethodInformationFilename(packageName)
            candidateCategories = {'export','detection','filter'};
            rootPath = fileparts(mfilename('fullpath'));
            
            if(isempty(intersect(packageName, candidateCategories)))
                methodInformationFilename = [];
            else
                methodInformationFilename = fullfile(rootPath,strcat('+',packageName),strcat(packageName,'.inf'));
                if(~exist(methodInformationFilename,'file'))
                    methodInformationFilename = [];
                end
            end
        end
        
                
        
        
        % =================================================================
        %> @brief Retrives a function call for files in directories with a '+'
        %> prefix.
        %------------------------------------------------------------------%
        %> @param Method's name (sans path and .m)
        %> @param Package name that method is part of (string).  Supported values include
        %> - @c export
        %> - @c detection
        %> - @c filter        
        %> @retval packageMethodName - method name with package prefix (e.g. export.someMethod) to call the method in
        %> the package a directory outside of its category.
        %> Empty if no match is found.
        % =================================================================
        function [parameterStruct, packageMethodName] = getMethodParameters(methodName,packageName)
            candidateCategories = {'export','detection','filter'};
            rootPath = fileparts(mfilename('fullpath'));
            
            if(isempty(intersect(packageName, candidateCategories)))
                packageMethodName = [];
                parameterStruct = [];
            else
                fullFilename = fullfile(rootPath,strcat('+',packageName),strcat(methodName,'.m'));
                if(exist(fullFilename,'file'))
                    packageMethodName = strcat(packageName,'.',methodName);
                    try
                        parameterStruct = feval(packageMethodName);
                    catch me
                        showME(me);
                        fprintf('An error occurred and was caught.  The variable parameterStruct will be set to []\n');
                        parameterStruct = [];
                    end
                else
                    packageMethodName = [];
                    parameterStruct = [];
                end
            end
        end        
        
        %------------------------------------------------------------------%
        %> @brief Parses an export package information file (.inf) and returns 
        %> each rows values as a struct entry.
        %------------------------------------------------------------------%        
        %> @param Full filename (path and name) of the export information
        %> file to parse.
        %> @retval Struct with the following fields:
        %> - @c mfilename Nx1 cell of filenames of the export method
        %> - @c description Nx1 cell of descriptions for each export method.
        %> - @c settingsEditor Nx1 cell of the settings editor to use for each method.     
        %> @note One entry per non-header row parsed of .inf file
        %------------------------------------------------------------------%
        function exportMethodsStruct = parseExportInfFile(exportInfFullFilename)
            exportMethodsStruct = [];
        
            if(exist(exportInfFullFilename,'file'))
                fid = fopen(exportInfFullFilename,'r');
                scanCell = textscan(fid,'%s %s %s','headerlines',1,'delimiter',',');
                fclose(fid);
                exportMethodsStruct.mfilename = scanCell{1};
                exportMethodsStruct.description = scanCell{2};
                exportMethodsStruct.settingsEditor = scanCell{3};
            end;
            
        end

        % ======================================================================
                %> @brief loads/parses the .SCO file associated with an EDF.        
        % ======================================================================
        %> @param filename Full .SCO filename (i.e. with path) to load.
        %> @param dest_samplerate Sample rate to use for SCO fields (return value)
        %> @param sco_samplerate The SCO file's internal samplerate used internal =
        %> this the sample rate used when generating the SCO file initially.
        %> Typically the samplerate is twice the highest sampling rate used for the .EDF
        %> channels as shown in the .EDF header.
        %> @retval SCO is a struct with the fields
        %> @li .epoch - the epoch that the scored event occured in
        %> @li .start_stop_matrix - the sample point that the events begin and end on
        %> @li .label - the string label used to describe the event
        %> @li .duration_seconds = the duration of the event in seconds (default is 1
        %> second)
        %> @li .start_time - events start time as a string in hour:minute:second format
        %> @param
        %> @note [ul,ui,uj] = unique(SCO.label); lm_epochs = SCO.epoch(3==uj,:); lm_evts = SCO.start_stop_matrix(3==uj,:);
        %> @note obtains the unique epochs for the third unique event
        %> @note History 
        %> Author: Hyatt Moore IV (< June, 2013)
        %>
        %> @note modified: 4/30/2014
        %>  1.  Added additional input arguments, dest_samplerate and sco_samplerate
        %>  to help with conversion.  Defaults are dest_samplerate = 100 and
        %>  sco_samplerate = 200
        %>  2.  Previously the duration_sec column was only divided by 100Hz and not
        %>  200Hz, so durations could be 2x's as long if the sampling rate was not
        %>  100 Hz.    
        %> @note modified 12/15/12
        %>  3. last argument to textscan has changed to a regular expression since new
        %>  files had extra columns at the end which are causing problems with the
        %>  imports.
        %> @note modified: 2/6/12 -
        %>  1.  Some .sco files had empty lines at the top, and we need to cruise
        %>  through these until something hits - so I do a getl until the scan
        %>  works, otherwise it will crash
        %>  2.  Some sco files do not convert correctly due to the sample rate being
        %>  done at 128.  The EDF is okay, but the SCO file needs to be converted
        %>  correctly as well.  The mode sample rate from the EDF hdr is used for
        %>  converting
        function SCO = parseSCOfile(filename,dest_samplerate, sco_samplerate)
            %> filename = '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11/A0210_3 170424.SCO';
            %> filename = '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11/A0097_4 174733.SCO';

            
            % Note:  EDF_filename = [filename(1:end-3),'EDF'];
            
            %     if(exist(EDF_filename,'file'))
            %         HDR = loadHDR(EDF_filename);
            %         samplerate = max(HDR.samplerate);
            %         conversion_factor=100/samplerate;
            %     else
            %         samplerate = 100;
            %         conversion_factor = 1;
            %     end
            %
            %
            %

            
            if(nargin<3 || isempty(sco_samplerate)|| sco_samplerate<0)
                sco_samplerate= 200;
            end
            
            if(nargin<2 || isempty(dest_samplerate)|| dest_samplerate<0)
                dest_samplerate= 100;
            end
            
            if(exist(filename,'file'))
                fid = fopen(filename,'r');
                %     x = textscan(fid,'%f %f %f %f %s %f %s %f %*f','delimiter','\t');
                %     x = textscan(fid,'%f %f %f %f %s %f %s %f %*[.]','delimiter','\t');
                x = textscan(fid,'%f %f %f %f %s %f %s %f %*[^\n]','delimiter','\t');
                if(isempty(x{1}))
                    file_size_bytes = fseek(fid,0,'eof');
                    if(file_size_bytes==0)
                        disp(['File size of ',filename,' is 0.  Going to crash now.']);
                    end
                    while(isempty(x{1}) && ftell(fid)<file_size_bytes)
                        fgetl(fid);
                        x = textscan(fid,'%f %f %f %f %s %f %s %f %*f','delimiter','\t');
                        disp(filename);
                    end
                end
                %remove potential problem of empty first line
                try
                    if(isnan(x{1}(1)))
                        for k=1:numel(x)
                            x{k} = x{k}(2:end);
                        end
                    end
                catch me
                    disp(me);
                end
                SCO.epoch = x{1};
                
                %handle the negative case, which pops up for the more recent sco files
                %which were not converted correctly the first time...
                % - adjusted on 4/30/2014 reference M.Stubbs email sent August 5, 2011
                neg = x{2}<0;
                
                if(any(neg))
                    x{2}(neg) = abs(floor(x{2}(neg)/100));
                    x{3}(neg) = abs(floor(x{3}(neg)/100));
                end
                
                x{3}(x{3}==0)=300; %make the default be 1.5 second duration.
                x{3}(isnan(x{3}))=300; %make the default be 1.5 second duration - typical case for Leg Movement to not have a value listed...
                
                %     EDF_filename = [filename(1:end-3),'EDF'];
                
                %     if(exist(EDF_filename,'file'))
                %         HDR = loadHDR(EDF_filename);
                %         samplerate = max(HDR.samplerate);
                %         conversion_factor=100/samplerate;
                %     else
                %         samplerate = 100;
                %         conversion_factor = 1;
                %     end
                
                conversion_factor = dest_samplerate/sco_samplerate;
                SCO.start_stop_matrix = floor([x{2},x{2}+x{3}]*conversion_factor); %remove any problems with the 0.5 indexing that can occur here
                
                SCO.duration_seconds = x{3}/sco_samplerate;
                SCO.start_time = x{7};
                SCO.label = deblank(x{5});
                fclose(fid);
            else
                SCO = [];
                disp('filename does not exist');
            end
            
            
        end
        
        %> @brief Export the current hypnogram to a .STA text file.
        %> @note Hypnograms are scored at the default interval set in the
        %> SEV parameters (e.g. 30 seconds)
        %> @param hypnogramVec A vector of consecutively scored sleep
        %> stages with numeric values interpreted as
        %> - c 0    Wake
        %> - c 1    Stage 1
        %> - c 2    Stage 2
        %> - c 3    Stage 3
        %> - c 4    Stage 4
        %> - c 5    REM sleep
        %> - c 7    Uknown                
        %> @param staFilename Optional filename to save hypnogram to.  If
        %> not included, the user is prompted for a filename.
        %> @note The .STA file format is two column, tab-delimited, ascii
        %> with the first column being a consecutive list of epochs and the
        %> second column containing the sleep scores that correspond to
        %> the first column epochs.        
        function saveHypnogram2STA(hypnogramVec, staFilename)
            epoch = (1:numel(hypnogramVec))';
            hypnogramVec = hypnogramVec(:);
            y = [epoch,hypnogramVec];
            
            if(nargin<2 ||isempty(staFilename))
                staFilename = [];
            end
            
            %double check that we have .STA extension
            save(staFilename,'y','-ascii');
            
        end
        
        % =================================================================
        %> @brief Returns the patid and study number related to the
        %> patstudy key provided.  This requires patstudy input string to
        %> follow a particular template (see source code).
        %> @param patstudy is the filename of the .edf, less the extention
        %> @retval PatID
        %> @retval StudyNum
        % =================================================================        
        function [PatID,StudyNum] = getDB_PatientIdentifiers(patstudy)
            %patstudy is the filename of the .edf, less the extention
            %             if(numel(patstudy)>=7)
            %                 pat = '(\w{5})_(\d+)'; %WSC format
            %             else
            %                 pat = '([A-Z]+)(\d+)';  %PTSD format
            %             end
            %                 pat = '(SSC_\d[4]'; %SSC format
            %             x=regexp(patstudy,pat,'tokens');
            
            patstudy = strrep(patstudy,'SSC_','');
            x=regexp(patstudy,'(\w+)_(\d+)||(\d+)_(\d+)||([^\d]+)(\d+)','tokens');
            x = x{1};
            PatID = x{1};
            StudyNum = x{2};
        end
        
        % =================================================================
        %> @brief Parse events from an Embla formatted events file (.evt/.nvt)
        %> The function parses Embla files 
        %> @li stage
        %> @li plm
        %> @li desat
        %> @li biocals
        %> @li user
        %> @li numeric
        %> @li baddata
        %> @param evtFilename Filename (string) of the Embla formatted event file
        %> @param embla_samplerate Sampling rate of the Embla event file.
        %> @param desired_samplerate (optional) sample rate to convert
        %> Embla events to.  This is helpful when displaying a samplerate
        %> different than recorded in the .evt file.  If desired_samplerate
        %> is not provided, then embla_samplerate is used.
        %> filename in .SCO format        
        % =================================================================
        function [embla_evt_Struct,embla_samplerate_out] = parseEmblaEvent(evtFilename,embla_samplerate,desired_samplerate)
            %embla_samplerate_out may change if there is a difference found in
            %the stage .evt file processing as determined by adjusting for
            %a 30 second epoch.
            
            seconds_per_epoch = 30;
            embla_samplerate_out = embla_samplerate;
            
            if(~exist(evtFilename,'file'))
                embla_evt_Struct = [];
                disp([nvt_filename,' not handled']);
            else
                
                if(nargin < 3 || isempty(desired_samplerate))
                    desired_samplerate = 0;
                end
                [~,name,~] = fileparts(evtFilename);
                
                fid = fopen(evtFilename,'r');
                HDR = CLASS_codec.parseEmblaHDR(fid);
                
                start_sec = [];
                stop_sec = [];
                dur_sec = [];
                epoch = [];
                stage = [];
                start_stop_matrix = [];
                description = [];
                
                eventType = name;
                
                if(HDR.num_records>0 && strncmpi(deblank(HDR.label),'event',5))
                    fseek(fid,0,'eof');
                    file_size = ftell(fid);
                    fseek(fid,32,'bof');
                    bytes_remaining = file_size-ftell(fid);
                    bytes_per_record = bytes_remaining/HDR.num_records;
                    start_sample = zeros(HDR.num_records,1);
                    stop_sample = start_sample;
                    
                    %sometimes these have the extension .nvt
                    if(strcmpi(eventType,'plm'))
                        intro_size = 8;
                        remainder = zeros(HDR.num_records,bytes_per_record-intro_size,'uint8');
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            stop_sample(r) = fread(fid,1,'uint32');
                            remainder(r,:) = fread(fid,bytes_per_record-intro_size,'uint8');
                        end
                    elseif(strcmpi(eventType,'desat'))
                        intro_size = 8;
                        remainder_size = bytes_per_record-intro_size;
                        remainder = zeros(HDR.num_records,remainder_size,'uint8');                        
                        
                        for r=1:HDR.num_records
                            
                            start_sample(r) = fread(fid,1,'uint32');
                            stop_sample(r) = fread(fid,1,'uint32');
                            %                             description = fread(fid,remainder_size/2,'uint16=>char')';
                            %desats - (come in pairs?)
                            % [8 1 2 0] [0/4 0 ? ?]  [255 255 255 255] [255 255 255 255] [84 16 13 164]
                            
                            % [? ? 88/86/87 64] [? ? ? ?] [? ? 86/87/85 64] [8/10 ? ? ?] [? ? ? ?]
                            %
                            %1 byte [224] = ?
                            %4 bytes 224  106   99  104] [186  131   88   64]  [87   27   67  211]  [29 108   87   64]   [9  144   98    0  228  151    98  0]
                            %4 bytes
                            remainder(r,:) = fread(fid,remainder_size,'uint8');
                        end
                    elseif(strcmpi(eventType,'resp'))
                        %80 byte blocks
                        
                        intro_size = 8;
                        remainder = zeros(HDR.num_records,bytes_per_record-intro_size,'uint8');                        
                        
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            stop_sample(r) = fread(fid,1,'uint32');
                            remainder(r,:) = fread(fid,bytes_per_record-intro_size,'uint8');
                        end
                        
                    elseif(strcmpi(eventType,'stage'))
                        %   stage_mat = fread(fid,[12,HDR.num_records],'uint8');
                        %   x=reshape(stage_mat,12,[])';
                        %  stage records are produced in 12 byte sections
                        %    1:4 [uint32] - elapsed_seconds*2^8 (sample_rate)
                        %    5:8 [uint32] - (stage*2^8)+1*2^0
                        %    9:10 [uint16] = ['9','2']  %34...
                        %    10:12 = ?
                        % Should be 12 bytes per record
                        %  1 = Wake
                        %  2 = Stage 1
                        %  3 = Stage 2
                        %  4 = Stage 3
                        %  5 = Stage 4
                        %  7 = REM
                        intro_size = 6;
                        stage = zeros(-1,HDR.num_records,1);
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            fseek(fid,1,'cof');
                            stage(r) = fread(fid,1,'uint8');
                            fseek(fid,bytes_per_record-intro_size,'cof');
                        end
                        stage = stage-1;
                        stage(stage==6)=5;
                        stage(stage==-1)=7;
                        samples_per_epoch = median(diff(start_sample));
                        embla_samplerate = samples_per_epoch/seconds_per_epoch;
                        embla_samplerate_out = embla_samplerate;
                        stop_sample = start_sample+samples_per_epoch;
                        description = cell(HDR.num_records,1);
                        
                        description(stage==0) = {'Wake'};
                        description(stage==1) = {'Stage 1'};
                        description(stage==2) = {'Stage 2'};
                        description(stage==3) = {'Stage 3'};
                        description(stage==4) = {'Stage 4'};
                        description(stage==5) = {'REM'};
                        description(stage==7) = {'Unknown'};
                        
                        
                                                %   stage_mat = fread(fid,[12,HDR.num_records],'uint8');
                        %   x=reshape(stage_mat,12,[])';
                        %  stage records are produced in 12 byte sections
                        %    1:4 [uint32] - elapsed_seconds*2^8 (sample_rate)
                        %    5:8 [uint32] - (stage*2^8)+1*2^0
                        %    9:10 [uint16] = ['9','2']  %34...
                        %    10:12 = ?
                        % Should be 12 bytes per record
                        %  1 = Wake
                        %  2 = Stage 1
                        %  3 = Stage 2
                        %  4 = Stage 3
                        %  5 = Stage 4
                        %  7 = REM
                        % stage_mat = fread(fid,[bytes_per_record/4,HDR.num_records],'uint32')';
                        % start_sample = stage_mat(:,1);
                        % stage = (stage_mat(:,2)-1)/256;  %bitshifting will also work readily;
                        
                    elseif(strcmpi(eventType,'biocals'))
                        % first line:
                        % [1][2] [3-4]...[23-24] [25-28]   [29-32]   || [33-36]                 [37-40]                     [41-42]
                        % [1  0] [uint16=>char]  uint32    uint32    || uint32
                        %        Title Text      checksum  # entries || elapsed sample start    [13 1 0 0]  - biocals
                        %                                                                       [1 stage# 0 0] - stage...   [34 0]
                        %
                        % Elapsed Time Format:
                        % byte ref =[0  1 2  3  4  5]
                        % example = [34 0 0 164 31 0]
                        %
                        % example[5]*256*256*0.5+example[4]*256*0.5+example[3]*0.5+example[2]*0.5*1/256...
                        % example(4)*2^15+example(3)*2^7+example(2)*2^-1+example(1)*2^-9
                        description = cell(HDR.num_records,1); %24 bytes  --> varies in size; some descriptions are longer, some are shorter
                        remainder = cell(HDR.num_records,1); % --> varies in size because description is not always the same length.
                        tag = zeros(1,6); %6 bytes                        
                        intro_size = 10; % 6 + 4
                        bytes_per_uint16 = 2;
%                         intro_size = 34;
%                         remainder = zeros(HDR.num_records,bytes_per_record-intro_size,'uint8');
                        
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');  % 4 bytes
                            tag = fread(fid,6,'uint8')'; %[13 1 0 0 0 0]  % 6 bytes
                            
                            curRecord = fread(fid,(bytes_per_record-intro_size)/bytes_per_uint16,'uint16')';
                            descriptionStop = find(curRecord==0,1,'first');
                            description{r} = char(curRecord(1:descriptionStop-1));
                            remainder{r}=curRecord(descriptionStop:end);
                            
                            
                            
                            %                             description{r} = fread(fid,12,'uint16=>char')';  %24 bytes %need to read until I get to a 34 essentially%now at 64 or %32 bytes read
                            %                             remainder(r,:) = fread(fid,bytes_per_record-intro_size,'uint8')';
                        end
                        stop_sample = start_sample;
                        
                    elseif(strcmpi(eventType,'numeric'))
                        disp('numeric');
                    elseif(strcmpi(eventType,'tag'))
                        intro_size = 4;
                        remainder = zeros(HDR.num_records,bytes_per_record-intro_size,'uint8');
                        
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            remainder(r,:) = fread(fid,bytes_per_record-intro_size,'uint8');
                        end
                        stop_sample = start_sample;
                        
                    elseif(strcmpi(eventType,'user'))
                        fseek(fid,32,'bof');
                        tag = zeros(1,6);
                        remainder = cell(HDR.num_records,1);
                        description = cell(HDR.num_records,1);
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            tag = fread(fid,6,'uint8');
                            %read until double 00 are encountered
                            cur_loc = ftell(fid);
                            curValue = 1;
                            while(~feof(fid) && curValue~=0)
                                curValue = fread(fid,1,'uint16');
                            end
                            description_size = ftell(fid)-cur_loc;
                            intro_size = 4+6+description_size;
                            fseek(fid,-description_size,'cof'); %or fseek(fid,cur_loc,'bof');
                            description{r} = fread(fid,description_size/2,'uint16=>char')';
                            remainder{r} = fread(fid,bytes_per_record-intro_size,'uint8=>char')';
                            %remainder is divided into sections  with
                            %tokens of  [0    17     0   153     0     3
                            %1     9     0 ]
                        end
                        
                    elseif(strcmpi(eventType,'snapshot'))
                        
                    elseif(strcmpi(eventType,'baddata'))
                        
                        start_sample = zeros(HDR.num_records,1);
                        stop_sample = start_sample;
                        intro_size = 8;
                        remainder = zeros(HDR.num_records,bytes_per_record-intro_size,'uint8');
                        
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            stop_sample(r) = fread(fid,1,'uint32');
                            remainder(r,:) = fread(fid,bytes_per_record-intro_size,'uint8');
                        end
                    end
                                        
                    start_stop_matrix = [start_sample(:)+1,stop_sample(:)+1]; %add 1 because MATLAB is one based
                    dur_sec = (start_stop_matrix(:,2)-start_stop_matrix(:,1))/embla_samplerate;
                    epoch = ceil(start_stop_matrix(:,1)/embla_samplerate/seconds_per_epoch);
                    
                    if(desired_samplerate>0)
                        start_stop_matrix = ceil(start_stop_matrix*(desired_samplerate/embla_samplerate));
                    end
                    
                end
                
                embla_evt_Struct.HDR = HDR;
                embla_evt_Struct.type = eventType;
                embla_evt_Struct.start_stop_matrix = start_stop_matrix;
                embla_evt_Struct.start_sec = start_sec;
                embla_evt_Struct.stop_sec = stop_sec;
                embla_evt_Struct.dur_sec = dur_sec;
                embla_evt_Struct.epoch = epoch;
                embla_evt_Struct.stage = stage;
                
                if(~isempty(description))
                    embla_evt_Struct.description = description;
                end

                fclose(fid);
            end
        end

        % =================================================================
        %> @brief Parse header an Embla formatted events file (.evt/.nvt)
        %> @param fid File identifier of opened Embla file stream (see
        %> fopen)
        %> @retval HDR Struct containing Embla event header
        %> @li label String label of the event file.
        %> @li checksum A chuck sum of the file stream.
        %> @li num_records Number of records stored in the file stream.
        % =================================================================
        function HDR=parseEmblaHDR(fid)
            %HDR is struct with the event file header information
            fseek(fid,2,'bof'); %2
            HDR.label = fread(fid,11,'uint16=>char')'; %24
            HDR.checksum = fread(fid,1,'int32'); %28
            HDR.num_records = fread(fid,1,'int32'); %32 bytes read
        end
        
        
        
        % =================================================================
        %> @brief This function takes an event file of Stanford Sleep Cohort's .evts
        %> format and returns a SEV event struct and a SEV hynpgram.
        %> @param filenameIn Full filename (i.e. with path) of the Stanford Sleep Cohort .evts 
        %> formatted file to parse for events and sleep staging.
        %> @param unknown_stage_label (Optional) Integer number to use for
        %> unclassified/unknown hypnogram stages.  Default is 7.
        %> @retval SCOStruct A SCO struct containing the following fields
        %> as parsed from filenameIn.
        %> - @c startStopSamples
        %> - @c durationSeconds Duration of the event in seconds
        %> - @c startStopTimeStr Start time of the event as a string with
        %> format HH:MM:SS.FFF
        %> - @c category The category of the event (e.g. 'resp')
        %> - @c description A description giving further information
        %> on the event (e.g. Obs Hypopnea)
        %> - @c samplerate The sampling rate used in the evts file (e.g.
        %> 512)
        %> @retval stageVec A hynpogram of scored sleep stages as parsed from filenameIn.       
        %> @note SSC .evts files give time and samples as elapsed values
        %> starting from 0 (for samples) and 00:00:00.000 (for time stamps)
        % =================================================================
        function [SCOStruct, stageVec] = parseSSCevtsFile(filenameIn,unknown_stage_label)
            if(nargin<2)
                default_unknown_stage = 7;
            else
                default_unknown_stage = unknown_stage_label;
            end 
            
            if(exist(filenameIn,'file'))
                fid = fopen(filenameIn,'r');
                %%---/ Contents of an .evts file (first 3 lines): %-----------------------/
                %#scoreDir=SCORED SS
                %Start Sample,End Sample,Start Time (elapsed),End Time (elapsed),Event,File Name
                %0,58240,00:00:00.000,00:01:53.750,"Bad Data (SaO2)",BadData.evt
                %----------------------------------------------/
                scanCell = textscan(fid,'%f %f %s %s %s %s','delimiter',',','commentstyle','#','headerlines',2);
                fclose(fid);
                
                if(isempty(scanCell{1}))
                    fprintf('Warning!  The file ''%s'' could not be parsed!\nAn empty struct will be returned.',filenameIn);
                    SCOStruct = [];
                    stageVec = [];
                else 
                    
                    % parse the stages first
                    stageInd = strcmp(scanCell{6},'stage.evt');
                    stageStartStopSamples = [scanCell{1}(stageInd),scanCell{2}(stageInd)];
                    stageStartStopDatenums =  [datenum(scanCell{3}(stageInd),'HH:MM:SS.FFF'),datenum(scanCell{4}(stageInd),'HH:MM:SS.FFF')];
                    epochDurSec = datevec(diff(stageStartStopDatenums(1,:)))*[0;0;24*60;60;1;1/60]*60;
                    epochDurSamples = diff(stageStartStopSamples(1,:));
                    SCOStruct.samplerate = epochDurSamples/epochDurSec;
                    lastStageSample  = stageStartStopSamples(end);
                    numEpochs = lastStageSample/epochDurSamples;  %or stageStartStopSamples(end,1)/epochDurSamples+1;
                    stageStr = strrep(strrep(strrep(strrep(scanCell{5}(stageInd),'"',''),'Stage ',''),'REM','5'),'Wake','0');
                    %fill in any missing stages with 7.
                    missingStageValue = default_unknown_stage;
                    stageVec = repmat(missingStageValue,numEpochs,1);
                    stageStartEpochs = stageStartStopSamples(:,1)/epochDurSamples+1;  %evts file's start samples begin at 0; 0-based nubmer, but MATLAB indexing starts at 1.
                    stageVec(stageStartEpochs) = str2double(stageStr);  % or, equivalently, str2num(cell2mat(stageStr));
                    %                 y = [eventStruct.epoch,eventStruct.stage];
                    %                 staFilename = fullfile(outPath,strcat(studyID,'STA'));
                    %                 save(staFilename,'y','-ascii');
                    
                    
                    % Okay, now that we have taken care of the staging, let's
                    % remove it and everything else that is not going to be
                    % shown as a scored event.
                    eventNames = strrep(strrep(scanCell{end},'.evt',''),'.nvt','');
                    
                    removeFields = {'BadData';'user';'filesect';'stage'};
                    
                    removeInd = ismember(eventNames,removeFields);
                    for s=1:numel(scanCell)-1
                        scanCell{s}(removeInd) = [];
                    end
                    eventNames(removeInd) = [];
                    SCOStruct.category = eventNames;
                    SCOStruct.description = strrep(scanCell{5},'"','');
                    
                    SCOStruct.startStopSamples = [scanCell{1},scanCell{2}]+1;
                    
                    % MATLAB starts indices at 1, while the rest of the
                    % programming world starts at 0.
                    SCOStruct.startStopDatenums =  [datenum(scanCell{3},'HH:MM:SS.FFF'),datenum(scanCell{4},'HH:MM:SS.FFF')];
                    SCOStruct.durationSeconds = datevec(diff(SCOStruct.startStopDatenums,1,2))*[0;0;24*60;60;1;1/60]*60;
                    
                end
            else
                fprintf('Warning!  The file ''%s'' does not exist and was not parsed!\nAn empty struct will be returned.',filenameIn);
                SCOStruct = [];
                stageVec = [];
            end
        end
        
        % =================================================================
        %> @brief This function takes an event file of SEV's evt.* format and
        %> returns a struct whose field names are taken from the third header
        %> line, and the values come from the corresponding columns.
        %> @param filenameIn Full filename (i.e. with path) of the SEV
        %> formatted evt file to parse for events.
        %> @retval evtStruct A SEV event struct containing values parsed
        %> from filenameIn.
        % =================================================================
        function evtStruct = parseSEVevtFile(filenameIn)
        %This function takes an event file of SEV's evt.* format and
        %returns a struct whose field names are taken from the third header
        %line, and the values come from the corresponding columns.
        %Additional fields include channel_label and event_label
            %3 header lines and then
            % Start_time	Duration_sec	Epoch	Stage
            % Start_time is (hh:mm:ss)
            % evtStruct has the following fields
            %   Duration_sec
            %   Start_sample
            %   Stop_sample
            %   Epoch
            %   Stage
            %   {parameters...}
            
            % Example Header lines from evt file
            % Event Label =	LM_ferri
            % EDF Channel Label(number) = 	LAT/RAT (7)
            % Start_time	Duration_sec Start_sample Stop_sample	Epoch	Stage	duration_sec	AUC	stage
            
            fid = fopen(filenameIn);
            eventLabelLine = fgetl(fid);
            s = regexp(eventLabelLine,'[^=]+=\s(?<event_label>\w+)\s*','names');
            try
                evtStruct.event_label = s.event_label;
            catch ME
                showME(ME);
            end
            channelLabelLine = fgetl(fid);
            
            %example header line:
            % channelLabelLine2 = 'EDF Channel Label(number) = LOC-M2 (1  2)'
            % channelLabelLine21 = 'EDF Channel Label(number) = LOC-M2 (1  2)'
            % channelLabelLine1 = 'EDF Channel Label(number) = LOC-M2 (1  2)'
            s = regexp(channelLabelLine,'[^=]+=\s+(?<channel_label>[^\s\(]+)\s*\((?<channel_number>(\d+\s*)+))','names');
            try
                evtStruct.channel_label = s.channel_label;
            catch ME
                showME(ME);
            end
            
            headerFields=textscan(fgetl(fid),'%s');
            headerFields = headerFields{1}(2:end); %skip the start time field for now...
            numFields = numel(headerFields);
                        
            defaultFieldCount = 5; %continue to skip the start_time field
            
            %skip the start_time field
            scanStr = ['%*f:%*f:%*f %f %n %n %n %n',repmat('%f',1,numFields-defaultFieldCount)];
            scanCell = textscan(fid,scanStr);
            
            for k=1:numFields %skip the start time...
                evtStruct.(headerFields{k}) = scanCell{k};
            end;
            
            fclose(fid);
        end
        

        %> @brief searches through the roc_struct to find the best possible configurations in terms of sensitivity and specificity and K_0_0, and K_1_0
        %> the roc_struct fields are ordered first by study name and then
        %> by configuration
        %> @param
        %> @retval Struct with same fields as input roc_struct and also
        %> additional field @c optimum which is a struct contaning the
        %> following fields:
        %> - @c K_0_0
        %> - @c K_1_0
        %> - @c FPR
        %> - @c TPR
        %> - @c mean.K_0_0
        %> - @c mean.K_1_0
        %> - @c mean.FPR
        %> - @c mean.TPR
        %> - @c mean.K_0_0_configID  Index of maximum mean.K_0_0 value.
        %> - @c mean.K_1_0_configID  Index of maximum mean.K_1_0 value.
        %> - @c mean.FPR_configID  Index of minimum mean FPR value.
        %> - @c mean.TPR_configID  Index of maximum mean TPR value.
        function roc_struct = findOptimalConfigurations(roc_struct)
           %searches through the roc_struct to find the best possible configurations in terms of sensitivity and specificity and K_0_0, and K_1_0
           %the roc_struct fields are ordered first by study name and then
           %by configuration
           num_studies = numel(roc_struct.study_names);
           num_configurations = numel(roc_struct.study)/num_studies;
           
           k_0_0 = reshape(roc_struct.K_0_0,num_configurations,num_studies);
           k_1_0 = reshape(roc_struct.K_1_0,num_configurations,num_studies);
           fpr = reshape(roc_struct.FPR,num_configurations,num_studies);
           tpr = reshape(roc_struct.TPR,num_configurations,num_studies);
           mean_k_0_0 = mean(k_0_0,2);  %a vector of size num_configurations
           mean_k_1_0 = mean(k_1_0,2);
           mean_fpr = mean(fpr,2);
           mean_tpr = mean(tpr,2);
           
           optimum.K_0_0 = max(k_0_0);
           optimum.K_1_0 = max(k_1_0);
           optimum.FPR = min(fpr);
           optimum.TPR = max(tpr);

           optimum.mean.K_0_0 = max(mean_k_0_0);
           optimum.mean.K_1_0 = max(mean_k_1_0);
           optimum.mean.FPR = min(mean_fpr);
           optimum.mean.TPR = max(mean_tpr);

           optimum.mean.K_0_0_configID = find(optimum.mean.K_0_0==mean_k_0_0);
           optimum.mean.K_1_0_configID = find(optimum.mean.K_1_0==mean_k_1_0);
           optimum.mean.FPR_configID = find(optimum.mean.FPR==mean_fpr);
           optimum.mean.TPR_configID = find(optimum.mean.TPR==mean_tpr);
           
           roc_struct.optimum = optimum;
                     
        end
        
        %> @brief Loads older ROC data file format output as generated by
        %> SEV's batch job.
        %> @param filename Name of the ROC output file produced by SEV's batch mode.  
        %> It has the following naming convention @c roc_truthAlgorithm_VS_estimateAlgorithm.txt
        %> where Algorithm is the algorithm name that produced the .txt output file from batch
        %> mode.
        %> @retval roc_struct Struct with the following fields
        %> loads the roc data as generated by the batch job
        %> - @c roc_struct.config - unique id for each parameter combination
        %> - @c roc_struct.truth_algorithm = algorithm name for gold standard
        %> - @c roc_struct.estimate_algorithm = algorithm name for the estimate
        %> - @c roc_struct.study - edf filename
        %> - @c roc_struct.Q    - confusion matrix (2x2)
        %> - @c roc_struct.FPR    - false positive rate (1-specificity)
        %> - @c roc_struct.TPR   - true positive rate (sensitivity)
        %> - @c roc_struct.ACC    - accuracy
        %> - @c roc_struct.values   - parameter values
        %> - @c roc_struct.key_names - key names for the associated values
        %> - @c roc_struct.study_names - unique study names for this container
        %> - @c roc_struct.K_0_0 - weighted Kappa value for QROC
        %> - @c roc_struct.K_1_0 - weighted Kappa value for QROC
        function roc_struct = loadROCdata(filename)

           pat = '.*ROC_(?<truth_algorithm>.+)_VS_(?<estimate_algorithm>.+)\.txt';
           t = regexpi(filename,pat,'names');
           if(isempty(t))
               roc_struct.truth_algorithm = 'unknown truth_algorithm';
               roc_struct.estimate_algorithm = 'unknown estimate_algorithm';
           else
               roc_struct.truth_algorithm = t.truth_algorithm;
               roc_struct.estimate_algorithm = t.estimate_algorithm;
               
           end
           
           fid = fopen(filename,'r');           
           
           header1 = fgetl(fid); %#True event suffix: h4_ocular
           name1 = regexp(header1,'.+:\s+(?<algorithm>.+)','names');
           if(~isempty(name1))
               roc_struct.truth_algorithm = name1.algorithm;
           end
           header2 = fgetl(fid); %#Detection Algorithm: detection.detection_ocular_movement_v2           
           name2 = regexp(header2,'.+:+\s+(?<algorithm>.+)','names');
           if(~isempty(name2))
               roc_struct.estimate_algorithm = name2.algorithm;
           end
           %                    TP      FN      FP      TN 
           % #Config	Study	Q(TP)	Q(FN)	Q(FP)	Q(TN)	FPR	TPR	ACC	K_1_0 K_0_0	CohensKappa	PPV	NPV	precision	recall	lower_threshold_uV	upper_threshold_uV	min_duration_sec	max_duration_sec	filter_hp_freq_Hz
           str = fgetl(fid);
           if(strcmp(str(1),'#'))
               str = str(2:end);
           end;
           
           %pull out all of the column names now and convert to a cell
           col_names = textscan(str,'%s');
           col_names = col_names{1};
           
           %creating the read encode format to a float (configID), two strings (1. FileName and
           %2. extension (.edf) and trailing space(?)), and remaining floats for parameter values
           data = textscan(fid,['%f%s%s',repmat('%f',1,numel(col_names)-2)]);
           study_name = [char(data{2}),repmat(' ',numel(data{2}),1),char(data{3})];

           roc_struct.config = data{1};
           roc_struct.study = mat2cell(study_name,ones(size(study_name,1),1),size(study_name,2));

           data(3) = []; %did this to help eliminate confusion due to filenames taking up two fields ({2} and {3}) due to the ' '/space in them.
          
           Q = [data{3},data{4},data{5},data{6}]; %data has already been normalized by sample size...
%            sample_size = sum(Q,2);
%            quality = sum(Q(:,[1,2]),2)./sample_size; %(TP+FP)/sample_size
            quality = sum(Q(:,[1,2]),2); %(TP+FP)

%            Q = reshape(Q',2,[])';
           
%            Q_cell = mat2cell(Q,2*ones(size(Q,1)/2,1),2);
%            roc_struct.Q = Q_cell;
           roc_struct.Q = Q;
           roc_struct.FPR = data{7};
           roc_struct.TPR = data{8};
           roc_struct.ACC = data{9};
           roc_struct.K_1_0 = data{10};
           roc_struct.K_0_0 = data{11};
           roc_struct.CohensKappay = data{12};
           roc_struct.PPV = data{13};
           roc_struct.NPV = data{14};
           roc_struct.precision = data{15};
           roc_struct.recall = data{16};

           roc_struct.values = data(17:end);
           roc_struct.key_names = col_names(17:end);
           

           roc_struct.quality = quality;

           roc_struct.study_names = unique(roc_struct.study);
           fclose(fid);
            
        end
        
        
        %> @brief Loads older ROC data file format output as generated by
        %> SEV's batch job.
        %> @param filename Filename with following file name template
        %> roc_truthAlgorithm_VS_estimateAlgorithm.txt Where Algorithm is
        %> the algorithm name that produced the .txt output file from batch
        %> mode.
        %> @retval roc_struct Struct with the following fields
        %> - @c roc_struct.config - unique id for each parameter combination
        %> - @c roc_struct.truth_algorithm = algorithm name for gold standard
        %> - @c roc_struct.estimate_algorithm = algorithm name for the estimate
        %> - @c roc_struct.study - edf filename
        %> - @c roc_struct.Q    - confusion matrix (2x2)
        %> - @c roc_struct.FPR    - false positive rate (1-specificity)
        %> - @c roc_struct.TPR   - true positive rate (sensitivity)
        %> - @c roc_struct.ACC    - accuracy
        %> - @c roc_struct.values   - parameter values
        %> - @c roc_struct.key_names - key names for the associated values
        %> - @c roc_struct.study_names - unique study names for this container
        %> - @c roc_struct.K_0_0 - weighted Kappa value for QROC
        %> - @c roc_struct.K_1_0 - weighted Kappa value for QROC
        function roc_struct = loadROCdataOld(filename) 
           
           pat = '.*ROC_(?<truth_algorithm>.+)_VS_(?<estimate_algorithm>.+)\.txt';
           t = regexpi(filename,pat,'names');
           if(isempty(t))
               roc_struct.truth_algorithm = 'unknown truth_algorithm';
               roc_struct.estimate_algorithm = 'unknown estimate_algorithm';
           else
               roc_struct.truth_algorithm = t.truth_algorithm;
               roc_struct.estimate_algorithm = t.estimate_algorithm;
           end
           
           fid = fopen(filename,'r');           
           
           header1 = fgetl(fid); %#True event suffix: h4_ocular
           name1 = regexp(header1,'.+:\s+(?<algorithm>.+)','names');
           if(~isempty(name1))
               roc_struct.truth_algorithm = name1.algorithm;
           end
           header2 = fgetl(fid); %#Detection Algorithm: detection.detection_ocular_movement_v2           
           name2 = regexp(header2,'.+:+\s+(?<algorithm>.+)','names');
           if(~isempty(name2))
               roc_struct.estimate_algorithm = name2.algorithm;
           end
           %                     TP      FN      FP      TN 
%            #Config	Study	Q_1_1	Q_1_2	Q_2_1	Q_2_2	FPR	TPR	ACC	sum_threshold_scale_factor	diff_threshold_scale_factor	max_merge_time_sec
           str = fgetl(fid);
           if(strcmp(str(1),'#'))
               str = str(2:end);
           end;
           col_names = textscan(str,'%s');
           col_names = col_names{1};
           data = textscan(fid,['%f%s%s',repmat('%f',1,numel(col_names)-2)]);
           study_name = [char(data{2}),repmat(' ',numel(data{2}),1),char(data{3})];

           roc_struct.config = data{1};
           roc_struct.study = mat2cell(study_name,ones(size(study_name,1),1),size(study_name,2));

           data(3) = []; %did this to help eliminate confusion due to filenames taking up two fields ({2} and {3}) due to the ' '/space in them.
          
           Q = [data{3},data{4},data{5},data{6}];
           sample_size = sum(Q,2);
           quality = sum(Q(:,[1,2]),2)./sample_size; %(TP+FP)/sample_size


%            Q = reshape(Q',2,[])';
           
%            Q_cell = mat2cell(Q,2*ones(size(Q,1)/2,1),2);
%            roc_struct.Q = Q_cell;
           roc_struct.Q = Q;
           roc_struct.FPR = data{7};
           roc_struct.TPR = data{8};
           roc_struct.ACC = data{9};
           roc_struct.values = data(10:end);
           roc_struct.key_names = col_names(10:end);
           

           roc_struct.K_0_0 = 1-roc_struct.FPR./quality;
           roc_struct.K_1_0 = (roc_struct.TPR-quality)./(1-quality);
           roc_struct.quality = quality;

           roc_struct.study_names = unique(roc_struct.study);
           fclose(fid);
            
        end
        
        %> @brief This function borrows heavily from sev../import_sco_events.m and requires
        %> the use of loadSCOfile.m
        %> @note Usage:
        %> - @c exportSCOtoEvt() prompts user for .SCO directory and evt output directory
        %> - @c exportSCOtoEvt(sco_pathname) sco_pathname is the .SCO file containing
        %> directory.  User is prompted for evt output directory
        %> - @c exportSCOtoEvt(sco_pathname, evt_pathname) evt_pathname is the directory
        %> where evt files are exported to.
        %> @param sco_pathname is the .SCO file containing directory. 
        %> @param evt_pathname The directory where evt files are exported to.
        function exportSCOtoEvt(sco_pathname, evt_pathname)
            % Author: Hyatt Moore IV, Stanford University
            % Date Created: 1/9/2012
            % modified 2/6/2012: Checked if evt_pathname exists first and, if not,
            % creates the directory before proceeding with export
            
            %this file has been integrated into CLASS_events_container.m as a static
            %method (10.19.12)
            if(nargin<1 || isempty(sco_pathname))
                sco_pathname = uigetdir(pwd,'Select .SCO (and .STA) import directory');
            end
            if(nargin<2 || isempty(evt_pathname))
                evt_pathname = uigetdir(sco_pathname,'Select .evt export directory');
            end
            
            if(~exist(evt_pathname,'dir'))
                mkdir(evt_pathname);
            end
            % sco_pathname = '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11';
            % evt_pathname = '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11/output/events/sco';
            
            if(~isempty(sco_pathname) && ~isempty(evt_pathname))
                
                dirStruct = dir(fullfile(sco_pathname,'*.SCO'));
                
                if(~isempty(dirStruct))
                    filecount = numel(dirStruct);
                    filenames = cell(numel(dirStruct),1);
                    [filenames{:}] = dirStruct.name;
                end
                
                %example output file name
                % evt.C1013_4 174933.SWA.0.txt
                evt_filename_str = 'evt.%s.SCO_%s.0.txt'; %use this in conjunction with sprintf below for each evt output file
                
                %evt header example:
                %    Event Label =	SWA
                %    EDF Channel Label(number) = 	C3-M2 (3)
                %    Start_time	Duration_seconds	Start_sample	Stop_sample	Epoch	Stage	freq	amplitude
                evt_header_str = ['Event Label =\t%s\r\nEDF Channel Label(number) =\tUnset (0)\r\n',...
                    'Start_time\tDuration_seconds\tStart_sample\tStop_sample\tEpoch\tStage\r\n'];
                
                %     timeFormat = 'HH:MM:SS';
                % %     evt_content_str = ['%s',...
                %      evt_content_str = [repmat('%c',1,numel(timeFormat)),...
                %                         '\t%0.4f',...
                %                         '\t%d',...
                %                         '\t%d',...
                %                         '\t%d',...
                %                         '\t%d',...
                %                         '\r\n'];
                
                for k=1:filecount
                    sco_filename = filenames{k};
                    study_name = strtok(sco_filename,'.'); %fileparts() would also work
                    
                    %example .STA filename:    A0097_4 174733.STA
                    %         sta_filename = [sco_filename(1:end-3),'STA'];
                    sta_filename = [study_name,'.STA'];
                    try
                        SCO = CLASS_code.parseSCOfile(fullfile(sco_pathname,sco_filename));
                    catch me
                        disp(me);
                        rethrow(me);
                    end
                    if(~isempty(SCO))
                        
                        STA = load(fullfile(sco_pathname,sta_filename),'-ASCII'); %for ASCII file type loading
                        stages = STA(:,2); %grab the sleep stages
                        
                        %indJ contains the indices corresponding to the unique
                        %labels in event_labels (i.e. SCO.labels = event_labels(indJ)
                        SCO.label(strcmpi(SCO.label,'Obst. Apnea')) = {'Obs Apnea'};
                        [event_labels,~,indJ] = unique(SCO.label);
                        
                        for j=1:numel(event_labels)
                            try
                                evt_label = deblank(event_labels{j});
                                space_ind = strfind(evt_label,' ');  %remove blanks and replace tokenizing spaces
                                evt_label(space_ind) = '_';  %with an underscore for database and file naming convention conformance
                                evt_filename = fullfile(evt_pathname,sprintf(evt_filename_str,study_name,evt_label));
                                evt_indices = indJ==j;
                                start_stop_matrix = SCO.start_stop_matrix(evt_indices,:);
                                
                                duration_seconds = SCO.duration_seconds(evt_indices);
                                epochs = SCO.epoch(evt_indices);
                                
                                evt_stages = stages(epochs);  %pull out the stages of interest
                                
                                start_time = char(SCO.start_time(evt_indices));
                                
                                %this must be here to take care of the text to file  problem
                                %that pops up when we get different lengthed time
                                %stamps (i.e. it is not guaranteed to be HH:MM:SS but
                                %can be H:MM:SS too)
                                evt_content_str = [repmat('%c',1,size(start_time,2)),...
                                    '\t%0.2f',...
                                    '\t%d',...
                                    '\t%d',...
                                    '\t%d',...
                                    '\t%d',...
                                    '\r\n'];
                                
                                % Start_time\tDuration_seconds\tStart_sample\tStop_sample\tEpoch\tStage'];
                                evt_content = [start_time+0,duration_seconds,start_stop_matrix,epochs, evt_stages];
                                fout = fopen(evt_filename,'w');
                                fprintf(fout,evt_header_str, evt_label);
                                fprintf(fout,evt_content_str,evt_content');
                                fclose(fout);
                            catch ME
                                disp(ME);
                                disp(['failed on ',study_name,' for event ',evt_label]);
                            end
                            
                        end
                    end
                end
            end
        end
        
            
    end %End static methods
    
end  % End class definition


%         % =================================================================
%         %> @brief
%         %> @param obj instance of CLASS_events_container class.
%         %> @param
%         %> @retval 
%         % =================================================================
%         function sourceStruct = getSourceStruct(obj,event_index)
%             %this method is not referenced and may be dropped in the future
%             %determine if there is a gui to use for this method to
%             %adjust the parameters/properties of the detection
%             %algorithm
%             global MARKING;
%             childobj = obj.getEventObj(event_index);
%             detection_struct = MARKING.getDetectionMethodsStruct();
%             gui_ind = find(strcmp(childobj.label,detection_struct.evt_label));
%             if(~isempty(gui_ind))
%                 sourceStruct.channel_indices = childobj.class_channel_index;
%                 sourceStruct.algorithm = [MARKING.SETTINGS.VIEW.detection_path(2:end),'.',detection_struct.param_gui{gui_ind}.mfile];
%                 sourceStruct.editor = detection_struct.param_gui{gui_ind};
%             else
%                 sourceStruct = [];
%             end
%         end