%> @file CLASS_settings.m
%> @brief CLASS_settings Control user settings and preferences of SEV.
% ======================================================================
%> @brief CLASS_settings used by SEV to initialize, store, and update
%> user preferences in the SEV.
%> The class is designed for storage and manipulation of user settings in
%> the SEV.
% ======================================================================
classdef  CLASS_settings < handle
%     (InferiorClasses = {?JavaVisible}) CLASS_settings < handle
    %CLASS_settings < handles
    %  A class for handling global initialization and settings
    %  - a.  Load settings - X
    %  - b.  Save settings - X
    %  - c.  Interface for editing the settings
    
    properties
        %> pathname of SEV working directory - determined at run time.
        rootpathname
        %> @brief name of text file that stores the SEV's settings
        %> (CLASS_UI_marking constructor will set this to <i>_sev.parameters.txt</i> by default)        
        parameters_filename
        %> @brief cell of string names corresponding to the struct properties that
        %> contain settings  <b><i> {'VIEW', 'BATCH_PROCESS', 'PSD',
        %> 'MUSIC'}</b></i>
        fieldNames;
        %> struct of SEV's single study mode (i.e. view) settings.
        VIEW;
        %> struct of SEV's batch mode settings.
        BATCH_PROCESS;
        %> struct of power spectral density settings.
        PSD;
        %> struct of multiple spectrum independent component settings.
        MUSIC;          
        %visibleObj;
    end
    
    properties(Constant)
        
        %> @brief Prefix string for calling detection package methods (i.e.
        %> 'detection.')
        detectorPackagePrefixStr = 'detection.';     
    end
    
    methods(Static)
        
        % ======================================================================
        %> @brief Returns a structure of parameters parsed from the text file identified by the
        %> the input filename.  
        %> Parameters in the text file are stored per row using the
        %> following form:
        %> - fieldname1 value1
        %> - fieldname2 value2
        %> - ....
        %>an optional ':' is allowed after the fieldname such as
        %>fieldname: value
        %
        %The parameters is 
        %>
        %> @param filename String identifying the filename to load.
        %> @retval paramStruct Structure that contains the listed fields found in the
        %> file 'filename' along with their corresponding values
        % =================================================================
        function paramStruct = loadParametersFromFile(filename)
            % written by Hyatt Moore
            % edited: 10.3.2012 - removed unused globals; and changed PSD
            % 8/25/2013 - ported into CLASS_settings
            
            fid = fopen(filename,'r');
            paramStruct = CLASS_settings.loadStruct(fid);
            fclose(fid);            
        end

                
        % ======================================================================
        %> @brief Parses the XML file and returns an array of structs
        %> @param xmlFilename Name of the XML file to parse (absolute path)
        %> @retval xmlStruct A structure containing the elements and
        %> associated attributes of the xml as parsed by xml_read.  
        % ======================================================================
        function xmlStruct = loadXMLStruct(xmlFilename)
            % Testing dom = xmlread('cohort.xml');
            %             dom = xmlread(xmlFilename);
            %
            %             firstName = dom.getFirstChild.getNodeName;
            %             firstLevel = dom.getElementsByTagName(firstName);
            %             numChildren = firstLevel.getLength();
            %
            %             xmlStruct.(firstName) = cell(numChildren,1);
            %             %numChildren = dom.getChildNodes.getLength();
            %             for i =0:numChildren-1
            %                 printf('%s\n',firstLevel.item(i));
            %             end
            %             % firstLevel.item(0).getElementsByTagName('projectName').item(0).getFirstChild.getData;
            %             %str2double(dom.getDocumentElement.getElementsByTagName('EpochLength').item(0).getTextContent);
            %
            xmlStruct = read_xml(xmlFilename);
        end
        
        % ======================================================================
        %> @brief Parses the file with file identifier fid to find structure
        %> and substructure value pairs.  If pstruct is passed as an input argument
        %> then the file substructure and value pairings will be put into it as new
        %> or overwriting fields and subfields.  If pstruct is not included then a
        %> new/original structure is created and returned.
        %> fid must be open for this to work.  fid is not closed at the end
        %> of this function.
        %> @param fid file identifier to parse
        %> @param pstruct (optional) If included, pstruct fields will be
        %> overwritten if existing, otherwise they will be added and
        %> returned.
        %> @retval pstruct return value of tokens2struct call.
        % ======================================================================
        function pstruct = loadStruct(fid,pstruct)
        %pstruct = loadStruct(fid,{pstruct})
            
            % Hyatt Moore IV (< June, 2013)
            
            % ferror(fid,'clear');
            % status = fseek(fid,0,'bof'); %move to the beginning of file
            % ferror(fid);
            if(~isempty(fopen(fid)))
                file_open = true;
                pat = '^([^\.\s]+)|\.([^\.\s]+)|\s+(.*)+$';
            else
                file_open = false;
            end
            

            if(nargin<2)
                pstruct = struct;                
            end;
            
            while(file_open)
                try
                curline = fgetl(fid); %remove leading and trailing white space
                if(~ischar(curline))
                    file_open = false;
                else
                    tok = regexp(strtrim(curline),pat,'tokens');
                    if(numel(tok)>1 && ~strcmpi(tok{1},'-last') && isempty(strfind(tok{1}{1},'#')))
                        %hack/handle the empty case
                        if(numel(tok)==2)
                            tok{3} = {''};
                        end
                        pstruct = CLASS_settings.tokens2struct(pstruct,tok);
                    end
                end;
                catch me
                    showME(me);
                    fclose(fid);
                    file_open = false;
                end  
            end;
        end
        
        
        % ======================================================================
        %> @brief helper function for loadStruct
        %> @param pstruct parent struct by which the tok cell will be converted to
        %> @tok cell array - the last cell is the value to be assigned while the
        %> previous cells are increasing nestings of the structure (i.e. tok{1} is
        %> the highest parent structure, tok{2} is the substructure of tok{1} and so
        %> and on and so forth until tok{end-1}.  tok{end} is the value to be
        %> assigned.
        %> the tok structure is added as a child to the parent pstruct.
        %> @retval pstruct Input pstruct with any additional tok
        %> children added.
        % ======================================================================
        function pstruct = tokens2struct(pstruct,tok)
            if(numel(tok)>1 && isvarname(tok{1}{:}))
                
                fields = '';
                
                for k=1:numel(tok)-1
                    fields = [fields '.' tok{k}{:}];
                end;
                
                %     if(isempty(str2num(tok{end}{:})))
                if(isnan(str2double(tok{end}{:})))
                    evalmsg = ['pstruct' fields '=tok{end}{:};'];
                else
                    evalmsg = ['pstruct' fields '=str2double(tok{end}{:});'];
                end;
                
                eval(evalmsg);
            end;
        end
        
        
        %> @brief Parses the parameters information file as a
        %> struct.
        %> @note This had previously been part of the
        %> CLASS_events_container class.
        %> param detectionPath
        %> param detectionInfFile
        %> @retval detectionStruct Struct describing the contents of the
        %> detection methods' information file.  Fields include:
        %> - @c mfile Cell of function names (.m files sans '.m')
        %> corresponding to each detection method.
        %> - @c evt_label Cell of string labels describing each detection
        %> method.
        %> - @c num_reqd_indices Vector containing the number of channels required for each
        %> method.
        %> - @c param_gui Cell of strings listing editor function for adjusting each detection
        %> methods parameters. (e.g. plist_editor_dlg)
        %> - @c batch_mode_label (This is going to be removed)
        %> - @c params Parameters for each detection method; place holder for use anon (i.e. [] initially)
        function detectionStruct = loadParametersInf(detectionPath,detectionInfFile)
            %loads a struct from the detection.inf file which contains the
            %various detection methods and parameters that the sev has
            %preloaded - or from filter.inf
            if(nargin<2)
                if(nargin<1)
                    detectionPath = '+detection';
                end
                [~, name, ~] = fileparts(detectionPath);
                name = strrep(name,'+','');
                detectionInfFile = strcat(name,'.inf');
            end            
            
            detection_inf = fullfile(detectionPath,detectionInfFile);
            
            if(exist(detection_inf,'file'))
                plusIndex = strfind(detectionPath,'+');
                if(~isempty(plusIndex))
                    importPath = strcat(strrep(detectionPath,'+',''),'.*');
                    import(importPath);
                end
                
                fid = fopen(detection_inf,'r');
                T = textscan(fid,'%s%s%n%s%s','commentstyle','#');
                [mfile, evt_label, num_reqd_indices, param_gui, batch_mode_label] = T{:};
                fclose(fid);
                params = cell(numel(mfile),1);
            else
                detection_files = dir(fullfile(detectionPath,'detection_*.m'));
                num_files = numel(detection_files);
                mfile = cell(num_files,1);
                [mfile{:}]=detection_files.name;
                
                num_reqd_indices = zeros(num_files,1);
                evt_label = mfile;
                
                params = cell(num_files,1);
                param_gui = cell(num_files,1);
                batch_mode_label = cell(num_files,1);
                batch_mode_label(:) = {'Unspecified'};
                param_gui(:)={'none'}; %expand none to fill this up..
                %                     http://blogs.mathworks.com/loren/2008/01/24/deal-or-n
                %                     o-deal/
                
            end
            
            detectionStruct.mfile = mfile;
            detectionStruct.evt_label = evt_label;
            detectionStruct.num_reqd_indices = num_reqd_indices;
            detectionStruct.param_gui = param_gui;
            detectionStruct.batch_mode_label = batch_mode_label;
            detectionStruct.params = params; %for storage of parameters as necessary
            
        end %end loadDetectionMethodsInf   
        
        % --------------------------------------------------------------------
        % @brief Initializes all .plist files in the +detection directory
        % to their algorithms' (.m file) default parameters as obtained by
        % calling the algorithm's method function (.m file) with zero
        % arguments.
        %> @param detectionPath String of the fullpathname where detection
        %> methods are stored on disk.
        %> @param detectionInfFilename String of the filename (located in
        %> detectionPath) with information describing each detection
        %> method's parameters.        
        function resetPlistFiles(detectionPath, detectionInfFilename)
            methods = CLASS_settings.loadParametersInf(detectionPath,detectionInfFilename);

            if(isstruct(methods)&& isfield(methods,'mfile'))
                try
                    for m=1:numel(methods.mfile)
                        param_gui = methods.param_gui{m};
                        if(~isempty(param_gui) && strcmpi(param_gui,'plist_editor_dlg'))
                            mfile = methods.mfile{m};
                            pfile = fullfile(detectionPath,[methods.mfile{m},'.plist']);
                            if(exist(fullfile(detectionPath,strcat(mfile,'.m')),'file'))
                                %get defaults and sciddadle.
                                try
                                    params = feval(strcat(CLASS_settings.detectorPackagePrefixStr,mfile));
                                    plist.saveXMLPlist(pfile,params);
                                catch me
                                    fprintf('--------------\n')
                                    showME(me);
                                    fprintf('There was an error with loading defaults from %s.  Check that the file exists.\n',mfile);
                                    fprintf('--------------\n')
                                end
                            else
                                fprintf('There was an error with loading defaults from %s.  Check that the file exists.\n',mfile);
                            end
                        end
                    end
                catch me
                    showME(me);
                    fprintf('There was an error with loading defaults on file %u of %u.\n',m,numel(methods.mfile));
                end                
            else
                fprintf('Unable to load detection method information file (%s)\n',fullfilename(detectionPath,detectionInfFilename));
            end
        end            
        

    end
    
    methods
        
        % --------------------------------------------------------------------
        % ======================================================================
        %> @brief Class constructor
        %>
        %> Stores the root path and parameters file and invokes initialize
        %> method.  Default settings are used if no parameters filename is
        %> provided or found.
        %>
        %> @param string rootpathname Pathname of SEV execution directory (string)
        %> @param string parameters_filename Name of text file to load
        %> settings from.
        %>
        %> @return instance of the classDocumentationExample class.
        % =================================================================
        function obj = CLASS_settings(rootpathname,parameters_filename)
            %initialize settings in SEV....
            
            
            if(nargin==0)
                obj.rootpathname = fileparts(mfilename('fullpath'));
                
            else
                obj.rootpathname = rootpathname;
                obj.parameters_filename = parameters_filename;
                obj.initialize();
            end
        end
        

        
        % --------------------------------------------------------------------
        % =================================================================
        %> @brief Constructor helper function.  Initializes class
        %> either from parameters_filename if such a file exists, or
        %> hardcoded default values (i.e. setDefaults).        %>
        %> @param obj instance of the CLASS_settings class.
        % =================================================================
        function initialize(obj)
            %initialize global variables in SEV....
            obj.fieldNames = {'VIEW','BATCH_PROCESS','PSD','MUSIC'};
            obj.setDefaults();
            
            full_paramsFile = fullfile(obj.rootpathname,obj.parameters_filename);
            
            if(exist(full_paramsFile,'file'))                
                paramStruct = obj.loadParametersFromFile(full_paramsFile);
                if(~isstruct(paramStruct))
                    fprintf('\nWarning: Could not load parameters from file %s.  Will use default settings instead.\n\r',full_paramsFile);
                    
                else
                    fnames = fieldnames(paramStruct);
                    
                    if(isempty(fnames))
                        fprintf('\nWarning: Could not load parameters from file %s.  Will use default settings instead.\n\r',full_paramsFile);
                    else
                    
                        for f=1:numel(obj.fieldNames)
                            cur_field = obj.fieldNames{f};
                            if(~isfield(paramStruct,cur_field) || ~isstruct(paramStruct.(cur_field)))
                                fprintf('\nWarning: Could not load parameters from file %s.  Will use default settings instead.\n\r',full_paramsFile);
                                return;
                            else
                                structFnames = fieldnames(obj.(cur_field));
                                for g= 1:numel(structFnames)
                                    cur_sub_field = structFnames{g};
                                    %check if there is a corruption
                                    if(~isfield(paramStruct.(cur_field),cur_sub_field))
                                        fprintf('\nSettings file corrupted.  The %s.%s parameter is missing.  Using initial/default SEV settings\n\n', cur_field,cur_sub_field);
                                        return;
                                    end                            

                                end
                            end
                        end
                        
                        for f=1:numel(fnames)
                            obj.(fnames{f}) = paramStruct.(fnames{f});
                        end
                    end
                end
            end
        end
        
        % -----------------------------------------------------------------
        % =================================================================
        %> @brief Activates GUI for editing single study mode settings
        %> (<b>VIEW</b>,<b>PSD</b>,<b>MUSIC</b>)
        %>
        %> @param obj instance of CLASS_settings.        
        %> @retval wasModified a boolean value; true if any changes were
        %> made to the settings in the GUI and false otherwise.
        % =================================================================
        % --------------------------------------------------------------------
        function wasModified = update_callback(obj,settingsField)
            wasModified = false;
            switch settingsField
                case 'PSD'
                    newPSD = psd_dlg(obj.PSD);
                    if(newPSD.modified)
                        newPSD = rmfield(newPSD,'modified');
                        obj.PSD = newPSD;
                        wasModified = true;
                    end;                
                case 'MUSIC'
                    wasModified = obj.defaultsEditor('MUSIC');
                case 'CLASSIFIER'
                    path = fullfile(obj.rootpathname,obj.VIEW.detection_path);
                    plist_editor_dlg([],path);
                case 'FILTER'
                    path = fullfile(obj.rootpathname,obj.VIEW.filter_path);
                    plist_editor_dlg([],path);
                case 'BATCH_PROCESS'
                case 'DEFAULTS'
                    wasModified= obj.defaultsEditor();
            end
        end
        
        % -----------------------------------------------------------------
        % =================================================================
        %> @brief Activates GUI for editing single study mode settings
        %> (<b>VIEW</b>,<b>PSD</b>,<b>MUSIC</b>)
        %>
        %> @param obj instance of CLASS_settings class.
        %> @retval wasModified a boolean value; true if any changes were
        %> made to the settings in the GUI and false otherwise.
        % =================================================================
        function wasModified = defaultsEditor(obj,optional_fieldName)
            tmp_obj = obj.copy();
            if(nargin<2)
                lite_fieldNames = {'VIEW','PSD','MUSIC'}; %these are only one structure deep
            else
                lite_fieldNames = optional_fieldName;
                if(~iscell(lite_fieldNames))
                    lite_fieldNames = {lite_fieldNames};
                end
            end
            
            tmp_obj.fieldNames = lite_fieldNames;
            tmp_obj = pair_value_dlg(tmp_obj);
            if(~isempty(tmp_obj))
                for f=1:numel(lite_fieldNames)
                    fname = lite_fieldNames{f};
                    obj.(fname) = tmp_obj.(fname);
                end
                wasModified = true;
                tmp_obj = []; %clear it out.

            else
                wasModified = false;
            end
        end
        
        % -----------------------------------------------------------------
        % =================================================================
        %> @brief saves all of the fields in saveStruct to the file filename
        %> as a .txt file
        %> @param obj instance of CLASS_settings class.
        %> @param saveStruct (optional) structure of parameters and values
        %> to save to the text file identfied by obj property filename or
        %> the input paramater filename.  Enter empty (i.e., []) to save
        %> all available fields
        %> @param filename (optional) name of file to save parameters to.
        % =================================================================
        % -----------------------------------------------------------------
        function saveParametersToFile(obj,dataStruct2Save,filename)
            %written by Hyatt Moore IV sometime during his PhD (2010-2011'ish)
            %
            %last modified
            %   9/28/2012 - added CHANNELS_CONTAINER.saveSettings() call - removed on
            %   9/29/2012
            %   7/10/2012 - added batch_process.images field
            %   5/7/2012 - added batch_process.database field
            %   8/24/2013 - import into settings class; remove globals
            
            if(nargin<3)
                filename = obj.parameters_filename;
                if(nargin<2)
                    dataStruct2Save = [];
                end                
            end
            
            if(isempty(dataStruct2Save))
                fnames = obj.fieldNames;
                for f=1:numel(fnames)
                    dataStruct2Save.(fnames{f}) = obj.(fnames{f});               
                end
            end
            
            fid = fopen(filename,'w');
            if(fid<0)
                [path, fname, ext]  = fileparts(filename);
                fid = fopen(fullfile(pwd,[fname,ext]));
            end
            if(fid>0)
                fprintf(fid,'-Last saved: %s\r\n\r\n',datestr(now)); %want to include the '-' sign to prevent this line from getting loaded in the loadFromFile function (i.e. it breaks the regular expression pattern that is used to load everything else).
                
                saveStruct(fid,dataStruct2Save)
                %could do this the other way also...
                %                     %saves all of the fields in inputStruct to a file
                %                     %filename as a .txt file
                %                     fnames = fieldnames(saveStruct);
                %                     for k=1:numel(fnames)
                %                         fprintf(fid,'%s\t%s\n',fnames{k},num2str(saveStruct.(fnames{k})));
                %                     end;
                fclose(fid);
            end
        end
        
        
        
        % --------------------------------------------------------------------
        %> @brief Initializes all .plist files in the +detection directory
        %> to their algorithms' (.m file) default parameters as obtained by
        %> calling the algorithm's method (.m file) with zero arguments.
        %> @param obj instance of CLASS_settings class.
        % --------------------------------------------------------------------
        function initializeDetectors(obj)
            detectionPath = fullfile(obj.rootpathname,obj.VIEW.detection_path);
            obj.resetPlistFiles(detectionPath,obj.VIEW.detection_inf_file);
        end
        
        % --------------------------------------------------------------------
        %> @brief Initializes all .plist files in the +filter directory
        %> to tsynchheir algorithms' (.m file) default parameters as obtained by
        %> calling the filter (.m file) with zero arguments.
        %> @param obj instance of CLASS_settings class.        
        % --------------------------------------------------------------------
        function initializeFilters(obj)
            filterPath = fullfile(obj.rootpathname,obj.VIEW.filter_path);
            obj.resetPlistFiles(filterPath,obj.VIEW.filter_inf_file);
        end
        
        % --------------------------------------------------------------------
        %> @brief sets default values for the class parameters listed in
        %> the input argument <i>fieldNames</i>.
        %> @param obj instance of CLASS_settings.
        %> @param fieldNames (optional) string identifying which of the object's
        %> parameters to reset.  Multiple field names may be listed using a
        %> cell structure to hold additional strings.  If no argument is provided or fieldNames is empty
        %> then object's <i>fieldNames</i> property is used and all
        %> parameter structs are reset to their default values.
        % --------------------------------------------------------------------
        function setDefaults(obj,fieldNames)
            
            if(nargin<2)
                fieldNames = obj.fieldNames; %reset all then
            end
            
            if(~iscell(fieldNames))
                fieldNames = {fieldNames};
            end
            
            for f = 1:numel(fieldNames)
                switch fieldNames{f}
                    case 'VIEW'
                        obj.VIEW.src_edf_pathname = '.'; %initial directory to look in for EDF files to load
                        obj.VIEW.src_edf_filename = ''; %initial filename to suggest when trying to load an .EDF
                        obj.VIEW.hypnogram_pathname_is_edf_pathname = 1; %Use edf pathname for staging pathname when true, otherwise use sta_pathname to locate staging files.
                        obj.VIEW.hypnogram_pathname = '.'; %initial directory to look in for EDF files to load
                        obj.VIEW.src_event_pathname_is_edf_pathname = 1; %Use edf pathname for src event pathname when true, otherwise use .src_event_pathname;
                        obj.VIEW.src_event_pathname = '.'; %initial directory to look in for EDF files to load
                        obj.VIEW.batch_folder = '.'; %'/Users/hyatt4/Documents/Sleep Project/EE Training Set/';
                        obj.VIEW.yDir = 'normal';  %or can be 'reverse'
                        obj.VIEW.standard_epoch_sec = 30; %perhaps want to base this off of the hpn file if it exists...
                        obj.VIEW.samplerate = 100;
                        obj.VIEW.unknown_stage = 7; %this is the default value to use when we don't have a staging file.  
                        obj.VIEW.screenshot_path = obj.rootpathname; %initial directory to look in for EDF files to load
                        
                        obj.VIEW.text_channels_filename = '';
                        obj.VIEW.text_channels_samplerate = 100;
                        obj.VIEW.channelsettings_file = 'channelsettings.mat'; %used to store the settings for the file
                        obj.VIEW.output_pathname = fullfile(fileparts(mfilename('fullpath')),'output');
                        if(~isdir(obj.VIEW.output_pathname))
                            try
                                mkdir(obj.VIEW.output_pathname);
                            catch me
                                showME(me);
                                obj.VIEW.output_pathname = fileparts(mfilename('fullpath'));
                            end;
                        end
                        obj.VIEW.detection_inf_file = 'detection.inf';
                        obj.VIEW.detection_path = '+detection';
                        obj.VIEW.filter_path = '+filter';
                        obj.VIEW.filter_inf_file = 'filter.inf';
                        obj.VIEW.database_inf_file = 'database.inf';
                        obj.VIEW.parameters_filename = '_sev.parameters.txt';
                    case 'MUSIC'                        
                        obj.MUSIC.window_length_sec = 2;
                        obj.MUSIC.interval_sec = 2;
                        obj.MUSIC.num_sinusoids = 6;
                        obj.MUSIC.freq_min = 0; %display min
                        obj.MUSIC.freq_max = 30; %display max                        
                    case 'PSD'                        
                        obj.PSD.wintype = 'hann';
                        obj.PSD.removemean = 'true';
                        obj.PSD.FFT_window_sec = 2; %length in second over which to calculate the PSD
                        obj.PSD.interval = 2; %how often to take the FFT's
                        obj.PSD.freq_min = 0; %display min
                        obj.PSD.freq_max = 30; %display max                        
                    case 'BATCH_PROCESS'
                        obj.BATCH_PROCESS.edf_folder = '.'; %the edf folder to do a batch job on.
                        obj.BATCH_PROCESS.output_path.parent = 'output';
                        obj.BATCH_PROCESS.output_path.roc = 'ROC';
                        obj.BATCH_PROCESS.output_path.power = 'PSD';
                        obj.BATCH_PROCESS.output_path.events = 'events';
                        obj.BATCH_PROCESS.output_path.artifacts = 'artifacts';
                        obj.BATCH_PROCESS.output_path.images = 'images';
            
                        %power spectrum analysis
                        obj.BATCH_PROCESS.output_files.psd_filename = 'psd.txt';
                        obj.BATCH_PROCESS.output_files.music_filename = 'MUSIC';
                        
                        %artifacts and events
                        obj.BATCH_PROCESS.output_files.events_filename = 'evt.';
                        obj.BATCH_PROCESS.output_files.artifacts_filename = 'art.';
                        obj.BATCH_PROCESS.output_files.save2txt = 1;
                        obj.BATCH_PROCESS.output_files.save2mat = 0;
                        
                        %database supplement
                        obj.BATCH_PROCESS.database.save2DB = 0;
                        obj.BATCH_PROCESS.database.filename = 'database.inf';
                        obj.BATCH_PROCESS.database.choice = 1;
                        obj.BATCH_PROCESS.database.auto_config = 1;
                        obj.BATCH_PROCESS.database.config_start = 1;
                        
                        %summary information
                        obj.BATCH_PROCESS.output_files.cumulative_stats_flag = 0;
                        obj.BATCH_PROCESS.output_files.cumulative_stats_filename = 'SEV.cumulative_stats.txt';
                        
                        obj.BATCH_PROCESS.output_files.individual_stats_flag = 0;
                        obj.BATCH_PROCESS.output_files.individual_stats_filename_suffix = '.stats.txt';
                        
                        obj.BATCH_PROCESS.output_files.log_checkbox = 1;
                        obj.BATCH_PROCESS.output_files.log_filename = '_log.txt';
                        
                        %images
                        obj.BATCH_PROCESS.images.save2img = 1;
                        obj.BATCH_PROCESS.images.format = 'PNG';
                        obj.BATCH_PROCESS.images.limit_count = 100;
                        obj.BATCH_PROCESS.images.limit_flag = 1;
                        obj.BATCH_PROCESS.images.buffer_sec = 0.5;
                        obj.BATCH_PROCESS.images.buffer_flag = 1;
                        
                        %export
                        obj.BATCH_PROCESS.export.edf_folder = '.'; %the edf folder to do a batch job on.
                        obj.BATCH_PROCESS.export.output_folder = '.';                        
                end
            end
        end
    end
    
    methods (Access = private)
        
        % -----------------------------------------------------------------
        %> @brief create a new CLASS_settings object with the same property
        %> values as this one (i.e. of obj)
        %> @param obj instance of CLASS_settings
        %> @retval copyObj a new instance of CLASS_settings having the same
        %> property values as obj.
        % -----------------------------------------------------------------
        function copyObj = copy(obj)
            copyObj = CLASS_settings();
            
            props = properties(obj);
            if(~iscell(props))
                props = {props};
            end
            for p=1:numel(props)
                pname = props{p};
                if(~strcmpi('detectorPackagePrefixStr',pname))
                    copyObj.(pname) = obj.(pname);
                end
            end
        end
 
    end
end
