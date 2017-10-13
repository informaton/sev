%> @file CLASS_events_container.cpp
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
        %> @param parent_fig  handle to the SEV gui
        %> @param parent_axes handle to the parent axes to show events on (child of
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
        %> @retval paramStruct A structure containing the detectorFcn
        %> parameters as obtained from the .plist or .mat file.  
        % =================================================================        
        function paramStruct = loadDetectionParams(obj,detectorFcn, fevalReadyDetectorFcn)
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
            else
                try
                    paramStruct = feval(fevalReadyDetectorFcn);
                    fprintf(1,'Loading default parameters for %s\n',detectorFcn);
                catch me
                    fprintf(1,'Could not load default parameters for %s\n',detectorFcn);
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
        %> @param source_indices The source indices or source data (i.e. raw
        %> digital sample values) to evaluate for events by the detector.
        %> @param params A struct containing detector specific parameters
        %> which refine the detector's behavior.  These are specific to the
        %> detector and are optional.
        %> @param varargin Cell of additional arguments that is passed through to
        %> the detector function when not empty (i.e. when numel(varargin)>0)
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
        function [detectStruct, source_pStruct] = evaluateDetectFcn(obj,shortDetectorFcn,source_indices,params, varargin)
            localDetectorFcn = strcat(strrep(obj.detection_path,'+',''),'.',shortDetectorFcn);

            if(iscell(source_indices))
                source_indices = cell2mat(source_indices);
            end
            if(nargin<4 || isempty(params))
                localDetectorFcn = strcat(strrep(obj.detection_path,'+',''),'.',shortDetectorFcn);

                params = obj.loadDetectionParams(shortDetectorFcn, localDetectorFcn);
                
                %no parameters available?
                if(isempty(params))
                    disp('No parameters to load here - debug here and run detector with no arguments to generate params file');
                    
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
            
            if(numel(varargin)==0)
                detectStruct = feval(localDetectorFcn,data,params,obj.stageStruct);
            else
                detectStruct = feval(localDetectorFcn,data,params,obj.stageStruct, varargin);                
            end
        end
        
        % =================================================================
        %> @brief Sets the stageStruct property
        %> @param obj instance of CLASS_events_container class.
        %> @param stageStruct A stage structure.
        % =================================================================
        function setStageStruct(obj,stageStruct)
            obj.stageStruct = stageStruct;
        end
        
        % =================================================================
        %> @brief Sets SEV's default sample rate
        %> @param obj instance of CLASS_events_container class.
        %> @param sampleRate The sample rate to set.
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
                'callback',@obj.contextmenu_showHistogram_callback);
            
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
            uimenu(contextmenu_patch_h,'Label','Show Histogram','separator','off','callback',@obj.contextmenu_showHistogram_callback);
            uimenu(contextmenu_patch_h,'Label','Remove','separator','on','callback',@obj.contextmenu_patch_removeInstance_callback);
            obj.children_contextmenu_patch_h = contextmenu_patch_h;
            
        end
        
        % =================================================================
        %> @brief Returns the detector ID associated with the input
        %> arguments.
        %> @param obj instance of CLASS_events_container class.
        %> @param DBstruct The struct of database information associated
        %> with this event.
        %> @param event_indices
        %> @retval detectorID is a vector of size channel_indices which contains
        %> the detector ID key from detectorinfo_t table found in
        %> database with configuration stored in DBstruct for children
        %> event objects with indices found in event_indices
        % =================================================================
        function detectorID = getDetectorID(obj,DBstruct, event_indices)
            
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
        %> @brief Sets the detectorID for event children objects located at
        %> indices stored in event_indices.
        %> @param obj instance of CLASS_events_container class.
        %> @param DBstruct
        %> @param event_indices
        %> @param optional_DetectorID is a vector of size event_indices with
        %> corresponding detector ID values for the detector located in
        %> mysql table detectorInfo_T
        % =================================================================
        function setDetectorID(obj,DBstruct, event_indices,optional_DetectorID)
            
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
        %> @brief Removes database event records from a mysql database.  
        %> @note removes the database events when necessary.
        %> @param obj instance of CLASS_events_container class.
        %> @param DBstruct A struct with fields for interacting with a MySQL database.  Field names include:
        %> - @c name
        %> - @c user
        %> - @c password
        %> - @c table for interacting with a mysql database
        %> @param optional_patstudy
        % =================================================================
        function deleteDatabaseEventRecords(obj, DBstruct,optional_patstudy)
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
        %> @brief Change the color of an event series.
        %> @param obj Instance of CLASS_events_container.
        %> @param newColor
        %> @param eventIndex
        % =================================================================
        function updateColor(obj,newColor,eventIndex)
            %consider using obj.cur_event_index if only newColor is passed;
            obj.cell_of_events{eventIndex}.updateColor(newColor);
        end
        
        % =================================================================
        %> @brief Calculates and stores the summary stats for
        %> obj.cur_event_index.
        %> @param obj instance of CLASS_events_container class.
        % =================================================================
        function calculate_summary_stats(obj)
            if(obj.cur_event_index>0 && obj.cur_event_index<=obj.num_events)
                obj.summary_stats = obj.getCurrentChild.get_summary_stats(obj.stageStruct);
                obj.summary_stats_axes_needs_update = true;
            end
        end
        
        % =================================================================
        %> @brief Display summary statistics/histogram.
        %> @param obj instance of CLASS_events_container class.
        %> @param parent_axes
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
        %> @brief Hide a series of events.
        %> @param obj instance of CLASS_events_container class.
        %> @param events2hide
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
        %> @brief Show (unhide) a series of events
        %> @param obj instance of CLASS_events_container class.
        %> @param event_indices
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
        %> @brief Retrieve event names
        %> @param obj instance of CLASS_events_container class.
        %> @retval cell_of_names Nx1 cell of event labels.
        % =================================================================
        function cell_of_names = get_event_labels(obj)
            cell_of_names = cell(obj.num_events,1);
            for k = 1:obj.num_events
                cell_of_names{k} = obj.cell_of_events{k}.label;
            end
        end
        
        % =================================================================
        %> @brief Retrieve name of a specific event object/series
        %> @param obj instance of CLASS_events_container class.
        %> @param event_index Index of the event object to obtain the label
        %> of.
        %> @retval event_name String label of the event series requested,
        %> or empty if none were found.
        % =================================================================
        function event_name = getName(obj,event_index)
            if(event_index>0 && event_index<=obj.num_events)
                event_name = obj.cell_of_events{event_index}.label;
            else
                event_name = '';
            end
        end
        
        
        % =================================================================
        %> @brief Finds the number of events associated with the channel at
        %> the index given
        %> @param obj instance of CLASS_events_container class.
        %> @param class_channel_index The index of the channel as tracked
        %> by obj.
        %> @retval num_events_in_channel The number of different events
        %> associated with the indexed channel 
        % =================================================================
        function num_events_in_channel = getNumEventsInChannel(obj,class_channel_index)
            if(isempty(class_channel_index))
                num_events_in_channel = 0;
            elseif(obj.num_events>0)
                num_events_in_channel = sum(class_channel_index(1)==obj.channel_vector);
            else
                num_events_in_channel = 0;
            end;
        end
        
        
        % =================================================================
        %> @brief Returns the number of events and their total duration in seconds
        %> in the cell at event_index
        %> @param obj instance of CLASS_events_container class.
        %> @param event_index
        %> @retval count
        %> @retval time_in_sec
        % =================================================================
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
        %> @brief Renames an event.
        %> changes the label of the event specified by event_index to
        %> event_label if event_label is of type char. 
        %> @param obj instance of CLASS_events_container class.
        %> @param event_index Index of cell_of_events to rename.
        %> @param event_label New name/label.
        % =================================================================
        function rename_event(obj,event_index,event_label)
            obj.cell_of_events{event_index}.rename(event_label);
        end

        % =================================================================
        %> @brief Used primarily for interactive additions or edits of
        %> existing events by the user
        %> @param obj instance of CLASS_events_container class.
        %> @param single_event  = start_stop vector of the event
        %> @param class_channel_index index into the obj.CHANNELS_CONTAINER of the
        %> associated channel/signal
        %> @param event_label = string of the events name/label
        %> @param event_index = 0 if this is a new event, otherwise it is the index
        %> to be edited/updated
        %> @param start_stop_matrix_index to be updated in the
        %> start_stop_matrix for the given event object/series.
        %> @param sourceStruct
        %> @retval event_index
        %> @retval start_stop_matrix_index
        % =================================================================
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
        %> @brief Modify the y offset for a given event
        %> @param obj instance of CLASS_events_container class.
        %> @param event_indices
        %> @param y_offset
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
        %> @brief Updates the current epochs starting location on the
        %> x-axis.
        %> Of the parent (i.e. channel) has moved up/down, we want to
        %> make sure the attached events (event_indices) are adjusted accordingly
        %> @param obj instance of CLASS_events_container class.
        %> @param event_indices
        %> @param start_x
        % =================================================================
        function updateCurrentEpochStartX(obj,event_indices,start_x)            
            for k=1:numel(event_indices)
                index = event_indices(k);
                if(index>0  && index<=obj.num_events)
                    childobj = obj.cell_of_events{index};
                    childobj.setCurrentEpochStartX(start_x);                    
                end
                
            end
        end

        % =================================================================
        %> @brief Show labels.
        %> @param obj instance of CLASS_events_container class.
        %> @param event_indices
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
        %> @brief Returns the number of start/stop pairs in the event object
        % located at event_index.  
        %> @param obj instance of CLASS_events_container class.
        %> @param event_index
        %> @retval num_start_stops
        % =================================================================
        function num_start_stops = getEventCount(obj,event_index)
            if(event_index>0 && event_index<=obj.num_events)
                num_start_stops = size(obj.cell_of_events{event_index}.start_stop_matrix,1);
            else
                num_start_stops = 0;
            end
        end
        
        % =================================================================
        %> @brief Adds an empty event. 
        %> This method is a necessary addition to the class which became
        %> clear when running the batch mode and finding cases where no
        %> events/artifacts for a particular method were found and the
        %> output in the periodogram file would not show the correct
        %> number of character spots in relation to the number of
        %> artifacts run
        %> @param obj instance of CLASS_events_container class.
        %> @param event_label
        %> @param parent_index
        %> @param sourceStruct
        %> @param paramStruct
        % =================================================================
        function addEmptyEvent(obj,event_label,parent_index,sourceStruct,paramStruct)
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
        %> @param event_data
        %> @param event_label
        %> @param parent_index is the index into the CHANNELS_CONTAINER
        %> that the event is associated with
        %> @param sourceStruct contains the fields
        %>  .indices = parent indices of the channels that the event was
        %>  derived from - as passed to the algorithm
        %>  .algorithm = algorithm name that the event was derived from
        %> @param paramStruct struct of parameters used in deriving the
        %> event (if any)
        % =================================================================
        function addEvent(obj,event_data, event_label,parent_index,sourceStruct,paramStruct)
            
            if(~isempty(event_data) && all(event_data(:))) %not empty and non-zero indices
                try
                    obj.num_events = obj.num_events+1;
                    obj.cur_event_index = obj.num_events;
                    obj.summary_stats_axes_needs_update = true;
                    %use this method instead of numel of the
                    %CHANNELS_CONTAINER{parent_index} to account for
                    %external values (i.e. parent_index==0)
                    num_events_in_channel = obj.getNumEventsInChannel(parent_index); %used for graphical offset from the parent channel being plotted
                    
                    if(isempty(parent_index))
                        parent_index = 0;
                    end
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
                    showME(ME);
                    obj.num_events = obj.num_events-1;
                end
            else
                disp 'empty event_data';
            end;
        end
        
        % =================================================================
        %> @brief Configure's children context menus for events in SEV gui.
        %> @param obj instance of CLASS_events_container class.
        %> @param event_index
        % =================================================================
        function configureChildrenContextmenus(obj,event_index)
            
            childobj = obj.getEventObj(event_index);
            label_contextmenu_h = copyobj(obj.children_contextmenu_label_h,get(obj.children_contextmenu_label_h,'parent'));
            patch_contextmenu_h = copyobj(obj.children_contextmenu_patch_h,get(obj.children_contextmenu_patch_h,'parent'));
            
            % A change was made to this code, somewhere along the way.
            if(~verLessThan('matlab','7.14'))
                label_contextmenu_h.Callback = obj.children_contextmenu_label_h.Callback;
                for l=1:numel(label_contextmenu_h.Children)
                    label_contextmenu_h.Children(l).Callback = obj.children_contextmenu_label_h.Children(l).Callback;
                end
                patch_contextmenu_h.Callback = obj.children_contextmenu_patch_h.Callback;

                for p=1:numel(patch_contextmenu_h.Children)
                    patch_contextmenu_h.Children(p).Callback = obj.children_contextmenu_patch_h.Children(p).Callback;
                end
            end
            
            
            childobj.setContextmenus(patch_contextmenu_h,label_contextmenu_h,@obj.updateEvent_callback);

        end
        
        % -------------------------------------------------------------------- 
        % Event Patches contextmenu callback section
        % -------------------------------------------------------------------- 
        % =================================================================
        %> @brief Contextmenu callback for event 'patches' drawn to SEV.
        %> @param obj instance of CLASS_events_container class.
        %> @param hObject
        %> @param eventData
        % =================================================================
        function contextmenu_patch_callback(obj,hObject,eventData)
            %parent context menu that pops up before any of the children contexts are
            %drawn...
            global MARKING;
            event_index = get(hObject,'userdata');
            MARKING.event_index = event_index;
            obj.cur_event_index = event_index; % MARKING.event_index;
        end
        
        % =================================================================
        %> @brief Contextmenu callback to show histogram of an event.
        %> @param obj instance of CLASS_events_container class.
        %> @param hObject Unused
        %> @param eventData Unused
        % =================================================================
        function contextmenu_showHistogram_callback(obj,hObject,eventData)
            global MARKING;
            obj.summary_stats_axes_needs_update = true;
            MARKING.setUtilityAxesType('EvtStats');
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events_container class.
        %> @param hObject Unused
        %> @param eventData Unused
        % =================================================================
        function contextmenu_changeColor_callback(obj,hObject,eventData)
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
        %> @param obj Instance of CLASS_events_container class.
        %> @param hObject Unused graphic handle to the box of the selected patch.
        %> @param eventData Unused        
        % =================================================================
        function contextmenu_patch_adjustOffset_callback(obj,hObject,eventData)
            eventObj = obj.getCurrentChild();
            vertical_offset_str = num2str(eventObj.vertical_offset_delta);
            
            vertical_offset_str = inputdlg(char({'Input desired display offset (in uV) for the event(s)','(0 turns off reference lines)'}),'Line Reference Input Dialog',1,{vertical_offset_str});
            if(~isempty(vertical_offset_str))
                vertical_offset = str2double(vertical_offset_str{1});

                if(~(isnan(vertical_offset)))
                    % since we don't keep track of the parent channel's y
                    % offset, we need to determine where it from the change
                    % in the vertical offset and the evt_patch_y position.
                    parent_channel_y_offset = eventObj.evt_patch_y - eventObj.vertical_offset_delta;
                    eventObj.vertical_offset_delta = vertical_offset;
                    eventObj.setYOffset(parent_channel_y_offset);
                end
            end
            set(gco,'selected','off');
        end
        
        % =================================================================
        %> @brief Contextmenu callback to remove an event.
        %> @param obj instance of CLASS_events_container class.
        %> @param hObject Unused
        %> @param eventData Unused
        % =================================================================
        function contextmenu_patch_removeInstance_callback(obj,hObject,eventData)
            global MARKING;
            obj.remove_event_instance(obj.cur_event_index,MARKING.start_stop_matrix_index);
            MARKING.start_stop_matrix_index = 0;
            MARKING.refreshAxes();
        end
        
        % =================================================================
        %> @brief SEV helpfer function to draw events at index event_index
        %> @param obj instance of CLASS_events_container class.
        %> @param event_index index of the event to be drawn
        % =================================================================
        function set_Channel_drawEvents(obj,event_index)
            %draw the events on the main psg axes            
            eventObj = obj.getEventObj(event_index);
            if(~isempty(eventObj) && ~isempty(obj.CHANNELS_CONTAINER))
                obj.CHANNELS_CONTAINER.setDrawEvents(obj.channel_vector(event_index));
                obj.event_indices_to_plot(event_index) = 1;
                obj.summary_stats_axes_needs_update = true;
                eventObj.draw();
            end
        end
        
        % =================================================================
        %> @brief Replace an existing event with input data.
        %> @param obj instance of CLASS_events_container class.
        %> @param event_data
        %> @param event_index
        %> @param event_paramStruct
        %> @param source_pStruct
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
        %> @param event_index Index of the event object (CLASS_event) stored by the events contaier
        %> (CLASS_events_container).  
        %> @param start_stop_matrix_index Row index of the start/stop event to remove from the
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
        %> @param event_index The index of the CLASS_event instance stored in
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
        %> @brief Checks if an event exists, and returns its index if it
        %> does.  Returns 0 otherwise.
        %> @param obj instance of CLASS_events_container class.
        %> @param event_label
        %> @param class_channel_index
        %> @retval event_index is the index of the event whose label is event_label
        %> otherwise 0/false is returned.
        % =================================================================
        function event_index = eventExists(obj, event_label,class_channel_index)
            event_index = 0;


            event_indices = find(obj.channel_vector==class_channel_index);
            if(~isempty(event_indices)&&obj.num_events~=0)
                for k=1:numel(event_indices)
                    
                    if(strcmpi(obj.cell_of_events{event_indices(k)}.label,event_label))
                        event_index = event_indices(k);
                        break; %stop at the first match...
                    end
                end;
            end;
        end

        % =================================================================
        %> @brief Update existing events with new data.
        %> @param obj instance of CLASS_events_container class.
        %> @param event_data
        %> @param event_index
        %> @param event_paramStruct
        %> @param source_pStruct
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
        %> @brief updateEvent in SEV; adds or modifies existing event
        %> @param obj instance of CLASS_events_container class.
        %> @param event_data is a start_stop matrix of events
        %> @param event_label is the label associated with the events listed in
        %> event_data
        %> @param class_channel_index refers to the CHANNELS_CONTAINER index that
        %> is associated with this event event_index is the index at which
        %> the event was placed/added in the container's cell (i.e. this obj).  
        %> Can be 0 or empty ([]) for external events that are being
        %> imported.
        %> @param sourceStruct contains the fields
        %>  .indices = parent indices of the channels that the event was
        %>     derived from - as passed to the algorithm
        %>  .algorithm = algorithm name that the event was derived from
        %> @param paramStruct Struct containing any parameter settings
        %> associated with the event (i.e. if it was derived in SEV)
        %> @note This may have changed and perhaps be the parameters
        %> associated with individual events.  
        %> @retval event_index The obj/container's index where the event is stored
        % =================================================================
        function event_index = updateEvent(obj,event_data,event_label,class_channel_index,sourceStruct,paramStruct)
            if(isempty(class_channel_index))
                class_channel_index = 0;
            end
            
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
        %> @brief Compare two events.
        %> @param obj instance of CLASS_events_container class.
        %> @param event_indices
        %> @param varargin
        %> @retval score
        %> @retval event_space
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
        %> @brief Calculate 2x2 confusion matrix analysis.
        %> @param obj instance of CLASS_events_container class.
        %> @param indices
        %> @retval quadData
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
        %> @brief Retrieve comparison struct for input arguments
        %> @param obj instance of CLASS_events_container class.
        %> @param optional_truth_ind
        %> @param optional_estimate_ind
        %> @param optional_artifact_ind
        %> @param optional_rangeIn
        %> @retval Struct of comparison results.  Fields are those returned
        %> by compare_classifications
        %> @note Indices must be a two element vector whose elements are within
        %> the range of available events
        % =================================================================
        function comparisonStruct = getComparisonStruct(obj, optional_truth_ind, optional_estimate_ind,optional_artifact_ind,optional_rangeIn)
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
        %> @param settings
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
        %> @brief Save events to MySQL datab database
        %> @param obj instance of CLASS_events_container class.
        %> @param DBstruct contains the following fields for database interaction
        %> - .name
        %> - .user
        %> - .password
        %> - .table
        %> @param patstudy is the name of .edf file sans .edf extension
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
        %> @brief Save events container to a .mat file.
        %> @note Duplicate of save2mat
        %> @param obj instance of CLASS_events_container class.
        %> @param filename
        %> @param indices2save
        % =================================================================
        function saveEventsContainerToFile(obj,filename,indices2save)
            %it is important to save the start and stop matrices of each
            %event, as well as its label name, sampling rate, and associated parent
            %channel
            save(filename,'obj','-mat');
            
        end;
        
        % =================================================================
        %> @brief Load events container from a .mat file.
        %> @param obj instance of CLASS_events_container class.
        %> @param filename Name of file to load events from.
        % =================================================================
        function loadEventsContainerFromFile(obj,filename)            
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
        %> @brief Load events from a MySQL database.
        %> @param obj instance of CLASS_events_container class.
        %> @param databaseImportStruct Contains information relevant to the
        %> import.  databaseImportStruct has the following fields
        %> - @c detectorID - detectorID from detectorinfo_t database table
        %> - @c channel_index - index of the channel that events are assigned
        %> - @c DB.name - database that contains the event table
        %> - @c DB.user
        %> - @c DB.password
        %> - @c patstudy
        % =================================================================
        function loadEventsFromDatabase(obj,databaseImportStruct)

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
        %> stage.evt file.
        %> @retval embla_evt_Struct Result of internal CLASS_codec.parseEmblaEvent call
        % =================================================================
        function embla_evt_Struct = loadEmblaEvent(obj,evtFilename,embla_samplerate)
            embla_evt_Struct = CLASS_codec.parseEmblaEvent(evtFilename,embla_samplerate,obj.defaults.parent_channel_samplerate);
            if(~isempty(embla_evt_Struct) && embla_evt_Struct.HDR.num_records>0)
                if(isfield(embla_evt_Struct,'description'))
                    paramStruct.description = embla_evt_Struct.description;
                else
                    paramStruct = [];
                end
                
                class_channel_index = 0;
                
                [~,pth,ext] = fileparts(evtFilename);
                
               
                sourceStruct.algorithm = strcat(pth,ext);
                sourceStruct.channel_indices = 0;
                sourceStruct.editor = 'none';
                
                cur_evt_label = embla_evt_Struct.type;
                obj.updateEvent(embla_evt_Struct.start_stop_matrix, cur_evt_label, class_channel_index,sourceStruct,paramStruct);
            end
        end
        
        % =================================================================
        %> @brief Loads events from input arguments
        %> @param obj instance of CLASS_events_container class.
        %> @param start_stop_matrix Nx2 matrix of N events start-stop
        %> sample pairings.
        %> @param evt_label String label for the events
        %> @param source_label Label of the signal channel to assign the
        %> events to in SEV.
        %> @param paramStruct Parameter struct associated with the events.
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
        %> @brief loadEventsFromSSCevtsFile loads events contained in an SSC
        %> formatted .evts ascii file        
        %> @param obj instance of CLASS_events_container class.
        %> @param filename The name of the .evts file
        %> @retval obj instance of CLASS_events_container class
        % =================================================================
        function loadEventsFromSSCevtsFile(obj,filename)
            % SCO is struct containing the following fields
            % as parsed from filenameIn.
            % - @c startStopSamples
            % - @c durationSeconds Duration of the event in seconds
            % - @c startStopTimeStr Start time of the event as a string with
            % format HH:MM:SS.FFF
            % - @c category The category of the event (e.g. 'resp')
            % - @c description A description giving further information
            %n the event (e.g. Obs Hypopnea)
            % - @c samplerate The sampling rate used in the evts file (e.g.
            % 512)
            SSC_evts = CLASS_codec.parseSSCevtsFile(filename);
            if(~isempty(SSC_evts) && ~isempty(SSC_evts.category))
                %indJ contains the indices corresponding to the unique
                %labels in event_labels (i.e. SCO.labels = event_labels(indJ)
                [event_labels,indI,indJ] = unique(SSC_evts.category);
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
                        paramStruct.description = SSC_evts.description(event_indices(k)==indJ);
                        
                        sourceStruct.algorithm = 'external file (.EVTS)';
                        sourceStruct.channel_indices = class_channel_index;
                        sourceStruct.editor = 'none';
                        
                        channel_samplerate = obj.CHANNELS_CONTAINER.cell_of_channels{class_channel_index}.samplerate;
                        conversion_factor = channel_samplerate/SSC_evts.samplerate;

                        

                        cur_event = ceil(SSC_evts.startStopSamples(event_indices(k)==indJ,:)*conversion_factor);
                        
                        
                        cur_evt_label = event_labels{k};
                        obj.updateEvent(cur_event, cur_evt_label, class_channel_index,sourceStruct,paramStruct);
                        %                        obj.set_Channel_drawEvents(obj.cur_event_index);
                    end
                end
            end
            
        
        end
        
        
        % =================================================================
        %> @brief loadEventsFromWSCscoFile loads events contained in a WSC
        %> formatted .SCO file        
        %> @param obj instance of CLASS_events_container class.
        %> @param filename The name of the .SCO file
        %> @retval obj instance of CLASS_events_container class
        % =================================================================
        function obj = loadEventsFromWSCscoFile(obj,filename)
            
            %SCO is a struct with the fields
            % .epoch - the epoch that the scored event occured in
            % .start_stop_matrix - the sample point that the events begin and end on
            % .label - the string label used to describe the event
            SCO = CLASS_codec.parseSCOfile(filename);
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
        %> @param optional_batch_process_running_flag (defaults to false)
        %> @retval cur_event a SEV event structure derived from data in the
        %> .evt file
        % =================================================================
        function cur_event = loadEvtFile(obj,filename,optional_batch_process_running_flag)
            %see evtTxt2evtStruct(filename) for external file calling            
            if(nargin<3)
                optional_batch_process_running_flag = false;
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
                        if(~optional_batch_process_running_flag)
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
                    if(~optional_batch_process_running_flag)
                        obj.set_Channel_drawEvents(event_index);
                    end
                else
                    fprintf(1,'unhandled file load in %s',mfilename('fullpath'));
                end
            end
        end
        

        % =================================================================
        %> @brief Save ROC results to text file.
        %
        %>  saves the ROC data of the events as compared to
        %> the current truth data.  The information is stored as text,
        %> with each row corresponding to a comparison of the events
        %> loaded.  Data is appended to filename if it already exists...
        %> @param obj instance of CLASS_events_container class.
        %> @param filename Filename to save to.
        %> @param est_event_indices
        %> @param truth_event_suffix
        %> @param study_name
        %> @note 
        % =================================================================
        function save2roc_txt(obj,filename,est_event_indices,truth_event_suffix,study_name)
            %save2roc_txt(obj,filename,est_event_indices)
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
            source = obj.cell_of_events{est_event_indices(1)}.source;
            keys = cellstr(fieldnames(source.pStruct));
                
            if(~exist(filename,'file'))
                fid = fopen(filename,'w');
                if(nargin<4)
                    truth_event_suffix = 'unspecified';
                end
                fprintf(fid,'#True event suffix: %s\r',truth_event_suffix);
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
        %> @brief Save all events to a .mat file.
        % ==========
        %> save2mat(filename) saves all events using the filename
        %> given.  If filename is a cell, then it must be of the same
        %> length as the number of events, and each cell element is used
        %> as unique filename to save the corresponding events to.  The
        %> events are stored in .mat format
        %> @note Possible duplicate with save to file container method.
        %> @param obj instance of CLASS_events_container class.
        %> @param filename (optional) Full name of full to save data to.  
        %> @note A popup window is displayed allowing the user to select a
        %> save filename in the event that the filename argument is not
        %> provided.
        % =================================================================
        function save2mat(obj,filename)            
            global MARKING;            
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
        %> @brief Saves events to .EVTS format; a multiplexed, comma separated 
        %> file, with each row containing a unique events.        
        %> @param obj instance of CLASS_events_container class.
        %> @param optional_filename Filename (string) Name of file to save events to.           
        %> @note .EVTS file format contains the following columns/fields for
        %> describing events on a per row basis:
        %> - Start sample point (based on ? Hz sampling rate)
        %> - End Sample
        %> - Start time of the event in hh:mm:ss.fff 24 hour format
        %> - End time of the event in hh:mm:ss.fff 24 hour format
        %> - Event Name of the event, or description where available.  
        %> - File Name - Name of file that the event was obtained from
        %> @note Example output from an .EVTS formatted file
        %> - \#scoreDir=scoredJA
        %> - Start Sample,End Sample,Start Time,End Time,Event,File Name
        %> - 32799,32799,00:01:04.060,00:01:04.060,"CPAP TRIAL STARTED WITH PATIENT'S OWN MASK;  RESMED MIRAGE QUATTRO MEDIUM FULL FACE @ 9 CM; LK @ 32",user.evt
        %> - 572001,572001,00:18:37.189,00:18:37.189,"Video Recording Started",biocals.evt
        %> - 572257,572257,00:18:37.689,00:18:37.689,"Impedence Check Passed",biocals.evt        
        % =================================================================
        function save2evts(obj,optional_filename)
            if(nargin>1 && ~isempty(optional_filename))
                start_stop_matrix = [];
                evt_labels = {};
                evt_filenames = {};
                for k =1:obj.num_events                    
                    evtObj = obj.getEventObj(k);
                    numRows = size(evtObj.start_stop_matrix,1);
                    evtFilename = cellstr(repmat(evtObj.source.algorithm,numRows,1));
                    if(any(strcmpi('description',evtObj.paramFieldNames))&&~isempty(evtObj.paramStruct.description))
                        labels = evtObj.paramStruct.description;
                    else
                        labels = cellstr(repmat(evtObj.label,numRows,1));                        
                    end
                    start_stop_matrix = [start_stop_matrix; evtObj.start_stop_matrix];                    
                    evt_filenames = [evt_filenames; evtFilename];
                    evt_labels = [evt_labels; labels];
                end
                
                [~,i] = sort(start_stop_matrix(:,1));
                event_start_stop_matrix = start_stop_matrix(i,:);
                evt_filenames = evt_filenames(i);
                evt_labels = evt_labels(i);
                
                fid = fopen(optional_filename,'w');
                if(fid>1)
                    
                    % print the header
                    fprintf(fid,'# Samplerate=%d\n',obj.defaults.parent_channel_samplerate);
                    fprintf(fid,'Start Sample,End Sample,Start Time,End Time,Event,File Name\n');
                    
                    
                    t0 = obj.stageStruct.startDateTime;

                    %Subtract 1 here to conform to conform with Somnologic/Embla's 0-based format
                    starts = event_start_stop_matrix(:,1)-1;
                    stops = event_start_stop_matrix(:,2)-1;
                    
                    
                    start_offset_sec = starts/obj.defaults.parent_channel_samplerate; %add the seconds here
                    start_times = datenum([zeros(numel(start_offset_sec),numel(t0)-1),start_offset_sec(:)])+datenum(t0);
                    start_times = datestr(start_times,'HH:MM:SS.FFF');
                    
                    stop_offset_sec =  (stops)/obj.defaults.parent_channel_samplerate; %add the seconds here
                    stop_times = datestr(datenum([zeros(numel(stop_offset_sec),numel(t0)-1),stop_offset_sec(:)])+datenum(t0),'HH:MM:SS.FFF');
                    
                    
                    for e=1:numel(starts);
                        fprintf(fid,'%u,%u,%s,%s,"%s",%s\n',starts(e),stops(e),start_times(e,:),stop_times(e,:),evt_labels{e},evt_filenames{e});
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
        end  %end save2evts(obj,varargin) 
        
      
        % =================================================================
        %> @brief save2text() opens a dialog where the user can select which
        %> events they want to save and enter a filename to save the
        %> events to.  Can save as plain text or matlab format (.mat)
        %> save2text(filename) - saves all events using the filename
        %> given.  
        %> @param obj instance of CLASS_events_container class.
        %> @param optional_filename Filename (optional) to save events too.
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
        %> @param optional_filename filename (optional) file name to save events too.
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
                    
                    %                     SCO_samplerate = 200;
                    
                    %                     conversion_factor = SCO_samplerate/obj.defaults.parent_channel_samplerate;
                    conversion_factor = 1;
                    starts_sco_samples = starts*conversion_factor;
                    duration_sco_samples = (event_start_stop_matrix(:,2)-event_start_stop_matrix(:,1))*conversion_factor;
                    duration_seconds = duration_sco_samples/obj.defaults.parent_channel_samplerate;
                    %                 fid = 1;
                    for r=1:numel(evt_indices);
                        e=evt_indices(r);
                        fprintf(fid,'%u\t%u\t%u\t%f\t%s\t%u\t%s\n',start_epochs(r),starts_sco_samples(r),duration_sco_samples(r),...
                            duration_seconds(r),evt_labels{e},e,start_times(r,:));
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
        end  %end save2sco(obj,varargin)
        
        % =================================================================
        %> @brief Contextmenu callback for deleting an event in the sev
        %> gui.
        %> @param obj instance of CLASS_events_container class.
        %> @param hObject
        %> @param eventData
        % =================================================================
        %% contextmenus which are attached to the children event labels that are on the
        % the left hand side of the sev axes
        function contextmenu_label_deleteEvent_callback(obj,hObject,eventData)
            %delete this event if it occurs...
            global MARKING;
            curEvent_index = obj.cur_event_index; %get(hObject,'userdata');
            obj.removeEvent(curEvent_index);
            MARKING.refreshAxes();
        end
        
        
        % =================================================================
        %> @brief Contextmenu callback for labeling an event in the sev
        %> gui.
        %> @param obj instance of CLASS_events_container class.
        %> @param hObject Graphic handle of contextmenu.
        %> @param eventData event data.
        % =================================================================
        function contextmenu_label_callback(obj,hObject,eventData)
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
        %> @param hObject Graphic handle of the event label (left side of main
        %> axes). 
        %> @param eventData not used.
        % =================================================================
        function contextmenu_label_previousEvent_callback(obj,hObject,eventData)
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
        %> @param hObject Graphic handle of the event label (left side of main
        %> axes). 
        %> @param eventData not used.
        % =================================================================
         function contextmenu_label_nextEvent_callback(obj,hObject,eventData)
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
        %> @brief Retrieves the containers current, active event class
        %> based on @c cur_event_index.
        %> @param obj instance of CLASS_events_container class.
        %> @retval childobj Instance of CLASS_events found at
        %> obj.cur_event_index
        % =================================================================
        function childobj = getCurrentChild(obj)
            childobj = obj.getEventObj(obj.cur_event_index);
        end
        
        % =================================================================
        %> @brief Retrieves the CLASS_event object found at the index
        %> provided.
        %> @param obj instance of CLASS_events_container class.
        %> @param event_index Index of the event object to retrieve from
        %> @c cell_of_events property.
        %> @retval childobj Instance of CLASS_events found at
        %> event_index
        % =================================================================
        function childobj = getEventObj(obj,event_index)
            if(event_index>0 && event_index<=obj.num_events)
                childobj = obj.cell_of_events{event_index};
            else
                childobj = [];
            end
        end
        
        % =================================================================
        %> @brief Retrieves the CLASS_event object whose label matches the
        %> input string provided.
        %> @param obj instance of CLASS_events_container class.
        %> @param thisLabel String label of the event object to retrieve from
        %> @c cell_of_events property using string comparison.
        %> @retval childobj Instance of CLASS_events with label @c
        %> thisLabel
        % =================================================================
        function childobj = getEventObjFromLabel(obj,thisLabel)
            allLabels = obj.get_event_labels();            
            childobj = obj.cell_of_events{strcmpi(thisLabel,allLabels)};
        end
        
        % =================================================================
        %> @brief Callback to trigger an event update
        %> @param obj instance of CLASS_events_container class.
        %> @param hObject Graphic handle.
        %> @param eventData not used
        % =================================================================
        function updateEvent_callback(obj,hObject,eventData)            
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
                    end
                    
                    MARKING.showReady();
                end
            end
        end
        
        % =================================================================
        %> @brief Contextmenu callback to export events to the workspace.
        %> @param obj instance of CLASS_events_container class.
        %> @param hObject Graphic handle.
        %> @param eventData not used
        % =================================================================
        function contextmenu_label_export2workspace_callback(obj,hObject,eventData)
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
        %> @brief Contextmenu callback to generate summary statistics.
        %> @param obj instance of CLASS_events_container class.
        % =================================================================
        function contextmenu_label_summaryStats_callback(obj,~,~)            
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
        %> @brief Contextmenu callback to rename/relabel an event
        %> @param obj instance of CLASS_events_container class.
        %> @param hObject Graphic handle.
        %> @param eventData not used
        % =================================================================
        function contextmenu_label_renameEvent_callback(obj,hObject,eventData)
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
        
        %> @brief Retrieve database information for the patstudykey given.
        %> @param patstudykey Unique database ID for the patient study to
        %> retrieve.
        %> @retval PatID The patient ID corresponding to patstudykey
        %> @retval StudyNum The study number corresponding to patstudykey
        function [PatID,StudyNum] = getDB_PatientIdentifiers(patstudykey)
            [PatID,StudyNum] = CLASS_code.getDB_PatientIdentifiers(patstudykey);
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
            [embla_evt_Struct,embla_samplerate_out] = CLASS_codec.parseEmblaEvent(evtFilename,embla_samplerate,desired_samplerate);

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
            HDR=CLASS_codec.parseEmblaHDR(fid);            
        end
        
        
        %> @brief Wrapper function for CLASS_codec.parseSEVevtFile
        %> @param filenameIn
        %> @retval evtStruct
        function evtStruct = evtTxt2evtStruct(filenameIn)
            evtStruct = CLASS_codec.parseSEVevtFile(filenameIn);

        end
        
        %> @brief Wrapper function for CLASS_codec.findOptimalConfigurations
        %> @param roc_struct
        %> @retval roc_struct
        function roc_struct = findOptimalConfigurations(roc_struct)
            roc_struct = CLASS_codec.findOptimalConfigurations(roc_struct);
        end
        
        %> @brief Wrapper function for CLASS_codec.loadROCdata
        %> @param filename
        %> @retval roc_struct
        function roc_struct = loadROCdata(filename)
            roc_struct = CLASS_codec.loadROCdata(filename);    
        end
        
        
        %> @brief Wrapper function for CLASS_codec.loadROCdataOld
        %> @param filename
        %> @retval roc_struct
        function roc_struct = loadROCdataOld(filename) 
            roc_struct = CLASS_codec.loadROCdataOld(filename);
        end
        
         
        % =================================================================
        %> @brief This function loads a Stanford Sleep Cohort's events
        %> structure as parsed by CLASS_codec's parseSSCevtsFile method.        
        %> @param evtsStruct A SCO struct containing the following fields
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
        %> - @c stageVec Vector of scored sleep stages.
        %> @note In the implementation, description is used as the event
        %> label and category is used as a parameter.
        % =================================================================
        function importSSCevtsStruct(evtsStruct)
            obj = CLASS_events_container();
            obj.setDefaultSamplerate(evtsStruct.samplerate);
            if(~isempty(evtsStruct) && ~isempty(evtsStruct.description))
                %indJ contains the indices corresponding to the unique
                %labels in event_labels (i.e. SCO.labels = event_labels(indJ)
                event_labels = unique(lower(evtsStruct.description));
                
                % event_indices = find(event_indices);
                % go through each label and assign it to a channel
                for e = 1:numel(event_labels)
                    cur_evt_label = event_labels{e};
                    evtInd = strcmpi(cur_evt_label,evtsStruct.description);
                    
                    paramStruct.category = evtsStruct.category(evtInd);
                    class_channel_index = [];
                    cur_event = evtsStruct.startStopSamples(evtInd,:);
                    sourceStruct.algorithm = 'external file (.evts)';
                    sourceStruct.channel_indices = [];
                    sourceStruct.editor = 'none';
                    obj.updateEvent(cur_event, cur_evt_label, class_channel_index,sourceStruct,paramStruct);
                end
            end
        end
        
        
        %> @brief Import events from an Embla format output directory.
        %> @param embla_path Path to load
        %> @param embla_samplerate Sample rate Embla used in the data to be
        %> loaded.
        %> @param desired_samplerate Desired samplerate to use in the
        %> output data.
        %> @retval obj Instance of CLASS_events_container
        function obj = importEmblaEvtDir(embla_path,embla_samplerate,desired_samplerate)
            obj = CLASS_events_container();
            import_types = {'biocals','resp','desat','plm','BadData','arousal','snore','tag','user','filesect'}; 
            if(nargin<2 || isempty(embla_samplerate))
                stage_evt_file = fullfile(embla_path,'stage.evt');
                if(exist(stage_evt_file,'file'))
                    [~,embla_samplerate] = CLASS_codec.parseEmblaEvent(stage_evt_file,studyStruct.samplerate,studyStruct.samplerate);
                else
                    fprintf('Original embla samplerate used for storing events is unknown, so there is no point in continuing to load the file.');
                    embla_samplerate = [];
                end
            end
            if(~isempty(embla_samplerate))
                if(nargin<3)
                    desired_samplerate = embla_samplerate;% leave as is for now.
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
                    else
                        fprintf(1,'Warning: %s event file not found!\n',event_file);
                    end
                end
            end
        end
    end
    
end
