classdef CLASS_converter < handle
    properties(Constant)
        events_pathname = '_events';
        EDFHDRSignalFields = {'label','transducer','physical_dimension','physical_minimum','physical_maximum','digital_minimum','digital_maximum','prefiltering','number_samples_in_each_data_record'};
    end
    properties
        srcPath;
        destPath;
        prefixStr; 
        srcType; %can be 'tier','flat','group','layer'
    end
    
    %> Must be implemented by instantiating class        
    methods(Abstract)
        convert2wsc(obj)
        mappedFilename = srcNameMapper(obj,srcFilename,mappedFileExtension)
        [dualchannel, singlechannel, unhandled] = getMontageConfigurations(obj)
    end
    
    methods(Abstract,Static)
    end
    
    
    methods
        
        %> @brief generates the mapping file for each conversion.  The
        %> mapping file helps audit cohort transcoding by placing the source
        %> .psg filename on the same line with the generated .EDF, .SCO, and
        %> .STA files (as applicable) during the conversion process.        
        %> @brief generates the mapping file for each conversion.  The
        %> mapping file helps audit cohort transcoding by placing the source
        %> .psg filename on the same line with the generated .EDF, .SCO, and
        %> .STA files (as applicable) during the conversion process.
        function generateMappingFile(obj)
            mapFilename = obj.getMappingFilename();
            fid = fopen(mapFilename,'w+');
            psgExt = '.edf';
            if(fid>0)
                try
                    if(strcmpi(obj.srcType,'group'))
                        
                        [~,edfPathnames] = getPathnames(obj.srcPath);
                        
                        for d=1:numel(edfPathnames)
                            fnames = getFilenamesi(edfPathnames{d},psgExt);
                            for f=1:numel(fnames)
                                srcFilename = fnames{f};
                                destFilename = obj.srcNameMapper(srcFilename,'EDF');
                                fprintf(fid,'%s\t%s\n',srcFilename,destFilename);
                            end
                        end
                        fclose(fid);
                    elseif(strcmpi(obj.srcType,'tier'))
                            [~,edfPathnames] = getPathnames(obj.srcPath);
                            
                            for f=1:numel(edfPathnames)
                                srcFilename = getFilenamesi(edfPathnames{f},psgExt);
                                srcFilename = char(srcFilename);
                                destFilename = obj.srcNameMapper(srcFilename,'EDF');
                                fprintf(fid,'%s\t%s\n',srcFilename,destFilename);                                
                            end
                            fclose(fid);
                    elseif(strcmpi(obj.srcType,'flat'))
                        fnames = getFilenamesi(obj.srcPath,psgExt);
                        for f=1:numel(fnames)
                            srcFilename = fnames{f};
                            destFilename = obj.srcNameMapper(srcFilename,'EDF');
                            fprintf(fid,'%s\t%s\n',srcFilename,destFilename);
                        end
                        
                        fclose(fid);
                    else
                        fprintf('This source type (%s) is not supported!',obj.srcType);
                        fclose(fid);
                    end
                catch me
                    showME(me);
                    fclose(fid);
                end
            else
                fprintf('Error!  Could not open %s for writing.\n',mapFilename);
            end
        end
        
        
        function mapFilename = getMappingFilename(obj)
            mapFilename = strcat(obj.prefixStr,'.map');
        end
        
        %Normalizes the destination files montage for single channel
        %configurations.
        function [newLabels, newLabelIndices] = getSingleMontageConfigurations(obj,fullDestFile)
            [~, singleChannel, ~] = obj.getMontageConfigurations();
            HDR = loadEDF(fullDestFile);
            
            newLabels = {};
            newLabelIndices = [];
            for d = 1:numel(singleChannel)
                curChannelLabels = singleChannel{d};
                for n=1:numel(curChannelLabels)-1
                    index = find(strcmpi(curChannelLabels{n},HDR.label));
                    
                    if(~isempty(index))
                        newLabelIndices(end+1) = index;
                        newLabels{end+1} = curChannelLabels{end};
                        break;
                    end
                end
            end
        end
        
        %mergeHDRentries is empty if there are no dual channel
        %configurations found in the EDF of the provided source file
        %mergeIndices is a two column vector containing the indices of the
        %EDF signals to combine (i.e., channel at mergeIndices(1) - channel
        %at mergeIndices(2).
        function [mergedHDREntries, mergeIndices] = getDualMontageConfigurations(obj,fullSrcFile)
            [dualChannel, ~, ~] = obj.getMontageConfigurations();
            HDR = loadEDF(fullSrcFile);
            
            mergedHDREntries = [];
            mergeIndices = [];
            mergeLabels = {};
            %check for EDF's and dual configurations if necessary
            for d = 1:numel(dualChannel)
                index1 = find(strcmpi(HDR.label,dualChannel{d}{1}));
                index2 = find(strcmpi(HDR.label,dualChannel{d}{2}));
                if(~isempty(index1) && ~isempty(index2))
                    mergeIndices(end+1,:) = [index1,index2];
                    mergeLabels{end+1} = dualChannel{d}{3};
                end
            end
            
            %remove any repetitions (e.g. C3-A2 -> C3-Ax and C3-A1 -> C3-Ax)
            if(~isempty(mergeLabels))
                [mergedLabels,i] =unique(mergeLabels);
                mergedLabels = mergedLabels(:);
                mergeIndices = mergeIndices(i,:);
                primaryIndices = mergeIndices(:,1);
                mergedHDREntries = CLASS_converter.extractEDFHeader(HDR,primaryIndices);
                mergedHDREntries.label = mergedLabels;
                %                 for n=1:numel(CLASS_converter.EDFHDRSignalFields)
                %                     curFieldname = CLASS_converter.EDFHDRSignalFields{n};
                %                     if(~strcmpi(curFieldname,'label'))
                %                         mergedHDREntries.(curFieldname) = HDR.(curFieldname)(primaryIndices);
                %                     end
                %                 end
            end
        end
        
        %> @brief export Grouped edf path - exports .EDF files found in subdirectories of the
        %> source directory.
        function exportGroupedEDFPath(obj)
            [~,edfPathnames] = getPathnames(obj.srcPath);
            for d=1:numel(edfPathnames)
                obj.exportFlatEDFPath(obj,edfPathnames{d})
            end            
        end

        %transfers .EDF files from their full source file to the full destination file given
        %dual channel montage configurations are combined first
        %single channel labels are normalized using list of names
        function exportEDF(obj,fullSrcFile,fullDestFile)
            
            %dual channel configurations are first reduced to single channels and
            %data is sent to destPath
            
            %returns two column array of indices to combine (each row
            %represents a unqiue channel that is formed by taking the
            %difference of EDF signal from the per row indices
            [mergeHDRentries, mergeIndices] = obj.getDualMontageConfigurations(fullSrcFile);
            
            if(isempty(mergeHDRentries))
                [success] = copyfile(fullSrcFile,fullDestFile);
            else                
                [success] = CLASS_converter.rewriteEDF(fullSrcFile,fullDestFile,mergeIndices,mergeHDRentries);
            end
            
            %destPath .EDF file headers are relabeled in place            
            if(success)
                [newLabels, newLabelIndices] = obj.getSingleMontageConfigurations(fullDestFile);
                if(~isempty(newLabels))
                    [success] = CLASS_converter.rewriteEDFHeader(fullDestFile,newLabelIndices,newLabels);
                    if(~success)
                        fprintf('An error occurred when relabeling channel names in the EDF header of %s.\n',fullDestFile);
                    end
                end
            else
                fprintf('Could not export %s.  An error occurred.\n',fullSrcFile);
            end
        end      
        
        %> @brief export flat edf path - exports a directory containing .EDFs listed
        %> flatly (i.e. not in subdirectories)
        function exportFlatEDFPath(obj,optionalSrcPath)
            
            %the optional 'optionalSrcPath' variable allows the flat EDF
            %path method to be used by the Grouped EDF path method.
            if(nargin<2 || isempty(optionalSrcPath))
                [srcFilenames,fullSrcFilenames] = getFilenamesi(obj.srcPath,'\.edf');
                
            else
                [srcFilenames,fullSrcFilenames] = getFilenamesi(optionalSrcPath,'\.edf');            
            end
            if(~isdir(obj.destPath))
                mkdir(obj.destPath);
            end
            
            if(isdir(obj.destPath))
                %make sure the source and destination paths are not the same...
                if((nargin>2 && ~isempty(optionalSrcPath) && strcmpi(optionalSrcPath,obj.destPath)) || strcmpi(obj.srcPath,obj.destPath))
                    fprintf(1,'Will not convert files when source and destination path are identical (%s)\n',obj.destPath);
                else
                    for f=1:numel(srcFilenames)
                        srcFile = srcFilenames{f};
                        if(nargin>1 && isa(obj.srcNameMapper,'function_handle'))
                            destFilename = obj.srcNameMapper(srcFile,'.EDF');
                            fullDestFilename = fullfile(obj.destPath,destFilename);
                        else
                            fullDestFilename = fullfile(obj.destPath,srcFile);
                        end
                        try
                            if(exist(fullSrcFilenames{f},'file'))
                                
                                obj.exportEDF(fullSrcFilenames{f},fullDestFilename);
                            else
                                fprintf('Could not export %s.  File not found.\n',fullSrcFile);
                            end
                        catch me
                            showME(me);
                        end
                    end
                end
            else
                fprintf('Could not create the destination path (%s).  Check your system level permissions.\n',obj.destPath);
            end
        end
        
        function emblaEvtExport(obj,emblaStudyPath, outPath, regularexpressions,outputType)
            %outputType is 'sco','evt','sta','all' {default}, 'db','edf'
            %db is database
            %sco is .SCO format
            %sta is .STA file formats   
            %EDF is .EDF 
            if(nargin<4)
                outputType = 'all';
            end
            pathnames = getPathnames(emblaStudyPath);
            unknown_range = '0000';
            
            if(~iscell(regularexpressions))
                regularexpressions = {regularexpressions};
            end
            
            studyStruct = CLASS_converter.getSEVStruct();
            studyStruct.samplerate = 256;
            
            for e=1:numel(regularexpressions)
                %matched files
                exp = regexp(pathnames,regularexpressions{e},'names');
                for s=1:numel(exp)                    
                    cur_exp = exp{s};                    
                    if(~isempty(cur_exp))
                        try
                            
                            srcFile = [pathnames{s},'.edf'];
                            
                            edfSrcPath = fullfile(emblaStudyPath,pathnames{s});
                            
                            studyID = obj.srcNameMapper(srcFile,'');
                            
                            fullSrcFile = fullfile(edfSrcPath,srcFile);
                            
                            HDR = loadEDF(fullSrcFile);
                            studyStruct.startDateTime = HDR.T0;
                            
                            num_epochs = ceil(HDR.duration_sec/studyStruct.standard_epoch_sec);
                            
                            stage_evt_file = fullfile(edfSrcPath,'stage.evt');
                            if(exist(stage_evt_file,'file'))
                                
                                [stageEventStruct,embla_samplerate] = CLASS_events_container.parseEmblaEvent(stage_evt_file,studyStruct.samplerate,studyStruct.samplerate);
                                studyStruct.samplerate = embla_samplerate;  %embla_samplerate is the source sample rate determined from the stage.evt file which we know/assume to use 30 seconds per epoch.
                                
                                if(num_epochs~=numel(stageEventStruct.epoch))
                                    %                         fprintf(1,'different stage epochs found in %s\n',studyname);
                                    if(any(strcmpi(outputType,{'STA','All'})))
                                        fprintf(1,'%s\texpected epochs: %u\tencountered epochs: %u to %u\n',srcFile,num_epochs,min(stageEventStruct.epoch),max(stageEventStruct.epoch));
                                    end
                                    
                                    new_stage = repmat(7,num_epochs,1);
                                    new_epoch = (1:num_epochs)';
                                    new_stage(stageEventStruct.epoch)=stageEventStruct.stage;
                                    stageEventStruct.epoch = new_epoch;
                                    stageEventStruct.stage = new_stage;
                                end
                                
                                if(strcmpi(outputType,'STA') || strcmpi(outputType,'all'))
                                    y = [stageEventStruct.epoch,stageEventStruct.stage];
                                    staFilename = fullfile(outPath,strcat(studyID,'STA'));
                                    save(staFilename,'y','-ascii');
                                end
                                
                                if(~strcmpi(outputType,'STA'))
                                    
                                    if(strcmpi(outputType,'EDF'))
                                        %export the .EDF
                                        obj.EDFexport(fullSrcFile,outPath);
                                        
                                    else
                                        events_container_obj = CLASS_events_container.importEmblaEvtDir(edfSrcPath,embla_samplerate);
                                        studyStruct.line = stageEventStruct.stage;
                                        studyStruct.cycles = scoreSleepCycles_ver_REMweight(studyStruct.line);
                                        events_container_obj.setStageStruct(studyStruct);
                                        
                                        if(strcmpi(outputType,'sco') || strcmpi(outputType,'all'))
                                            scoFilename = fullfile(outPath,strcat(studyID,'SCO'));
                                            events_container_obj.save2sco(scoFilename);
                                        end
                                        
                                        if(strcmpi(outputType,'evt') || strcmpi(outputType,'all'))
                                            %avoid the problem of file
                                            %names like : evt.studyName..txt
                                            if(studyID(end)=='.')
                                                studyID = studyID(1:end-1);
                                            end
                                            events_container_obj.save2txt(fullfile(outPath,strcat('evt.',studyID)));
                                        end
                                        
                                        if(strcmpi(outputType,'evts') || strcmpi(outputType,'all'))
                                            %avoid the problem of file
                                            %names like : evt.studyName..txt
                                            if(studyID(end)=='.')
                                                studyID = studyID(1:end-1);
                                            end
                                            events_container_obj.loadEmblaEvent(stage_evt_file,embla_samplerate);
                                            events_container_obj.save2evts(fullfile(outPath,strcat(studyID,'.EVTS')));
                                        end                                        
                                        %                                     if(strcmpi(outputType,'db') || strcmpi(outputType,'all'))
                                        %                                         %ensure there is a record of it in
                                        %                                         %the database !!!
                                        %                                         %       CLASS_events_container.import_evtFile2db(dbStruct,ssc_edf_path,ssc_evt_path);
                                        %
                                        %                                     end
                                    end
                                end
                            else
                                fprintf(1,'%s\tNo stage File found\n',srcFile);
                            end
                            
                        catch me
                            showME(me);
                            fprintf(1,'%s (%u) - Fail\n',srcFile,s);
                        end
                    end
                end
            end
        end
    end
    
    methods (Static)       
        
        function [channelNames, channelNamesAll] = getAllChannelNames(psgPath)
            if(nargin<1)
                msg_string = 'Select directory with .EDFs';
                psgPath =uigetdir(pwd,msg_string);
                if(isnumeric(psgPath) && ~psgPath)
                    psgPath = [];
                end
            end  
            
            files = getFilenames(psgPath,'*.EDF');            
            channelNames = {};            
            
            channelNamesAll = cell(numel(files),1);
            for f=1:numel(files)
                srcFile = files{f};
                fullSrcFile = fullfile(psgPath,srcFile);
                if(exist(fullSrcFile,'file'))
                    HDR = loadEDF(fullSrcFile);
                    channelNames = union(channelNames,HDR.label);                    
                    channelNamesAll{f} = HDR.label;
                end
            end
            
            disp(char(channelNames));            
            
        end
        
        function [dualchannel, singlechannel, unhandled] = getMontageConfigurationsMROS()
            unhandled ={};
            dualchannel = {
                %                 {'Leg L','Leg R','L/RAT'}
                {'L Chin','R Chin','L Chin-R Chin'}
                {'ECG L','ECG R','ECG L-ECG R'}
                {'C4','A1','C4-A1'}
                {'C3','A2','C3-A2'}
                {'LOC','A2','LOC-A2'}
                {'ROC','A1','ROC-A1'}
                };
            singlechannel = {
                {'SAO2','SaO2','SpO2'};
                {'HR','Heart Rate'};
                };
        end
        
        
        function [dualchannel, singlechannel, unhandled] = getMontageConfigurationsAPOE()
            
            unhandled ={
                {'Cannula'}
                {'Airflow'}
                {'PAP Tidal Volume'}
                {'T3-O1'}
                {'T4-O2'}
                {'C3-O1'}
                {'C3-AVG'}
                };

            dualchannel = {
                {'LAT','RAT','L/RAT'}
                {'O1','A2','O1-A2'}
                {'O2','A1','O2-A1'}
                {'C3','A1','C3-A1'}
                {'C3','A2','C3-A2'}
                {'C4','A1','C4-A1'}
                {'C4','A2','C4-A2'}
                {'Fz','A1','Fz-A1'}
                {'Fz','A2','Fz-A2'}
                {'Fp1','A2','F1-A2'}
                {'Fp2','C4','F2-C4'}
                {'Fp2','T4','F2-T4'}
                {'Arms-1','Arms-2','Arms'}
                {'EKG-R','EKG-L','EKG'}
                {'RIC-1','RIC-2','RIC'}
                {'LOC','A2','LOC-A2'}
                {'ROC','A1','ROC-A1'}
                };
            
            singlechannel = {
                {'ABD', 'Abd','Abdomen'};
                {'ARMS', 'Arm EMG','Arms'};
                {'CHEST','Chest' };
                {'MIC','Mic'};
                {'Chin EMG','EMG','Chin1-Chin2','Chin1-Chin3','Chin3-Chin2','Chin EMG'};
                {'FZ-A1/A2','FZ-A1A2','Fz-A2'};
                {'F1/A2','FP1-A2','FP1-AZ','FP1/A2','F1-A2'};
                {'FP1-C33456','FP1-T3','FP-?'};
                {'F2/A1','FP2-A1','F2-A1'};
                {'FP2-T4','F2-T4'};
                {'PES','Pes','Esophageal Pressure'};
                {'SaO2', 'SpO2'};
                {'LLEG1-RLEG1','LLEG1-RLEG2','RLEG1-RLEG2','LLEG2-RLEG1','LLEG2-RLEG2','LAT-RAT'};
                {'EKG1-EKG2','EKG'};
                {'O1-A2','O1-AVG','O1-M2','O1-x'};
                {'O2-A1','O2-AVG','O2-M1','O2-x'};
                {'C3-A2','C3-A23456','C3-M2','C3-A2'};
                {'F3-AVG','F3-M2','F3-x'};
                {'F4-AVG','F4-M2','F4-x'};
                {'LEOG-AVG','LEOG-M2','LEOG-x'};
                {'REOG-AVG','REOG-M1','REOG-M2','REOG-x'};
                {'POSITION','Position'};
                {'ETCO2', 'EtCO2'};
                {'Nasal','Nasal Pressure'};
                {'C-PRES', 'PAP Pressure'};
                {'Oral','Oral Thermistor'};
                {'CPAP Leak', 'PAP Leak','PAP Leak'};
                {'Pulse','PULSE','Pulse Rate'};
                {'PTT','Pulse Transit Time'};
                {'pCO2','TcCO2'};
                {'PAP Pt Flow','PAP Patient Flow'}
                };
            
        end

                
        function sevStruct = getSEVStruct()
            sevStruct.src_edf_pathname = '.'; %initial directory to look in for EDF files to load
            sevStruct.src_event_pathname = '.'; %initial directory to look in for EDF files to load
            sevStruct.batch_folder = '.'; %'/Users/hyatt4/Documents/Sleep Project/EE Training Set/';
            sevStruct.yDir = 'normal';  %or can be 'reverse'
            sevStruct.standard_epoch_sec = 30; %perhaps want to base this off of the hpn file if it exists...
            sevStruct.samplerate = 100;
            sevStruct.channelsettings_file = 'channelsettings.mat'; %used to store the settings for the file
            sevStruct.output_pathname = 'output';
            sevStruct.detectionInf_file = 'detection.inf';
            sevStruct.detection_path = '+detection';
            sevStruct.filter_path = '+filter';
            sevStruct.databaseInf_file = 'database.inf';
            sevStruct.parameters_filename = '_sev.parameters.txt';
            
        end
        
        % =================================================================
        %> @brief This function automates the file conversion process from
        %> twin formatted .nvt and .evt files to SEV formatted event files.
        %> @param twinStudyPath (optional) This is the parent directory of
        %> twin saved sleep studies.  Contents of this folder include
        %> subfolders for each sleep study.  The twinStudyPath is parsed for
        %> subfolders and the events found in each subfolder are saved to a
        %> separate evt.[study].[event].txt file name using the subfolder name
        %> for [study] and the event file name for [event].
        %> The user is prompted if twinStudy does not exist or is not
        %> entered.
        %> @param outPath (optional) String name of the directory to store the output .SCO files.
        %> The user is prompted if outPath does not exist or is not entered.
        % =================================================================
        function twin2evt(twinStudyPath, outPath)
            if(nargin<2)
                disp('Select Directory containing twin PSG directories.  Typically twin stores each study as a separate named directory.  Choose the directory that contains these named directories in them.');
                msg = 'Select Event directory (*.evt) to use or Cancel for none.';
                twinStudyPath = CLASS_converter.getPathname(pwd,msg);
                msg = 'Select Directory to save SEV evt files to';
                disp(msg);
                outPath =CLASS_converter.getPathname(twinStudyPath,msg);
            end
            
            if(exist(twinStudyPath,'file') && exist(outPath,'file'))
                CLASS_converter.twinEvtExport(twinStudyPath,outPath,'evt');
            else
                fprintf('One or both of the paths were not found');
            end            
        end
        
        % =================================================================
        %> @brief This function automates the file conversion process from
        %> twin formatted stage.evt files to STA file format used by SEV.formatted event files.
        %> @param twinStudyPath (optional) This is the parent directory of
        %> twin saved sleep studies.  Contents of this folder include
        %> subfolders for each sleep study.  The twinStudyPath is parsed for
        %> subfolders and the stage.evt files in each subfolder are saved to a
        %> [study].STA files using each subfolder name in the twinStudyPath to 
        %> identify [study].  
        %> for [study] and the event file name for [event].
        %> The user is prompted if twinStudy does not exist or is not
        %> entered.
        %> @param outPath (optional) String name of the directory to store the output .SCO files.
        %> The user is prompted if outPath does not exist or is not entered.
        % =================================================================
        function twin2STA(twinStudyPath, outPath)
            if(nargin<2)
                disp('Select Directory containing twin PSG directories.  Typically twin stores each study as a separate named directory.  Choose the directory that contains these named directories in them.');
                msg = 'Select Event directory (*.evt) to use or Cancel for none.';
                twinStudyPath = CLASS_converter.getPathname(pwd,msg);
                disp('Select Directory to save .STA files to');
                outPath =CLASS_converter.getPathname(twinStudyPath,'Select directory to save .STA files to.');
            end
            
            if(exist(twinStudyPath,'file') && exist(outPath,'file'))
        
                CLASS_converter.twinEvtExport(twinStudyPath,outPath,'STA');
            else
                fprintf('One or both of the paths were not found');
            end
        end
        
        % =================================================================
        %> @brief This function automates the file conversion process from
        %> Twin formatted event files (*_E.TXT) to a single Wisconsin Sleep
        %> Cohort multiplex .SCO format.
        %> @param twinStudyPath (optional) This is the parent directory of
        %> Twin saved sleep studies.  Contents of this folder include
        %> subfolders for each sleep study.  The twinStudyPath is parsed for
        %> subfolders and the events found in each subfolder are saved to a
        %> .SCO file of same name as the subfolder in the outPath directory.
        %> The user is prompted if twinStudy does not exist or is not
        %> entered.
        %> @param outPath (optional) String name of the directory to store the output .SCO files.
        %> The user is prompted if outPath does not exist or is not entered.
        % =================================================================
        function twin2sco(twinStudyPath, outPath)
            if(nargin<2)
                disp('Select the directory containing Twin PSG files (i.e. *_E.TXT).');
                msg = 'Select Twin PSG event directory (*_E.TXT) to use or Cancel for none.';
                twinStudyPath = CLASS_converter.getPathname(pwd,msg);                
                disp('Select destination directory for .SCO files ');
                outPath =CLASS_converter.getPathname(twinStudyPath,'Select directory to send .SCO files to.');                
            end
            
            if(exist(twinStudyPath,'file') && exist(outPath,'file'))
                CLASS_converter.twinEvtExport(twinStudyPath,outPath,'sco');
            else
                fprintf('One or both of the paths were not found');
            end
        end
        
        % =================================================================
        %> @brief This function automates the file conversion process from
        %> Embla formatted .nvt and .evt files to SEV formatted event files.
        %> @param emblaStudyPath (optional) This is the parent directory of
        %> Embla saved sleep studies.  Contents of this folder include
        %> subfolders for each sleep study.  The emblaStudyPath is parsed for
        %> subfolders and the events found in each subfolder are saved to a
        %> separate evt.[study].[event].txt file name using the subfolder name
        %> for [study] and the event file name for [event].
        %> The user is prompted if emblaStudy does not exist or is not
        %> entered.
        %> @param outPath (optional) String name of the directory to store the output .SCO files.
        %> The user is prompted if outPath does not exist or is not entered.
        % =================================================================
        function embla2evt(emblaStudyPath, outPath)
            if(nargin<2)
                disp('Select Directory containing Embla PSG directories.  Typically Embla stores each study as a separate named directory.  Choose the directory that contains these named directories in them.');
                msg = 'Select Event directory (*.evt) to use or Cancel for none.';
                emblaStudyPath = CLASS_converter.getPathname(pwd,msg);
                msg = 'Select Directory to save SEV evt files to';
                disp(msg);
                outPath =CLASS_converter.getPathname(emblaStudyPath,msg);
            end
            
            if(exist(emblaStudyPath,'file') && exist(outPath,'file'))
                CLASS_converter.staticEmblaEvtExport(emblaStudyPath,outPath,'evt'); %exports .evt files
            else
                fprintf('One or both of the paths were not found');
            end            
        end
        
        % =================================================================
        %> @brief This function automates the file conversion process from
        %> Embla formatted stage.evt files to STA file format used by SEV.formatted event files.
        %> @param emblaStudyPath (optional) This is the parent directory of
        %> Embla saved sleep studies.  Contents of this folder include
        %> subfolders for each sleep study.  The emblaStudyPath is parsed for
        %> subfolders and the stage.evt files in each subfolder are saved to a
        %> [study].STA files using each subfolder name in the emblaStudyPath to 
        %> identify [study].  
        %> for [study] and the event file name for [event].
        %> The user is prompted if emblaStudy does not exist or is not
        %> entered.
        %> @param outPath (optional) String name of the directory to store the output .SCO files.
        %> The user is prompted if outPath does not exist or is not entered.
        % =================================================================
        function embla2STA(emblaStudyPath, outPath)
            if(nargin<2)
                disp('Select Directory containing Embla PSG directories.  Typically Embla stores each study as a separate named directory.  Choose the directory that contains these named directories in them.');
                msg = 'Select Event directory (*.evt) to use or Cancel for none.';
                emblaStudyPath = CLASS_converter.getPathname(pwd,msg);
                disp('Select Directory to save .STA files to');
                outPath =CLASS_converter.getPathname(emblaStudyPath,'Select directory to save .STA files to.');
            end
            
            if(exist(emblaStudyPath,'file') && exist(outPath,'file'))
                CLASS_converter.staticEmblaEvtExport(emblaStudyPath,outPath,'STA'); %exports all STA files
            else
                fprintf('One or both of the paths were not found');
            end
        end
        
        
        
        % =================================================================
        %> @brief This function automates the file conversion process from
        %> Embla formatted .nvt and .evt files and a single Wisconsin Sleep
        %> Cohort multiplex .SCO format.
        %> @param emblaStudyPath (optional) This is the parent directory of
        %> Embla saved sleep studies.  Contents of this folder include
        %> subfolders for each sleep study.  The emblaStudyPath is parsed for
        %> subfolders and the events found in each subfolder are saved to a
        %> .SCO file of same name as the subfolder in the outPath directory.
        %> The user is prompted if emblaStudy does not exist or is not
        %> entered.
        %> @param outPath (optional) String name of the directory to store the output .SCO files.
        %> The user is prompted if outPath does not exist or is not entered.
        % =================================================================
        function embla2sco(emblaStudyPath, outPath)
            if(nargin<2)
                disp('Select Directory containing Embla PSG directories.  Typically Embla stores each study as a separate named directory.  Choose the directory that contains these named directories in them.');
                msg = 'Select Event directory (*.evt) to use or Cancel for none.';
                emblaStudyPath = CLASS_converter.getPathname(pwd,msg);                
                disp('Select Directory (*.evt)');
                outPath =CLASS_converter.getPathname(emblaStudyPath,'Select directory to send .SCO files to.');                
            end
            
            if(exist(emblaStudyPath,'file') && exist(outPath,'file'))
                CLASS_converter.staticEmblaEvtExport(emblaStudyPath,outPath,'SCO'); %exports SCO files
            
                %SSC_APOE_expressions = {'^(?<studyname>\d{4})_(?<studydate>\d{1,2}-\d{1,2}-\d{4})';
                %    '^nonMatch(?<studyname>\d{1,3})'};
                %CLASS_converter.emblaEvtExport(emblaStudyPath,outPath,SSC_APOE_expressions,'sco');
            else
                fprintf('One or both of the paths were not found');
            end
        end
        
        
        function staticEmblaEvtExport(emblaStudyPath, outPath,outputType)
            %outputType is 'sco','evt','evts','sta','all' {default}, 'db','edf'
            %db is database
            %sco is .SCO format
            %sta is .STA file formats   
            %EDF is .EDF 
            if(nargin<3)
                outputType = 'all';
            end
            pathnames = getPathnames(emblaStudyPath);
            
            
            studyStruct = CLASS_converter.getSEVStruct();
            studyStruct.samplerate = 256;
            
            for s=1:numel(pathnames)
                try
                    studyName = pathnames{s};
                    srcFile = [studyName,'.edf'];
                    
                    edfSrcPath = fullfile(emblaStudyPath,pathnames{s});
                    
                    
                    fullSrcFile = fullfile(edfSrcPath,srcFile);
                    
                    HDR = loadEDF(fullSrcFile);
                    studyStruct.startDateTime = HDR.T0;
                    
                    num_epochs = ceil(HDR.duration_sec/studyStruct.standard_epoch_sec);
                    
                    stage_evt_file = fullfile(edfSrcPath,'stage.evt');
                    if(exist(stage_evt_file,'file'))
                        
                        [eventStruct,src_samplerate] = CLASS_events_container.parseEmblaEvent(stage_evt_file,studyStruct.samplerate,studyStruct.samplerate);
                        studyStruct.samplerate = src_samplerate;
                        
                        if(num_epochs~=numel(eventStruct.epoch))
                            if(any(strcmpi(outputType,{'STA','All'})))
                                fprintf(1,'%s\texpected epochs: %u\tencountered epochs: %u to %u\n',srcFile,num_epochs,min(eventStruct.epoch),max(eventStruct.epoch));
                            end
                            
                            new_stage = repmat(7,num_epochs,1);
                            new_epoch = (1:num_epochs)';
                            new_stage(eventStruct.epoch)=eventStruct.stage;
                            eventStruct.epoch = new_epoch;
                            eventStruct.stage = new_stage;
                        end
                        
                        if(strcmpi(outputType,'STA') || strcmpi(outputType,'all'))
                            y = [eventStruct.epoch,eventStruct.stage];
                            staFilename = fullfile(outPath,strcat(studyName,'.STA'));
                            save(staFilename,'y','-ascii');
                        end
                        
                        if(~strcmpi(outputType,'STA'))
                            
                            if(strcmpi(outputType,'EDF'))
                                %export the .EDF
                                fprintf('EDF conversion is not implemented as a static method');                                
                            else
                                events_container_obj = CLASS_events_container.importEmblaEvtDir(edfSrcPath,src_samplerate);
                                studyStruct.line = eventStruct.stage;
                                studyStruct.cycles = scoreSleepCycles_ver_REMweight(studyStruct.line);
                                events_container_obj.setStageStruct(studyStruct);
                                
                                if(strcmpi(outputType,'sco') || strcmpi(outputType,'all'))
                                    scoFilename = fullfile(outPath,strcat(studyName,'.SCO'));
                                    events_container_obj.save2sco(scoFilename);
                                end
                                
                                if(strcmpi(outputType,'evt') || strcmpi(outputType,'all'))
                                    %avoid the problem of file
                                    %names like : evt.studyName..txt
                                    if(studyName(end)=='.')
                                        studyName = studyName(1:end-1);
                                    end
                                    events_container_obj.save2txt(fullfile(outPath,strcat('evt.',studyName)));
                                end
                                
                                if(strcmpi(outputType,'evts') || strcmpi(outputType,'all'))
                                    %avoid the problem of file
                                    %names like : studyName..EVTS
                                    if(studyName(end)=='.')
                                        studyName = studyName(1:end-1);
                                    end
                                    events_container_obj.save2evts(fullfile(outPath,strcat(studyName,'.EVTS')));
                                end
                                
                                

                            end
                        end
                    else
                        fprintf(1,'%s\tNo stage File found\n',srcFile);
                    end
                    
                catch me
                    showME(me);
                    fprintf(1,'%s (%u) - Fail\n',srcFile,s);
                end
            end
        end
        
        %helper/wrapper function to get the pathnames.
        function pathnameOut = getPathname(src_directory,msg_string)
            if(nargin<1 || ~isdir(src_directory))
                src_directory = pwd;
            end
            pathnameOut =uigetdir(src_directory,msg_string);
            if(isnumeric(pathnameOut) && ~pathnameOut)
                pathnameOut = [];
            end
        end
        
        function twinEvtExport(srcPath, destPath, outputType)
            %outputType is 'sco','evt','sta','all' {default}, 'db','edf'
            %db is database
            %sco is .SCO format
            %sta is .STA file formats
            %EDF is .EDF
            if(nargin<3)
                outputType = 'all';
            end
            
            %% export event and stage files
            files = getFilenames(srcPath,'*_E.TXT');
            % filename = 'A0013_7_120409_E.TXT';
            % filename = 'A0014_7_120409_E.TXT';
            
            
            studyStruct = CLASS_converter.getSEVStruct();
            
            if(~isdir(destPath))
                mkdir(destPath)
            end
            
            
            sta_problems = {};
            unknown_problems = {};

            for f=1:numel(files)
                try
                    filename = files{f};
                    evt_fullfilename = fullfile(srcPath,filename);
                    studyName = strrep(filename,'_E.TXT','');
                    EDF_name = fullfile(srcPath,strcat(studyName,'.EDF'));
                    
                    HDR = loadEDF(EDF_name);
                    
                    %         studyStruct.samplerate = max(HDR.samplerate);
                    num_epochs_expected = ceil(HDR.duration_sec/studyStruct.standard_epoch_sec);
                    
                    fid = fopen(evt_fullfilename,'r');
                    
                    c = textscan(fid,'%f/%f/%f_%f:%f:%f %[^\r\n]');
                    startDateNum = datenum(HDR.T0);
                    
                    allDateNum = datenum([c{3},c{1},c{2},c{4},c{5},c{6}]);
                    % allDateNum = datenum(cell2mat(cells2cell(c{1:end-1})));
                    
                    datenumPerSec = datenum([0, 0 , 0 ,0 ,0 ,1]);
                    
                    all_elapsed_sec = (allDateNum - startDateNum)/datenumPerSec+1/studyStruct.samplerate; %this is necessary because they began at elapsed seconds of 0
                    seconds_per_epoch = studyStruct.standard_epoch_sec;
                    all_epoch = ceil(all_elapsed_sec/seconds_per_epoch);
                    
                    txt = c{end};
                    exp = regexp(txt,['(?<type>.+) - DUR: (?<dur_sec>\d+.\d+) SEC. - (?<description>[^-]+).*|',...
                        '(?<type>.+) - (?<description>[^-]+).*|',...
                        '(?<type>.+)'],'names');
                   
                    expMat = cell2mat(exp);
                    expTypes = cells2cell(expMat.type);
                    expDursec = cells2cell(expMat.dur_sec);
                    expDescription = cells2cell(expMat.description);
                    
                    fclose(fid);
                    
                    max_epoch_encountered = max(all_epoch);
                    if(max_epoch_encountered>num_epochs_expected)
                        sta_problems{end+1} = filename;
                        fprintf(1,'%s\texpected epochs: %u\tencountered epochs: %u\n',filename,num_epochs_expected,max_epoch_encountered);
                        okay_ind =all_epoch<=num_epochs_expected;
                        all_epoch = all_epoch(okay_ind);
                        all_elapsed_sec = all_elapsed_sec(okay_ind);
                        expTypes = expTypes(okay_ind);
                        expDursec = expDursec(okay_ind);
                        expDescription = expDescription(okay_ind);
                    end
                    
                    expDursec = str2double(expDursec);
                    expDursec(isnan(expDursec))=0; %give 0 duration to events with no listing
                    
                    % studyStruct.samplerate = mode(HDR.samplerate);
                    studyStruct.startDateTime  = HDR.T0;
                    
                    all_start_stop_sec = [all_elapsed_sec(:), all_elapsed_sec+expDursec(:)];
                    all_start_stop_matrix = ceil(all_start_stop_sec.*studyStruct.samplerate);
                    
                    
                    
                    %                     types = {'STAGE','AROUSAL','LM','RESPIRATORY EVENT','DESATURATION','NEW MONTAGE'};
                    %not interested in all of these ones
                    
                    num_epochs = ceil(HDR.duration_sec/studyStruct.standard_epoch_sec);
                    
                    %handle the stages first
                    ind = strcmpi(expTypes,'STAGE');
                    
                    
                    stageDescription = expDescription(ind);
                    %         unique(stageDescription)
                    stageMat = [1:num_epochs_expected;repmat(7,1,num_epochs_expected)]';
                    
                    %change out the text identifiers to numeric stage identifiers (0 =
                    %W, 5= N5, 7 = unknown'
                    stageStrings = {'W','N1','N2','N3','N4','R','N6','NO STAGE'};
                    stageValues = repmat(7,size(stageDescription));
                    for s = 1:numel(stageStrings)
                        stageValues(strcmpi(stageDescription,stageStrings{s}))=s-1;
                    end
                    
                    %go to an epoch based indexing
                    stage_epoch = all_epoch(ind==1);
                    cur_epoch = stage_epoch(1);
                    stageValue = stageValues(1);
                    
                    for s=2:numel(stage_epoch)
                        next_epoch = stage_epoch(s);
                        try
                            stageMat(cur_epoch:next_epoch-1,2) = stageValue;
                        catch me
                            me.message
                        end
                        
                        cur_epoch = next_epoch;
                        stageValue = stageValues(s);
                    end
                    stageMat(cur_epoch:end,2) = stageValue;
                    
                    if(strcmpi(outputType,'STA')||strcmpi(outputType,'ALL'))
                        stageFilename = fullfile(destPath,strcat(studyName,'.STA'));
                        save(stageFilename,'stageMat','-ascii');
                    end
                    
                    
                    if(~strcmpi(outputType,'STA'))
                        types = {'LM','AROUSAL','RESPIRATORY EVENT','DEASUTRATION'};
                        src_label = 'WSC Twin File';
                        
                        studyStruct.line = stageMat(:,2);
                        
                        studyStruct.cycles = scoreSleepCycles_ver_REMweight(studyStruct.line);
                        eventContainer = CLASS_events_container([],[],studyStruct.samplerate,studyStruct);
                        
                        % eventContainer.setStageStruct(studyStruct);
                        % eventContainer.setSamplerate(studyStruct.samplerate);
                        for t=1:numel(types)
                            type = types{t};
                            ind = strcmpi(expTypes,type);
                            
                            typeName = strrep(type,' ','_');
                            evtLabel = strcat('SCO_',typeName);
                            start_stop_matrix = all_start_stop_matrix(ind,:);
                            paramStruct = [];
                            if(~isempty(start_stop_matrix))
                                eventContainer.loadGenericEvents(start_stop_matrix,evtLabel,src_label,paramStruct);
                            end
                        end
                                                
                        if(strcmpi(outputType,'sco') || strcmpi(outputType,'all'))
                            scoFilename = fullfile(destPath,strcat(studyName,'.SCO'));
                            eventContainer.save2sco(scoFilename);
                        end
                        
                        if(strcmpi(outputType,'evt') || strcmpi(outputType,'all'))
                            eventContainer.save2txt(fullfile(destPath,strcat('evt.',studyName)));
                        end
                    end                
                    
                catch me
                    showME(me);
                    fprintf(1,'%s (%u) - Fail\n',filename,f);
                end
            end
        end
        
        
        %exports directory of sev evt..txt files to database described by
        %dbStruct.
        function sevEvt2db(dbStruct,edf_sta_path,evt_path,samplerate)
            %import the events into a database structure
            
            EvtFiles = getFilenames(evt_path,strcat('evt.*.txt'));
            patstudy = strrep(strrep(EvtFiles,'SSC_',''),'evt.','');
            
            exp=regexp(patstudy,'(\w+_\d+).*||(\d+_\d+).*||([^\d]+\d+).*','tokens');
            exp_cell = cell(size(exp));
            for f=1:numel(exp)
                exp_cell(f) = exp{f}{1};
            end
            uniquePat = unique(exp_cell);
            for s=1:numel(uniquePat)
                
                %this is a hack created by the necessity of save2DB method in
                %CLASS_events which calls on this global...
                %                 STAFiles = getFilenames(edf_sta_path,'*.STA');
                %                 if(strncmp(STAFiles{1},'SSC_',4))
                %                     PatIDs = strrep(strrep(STAFiles,'.STA',''),'SSC_','');
                %                 else
                %                     PatIDs = strtok(STAFiles,' ');
                %                 end
                %
                
                %             for s=1:numel(STAFiles)
                %                 cur_STA_filename = fullfile(edf_sta_path,STAFiles{s});
                cur_STA_filename = dir(fullfile(edf_sta_path,strcat('*',uniquePat{s},'*.STA')));
                
                cur_STA_filename = fullfile(edf_sta_path,cur_STA_filename.name);
                
                if(exist(cur_STA_filename,'file'))
                    EvtFiles = getFilenames(evt_path,strcat('evt.*',uniquePat{s},'*.txt'));
                    
                    sev_STAGES = loadSTAGES(cur_STA_filename);
                    event_container = CLASS_events_container();
                    event_container.setDefaultSamplerate(samplerate);  %this is required to handle the incorporation of new events added from elsewhere
                    
                    for f=1:numel(EvtFiles)
                        evtFile = fullfile(evt_path,EvtFiles{f});
                        cur_evt = event_container.loadEvtFile(evtFile);
                        if(~isempty(cur_evt.events))
                            curEvtObj = event_container.getCurrentChild();
                            if(strcmpi(cur_evt.channel_label,'Unset'))
                                curEvtObj.channel_name = 'External';
                            else
                                curEvtObj.channel_name = cur_evt.channel_label;
                            end
                        end
                    end
                    event_container.save2DB(dbStruct,uniquePat{s},sev_STAGES);
                end
            end
        end
        
        
        %this function requires the use of loadSCOfile.m and is useful
        %for batch processing...
        % Usage:
        % exportSCOtoEvt() prompts user for .SCO directory and evt output directory
        % exportSCOtoEvt(sco_pathname) sco_pathname is the .SCO file containing
        %    directory.  User is prompted for evt output directory
        % exportSCOtoEvt(sco_pathname, evt_pathname) evt_pathname is the directory
        %    where evt files are exported to.
        function convertSCOtoEvt(sco_pathname, evt_pathname)
            %this function requires the use of loadSCOfile.m and is useful
            %for batch processing...
            % Usage:
            % exportSCOtoEvt() prompts user for .SCO directory and evt output directory
            % exportSCOtoEvt(sco_pathname) sco_pathname is the .SCO file containing
            %    directory.  User is prompted for evt output directory
            % exportSCOtoEvt(sco_pathname, evt_pathname) evt_pathname is the directory
            %    where evt files are exported to.
            %
            % Author: Hyatt Moore IV, Stanford University
            % Date Created: 1/9/2012
            % modified 2/6/2012: Checked if evt_pathname exists first and, if not,
            % creates the directory before proceeding with export
            
            
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
                evt_filename_str = 'evt.%s.%s.0.txt'; %use this in conjunction with sprintf below for each evt output file
                
                %evt header example:
                %    Event Label =	SWA
                %    EDF Channel Label(number) = 	C3-M2 (3)
                %    Start_time	Duration_seconds	Start_sample	Stop_sample	Epoch	Stage	freq	amplitude
                evt_header_str = ['Event Label =\t%s\r\nEDF Channel Label(number) =\tUnset (0)\r\n',...
                    'Start_time\tDuration_seconds\tStart_sample\tStop_sample\tEpoch\tStage\r\n'];
                

                
                for k=1:filecount
                    sco_filename = filenames{k};
                    study_name = strtok(sco_filename,'.'); %fileparts() would also work
                    
                    %example .STA filename:    A0097_4 174733.STA
                    %         sta_filename = [sco_filename(1:end-3),'STA'];
                    sta_filename = [study_name,'.STA'];
                    try
                        SCO = loadSCOfile(fullfile(sco_pathname,sco_filename));
                    catch me
                        showME(me);
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
                                evt_label = strcat('SCO_',deblank(event_labels{j}));
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
                                showME(ME);
                                disp(['failed on ',study_name,' for event ',evt_label]);
                            end
                            
                        end
                    end
                end
            end
        end
        

        
        
        function dirdump = getEDFNames(edfPathname)
            if(nargin <1)
                edfPathname = uigetfulldir(pwd,'Select directory containing .EDF files');
            end
            if(isdir(edfPathname))
                dirdump = dir(edfPathname);
            else
                dirdump = [];                
            end
        end

        % export Grouped edf path - exports .EDF files found in subdirectories of the
        % source directory.
        function exportGroupedXMLPath(obj,nameConvertFcn,exportType)
            [~,xmlPathnames] = getPathnames(obj.srcPath);
            for d=1:numel(xmlPathnames)
                obj.exportFlatXMLPath(obj,nameConvertFcn,exportType,xmlPathnames{d})
            end            
        end
        
        function exportFlatXMLPath(obj,nameConvertFcn,exportType, optionalSrcPath)
            
            %the optional 'optionalSrcPath' variable allows the flat EDF
            %path method to be used by the Grouped EDF path method.
            if(nargin<3 || isempty(optionalSrcPath))
                [srcFilenames,fullSrcFilenames] = getFilenamesi(obj.srcPath,'\.xml');
            else
                [srcFilenames,fullSrcFilenames] = getFilenamesi(optionalSrcPath,'\.xml');            
            end
            if(~isdir(obj.destPath))
                mkdir(obj.destPath);
            end
            if(isdir(obj.destPath))
            
                for f=1:numel(srcFilenames)
                    try
                        srcFile = srcFilenames{f};
                        if(nargin>1 && isa(nameConvertFcn,'function_handle'))
                            destFilename = nameConvertFcn(srcFile);
                            fullDestFilename = fullfile(obj.destPath,destFilename);
                        else
                            fullDestFilename = fullfile(obj.destPath,srcFile);
                        end
                        
                        if(exist(fullSrcFilenames{f},'file'))
                            obj.exportXML(fullSrcFilenames{f},fullDestFilename,exportType);
                        else
                            fprintf('Could not export %s.  File not found.\n',fullSrcFile);
                        end
                    catch me
                        showME(me);
                        fprintf('Could not export %s.  File not found.\n',srcFile);
                        
                    end
                end
            else
                fprintf('Could not create the destination path (%s).  Check your system level permissions.\n',obj.destPath);
            end
        end
        
        function exportXML(srcFilename,destFilename,exportType)
            
            dom = xmlread(srcFilename);
            epochLengthSec = str2double(dom.getDocumentElement.getElementsByTagName('EpochLength').item(0).getTextContent);
                            
            edfFilename = strcat(destFilename,'.EDF');
            %strrep(strrep(destFilename,'.STA','.EDF'),'.SCO','.EDF');
            
            edfHDR = loadEDF(edfFilename); %get the EDF header

            if(strcmpi(exportType,'STA'))

                numEDFEpochs = ceil(edfHDR.duration_sec/epochLengthSec);
                
                sleepstages= dom.getElementsByTagName('SleepStage');
                numStages = sleepstages.getLength();
                if(numEDFEpochs~=numStages)                    
                    fprintf(1,'%s\texpected epochs: %u\tencountered epochs: %u\n',srcFilename,numEDFEpochs,numStages);                    
                end
                if(numStages>0)                
                    %java's xml implementation is 0-based
                    fid = fopen(strcat(destFilename,'.STA'),'w');
                    for n=0:min(numEDFEpochs,numStages)-1
                        curStage = char(sleepstages.item(n).getTextContent);
                        if(numel(curStage)<1 || numel(curStage)>1 || curStage<'0' || curStage>'7' || curStage == '6')
                            curStage = '7';
                        end
                        fprintf(fid,'%u\t%s\n',n+1,curStage);
                    end
                    fclose(fid);
                    
%                     stageVec = repmat(7,numEDFEpochs,1);

%                     for n=0:min(numel(numEDFEpochs),numel(numStages))-1
%                         stageVec(n) = str2double(sleepstages.item(n).getTextContent);
%                     end
%                     y = [(1:numStages)',stageVec(:)];
%                     save(destFilename,'y','-ascii');
                end
            elseif(strcmpi(exportType,'SCO'))
                scoredEvents = dom.getElementsByTagName('ScoredEvent');
                t0 = edfHDR.T0;
                numEvents = scoredEvents.getLength;
                    
                fid = fopen(strcat(destFilename,'.SCO'),'w');
                for e=0:numEvents-1
                    try
                        curEntry = scoredEvents.item(e);
                        
                        curEventName = char(curEntry.getElementsByTagName('Name').item(0).getTextContent);
                        startSec = str2double(curEntry.getElementsByTagName('Start').item(0).getTextContent);
                        
                        durationSec = char(curEntry.getElementsByTagName('Duration').item(0).getTextContent);
                        %if(~isnull(curEntry.getElementsByTagName('Input').item(0)))
                        %channelSrc = char(curEntry.getElementsByTagName('Input').item(0).getTextContent);
                        %   -> this sometimes fails, and because it is not
                        %      used, we will leave it out.
                        sevSamplerate = 100;
                        
                        %make sure we stay 1-based for MATLAB (MrOS studies are
                        %0-based.
                        startSample = floor(startSec*sevSamplerate+1);
                        startTimeStr = datestr(datenum(0,0,0,0,0,startSec)+datenum(t0),'HH:MM:SS.FFF');
                        
                        durationSamples = round(str2double(durationSec)*sevSamplerate);
                        %                 start_epochs = sample2epoch(starts,studyStruct.standard_epoch_sec,obj.samplerate);
                        startEpoch = sample2epoch(startSample,epochLengthSec,sevSamplerate);
                        
                        unk = '0'; %this is the event category typed to the event, which has no meaning for us now, but still need this as a place holder
                        fprintf(fid,'%u\t%u\t%u\t%c\t%s\t%c\t%s\n',startEpoch,startSample,durationSamples,unk,...
                            curEventName,unk,startTimeStr);
                        %miscellaneous values that are added in
                        %desaturationPct = curEntry.getElementsByTagName('Desaturation').item(0).getTextContent;
                        %lowestSpO2 = curEntry.getElementsByTagName('LowestSpO2').item(0).getTextContent;
                        
                        %alternative way to get around this problem.
                        %                     channelSrc = dom.getElementsByTagName('ScoredEvents').item(0).getElementsByTagName('Input').item(e).getTextContent;
                        %                     fprintf(fidOut,'');
                    catch me
                        showME(me);
                    end
                end
                fclose(fid);
            end
                
        end            
        
        
         
        
        %remove HDR entries at indices purgeIndices
        %purgeIndices is a 1-based vector of indices to purge from HDR
        function purgedHDR = purgeEDFHeader(HDR, purgeIndices)
            purgedHDR = HDR;
            for n=1:numel(CLASS_converter.EDFHDRSignalFields)
                curFieldname = CLASS_converter.EDFHDRSignalFields{n};
                purgedHDR.(curFieldname)(purgeIndices) = [];
            end
        end
        
        %extract HDR entries from indices at extractIndices
        %extractIndices is a 1-based vector of indices to purge from HDR
        function extractedHDR = extractEDFHeader(HDR, extractIndices)
            extractedHDR = HDR;
            for n=1:numel(CLASS_converter.EDFHDRSignalFields)
                curFieldname = CLASS_converter.EDFHDRSignalFields{n};
                extractedHDR.(curFieldname) = HDR.(curFieldname)(extractIndices);                
            end
        end

        
        function mergedHDR = mergeEDFHeader(HDR,HDRentriesToMerge)
            %combine HDR and mergeHDRentries here
            mergedHDR = HDR;
            for n=1:numel(CLASS_converter.EDFHDRSignalFields)
                curFieldname = CLASS_converter.EDFHDRSignalFields{n};
                if(iscell(curFieldname))
                    mergedHDR.(curFieldname) = [HDR.(curFieldname){:};HDRentriesToMerge.(curFieldname){:}];
                else
                    mergedHDR.(curFieldname) = [HDR.(curFieldname)(:);HDRentriesToMerge.(curFieldname)(:)];
                end
            end
        end
        
        function success = rewriteEDF(fullSrcFilename,fullDestFilename,mergeIndices,HDREntriesToMerge)
            try
                [HDR, channelData] = loadEDF(fullSrcFilename);
                numMerges = size(mergeIndices,1);
                mergeData = cell(numMerges,1);                                
                for n=1:numMerges
                   mergeData{n} = channelData{mergeIndices(n,1)}-channelData{mergeIndices(n,2)};                   
                end
                
                
                %create section data cell and header of remaining/non-merged EDF channels
                nonmergeHDR = CLASS_converter.purgeEDFHeader(HDR,unique(mergeIndices(:)));
                channelData(mergeIndices(:)) = []; %this is the non merged data
                
                %merge everything together
                mergedData = [channelData; mergeData];
                mergedHDR = CLASS_converter.mergeEDFHeader(nonmergeHDR,HDREntriesToMerge);
                
                %prep it for EDF format
                for c=1:numel(mergedData)
                    mergedData{c} = CLASS_converter.double2EDFReadyData(mergedData{c},mergedHDR,c);
                end
                
                %should we filter first?
                %                 fir_bp.params.start_freq_hz = 1;
                %                 fir_bp.params.stop_freq_hz = 49;
                %
                %                 fir_bp.params.sample_rate = HDR.samplerate(channels.legs(1));
                %                 fir_bp.params.order = fir_bp.params.sample_rate;
                %                 data.legs = +filter.fir_bp(data.legs,fir_bp.params);
                
           
                mergedHDR.num_signals = numel(mergedData);
                CLASS_converter.writeEDF(fullDestFilename,mergedHDR,mergedData);
                success = true;

            catch me
                showME(me);
                success = false;
            end
        end
        
        
        function success = rewriteEDFHeader(edf_filename, label_indices,new_labels)
            %new_labels = cell of label names
            %label_indices = vector of indices (1-based) of the label to be replaced in
            %the EDF header
            %Author: Hyatt Moore IV
            %10.18.2012
            success = false;
            if(exist(edf_filename,'file'))
                
                fid = fopen(edf_filename,'r+');
                
                fseek(fid,252,'bof');
                number_of_channels = str2double(fread(fid,4,'*char')');
                label_offset = 256; %ftell(fid);
                out_of_range_ind = label_indices<1 | label_indices>number_of_channels;
                label_indices(out_of_range_ind) = [];
                new_labels(out_of_range_ind) = [];
                num_labels = numel(new_labels);
                label_size = 16; %16 bytes
                
                for k=1:num_labels
                    numChars = min(numel(new_labels{k}),label_size);
                    new_label = repmat(' ',1,label_size);
                    new_label(1:numChars) = new_labels{k}(1:numChars);
                    fseek(fid,label_offset+(label_indices(k)-1)*label_size,'bof');
                    fwrite(fid,new_label,'*char');
                end
                fclose(fid);
                success = true;
            end
        end
        
        
        function edfData = double2EDFReadyData(signal,HDR,k)
            %hdr is the HDR information only for the signal passed
            %signal is a vector of type double
            %k is the index of signal in the HDR (.EDF)
            
            % helper function for something, but it has been a while
            % Hyatt Moore, IV
            % < June, 2013
            edfData = int16((signal-HDR.physical_minimum(k))*(HDR.digital_maximum(k)-HDR.digital_minimum(k))/(HDR.physical_maximum(k)-HDR.physical_minimum(k))+HDR.digital_minimum(k));
        end
        
        %% The following methods to export matlab data were programmed by Adam Rhine (June, 2011)
        function [HDR, signals] = writeEDF(filename, HDR, signals)
            %Writes EDF files (not EDF+ format); if no HDR is specified then
            %a "blank" HDR is used. If no signals are specified, 2 signals of
            %repeating matrices of 5000 and 10000 are used.
            
            %written by Adam Rhine  (June, 2011)
            %updated by Hyatt Moore (January, 2014)
            if(nargin==0)
                disp 'No input filename given; aborting';
                return;
            end;
            
            if (nargin==1)  %If no HDR specified, blank HDR used instead
                HDR.ver = 0;
                HDR.patient = 'UNKNOWN';
                HDR.local = 'UNKNOWN';
                HDR.startdate = '01.01.11';
                HDR.starttime = '00.00.00';
                HDR.HDR_size_in_bytes = 768;
                HDR.number_of_data_records = 18522;
                HDR.duration_of_data_record_in_seconds = 1;
                HDR.num_signals = 1;
                HDR.label = {'Blank1'};
                HDR.transducer = {'unknown'};
                HDR.physical_dimension = {'uV'};
                HDR.physical_minimum = -250;
                HDR.physical_maximum = 250;
                HDR.digital_minimum = -2048;
                HDR.digital_maximum = 2047;
                HDR.prefiltering = {'BP: 0.1HZ -100HZ'};
                HDR.number_samples_in_each_data_record = 100;
            end;
            
            if(nargin<3)    %If no signals specified, fills with num_signals worth of repeating signals (5000 for first signal, 10000 for second, etc.)
                disp(HDR.num_signals);
                signals = cell(HDR.num_signals,1);
                for k=1:HDR.num_signals
                    signals{k}=repmat(5000*k,1852200,1);
                end;
            end;
            if(nargin>=3)
                if(HDR.num_signals == 0)
                    if(iscell(signals))
                        HDR.num_signals = numel(signals);
                    else
                        HDR.num_signals = size(signals,1);  %signals are (should be) stored as row entries
                    end
                end
                if(nargin>3)
                    disp('Too many input arguments in loadEDF.  Extra input arguments are ignored');
                end
            end
            
            fid = fopen(filename,'w');
            
            %'output' becomes the header
            output = CLASS_converter.resize(num2str(HDR.ver),8);
            output = [output CLASS_converter.resize(HDR.patient,80)];
            output = [output CLASS_converter.resize(HDR.local,80)];
            output = [output CLASS_converter.resize(HDR.startdate,8)];
            output = [output CLASS_converter.resize(HDR.starttime,8)];
            
            %location is currently 160+24+1 ("1-based") = 185
            output = [output CLASS_converter.resize(num2str(HDR.HDR_size_in_bytes),8)];
            output = [output repmat(' ',1,44)]; %HDR.reserved
            output = [output CLASS_converter.resize(num2str(HDR.number_of_data_records),8)];
            output = [output CLASS_converter.resize(num2str(HDR.duration_of_data_record_in_seconds),8)];
            output = [output CLASS_converter.resize(num2str(HDR.num_signals),4)];
            output = [output CLASS_converter.rep_sig(HDR.label,16)];
            output = [output CLASS_converter.rep_sig(HDR.transducer,80)];
            output = [output CLASS_converter.rep_sig(HDR.physical_dimension,8)];
            output = [output CLASS_converter.rep_sig_num(HDR.physical_minimum,8,'%1.1f')];
            output = [output CLASS_converter.rep_sig_num(HDR.physical_maximum,8,'%1.1f')];
            output = [output CLASS_converter.rep_sig_num(HDR.digital_minimum,8)];
            output = [output CLASS_converter.rep_sig_num(HDR.digital_maximum,8)];
            output = [output CLASS_converter.rep_sig(HDR.prefiltering,80)];
            output = [output CLASS_converter.rep_sig_num(HDR.number_samples_in_each_data_record,8)];
            
            ns = HDR.num_signals;
            
            for k=1:ns
                output = [output repmat(' ',1,32)]; %reserved...
            end;
            
            HDR.HDR_size_in_bytes = numel(output);
            output(185:192) = CLASS_converter.resize(num2str(HDR.HDR_size_in_bytes),8);
            
            precision = 'uint8';
            fwrite(fid,output,precision); %Header is written to the file
                      
            
            %just do the whole thing slowly - at least we know it will work
            
            try
            for rec=1:HDR.number_of_data_records
                for k=1:ns
                    samples_in_record = HDR.number_samples_in_each_data_record(k);
                    
                    range = (rec-1)*samples_in_record+1:(rec)*samples_in_record;
                    if(iscell(signals))
                        currentsignal = int16(signals{k}(range));
                    else
                        currentsignal = int16(signals(k,range));
                    end
                    fwrite(fid,currentsignal,'int16');
                end
            end
            fclose(fid);

            catch me
                showME(me);
                fclose(fid);
            end
            
        end
            
        %Modifies a string ('input') to be as long as 'length', with blanks filling
        %in the missing chars        
        function [resized_string] = resize(input,length)            
            resized_string = repmat(' ',1,length);            
            for k=1:numel(input)
                resized_string(k)=input(k);
            end;            
        end
                
        
        %Same as resize(), but does so for all elements in a cell array
        function [multi_string] = rep_sig(input,length)
            multi_string = '';
            for k=1:numel(input)
                multi_string = [multi_string CLASS_converter.resize(input{k},length)];
            end;
        end
        
        %Same as rep_sig(), but does so for all elements in a matrix of doubles
        function [multi_string] = rep_sig_num(input,length,prec)
            
            if (nargin<3)
                prec = '%1.0f';
            end;
            
            multi_string = '';
            
            for k=1:numel(input)
                multi_string = [multi_string CLASS_converter.resize(num2str(input(k),prec),length)];
            end;
        end
        
        %The following XML functions were taken from the Mathworks website
        %on March 5, 2014 
        % http://www.mathworks.com/help/matlab/ref/xmlread.html
        function theStruct = parseXML(filename)
            % PARSEXML Convert XML file to a MATLAB structure.
            try
                tree = xmlread(filename);
            catch
                error('Failed to read XML file %s.',filename);
            end
            
            % Recurse over child nodes. This could run into problems
            % with very deeply nested trees.
            try
                theStruct = CLASS_converter.parseChildNodes(tree);
            catch
                error('Unable to parse XML file %s.',filename);
            end
        end
        
        
        % ----- Local function PARSECHILDNODES -----
        function children = parseChildNodes(theNode)
            % Recurse over node children.
            children = [];
            if theNode.hasChildNodes
                childNodes = theNode.getChildNodes;
                numChildNodes = childNodes.getLength;
                allocCell = cell(1, numChildNodes);
                
                children = struct(             ...
                    'Name', allocCell, 'Attributes', allocCell,    ...
                    'Data', allocCell, 'Children', allocCell);
                
                for count = 1:numChildNodes
                    theChild = childNodes.item(count-1);
                    children(count) = CLASS_converter.makeStructFromNode(theChild);
                end
            end
        end
        
        % ----- Local function MAKESTRUCTFROMNODE -----
        function nodeStruct = makeStructFromNode(theNode)
            % Create structure of node info.
            
            nodeStruct = struct(                        ...
                'Name', char(theNode.getNodeName),       ...
                'Attributes', CLASS_converter.parseAttributes(theNode),  ...
                'Data', '',                              ...
                'Children', CLASS_converter.parseChildNodes(theNode));
            
            if any(strcmp(methods(theNode), 'getData'))
                nodeStruct.Data = char(theNode.getData);
            else
                nodeStruct.Data = '';
            end
        end
        
        % ----- Local function PARSEATTRIBUTES -----
        function attributes = parseAttributes(theNode)
            % Create attributes structure.
            
            attributes = [];
            if theNode.hasAttributes
                theAttributes = theNode.getAttributes;
                numAttributes = theAttributes.getLength;
                allocCell = cell(1, numAttributes);
                attributes = struct('Name', allocCell, 'Value', ...
                    allocCell);
                
                for count = 1:numAttributes
                    attrib = theAttributes.item(count-1);
                    attributes(count).Name = char(attrib.getName);
                    attributes(count).Value = char(attrib.getValue);
                end
            end
        end
        
    end %end STATIC
    
end %CLASSDEF

