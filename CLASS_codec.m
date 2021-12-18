%> @file CLASS_codec.cpp
% ======================================================================
%> @brief CLASS_codec encapuslates much of the coding and decoding
%> functionality required by SEV's IO routines.  The methods here are all static.
%> @note Author: Hyatt Moore IV
%> @note Created 9/29/2014 - Derived from CLASS_events_container static
%> methods.
% ======================================================================
classdef CLASS_codec < handle
    properties(Constant)
       SECONDS_PER_EPOCH = 30;
       EDF_ANNOTATIONS_CHANNEL = 1;
    end
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
        %> - @c line = the second column of stages_filename - the scored sleep stages
        %> - @c count = the number of stages for each one
        %> - @c cycle - the nrem/rem cycle
        %> - @c firstNonWake - index of first non-Wake(0) and non-unknown(7) staged epoch
        %> - @c standard_epoch_sec 30 seconds
        %> - @c filename Name of the staging filename
        %> - @c study_duration_in_seconds How long the study is measured in
        %> seconds based on the number of epochs entered and the
        %> standard_epoch_sec duration (i.e. 30 seconds)
        %> - @c standard_epoch_sec standard epoch duration in sec (30 s)
        %> - @c standard_epoch_min minutes per epoch (e.g. 0.5 m)
        %> @note Author: Hyatt Moore IV
        %> Written: 9.26.2012
        %> modified before 12.3.2012 to include scoreSleepCycles(.);
        %> modified 1/16/2013 - added .firstNonWake
        %> modified 2/2/2013 - added .standard_epoch_sec = 30
        %>                           .study_duration_in_seconds
        %> modified 5.1.2013 - added .filename = stages_filename;
        %> midified 12.17.2019 - adding stage summary metrics (e.g. sleep
        %>                       latency metric)
        function STAGES = loadSTAGES(stages_filename,num_epochs,unknown_stage_label)

            if(nargin<3)
                default_unknown_stage = 7;
                if(nargin<2)
                    num_epochs = -1;
                    if(nargin<1)
                        stages_filename = [];
                    end
                end
            else
                default_unknown_stage = unknown_stage_label;
            end

            % Make a default line, regardless of what comes out of here.
            stages = repmat(default_unknown_stage,num_epochs,1);

            if(~isempty(stages_filename))
                [~,~,ext] = fileparts(stages_filename);

                %load stages information if the file exists and we know its
                %extension.
                if(exist(stages_filename,'file') && (strcmpi(ext,'.sta')||strcmpi(ext,'.evts')))
                    if(strcmpi(ext,'.sta') || strcmpi(ext,'.evts'))
                        if(strcmpi(ext,'.sta'))
                            stages = load(stages_filename,'-ASCII'); %for ASCII file type loading
                        else
                            [~,stages] = CLASS_codec.parseSSCevtsFile(stages_filename,default_unknown_stage);
                        end
                        %                 elseif(strcmpi(ext,'.evts'))
                        %                     [~,stageVec] = CLASS_codec.parseSSCevtsFile(stages_filename,default_unknown_stage);
                        %                     STAGES.line = stageVec;
                        %                     STAGES.epochs = 1:numel(STAGES.line);
                        %                 end
                    end
                else
                    mfile =  strcat(mfilename('fullpath'),'.m');
                    fprintf('failed in %s\n\tFilename argument for loadSTAGES could not be found.\n',mfile);
                    %  throw(MException('SEV:ARGERR','Filename argument for loadSTAGES could not be found'));
                end
            else
                mfile =  strcat(mfilename('fullpath'),'.m');
                fprintf('failed in %s\n\tMissing or empty filename argument for loadSTAGES\n',mfile);
                % throw(MException('SEV:ARGERR','Missing or empty filename argument for loadSTAGES'));
            end
            STAGES = CLASS_codec.stages2STAGES(stages,num_epochs, default_unknown_stage);
            STAGES.filename = stages_filename;
        end

        % Returns axes handle (ax)
        function ax = plotSTAGES(STAGES, study_start_time)
            %
            % W  (w)  0
            % R  (r)  5
            % N1 (p)  1
            % N2 (v)  2
            % N3 (g)  3
            %          Lights out - (next hour skipped) - then each hour (HH AM/PM)
            if nargin<2 || isempty(study_start_time)
                study_start_time = [0 0 0];
            end

            hypno = STAGES.line(STAGES.tib_first_epoch:STAGES.tib_final_epoch);

            % lights out
            staging_start_time = datenum([0 0 0, study_start_time]+[0 0 0 0 STAGES.tib_first_epoch*0.5 0]);
            epoch_time = datenum([0 0 0 0 0 30]);
            % lights on
            staging_end_time = datenum([0 0 0, study_start_time]+[0 0 0 0 STAGES.tib_final_epoch*0.5 0]);
            % end_time = start_time+(numel(hypno)-1)*epoch_time;
            x = staging_start_time:epoch_time:staging_end_time;
            % go every hour after an hour, rounded up, from the start time.
            x_ticks = [staging_start_time, ceil(mod(staging_start_time, 1)*24+1)/24:1/24:staging_end_time];

            hypno_offset = [0 10 'k'+0
                            5  8 'r'+0
                            1  6 'm'+0
                            2  4 'b'+0
                            3  2 'g'+0
                            4  2 'g'+0
                            7  0 'w'+0] ;
            %hypno_line = nan(size(hypno));
            % Place the lines at the specified offsets.
            set(gcf,'position', [10 1000 750 128]);
            ax = axes('box','on', 'nextplot','add','tickdir','out',...
                'ylim',[0, 12], 'xlim',[staging_start_time, staging_end_time],...
                'xtickmode','manual','xtick',x_ticks,...
                'plotboxaspectratiomode','manual','plotboxaspectratio',[30 12 1],...
                'dataaspectratiomode','manual','dataaspectratio',[3 1200 1],...
                'yticklabelmode','manual','ytick', flipud(hypno_offset(1:end-2,2)),...
                'yticklabel',fliplr({'W','R','N1','N2','N3'}));
            width = 1;

            for s=1:size(hypno_offset,1)
                hypno_line = nan(size(hypno));
                hypno_line(hypno==hypno_offset(s,1)) = hypno_offset(s,2);
                bar(ax, x, hypno_line, width, char(hypno_offset(s,3)));
            end
            % datetick(ax,'x','HH PM','keeplimits');
            datetick(ax,'x','HH PM','keepticks','keeplimits');
            xticklabels = string(get(ax,'xticklabel'));
            xticklabels{1} = datestr(staging_start_time,'HH:MM:SS PM');
            set(ax,'xticklabel',xticklabels);

        end

        % stages is either an Mx1 vector or an Mx2 or Mx3 matrix
        % If Mx1 then elements are stages in epoch order.
        % If Mx2 then column 1 comprises the scored epoch number and column 2
        % comprises the sleep stage scored for the corresponding epoch
        function STAGES = stages2STAGES(stages, num_epochs, default_unknown_stage)
            narginchk(1,3);

            if(nargin<3)
                default_unknown_stage = 7;
            end
            STAGES.standard_epoch_sec = CLASS_codec.SECONDS_PER_EPOCH; %30 second epochs
            STAGES.standard_epoch_min = CLASS_codec.SECONDS_PER_EPOCH/60; %30 second epochs

            if(size(stages,2)>2)
                stages = stages(:, 1:2);
            end

            if(size(stages,2)~=2)
                stage_vec = stages;
                epochs = 1:numel(stage_vec);
                stages = [epochs(:), stage_vec];
            end

            % stages is Mx2 matrix with column 1 being the
            % epochs and column 2 being the stage
            if(nargin<2 || num_epochs<0)
                num_epochs = size(stages,1);
            end

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

            STAGES.filename = [];
            STAGES.firstNonWake = [];
            STAGES.summary_field_names = CLASS_codec.getSTAGESSummaryFieldNames();
            STAGES.count = zeros(8,1);
            STAGES.bouts = zeros(8,1);

            if(nargin<2)
                num_epochs = numel(STAGES.line);
            end
            %calculate number of epochs in each stage
            for k = 0:numel(STAGES.count)-1
                STAGES.count(k+1) = sum(STAGES.line==k);
                bout_diff = diff(STAGES.line==k);
                STAGES.bouts(k+1) = max(sum(bout_diff==1), sum(bout_diff==-1));
            end

            firstNonWake = 1;
            while( firstNonWake<=numel(STAGES.line) && (STAGES.line(firstNonWake)==7||STAGES.line(firstNonWake)==0))
                firstNonWake = firstNonWake+1;
            end
            if firstNonWake> numel(STAGES.line)
                firstNonWake = [];
            end

            STAGES.firstN1_epoch = find(STAGES.line==1,1);
            STAGES.firstN2_epoch = find(STAGES.line==2,1);
            STAGES.firstSWS_epoch = find(STAGES.line==3|STAGES.line==4,1);

            [STAGES.tib_first_epoch, STAGES.tib_final_epoch] = CLASS_codec.getTIBEpochs(STAGES.line, default_unknown_stage);

            lastNonWake = STAGES.tib_final_epoch;
            if ~isempty(lastNonWake)
                while( lastNonWake>=1 && (STAGES.line(lastNonWake)==7||STAGES.line(lastNonWake)==0))
                    lastNonWake = lastNonWake-1;
                end
                if lastNonWake<1
                    lastNonWake = [];
                end
            end

            STAGES.firstNonWake = firstNonWake;
            STAGES.lastNonWake = lastNonWake;
            if(num_epochs~=numel(STAGES.line))
                fprintf(1,'Hypnogram contains %u stages, but shows it should have %u\n', numel(STAGES.line),num_epochs);
            end

            % tib
            wk_tib_bout_diff = diff(STAGES.line(STAGES.tib_first_epoch:STAGES.tib_final_epoch)==0);
            STAGES.bouts_wake_during_tib = max(sum(wk_tib_bout_diff==1), sum(wk_tib_bout_diff==-1));

            % sleep period time
            wk_spt_bout_diff = diff(STAGES.line(STAGES.firstNonWake:STAGES.lastNonWake)==0);
            STAGES.bouts_wake_during_spt = max(sum(wk_spt_bout_diff==1), sum(wk_spt_bout_diff==-1));

            %this may be unnecessary when the user does not care about sleep cycles.
            % STAGES.cycles = scoreSleepCycles(STAGES.line);

            STAGES.cycles = scoreSleepCycles_ver_REMweight(STAGES.line);
            STAGES.study_duration_in_seconds = STAGES.standard_epoch_sec*numel(STAGES.line);
            STAGES.study_duration_minutes = numel(STAGES.line) * STAGES.standard_epoch_min;
            STAGES.total_wake_sleep_minutes = sum(STAGES.line~=7) * STAGES.standard_epoch_min;
            STAGES.sleep_latency_minutes = CLASS_codec.getSleepLatency(STAGES);
            STAGES.rem_latency_minutes = CLASS_codec.getREMLatency(STAGES);
            STAGES.n1_latency_minutes = nan;
            STAGES.n2_latency_minutes = nan;
            STAGES.sws_latency_minutes = nan;
            if ~isempty(STAGES.firstN1_epoch)
                STAGES.n1_latency_minutes = (STAGES.firstN1_epoch-STAGES.tib_first_epoch)*STAGES.standard_epoch_min;
            end
            if ~isempty(STAGES.firstN2_epoch)
                STAGES.n2_latency_minutes = (STAGES.firstN2_epoch-STAGES.tib_first_epoch)*STAGES.standard_epoch_min;
            end
            if ~isempty(STAGES.firstSWS_epoch)
                STAGES.sws_latency_minutes = (STAGES.firstSWS_epoch-STAGES.tib_first_epoch)*STAGES.standard_epoch_min;
            end

            STAGES.waso_minutes = sum(STAGES.line(STAGES.firstNonWake:end)==0) * STAGES.standard_epoch_min;
            STAGES.total_wake_min = sum(STAGES.line==0) * STAGES.standard_epoch_min;
            STAGES.total_sleep_min = sum(STAGES.line~=0 & STAGES.line~=7) * STAGES.standard_epoch_min;
            STAGES.total_s1_min = sum(STAGES.line==1) * STAGES.standard_epoch_min;
            STAGES.total_s2_min = sum(STAGES.line==2) * STAGES.standard_epoch_min;
            STAGES.total_sws_min = sum(STAGES.line==3|STAGES.line==4) * STAGES.standard_epoch_min;
            STAGES.total_rem_min = sum(STAGES.line==5) * STAGES.standard_epoch_min;

            % spt - sleep period time
            STAGES.total_sleep_period_min = (STAGES.lastNonWake-STAGES.firstNonWake+1) * STAGES.standard_epoch_min;
            STAGES.total_wake_during_tib_min = sum(STAGES.line(STAGES.tib_first_epoch: STAGES.tib_final_epoch)==0) * STAGES.standard_epoch_min;
            STAGES.total_wake_during_sleep_period_min = sum(STAGES.line(STAGES.firstNonWake: STAGES.lastNonWake)==0) * STAGES.standard_epoch_min;
            num_epochs_in_bed = STAGES.tib_final_epoch-STAGES.tib_first_epoch+1;
            if isempty(num_epochs_in_bed)
                num_epochs_in_bed = 0;
            end

            STAGES.tib_min = max(num_epochs_in_bed *STAGES.standard_epoch_min,0); % ensure sure we don't get negative values with max(...,0)

            % Duration in minutes of epochs scored as 7 ('unknown')
            STAGES.unscored_tib_min = STAGES.tib_min - STAGES.total_wake_sleep_minutes;
            if (STAGES.unscored_tib_min < 0)
               %A0120_6
               fprintf(1,'Warning\n');
            end
        end

        function [first_epoch, final_epoch] = getTIBEpochs(stages_vec, not_in_bed_value)
            if nargin<2
                not_in_bed_value = 7;
            end
            first_epoch = 1;
            final_epoch = numel(stages_vec);
            mask_indices = stages_vec==not_in_bed_value;
            if(mask_indices(1))
                first_epoch = find(~mask_indices, 1, 'first');
            end

            % book end - does it end masked (i.e. finish with 7's)
            if(mask_indices(end))
                final_epoch = find(~mask_indices,1, 'last');
            end
        end

        function summary_field_names = getSTAGESSummaryFieldNames()
            summary_field_names = { ...
                'study_duration_minutes', 'tib_min', ...
                'total_wake_sleep_minutes', 'unscored_tib_min', ...
                'sleep_latency_minutes', 'rem_latency_minutes', 'waso_minutes', ...
                'total_wake_min', 'total_sleep_min', 'total_s1_min', ...
                'total_s2_min', 'total_sws_min', 'total_rem_min' ...
                };
        end

        function sleepl_minutes_elapsed = getSleepLatency(STAGES)
            sleepl_minutes_elapsed = (STAGES.firstNonWake-STAGES.tib_first_epoch)*STAGES.standard_epoch_min;
        end

        % The presence of a SOREMP upon first falling asleep was first reported by
        % Vogel in 1960 and Rechaffen and Dement in approximately half of untreated
        % patients with narcolepsy.  In a large study of 648 Type 1 patients and
        % 1369 controls we found that a REM latency (REML) ? 15 minutes was highly
        % specific in controls (98.0% but only had a specificity of 49.7%.  A
        % cutoff for REML of <= 15 minutes was used as it is the value also used in
        % MSLT naps, although in many models REML ranging <= 20 minutes were more
        % advantageous, allowing sensitivity to be raised to 60% with limited loss
        % of specificity and are likely to be used in a combined model.
        function [reml_minutes_elapsed, test_result] = getREMLatency(STAGES, threshold_optional)
            INIT_SOREMP_THRESHOLD_MIN = 15;
            REM_STAGE = 5;
            if(nargin>1 && ~isempty(threshold_optional))
                threshold_min = threshold_optional;
            else
                threshold_min = INIT_SOREMP_THRESHOLD_MIN;
            end
            firstREMIndex = find(STAGES.line==REM_STAGE,1);
            reml_minutes_elapsed = (firstREMIndex - STAGES.firstNonWake)*STAGES.standard_epoch_min;

            test_result = reml_minutes_elapsed <= threshold_min;
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
        %> and have a file extension of '.EVTS' or '.SCO'
        %> @param events_filename Filename of the hypnogram with path.
        %> .EVTS is checked first, then .SCO extension is checked if .STA is
        %> not found.  If neither staging file type is found (.STA or .EVTS)
        %> then stages_filename is returned as empty (i.e. [])
        %> @retval event_Filename
        %> @retval edf_name edf filename sans pathname.
        % ======================================================================
        function [event_Filename, edf_name] = getEventsFilenameFromEDF(edf_fullfilename)
            [edf_path,edf_name,edf_ext] = fileparts(edf_fullfilename);
            event_Filename = fullfile(edf_path,strcat(edf_name,'.EVTS'));

            if(~exist(event_Filename,'file'))
                event_Filename = fullfile(edf_path,strcat(edf_name,'.SCO'));
                if(~exist(event_Filename,'file'))
                    event_Filename = [];
                end
            end
            edf_name = strcat(edf_name,edf_ext);
        end

        % =================================================================
        %> @brief Retrives a function call for files in directories with a '+'
        %> prefix.
        %------------------------------------------------------------------%
        %> @param methodName Method's name (sans path and .m)
        %> @param packageName Package name (string).  Supported values include
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
        %> @param packageName Package name (string).  Supported values include
        %> - @c export
        %> - @c detection
        %> - @c filter
        %> @retval methodInformationFilename Full filename of the information
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
        %> @param methodName Method's name (sans path and .m)
        %> @param packageName Package name that method is part of (string).  Supported values include
        %> - @c export
        %> - @c detection
        %> - @c filter
        %> @retval parameterStruct
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
        %> @param exprtInfFullFilename Full filename (path and name) of the export information
        %> file to parse.
        %> @retval exportMethodsStruct Struct with the following fields:
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
            end
        end
        
        function hdr = loadHDR(edfFilename)
            hdr = loadHDR(edfFilename);
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

            fid = fopen(staFilename, 'w');
            if fid>2
                fprintf(fid, '%d\t%d\n', y');
                fclose(fid);
            else
                %double check that we have .STA extension
                save(staFilename,'y','-ascii');
            end

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
        
        %> @brief stages here refers to Stanford's STAGES cohort, a multisite 
        %> collection of PSGs.
        function [evt_Struct,samplerate_out] = parseSTAGESEventFile(eventsFile, edfFile, desired_samplerate)
            samplerate_out = desired_samplerate;
            if(~exist(eventsFile,'file'))                
                error('File does not exist or was not given: %s', eventsFile);
            end
            
            if nargin<3 || isempty(desired_samplerate)
                desired_samplerate = 100;
            end
            if nargin<2
                edfFile = [];
            end
            
            fid = fopen(eventsFile, 'r');
            if fid < 1
                error('Unable to open file: %s', eventsFile);
            else
                % Start Time,Duration (seconds),Event
                % 19:52:36, 0.000, MChg
                % 19:52:36, 0.000, MChg
                % 19:52:36, 0.000, MChg
                a = textscan(fid, '%{hh:mm:ss}T %f %s', 'headerlines', 1, 'delimiter',',');
                fclose(fid);
                start_time = a{1};
                duration_sec = a{2};
                event_label = a{3};
                
                custom_idx = startsWith(event_label, 'custom','IgnoreCase', true);
                start_time(custom_idx) = [];
                duration_sec(custom_idx) = [];
                event_label(custom_idx) = [];
                
                if ~isempty(edfFile) && exist(edfFile, 'file')
                    HDR = loadHDR(edfFile);
                else
                    HDR = [];
                end
                
                evt_Struct = CLASS_codec.makeEventStruct();
                evt_Struct.HDR = HDR;
                evt_Struct.type = eventType;
                evt_Struct.start_stop_matrix = start_stop_matrix;
                evt_Struct.start_sec = start_sec;
                evt_Struct.stop_sec = stop_sec;
                evt_Struct.dur_sec = dur_sec;
                evt_Struct.epoch = epoch;
                evt_Struct.stage = stage;
                evt_Struct.evtID = evtID;
                if(~isempty(description))
                    evt_Struct.description = description;
                end
                if(~isempty(remainder))
                    evt_Struct.unknown = remainder;
                end
            end                
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
        %> @retval embla_evt_Struct
        %> @retval embla_samplerate_out
        % =================================================================
        function [embla_evt_Struct, embla_samplerate_out] = parseEmblaEvent(evtFilename, embla_samplerate, desired_samplerate)
            %embla_samplerate_out may change if there is a difference found in
            %the stage .evt file processing as determined by adjusting for
            %a 30 second epoch.
            if(nargin<2)
                embla_samplerate = [];
            end
            embla_samplerate_out = embla_samplerate;

            if(~exist(evtFilename,'file'))
                embla_evt_Struct = [];
                disp([evtFilename,' not handled']);
            else
                if(nargin < 3 || isempty(desired_samplerate))
                    desired_samplerate = 0;
                end
                [~,name,~] = fileparts(evtFilename);

                fid = fopen(evtFilename,'r','l'); % little endian format
                HDR = CLASS_codec.parseEmblaHDR(fid);

                start_sec = [];
                stop_sec = [];
                dur_sec = [];
                epoch = [];
                stage = [];
                start_stop_matrix = [];
                description = [];
                evtID = [];

                remainder = [];
                eventType = name;
                bytes_per_uint16 = 2;

                if(HDR.num_records>0 && strncmpi(deblank(HDR.label),'event',5))
                    fseek(fid,0,'eof');
                    file_size = ftell(fid);
                    fseek(fid,32,'bof');
                    bytes_remaining = file_size-ftell(fid);
                    bytes_per_record = bytes_remaining/HDR.num_records;
                    start_sample = zeros(HDR.num_records,1);
                    stop_sample = start_sample;
                    evtID = zeros(HDR.num_records,2);
                    if strcmpi(eventType,'arousal')

                        arousType = stop_sample;
                        arousSecondType = stop_sample;
                        description = cell(HDR.num_records,1);
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            a
                            fseek(fid,32,'bof');
                        end

                        if(bytes_per_record==52)
                            unknownID = zeros(HDR.num_records,3);
                            remainder = zeros(HDR.num_records,4,'uint8');
                            orderPlaced = start_sample;
                            for r=1:HDR.num_records
                                start_sample(r) = fread(fid,1,'uint32');%[0-3
                                stop_sample(r) = fread(fid,1,'uint32');%[4-7
                                evtID(r,:) = fread(fid,2,'uint8'); % [8- [6,1]
                                unknownID(r,:) = fread(fid,3,'uint16');%[10-15
                                orderPlaced(r) = fread(fid,1,'uint32');%[16-
                                fseek(fid,28,'cof');% [20
                                remainder(r,:) = fread(fid,4,'uint8');%[440
                            end
                        elseif(bytes_per_record==16)
                            unknownID = zeros(HDR.num_records,2);
                            remainder = zeros(HDR.num_records,2,'uint8');
                            for r=1:HDR.num_records
                                start_sample(r) = fread(fid,1,'uint32');
                                stop_sample(r) = fread(fid,1,'uint32');
                                evtID(r,:) = fread(fid,2,'uint8'); % [6,1]
                                unknownID(r,:) = fread(fid,2,'uint16');
                                remainder(r,:) = fread(fid,2,'uint8');
                            end
                        end
                    elseif(strcmpi(eventType,'baddata'))
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            fseek(fid,32,'bof');
                            a(:,5:end)
                        end
                        start_sample = zeros(HDR.num_records,1);
                        stop_sample = start_sample;
                        intro_size = 10;
                        remainder = zeros(HDR.num_records,bytes_per_record-intro_size,'uint8');

                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            stop_sample(r) = fread(fid,1,'uint32');
                            evtID(r,:) = fread(fid,2,'uint8'); % [5,1]
                            remainder(r,:) = fread(fid,bytes_per_record-intro_size,'uint8');
                        end
                    elseif(strcmpi(eventType,'biocals'))
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            a
                            fseek(fid,32,'bof');
                        end
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
                        intro_size = 10; % 6 + 4
%                         intro_size = 34;
%                         remainder = zeros(HDR.num_records,bytes_per_record-intro_size,'uint8');

                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');  % 4 bytes
                            evtID(r,:) = fread(fid,2,'uint8'); % [13,1]

                            padding = fread(fid,1,'uint32')'; %[0 0 0 0]  % 4 bytes
                            curRecord = fread(fid,(bytes_per_record-intro_size)/bytes_per_uint16,'uint16')';
                            descriptionStop = find(curRecord==0,1,'first');
                            description{r} = char(curRecord(1:descriptionStop-1));
                            remainder{r}=curRecord(descriptionStop:end);

                            %                             description{r} = fread(fid,12,'uint16=>char')';  %24 bytes %need to read until I get to a 34 essentially%now at 64 or %32 bytes read
                            %                             remainder(r,:) = fread(fid,bytes_per_record-intro_size,'uint8')';
                        end
                        stop_sample = start_sample+5*embla_samplerate_out; %make it 5 seconds for viewing

                    elseif strcmpi(eventType,'custom')
                        %.evt is a 12 byte record

                        % 20 byte record
                        customType = stop_sample;

                        intro_size = 10;

                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            fseek(fid,32,'bof');
                            a
                        end


                        % Earlier notes from Hyatt
                        %80 byte blocks
                        %  1       5       9        13       14     15        16               17       25       30            31       32     33       38            39             40     41        42       45     46     47       49        53      57             58       61        77     78     79     80
                        % [uint32][uint32][uint8*4][ uint8] [uint8][uint8   ][uint8]          [uint8*8][uint8*5][uint8       ][uint8  ][uint8][uint8*5][uint8       ][uint8        ][uint8][uint8   ][uint8*3][uint8][uint8][uint8*2][uint32  ][uint32][uint8        ][uint8*3][uint32*4][uint8][uint8][uint8][uint8]
                        % [start ][stop  ][7 2 3 0][1/32/33][ 0   ][0-248   ][0/63/64/191/192][  255  ][   0   ][0/64/128/192][0/86/87][0/64 ][0      ][0/64/128/192][0/84/85/86/87][ 0/64][ 44/46  ][ 0     ][0-255][0/1/2][ 0     ][? or 255][ 255  ][counter++/255][0/255  ][   255  ][42   ][0/128][0-248][0/63/64/191/192]
                        %                                                                                                                                                                                                          i
                        %intro_size = 8;
                        %                         remainder_byte_count = (bytes_per_record-intro_size)/bytes_per_uint16;
                        remainder_byte_count = (bytes_per_record-intro_size);

                        remainder = zeros(HDR.num_records,remainder_byte_count,'uint8');

                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            stop_sample(r) = fread(fid,1,'uint32');
                            evtID(r,:) = fread(fid,2,'uint8'); % [20,?]

                            remainder(r,:) = fread(fid,remainder_byte_count,'uint8');
                        end

                    elseif(strcmpi(eventType,'desat'))
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')'
                            a
                            fseek(fid,32,'bof');
                        end

                        desatType = stop_sample;
                        respRelated = stop_sample;

                        desatHigh = stop_sample;
                        desatLow = stop_sample;
                        unknownFlags = nan(HDR.num_records,1);
                        otherStartStop = nan(HDR.num_records,2);
                        unknownDouble = desatHigh;
                        % 48 byte record
                        if(bytes_per_record ==48)
                            remainder = nan(HDR.num_records,1);
                            for r=1:HDR.num_records

                                start_sample(r) = fread(fid,1,'uint32'); % 04
                                stop_sample(r) = fread(fid,1,'uint32');  % 08
                                %  description = fread(fid,remainder_size/2,'uint16=>char')';
                                %desats - (come in pairs?)
                                % [8 1 2 0] [0/4 0 ? ?]  [255 255 255 255] [255 255 255 255] [84 16 13 164]

                                % [? ? 88/86/87 64] [? ? ? ?] [? ? 86/87/85 64] [8/10 ? ? ?] [? ? ? ?]
                                %
                                %1 byte [224] = ?
                                %4 bytes 224  106   99  104] [186  131   88   64]  [87   27   67  211]  [29 108   87   64]   [9  144   98    0  228  151    98  0]
                                %4 bytes
                                evtID(r,:) = fread(fid,2,'uint8'); % 10
                                desatType(r) = fread(fid,1,'uint16'); %12
                                respRelated(r) = fread(fid,1,'uint16'); %14
                                unknownFlags(r) = fread(fid,1,'int16'); %resp related flag %16
                                otherStartStop(r,:) = fread(fid,2,'int32'); % 24 % Padding
                                %                                 unknown(r) = fread(fid,1,'uint32'); % 28
                                % Signal# (##) 2 bytes
                                %                             signal(r) = fread(fid,1,'uint16'); %16
                                % Order of events placed (##) 2 bytes
                                % placementOrder(r) = fread(fid,1,'uint16'); %18

                                % skip 6 bytes
                                % unknown(r,:) = fread(fid,3,'uint16'); % 24

                                desatHigh(r) = fread(fid,1,'double'); % 36
                                desatLow(r) = fread(fid,1,'double');  % 44
                                unknownDouble(r) = fread(fid,1,'double');
                                remainder(r) = unknownDouble(r);

%                                 remainder(r) = fread(fid,1,'double');
                            end
                        elseif(bytes_per_record ==80)
                            remainder = zeros(HDR.num_records,4,'uint8');
                            for r=1:HDR.num_records
                                start_sample(r) = fread(fid,1,'uint32'); % 04
                                stop_sample(r) = fread(fid,1,'uint32');  % 08
                                evtID(r,:) = fread(fid,2,'uint8'); % 10
                                desatType(r) = fread(fid,1,'uint16'); %12
                                respRelated(r) = fread(fid,1,'uint16'); %14
                                unknownFlags(r) = fread(fid,1,'int16'); %resp related flag %16
                                otherStartStop(r,:) = fread(fid,2,'int32'); % 24 % Padding
                                desatHigh(r) = fread(fid,1,'double'); % 32
                                desatLow(r) = fread(fid,1,'double');  % 40
                                unknownDouble(r) = fread(fid,1,'double');
                                %                                 fseek(fid,2,'cof'); % 42 [255x2]
                                %                                 fseek(fid,4,'cof'); %46
                                %                                 fseek(fid,2,'cof'); % 48 [0x2]

                                fseek(fid,28,'cof'); % 76 [255x28]
                                % last 4 bytes: checksum
                                remainder(r,:) = fread(fid,4,'uint8');% 80 [41,108,0,0]
                            end
                        end

                        description = cell(HDR.num_records,1);
                        for r=1:HDR.num_records
                            subIDStr = '';
                            if(evtID(r,2)~=1)
                                subIDStr = sprintf(' SubID(%d)',evtID(r,2));
                            end
                            desatStr = '';
                            if(desatType(r)~=2)
                                desatStr = sprintf(' DesatType(%d)',desatType(r));
                            end
                            if(respRelated(r)==4)
                                respStr = ' w/Respiratory';
                            elseif(respRelated(r)==0)
                                respStr = '';
                            else
                                respStr = sprintf(' w/%d',respRelated(r));
                            end
                           description{r} = strtrim(sprintf('High=%f Low=%f%s%s%s',desatHigh(r), desatLow(r),subIDStr,desatStr,respStr));
                        end

                    elseif strcmpi(eventType,'filesect')
                        % 528 byte record
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            a
                            fseek(fid,32,'bof');
                        end
                        description = cell(HDR.num_records,1);
                        intro_size = 10;
                        remainder = cell(HDR.num_records,1);

                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            evtID(r,:) = fread(fid,2,'uint8'); % [6]
                            fseek(fid,4,'cof');  % zero padding fread(fid,1,'uint32');[10]

                            %get current position.
                            %                             curPos = ftell(fid);
                            % read until 0 char ? [42]
                            curRecord = fread(fid,(bytes_per_record-intro_size)/bytes_per_uint16,'uint16')';
                            descriptionStop = find(curRecord==0,1,'first');
                            description{r} = char(curRecord(1:descriptionStop-1));

                            remainder{r}=curRecord(descriptionStop+1:end-1);
                            recordStopSig = curRecord(end); % 31
                        end
                        stop_sample = start_sample+5*embla_samplerate_out; %make it 5 seconds for viewing
                    elseif strcmpi(eventType,'hr')
                        %  32 byte record
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            a
                            fseek(fid,32,'bof');
                        end

                        remainder = zeros(HDR.num_records,4);
                        float1 = nan(HDR.num_records,1);
                        float2 = nan(HDR.num_records,1);
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            stop_sample(r) = fread(fid,1,'uint32');
                            evtID(r,:) = fread(fid,2,'uint8'); % [6]
                            fseek(fid,2,'cof');  % zero padding fread(fid,1,'uint16');[10]
                            float1(r) = fread(fid,1,'float');
                            fseek(fid,4,'cof'); % 0-padding
                            float2(r) = fread(fid,1,'float');
                            remainder(r,:) = fread(fid,4,'uint16');
                        end
                    elseif(strcmpi(eventType,'numeric'))
                        % With text fields 7060_5-7-2006/numeric.evt
                        fseek(fid,32,'bof');
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            a(:,9:18)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record/2,inf],'uint16')';
                            a(:,9:end)
                            fseek(fid,32,'bof');
                        end
                        studyType = start_sample;
                        readLevels = zeros(HDR.num_records,2);
                        remainder = zeros(HDR.num_records,8,'uint8');
                        unknown = nan(HDR.num_records,1);
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            stop_sample(r) = fread(fid,1,'uint32'); % duration?
                            evtID(r,:) = fread(fid,2,'uint8');   %10
                            studyType(r) = evtID(r,2);
                            fseek(fid,4,'cof');  %unused. %14
                            unknown(r) = fread(fid,1,'uint16'); % used but unknown %16 % maybe ascii char
                            readLevels(r,:) = fread(fid,2,'double'); %32
                            remainder(r,:) = fread(fid,8,'uint8');
                        end
                        stop_sample = start_sample;
                        description = cell(HDR.num_records,1);
                        for r=1:HDR.num_records
                            %subIDStr = this.getNumericSubID(evtID(r,2));
                            if(evtID(r,2)==1)
                                subIDStr = 'CPAP';
                                levelStr = sprintf('(%0.3f)',readLevels(r,1));
                            elseif(evtID(r,2)==2)
                                subIDStr = 'Bilevel';
                                levelStr = sprintf('(%0.3f %0.3f)',readLevels(r,:));
                            else
                                subIDStr = sprintf('Numeric(subID=%d)',evtID(r,2));
                                levelStr = sprintf('(%0.3f %0.3f)',readLevels(r,:));
                            end
                           description{r} = sprintf('%s %s',subIDStr,levelStr);
                        end


                    %sometimes these have the extension .nvt
                    elseif(strcmpi(eventType,'plm'))
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            a(1:4,:)
                            fseek(fid,32,'bof');

                        end
                        leg = stop_sample;
                        arousal = stop_sample;
                        %                         signal = stop_sample;
                        %                         tag = signal;
                        %                         intro_size = 18;
                        arousalField = arousal;
                        if(bytes_per_record==52)
                            remainder = zeros(HDR.num_records,4,'uint8');
                            eventNumber = arousalField;
                            for r=1:HDR.num_records
                                start_sample(r) = fread(fid,1,'uint32'); % 4
                                stop_sample(r) = fread(fid,1,'uint32');  % 8

                                evtID(r,:) = fread(fid,2,'uint8'); % 10
                                leg(r) = fread(fid,1,'uint16'); %12 % From Oscar - Legs (L,R,Both: 1,2,3) 2 bytes
                                arousal(r) = fread(fid,1,'uint16'); %14 - % Arousal (No,Yes: 0,1) 2 bytes
                                % if there is an aroual
                                arousalField(r) = fread(fid,1,'uint16'); % Then this might be the channel associated with it, or the event associated with it. % 7 is a respiratory event
                                eventNumber(r) = fread(fid,1,'uint32'); % This is the event record number.  If there are no associated events, it is the current records value.  Otherwise, it is the number of associated events for that type.
                                fseek(fid,28,'cof');
                                remainder(r,:) = fread(fid,4,'uint8');
                            end
                        elseif(bytes_per_record==16)
                            remainder = zeros(HDR.num_records,2,'uint8');
                            for r=1:HDR.num_records
                                start_sample(r) = fread(fid,1,'uint32'); % 4
                                stop_sample(r) = fread(fid,1,'uint32');  % 8

                                evtID(r,:) = fread(fid,2,'uint8'); % 10
                                leg(r) = fread(fid,1,'uint16'); %12 % From Oscar - Legs (L,R,Both: 1,2,3) 2 bytes
                                arousal(r) = fread(fid,1,'uint16'); %14 - % Arousal (No,Yes: 0,1) 2 bytes
                                remainder(r,:) = fread(fid,2,'uint8');

                                % Signal# (##) 2 bytes
                                %                             signal(r) = fread(fid,1,'uint16'); %16
                                % Tag# entered? (##) 2 bytes
                                %                             tag(r) = fread(fid,1,'uint16'); %18
                                % skip 30 bytes
                                % last 4 bytes: checksum?
                                %                             remainder(r,:) = fread(fid,bytes_per_record-intro_size,'uint8');
                            end
                        end

                        description = cell(HDR.num_records,1);
                        for r=1:HDR.num_records
                            subIDStr = '';
                            if(evtID(r,2)~=2)
                                subIDStr = sprintf(' SubID(%d)',evtID(r,2));
                            end
                            legStr = '';
                            if(leg(r)==1)
                                legStr = 'Left leg';
                            elseif(leg(r)==2)
                                legStr = 'Right leg';
                            elseif(leg(r)==3)
                                legStr = 'Both legs';
                            end
                            if(arousal(r)==1)
                                arousalStr = ' w/Arousal';
                            elseif(arousal(r)==0)
                                arousalStr = '';
                            else
                                arousalStr = sprintf(' w/%d',arousal(r));
                            end
                           description{r} = strtrim(sprintf('%s%s%',subIDStr,legStr,arousalStr));
                        end


                    elseif strcmpi(eventType,'resp')

                        respType = stop_sample;
                        mediatedType = stop_sample;
                        arousal = stop_sample;
                        signal = stop_sample;
                        placementOrder = signal;

                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            a(:,9:18)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record/2,inf],'uint16')';
                            a=fread(fid,[bytes_per_record/4,inf],'uint32')';
                            a(:,9:end)
                            fseek(fid,32,'bof');
                        end
                        if(bytes_per_record==48) % found this in 'resp.evt'

                            for r=1:HDR.num_records
                                start_sample(r) = fread(fid,1,'uint32'); % [0,3]
                                stop_sample(r) = fread(fid,1,'uint32'); % [4,7]
                                evtID(r,:) = fread(fid,2,'uint8'); % [8] 7:
                                respType(r) = evtID(r,2); % [9] 1: Apnea; 2: Hypopne; 5: RERA
                                mediatedType(r) = fread(fid,1,'uint16'); % [10,11]  1: Central; 2: Mixed; 3: Obstructive; 0: ''
                                arousal(r) = fread(fid,1,'uint16'); % [12,13] 1: w/Arousal 32: w/Desat
                                signal(r) = fread(fid,1,'uint16'); % [14,15] => Signal# (##) 2 bytes?
                                fread(fid,8,'uint8'); % [18,25] 8 bytes of 1 bits set
                                fread(fid,16,'uint8'); %[26, 41] 16 bytes of 1 bits set
                                fread(fid,1,'uint8'); % [42] The number 10
                                fread(fid,7,'uint8'); % [43, 49] ?
                            end
                        elseif(bytes_per_record==80)   % found this in resp.nvt

                            % 80 byte record
                            % Earlier notes from Hyatt
                            %80 byte blocks
                            %  1       5       9        13       14     15        16               17       25       30            31       32     33       38            39             40     41        42       45     46     47       49        53      57             58       61        77     78     79     80
                            % [uint32][uint32][uint8*4][ uint8] [uint8][uint8   ][uint8]          [uint8*8][uint8*5][uint8       ][uint8  ][uint8][uint8*5][uint8       ][uint8        ][uint8][uint8   ][uint8*3][uint8][uint8][uint8*2][uint32  ][uint32][uint8        ][uint8*3][uint32*4][uint8][uint8][uint8][uint8]
                            % [start ][stop  ][7 2 3 0][1/32/33][ 0   ][0-248   ][0/63/64/191/192][  255  ][   0   ][0/64/128/192][0/86/87][0/64 ][0      ][0/64/128/192][0/84/85/86/87][ 0/64][ 44/46  ][ 0     ][0-255][0/1/2][ 0     ][? or 255][ 255  ][counter++/255][0/255  ][   255  ][42   ][0/128][0-248][0/63/64/191/192]
                            %                                                                                                                                                                                                          i
                            %intro_size = 8;
                            %                         remainder_byte_count = (bytes_per_record-intro_size)/bytes_per_uint16;
                            intro_size = 18;
                            remainder_byte_count = (bytes_per_record-intro_size);
                            remainder = zeros(HDR.num_records,remainder_byte_count,'uint8');
                            for r=1:HDR.num_records
                                start_sample(r) = fread(fid,1,'uint32'); % [0,3]
                                stop_sample(r) = fread(fid,1,'uint32'); % [4,7]
                                evtID(r,:) = fread(fid,2,'uint8'); % [8] 7:
                                respType(r) = evtID(r,2); % [9] 1: Apnea; 2: Hypopne; 5: RERA
                                mediatedType(r) = fread(fid,1,'uint16'); % [10,11]  1: Central; 2: Mixed; 3: Obstructive; 0: ''
                                arousal(r) = fread(fid,1,'uint16'); % [12,13] 1: w/Arousal 32: w/Desat
                                signal(r) = fread(fid,1,'uint16'); % [14,15] => Signal# (##) 2 bytes
                                placementOrder(r) = fread(fid,1,'uint16'); % [16,17] => Order of events placed (##) 2 bytes
                                remainder(r,:) = fread(fid,remainder_byte_count,'uint8');

                            end
                        else
                            fprintf(1,'Unknown block size (%d) for respiratory events\n',bytes_per_record);
                        end
                        description = cell(HDR.num_records,1);
                        for r=1:HDR.num_records
                        description{r} = strtrim(sprintf('%s %s %s',CLASS_codec.getRespMediatedType(mediatedType(r)),...
                                    CLASS_codec.getRespType(respType(r)),CLASS_codec.getRespAssociation(arousal(r))));
                        end
                    elseif(strcmpi(eventType,'snapshot'))
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            a
                            fseek(fid,32,'bof');
                        end

                    elseif strcmpi(eventType,'snore')
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            a
                            fseek(fid,32,'bof');
                        end
                        arousal = stop_sample;
                        respRelated = arousal;
                        snoreType = zeros(HDR.num_records,1);

                        if(bytes_per_record==16)
                            remainder = zeros(HDR.num_records,2,'uint8');
                            for r=1:HDR.num_records
                                start_sample(r) = fread(fid,1,'uint32'); % 4
                                stop_sample(r) = fread(fid,1,'uint32');  % 8

                                evtID(r,:) = fread(fid,2,'uint8'); % 10
                                %                                 snoreType(r) = fread(fid,1,'uint16'); %12 % ?
                                respRelated(r) = fread(fid,1,'uint16'); %14
                                arousal(r) = fread(fid,1,'uint16'); %14 - % Arousal (No,Yes: 0,1) 2 bytes
                                remainder(r,:) = fread(fid,2,'uint8');
                            end
                        elseif(bytes_per_record==52)
                            remainder = zeros(HDR.num_records,4,'uint8');

                            secondSignal = arousal; % related to respiratory 4 signal.

                            for r=1:HDR.num_records
                                start_sample(r) = fread(fid,1,'uint32'); % 4
                                stop_sample(r) = fread(fid,1,'uint32');  % 8

                                evtID(r,:) = fread(fid,2,'uint8'); % 10
                                snoreType(r) = fread(fid,1,'uint16'); %12 % ?
                                respRelated(r) = fread(fid,1,'uint16'); %14
                                arousal(r) = fread(fid,1,'uint16'); %16 - % Arousal (No,Yes: 0,1) 2 bytes
                                counter = fread(fid,1,'uint32');
                                padding = fread(fid,1,'uint32');
                                secondSignal(r) = fread(fid,1,'uint32');  % seen a three
                                fseek(fid,20,'cof');
                                remainder(r,:) = fread(fid,4,'uint8');
                            end
                        end
                        description = cell(HDR.num_records,1);
                        for r=1:HDR.num_records
                            subIDStr = '';
                            if(evtID(r,2)~=1)
                                subIDStr = sprintf(' SubID(%d)',evtID(r,2));
                            end
                            snoreStr = '';
                            if(snoreType(r)~=0)
                                snoreStr = sprintf(' SnoreType(%d)',snoreType(r));
                            end
                            if(respRelated(r)==4)
                                respStr = ' w/Respiratory';
                            elseif(respRelated(r)==0)
                                respStr = '';
                            else
                                respStr = sprintf(' w/%d',respRelated(r));
                            end
                           description{r} = strtrim(sprintf('%s%s%',subIDStr,snoreStr,respStr));
                        end

                    elseif(strcmpi(eventType,'stage'))
                         if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            a
                            fseek(fid,32,'bof');
                        end
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
                        stage = zeros(HDR.num_records,1);  %had been zeros(-1, HDR.num_records,1); on 12/6/2016
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            evtID(r,:) = fread(fid,2,'uint8');
                            stage(r) = evtID(r,2);
                            fseek(fid,bytes_per_record-intro_size,'cof');
                        end
                        stage = stage-1;
                        stage(stage==6)=5;
                        stage(stage==-1)=7;
                        samples_per_epoch = median(diff(start_sample));
                        embla_samplerate = samples_per_epoch/CLASS_codec.SECONDS_PER_EPOCH;
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

                    elseif(strcmpi(eventType,'tag'))
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            fseek(fid,32,'bof');
                            a(:,5:end)
                            a=fread(fid,[bytes_per_record/2,inf],'uint16')';
                            a(:,5:end)
                            fseek(fid,32,'bof');
                        end
                        intro_size = 8;

                        tagType = start_sample;
                        tagSubType = tagType;
                        tagSidePosition = tagType;
                        description = cell(HDR.num_records,1);

                        remainder = zeros(HDR.num_records,bytes_per_record-intro_size,'uint8');

                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            evtID(r,:) = fread(fid,2,'uint8'); %
                            tagType(r) = evtID(r,2);
                            tagSubType(r) = fread(fid,1,'uint8');
                            tagSidePosition(r) = fread(fid,1,'uint8');

                            remainder(r,:) = fread(fid,bytes_per_record-intro_size,'uint8'); %[0,0,43,{0,68,1}]
                            description{r} = strtrim(sprintf('%s %s %s',CLASS_codec.getTagType(tagType(r)),...
                                CLASS_codec.getTagSubType(tagSubType(r)),CLASS_codec.getTagSidePosition(tagSidePosition(r))));

                        end
                        stop_sample = start_sample+5*embla_samplerate_out; %make it 5 seconds for viewing


                    elseif(strcmpi(eventType,'user'))
                        if(false)
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record,inf],'uint8')';
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record/2,inf],'uint16')';
                            fseek(fid,32,'bof');
                            fseek(fid,32,'bof');
                            a=fread(fid,[bytes_per_record/4,inf],'uint32')';
                            fseek(fid,32,'bof');
                            a
                        end

                        fseek(fid,32,'bof');
                        remainder = cell(HDR.num_records,1);
                        description = cell(HDR.num_records,1);
                        intro_size = 10;
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            evtID(r,:) = fread(fid,2,'uint8'); % [4,1]
                            padding = fread(fid,1,'uint32'); % [0,0,0,0]

                            curRecord = fread(fid,(bytes_per_record-intro_size)/bytes_per_uint16,'uint16')';
                            descriptionStop = find(curRecord==0,1,'first');
                            description{r} = char(curRecord(1:descriptionStop-1));
                            remainder{r}=curRecord(descriptionStop:end);

                            % Old way
                            %                             %read until double 00 are encountered
                            %                             cur_loc = ftell(fid);
                            %                             curValue = 1;
                            %                             while(~feof(fid) && curValue~=0)
                            %                                 curValue = fread(fid,1,'uint16');
                            %                             end
                            %                             description_size = ftell(fid)-cur_loc;
                            %                             intro_size = 4+6+description_size;
                            %                             fseek(fid,-description_size,'cof'); %or fseek(fid,cur_loc,'bof');
                            %                             description{r} = fread(fid,description_size/2,'uint16=>char')';
                            %                             remainder{r} = fread(fid,bytes_per_record-intro_size,'uint8=>char')';
                            %remainder is divided into sections  with
                            %tokens of  [0    17     0   153     0     3
                            %1     9     0 ]
                        end
                        stop_sample = start_sample+5*embla_samplerate_out; %make it 5 seconds for viewing


                    end

                    start_stop_matrix = [start_sample(:)+1,stop_sample(:)+1]; %add 1 because MATLAB is one based
                    dur_sec = (start_stop_matrix(:,2)-start_stop_matrix(:,1))/embla_samplerate;
                    epoch = ceil(start_stop_matrix(:,1)/embla_samplerate/CLASS_codec.SECONDS_PER_EPOCH);

                    if(desired_samplerate>0)
                        start_stop_matrix = ceil(start_stop_matrix*(desired_samplerate/embla_samplerate));
                    end

                end
                embla_evt_Struct = CLASS_codec.makeEventStruct();
                embla_evt_Struct.HDR = HDR;
                embla_evt_Struct.type = eventType;
                embla_evt_Struct.start_stop_matrix = start_stop_matrix;
                embla_evt_Struct.start_sec = start_sec;
                embla_evt_Struct.stop_sec = stop_sec;
                embla_evt_Struct.dur_sec = dur_sec;
                embla_evt_Struct.epoch = epoch;
                embla_evt_Struct.stage = stage;
                embla_evt_Struct.evtID = evtID;
                if(~isempty(description))
                    embla_evt_Struct.description = description;
                end
                if(~isempty(remainder))
                    embla_evt_Struct.unknown = remainder;
                end

                fclose(fid);
            end
        end


        % =================================================================
        %> @brief Returns a stage event struct using input arguments.
        %> @param stage Row vector of staging values
        %> @param sampleRate
        %> @param HDR (optional) Header of corresponding EDF study.  If HDR
        %> is included the duration of the entire study will be taken from
        %> the HDR.duration_sec field and be used as the final/last stop
        %> value of the @c stop_sec field (and corresponding value of
        %> start_stop_matrix(end).  Otherwise, these values will be
        %> determined by assuming the last epoch is complete and lasts
        %> SECONDS_PER_EPOCH.
        %> @retval evt_Struct Struct for holding hynogram/staging data.
        %> Fields include:
        %> - @c HDR (optionally filled)
        %> - @c type = 'stage'
        %> - @c start_stop_matrix
        %> - @c start_sec
        %> - @c stop_sec
        %> - @c dur_sec
        %> - @c epoch
        %> - @c stage
        %> - @c description (empty)
        %> - @c unknown (empty)
        %> - @c channel (empty)
        % =================================================================
        function evt_Struct = makeStageEventStruct(stage, sampleRate,HDR)
            if(nargin<3)
                HDR = [];
            end
            evt_Struct = CLASS_codec.makeEventStruct('HDR',HDR,'type','stage','stage',stage(:));
            evt_Struct.epoch = (1:numel(stage))';

            if(~isempty(HDR) && isfield(HDR,'duration_sec'))
                duration_sec = HDR.duration_sec;
            else
                duration_sec = CLASS_codec.SECONDS_PER_EPOCH*evt_Struct.epoch(end);
            end

            evt_Struct.start_sec = (0:CLASS_codec.SECONDS_PER_EPOCH:duration_sec)';
            evt_Struct.stop_sec = evt_Struct.start_sec+CLASS_codec.SECONDS_PER_EPOCH;
            evt_Struct.stop_sec(end) = duration_sec;
            evt_Struct.dur_sec = repmat(CLASS_codec.SECONDS_PER_EPOCH,size(evt_Struct.epoch));

            evt_Struct.start_stop_matrix = [evt_Struct.start_sec,evt_Struct.stop_sec]*sampleRate;
            evt_Struct.start_stop_matrix(:,1) = evt_Struct.start_stop_matrix(:,1)+1; % MATLAB starts indexing at 1.
        end

        % =================================================================
        %> @brief Returns an empty event struct
        %> @retval evt_Struct Struct for holding event data.  Fields are empty and
        %> include:
        %> - @c HDR
        %> - @c type
        %> - @c start_stop_matrix
        %> - @c start_sec
        %> - @c stop_sec
        %> - @c dur_sec
        %> - @c epoch
        %> - @c stage
        %> - @c description
        %> - @c unknown
        %> - @c channel
        %> - @c samplerate
        %> - @c start_vec start time as a datevec
        %> - @c stop_vec stop time as a datevec
        % =================================================================
        function evt_Struct = makeEventStruct(varargin)
            names = {'HDR','type','start_stop_matrix','start_sec','stop_sec',...
                'dur_sec','epoch','stage','description','unknown','channel',...
                'samplerate','start_vec','stop_vec'};

            defaults = cell(size(names));
            values = defaults;
            [values{:}] = parsepvpairs(names,defaults,varargin{:});

            for n=1:numel(names)
                evt_Struct.(names{n}) = values{n};
            end

            if( ~isempty(evt_Struct.start_sec) && (~isempty(evt_Struct.stop_sec)||~isempty(evt_Struct.dur_sec)) )
                if(isempty(evt_Struct.dur_sec))
                    evt_Struct.dur_sec = evt_Struct.stop_sec-evt_Struct.start_sec;
                end
                if(isempty(evt_Struct.stop_sec))
                    evt_Struct.stop_sec = evt_Struct.start_sec+evt_Struct.dur_sec;
                end

                if(~isempty(evt_Struct.HDR) && isfield(evt_Struct.HDR,'T0'))
                    evt_Struct.startDateTime = evt_Struct.HDR.T0;  
                    numEvents = numel(evt_Struct.dur_sec);
                    t0_notSec = evt_Struct.HDR.T0(1:end-1);
                    t0_sec = evt_Struct.HDR.T0(end);
                    evt_Struct.start_vec = [repmat(t0_notSec,numEvents,1),t0_sec+evt_Struct.start_sec];
                    evt_Struct.stop_vec = [repmat(t0_notSec,numEvents,1),t0_sec+evt_Struct.stop_sec];
                end
            end

            hasStartStopSec = ~isempty(evt_Struct.start_sec) && ~isempty(evt_Struct.stop_sec);
            if(~isempty(evt_Struct.samplerate))
                if(~isempty(evt_Struct.start_stop_matrix) || hasStartStopSec)
                    if(~hasStartStopSec)
                        evt_Struct.start_sec = max(0,(evt_Struct.start_stop_matrix(:,1)-1)/evt_Struct.samplerate); % -1 b/c MATLAB is 1-based
                        evt_Struct.stop_sec = evt_Struct.start_stop_matrix(:,2)/evt_Struct.samplerate;

                        % Or perhaps do nothing if it already exists.  But
                        % what if it exists and is incorrect??? Enough.
                        evt_Struct.dur_sec = evt_Struct.stop_sec-evt_Struct.start_sec;
                    end
                    if(isempty(evt_Struct.start_stop_matrix))
                        evt_Struct.start_stop_matrix = [evt_Struct.start_sec(:), evt_Struct.stop_sec(:)]*evt_Struct.samplerate;
                        evt_Struct.start_stop_matrix(:,1) = evt_Struct.start_stop_matrix(:,1)+ 1; % +1 b/c MATLAB is 1-based
                    end
                end
            end

        end

        function [annotationsCell, header] = parseEDFPlusAnnotations(fileName)
            [annotationsCell, header ] =  getEDFPlusAnnotations(fileName);  % currently in ~/git/matlab/sleep
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
        %> @brief Parses time annotated lists (TALs) as events from a
        %> a single EDF annotation record.
        %> @param annRecord Struct containing one or more TALs as obtained
        %> from cell of EDF Annotation data obtained from getEDFPlusAnnotations.
        %> @param HDR Struct containing EDF Plus header data.  This is used
        %> to obtain sampling rate.
        %> @retval eventStructs Nx1 vector of structs.  See CLASS_codec.makeEventStruct
        %> for field names.
        % =================================================================
        function eventStructs = getEventsFromEDFAnnotationRecord(annRecord, HDR)
            if(numel(annRecord)==1)
                eventStructs = CLASS_codec.tal2evt(annRecord,HDR);
            else
                numTals = numel(annRecord);
                eventStructs = repmat(CLASS_codec.makeEventStruct(),numTals,1);
                for t=1:numTals
                    eventStructs(t) = CLASS_codec.tal2evt(annRecord(t),HDR);
                end
            end
        end

        % =================================================================
        %> @brief Translate one item of time annotated lists (TALs) to an event struct.
        %> @param tal A TAL item in a struct.  See getEDFPlusAnnotations.m
        %> @param HDR Struct containing EDF Plus header data.  This is used
        %> to obtain sampling rate.
        %> @retval eventStruct A struct with tal information.  See CLASS_codec.makeEventStruct
        %> for field names.
        % =================================================================
        function eventStruct = tal2evt(tal,HDR)
            startSec = tal.tal_start;
            durationSec = tal.duration;
            fs = max(HDR.samplerate);  %use the highest sampling rate available in the signal.  Otherwise you may run into issues of decimal precision sample indices.
            stageStrPrefixCount = numel('Sleep stage ');
            if(strncmpi(tal.annotation,'Sleep stage ',stageStrPrefixCount))
                stageStr = tal.annotation(stageStrPrefixCount+1:end);
                switch stageStr
                    case 'W'
                        stageVal = 0;
                    case 'N1'
                        stageVal = 1;
                    case 'N2'
                        stageVal = 2;
                    case 'N3'
                        stageVal = 3;
                    case 'N4'
                        stageVal = 4;
                    case 'R'
                        stageVal = 5;
                    otherwise
                        stageVal = 7;
                end

                cur_epoch = ceil(startSec/CLASS_codec.SECONDS_PER_EPOCH);
                %dur_epochs = ceil(durationSec/CLASS_codec.SECONDS_PER_EPOCH);
                % removed ('HDR',HDR,...) because the event struct here is
                % so small, perhaps containing 3 or 4 events at most, per
                % tal.  Repeated calls to tal2evt to get all tals parsed
                % results in multiple HDR fields with the same information,
                % which is a waste.
                eventStruct = CLASS_codec.makeEventStruct('samplerate',fs,...
                    'start_sec',startSec,'dur_sec',durationSec,'epoch',cur_epoch,...
                    'description',stageStr,'type','stage','stage',stageVal);
            else
                description = strtrim(strsplit(tal.annotation,':'));

                if(numel(description)>1)
                    channelStr = description{1};
                    description = description{2};
                else

                    description = description{1};
%                     if(strncmpi(description,'<EDF_XML',8))
%                         description = 'XML note';
%                         channelStr = []
%                     else
%                         channelStr = [];
%                     end

                        %<EDF_XMLnote>
                        %                     <Sauerstoffsättigungsabfall>
                        %                     <Value unit="%">3</Value>
                        %                     </Sauerstoffsättigungsabfall>
                        %                     </EDF_XMLnote>",

                    channelStr = 'unspecified';
                end
                description = strrep(description,'"','''');
                eventStruct = CLASS_codec.makeEventStruct('HDR',HDR,'samplerate',fs,...
                    'start_sec',startSec,'dur_sec',durationSec,...
                    'description',description,'type',channelStr);
            end

        end

        function  stageStruct = getStageStructFromEDFPlusFile(edfPlusFile)
            [annotationRecords, HDR] = getEDFPlusAnnotations(edfPlusFile);
            stageStruct = CLASS_codec.getStageStructFromEDFPlusAnnotations(annotationRecords,HDR);
        end

        % =================================================================
        %> @brief Parses the hypnogram from an annotations cell, as obtained
        %> from call to getEDFPlusAnnotations with an EDF Plus file, and returns
        %> it in a struct.
        %> @param annotations Cell of EDF Annotation data obtained from getEDFPlusAnnotations.
        %> @param HDR Struct containing EDF Plus header data.
        %> @retval stageStruct Struct containing the parsed hypnogram.
        %> @note See @makeStageEventStruct for stageStruct field names.
        % =================================================================
        function stageStruct = getStageStructFromEDFPlusAnnotations(annotations, HDR)

            num_epochs = ceil(HDR.duration_sec/CLASS_codec.SECONDS_PER_EPOCH);
            stage = repmat(7,num_epochs,1);
            % stageStartTime = zeros(size(stage));
            num_records = size(annotations,1);
            stageStrPrefixCount = numel('Sleep stage ');
            for r=1:num_records
                num_tals = size(annotations{r},1);
                for t=1:num_tals
                    tal = annotations{r}(t);
                    if(strncmpi(tal.annotation,'Sleep stage ',stageStrPrefixCount))
                        stageStr = tal.annotation(stageStrPrefixCount+1:end);
                        startTime = str2double(tal.tal_start);
                        duration = str2double(tal.duration);

                        switch stageStr
                            case 'W'
                                stageVal = 0;
                            case 'N1'
                                stageVal = 1;
                            case 'N2'
                                stageVal = 2;
                            case 'N3'
                                stageVal = 3;
                            case 'N4'
                                stageVal = 4;
                            case 'R'
                                stageVal = 5;
                            otherwise
                                stageVal = 7;
                        end

                        cur_epoch = floor(startTime/CLASS_codec.SECONDS_PER_EPOCH + 1);

                        dur_epochs = ceil(duration/CLASS_codec.SECONDS_PER_EPOCH);
                        stage(cur_epoch:cur_epoch+dur_epochs-1) = stageVal;
                        % fprintf('%u\n',stage);
                    else

                    end
                end
            end
            fs = max(HDR.samplerate);
            stageStruct = CLASS_codec.makeStageEventStruct(stage,fs,HDR);


        end

        % See also parseSTAGESEventFile
        function [evtStruct, stageVec] = parseSTAGEScsvFile(filenameIn, edfHDR, desiredSamplerate)
            evtStruct = struct();
            stageVec = [];
            if nargin<3
                desiredSamplerate = 100;
            end
            if(~exist(filenameIn,'file'))
                fprintf(2, 'Warning!  The file "%s" does not exist.  An empty struct will be returned.\n', filenameIn);
            else
                fid = fopen(filenameIn,'r');
                %-------/ .csv example contents \-------------------/
                % Start Time,Duration (seconds),Event
                % 20:16:00, 30.000, Wake
                % 20:16:13, 0.000, Custom User Event 4
                % 20:16:30, 30.000, Stage2
                % 20:16:51, 0.000, Calibration Start
                % 20:16:57, 0.000, Custom User Event 32, some extra comment
                % 20:17:00, 30.000, Stage2
                % 20:17:30, 30.000, Wake
                % 20:18:00, 30.000, Wake
                % 20:18:30, 30.000, Wake
                % 20:19:00, 30.000, Wake
                % 20:19:12, 0.000, Calibration End
                %---------------------------------------------------/
                % Debugging
                % str = '20:16:00, 30.000, Wake';
                % scanCell = textscan(str, '%{HH:mm:ss}D %f %s', 'delimiter',',');
                % evtStart = scanCell{1};
                % evtDuration = scanCell{2};
                % evtComment = strip(scanCell{3});
                %
                
                headerLine = fgetl(fid);
                headerLineStripped = strrep(headerLine,' ','');
                expectedHeaderLine = strrep('Start Time,Duration (seconds),Event',' ','');
                
                if ~strcmpi(headerLineStripped, expectedHeaderLine)
                    fclose(fid);
                    error('Unexpected header line "%s", found in %s', headerLine, filenameIn);
                else
                    % scanCell = textscan(fid, '%{HH:mm:ss}D %f %s', 'delimiter',',');
                    scanCell = textscan(fid, '%{hh:mm:ss}T %f %[^\n]', 'delimiter',',');  % T is for duration
                    fclose(fid);
                    if(isempty(scanCell{1}))
                        fprintf('Warning!  The file ''%s'' could not be parsed!\nAn empty struct will be returned.',filenameIn);
                    else
                        % STAGES = CLASS_codec.stages2STAGES(stages,num_epochs, default_unknown_stage);
                        evtStart = datenum(scanCell{1});
                        firstEvtStart = evtStart(1);
                        evtDurationSec = scanCell{2};
                        evtComment = strip(scanCell{3});
                        
                        custom_idx = startsWith(evtComment, 'custom', 'IgnoreCase', true);
                        evtStart(custom_idx) = [];
                        evtDurationSec(custom_idx) = [];
                        evtComment(custom_idx) = [];
                        
                        studyStart = datenum(edfHDR.T0);
                        studyStartDay = floor(studyStart);
                        studyStartTime = mod(studyStart, 1);
                        
                        [~, min_start_idx] = min(evtStart);                        
                        evtStart = evtStart + studyStartDay;
                        
                        % In cases where the events occur before the study 
                        if studyStartTime > 22/24 && firstEvtStart < 2/24 % firstEvtStart < studyStartTime &&  firstEventStart < 1/24
                            evtStart = evtStart+1; %  we are actually starting on the following day then in this case. Or we have events that occur before the study started :( that is an issue if possible.  See STNF00423.edf for problematic study which has events starting at 20.55.00 and the edf starting at 20.55.15
                        elseif ~isempty(min_start_idx) && min_start_idx > 1
                            % This is where we conceivably went past midnight.
                            evtStart(min_start_idx:end) = evtStart(min_start_idx:end)+1;
                        end
                        
                        datenumPerSec = datenum([0, 0, 0, 0, 0, 1]);
                        evtStartSec = (evtStart - studyStart)/datenumPerSec;
                                               
                        stageInd = contains(evtComment,'Stage','ignorecase', true) | strcmpi(evtComment, 'REM') | strcmpi(evtComment, 'Wake');
                        evtInd = ~stageInd;
                        
                        try
                            evtStruct = CLASS_codec.makeEventStruct('HDR', edfHDR, 'samplerate', desiredSamplerate, 'start_sec', evtStartSec(evtInd), 'dur_sec', evtDurationSec(evtInd), 'description', evtComment(evtInd));
                        catch me
                            showME(me);
                        end
                        
                        evtStruct.startDateTime = edfHDR.T0;
                        standard_epoch_sec = CLASS_codec.SECONDS_PER_EPOCH;
                        num_epochs = ceil(edfHDR.duration_sec/standard_epoch_sec);
                        
                        % parse the stages
                        stageVec = repmat(7, num_epochs, 1);
                        if ~isempty(stageInd) && any(stageInd)
                            
                            % Create a numeric stage score vector
                            stageStr = {'Wake'          % 0
                                'Stage1'        % 1
                                'Stage2'        % 2
                                'Stage3'        % 3
                                'Stage4'        % 4
                                'REM'           % 5
                                % 'UnknownStage'  % 7
                                };
                            
                            evtStageLabels = evtComment(stageInd);
                            evtStageVec = repmat(7, size(evtStageLabels));
                            
                            for s=1:numel(stageStr)
                                score = s-1;
                                evtStageVec(strcmpi(evtStageLabels, stageStr(s))) = score;
                            end
                            
                            evtStageStartSec = evtStartSec(stageInd);
                            evtStageStartEpoch = floor(evtStageStartSec/standard_epoch_sec)+1;  % make sure 30 second is epoch 2, and 0 seconds is epoch 1.  
                            
                            evtStageDurationSec = evtDurationSec(stageInd);
                            
                            if sum(evtStageDurationSec)==0
                                evtStageDurationSec(:) = standard_epoch_sec;
                                fprintf('Setting stage durations to % d\n', standard_epoch_sec);
                            end
                            badEpochs = evtStageDurationSec == 0 | evtStageStartSec < 0; % check any that start before the edf as well (problem with STNF studies for example)
                            
                            if any(badEpochs)
                                evtStageStartEpoch(badEpochs) = [];
                                evtStageDurationSec(badEpochs) = [];
                                evtStageVec(badEpochs) = [];
                            end
                            
                            evtStageDurationEpoch = ceil(evtStageDurationSec/standard_epoch_sec);                            
                            evtStageStopEpoch = evtStageStartEpoch+evtStageDurationEpoch-1;
                            
                            maxEpoch = max(evtStageStopEpoch);
                            if maxEpoch>num_epochs
                                fprintf(2, 'Warning: The number of epochs scored (%d) exceeds the number of epochs found in the EDF (%d): %s\n', maxEpoch, num_epochs, filenameIn);
                                % Place a ceiling on the stop epoch so we don't crash our for loop below.
                                evtStageStopEpoch(evtStageStopEpoch>num_epochs) = num_epochs;
                            end
                            
                            stageVec = repmat(7,num_epochs,1);
                            epochVec = (1:num_epochs)';
                            
                            for e=1:numel(evtStageVec)
                                start_epoch = evtStageStartEpoch(e);
                                if start_epoch <= num_epochs
                                    stop_epoch = evtStageStopEpoch(e);
                                    score_epoch = evtStageVec(e);
                                    stageVec(start_epoch:stop_epoch) = score_epoch;
                                end
                            end  
                            
                            lightsOn_idx = startsWith(evtComment, 'LightsOn', 'IgnoreCase', true);
                            lightsOff_idx = startsWith(evtComment, 'LightsOff', 'IgnoreCase', true);                            
                            
                            lightsOffStartSec = evtStartSec(lightsOff_idx);
                            lightsOffEpoch = floor(lightsOffStartSec/standard_epoch_sec)+1;                            

                            lightsOnStartSec = evtStartSec(lightsOn_idx);
                            lightsOnEpoch = floor(lightsOnStartSec/standard_epoch_sec)+1;
                            
                            cur_epoch = 0;
                            for e=1:min([numel(lightsOffEpoch), numel(lightsOnEpoch)])                                
                                stageVec(cur_epoch+1:lightsOffEpoch(e)-1)=7;
                                cur_epoch = lightsOnEpoch(e)-1;
                            end
                            
                            if cur_epoch>0 && cur_epoch<numel(stageVec)
                               stageVec(cur_epoch+1:end)=7; 
                            end
                            
                            evtStruct.epoch = epochVec;
                            evtStruct.stage = stageVec;
                        end
                    end
                end
            end
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
        %> @note The stageVec is ordered by epoch from 1:N sequentially, 1
        %> epoch increase per row  (i.e. stageVec(2) is the stage for epoch
        %> 2, and stageVec(N) is the stage for the Nth epoch.  It is
        %> possible that the stageVec is shorter than the recorded file.  In
        %> this case, it is necessary for the calling member to add
        %> addtional epochs as unknown (e.g. 7).
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

                headerLine1 = fgetl(fid);

                scanCell = textscan(fid,'%f %f %s %s %q %s','delimiter',',','commentstyle','#','headerlines',1);  %used to be 2, but now I retrieve the first line in case there is additional information there.
                fclose(fid);

                if(isempty(scanCell{1}))
                    fprintf('Warning!  The file ''%s'' could not be parsed!\nAn empty struct will be returned.',filenameIn);
                    SCOStruct = [];
                    stageVec = [];
                else

                    fsCell = regexp(headerLine1,'#\s*\w+=(?<samplerate>\d+(\.\d+)?)','names');
                    if(~isempty(fsCell))
                        SCOStruct.samplerate = str2double(fsCell.samplerate);
                    else
                        SCOStruct.samplerate = [];
                    end

                    % parse the stages first
                    stageInd = strncmpi(scanCell{6},'stage',5);

                    if(isempty(stageInd) || ~any(stageInd))
                        stageVec = [];

                        if(isempty(SCOStruct.samplerate))
                           SCOStruct.samplerate = getSamplerateDlg();
                        end
                    else
                        stageStartStopSamples = [scanCell{1}(stageInd),scanCell{2}(stageInd)];
                        stageStartStopDatenums =  [datenum(scanCell{3}(stageInd),'HH:MM:SS.FFF'),datenum(scanCell{4}(stageInd),'HH:MM:SS.FFF')];
                        stageDurSecs = datevec(stageStartStopDatenums(:,2)-stageStartStopDatenums(:,1))*[0;0;24*60;60;1;1/60]*60;
                        %epochDurSec = datevec(diff(stageStartStopDatenums(1,:)))*[0;0;24*60;60;1;1/60]*60;
                        stageDurSamples = stageStartStopSamples(:,2)-stageStartStopSamples(:,1)+1;
                        if(isempty(SCOStruct.samplerate))

                            % Sometimes that stop sample extends to the next start sample
                            % due to a systematic conversion problem in
                            % events files received from Huneo.
                            if(size(stageStartStopSamples,1)>1)

                                if(stageStartStopSamples(1,2)==stageStartStopSamples(2,1))
                                    stageStartStopSamples(:,2) = stageStartStopSamples(:,2) -1;
                                    stageDurSamples = stageDurSamples - 1;
                                end
                            end
                            SCOStruct.samplerate = stageDurSamples(1)/stageDurSecs(1);
                        end

                        % Sort the stages just to be sure now.
                        [lastStageSample, finalStopIndex] = max(stageStartStopSamples(:,2));
                        stageStartStopEpochs = floor(stageStartStopSamples/SCOStruct.samplerate/CLASS_codec.SECONDS_PER_EPOCH)+1;
                        numEpochs = stageStartStopEpochs(finalStopIndex,end);

                        %numStagedEpochs =  (finalStartValue+stageDurSamples(finalStartIndex))/SCOStruct.samplerate/CLASS_codec.SECONDS_PER_EPOCH; %30 second epcohs

                        %numEpochs = ceil(lastStageSample/SCOStruct.samplerate/CLASS_codec.SECONDS_PER_EPOCH);
                        stageStr = strrep(strrep(strrep(strrep(scanCell{5}(stageInd),'"',''),'Stage ',''),'REM','5'),'Wake','0');
                        stageStr = strrep(stageStr,'N','');  %These were added with Innsbruck files
                        stageStr = strrep(stageStr,'W','0');
                        stageStr = strrep(stageStr,'R','5');

                        stageNum = str2double(stageStr);

                        %                         stageStr(cellfun(@isempty,stageStr))={num2str(missingStageValue)};

                        %fill in any missing stages with 7.
                        missingStageValue = default_unknown_stage;
                        stageVec = repmat(missingStageValue,numEpochs,1);

                        for s=1:size(stageStartStopEpochs)
                            stageVec(stageStartStopEpochs(s,1):stageStartStopEpochs(s,2)) = stageNum(s);
                        end
                        %stageStartEpochs = stageStartStopSamples(:,1)/epochDurSamples+1;  %evts file's start samples begin at 0; 0-based nubmer, but MATLAB indexing starts at 1.
                        %stageVec(stageStartEpochs) = str2double(stageStr);  % or, equivalently, str2num(cell2mat(stageStr));

                        % Sometimes we get '' as a stage value, and these
                        % are converted to nan by str2double.

                        stageVec(isnan(stageVec)) = missingStageValue;
                        %                 y = [eventStruct.epoch,eventStruct.stage];
                        %                 staFilename = fullfile(outPath,strcat(studyID,'STA'));
                        %                 save(staFilename,'y','-ascii');
                    end

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
                fprintf(2, 'Warning!  The file ''%s'' does not exist and was not parsed!\nAn empty struct will be returned.\n',filenameIn);
                SCOStruct = [];
                stageVec = [];
            end
        end

        function [evtStruct, STAGES] = parseWSCexportFile(filenameIn,unknown_stage_label)
            if(nargin<2)
                default_unknown_stage = 7;
            else
                default_unknown_stage = unknown_stage_label;
            end

            evtStruct = [];
            STAGES = [];
            if(exist(filenameIn,'file'))
                fid = fopen(filenameIn,'r');
                %%---/ Contents of an .export.csv file (first 3 lines): %-----------------------/
                %;;;
                %;1.0; 22:41:30.00;Start Recording
                %;1.0; 22:41:30.00;New Montage - NPSG Standard Plus
                %----------------------------------------------/

                frewind(fid);
                a = textscan(fid, ';%f;%[^;];%[^\n\r]','headerlines',1);

                fclose(fid);
                epoch = a{1};
                start_time = a{2};
                description = a{3};
                start_datenum = datenum(start_time,'HH:MM:SS.FFF');

                if(isempty(epoch))
                    fprintf(2,'Warning!  The file ''%s'' could not be parsed!\nAn empty struct will be returned.\n',filenameIn);
                else

                    % parse the stages first
                    stageInd = strncmpi(description,'stage',5); % logical indexing vector

                    if(~isempty(stageInd) && any(stageInd))
                        stage_epochs = epoch(stageInd);
                        stage_descriptions = description(stageInd);
                        stage_start_datenum = start_datenum(stageInd);
                        stage_start_times = start_time(stageInd);

                        evtStruct.epoch = epoch(~stageInd);
                        evtStruct.description = description(~stageInd);
                        evtStruct.start_time = start_time(~stageInd);
                        evtStruct.start_datenum = start_datenum(~stageInd);

                        % last_staged_epoch = max(epoch(stageInd));
                        % first_staged_epoch = min(epoch(stageInd));
                        % num_staged_epochs = last_staged_epoch-first_staged_epoch+1;
                        num_epochs = max(epoch);

                        %numEpochs = ceil(lastStageSample/SCOStruct.samplerate/CLASS_codec.SECONDS_PER_EPOCH);
                        stageStr = strtrim(strrep(strrep(strrep(strrep(strrep(stage_descriptions,'"',''),'Stage',''),'REM','5'),'Wake','0'),'-',''));
                        stageStr = strrep(stageStr,'No','7'); % this is the 'No Stage'
                        stageStr = strrep(stageStr,'N','');  %These were added with Innsbruck files
                        stageStr = strrep(stageStr,'W','0');
                        stageStr = strrep(stageStr,'R','5');

                        stageNum = str2double(stageStr);

                        lights_on_index = strcmpi(evtStruct.description,'Lights On');

                        if(isempty(lights_on_index))
                            last_lights_on_epoch = max(stage_epochs);
                        else
                            last_lights_on_epoch = evtStruct.epoch(lights_on_index);
                        end

                        last_scored_epoch = max(last_lights_on_epoch, max(stage_epochs));

                        %fill in any missing stages with 7.
                        missingStageValue = default_unknown_stage;
                        stageVec = repmat(missingStageValue,last_scored_epoch,1);

                        stage_start_epochs = stage_epochs;
                        stage_end_epochs = [stage_epochs(2:end)-1; last_scored_epoch];
                        stageStartEndEpochs = [stage_start_epochs, stage_end_epochs];
                        for s=1:size(stageStartEndEpochs)
                            stageVec(stageStartEndEpochs(s,1):stageStartEndEpochs(s,2)) = stageNum(s);
                        end
                        %stageStartEpochs = stageStartStopSamples(:,1)/epochDurSamples+1;  %evts file's start samples begin at 0; 0-based nubmer, but MATLAB indexing starts at 1.
                        %stageVec(stageStartEpochs) = str2double(stageStr);  % or, equivalently, str2num(cell2mat(stageStr));

                        % Sometimes we get '' as a stage value, and these
                        % are converted to nan by str2double.

                        stageVec(isnan(stageVec)) = missingStageValue;
                        STAGES = CLASS_codec.stages2STAGES(stageVec, num_epochs);

                        %                 y = [eventStruct.epoch,eventStruct.stage];
                        %                 staFilename = fullfile(outPath,strcat(studyID,'STA'));
                        %                 save(staFilename,'y','-ascii');
                    end


                end
            else
                fprintf('Warning!  The file ''%s'' does not exist and was not parsed!\nAn empty struct will be returned.',filenameIn);
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
            end

            fclose(fid);
        end


        %> @brief searches through the roc_struct to find the best possible configurations in terms of sensitivity and specificity and K_0_0, and K_1_0
        %> the roc_struct fields are ordered first by study name and then
        %> by configuration
        %> @param roc_struct
        %> @retval roc_struct Struct with same fields as input roc_struct and also
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
           end

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
           end
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

        function respStr = getRespType(rint)
            switch(rint)
                case 1
                    respStr = 'Apnea';
                case 2
                    respStr = 'Hypopnea';
                case 5
                    respStr = 'RERA'; %respiratory effort related arousal
                otherwise
                    respStr = '';
            end
        end

        function respMedtypeStr = getRespMediatedType(rint)
            switch(rint)
                case 1
                    respMedtypeStr = 'Central';
                case 2
                    respMedtypeStr = 'Mixed';
                case 3
                    respMedtypeStr = 'Obstructive';
                otherwise
                    respMedtypeStr = '';
            end
        end

        function assocStr = getRespAssociation(rint)
            switch(rint)
                case 0
                    assocStr = '';
                case 1
                    assocStr = 'w/Arousal';
                case 32
                    assocStr = 'w/Desat';
                case 33
                    assocStr = 'w/Arousal w/Desat';
                otherwise
                    assocStr = sprintf('w/%d',rint);
            end
        end

        function tagStr = getTagType(tagInt)
            tagCell = {'Lights'
                'Bathroom';
                'Tech';
                'Position';
                'Cough';
                'Feeding';
                };
            try
                tagStr = tagCell{tagInt};
            catch me
                tagStr = '';
            end
        end

        function tagSubStr = getTagSubType(tagInt)
            tagCell = {'On'
                'Off';
                'In';
                'Out';
                'Prone';
                'Supine';
                'Side';
                };
            try
                tagSubStr = tagCell{tagInt};
            catch me
                tagSubStr = '';
            end
        end
        function posStr = getTagSidePosition(tagInt)
            tagCell = {'Left'
                'Right';
                };
            try
                posStr = tagCell{tagInt};
            catch me
                posStr = '';
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
