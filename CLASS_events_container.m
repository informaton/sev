%> @file CLASS_events_container.m
%> @brief CLASS_events_container is a wrapper for CLASS_events.
% ======================================================================
%> @brief CLASS_events_container assists in organizing, updating, and
%> adjusting instances of CLASS_events.  

% History 
% Written by Hyatt Moore IV
% updated 9.30.2012 - incorporate event UI components of SEV into this
% class
% 1/8/2013 - added refresh method here for refreshing event calls when
% channel data changes in the SEV due to filtering and such.  May want to
% add a safety check or lock to not update when detection method is very
% time consuming
% 1-2/?/2013 - added field for CHANNELS_CONTAINER pointer 
% 2/6/2013 - added StageStruct here
% ======================================================================
classdef CLASS_events_container < handle

    properties
        cell_of_events;
        %>size of cell_of_events (and also channel_vector)
        num_events;
        
        %> @brief vector of channel indices that are associated with the corresponding elements of cell_of_events
        %> a value of 0 in this vector represents a
        %> nonassociated event, likely from an external
        %> (file) source
        %> this is useful when removing events, and needing
        %> to make sure that they are no longer referenced
        %> by the source channel or when editing an event
        channel_vector;
        %> @brief used to initialize events when initialization parameters
        %> are not provided
        defaults; 
        %> index of the event to be used as truth in ROC curves
        roc_truth_ind; 
        %> index of the event to be used for the estimate in ROC curves 
        roc_estimate_ind; 
        %> index of the event to b used as the artifact index in the ROC curves...
        roc_artifact_ind; 
        %> two column matrix of valid sample ranges to compare ROC events over
        roc_comparison_range; 
        %> vector of plus-one stage values selected from settings_roc_dlg()        
        roc_stage_selection; 
        
        %> boolean flag that indicates if the roc_axes has been updated or not with the latest changes
        roc_axes_needs_update; 
        %> summary statistics structure for the current event (cur_event_index) when selected.  default is empty (not selected or calculated)
        summary_stats; 
        %> @brief boolean flag that indicates if the axes needs to be
        %> updated or not for events
        summary_stats_axes_needs_update; 
        %> handle to the figure used to display summary_stats
        summary_stats_figure_h; 
        %> handle to the table which holds the summary_stats structure        
        summary_stats_uitable_h; 
        %> @brief structure to hold settings of summary stats to display in
        %> a parent axes 
        %> - .type  - a string 'count' or 'dur_sec'
        %> - .show_density - true or false
        summary_stats_settings;  
                           
        %> folder that contains the detection algorithms and hopefully the detection.inf file
        detection_path; 
        %>@brief filename containing meta deta for detection algorithms to load
        %> into SEV - set externally at the moment
        detection_inf_file; 

        %> event group currently selected by the user.... - default is 0; no selection
        cur_event_index; 
        %> where these things will be plotted too.
        parent_axes; 
        parent_fig;
        
        %> contextmenu handle to attach to event patches (the rectangles shown for each event instance)
        children_contextmenu_patch_h;
        %> contextmenu handle to attach to event labels
        children_contextmenu_label_h; 
        %> vector containing indices of the events that should be plotted
        %> on the time line axes.
        event_indices_to_plot; 
        %> POINTER (I hope) to an instance object of CLASS_channels_container
        CHANNELS_CONTAINER; 
        %> structure of stages
        stageStruct; 
    end
    
    methods
        % =================================================================
        %> @brief Constructor
        %> @param obj instance of CLASS_events_container class.
        %> @param handle to the SEV gui
        %> @param handle to the parent axes to show events on (child of
        %> figure handle        
        %> @param base_samplerate Base sample rate for showing events (e.g.
        %> 100)
        %> @param stageStruct Struct of staging values loaded by SEV
        %> @retval obj instance of CLASS_events_container class.
        % =================================================================
        function obj = CLASS_events_container(parent_fig,parent_axes, base_samplerate, stageStruct)
            
            obj.CHANNELS_CONTAINER = [];


            if(nargin == 0)
                parent_fig = [];
                parent_axes=  [];
                base_samplerate = [];
                stageStruct = [];
            end
            if(nargin<4)
                stageStruct = [];
                if(nargin<3)
                    base_samplerate = [];
                end                
            end
            obj.stageStruct = stageStruct;
            obj.event_indices_to_plot = [];
            obj.cell_of_events = {};
            obj.num_events = 0;
            obj.defaults.parent_channel_index = 0;
            obj.defaults.parent_channel_title = 'External';
            obj.defaults.parent_channel_samplerate = base_samplerate;
            
            obj.roc_truth_ind = [];
            obj.roc_estimate_ind = [];
            obj.roc_artifact_ind =[];            
            obj.roc_comparison_range = [];
            obj.roc_stage_selection = [];
            obj.roc_axes_needs_update = false;
            obj.detection_path = '+detection';
            obj.cur_event_index = 0;
            obj.summary_stats_axes_needs_update = false;
            obj.summary_stats = [];
            obj.summary_stats_figure_h = [];
            obj.summary_stats_uitable_h = [];
            obj.summary_stats_settings.show_density = 'false';
            obj.summary_stats_settings.type = 'count';
            
            if(nargin>=2 && ~isempty(parent_fig)&&~isempty(parent_axes))
                
                obj.parent_fig = parent_fig;
                obj.parent_axes = parent_axes;
                
                obj.makeContextmenus()
            else
                obj.parent_fig = [];
                obj.parent_axes = []; 
                obj.children_contextmenu_patch_h = [];
                obj.children_contextmenu_label_h = [];
  
            end

        end

        % =================================================================
        %> @brief Load detection parameters from the .plist or .mat file
        %> that associated with the passed detector function filename.  These
        %> parameters can be passed directly to the detector function and are
        %> helpful in keeping track of user preferences.
        %> @param obj instance of CLASS_events_container class.
        %> @param detectorFcn The filename of the detector function to get parameters for.
        %> @retval obj instance of CLASS_events_container class.
        %> @retval paramStruct A structure containing the detectorFcn
        %> parameters as obtained from the .plist or .mat file.  
        % =================================================================        
        function paramStruct = loadDetectionParams(obj,detectorFcn)
            pfile = fullfile(obj.detection_path,strcat(strrep(detectorFcn,'.m',''),'.plist'));
            matfile = fullfile(obj.detection_path,strcat(strrep(detectorFcn,'.m',''),'.mat'));
            paramStruct = [];
            if(exist(pfile,'file'))
                try
                    paramStruct = plist.loadXMLPlist(pfile);
                catch me
                    fprintf(1,'Could not load parameters from %s directly.\n',pfile);
                    showME(me);
                end
            elseif(exist(matfile,'file'))
                try
                    matfileStruct = load(matfile);
                    paramStruct = matfileStruct.params;
                catch me
                    fprintf(1,'Could not load parameters from %s directly.\n',matfile);
                    showME(me);
                end
            end
        end
        
        % =================================================================
        %> @brief Evaluates a SEV detection algorithm using the passed
        %> parameters.  
        %> @param obj instance of CLASS_events_container class.
        %> @param shortDetectorFcn Filename (sans pathname) of the detector
        %> to evaluate.
        %> @source_indices The source indices or source data (i.e. raw
        %> digital sample values) to evaluate for events by the detector.
        %> @param params A struct containing detector specific parameters
        %> which refine the detector's behavior.  These are specific to the
        %> detector and are optional.
        %> @retval obj instance of CLASS_events_container class.
        %> @retval detectStruct Structure containing the detection result
        %> output.
        %> @retval source_pStruct The parameters that were used/passed to
        %> the detector function (this is params if params is entered as an
        %> argument and not empty).
        %> @note This function calls loadDetectionParams if the params
        %> argument is empty or not given and will do a dummy evaluation of
        %> the detector function to try and generate the default parameters
        %> which can then be subsequently loaded and then run a second time
        %> (for real, yo).  
        % =================================================================
        function [detectStruct, source_pStruct] = evaluateDetectFcn(obj,shortDetectorFcn,source_indices,params)
            localDetectorFcn = strcat(strrep(obj.detection_path,'+',''),'.',shortDetectorFcn);

            if(iscell(source_indices))
                source_indices = cell2mat(source_indices);
            end
            if(nargin<4 || isempty(params))
                params = obj.loadDetectionParams(shortDetectorFcn);
                
                %no parameters available?
                if(isempty(params))
                    disp('No parameters to load here - debug here and run detector with no arguments to generate params file');
                    localDetectorFcn = strcat(strrep(obj.detection_path,'+',''),'.',shortDetectorFcn);
                    
                    %run an empty version once to generate the detection
                    %parameters file
                    try
                        feval(localDetectorFcn,rand(30,1));
                    catch me
                    end
                    params = obj.loadDetectionParams(shortDetectorFcn);                
                end                
            end
            source_pStruct = params;
            params.samplerate = obj.CHANNELS_CONTAINER.getSamplerate(source_indices(1));

            if(numel(source_indices)>1)
                data = cell(size(source_indices));

                for c=1:numel(source_indices)
                    data{c} = obj.CHANNELS_CONTAINER.getData(source_indices(c));
                end
            else
                data = obj.CHANNELS_CONTAINER.getData(source_indices);
            end
            detectStruct = feval(localDetectorFcn,data,params,obj.stageStruct);
        end
        
        % =================================================================
        %> @brief Sets the stageStruct property
        %> @param obj instance of CLASS_events_container class.
        %> @param stageStruct A stage structure.
        %> @retval obj instance of CLASS_events_container class.
        % =================================================================
        function setStageStruct(obj,stageStruct)
            obj.stageStruct = stageStruct;
        end
        
        % =================================================================
        %> @brief Sets SEV's default sample rate
        %> @param obj instance of CLASS_events_container class.
        %> @param sampleRate The sample rate to set.
        %> @retval obj instance of CLASS_events_container class.
        % =================================================================
        function setDefaultSamplerate(obj,sampleRate)
            if(sampleRate>0)
                obj.defaults.parent_channel_samplerate = sampleRate;
            end
        end
        
        % =================================================================
        %> @brief Creates context menus for placing on detection labels
        %> (i.e. the detector name that is displayed to the left of the main
        %> view in SEV's single study mode) and on the event's themselves
        %> (i.e. the patches that show the location of the event in the main
        %> view).
        %> <br> Context menus for the detection lables include:
        %> - Next Event Epoch
        %> - Previous Event Epoch
        %> - Delete Event
        %> - Rename Event
        %> - Show Histogram
        %> - Summary Statistics (Popout)
        %> - Export to workspace
        %> - Change Color
        %> <br> Context menus for the 
        %> @param obj instance of CLASS_events_container class.
        %> @param obj instance of CLASS_events_container class.
        % =================================================================
        function makeContextmenus(obj)
            %label contextmenu for the label on the left hand side
            label_contextmenu_h = uicontextmenu('parent',obj.parent_fig,...
                'callback',@obj.contextmenu_label_callback);%,get(parentAxes,'parent'));
            uimenu(label_contextmenu_h,'Label','Next Event Epoch',...
                'separator','off',...
                'callback',@obj.contextmenu_label_nextEvent_callback);
            uimenu(label_contextmenu_h,'Label','Previous Event Epoch',...
                'separator','off',...
                'callback',@obj.contextmenu_label_previousEvent_callback);
            uimenu(label_contextmenu_h,'Label','Delete Event',...
                'separator','on',...
                'callback',@obj.contextmenu_label_deleteEvent_callback);
            uimenu(label_contextmenu_h,'Label','Rename Event',...
                'separator','off',...
                'callback',@obj.contextmenu_label_renameEvent_callback);
            uimenu(label_contextmenu_h,'Label','Show Histogram',...
                'separator','on',...
                'callback',@obj.contextmenu_changeColorcallback);
            uimenu(label_contextmenu_h,'Label','Summary Statistics (Popout)',...
                'separator','off',...
                'callback',@obj.contextmenu_label_summaryStats_callback);
            uimenu(label_contextmenu_h,'Label','Export to workspace',...
                'separator','off',...
                'callback',@obj.contextmenu_label_export2workspace_callback);
            uimenu(label_contextmenu_h,'Label','Change Color',...
                'separator','on',...
                'callback',@obj.contextmenu_changeColor_callback);
            
            obj.children_contextmenu_label_h = label_contextmenu_h;
            
            %patch contextmenu for the individual patches associated with
            %each event instance
            contextmenu_patch_h = uicontextmenu('callback',@obj.contextmenu_patch_callback,'parent',obj.parent_fig);
            uimenu(contextmenu_patch_h,'Label','Change Color','separator','off','callback',@obj.contextmenu_changeColor_callback);
            uimenu(contextmenu_patch_h,'Label','Adjust Offset','separator','off','callback',@obj.contextmenu_patch_adjustOffset_callback);
            uimenu(contextmenu_patch_h,'Label','Show Histogram','separator','off','callback',@obj.contextmenu_changeColorcallback);
            uimenu(contextmenu_patch_h,'Label','Remove','separator','on','callback',@obj.contextmenu_patch_removeInstance_callback);
            obj.children_contextmenu_patch_h = contextmenu_patch_h;
            
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function detectorID = getDetectorID(obj,DBstruct, event_indices)
            %detectorID is a vector of size channel_indices which contains
            %the detector ID key from detectorinfo_t table found in
            %database with configuration stored in DBstruct for children
            %event objects with indices found in event_indices
             if(~isempty(DBstruct))
                 if(~mym())
                     mym('open','localhost',DBstruct.user,DBstruct.password);
                     mym(['USE ',DBstruct.name]);
                 end
                 detectorID = zeros(size(event_indices));
                 for k=1:numel(event_indices)
                     eventObj = obj.getEventObj(event_indices(k));
                     if(~isempty(eventObj))
                         q = mym('SELECT DetectorID, ConfigChannelLabels, configparamstruct as paramStruct FROM DetectorInfo_T WHERE DetectorLabel="{S}" order by configid',eventObj.label);
                         for d=1:numel(q.DetectorID)
                             if((isequal(q.ConfigChannelLabels{d},eventObj.channel_name)|| isequal(char(q.ConfigChannelLabels{d}),eventObj.channel_name)) && isequal(q.paramStruct{d},eventObj.paramStruct))
                                 detectorID(k) = q.DetectorID(d);
                             end
                         end
                     end
                 end
             end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function setDetectorID(obj,DBstruct, event_indices,optional_DetectorID)
            %sets the detectorID for event children objects located at
            %indices stored in event_indices. 
            %optional_DetectorID is a vector of size event_indices with
            %corresponding detector ID values for the detector located in
            %mysql table detectorInfo_T
            if(nargin<4 || isempty(optional_DetectorID))
                optional_DetectorID = obj.getDetectorID(DBstruct,event_indices);
            end
            
            for k=1:numel(event_indices)
                eventObj = obj.getEventObj(event_indices(k));
                if(~isempty(eventObj))
                    eventObj.detectorID = optional_DetectorID(k);
                end
             end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function deleteDatabaseEventRecords(obj, DBstruct,optional_patstudy)
            %database_struct contains fields 'name','user','password', and 'table' for interacting with a mysql database
            %removes the database events when necessary.
            if(~isempty(DBstruct))
                mym('open','localhost',DBstruct.user,DBstruct.password);
                mym(['USE ',DBstruct.name]);
                
                if(nargin>2)
                    patstudy = optional_patstudy;
                    if(numel(patstudy)>=7)
                        pat = '(\w{5})_(\d+)'; %WSC format
                    else
                        pat = '([A-Z]+)(\d+)';  %PTSD format
                    end
                    x=regexp(patstudy,pat,'tokens');
                    x = x{1};
                    PatID = x{1};
                    StudyNum = x{2};
                    
                    q = mym(['SELECT PatStudyKey FROM studyinfo_T WHERE PatID=''',...
                        PatID,''' AND StudyNum=''',StudyNum,'''']);
                    
                    mym('SET autocommit=0');
                    
                    for event_index=1:obj.num_events
                        obj.cell_of_events{event_index}.deleteDataBaseEventRecords(DBstruct.table,q.PatStudyKey);
                    end
                else
                    
                    
                    for k=1:obj.num_events
                        obj.cell_of_events{k}.deleteDataBaseEventRecords(DBstruct.table);
                    end
                end
                
                mym('COMMIT');
                mym('SET autocommit=1');
                
                mym('CLOSE');
                
            end
        end

        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function obj = updateColor(obj,newColor,eventIndex)
            %consider using obj.cur_event_index if only newColor is passed;
            obj.cell_of_events{eventIndex}.updateColor(newColor);
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function obj = calculate_summary_stats(obj)
            %calculates and stores the summary stats for obj.cur_event_index 
            if(obj.cur_event_index>0 && obj.cur_event_index<=obj.num_events)
                obj.summary_stats = obj.getCurrentChild.get_summary_stats(obj.stageStruct);
                obj.summary_stats_axes_needs_update = true;
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function draw_summary_stats(obj, parent_axes)
           %puts the histogram of the summary_stats method 
           count_or_duration_str = obj.summary_stats_settings.type; %count or dur_sec
           show_density = obj.summary_stats_settings.show_density;
           % count is a struct with the following fields
           %    evt_all - numeric count of all events
           %    evt_stage = vector with numeric event count by stage
           % dur_sec is a struct with the following fields
           %    evt_all - duration in seconds of all events
           %    evt_stage = vector with duration of events by stage in seconds
           %    study_all - duration of entire study in seconds
           %    study_stage = vector of stage durations in seconds
           if(~isempty(obj.summary_stats))  
               
               %this just shows the stage count relative to all stages -
               %may be misleading when the stage duration is longer or
               %shorter than the other stages
               if(~show_density)
                   x = 0:numel(obj.summary_stats.(count_or_duration_str).evt_stage)-1;
                   y = obj.summary_stats.(count_or_duration_str).evt_stage/obj.summary_stats.(count_or_duration_str).evt_all;
                   
               %this normalizes the count for all stages - may be a problem
               %with outliers which have a small number
               else
                   x = 0:numel(obj.summary_stats.(count_or_duration_str).evt_stage)-1;
                   y = obj.summary_stats.(count_or_duration_str).evt_stage./obj.summary_stats.(count_or_duration_str).evt_all.*obj.summary_stats.dur_sec.study_stage./obj.summary_stats.dur_sec.study_all;
                   y(isnan(y))= 0;
                   y = y/sum(y);
               end
               bar(parent_axes,x,y);               
           end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function hide(obj,events2hide)
            for k=1:numel(events2hide)
                event_index = events2hide(k);
                if(event_index <=obj.num_events)
                    obj.cell_of_events{event_index}.hide;
                end;
            end;
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function show(obj,event_indices)
            for k=1:numel(event_indices)
                event_index = event_indices(k);
                if(event_index <=obj.num_events && event_index>0)
                    obj.cell_of_events{event_index}.show;
                end;
            end;
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function cell_of_names = get_event_labels(obj)
            cell_of_names = cell(obj.num_events,1);
            for k = 1:obj.num_events
                cell_of_names{k} = obj.cell_of_events{k}.label;
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function event_name = getName(obj,event_index)
            if(event_index>0 && event_index<=obj.num_events)
                event_name = obj.cell_of_events{event_index}.label;
            else
                event_name = '';
            end
        end
        
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function num_events_in_channel = getNumEventsInChannel(obj,class_channel_index)
            if(obj.num_events>0)
                num_events_in_channel = sum(class_channel_index(1)==obj.channel_vector);
            else
                num_events_in_channel = 0;
            end;
        end
        
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval
        % =================================================================
%return the number of events and their total duration in seconds
        %in the cell at event_index
        function [count, time_in_sec] = events_count(obj,event_index)
             if(event_index>0 && event_index<=obj.num_events)
                 event_matrix = obj.cell_of_events{event_index}.start_stop_matrix;
                 count = size(event_matrix,1);
                 time_in_sec = sum(event_matrix(:,2)-event_matrix(:,1))/obj.cell_of_events{event_index}.samplerate;
                 
             else
                 count =  0;
                 time_in_sec = 0;
             end;   
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function rename_event(obj,event_index,event_label)
            %changes the label of the event specified by event_index to
            %event_label if event_label is of type char.
            obj.cell_of_events{event_index}.rename(event_label);
        end

        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        %to be used primarily for interactive additions or edits of
        %existing events by the user
        %single_event  = start_stop vector of the event
        %event_label = string of the events name/label
        %parent_index = index into the obj.CHANNELS_CONTAINER of the
        %associated channel/signal
        %event_index = 0 if this is a new event, otherwise it is the index
        %to be edited/updated
        function [event_index, start_stop_matrix_index] = updateSingleEvent(obj,single_event, class_channel_index, event_label, event_index,start_stop_matrix_index,sourceStruct)
            if(event_index==0)
                paramStruct = [];
                obj.addEvent(single_event,event_label,class_channel_index,sourceStruct,paramStruct);
                event_index = obj.num_events;  %it was added to the end
                start_stop_matrix_index = 1;
            else
                if(start_stop_matrix_index>0 && start_stop_matrix_index<=obj.getEventCount(event_index))                    
                    obj.cell_of_events{event_index}.start_stop_matrix(start_stop_matrix_index,:)=single_event;
                else
                    obj.cell_of_events{event_index}.appendEvent(single_event);
                    start_stop_matrix_index = obj.getEventCount(event_index);
                end
            end;
            %make sure the parent channel knows to redraw this...
            obj.draw_events(event_index);
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function updateYOffset(obj,event_indices,y_offset)
            for e = 1:numel(event_indices)
                event_index = event_indices(e);
                if(event_index>0  && event_index<=obj.num_events)
                    obj.cell_of_events{event_index}.setYOffset(y_offset);
                end
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function updateCurrentEpochStartX(obj,event_indices,start_x)            
            %if the parent (i.e. channel) has moved up/down, we want to
            %make sure the attached events (event_indices) are adjusted accordingly
            for k=1:numel(event_indices)
                index = event_indices(k);
                if(index>0  && index<=obj.num_events)
                    childobj = obj.cell_of_events{index};
                    childobj.setCurrentEpochStartX(start_x);                    
                end
                
            end
        end

        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function show_labels(obj, event_indices)
            for k=1:numel(event_indices)
                index = event_indices(k);
                if(index>0  && index<=obj.num_events)
                    childobj = obj.cell_of_events{index};
                    childobj.showLabel(obj.range(1),obj.offset);
                    childobj.showParameterValues(obj.range(1),obj.offset);
                end
            end             
        end
        
        % =================================================================
        %> @brief calls CLASS_event's member function draw() for objects at
        %> event_indices
        %> @param obj instance of CLASS_events_container class.
        %> @param event_indices vector of event indices to draw
        %> @retval object of class CLASS_events_container
        % =================================================================
        function draw_events(obj,event_indices)
             if(nargin<2 || isempty(event_indices))
                 event_indices = obj.event_indices_to_plot; 
             end
            for k=1:numel(event_indices)
                index = event_indices(k);
                if(index>0  && index<=obj.num_events)
                    obj.cell_of_events{index}.draw();
                end                
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function num_start_stops = getEventCount(obj,event_index)
            %returns the number of start/stop pairs in the event object
            %located at event_index. 
            if(event_index>0 && event_index<=obj.num_events)
                num_start_stops = size(obj.cell_of_events{event_index}.start_stop_matrix,1);
            else
                num_start_stops = 0;
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function obj = addEmptyEvent(obj,event_label,parent_index,sourceStruct,paramStruct)
           %adds an empty event - this method is a necessary addition to the class which became
           %clear when running the batch mode and finding cases where no
           %events/artifacts for a particular method were found and the
           %output in the periodogram file would not show the correct
           %number of character spots in relation to the number of
           %artifacts run
           obj.num_events = obj.num_events+1;
           obj.event_indices_to_plot(obj.num_events) = 0;

                
           num_events_in_channel = obj.getNumEventsInChannel(parent_index); %used for graphical offset from the parent channel being plotted
           
           if(parent_index>0)
               EDF_index = zeros(1,numel(parent_index));
               for k=1:numel(parent_index)
                   EDF_index(k) = obj.CHANNELS_CONTAINER.cell_of_channels{parent_index(k)}.EDF_index;
               end;
               
               parent_index = parent_index(1); %avoid problems wiht multiple parents, as the case with ocular movements.
               
               %associate this with the parent class
               parent_obj = obj.CHANNELS_CONTAINER.cell_of_channels{parent_index};
               parent_obj.add_event(obj.num_events);
               parent_EDF_label = parent_obj.EDF_label;
               parent_channel_samplerate = parent_obj.samplerate;
               parent_color = parent_obj.color;
           else
               parent_color = 'b';
               parent_EDF_label = obj.defaults.parent_channel_title;
               parent_channel_samplerate = obj.defaults.parent_channel_samplerate;
               EDF_index = 0;
           end;
           obj.channel_vector(obj.num_events) = parent_index;
           obj.cell_of_events{obj.num_events} = ...
               CLASS_events([],...
               event_label,...
               parent_EDF_label,...
               parent_channel_samplerate,...
               obj.num_events,...
               num_events_in_channel,...
               parent_color,...
               EDF_index,...
               parent_index,...
               sourceStruct,...
               paramStruct,...
               obj.parent_fig,...
               obj.parent_axes);           
        end
        
        % =================================================================
        %> @brief appends the event to the last event cell
        %> check that the event_data is not empty
        %> @param obj instance of CLASS_events_container class.
        %> @param parent_index is the index into the CHANNELS_CONTAINER
        %> that the event is associated with
        %> @param sourceStruct contains the fields
        %>  .indices = parent indices of the channels that the event was
        %>  derived from - as passed to the algorithm
        %>  .algorithm = algorithm name that the event was derived from
        %> @param paramStruct struct of parameters used in deriving the
        %> event (if any)
        %> @retval obj instance of CLASS_events_container
        % =================================================================
        function obj = addEvent(obj,event_data, event_label,parent_index,sourceStruct,paramStruct)
            
            if(~isempty(event_data) && all(event_data(:))) %not empty and non-zero indices
                try
                    obj.num_events = obj.num_events+1;
                    obj.cur_event_index = obj.num_events;
                    obj.summary_stats_axes_needs_update = true;
                    %use this method instead of numel of the
                    %CHANNELS_CONTAINER{parent_index} to account for
                    %external values (i.e. parent_index==0)
                    num_events_in_channel = obj.getNumEventsInChannel(parent_index); %used for graphical offset from the parent channel being plotted
                    
                    if(parent_index>0)
                        EDF_index = zeros(1,numel(parent_index));
                        for k=1:numel(parent_index)
                            EDF_index(k) = obj.CHANNELS_CONTAINER.cell_of_channels{parent_index(k)}.EDF_index(1);  %sometimes there are two EDF indices here when more than one channel is used in synthesizing the event - and will go back to the original one then.
                        end;
                        
                        parent_index = parent_index(1); %avoid problems wiht multiple parents, as the case with ocular movements.
                        
                        %associate this with the parent class
                        parent_obj = obj.CHANNELS_CONTAINER.getChannel(parent_index);
                        parent_obj.add_event(obj.num_events);
                        parent_EDF_label = parent_obj.EDF_label;
                        parent_channel_samplerate = parent_obj.samplerate;
                        parent_color = parent_obj.color;
                    else
                        parent_color = 'b';
                        parent_EDF_label = obj.defaults.parent_channel_title;
                        parent_channel_samplerate = obj.defaults.parent_channel_samplerate;
                        EDF_index = 0;
                    end;
                    class_channel_index = parent_index;
                    
                    obj.channel_vector(obj.num_events) = parent_index;
                    obj.cell_of_events{obj.num_events} = ...
                        CLASS_events(event_data,...
                        event_label,...
                        parent_EDF_label,...
                        parent_channel_samplerate,...
                        obj.num_events,...
                        num_events_in_channel,...
                        parent_color,...
                        EDF_index,...
                        class_channel_index,...
                        sourceStruct,...
                        paramStruct,...
                        obj.parent_fig,...
                        obj.parent_axes);
                    
                    obj.cur_event_index = obj.num_events;
                    obj.event_indices_to_plot(obj.cur_event_index) = 1;

                    %% add contextmenus to the events if there is an axes
                    %available
                    if(~isempty(obj.parent_fig) && ~isempty(obj.parent_axes))
                        obj.configureChildrenContextmenus(obj.cur_event_index);
                    end
                    
                catch ME
                    disp(ME.message);
                    disp(ME.stack(1))
                    obj.num_events = obj.num_events-1;
                end
            else
                disp 'empty event_data';
            end;
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function configureChildrenContextmenus(obj,event_index)
            
            childobj = obj.getEventObj(event_index);
            label_contextmenu_h = copyobj(obj.children_contextmenu_label_h,get(obj.children_contextmenu_label_h,'parent'));
            patch_contextmenu_h = copyobj(obj.children_contextmenu_patch_h,get(obj.children_contextmenu_patch_h,'parent'));
            
            childobj.setContextmenus(patch_contextmenu_h,label_contextmenu_h,@obj.updateEvent_callback);

        end
        
        % -------------------------------------------------------------------- 
        % Event Patches contextmenu callback section
        % -------------------------------------------------------------------- 
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function contextmenu_patch_callback(obj,hObject,eventdata)
            %parent context menu that pops up before any of the children contexts are
            %drawn...
            global MARKING;
            event_index = get(hObject,'userdata');
            MARKING.event_index = event_index;
            obj.cur_event_index = event_index; % MARKING.event_index;
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function contextmenu_changeColorcallback(obj,hObject,eventdata)
            global MARKING;
            obj.summary_stats_axes_needs_update = true;
            MARKING.setUtilityAxesType('EvtStats');
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function contextmenu_changeColor_callback(obj,hObject,eventdata)
            global MARKING;
            eventObj = obj.getCurrentChild();
            c = uisetcolor(eventObj.cur_color);
            if(numel(c)~=1)
                eventObj.updateColor(c);
            end;        
            MARKING.refreshAxes();
        end
        
        % =================================================================
        %> @brief Adjust the vertical display offset of the current event
        %> in relation to its parent channel.
        %> @param Instance of CLASS_events_container class.
        %> @param Graphic handle to the box of the selected patch.
        % =================================================================
        function contextmenu_patch_adjustOffset_callback(obj,hObject,~)
            eventObj = obj.getCurrentChild();
            vertical_offset_str = num2str(eventObj.vertical_offset_delta);
            
            vertical_offset_str = inputdlg(char({'Input desired display offset (in uV) for the event(s)','(0 turns off reference lines)'}),'Line Reference Input Dialog',1,{vertical_offset_str});
            if(~isempty(vertical_offset_str))
                vertical_offset = str2double(vertical_offset_str{1});

                if(~(isnan(reference_offset)))
                    % since we don't keep track of the parent channel's y
                    % offset, we need to determine where it from the change
                    % in the vertical offset and the evt_patch_y position.
                    parent_channel_y_offset = eventObj.evt_patch_y - eventObj.vertical_offset_delta;
                    event_obj.vertical_offset_delta = vertical_offset;
                    event_obj.setYoffset(parent_channel_y_offset);
                end
            end
            set(gco,'selected','off');
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function contextmenu_patch_removeInstance_callback(obj,hObject,eventdata)
            global MARKING;
            obj.remove_event_instance(obj.cur_event_index,MARKING.start_stop_matrix_index);
            MARKING.start_stop_matrix_index = 0;
            MARKING.refreshAxes();
        end
        
        % =================================================================
        %> @brief SEV helpfer function to draw events at index event_index
        %> @param obj instance of CLASS_events_container class.
        %> @param event_index index of the event to be drawn
        %> @retval object of CLASS_events_container
        % =================================================================
        function set_Channel_drawEvents(obj,event_index)
            %draw the events on the main psg axes            
            eventObj = obj.getEventObj(event_index);
            if(~isempty(eventObj))
                obj.CHANNELS_CONTAINER.setDrawEvents(obj.channel_vector(event_index));
                obj.event_indices_to_plot(event_index) = 1;
                obj.summary_stats_axes_needs_update = true;
                eventObj.draw();
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function obj = replaceEvent(obj,event_data, event_index,event_paramStruct,source_pStruct)
            %replaces the start_stop_matrix of the event at event_index
            %with event_data
            
            if(isempty(event_data) || any(event_data(:)==0)) %no new data, so remove it
                obj.removeEvent(event_index);
            else
                
                %get's the pointer to the event object
                event_obj = obj.getEventObj(event_index);
                event_obj.start_stop_matrix = event_data;
                event_obj.paramStruct = event_paramStruct;
                event_obj.summary_stats_needs_updating_Bool = true;
                event_obj.source.pStruct = source_pStruct; %update any changes to the detectors parameters;
            end;
            
            obj.set_Channel_drawEvents(event_index);
        end
        
        % =================================================================
        %> @brief Removes the individual event instance of one event object as
        %< specified by the input arguments
        %> @param obj instance of CLASS_events_container class.
        %> @param Index of the event object (CLASS_event) stored by the events contaier
        %> (CLASS_events_container).  
        %> #param Row index of the start/stop event to remove from the
        %> event object (CLASS_event)
        %> @note Method checks if event_index is within acceptable range of
        %> available events before trying to remove the event.
        % =================================================================
        function obj = remove_event_instance(obj,event_index,start_stop_matrix_index)
            
            if(event_index>0 && event_index <= obj.num_events)
                obj.set_Channel_drawEvents(event_index);
                obj.cell_of_events{event_index}.remove(start_stop_matrix_index);
                if(obj.cell_of_events{event_index}.isempty())
                    obj.removeEvent(event_index);
                else
                    obj.set_Channel_drawEvents(event_index);
                end
            end
        end
        
        % =================================================================
        %> @brief Removes the event class found at index event_index from
        %> obj.cell_of_events   
        %> @param obj instance of CLASS_events_container class.
        %> @param The index of the CLASS_event instance stored in
        %> cell_of_events to be removed.
        % =================================================================
        function obj = removeEvent(obj,event_index)
                                 
            parent_channel_index =obj.channel_vector(event_index);
            obj.CHANNELS_CONTAINER.remove_event(parent_channel_index, event_index);
            
            byebye_eventObj = obj.getEventObj(event_index);
            delete(byebye_eventObj);


            %reduce the event_index for any events that are in the class
            %which are above the index being removed
            for k = event_index+1:obj.num_events          
                cur_event_ind = obj.cell_of_events{k}.current_event_index; %should be the same as k, but do this just in case. ..
                obj.cell_of_events{k}.changeEventIndex(cur_event_ind-1);
            end
            
            obj.cell_of_events(event_index)=[];
            obj.channel_vector(event_index)=[];
            obj.event_indices_to_plot(event_index) = [];
            
            
            %and finally, reduce the num_events count by one and clean up remaining
            %reference problem possibilities            
            obj.num_events = obj.num_events-1;
            if(obj.cur_event_index == event_index)
                obj.cur_event_index = obj.num_events;
                obj.summary_stats_axes_needs_update = true;
            elseif(obj.cur_event_index>event_index)
                obj.cur_event_index = obj.cur_event_index-1;
                obj.summary_stats_axes_needs_update = true;
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function event_index = eventExists(obj, event_label,class_channel_index)
            %event_index is the index of the event whose label is event_label
            %otherwise 0/false is returned.
            event_index = 0;


            event_indices = find(obj.channel_vector==class_channel_index);
            if(~isempty(event_indices)&&obj.num_events~=0)
                for k=1:numel(event_indices)
                    
                    if(strcmp(obj.cell_of_events{event_indices(k)}.label,event_label))
                        event_index = event_indices(k);
                        break; %stop at the first match...
                    end
                end;
            end;
        end

        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function updateExistingEvent(obj,event_data,event_index,event_paramStruct, source_pStruct)
           %similar to updateEvent, but in this case we know the event already exists, and
           %its event_index is passed as the only parameter
           
           if(~isempty(event_index) && event_index > 0 && event_index<=obj.num_events)
               obj.replaceEvent(event_data, event_index,event_paramStruct,source_pStruct);
               
               if((~isempty(obj.roc_truth_ind)&&any(event_index == obj.roc_truth_ind)) ||...
                       (~isempty(obj.roc_estimate_ind)&&any(event_index == obj.roc_estimate_ind)) ||...
                       (~isempty(obj.roc_artifact_ind)&&any(event_index == obj.roc_artifact_ind)))
                   obj.roc_axes_needs_update = true;
               end
               obj.set_Channel_drawEvents(event_index);
           end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function sourceStruct = getSourceStruct(obj,event_index)
            %this method is not referenced and may be dropped in the future
            %determine if there is a gui to use for this method to
            %adjust the parameters/properties of the detection
            %algorithm
            global MARKING;
            childobj = obj.getEventObj(event_index);
            detection_struct = MARKING.getDetectionMethodsStruct();
            gui_ind = find(strcmp(childobj.label,detection_struct.evt_label));
            if(~isempty(gui_ind))
                sourceStruct.channel_indices = childobj.class_channel_index;
                sourceStruct.algorithm = [MARKING.SETTINGS.VIEW.detection_path(2:end),'.',detection_struct.param_gui{gui_ind}.mfile];
                sourceStruct.editor = detection_struct.param_gui{gui_ind};
            else
                sourceStruct = [];
            end
        end
            
        % =================================================================
        %> @brief updateEvent in SEV; adds or modifies existing event
        %> @param obj instance of CLASS_events_container class.
        %> @param event_data is a start_stop matrix of events
        %> @param event_label is the label associated with the events listed in
        %> event_data
        %> @param class_channel_index refers to the CHANNELS_CONTAINER index that
        %> is associated with this event event_index is the index at which
        %> the event was placed/added in the container's cell (i.e. this obj).  
        %> @param sourceStruct contains the fields
        %>  .indices = parent indices of the channels that the event was
        %>     derived from - as passed to the algorithm
        %>  .algorithm = algorithm name that the event was derived from
        %> @param paramstruct Struct containing any parameter settings
        %> associated with the event (i.e. if it was derived in SEV)
        %> @retval event_index The obj/container's index where the event is stored
        % =================================================================
        function event_index = updateEvent(obj,event_data,event_label,class_channel_index,sourceStruct,paramStruct)
            event_index = obj.eventExists(event_label,class_channel_index);
            if(event_index)
                obj.replaceEvent(event_data, event_index, paramStruct,sourceStruct);
            else
                if(nargin<5)
                    sourceStruct.algorithm = 'unknown';
                    sourceStruct.channel_indices = class_channel_index;
                    sourceStruct.editor = 'none';
                end
                    
                obj.addEvent(event_data, event_label,class_channel_index,sourceStruct, paramStruct);
                event_index = obj.num_events;
            end;
            
            if((~isempty(obj.roc_truth_ind)&&any(event_index == obj.roc_truth_ind)) ||...
                    (~isempty(obj.roc_estimate_ind)&&any(event_index == obj.roc_estimate_ind)) ||...
                    (~isempty(obj.roc_artifact_ind)&&any(event_index == obj.roc_artifact_ind)))
                obj.roc_axes_needs_update = true;
            end
            if(event_index>0)
                %  An equivalent call?
                %  obj.set_Channel_drawEvents(obj,event_index)
                obj.cur_event_index = event_index;
                obj.summary_stats_axes_needs_update = true;
                obj.event_indices_to_plot(event_index) = true;                
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        %varargin is an optional start stop range that can be used to put
        %bounds on the events under consideration
        function [score, event_space] = compareEvents(obj,event_indices,varargin)
           if(numel(varargin)>0)
               [score, event_space] = compareEvents(...
                   obj.cell_of_events{event_indices(1)}.start_stop_matrix,...
                   obj.cell_of_events{event_indices(2)}.start_stop_matrix,...
                   varargin{1});
           else
               [score,event_space] = compareEvents(...
                   obj.cell_of_events{event_indices(1)}.start_stop_matrix,...
                   obj.cell_of_events{event_indices(2)}.start_stop_matrix);
           end               
            
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function quadData = calculateQuadAnalysis(obj, indices)
            %quadData is a 2x2 matrix with the following values
            %A&B, !A&B
            %A&!B,!A&!B
            %-with A being representative of the events of indices(1) and B
            %being from indices(2)
            quadData = zeros(2);
            matA = obj.cell_of_events{indices(1)}.start_stop_matrix;
            matB = obj.cell_of_events{indices(2)}.start_stop_matrix;
            numA = sum(matA(:,2)-matA(:,1));
            numB = sum(matB(:,2)-matB(:,1));
            
            [score, event_space, numAandB, numAorB] = compareEvents(matA,matB);
            disp(score);
            quadData(1,1)=numAandB;
            quadData(1,2)=-numAandB+numA;  %and/or equivalently numAorB-numA
            quadData(2,1)=-numAandB+numB;
            quadData(2,2)=numAorB; %the sum of or'ing the results...
            
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function comparisonStruct = getComparisonStruct(obj, optional_truth_ind, optional_estimate_ind,optional_artifact_ind,optional_rangeIn)
            %indices must be a two element vector whose elements are within
            %the range of available events
                    
            if(nargin>1)
                obj.roc_truth_ind = optional_truth_ind;
            end
            if(nargin>2)
                obj.roc_estimate_ind = optional_estimate_ind;
            end
            if(nargin>3)
                obj.roc_artifact_ind = optional_artifact_ind;
            end
            if(nargin>4)
                obj.roc_comparison_range = optional_rangeIn;
            end
            truth = [];
            for k=1:numel(obj.roc_truth_ind)
                truth = [truth;obj.cell_of_events{obj.roc_truth_ind(k)}.start_stop_matrix];
            end
            
            estimate = [];
            for k=1:numel(obj.roc_estimate_ind)
                estimate = [estimate;obj.cell_of_events{obj.roc_estimate_ind(k)}.start_stop_matrix];
            end
            
            if(isempty(truth)||isempty(estimate))
                comparisonStruct = [];
            else
                if(~issorted(truth(:,1)))
                    [~,ind]=sort(truth(:,1));
                    truth = truth(ind,:);
                end
                if(~issorted(estimate(:,1)))
                    [~,ind]=sort(estimate(:,1));
                    estimate = estimate(ind,:);
                end
                
                if(~isempty(obj.roc_artifact_ind))
                    artifact = [];
                    for k=1:numel(obj.roc_artifact_ind)
                        artifact = [artifact;obj.cell_of_events{obj.roc_artifact_ind(k)}.start_stop_matrix];
                    end
                    if(~issorted(artifact(:,1)))
                        [~,ind]=sort(artifact(:,1));
                        artifact = artifact(ind,:);
                    end
                else
                    artifact = [];
                end
                comparisonStruct = compare_classifications(truth,estimate,artifact,obj.roc_comparison_range);

            end
                
            
        end
        
        % =================================================================
        %> @brief save2image - save pictures of the channel data at the
        %> specified event;s start and stop locations
        %> @param obj instance of CLASS_events_container class.
        %> @param event_index index of the event object to use
        %> @param full_filename_prefix - name of the file to save data to
        %> sans the extension (e.g. .png, .jpg).
        %> @retval obj object of CLASS_events_container 
        % =================================================================
        function save2images(obj,event_index,full_filename_prefix,settings)
           %this method saves the event data, located in event_object at
           %event_index to disk.
           %optional_cap_limit will put a cap on how many images can be
           %saved to disk per event
           
           if(nargin<=3)
               settings.format = 'PNG';
               settings.limit_count = 0;
               settings.buffer_sec = 0.5;
           end

           settings.standard_epoch_sec = obj.stageStruct.standard_epoch_sec;

           cur_EVENT = obj.getEventObj(event_index);
           channel_index = cur_EVENT.source.channel_indices(1);
           channel_data = obj.CHANNELS_CONTAINER.getData(channel_index);
           channel_name = obj.CHANNELS_CONTAINER.getChannelName(channel_index);
           full_filename_prefix = strcat(full_filename_prefix,'_',channel_name);
           cur_EVENT.save2images(full_filename_prefix,channel_data,settings);
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param % DBstruct contains the following fields for database interaction
        %> - .name
        %> - .user
        %> - .password
        %> - .table
        %> #param patstudy is the name of .edf file sans .edf extension
        %> @param localStageStruct (optional).  Include if you want to usea
        %> the otherwise default obj.stageStruct instance variable
        %> stage struct.        
        % =================================================================
        function save2DB(obj,DBstruct,patstudy,localStageStruct)
            
            if(nargin<4)
                localStageStruct = obj.stageStruct;
            end
            if(~isempty(DBstruct) && ~isempty(localStageStruct))
               
                [PatID, StudyNum] = obj.getDB_PatientIdentifiers(patstudy);
                mym('open','localhost',DBstruct.user,DBstruct.password);
                mym(['USE ',DBstruct.name]);
                
                q = mym(['SELECT PatStudyKey FROM studyinfo_T WHERE PatID=''',...
                    PatID,''' AND StudyNum=''',StudyNum,'''']);
                
                if(~isempty(q.PatStudyKey))
                    mym('SET autocommit=0');
                    
                    for event_index=1:obj.num_events
                        eventObj = obj.getEventObj(event_index);
                        if(isempty(eventObj.detectorID))
                            obj.setDetectorID(DBstruct,event_index);
                        end
                        eventObj.save2DB(DBstruct.table,q.PatStudyKey,localStageStruct);
                    end
                    
                    mym('COMMIT');
                    mym('SET autocommit=1');
                end
                mym('CLOSE');
            end
        end;
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function saveEventsContainerToFile(obj,filename,indices2save)
            %it is important to save the start and stop matrices of each
            %event, as well as its label name, sampling rate, and associated parent
            %channel
            save(filename,'obj','-mat');
            
        end;
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function obj = loadEventsContainerFromFile(obj,filename)            
            X = load(filename,'-mat');
            for k=1:numel(X.obj.cell_of_events)
                %check that class_channel_index exists, otherwise make it 0;
                cur_event = X.obj.cell_of_events{k};
                class_channel_index = 0;
                for c = 1:obj.CHANNELS_CONTAINER.num_channels
                   if(strcmp(obj.CHANNELS_CONTAINER.cell_of_channels{c}.EDF_label, cur_event.channel_name))
                       class_channel_index = c;
                       break;
                   end;
                end;
                
                if(isfield(cur_event,'paramStruct'))
                    paramStruct = cur_event.paramStruct;
                else
                    paramStruct = [];
                end;
                
                sourceStruct.algorithm = 'external file (.SCO)';
                sourceStruct.channel_indices = class_channel_index;
                sourceStruct.editor = 'none';
                
                obj.updateEvent(cur_event.start_stop_matrix, cur_event.label, class_channel_index,sourceStruct,paramStruct)
            end
        end
        
        
                    
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function obj = loadEventsFromDatabase(obj,databaseImportStruct)
            %databaseImportStruct has the following fields
            % detectorID - detectorID from detectorinfo_t database table
            % channel_index - index of the channel that events are assigned
            % DB.name - database that contains the event table
            % DB.user
            % DB.password
            % patstudy
            patstudy = databaseImportStruct.patstudy;
            [PatID,StudyNum] = obj.getDB_PatientIdentifiers(patstudy);
%             if(numel(patstudy)>=7)
%                 pat = '(\w{5})_(\d+)'; %WSC format
%             else
%                 pat = '([A-Z]+)(\d+)';  %PTSD format
%             end
%             x=regexp(patstudy,pat,'tokens');
%             x = x{1};
%             PatID = x{1};
%             StudyNum = x{2};
            
            
            DB = databaseImportStruct.DB;
            mym('open','localhost',DB.user,DB.password);
            mym(['USE ',DB.name]);
            
            q = mym(['SELECT patstudykey FROM studyinfo_T WHERE PatID=''',...
                PatID,''' AND StudyNum=''',StudyNum,'''']);
            patstudykey = q.patstudykey;
            if(~isempty(patstudykey))
                qDetect = mym('select * from detectorinfo_t where detectorid={Si}',databaseImportStruct.detectorID);
                qEvent = mym('select * from events_t where detectorid={Si} and patstudykey={Si}',databaseImportStruct.detectorID,patstudykey);
                if(~isempty(qEvent.PatStudyKey))
                    sourceStruct.algorithm = qDetect.DetectorFilename;
                    sourceStruct.channel_indices = [];%alternatively: can find matches for qDetect.ConfigChannelLabels{1}() or databaseImportStruct.channel_index;
                    sourceStruct.editor = 'none';                   
                    cur_evt.events = [qEvent.Start_sample,qEvent.Stop_sample];
                    cur_evt.label = ['Database:', qDetect.DetectorLabel{1}];
                    class_channel_index = databaseImportStruct.channel_index;
                    paramMat = cell2mat(qEvent.Params);
                    if(isstruct(paramMat))
                        fields = fieldnames(paramMat);
                        x = cell(numel(qEvent.Params),1);
                        
                        for f=1:numel(fields)
                            [x{:}] = paramMat.(fields{f});
                            paramStruct.(fields{f}) = cell2mat(x);
                            
                        end
                    else
                        paramStruct = [];
                    end
                    obj.updateEvent(cur_evt.events, cur_evt.label, class_channel_index,sourceStruct,paramStruct);
                end
            end
            
        end;

        % =================================================================
        %> @brief Loads Embla formatted event file (.evt or .nvt) into obj
        %> @param obj instance of CLASS_events_container class.
        %> @param evtFilename Pathname (string) containing the embla events
        %> to load.
        %> @param embla_samplerate Sampling rate used in the Embla files.
        %> @note The embla samplerate can often be determined from the
        %stage.evt file.
        %> @retval embla_evt_Struct Result of internal parseEmblaEvent call
        % =================================================================
        function embla_evt_Struct = loadEmblaEvent(obj,evtFilename,embla_samplerate)
            embla_evt_Struct = obj.parseEmblaEvent(evtFilename,embla_samplerate,obj.defaults.parent_channel_samplerate);
            if(~isempty(embla_evt_Struct) && embla_evt_Struct.HDR.num_records>0)
                paramStruct = [];
                class_channel_index = 0;
                
                sourceStruct.algorithm = 'external file (Embla .evt)';
                sourceStruct.channel_indices = 0;
                sourceStruct.editor = 'none';
                
                cur_evt_label = embla_evt_Struct.type;
                obj.updateEvent(embla_evt_Struct.start_stop_matrix, cur_evt_label, class_channel_index,sourceStruct,paramStruct);
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function loadGenericEvents(obj,start_stop_matrix,evt_label,source_label,paramStruct)
            %parse data from twin file
            if(~isempty(start_stop_matrix))
                class_channel_index = 0;
                sourceStruct.channel_indices = 0;
                sourceStruct.editor = 'none';
                if(nargin<5)
                    paramStruct = [];
                    if(nargin<4)
                        if(nargin<3)
                            evt_label = 'unknown';
                        end
                        sourceStruct.algorithm = 'external file';
                    else
                        sourceStruct.algorithm = source_label;
                    end                    
                end
                obj.updateEvent(start_stop_matrix, evt_label, class_channel_index,sourceStruct,paramStruct);
            end
        end
                
        % =================================================================
        %> @brief loadEventsFromSCOFile loads events contained in a WSC
        %> formatted .SCO file        
        %> @param obj instance of CLASS_events_container class.
        %> @param filename The name of the .SCO file
        %> @retval obj instance of CLASS_events_container class
        % =================================================================
        function obj = loadEventsFromSCOFile(obj,filename)
            
            %SCO is a struct with the fields
            % .epoch - the epoch that the scored event occured in
            % .start_stop_matrix - the sample point that the events begin and end on
            % .label - the string label used to describe the event
            SCO = loadSCOfile(filename);
            if(~isempty(SCO) && ~isempty(SCO.epoch))
                %indJ contains the indices corresponding to the unique
                %labels in event_labels (i.e. SCO.labels = event_labels(indJ) 
               [event_labels,indI,indJ] = unique(SCO.label);
               event_indices = listdlg('PromptString','Select Event(s) to Import',...
                   'ListString',event_labels,'name','Event Selector');
               channel_names = obj.CHANNELS_CONTAINER.get_labels();
               event_labels = event_labels(event_indices);
%                event_indices = find(event_indices);
               %go through each label and assign it to a channel
               for k = 1:numel(event_indices)
                   class_channel_index = listdlg('PromptString',[event_labels{k},' channel'],...
                       'ListString',channel_names,'name','Channel Selector',...
                       'SelectionMode','single');
                   if(~isempty(class_channel_index))                       
                       
                       paramStruct = [];
                       
                       sourceStruct.algorithm = 'external file (.SCO)';
                       sourceStruct.channel_indices = class_channel_index;
                       sourceStruct.editor = 'none';
                       
                       cur_event = SCO.start_stop_matrix(event_indices(k)==indJ,:);
                       cur_evt_label = event_labels{k};
                       obj.updateEvent(cur_event, cur_evt_label, class_channel_index,sourceStruct,paramStruct);  
%                        obj.set_Channel_drawEvents(obj.cur_event_index);
                   end
               end
            end           
        end
        
        
        % =================================================================
        %> @brief Load .evt stored events into SEV
        %> @param obj instance of CLASS_events_container class.
        %> @param filename name of the .evt file to load events from
        %> @param optional_batch_processing_flag (defaults to false)
        %> @retval cur_event a SEV event structure derived from data in the
        %> .evt file
        % =================================================================
        function cur_event = loadEvtFile(obj,filename,optional_batch_process_running)
            %see evtTxt2evtStruct(filename) for external file calling            
            if(nargin<3)
                optional_batch_process_running = false;
            end
            [~,~,ext] = fileparts(filename);
            if(strcmp(ext,'.txt'))
                %pulls data from the files header
                cur_event = obj.evtTxt2evtStruct(filename);
                cur_event.events = [cur_event.Start_sample, cur_event.Stop_sample]; %to make compatible with below...
                cur_event.label = cur_event.event_label;
            else
                cur_event = load(filename,'-mat');
                rp = '([^\.]+\.+)*';
                label = regexp(filename,rp,'split');
                cur_event.label = label{end};
                channel_label = [];
            end
            if(isfield(cur_event,'events'))
                class_channel_index = 0;
                if(isfield(cur_event,'channel_label'))
                    channel_label = cur_event.channel_label;
                else
                    expression = regexp(filename,'([^\.]+\.+)+(?<channel>[^\.]+)\.(?<event>[^\.]+)','names');
                    if(numel(expression)>0)
                        channel_label = expression.channel;
                    end;
                end
                if(~isempty(obj.CHANNELS_CONTAINER))
                    if(~isempty(channel_label))
                        for c = 1:obj.CHANNELS_CONTAINER.num_channels
                            if(strcmp(obj.CHANNELS_CONTAINER.cell_of_channels{c}.EDF_label, channel_label))
                                class_channel_index = c;
                                break;
                            end;
                        end;
                    end
                    if(class_channel_index == 0)
                        if(~optional_batch_process_running)
                            channel_names = obj.CHANNELS_CONTAINER.get_labels();
                            class_channel_index = listdlg('PromptString','Select Channel to Assign Events to',...
                                'ListString',channel_names,'name','Channel Selector',...
                                'SelectionMode','single');
                        end
                    end
                end
                if(~isempty(class_channel_index))
                    if(isfield(cur_event,'paramStruct'))
                        paramStruct = cur_event.paramStruct;
                    else
                        paramStruct = [];
                    end;
                    
                    sourceStruct.algorithm = 'external file';
                    sourceStruct.channel_indices = class_channel_index;
                    sourceStruct.editor = 'none';
                    
                    event_index = obj.updateEvent(cur_event.events, cur_event.label, class_channel_index,sourceStruct,paramStruct);
                    if(isfield(cur_event,'range'))
                        obj.cell_of_events{event_index}.roc_comparison_range = cur_event.range;
                    end
                    if(~optional_batch_process_running)
                        obj.set_Channel_drawEvents(event_index);
                    end
                else
                    fprintf(1,'unhandled file load in %s',mfilename('fullpath'));
                end
            end
        end
        

        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function save2roc_txt(obj,filename,est_event_indices,truth_event_suffix,study_name)
            %save2roc_txt(obj,filename,est_event_indices) saves the ROC data of the events as compared to
            %the current truth data.  The information is stored as text,
            %with each row corresponding to a comparison of the events
            %loaded.  Data is appended to filename if it already exists...
            
            source = obj.cell_of_events{est_event_indices(1)}.source;
            keys = cellstr(fieldnames(source.pStruct));
                
            if(~exist(filename,'file'))
                fid = fopen(filename,'w');
                if(nargin<4)
                    truth_event_suffix = 'unspecified';
                end
                fprintf(fid,'#True event suffix: %s\r',truth_event_suffix);
                %struct that contains the following fields
                %.algorithm :  .m file/function call associated with creating this event...
                %.channel_indices : the channels that were used in creating
                %   this event - as passed to the source.algorithm
                %.editor = 'none';
                %.sourceStruct.pStruct = pStruct;
                %   pStruct is a plist struct whose fields and associated
                %   values are specific to the parameters used in creating
                %   the event when there is a .plist associated with the
                %   event's creation detection algorithm.
                
                fprintf(fid,'#Detection Algorithm: %s\r',source.algorithm);
                fprintf(fid,'#Config\tStudy\tQ(TP)\tQ(FN)\tQ(FP)\tQ(TN)\tFPR\tTPR\tACC\tK_1_0\tK_0_0\tCohensKappa\tPPV\tNPV\tprecision\trecall');
                for k=1:numel(keys)
                    fprintf(fid,'\t%s',keys{k});
                end
                fclose(fid);
            end;

            fid = fopen(filename,'a');
            configID = 1;
            for est_ind = est_event_indices(1):est_event_indices(end)
                obj.roc_estimate_ind = est_ind;
                [TPR,FPR,K_1_0,K_0_0, CohensKappa,PPV,NPV, accuracy,precision,recall,f_measure,confusion_matrix_count] = obj.getConfusionMatrix();
                
%                 Q = zeros(1,4);
%                 Q(1,1) = TP;
%                 Q(1,2) = FP;
%                 Q(1,3) = FN;
%                 Q(1,4) = TN;
                Q = confusion_matrix_count;
                pStruct = obj.cell_of_events{est_ind}.source.pStruct;
                fprintf(fid,'\r%i\t%s\t%i\t%i\t%i\t%i\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d',configID,study_name,Q(1,1),Q(1,2),Q(1,3),Q(1,4),FPR,TPR,ACC,K_1_0, K_0_0, CohensKappa,PPV,NPV,precision, recall);
                for k = 1:numel(keys)
                    value = pStruct.(keys{k});
                    if(isnumeric(value))
                        fprintf(fid,'\t%d',value);
                    else
                        fprintf(fid,'\t%s',value);
                    end
                end
                configID = configID+1;
            end
            fclose(fid);
        end
                        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function save2mat(obj,filename)            
            global MARKING;
            
            %save2mat(filename) saves all events using the filename
            %given.  If filename is a cell, then it must be of the same
            %length as the number of events, and each cell element is used
            %as unique filename to save the corresponding events to.  The
            %events are stored in .mat format 
            if(nargin<2)
                suggested_filename = fullfile(MARKING.SETTINGS.VIEW.src_event_pathname,['evt.',MARKING.SETTINGS.VIEW.src_edf_filename(1:end-4)]);
                [event_filename, event_path] = uiputfile('*.*', 'Save Events to .mat format',suggested_filename);
                if isequal(event_filename,0) || isequal(event_path,0)
                    disp('User pressed cancel');
                    filename = [];
                else
                    filename = fullfile(event_path,event_filename);
                    MARKING.SETTINGS.VIEW.src_event_pathname = event_path;
                end            
            end
            
            if(~isempty(filename))
                for k =1:obj.num_events
                    obj.cell_of_events{k}.save2mat(filename,obj.stageStruct);
                end                
            end
        end
        
      
        % =================================================================
        %> @brief save2text() opens a dialog where the user can select which
        %> events they want to save and enter a filename to save the
        %> events to.  Can save as plain text or matlab format (.mat)
        %> save2text(filename) - saves all events using the filename
        %> given.  
        %> @param obj instance of CLASS_events_container class.
        %> @param filename (optional) file name to save events too.
        %> If filename is a cell, then it must be of the same
        %> length as the number of events, and each cell element is used
        %> as unique filename to save the corresponding events to. 
        %> @note See save2text and save2mat methods of the CLASS_events
        %> class for further information on the output file format.
        % =================================================================
        function save2txt(obj,optional_filename)
                       
            global MARKING;
            if(nargin>1 && ~isempty(optional_filename))
                filename = optional_filename;
                for k =1:obj.num_events                    
                    obj.cell_of_events{k}.save2text(filename,obj.stageStruct);
                end
            else
                if(obj.num_events<1)
                    warndlg('No events currently available');
                else
                    
                    units = 'points';
                    dlg = dialog('visible','off','units',units);
                    
                    pan_channels = uipanel('title','SEV Events','parent',dlg,'units',units);
                    
                    for k=1:obj.num_events;
                        eventLabel = [obj.getName(k)];
                        if(obj.channel_vector>0)
                            eventLabel = strcat(eventLabel,' (',obj.CHANNELS_CONTAINER.getChannelName(obj.channel_vector(k)),')');
                        end
                        uicontrol('style','checkbox','units',units,'string',eventLabel,'parent',pan_channels,'userdata',k,'value',1);
                    end;
                    
                    % left and bottom are the distance from the lower-left corner of the parent object to the lower-left corner of the uicontrol object. width and height are the dimensions of the uicontrol rectangle. All measurements are in units specified by the Units property.
                    
                    width = 25;
                    
                    delta = 5;
                    cur_pos = [delta, delta, 0 0];
                    
                    h = allchild(pan_channels);
                    h = h(1:end-1); %skip the initial channel, which is not there
                    h_channels = h;
                    for k=1:numel(h)
                        extent = get(h(k),'extent');
                        cur_pos(3:4) = max(cur_pos(3:4),extent(3:4)+20);
                        set(h(k),'position',cur_pos);
                        cur_pos(2) = cur_pos(2)+cur_pos(4);
                        
                    end
                    
                    bSAVE = uicontrol('parent',dlg,'style','pushbutton','string','SAVE','units',units,'position',[50,20,50,20]);
                    bCancel = uicontrol('parent',dlg,'style','pushbutton','string','Cancel','units',units,'position',[50+50+10,20,50,20],'callback','output = [],close(gcbf)');
                    bPos = get(bSAVE,'position');
                    
                    set(pan_channels,'units',units,'position',[width*1.5, 2*bPos(2)+bPos(4), cur_pos(3)+width*3,cur_pos(2)+delta*2]);
                    pan_channelsPos = get(pan_channels,'position');                    
                    
                    set(bSAVE,'callback','uiresume(gcbf)');
                    
                    set(pan_channels,'position',pan_channelsPos);
                    bPos(1) = width*1.5;
                    set(bSAVE,'position',bPos);
                    max_width = pan_channelsPos(3);
                    bPos(1) = max_width+width*1.5-bPos(3);
                    set(bCancel,'position',bPos);
                    figPosition = get(dlg,'position');
                    
                    set(0,'Units',units)
                    scnsize = get(0,'ScreenSize');
                    
                    figPosition(3:4) = [max_width+width*3,...
                        bPos(4)+pan_channelsPos(4)+pan_channelsPos(2)]; %[width, height]
                    
                    set(dlg,'position',[(scnsize(3:4)-figPosition(3:4))/2,figPosition(3:4)],'visible','on');
                    uiwait(dlg);
                    
                    %output will contain a boolean matrix containing the on/off selection
                    %values for each label that was created.  This is changed to just indices of the true values so
                    %they can be used to determine
                    %which values should be drawn along the entire night axes (axes2) in
                    %updateAxes2 function
                    if(ishghandle(dlg)) %if it is still a graphic, then...
                        
                        if(numel(h_channels)==1)
                            if(get(h_channels,'value'))
                                event2save = get(h_channels,'userdata');
                            else
                                event2save = [];
                            end
                        else
                            event2save = get(h_channels(cell2mat(get(h_channels,'value'))==1),'userdata');
                        end;
                        if(iscell(event2save))
                            event2save = cell2mat(event2save);
                        end
                        
                        if(any(event2save))
                            filterspec = {'*.txt','Text (*.txt)';'*.mat','MAT_files (*.mat)'};
                            [~,evt_filename,~] = fileparts(MARKING.SETTINGS.VIEW.src_edf_filename);
                            [evt_filename, evt_pathname, filterspec_index] = uiputfile(filterspec,'Screenshot name',fullfile(MARKING.SETTINGS.VIEW.src_event_pathname,evt_filename));
                            if(~isequal(evt_filename,0) && ~isequal(evt_pathname,0))
                                MARKING.SETTINGS.VIEW.src_event_pathname = evt_pathname;
                                
                                evt_filename = fullfile(evt_pathname,evt_filename(1:end-4));
                                
                                for k =1:numel(event2save)
                                    if(filterspec_index==1)
                                        obj.cell_of_events{event2save(k)}.save2text(evt_filename,obj.stageStruct);
                                    elseif(filterspec_index==2)
                                        obj.cell_of_events{event2save(k)}.save2mat(evt_filename,obj.stageStruct);
                                    end
                                end
                            end
                        end
                        delete(dlg);
                    end;
                end;
            end
        end 
       % =================================================================
        %> @brief Saves events to a .SCO format file.
        %> @param obj instance of CLASS_events_container class.
        %> @param filename (optional) file name to save events too.
        %> If filename is not empty, then all events in obj are saved to
        %> filename in .SCO format    
        %> @note .SCO file format contains the following column values for
        %> describing events on a per row basis:
        %> - Start epoch
        %> - Start sample point (based on 200 Hz sampling rate)
        %> - Duration of the event in seconds
        %> - numeric code representing the event (unused)
        %> - Name of the event as a string label
        %> - Start time of the event in hh:mm:ss.fff 24 hour format
        % =================================================================
        function save2sco(obj,optional_filename)

            %save2text(filename) - saves all events using the filename
            %given.  If filename is a cell, then it must be of the same
            %length as the number of events, and each cell element is used
            %as unique filename to save the corresponding events to. 
            if(nargin>1 && ~isempty(optional_filename))
                start_stop_matrix = [];
                evt_indices = [];
                evt_labels = cell(obj.num_events,1);
                for k =1:obj.num_events                    
                    cur_evt = obj.getEventObj(k);
                    evt_labels{k} = obj.getName(k);
                    evt_indices = [evt_indices(:);repmat(k,size(cur_evt.start_stop_matrix,1),1)]; 
                    start_stop_matrix = [start_stop_matrix;cur_evt.start_stop_matrix];
                end
                [~,i] = sort(start_stop_matrix(:,1));
                event_start_stop_matrix = start_stop_matrix(i,:);
                evt_indices = evt_indices(i);
                
                fid = fopen(optional_filename,'w');
                if(fid>1)
                    t0 = obj.stageStruct.startDateTime;
                    
                    starts = event_start_stop_matrix(:,1);
                    
                    %subtract 1 below, since the 1st sample technically starts at
                    %           %t0 and thus the first sample in matlab would otherwise be listed as 1/fs seconds after t0
                    start_offset_sec = (starts-1)/obj.defaults.parent_channel_samplerate; %add the seconds here
                    
                    start_times = datenum([zeros(numel(start_offset_sec),numel(t0)-1),start_offset_sec(:)])+datenum(t0);
                    start_times = datestr(start_times,'HH:MM:SS.FFF');
                    
                    %                 start_epochs = sample2epoch(starts,studyStruct.standard_epoch_sec,obj.samplerate);
                    
                    start_epochs = sample2epoch(starts,30,obj.defaults.parent_channel_samplerate);
                    
                    SCO_samplerate = 200;
                    conversion_factor = SCO_samplerate/obj.defaults.parent_channel_samplerate;                    
                    starts_sco_samples = starts*conversion_factor;
                    duration_sco_samples = (event_start_stop_matrix(:,2)-event_start_stop_matrix(:,1))*conversion_factor;
                    %                 fid = 1;
                    for r=1:numel(evt_indices);
                        e=evt_indices(r);
                        fprintf(fid,'%u\t%u\t%u\t%u\t%s\t%u\t%s\n',start_epochs(r),starts_sco_samples(r),duration_sco_samples(r),e,...
                            evt_labels{e},e,start_times(r,:));
                    end
                    
                    fclose(fid);
                else
                    fprintf('Could not open %s for writing.\n',optional_filename);
                end
                
                
            else
                if(obj.num_events<1)
                    warndlg('No events currently available');
                else
                    
                end;
            end
        end  %end save2txt(obj,varargin)
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        %% contextmenus which are attached to the children event labels that are on the
        % the left hand side of the sev axes
        function contextmenu_label_deleteEvent_callback(obj,hObject,~)
            %delete this event if it occurs...
            global MARKING;
            curEvent_index = obj.cur_event_index; %get(hObject,'userdata');
            obj.removeEvent(curEvent_index);
            MARKING.refreshAxes();
        end
        
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function contextmenu_label_callback(obj,hObject,eventdata)
            %added this to ensure the event's textbox is highlighted and the user does
            %not accidentally delete the wrong event by mistake
            %     global EVENT_CONTAINER;
            %     curEvent_index = get(hObject,'userdata');
            %     label_handle = EVENT_CONTAINER.cell_of_events{curEvent_index}.label_h;
            %     set(label_handle,'selected','on');
            %     set(allchild(hObject),'visible','on');
            %     set(hObject,'visible','on');
            %     drawnow();
            %     waitforbuttonpress();
            %     waitfor(allchild(hObject),'visible','off');
            %     set(allchild(hObject),'createfcn','disp(''hello'')');
            %     disp('done waiting');
            %     set(label_handle,'selected','off');
            obj.cur_event_index = get(hObject,'userdata');
        end

        
        % =================================================================
        %> @brief Event label callback to get to the previos epoch
        %> containing the current event type.
        %> @param obj instance of CLASS_events_container class.
        %> @param Graphic handle of the event label (left side of main
        %> axes). 
        % =================================================================
        function contextmenu_label_previousEvent_callback(obj,hObject,~)
            global MARKING;
            childobj = obj.getCurrentChild();
            cur_range = get(obj.parent_axes,'xlim');
            
            previousInd = find(childobj.start_stop_matrix(:,1)<cur_range(1),1,'last');
            
            previousEpoch = MARKING.getEpochAtSamplePt(childobj.start_stop_matrix(previousInd,1));
            
            if(~isempty(previousEpoch))
                MARKING.setEpoch(previousEpoch);
            end

        end
        
        
        % =================================================================
        %> @brief Event label callback to get to the next epoch
        %> containing the current event type.
        %> @param obj instance of CLASS_events_container class.
        %> @param Graphic handle of the event label (left side of main
        %> axes). 
        % =================================================================
         function contextmenu_label_nextEvent_callback(obj,hObject,~)
            global MARKING;
            childobj = obj.getCurrentChild();
            cur_range = get(obj.parent_axes,'xlim');
            nextInd = find(childobj.start_stop_matrix(:,1)>cur_range(end),1,'first');
            
            nextEpoch = MARKING.getEpochAtSamplePt(childobj.start_stop_matrix(nextInd,1));
            
            if(~isempty(nextEpoch))
                MARKING.setEpoch(nextEpoch);
            end
        end
        
        % =================================================================
        %> @brief refresh the event object at index event_index by rerunning
        %> the detection method, likely helpful when the channel changes due to filtering
        %> @param obj instance of CLASS_events_container class.
        %> @param event_index index into the container of the event to be
        %> visually refreshed in SEV
        % =================================================================
        function refresh(obj, event_index)
            childObj = obj.getEventObj(event_index);
            if(~isempty(childObj) && ~isempty(childObj.source.channel_indices)) %empty for external events that are loaded
                detectStruct = childObj.rerun(obj.detection_path);
                
                obj.summary_stats_axes_needs_update = true;
                obj.event_indices_to_plot(event_index) = true;
                obj.replaceEvent(detectStruct.new_events, event_index, detectStruct.paramStruct);
                
                if((~isempty(obj.roc_truth_ind)&&any(event_index == obj.roc_truth_ind)) ||...
                        (~isempty(obj.roc_estimate_ind)&&any(event_index == obj.roc_estimate_ind)) ||...
                        (~isempty(obj.roc_artifact_ind)&&any(event_index == obj.roc_artifact_ind)))
                    obj.roc_axes_needs_update = true;
                end
                if(event_index>0)
                    obj.cur_event_index = event_index;
                    obj.summary_stats_axes_needs_update = true;
                    obj.event_indices_to_plot(event_index) = true;
                end
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function childobj = getCurrentChild(obj)
            childobj = obj.getEventObj(obj.cur_event_index);
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function childobj = getEventObj(obj,event_index)
            if(event_index>0 && event_index<=obj.num_events)
                childobj = obj.cell_of_events{event_index};
            else
                childobj = [];
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function updateEvent_callback(obj,hObject,~)            
            %update the parameters of this event and such...
            global MARKING;
            childObj = obj.getCurrentChild();
            if(~isempty(childObj))
                source = childObj.source;
                
                
                %want to pass on the label that was selected directly to the editing
                %function
                if(strcmp(source.editor,'plist_editor_dlg'))
                    %                 event_label = EVENT_CONTAINER.cell_of_events{userdata.event_index}.label;
                    sev_detection_path = fullfile(MARKING.SETTINGS.rootpathname,MARKING.SETTINGS.VIEW.detection_path);
                    updated_params = feval(source.editor,source.algorithm,sev_detection_path,source.pStruct);
                else
                    if(~isempty(source.editor) && ~strcmpi(source.editor,'none'))
                        updated_params = feval(source.editor);
                    end
                end
                
                %the user did not close or cancel the editor
                if(~isempty(updated_params))
                    MARKING.showBusy();
                    [detectStruct, ~] = obj.evaluateDetectFcn(source.algorithm,source.channel_indices,updated_params);
%                     detectStruct = feval(source.algorithm,source.channel_indices);
                    
                    obj.updateExistingEvent(detectStruct.new_events,obj.cur_event_index,detectStruct.paramStruct,updated_params);
                    
                    MARKING.refreshAxes();
                    
                    if(ishandle(obj.summary_stats_uitable_h))
                        obj.contextmenu_label_summaryStats_callback([]);
                        %         contextmenu_label_summaryStats_callback(hObject);
                    end
                    
                    MARKING.showReady();
                end
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function contextmenu_label_export2workspace_callback(obj,hObject,~)
            eventObj = obj.getCurrentChild();
            tmpStruct.label = eventObj.label;
            tmpStruct.start_stop_matrix = eventObj.start_stop_matrix;
            tmpStruct.source = eventObj.source;
            tmpStruct.samplerate = eventObj.samplerate;
            tmpStruct.paramStruct = eventObj.paramStruct;
            varName = strcat('evt_',eventObj.label);
            try
                assignin('base',varName,tmpStruct);
            catch me
                varName = 'evtStruct';
                assignin('base',varName,tmpStruct);
                
            end
            uiwait(msgbox(sprintf('Event data assigned to workspace variable %s',varName)));
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function contextmenu_label_summaryStats_callback(obj,hObject,~)            
            %             curEvent_index = obj.index; %get(hObject,'userdata');
            obj.summary_stats = obj.getCurrentChild().get_summary_stats(obj.stageStruct);
            obj.summary_stats.description_str = ['Summary statistics for ',obj.getName(obj.cur_event_index)];
            if(isempty(obj.summary_stats_uitable_h)||~ishandle(obj.summary_stats_uitable_h))
                obj.summary_stats_figure_h = figure('menubar','none','visible','off','name',obj.summary_stats.description_str);
                obj.summary_stats_uitable_h = uitable('parent',obj.summary_stats_figure_h,'columnname',obj.summary_stats.table_column_names,'data',obj.summary_stats.table_data,'rowname',obj.summary_stats.table_row_names);
            else
                set(obj.summary_stats_uitable_h,'columnname',obj.summary_stats.table_column_names,'data',obj.summary_stats.table_data,'rowname',obj.summary_stats.table_row_names);
            end
            extent = get(obj.summary_stats_uitable_h,'extent');
            figure_pos = get(obj.summary_stats_figure_h,'position');
            set(obj.summary_stats_uitable_h,'position',[0 0 extent(3:4)]);
            set(obj.summary_stats_figure_h,'position',[figure_pos(1:2), extent(3:4)]);
            
            %b/c Matlab is sometimes difficult it is necessary to repeat this step
            %to obtained desired visual results this way
            extent = get(obj.summary_stats_uitable_h,'extent');
            figure_pos = get(obj.summary_stats_figure_h,'position');
            set(obj.summary_stats_uitable_h,'position',[0 0 extent(3:4)]);
            set(obj.summary_stats_figure_h,'position',[figure_pos(1:2), extent(3:4)],'visible','on');
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param
        %> @retval 
        % =================================================================
        function contextmenu_label_renameEvent_callback(obj,hObject,~)
            curEvent_index = obj.cur_event_index;
            
            %             curEvent_index = obj.container_index; %get(hObject,'userdata');
            new_label = char(inputdlg('Enter new event name','Rename Event',1,...
                {obj.getName(curEvent_index)}));
            if(new_label)
                obj.rename_event(curEvent_index,new_label);
            end
        end
        
    end
    
    methods(Static)
        
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
                [~,name,~] = fileparts(evtFilename);
                
                fid = fopen(evtFilename,'r');
                HDR = CLASS_events_container.parseEmblaHDR(fid);
                
                start_sec = [];
                stop_sec = [];
                dur_sec = [];
                epoch = [];
                stage = [];
                start_stop_matrix = [];
                
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
                        %         stage_mat = fread(fid,[12,HDR.num_records],'uint8');
                        %         x=reshape(stage_mat,12,[])';
                        %stage records are produced in 12 byte sections
                        %1:4 [uint32] - elapsed_seconds*2^8 (sample_rate)
                        %5:8 [uint32] - (stage*2^8)+1*2^0
                        %9:10 [uint16] = ['9','2']  %34...
                        %10:12 = ?
                        %should be 12 bytes per record
%                         1 = Wake
%                         2 = Stage 1
%                         3 = Stage 2
%                         4 = Stage 3
%                         5 = Stage 4
%                         7 = REM
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
                        
                        %                         stage_mat = fread(fid,[bytes_per_record/4,HDR.num_records],'uint32')';
                        %                         start_sample = stage_mat(:,1);
                        %                         stage = (stage_mat(:,2)-1)/256;  %bitshifting will also work readily;
                        
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
                        description = cell(HDR.num_records,1); %24 bytes
                        tag = zeros(1,6); %6 bytes
                        intro_size = 34;
                        remainder = zeros(HDR.num_records,bytes_per_record-intro_size,'uint8');
                        for r=1:HDR.num_records
                            start_sample(r) = fread(fid,1,'uint32');
                            tag = fread(fid,6,'uint8')'; %[13 1 0 0 0 0]
                            
                            description{r} = fread(fid,12,'uint16=>char')';  %need to read until I get to a 34 essentially%now at 64 or %32 bytes read
                            remainder(r,:) = fread(fid,bytes_per_record-intro_size,'uint8')';
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
                    
                    if(nargin>2 && desired_samplerate>0)
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
        
        function evtStruct = evtTxt2evtStruct(filenameIn)
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
        
        function roc_struct = loadROCdata(filename)
           %loads the roc data as generated by the batch job 
           %The ROC file follows the naming convention
           %roc_truthAlgorithm_VS_estimateAlgorithm.txt
%            roc_struct.config - unique id for each parameter combination
%            roc_struct.truth_algorithm = algorithm name for gold standard
%            roc_struct.estimate_algorithm = algorithm name for the estimate 
%            roc_struct.study - edf filename
%            roc_struct.Q    - confusion matrix (2x2)
%            roc_struct.FPR    - false positive rate (1-specificity)
%            roc_struct.TPR   - true positive rate (sensitivity)
%            roc_struct.ACC    - accuracy
%            roc_struct.values   - parameter values
%            roc_struct.key_names - key names for the associated values
%            roc_struct.study_names - unique study names for this container
%            roc_struct.K_0_0 - weighted Kappa value for QROC
%            roc_struct.K_1_0 - weighted Kappa value for QROC

           
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
        function roc_struct = loadROCdataOld(filename) %the method for older ROC data file format
           %loads the roc data as generated by the batch job 
           %The ROC file follows the naming convention
           %roc_truthAlgorithm_VS_estimateAlgorithm.txt
%            roc_struct.config - unique id for each parameter combination
%            roc_struct.truth_algorithm = algorithm name for gold standard
%            roc_struct.estimate_algorithm = algorithm name for the estimate 
%            roc_struct.study - edf filename
%            roc_struct.Q    - confusion matrix (2x2)
%            roc_struct.FPR    - false positive rate (1-specificity)
%            roc_struct.TPR   - true positive rate (sensitivity)
%            roc_struct.ACC    - accuracy
%            roc_struct.values   - parameter values
%            roc_struct.key_names - key names for the associated values
%            roc_struct.study_names - unique study names for this container
%            roc_struct.K_0_0 - weighted Kappa value for QROC
%            roc_struct.K_1_0 - weighted Kappa value for QROC
           
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
        
        
        function detection_struct = loadDetectionMethodsInf(detection_path,detection_inf_file)
            %loads a struct from the detection.inf file which contains the
            %various detection methods and parameters that the sev has
            %preloaded - or from filter.inf
            if(nargin<2)
                if(nargin<1)
                    detection_path = '+detection';
                end
                [~, name, ~] = fileparts(detection_path);
                name = strrep(name,'+','');
                detection_inf_file = strcat(name,'.inf');
            end
            
            detection_inf = fullfile(detection_path,detection_inf_file);
            
            if(exist(detection_inf,'file'))
                [mfile, evt_label, num_reqd_indices, param_gui, batch_mode_label] = textread(detection_inf,'%s%s%n%s%s','commentstyle','shell');
                params = cell(numel(mfile),1);
            else
                detection_files = dir(fullfile(detection_path,'detection_*.m'));
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
            
            detection_struct.mfile = mfile;
            detection_struct.evt_label = evt_label;
            detection_struct.num_reqd_indices = num_reqd_indices;
            detection_struct.param_gui = param_gui;
            detection_struct.batch_mode_label = batch_mode_label;
            detection_struct.params = params; %for storage of parameters as necessary
            
        end %end loadDetectionMethodsInf
        
        
        

        
        function obj = importEmblaEvtDir(embla_path,embla_samplerate,desired_samplerate)
            obj = CLASS_events_container();
            import_types = {'resp','desat','plm'}; 
            if(nargin<2 || isempty(embla_samplerate))
                stage_evt_file = fullfile(embla_path,'stage.evt');
                if(exist(stage_evt_file,'file'))
                    [eventStruct,base_samplerate] = CLASS_events_container.parseEmblaEvent(stage_evt_file,studyStruct.samplerate,studyStruct.samplerate);
                    embla_samplerate = base_samplerate;
                    if(num_epochs~=numel(eventStruct.epoch))
                        fprintf(1,'%s\texpected epochs: %u\tencountered epochs: %u to %u\n',srcFile,num_epochs,min(eventStruct.epoch),max(eventStruct.epoch));
                        
                        new_stage = repmat(7,num_epochs,1);
                        new_epoch = (1:num_epochs)';
                        new_stage(eventStruct.epoch)=eventStruct.stage;
                        eventStruct.epoch = new_epoch;
                        eventStruct.stage = new_stage;
                    end
                else
                    fprintf('Original embla samplerate used for storing events is unknown, so there is no point in continuing to load the file.');
                    embla_samplerate = [];
                end
            end
            if(~isempty(embla_samplerate))
                if(nargin<3)
                    desired_samplerate = 100;
                end
                obj.setDefaultSamplerate(desired_samplerate);
                
                %get the sample rate from the .EDF in there?
                for f=1:numel(import_types)
                    event_file = fullfile(embla_path,strcat(import_types{f},'.evt'));
                    if(~exist(event_file,'file'))
                        event_file = fullfile(embla_path,strcat(import_types{f},'.nvt'));                        
                    end
                    if(exist(event_file,'file'))
                        obj.loadEmblaEvent(event_file,embla_samplerate);
                    end
                end
            end
        end
            
 
    end
    
end