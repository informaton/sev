%> @file CLASS_UI_marking.m
%> @brief CLASS_UI_marking serves as the UI component of event marking in
%> the SEV.  In the model, view, controller paradigm, this is the
%> controller.
% ======================================================================
%> @brief CLASS_UI_marking serves as the UI component of event marking in
%> the SEV.  
%
%> In the model, view, controller paradigm, this is the
%> controller.  It is used by SEV to initialize, store, and update
%> user preferences in the SEV.

%The class CLASS_UI_marking serves as the UI component of event marking in
%the SEV
%
% ======================================================================
% History
% Written by Hyatt Moore IV
% 9.30.2012
% modified 4/24/2012 - corrected "center here" callback; after centering the
% epoch would be set and, on occassion, interfere with the desired
% centering.
% ======================================================================
classdef CLASS_UI_marking < handle

    properties
        %> for the patch handles when editing and dragging
        hg_group; 
        %> label of the currently selected channel
        channel_label; 
        %>current index of channel with associated event being marked
        class_channel_index; 
        %>index of start_stop sample location of the event pointed to by event_index
        start_stop_matrix_index;
        %>holds the labels of the events that can be selected
        event_label_cell;
        %>name of the current event being marked
        event_label; 
        %>index of the event in the events_container object
        event_index; 
        %>linehandle in SEV currently selected;
        current_linehandle;
        
        %>cell of string choices for the marking state (off, 'marking','general')
        state_choices_cell; 
        %>string of the current selected choice
        marking_state; 
        %>handle to the figure an instance of this class is associated with
        figurehandle;
        
        %> @brief struct whose fields are axes handles.  Fields include:
            %> - @b.mainhandle handle to the main axes an instance of this class is associated with
            %> - @b.timeline hypnogram and event axes
            %> - @b.utility handle the miscellaneous axes in the lower left corner of the SEV
        axeshandle;
        
        %> @brief struct of text handles.  Fields are: 
        %> - .status; %handle to the text status location of the sev figure where updates can go
        %> - .src_filename; %handle to the text box for display of loaded filename
        texthandle; 
        
        %> struct of handles for the context menus
        contextmenuhandle; 
        
        %> @brief struct with field
        %> - .x_minorgrid which is used for the x grid on the main axes
        linehandle;
         
        toolbarhandle; %handle for the toolbars we add to the SEV
        annotationhandle; %struct for annotation handles
            %- .timeline
        drag_right_h; %right side handle (a block of type line)
        drag_left_h; %the square on the left side of the patch that is draggable
        %these are for adjusting the different time scales and views of the
        %sev
        EDF_HDR;
        epoch_resolution;%struct of different time resolutions, field names correspond to the units of time represented in the field        
        edit_epoch_h;  %handle to the editable epoch handle
        current_epoch;
        num_epochs;
        display_samples; %vector of the samples to be displayed
        shift_display_samples_delta; %number of samples to adjust display by for moving forward or back
        startDateTime;
        study_duration_in_seconds;
        study_duration_in_samples;
        STATE; %struct to keep track of various SEV states
        SETTINGS; %CLASS_settings object - this is brought in to eliminate the need for several globals
        sev; %struct for maintaining sev parameters, which includes these fields:
        %         sev.samplerate; %display samplerate
        %         sev.standard_epoch_sec; %standard epoch size in sev - this is for displaying stages, which hsould be of duration standard epoch size in seconds for each scored stage
        %         sev.screenshot_path; %directory for saving screenshots too
        %         sev_mainaxes_ylim; %main axes y limit
        %         sev_mainaxes_xlim; %main axes x limit
        %         sev.sev.rootpathname; %path that ths file is called from
        %         sev.src_edf_pathname; %pathname of source file
        %         sev.src_filename; %name of source file
        %         sev.yDir; %copy of SEV's global DEFAULTS
        %         sev.databaseInfFile; %file name that includes the available
        %         database configurations
        sev_loading_file_flag; %boolean set to true when initially loading a src file
        sev_mainaxes_ylim;
        sev_mainaxes_xlim;
        sev_STAGES; %struct with fields
            %.line - vector containing stage scores per 30-s epoch as
            %outlined in the .STA file and obtained from WSC
            %.cycles - vector containing the NREM/REM sleep cycle
            %.count - count of epochs for each stage
        sev_adjusted_STAGES; %this is sev_STAGES adjusted for different sized epochs
    end
    
    %sev changes
    % remove resetSEV(handles)
    % copy2clipboard()
    % sev_main_fig_WindowButtonDownFcn(hObject, eventdata)
    % line_buttonDownFcn(hObject, eventdata)
    %     contextmenu_event_showhistogram_callback
    %     contextmenu_event_remove_callback(hObject,eventdata)
    %     restore_state()
    %     set_marking_state_callback(hObject,eventdata)
    %     set_general_edit_state_callback(hObject,eventdata)
    % event_toolbox_callback()
    %     contextmenu_line_referenceline_callback
    %     function contextmenu_line_default_callback(hObject,eventdata)
    %     function contextmenu_line_show_filtered_callback(hObject,eventdata)
    %     function contextmenu_line_show_psd_callback(hObject,eventdata)
    %         function contextmenu_event_detector_callback(hObject,eventdata,detection_mfile)
    % function contextmenu_line_show_epoch_stats_callback(hObject,eventdata)
    % function copy_epoch2clipboard(hObject,eventdata)
    % function copy_channel2workspace(hObject,eventdata)
    % function contextmenu_line_duplicate_callback(hObject,eventdata)
    % function contextmenu_line_hide_callback(hObject,eventdata)
    %     %% reference lines may need a different section
    % function contextmenu_ref_line_callback(hObject,eventdata)
    % function contextmenu_ref_line_color_callback(hObject,eventdata)
    % function contextmenu_ref_line_remove_callback(hObject,eventdata)
    %function compare_events_callback(hObject,eventdata)
    %function menu_tools_quad_Callback(hObject, eventdata, handles)
    %     function contextmenu_align_channels_callback(hObject,eventdata)
    %SETTINGS object (type CLASS_settings) added as a parameter 
    %function close();  %close down, which now uses the SETTINGS close out
    %function clear(); %overloaded destructor
    %to save settings to text.

    methods
        
        function obj = CLASS_UI_marking(sev_fig_h,...
                rootpathname,...
                parameters_filename)
            if(nargin<1)
                sev_fig_h = [];
            end
            if(nargin<2)
                rootpathname = fileparts(mfilename('fullpath'));
            end
            
            %check to see if a settings file exists
            if(nargin<3)
                parameters_filename = '_sev.parameters.txt';
            end;
            
            %create/intilize the settings object            
            obj.SETTINGS = CLASS_settings(rootpathname,parameters_filename);

            obj.figurehandle.sev = sev_fig_h;
            if(ishandle(sev_fig_h))
                obj.initializeProperties();
            end                
        end
        
        %> Destructor
        function close(obj)
            obj.toolbarhandle.jCombo = [];
            obj.saveParameters(); %requires SETTINGS variable
            obj.SETTINGS = [];
        end
        
        
        function paramStruct = getSaveParametersStruct(obj)
            paramStruct = obj.SETTINGS.VIEW;
        end
            
        function initializeProperties(obj) %the constructor more or less
            handles = guidata(obj.figurehandle.sev);
            obj.STATE.batch_process_running = false;
            obj.STATE.single_study_running = false;
            obj.shift_display_samples_delta = 10;
            obj.axeshandle.main = handles.axes1;
            obj.axeshandle.timeline = handles.axes2;
            obj.axeshandle.utility = handles.axes3;
            obj.texthandle.status = handles.text_marker;
            obj.texthandle.src_filename = handles.text_filename;
            obj.hg_group = [];
            obj.class_channel_index = 0;
            obj.channel_label = '';
            obj.start_stop_matrix_index = 0;
            obj.event_label_cell = {'Muscle Activity','Ocular Movement','Electrode Pop','Flat Line','Artifact','Unknown','Leg Movement','PLM','Create New'};
            obj.event_label =''; %make it empty at first
            obj.event_index = 0;
            obj.state_choices_cell = {'off','Marking','Editing'};
            obj.marking_state = 'off';
            obj.current_linehandle = [];
            obj.drag_right_h = [];
            obj.drag_left_h = [];
            
            obj.sev_loading_file_flag = [];
            obj.sev_mainaxes_ylim = [-300,300];
            obj.sev_mainaxes_xlim = [1 3000];
            obj.current_epoch = 0;
            
            obj.configureMainAxesContextmenu();
            obj.configureMenubar();
            obj.setEditEpochHandle(handles.edit_cur_epoch);
            obj.setEpochResolutionHandle(handles.popupmenu_epoch);
            obj.configureUtilitySettings();
            
            obj.addToolbar();
            obj.restore_state();
        end
        
        function saveParameters(obj)
            obj.SETTINGS.saveParametersToFile();
        end
        
        %% -- Button settings for utitlity axes
        function configureUtilitySettings(obj)
            handles = guidata(obj.figurehandle.sev);
%             set(handles.button_utility_settings,'callback',@obj.button_axesutility_settings_callback);
            obj.configureAxesUtilityContextmenu();
            set(handles.bgroup_utility,'selectionchangefcn',@obj.bgroup_utility_radiobutton_selectionchangefcn);
            
            obj.setUtilityAxesType(get(get(handles.bgroup_utility,'selectedobject'),'string'));
            
        end
             
        
        % --- Executes when selected object is changed in bgroup_utility.
        function bgroup_utility_radiobutton_selectionchangefcn(obj,hObject, eventdata)
            % eventdata  structure with the following fields (see UIBUTTONGROUP)
            %	EventName: string 'SelectionChanged' (read only)
            %	OldValue: handle of the previously selected object or empty if none was selected
            %	NewValue: handle of the currently selected object
            
            obj.setUtilityAxesType(get(eventdata.NewValue,'string'));
        end
        
        function setUtilityAxesType(obj,type_string)
            global EVENT_CONTAINER;
            handles = guidata(obj.figurehandle.sev);
            cur_axes = obj.axeshandle.utility;
            button_h = handles.button_utility_settings;
            cla(cur_axes);
            xlabel(cur_axes,'');
            ylabel(cur_axes,'');
            legend(cur_axes,'off');
            set(handles.(strcat('radio_',lower(type_string))),'value',1);
            switch type_string
                case 'PSD'
                    set(cur_axes,'xlim',[0.5 obj.SETTINGS.VIEW.samplerate/2-0.5],'ylimmode','auto');
                    set(cur_axes,'xtickmode','auto');
                    set(obj.contextmenuhandle.axesutility.psd_autoscale,'checked','on'); %clean up the context menu to reflect the ylimmode being on auto now
                    set(cur_axes,'uicontextmenu',obj.contextmenuhandle.axesutility.psd);                    
                    set(button_h,'callback',@obj.updateSettings_PSD_callback);
                case 'MUSIC'
                    set(cur_axes,'xlim',[0.5 obj.SETTINGS.VIEW.samplerate/2-0.5],'ylimmode','auto');
                    set(cur_axes,'xtickmode','auto');
                    set(obj.contextmenuhandle.axesutility.psd_autoscale,'checked','on'); %clean up the context menu to reflect the ylimmode being on auto now
                    set(cur_axes,'uicontextmenu',obj.contextmenuhandle.axesutility.psd);                    
                    set(button_h,'callback',@obj.updateSettings_MUSIC_callback);
                case 'ROC'
                    set(cur_axes,'xlim',[0 1],'ylimmode','manual','ylim',[0 1]);
                    if(~isempty(EVENT_CONTAINER.roc_truth_ind)&&~isempty(EVENT_CONTAINER.roc_estimate_ind))
                        EVENT_CONTAINER.roc_axes_needs_update = true;
                    end
                    set(button_h,'callback',@obj.updatePreferencesROC_callback);
                    set(cur_axes,'uicontextmenu',[]);
                case 'EvtStats'
                    set(cur_axes,'xlim',[0 numel(obj.sev_STAGES.count)-1],'ylimmode','manual','ylim',[0 1]);
                    set(cur_axes,'uicontextmenu',obj.contextmenuhandle.axesutility.evtstats);
                    
                    %5/3/2012 = bug fix - ensures that summary stats are drawn again
                    %when switching to this mode.
                    EVENT_CONTAINER.summary_stats_axes_needs_update = true;
                    set(button_h,'callback',[]);
                    %         EVENT_CONTAINER.calculate_summary_stats();
                otherwise
                    warndlg('unknown selection');
            end
            
            obj.updateUtilityAxes();
        end
        
        function updatePreferencesROC_callback(obj,varargin)
            global EVENT_CONTAINER;
            if(EVENT_CONTAINER.num_events>1)
                roc_settings = settings_roc_dlg();
                if(~isempty(roc_settings))
                    EVENT_CONTAINER.roc_truth_ind = roc_settings.truth;
                    EVENT_CONTAINER.roc_estimate_ind = roc_settings.estimate;
                    EVENT_CONTAINER.roc_artifact_ind = roc_settings.artifact;
                    EVENT_CONTAINER.roc_stage_selection = roc_settings.stage;
                    
                    %calculate the range in - the valid comparison range over whic
                    %comparisons can be made
                    
                    if(isfield(obj.sev_STAGES,'line'))
                        comparison_epoch_ind = zeros(size(obj.sev_STAGES.line));
                        stage_selection = roc_settings.stage;
                        for k=1:numel(stage_selection)
                            cur_stage = stage_selection(k)-1; %-1 b/c 1 based and first stage is 0
                            comparison_epoch_ind = comparison_epoch_ind|obj.sev_STAGES.line==cur_stage;
                        end
                        samples_per_epoch = obj.SETTINGS.VIEW.standard_epoch_sec*obj.SETTINGS.VIEW.samplerate;
                        epoch_ind=[(0:numel(obj.sev_STAGES.line)-1)'*samples_per_epoch+1,(1:numel(obj.sev_STAGES.line))'*samples_per_epoch];
                        comparison_range = epoch_ind(comparison_epoch_ind,:);
                        merge_within_num_samples = 2;
                        merged_events = CLASS_events.merge_nearby_events(comparison_range,merge_within_num_samples);
                        EVENT_CONTAINER.roc_comparison_range = merged_events;
                    else
                        EVENT_CONTAINER.roc_comparison_range = [];
                    end
                    %they selected noe - thought this is taken care of earlier in the
                    %settings_roc_dlg component now
                    if(EVENT_CONTAINER.roc_artifact_ind>EVENT_CONTAINER.num_events)
                        EVENT_CONTAINER.roc_artifact_ind = [];
                    end
                    EVENT_CONTAINER.roc_axes_needs_update = true;
                    obj.updateUtilityAxes();
                end
            else
                warndlg('Not enough events available yet [2]');
            end
        end
        
        function updateSettings_PSD_callback(obj,varargin)
            global CHANNELS_CONTAINER;
            wasModified = obj.SETTINGS.update_callback('PSD');
            if(~isempty(CHANNELS_CONTAINER) && wasModified && (isfield(CHANNELS_CONTAINER,'current_psd_channel_index'))) 
                    CHANNELS_CONTAINER.current_spectrum_channel_index = obj.SETTINGS.PSD.channel_ind;
                    CHANNELS_CONTAINER.showPSD(obj.SETTINGS.PSD);
            end
                
        end
        function updateSettings_MUSIC_callback(obj,varargin)
            global CHANNELS_CONTAINER;
            wasModified = obj.SETTINGS.update_callback('MUSIC');
            if(~isempty(CHANNELS_CONTAINER) && wasModified && (isfield(CHANNELS_CONTAINER,'current_psd_channel_index')))
                CHANNELS_CONTAINER.current_spectrum_channel_index = obj.SETTINGS.MUSIC.channel_ind;
                CHANNELS_CONTAINER.showMUSIC(obj.SETTINGS.MUSIC);
            end
        end
        
        function updateSettings_callback(obj,hObject,eventdata,settingsName)
            %settingsName is a string specifying the settings to update:
            %   'PSD','MUSIC','CLASSIFIER','BATCH_PROCESS','VIEW'
            wasModified = obj.SETTINGS.update_callback(settingsName);
            if(wasModified)
                set(obj.axeshandle.main,...
                    'ydir',obj.SETTINGS.VIEW.yDir);
%                 seconds_per_epoch = obj.getSecondsPerEpoch();
%                 if(seconds_per_epoch == obj.SETTINGS.VIEW.standard_epoch_sec)
% %                     set(obj.axeshandle.main,'dataaspectratiomode','manual','dataaspectratio',[30 12 1]);
%                     set(obj.axeshandle.main,'plotboxaspectratiomode','manual','plotboxaspectratio',[30 12 1]);
%                 else
% %                     set(obj.axeshandle.main,'dataaspectratiomode','auto');
%                     set(obj.axeshandle.main,'plotboxaspectratiomode','auto');
%                 end;
% 
%                 %show the PSD, ROC, events, etc.
% %                 set(obj.axeshandle.utility,...
% %                     'xlim',[0 obj.SETTINGS.VIEW.samplerate/2]);
% %             
                if(obj.STATE.single_study_running)
                    obj.setAxesResolution()
                    obj.refreshAxes();
                end
            end
        end


        %% -- Menubar configuration --
        function configureMenubar(obj)
            handles = guidata(obj.figurehandle.sev);
            
            %file
            set(handles.menu_file_screenshot,'callback',@obj.menu_file_screenshot_callback);
            
               %import section
            set(handles.menu_file_load_sco,'callback',@obj.menu_file_load_sco_callback);
            set(handles.menu_file_load_Evt_File,'callback',@obj.menu_file_load_evt_file_callback);
            set(handles.menu_file_load_events_container,'callback',@obj.menu_file_load_events_container_callback);
            set(handles.menu_file_import_Evt_database,'callback',@obj.menu_file_import_evt_database_callback);
               %export section
            set(handles.menu_file_export_events2txt,'callback',@obj.menu_file_export_events2txt_callback)
            set(handles.menu_file_export_psd2txt,'callback',@obj.menu_file_export_psd2txt_callback);
            set(handles.menu_file_export_events_container,'callback',@obj.menu_file_export_events_container_callback);
            set(handles.menu_file_export_events2mat,'callback',@obj.menu_file_export_events2mat_callback);
            set(handles.menu_file_export_fft2txt,'callback',@obj.menu_file_export_fft2txt_callback);
            
            set(handles.menu_file_createEDF,'callback',@obj.menu_file_createEDF_callback)
            set(handles.menu_file_load_channels,'callback',@obj.load_EDFchannels_callback);%
            set(handles.menu_file_load_EDF,'callback',@obj.load_EDF_callback);%
            
            
            set(handles.menu_tools_event_toolbox,'callback',@obj.eventtoolbox_callback);
            set(handles.menu_tools_filter_toolbox,'callback',@obj.filter_channel_callback);%             filter_channel_Callback
            set(handles.menu_tools_compare_events,'callback',@compare_events_callback);
            set(handles.menu_tools_quad,'callback',@obj.menu_tools_quad_callback);            
            set(handles.menu_tools_roc,'callback',@obj.roc_directory_callback);
            set(handles.menu_tools_timelineEventsSelection,'callback',@obj.menu_tools_timelineEventsSelection_callback);
            
            
            %preferences
            set(handles.menu_settings_power_psd,'callback',@obj.updateSettings_PSD_callback);
            set(handles.menu_settings_power_music,'callback',@obj.updateSettings_MUSIC_callback);
            set(handles.menu_settings_roc,'callback',@obj.updatePreferencesROC_callback);
            set(handles.menu_settings_classifiers,'callback',{@obj.updateSettings_callback,'CLASSIFIER'});
            set(handles.menu_settings_defaults,'callback',{@obj.updateSettings_callback,'DEFAULTS'});
            set(handles.menu_settings_saveChannelConfig,'callback',@obj.menu_settings_defaults_callback);
            set(handles.menu_settings_saveChannelConfig,'callback',@obj.menu_settings_saveChannelConfig_callback);
            
            
            

            %batch mode
            set(handles.menu_batch_run,'callback',@obj.menu_batch_run_callback);
            set(handles.menu_tools_roc_directory,'callback',@obj.roc_directory_callback);
            set(handles.menu_batch_roc_database,'callback',@obj.menu_batch_roc_database_callback);
            

            %help - reset and restart left in the SEV for now
            set(handles.menu_help_outputHDR,'callback',@obj.menu_help_outputHDR_callback);
            set(handles.menu_help_stage2workspace,'callback',@obj.menu_help_stage2workspace_callback);
        end
        
        function menu_help_stage2workspace_callback(obj,hObject, eventdata)
            %send the staging data for the current file to the workspace
            varName = 'sev_STAGES';
            
            assignin('base',varName,obj.sev_STAGES);
            uiwait(msgbox(sprintf('Staging data saved to workspace variable %s',varName)));
        end
        
        % --------------------------------------------------------------------
        function menu_file_screenshot_callback(obj,hObject, eventdata)
            % hObject    handle to menu_file_screenshot (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            if(~isfield(obj.SETTINGS.VIEW,'screenshot_path'))
                obj.SETTINGS.VIEW.screenshot_path = pwd;
            end
            
            filterspec = {'png','PNG';'jpeg','JPEG'};
            save_format = {'-dpng','-djpeg'};
            img_filename = [obj.SETTINGS.VIEW.src_edf_filename,'_epoch ',num2str(obj.current_epoch),'.png'];
            [img_filename, img_pathname, filterindex] = uiputfile(filterspec,'Screenshot name',fullfile(obj.SETTINGS.VIEW.screenshot_path,img_filename));
            if isequal(img_filename,0) || isequal(img_pathname,0)
                disp('User pressed cancel')
            else
                try
                    if(filterindex>2)
                        filterindex = 1; %default to .png
                    end
                    fig_h = obj.figurehandle.sev;
                    axes1_copy = copyobj(obj.axeshandle.main,fig_h);
%                     axes1_props = get(axes1_copy);
%                     text_h = strcmp(get(axes1_props.Children,'type'),'text');
%                     text_h = axes1_props.Children(text_h);
                    
                    %         apos = get(handles.axes1,'position');
                    %         dataaspectratio = get(handles.axes1,'dataaspectratio');
                    %         original_axes_settings = get(handles.axes1);
                    %         f = figure('visible','off','paperpositionmode','auto','units',axes1_props.Units);
                    f = figure('visible','off','paperpositionmode','auto','inverthardcopy','on',...
                        'units',get(fig_h,'units'),'position',get(fig_h,'position'),...
                        'toolbar','none','menubar','none');
                    set(f,'units','normalized');
                    set(axes1_copy,'parent',f);
                    
%                     set(text_h,'Units','normalized');
%                     
%                     text_E = get(text_h,'extent');
%                     pos_E = get(text_h,'position');
%                     if(iscell(text_E))
%                         text_E = cell2mat(text_E);
%                         pos_E = cell2mat(pos_E);
%                     end
%                     max_E_width = max(text_E(:,3));
%                     
%                     for k=1:numel(text_h)
%                         set(text_h(k),'position',[-text_E(k,3)-0.1*max_E_width,pos_E(k,2)]);
%                     end
%                     
%                     
%                     set(axes1_copy,'Position',[max_E_width,(1-sum(axes1_props.Position([2,4])))/2,1-max_E_width*1.1,sum(axes1_props.Position([2,4]))])
cropFigure2Axes(f,axes1_copy);

                    set(f,'visible','on');
                    set(f,'clipping','off');
                    
                    
                    %         style = getappdata(f,'Exportsetup');
                    %         if isempty(style)
                    %             try
                    %                 style = hgexport('readstyle','Default');
                    %             catch me
                    %                 style = hgexport('factorystyle');
                    %             end
                    %         end
                    %         hgexport(f,fullfile(img_pathname,img_filename),style,'Format',filterspec{filterindex,1});
                    print(f,save_format{filterindex},'-r0',fullfile(img_pathname,img_filename));
                    
                    %save the screenshot
                    %         print(f,['-d',filterspec{filterindex,1}],'-r75',fullfile(img_pathname,img_filename));
                    %         print(f,fullfile(img_pathname,img_filename),['-d',filterspec{filterindex,1}]);
                    %         print(f,['-d',filterspec{filterindex,1}],fullfile(img_pathname,img_filename));
                    %         set(handles.axes1,'position',apos,'dataaspectratiomode','manual' ,'dataaspectratio',dataaspectratio,'parent',handles.sev_main_fig)
                    delete(f);
                    
                    obj.SETTINGS.VIEW.screenshot_path = img_pathname;
                catch ME
                    showME(ME);
                    %         set(handles.axes1,'parent',handles.sev_main_fig);
                end
            end
        end
        
        % --------------------------------------------------------------------
        function menu_help_outputHDR_callback(obj,hObject, eventdata)
            % hObject    handle to menu_tools_printHDR (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            %display the HDR information for the currently loaded EDF
            
            fields = fieldnames(obj.EDF_HDR);
            for k = 1:numel(fields)
                value = obj.EDF_HDR.(fields{k});
                if(isnumeric(value))
                    disp([fields{k},': ',num2str(value(:)')]);
                else
                    disp([fields{k},': ',value(:)']);
                end
            end
        end
        
        % --------------------------------------------------------------------
        function menu_file_load_sco_callback(obj,hObject, eventdata)
            % hObject    handle to menu_file_load_sco (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            global EVENT_CONTAINER;
            
            suggested_filename = fullfile([obj.SETTINGS.VIEW.src_edf_filename(1:end-4),'.SCO']);
            suggested_pathname = obj.SETTINGS.VIEW.src_event_pathname;
            
            if(exist(fullfile(suggested_pathname,suggested_filename),'file'))
                sco_suggestion = fullfile(suggested_pathname,suggested_filename);
            else
                sco_suggestion = suggested_pathname;
            end
            [filename,pathname]=uigetfile({suggested_filename,'Study Events saved as .SCO';...
                '*.SCO','All .SCO files';'*.*','All Files (*.*)'},'Event File Finder',...
                sco_suggestion);
            if(filename~=0)
                obj.SETTINGS.VIEW.src_event_pathname = pathname;
                EVENT_CONTAINER.loadEventsFromSCOFile(fullfile(pathname,filename));
                obj.refreshAxes();
            end;
            
        end
        
        % --------------------------------------------------------------------
        function menu_file_load_evt_file_callback(obj,hObject, eventdata)
            % Purpose: update the SEV with a range of events that were previously saved
            % using the save to .mat menu item.
            % hObject    handle to menu_file_load_events_container (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            global EVENT_CONTAINER;
            
            suggested_filename = fullfile(['evt.',obj.SETTINGS.VIEW.src_edf_filename(1:end-4),'.*']);
            suggested_pathname = obj.SETTINGS.VIEW.src_event_pathname;
            suggested_file = getFilenames(suggested_pathname,suggested_filename);
            if(~isempty(suggested_file))
                suggestion = fullfile(suggested_pathname,suggested_file{1});
            else
                suggestion = suggested_pathname;
            end
            [filename,pathname]=uigetfile({suggested_filename,'Study Events (Evt.) -mat or .txt';...
                '*.*','All Files (*.*)'},'Event File Finder',...
                suggestion);
            if(filename~=0)
                obj.SETTINGS.VIEW.src_event_pathname = pathname;

                EVENT_CONTAINER.loadEvtFile(fullfile(pathname,filename));
                obj.refreshAxes();
            end;
        end
        
        % --------------------------------------------------------------------
        function menu_file_load_events_container_callback(obj,hObject, eventdata)
            % hObject    handle to menu_file_load_events_container (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            global EVENT_CONTAINER;            
            
            
            [filename,pathname]=uigetfile({'*.MAT;*.mat','Matlab format'},'Event File Finder',...
                obj.SETTINGS.VIEW.src_event_pathname);
            if(filename~=0)
                EVENT_CONTAINER.loadEventsContainerFromFile(fullfile(pathname,filename));
                obj.SETTINGS.VIEW.src_event_pathname = pathname;
                obj.refreshAxes();
            end;
        end
        
        
        % --------------------------------------------------------------------
        function menu_file_import_evt_database_callback(obj,hObject, eventdata)
            % hObject    handle to menu_file_import_Evt_database (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            global CHANNELS_CONTAINER;
            global EVENT_CONTAINER;
            
            selection = importDBaseEvents_dlg(CHANNELS_CONTAINER.getChannelNames());
            % selection is a struct with following fields
            % selection.detectorID
            % selection.database_choice
            % selection.channel_index
            
            if(~isempty(selection))
                %prepare database import fields
                selection.DB = loadDatabaseStructFromInf(obj.SETTINGS.VIEW.database_inf_file);
                DB_fields = fieldnames(selection.DB);
                for k=1:numel(DB_fields)
                    selection.DB.(DB_fields{k}) = selection.DB.(DB_fields{k}){selection.database_choice};
                end
                selection.patstudy = obj.SETTINGS.VIEW.src_edf_filename;
                try
                    EVENT_CONTAINER.loadEventsFromDatabase(selection);
                    obj.refreshAxes();

                catch me
                    warndlg('Database load failed.  See console window for more information');
                    showME(me);
                end
            end
        end
        
        % --------------------------------------------------------------------
        function menu_file_export_events2txt_callback(obj,hObject, eventdata)
            global EVENT_CONTAINER;
            if(ismethod(EVENT_CONTAINER,'save2txt'))
                EVENT_CONTAINER.save2txt();
            end
        end

        % --------------------------------------------------------------------
        function menu_file_export_psd2txt_callback(obj,hObject, eventdata, handles)
            global CHANNELS_CONTAINER;
            
            CHANNELS_CONTAINER.savePSD2txt(obj.SETTINGS.VIEW.src_edf_filename);
        end
        
        
        % --------------------------------------------------------------------
        function menu_file_export_events_container_callback(obj,hObject, eventdata)
            % hObject    handle to menu_file_export_events_container (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)            
            global BATCH_PROCESS;          
            global EVENT_CONTAINER;
            
            filename_out = obj.SETTINGS.VIEW.src_edf_filename;
            if(obj.STATE.batch_process_running)
                filename_out = [filename_out(1:end-3) BATCH_PROCESS.output_files.events_filename];
            else
                filename_out = [filename_out(1:end-3) 'evt.mat'];
            end;
            
            filename= fullfile(obj.SETTINGS.VIEW.src_event_pathname,obj.SETTINGS.VIEW.output_pathname,filename_out);
            
            EVENT_CONTAINER.saveEventsContainerToFile(filename);
            disp(['Events saved to file: ', filename]);
        end
        
        % --------------------------------------------------------------------
        function menu_file_export_events2mat_callback(obj,hObject, eventdata)
            % hObject    handle to menu_file_export_events2mat (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            global EVENT_CONTAINER;
            EVENT_CONTAINER.save2mat();
            
        end
        % --------------------------------------------------------------------
        function menu_file_export_fft2txt_callback(obj,hObject, eventdata)
            % hObject    handle to menu_file_export_fft2txt (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            disp 'This function was moved to another file';
        end
        
        % --------------------------------------------------------------------
        function menu_file_createEDF_callback(obj,hObject, eventdata)
            % hObject    handle to menu_file_createEDF (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            createEDF();
        end
        
        %--------------------------------%
        %      Analyzer Callbacks        %
        %--------------------------------%        
        % --------------------------------------------------------------------
        function filter_channel_callback(obj,hObject, eventdata)
            % hObject    handle to menu_tools_filter_toolbox (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            global CHANNELS_CONTAINER;
            
            channel_label_str = cell(CHANNELS_CONTAINER.num_channels,1);
            for k=1:numel(channel_label_str)
                channel_label_str{k} = CHANNELS_CONTAINER.cell_of_channels{k}.EDF_label;
            end
            
            filter_struct = prefilter_dlg(channel_label_str,CHANNELS_CONTAINER.filterArrayStruct,[],obj.SETTINGS.VIEW.filter_path,obj.SETTINGS.VIEW.filter_inf_file,CHANNELS_CONTAINER);
            
            %filter_struct has the following fields
            % src_channel_index   (the index of the event_container EDF channel)
            % src_channel_label   (cell label of the string that holds the EDF channel
            %                      label
            % m_file                matlab filename to use for the filtering (feval)
            % ref_channel_index   (the index or indices of additional channels to use
            %                       as a reference when and where necessary
            % ref_channel_label   (cell of strings that hold the EDF channel label
            % associated with the ref_channel_index
            if(~isempty(filter_struct))
                obj.showBusy();
                CHANNELS_CONTAINER.filter(filter_struct);
                obj.refreshAxes();
            end
            
        end
        
        function compare_events_callback(obj,hObject,eventdata)
            global EVENT_CONTAINER;
            
            handles = guidata(hObject);
            if(EVENT_CONTAINER.num_events<=1)
                errordlg('Not enough events available to compare.');
                obj.restore_state();
            else
                comparison_dlg =CLASS_compareEvents_dialog;
                [indices2compare, bounds] = comparison_dlg.run();
                if(any(indices2compare))
                    if(bounds==1) %compare the whole night
                        [score, events_space] =EVENT_CONTAINER.compareEvents(indices2compare);
                    elseif(bounds==2) %compare the current view
                        range = get(handles.axes1,'xlim');
                        [score, events_space] =EVENT_CONTAINER.compareEvents(indices2compare,range);
                    end;
                    h = figure('name',[num2str(100*score,'%05.2f'),'% overlap'],...
                        'toolbar','none','menubar','none');
                    colormap([0 0 0; 1 1 1]);
                    imagesc(events_space);
                    
                    xlabel(comparison_dlg.event_labels{comparison_dlg.selected_events(2)},'interpreter','none');
                    ylabel(comparison_dlg.event_labels{comparison_dlg.selected_events(1)},'interpreter','none');
                    
                    waitforbuttonpress();
                    if(ishandle(h))
                        delete(h);
                    end;
                end;
            end
            
        end
        
        % --------------------------------------------------------------------
        function menu_tools_quad_callback(obj,hObject, eventdata)
            % hObject    handle to menu_tools_quad (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            global EVENT_CONTAINER;
            
            % handles = guidata(hObject);
            if(EVENT_CONTAINER.num_events<=1)
                errordlg('Not enough events available to compare.');
                obj.restore_state();
            else
                
                
                comparison_dlg =CLASS_compareEvents_dialog;
                [indices2compare, bounds] = comparison_dlg.run();

            end
            
        end
        
        % --------------------------------------------------------------------
        function menu_settings_defaults_callback(obj,hObject, eventdata, handles)
            %Purpose: let user change default settings
            % hObject    handle to menu_settings_Defaults (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            

            
        end
        
        % --------------------------------------------------------------------
        function menu_tools_timelineEventsSelection_callback(obj,hObject, eventdata)
            % hObject    handle to menu_tools_viewAllEvents (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            %called from the menu bar, and is used to determine how the lower axes
            %should display events
            global EVENT_CONTAINER;
            % global CHANNELS_CONTAINER;
            
            if(EVENT_CONTAINER.num_events<1)
                warndlg('No events currently available');
            else
                units = 'points';
                dlg = dialog('visible','off','units',units);
                
                pan_file = uipanel('title','External Events (file or user)','parent',dlg,'units',units);
                pan_channels = uipanel('title','SEV Events','parent',dlg,'units',units);
                
                %loop through each channel, and then through each event object within that
                %channel - make a control for each and set to enable/checked if previously
                %selected...
                for k=1:EVENT_CONTAINER.num_events;
                    
                    eventLabel = [EVENT_CONTAINER.cell_of_events{k}.label,' (',num2str(EVENT_CONTAINER.channel_vector(k)),')'];
                    
                    if(EVENT_CONTAINER.channel_vector(k)) %i.e. it is not ==0 and thus not a file event
                        parent = pan_channels;
                    else
                        parent = pan_file;
                    end;
                    uicontrol('style','checkbox','units',units,'string',eventLabel,'parent',pan_channels,'userdata',k,'value',CHANNELS_CONTAINER.events_to_plot(k));
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
                
                bOK = uicontrol('parent',dlg,'style','pushbutton','string','OK','units',units,'position',[50,20,50,20]);
                bCancel = uicontrol('parent',dlg,'style','pushbutton','string','Cancel','units',units,'position',[50+50+10,20,50,20],'callback','output = [],close(gcbf)');
                bPos = get(bOK,'position');
                
                set(pan_channels,'units',units,'position',[width*1.5, 2*bPos(2)+bPos(4), cur_pos(3)+width*3,cur_pos(2)+delta*2]);
                pan_channelsPos = get(pan_channels,'position');
                
                cur_pos = [delta, delta, 0 0];
                
                h = allchild(pan_file);
                h = h(1:end-1); %skip the initial channel, which is not there
                h_file = h;
                for k=1:numel(h)
                    extent = get(h(k),'extent');
                    cur_pos(3:4) = max(cur_pos(3:4),extent(3:4)+20);
                    set(h(k),'position',cur_pos);
                    cur_pos(2) = cur_pos(2)+cur_pos(4);
                end
                
                set(bOK,'callback','uiresume(gcbf)');
                
                set(pan_file,'units',units,'position',[width*1.5, pan_channelsPos(2)+pan_channelsPos(4)+bPos(4), cur_pos(3)+width*3,cur_pos(2)+delta*2]);
                pan_filePos = get(pan_file,'position');
                max_width = max(pan_channelsPos(3),pan_filePos(3));
                pan_filePos(3) = max_width;
                pan_channelsPos(3)=max_width;
                set(pan_file,'position',pan_filePos);
                set(pan_channels,'position',pan_channelsPos);
                bPos(1) = width*1.5;
                set(bOK,'position',bPos);
                bPos(1) = max_width+width*1.5-bPos(3);
                set(bCancel,'position',bPos);
                figPosition = get(dlg,'position');
                
                set(0,'Units',units)
                scnsize = get(0,'ScreenSize');
                
                figPosition(3:4) = [max_width+width*3,...
                    bPos(4)+pan_filePos(4)+pan_filePos(2)]; %[width, height]
                set(dlg,'position',[(scnsize(3:4)-figPosition(3:4))/2,figPosition(3:4)],'visible','on');
                uiwait(dlg);
                
                %output will contain a boolean matrix containing the on/off selection
                %values for each label that was created.  This is changed to just indices of the true values so
                %they can be used to determine
                %which values should be drawn along the entire night axes (axes2) in
                %updateAxes2 function
                if(ishghandle(dlg)) %if it is still a graphic, then...
                    if(numel(h_file)==1)
                        if(get(h_file,'value'))
                            file_events_to_plot = get(h_file,'userdata');
                        else
                            file_events_to_plot = [];
                        end
                    else
                        file_events_to_plot = get(h_file(cell2mat(get(h_file,'value'))==1),'userdata');
                    end;
                    if(iscell(file_events_to_plot))
                        file_events_to_plot = cell2mat(file_events_to_plot);
                    end;
                    
                    if(numel(h_channels)==1)
                        if(get(h_channels,'value'))
                            channel_events_to_plot = get(h_channels,'userdata');
                        else
                            channel_events_to_plot = [];
                        end
                    else
                        channel_events_to_plot = get(h_channels(cell2mat(get(h_channels,'value'))==1),'userdata');
                    end;
                    if(iscell(channel_events_to_plot))
                        channel_events_to_plot = cell2mat(channel_events_to_plot);
                    else
                        channel_events_to_plot = false(EVENT_CONTAINER.num_eventS);
                        
                    end
                    EVENT_CONTAINER.events_to_plot = [file_events_to_plot,channel_events_to_plot];
                    delete(dlg);
                    obj.refreshAxes(handles);
                end;
            end;
        end


        
        
        % --------------------------------------------------------------------
        function menu_settings_saveChannelConfig_callback(obj,hObject, eventdata, handles)
            % hObject    handle to menu_settings_saveChannelConfig (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            global CHANNELS_CONTAINER;
            
            if(~isempty(CHANNELS_CONTAINER))
                CHANNELS_CONTAINER.saveSettings(obj.SETTINGS.VIEW.channelsettings_file);
            end
        end
        

        %--------------------------------%
        %      Batch mode Callbacks      %
        %--------------------------------%
        % --------------------------------------------------------------------
        function menu_batch_run_callback(obj,hObject, eventdata, handles)
            % hObject    handle to menu_batch_run (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            batch_run();
        end

                % --------------------------------------------------------------------
        function menu_batch_roc_database_callback(obj,hObject, eventdata)
            batch_roc_viewer();
        end
        
        % --------------------------------------------------------------------
        function roc_directory_callback(obj,hObject, eventdata)
            roc_dlg();
        end
        
   
        %% -- Contextmenu configuration section --

        
        % ----------------------
        % Main Axes Contextmenus 
        % ----------------------
        function configureMainAxesContextmenu(obj)
            %%% reference line contextmenu
            
            contextmenu_mainaxes_h = uicontextmenu('callback',@obj.contextmenu_mainaxes_callback);
            obj.contextmenuhandle.axesmain.alignchannels = uimenu(contextmenu_mainaxes_h,'Label','Align Channels');
            obj.contextmenuhandle.axesmain.centerepoch = uimenu(contextmenu_mainaxes_h,'Label','Center Here','callback',@obj.contextmenu_mainaxes_center_callback);
            obj.contextmenuhandle.axesmain.unhide = uimenu(contextmenu_mainaxes_h,'Label','Unhide');
            obj.contextmenuhandle.axesmain.x_minorgrid = uimenu(contextmenu_mainaxes_h,'Label','Minor Grid','callback',@obj.contextmenu_mainaxes_minorgrid_callback,'checked','on','separator','on');
            obj.contextmenuhandle.axesmain.x_majorgrid = uimenu(contextmenu_mainaxes_h,'Label','Major Grid','callback',@obj.contextmenu_mainaxes_majorgrid_callback,'checked','on');
            uimenu(contextmenu_mainaxes_h,'Label','Pop out','callback',{@obj.popout_axes,obj.axeshandle.main});
            uimenu(contextmenu_mainaxes_h,'Label','Event Toolbox','separator','on','callback',@obj.eventtoolbox_callback);
            set(obj.axeshandle.main,'uicontextmenu',contextmenu_mainaxes_h);
        end
        
        % --------------------------------------------------------------------
        function contextmenu_mainaxes_callback(obj,hObject, eventdata)
            %configure sub contextmenus
            global CHANNELS_CONTAINER;
            set(obj.contextmenuhandle.axesmain.alignchannels,'callback',@CHANNELS_CONTAINER.align_channels_on_axes);
%             gridstate = get(obj.axesmain,'grid');
%             if(strcmpi(gridstate,'on'))
%                 set(obj.contextmenuhandle.axesmain.grid,'string','Turn Grid Off');
%             else
%                 set(obj.contextmenuhandle.axesmain.grid,'string','Turn Grid On');
%             end
            CHANNELS_CONTAINER.configure_contextmenu_unhidechannels(obj.contextmenuhandle.axesmain.unhide);
        end
        
        function contextmenu_mainaxes_center_callback(obj,hObject,evetdata)
            pos = round(get(obj.axeshandle.main,'currentpoint'));
            
            startSample = round((pos(1)-obj.getSamplesPerEpoch()/2));  %make mouse position be in the middle of the new epoch
            
            %don't do this call:
            %    obj.setStartSample(startSample);
            %becasue it will realign on the epoch if the centering changes
            %the epoch start position.
            samples_per_epoch = obj.getSamplesPerEpoch();
            if(startSample<1)
                obj.display_samples = 1:samples_per_epoch;
            elseif(startSample+samples_per_epoch>obj.study_duration_in_samples)
                obj.display_samples = obj.study_duration_in_samples-samples_per_epoch+1:obj.study_duration_in_samples;
            else
                obj.display_samples = startSample:startSample+samples_per_epoch-1;
            end
            obj.sev_mainaxes_xlim = [obj.display_samples(1),obj.display_samples(end)];
            
            obj.updateMainAxes();
        end 

        function setStartSample(obj,startSample)
            %begin the main axes at start sample
            samples_per_epoch = obj.getSamplesPerEpoch();
            if(startSample<1)
                obj.display_samples = 1:samples_per_epoch;
            elseif(startSample+samples_per_epoch>obj.study_duration_in_samples)
                obj.display_samples = obj.study_duration_in_samples-samples_per_epoch+1:obj.study_duration_in_samples;
            else
                obj.display_samples = startSample:startSample+samples_per_epoch-1;
            end
            obj.sev_mainaxes_xlim = [obj.display_samples(1),obj.display_samples(end)];
            
            new_epoch = obj.getEpochAtSamplePt(obj.sev_mainaxes_xlim(1));
            
            if(new_epoch~=obj.current_epoch)
                obj.setEpoch(new_epoch);
            else
                obj.updateMainAxes();
            end;
        end
        
        function increaseStartSample(obj)
            obj.setStartSample(obj.display_samples+obj.shift_display_samples_delta); 
        end
        function decreaseStartSample(obj)
            obj.setStartSample(obj.display_samples-obj.shift_display_samples_delta); 
        end
        
        % --------------------------------------------------------------------
        function contextmenu_mainaxes_majorgrid_callback(obj,hObject, eventdata)
            if(strcmp(get(hObject,'Checked'),'on'))
                set(hObject,'Checked','off');
                set(obj.axeshandle.main,'xgrid','off');%,'ygrid','on');
            else
                set(hObject,'Checked','on');
                set(obj.axeshandle.main,'xgrid','on');%,'ygrid','off');
            end;
        end
        function contextmenu_mainaxes_minorgrid_callback(obj,hObject, eventdata)
            if(strcmp(get(hObject,'Checked'),'on'))
                set(hObject,'Checked','off');
                set(obj.linehandle.x_minorgrid,'visible','off');
            else
                set(hObject,'Checked','on');
                obj.draw_x_minorgrid();
                set(obj.linehandle.x_minorgrid,'visible','on');
            end;
        end
        

        % --------------------------------------------------------------------
        function context_menu_swap_Callback(hObject, eventdata, handles)
            % hObject    handle to context_menu_swap (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)   
        end
        
        % --------------------------------------------------------------------
        function context_menu_swap_psd_Callback(hObject, eventdata, handles)
            % hObject    handle to context_menu_swap_psd (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            tmpPos = get(handles.axes1,'position');
            % tmpOuterPos = get(handles.axes1,'outerposition');
            set(handles.axes1,'position',get(handles.axes3,'position'));
            % set(handles.axes1,'outerposition',get(handles.axes3,'outerposition'));
            set(handles.axes3,'position',tmpPos);
            % set(handles.axes3,'outerposition',tmpOuterPos);
        end
        
        % --------------------------------------------------------------------
        function context_menu_swap_axes2_Callback(hObject, eventdata, handles)
            % hObject    handle to context_menu_swap_axes2 (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            tmpPos = get(handles.axes1,'position');
            set(handles.axes1,'position',get(handles.axes2,'position'));
            set(handles.axes2,'position',tmpPos);            
        end
        
        function eventtoolbox_callback(obj,hObject,eventdata)
            %sets up and calls the CLASS_events_toolbox_dialog function which in turn
            %synthesizes new channels and events as determined by the user.
            global EVENT_CONTAINER;
            
            if(ishandle(obj.current_linehandle))
                channel_index = obj.class_channel_index;
            else
                channel_index = 1;
            end;
            
            event_toolbox = CLASS_events_toolbox_dialog(); %create an empty object...
            event_toolbox.num_sources = 1;
            event_toolbox.channel_selections = channel_index;
            event_toolbox.detection_path = fullfile(obj.SETTINGS.rootpathname,obj.SETTINGS.VIEW.detection_path);
            event_toolbox.detection_inf_file = obj.SETTINGS.VIEW.detection_inf_file;
            try
                event_toolbox.run();
                
                obj.event_index = event_toolbox.updated_event_index;
                if(~isempty(obj.event_index))
                    
                    EVENT_CONTAINER.draw_events(obj.event_index); %events_to_plot(event_index) = 1;
                    obj.refreshAxes();
                end;
            catch ME
                showME(ME);
                delete(event_toolbox.dialog_handle);
                delete(event_toolbox);
            end
            obj.restore_state();

        end

        % ----------------------
        % Utility Axes Contextmenus 
        % ----------------------
        function configureAxesUtilityContextmenu(obj)
            contextmenu_axesutility_psd_h = uicontextmenu('callback',@obj.contextmenu_axesutility_psd_callback,'parent',obj.figurehandle.sev);
            obj.contextmenuhandle.axesutility.psd_autoscale = uimenu(contextmenu_axesutility_psd_h,'Label','Auto Scale','callback',@obj.contextmenu_axesutility_psd_autoscale_callback);
            obj.contextmenuhandle.axesutility.psd_select_channel = uimenu(contextmenu_axesutility_psd_h,'Label','Select Channel');
            uimenu(contextmenu_axesutility_psd_h,'Label','Pop out','callback',{@obj.popout_axes,obj.axeshandle.utility});
            obj.contextmenuhandle.axesutility.psd = contextmenu_axesutility_psd_h;
            
            contextmenu_axesutility_evtstats_h = uicontextmenu('callback',@obj.contextmenu_axesutility_evtstats_callback,'parent',obj.figurehandle.sev);
            obj.contextmenuhandle.axesutility.evtstats_select_event = uimenu(contextmenu_axesutility_evtstats_h,'Label','Select Event');
            obj.contextmenuhandle.axesutility.evtstats_select_stats_type = uimenu(contextmenu_axesutility_evtstats_h,'Label','Parameter to show');
            uimenu(obj.contextmenuhandle.axesutility.evtstats_select_stats_type,'Label','Count','callback',{@obj.contextmenu_axesutility_evtstats_select_stats_type,'count'});
            uimenu(obj.contextmenuhandle.axesutility.evtstats_select_stats_type,'Label','Duration (seconds)','callback',{@obj.contextmenu_axesutility_evtstats_select_stats_type,'dur_sec'});
            
            obj.contextmenuhandle.axesutility.evtstats_check_density = uimenu(contextmenu_axesutility_evtstats_h,'Label','Show as Density','checked','off','callback',@obj.contextmenu_axesutility_evtstats_check_density_callback);
            obj.contextmenuhandle.axesutility.evtstats = contextmenu_axesutility_evtstats_h;
            
        end
        
        
        % --------------------------------------------------------------------
        %Event stats utililty axes selection contextmenus
        function contextmenu_axesutility_evtstats_callback(obj,hObject, eventdata)
            % hObject    handle to EvtStats_contextmenu (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            % hObject    handle to PSD_context_menu (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            global EVENT_CONTAINER;  
            event_selection_menu_h = obj.contextmenuhandle.axesutility.evtstats_select_event;
            delete(get(event_selection_menu_h,'children'));
            n = EVENT_CONTAINER.num_events;
            if(n>0)
                set(event_selection_menu_h,'enable','on');
                for k=1:n
                    label = EVENT_CONTAINER.cell_of_events{k}.label;
                    if(EVENT_CONTAINER.cur_event_index==k)
                        checked = 'on';
                    else
                        checked = 'off';
                    end;
                    uimenu(event_selection_menu_h,'Label',label,'separator','off',...
                        'checked',checked,'userdata',{k,@obj.updateUtilityAxes},'callback',...
                        'global EVENT_CONTAINER;data= get(gcbo,''userdata'');EVENT_CONTAINER.cur_event_index=data{1}; EVENT_CONTAINER.summary_stats_axes_needs_update=true;func=data{2};feval(func);');
                end;
            else
                set(event_selection_menu_h,'enable','off');
            end
        end
        
        function contextmenu_axesutility_evtstats_select_stats_type(obj,hObject,eventdata, selected_type_str)
            global EVENT_CONTAINER;
            EVENT_CONTAINER.summary_stats_settings.type = selected_type_str;
            EVENT_CONTAINER.summary_stats_axes_needs_update=true;
            obj.updateUtilityAxes();
        end
            
        function contextmenu_axesutility_evtstats_check_density_callback(obj,hObject,eventdata)
            global EVENT_CONTAINER;
            if(strcmp(get(hObject,'Checked'),'off'))
                set(hObject,'checked','on');  %show density
            else
                set(hObject,'checked','off'); %show raw
            end;
            EVENT_CONTAINER.summary_stats_settings.show_density = strcmpi(get(hObject,'Checked'),'on');
            EVENT_CONTAINER.summary_stats_axes_needs_update=true;

            obj.updateUtilityAxes();                
        end
            
            
        %PSD utility axes
        % --------------------------------------------------------------------
        function contextmenu_axesutility_psd_callback(obj,hobject, eventdata)
            % hObject    handle to PSD_context_menu (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            global CHANNELS_CONTAINER;
            channel_selection_h = obj.contextmenuhandle.axesutility.psd_select_channel;
            delete(get(channel_selection_h,'children'));
            n = CHANNELS_CONTAINER.num_channels;
            if(n>0)
                set(channel_selection_h,'enable','on');
                for k=1:CHANNELS_CONTAINER.num_channels
                    tmp = CHANNELS_CONTAINER.cell_of_channels{k};
                    if(~tmp.hidden)
                        if(CHANNELS_CONTAINER.current_spectrum_channel_index==k)
                            checked = 'on';
                        else
                            checked = 'off';
                        end;
                        uimenu(channel_selection_h,'Label',tmp.title,'separator','off',...
                            'checked',checked,'callback',{@obj.contextmenu_axesutility_psd_selectchannel_callback,k});
                    end;
                end;
            else
                set(channel_selection_h,'enable','off');
            end
        end
        
         % --------------------------------------------------------------------
        function contextmenu_axesutility_psd_selectchannel_callback(obj,hObject, eventdata, channel_index)
            global CHANNELS_CONTAINER;
            CHANNELS_CONTAINER.current_spectrum_channel_index = channel_index;
            obj.updateUtilityAxes();
        end
        % --------------------------------------------------------------------
        function contextmenu_axesutility_psd_autoscale_callback(obj,hObject, eventdata, handles)
            % hObject    handle to psd_context_menu_auto_scale (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            if(strcmp(get(hObject,'Checked'),'off'))
                set(hObject,'checked','on');
                set(obj.axeshandle.utility,'ylimmode','auto')
            else
                set(hObject,'checked','off');
                set(obj.axeshandle.utility,'ylimmode','manual');%,'ylim',get(handles.axes3,'ylim'));
            end;
            guidata(hObject,handles);
        end
        
                
        
        
         %% -- Toolbar configuration section

        function addToolbar(obj)
            handles = guidata(obj.figurehandle.sev);
            
            
            %remove the default toolbar
            default_toolbar = findobj(allchild(obj.figurehandle.sev),'type','uitoolbar');
            delete(default_toolbar);
            % th = findall(hObject,'tag','FigureToolBar');
            % toolbuttons = findall(th);
            th = uitoolbar('parent',obj.figurehandle.sev);
            drawnow();
            jToolbar = get(get(th,'JavaContainer'),'ComponentPeer');
            backgroundColor = get(jToolbar,'Background')*255;
            
            
            
            %% load EDF folder icon
            loadedf_img = imread(fullfile(obj.SETTINGS.rootpathname,'icons/folder-24x24.png'));
            
            resolution = size(loadedf_img);
            backgroundImg = ones(resolution);
            whitebackgroundImg = repmat(255,resolution);
            
            for k=1:resolution(3)
                backgroundImg(:,:,k) = repmat(backgroundColor(k),resolution(1),resolution(2));
            end
            
            blank_ind = loadedf_img==whitebackgroundImg;
            loadedf_img(blank_ind) = backgroundImg(blank_ind);
            obj.toolbarhandle.loadedf_push = uipushtool(th,'CData',loadedf_img,'separator','off',...
                'TooltipString','Load .EDF',...
                'HandleVisibility','off','clickedcallback',@obj.load_EDF_callback);
            
            %% Toolbox
            % toolbox_img = imread(fullfile(obj.sev.rootpathname,'icons/toolbox-16x16.png'));
            toolbox_img = imread(fullfile(obj.SETTINGS.rootpathname,'icons/toolbox-24x24.png'));
            blank_ind = xor(toolbox_img,backgroundImg);
            toolbox_img(blank_ind) = backgroundImg(blank_ind);
            obj.toolbarhandle.toolbox_push = uipushtool(th,'CData',toolbox_img,'separator','on',...
                'TooltipString','Event Toolbox',...
                'HandleVisibility','off','clickedcallback',@obj.eventtoolbox_callback);
            
            
            %% Filter toolbox
            % filter_img = imread(fullfile(obj.sev.rootpathname,'icons/filter-16x16.png'));
            filter_img = imread(fullfile(obj.SETTINGS.rootpathname,'icons/filter2-24x24.png'));
            % blank_ind = xor(filter_img,backgroundImg);
            % filter_img(blank_ind) = backgroundImg(blank_ind);
            
            obj.toolbarhandle.filter_toggle = uitoggletool(th,'CData',filter_img,'Separator','off',...
                'TooltipString','Filter Toolbox',...
                'HandleVisibility','off','clickedcallback',@obj.filter_channel_callback);
            
            
            % compare_img = imread('icons/balance-16x16.png');
            compare_img = imread(fullfile(obj.SETTINGS.rootpathname,'icons/balance-24x24.png'));
            blank_ind = xor(compare_img,backgroundImg);
            compare_img(blank_ind) = backgroundImg(blank_ind);
            obj.toolbarhandle.eventcomparisons_push = uipushtool(th,'CData',compare_img,'separator','off',...
                'TooltipString','Compare Events',...
                'HandleVisibility','off','clickedcallback',@obj.compare_events_callback);
            
            
            %% General Edit
            
            general_edit_on_img = imread(fullfile(obj.SETTINGS.rootpathname,'icons/hand-24x24.png'));
            general_edit_off_img = general_edit_on_img;
            
            resolution = size(general_edit_on_img);
            backgroundImg = ones(resolution);
            whitebackgroundImg = repmat(255,resolution);
            blackbackgroundImg = zeros(resolution);
            for k=1:resolution(3)
                backgroundImg(:,:,k) = repmat(backgroundColor(k),resolution(1),resolution(2));
            end
            
            % blank_ind = xor(general_edit_off_img,backgroundImg);
            blank_ind = general_edit_on_img==whitebackgroundImg;
            general_edit_off_img(blank_ind) = backgroundImg(blank_ind);
            general_edit_on_img(blank_ind) = blackbackgroundImg(blank_ind);
            
            userdata.on_img = general_edit_on_img;
            userdata.off_img = general_edit_off_img;
            obj.toolbarhandle.general_edit_toggle = uitoggletool(th,'CData',general_edit_off_img,'Separator','off',...
                'TooltipString','General Editing State On/Off','userdata',userdata,'tag','general_edit',...
                'HandleVisibility','off','clickedcallback',@obj.toggle_general_edit_toolbar);
            
            %% Marking toolbar icon
            %this icon has a black background by default
            marking_on_img = imread(fullfile(obj.SETTINGS.rootpathname,'icons/pencil-24x24.png'));
            marking_off_img = marking_on_img;
            
            resolution = size(marking_on_img);
            backgroundImg = ones(resolution);
            % whitebackgroundImg = repmat(255,resolution);
            blackbackgroundImg = zeros(resolution);
            
            for k=1:resolution(3)
                backgroundImg(:,:,k) = repmat(backgroundColor(k),resolution(1),resolution(2));
            end
            
            blank_ind = marking_on_img==blackbackgroundImg;
            marking_off_img(blank_ind) = backgroundImg(blank_ind);
            
            userdata.on_img = marking_on_img;
            userdata.off_img = marking_off_img;
            
            obj.toolbarhandle.marking_toggle = uitoggletool(th,'CData',marking_off_img,'Separator','off',...
                'TooltipString','Marking State Off','userdata',userdata,...
                'HandleVisibility','off','clickedcallback',@obj.toggle_marking_toolbar,'tag','marking');
            
            
            % Add undo dropdown list to the toolbar
            if ~isempty(jToolbar)
                obj.toolbarhandle.jCombo = javax.swing.JComboBox(obj.event_label_cell);
                obj.event_label = obj.event_label_cell{1};
                drawnow();
                obj.toolbarhandle.jCombo.setEnabled(false); %javaMethodEDT('setEnabled',jCombo,false);
                height = get(obj.toolbarhandle.jCombo.getPreferredSize,'height');
                width = get(obj.toolbarhandle.jCombo.getPreferredSize,'width');
                obj.toolbarhandle.jCombo.setMaximumSize(java.awt.Dimension(width,height));
                
                jToolbar(1).add(obj.toolbarhandle.jCombo);
                jToolbar(1).revalidate;
                jToolbar(1).repaint;
                
                set(obj.toolbarhandle.marking_toggle,'userdata',userdata);
                
                %establish the callbck
                msgid= 'MATLAB:hg:JavaSetHGProperty';
                warning('off',msgid);
                set(obj.toolbarhandle.jCombo, 'ActionPerformedCallback', @obj.combo_selectEventLabel_callback);
                warning('on',msgid);
                
            end
            guidata(obj.figurehandle.sev,handles);
        end
        
        %% menubar callbacks from SEV
        function load_EDF_callback(obj,hObject,eventdata)
            %SEV figure callback for choosing a source EDF file for loading
            
            try
                suggested_pathname = obj.SETTINGS.VIEW.src_edf_pathname;
                
                suggested_file = fullfile(suggested_pathname,obj.SETTINGS.VIEW.src_edf_filename);
                if(exist(suggested_file,'file'))
                    suggestion = suggested_file;
                else
                    suggestion = suggested_pathname;
                end
                
                [filename,pathname]=uigetfile({'*.EDF;*.edf','European Data Format';'*.REC;*.rec','European Data Format (.rec)'},'File Finder',...
                    suggestion);
                if(filename~=0)
                    obj.loadEDFintoSEV(filename,pathname);
                end;
                
            catch ME
                fprintf(1,'Problem loading file in %s\n',mfilename('fullpath'));
                showME(ME);
%                 recoverFromError(guidata(hObject),ME);
            end
        end
        
        function loadSTAGES(obj,stages_filename,num_epochs)
            global EVENT_CONTAINER;
            obj.sev_STAGES = loadSTAGES(stages_filename,num_epochs);            
            obj.sev_adjusted_STAGES = obj.sev_STAGES;            
            EVENT_CONTAINER.setStageStruct(obj.sev_STAGES);
        end
        
        function new_channels_loaded = loadEDFintoSEV(obj,EDF_filename,EDF_pathname)
            %function that loads a selected EDF and begins with asking for
            %which channels to load
            global CHANNELS_CONTAINER;
            obj.SETTINGS.VIEW.src_edf_filename = EDF_filename;
            obj.SETTINGS.VIEW.src_edf_pathname = EDF_pathname;
            obj.sev_loading_file_flag = true;
            obj.initializeView();
            
            new_channels_loaded = obj.load_EDFchannels_callback();
            if(new_channels_loaded)
                [~,name,~]= fileparts(obj.SETTINGS.VIEW.src_edf_filename);
                stages_filename = fullfile(obj.SETTINGS.VIEW.src_edf_pathname,strcat(name,'.STA'));
                obj.setDateTimeFromHDR();
                
                if(~exist(stages_filename,'file'))
                    fprintf(1,'Staging File %s not found!  Fictitious staging will be used.\r\n',stages_filename);
                end
                
                obj.loadSTAGES(stages_filename,obj.num_epochs);
                
                obj.display_samples = 1:obj.getSamplesPerEpoch(); 
                obj.setAxesResolution(); %calls refreshAxes()  %calls set epoch;

                CHANNELS_CONTAINER.align_channels_on_axes();
                CHANNELS_CONTAINER.setChannelSettings();
                
                enableFigureHandles(obj.figurehandle.sev);
                set(obj.texthandle.src_filename,'string',obj.SETTINGS.VIEW.src_edf_filename);
                obj.STATE.single_study_running = true;
            end
            obj.sev_loading_file_flag = false;
        end
        
        
        function new_channels_loaded_flag = load_EDFchannels_callback(obj,varargin)
%             new_channels_loaded_flag is true if new channels were
%             loaded/added and otherwise false
            global CHANNELS_CONTAINER
            EDF_filename = fullfile(obj.SETTINGS.VIEW.src_edf_pathname,obj.SETTINGS.VIEW.src_edf_filename);
            
            loadedIndices = CHANNELS_CONTAINER.getLoadedEDFIndices();
            obj.EDF_HDR = loadEDF(EDF_filename);
            %montage is a struct with the fields
            %   channels_selected (logical vector with true indices reflecting selected
            %       channels
            %   artifact_channel = the channel to use for calculating artifacts on
            %   primary_channel = the channel to use for various detection methods..
            montage=montage_dlg(obj.EDF_HDR.label,loadedIndices);
            
            if(~isempty(montage))
                selected_indices = find(montage.channels_selected);
                newIndicesToLoad = setdiff(selected_indices,loadedIndices);
                
                num_indicesToLoad = numel(newIndicesToLoad);
                if(num_indicesToLoad>0)
                    obj.showBusy('Loading EDF channels');
                    
                    CHANNELS_CONTAINER.loadEDFchannels(EDF_filename,newIndicesToLoad);
                    obj.showReady();
                    
                    %position others where they are best liked based on past
                    %views...
                    
                    if(~obj.sev_loading_file_flag)
                        CHANNELS_CONTAINER.setCurrentSamples(obj.display_samples);
                        CHANNELS_CONTAINER.align_channels_on_axes();
                        CHANNELS_CONTAINER.setChannelSettings();
                    end;
                end
            end 
            new_channels_loaded_flag =~isempty(montage)&&num_indicesToLoad>0;
        end
        
                
        function setDateTimeFromHDR(obj,HDR)
            %setup values based on EDF HDR passed in
            if(nargin==1)
                HDR = obj.EDF_HDR;
            end
            obj.startDateTime = HDR.T0;
            
            %this causes problems with alternatively sampled data
            %WORKSPACE.study_duration_in_samples = numel(CHANNELS_CONTAINER.cell_of_channels{1}.raw_data);
            
            
            %This caused problems when channels are of different sampling rates or durations.  Everything should be converted to 100 Hz, but still there were some problems in APOE.  Convert to time to adjust.
            obj.study_duration_in_seconds = HDR.duration_sec;
            obj.study_duration_in_samples = obj.study_duration_in_seconds*obj.SETTINGS.VIEW.samplerate;
            
            seconds_per_epoch = obj.getSecondsPerEpoch();
            
            if(seconds_per_epoch<=0)
                obj.num_epochs = 1;
            else
                obj.num_epochs = ceil(HDR.duration_sec/seconds_per_epoch); %floor(HDR.duration_sec/seconds_per_epoch);
            end
        end
        
        function initializeView(obj)
            %initializes the axes and makes sure everything is good to go for a first
            %time use or when loading a new file or recovering from an error
            global CHANNELS_CONTAINER;
            global EVENT_CONTAINER;
            full_detection_inf_filename = fullfile(obj.SETTINGS.rootpathname,obj.SETTINGS.VIEW.detection_path,obj.SETTINGS.VIEW.detection_inf_file);
            EVENT_CONTAINER = CLASS_events_container(obj.figurehandle.sev,obj.axeshandle.main,obj.SETTINGS.VIEW.samplerate);
            EVENT_CONTAINER.detection_path = obj.SETTINGS.VIEW.detection_path;
            EVENT_CONTAINER.detection_inf_file = full_detection_inf_filename;
            
            sevDefaults = obj.SETTINGS.VIEW;
            sevDefaults.detection_inf_filename = full_detection_inf_filename;
            
            CHANNELS_CONTAINER = CLASS_channels_container(obj.figurehandle.sev,obj.axeshandle.main,obj.axeshandle.utility,sevDefaults);
            CHANNELS_CONTAINER.loadSettings(obj.SETTINGS.VIEW.channelsettings_file);
            
            EVENT_CONTAINER.CHANNELS_CONTAINER = CHANNELS_CONTAINER;
            disableFigureHandles(obj.figurehandle.sev);
            
            set(0,'showhiddenhandles','on');
            
            cla(obj.axeshandle.main);
            cla(obj.axeshandle.timeline);
            cla(obj.axeshandle.utility);
            
            obj.texthandle.current_stage = text('string','','parent',obj.axeshandle.main,'color',[1 1 1]*.9,'fontsize',42);
            obj.texthandle.previous_stage = text('string','','parent',obj.axeshandle.main,'color',[1 1 1]*.9,'fontsize',35);
            obj.texthandle.next_stage = text('string','','parent',obj.axeshandle.main,'color',[1 1 1]*.9,'fontsize',35);
            
            cf = get(0,'children');
            for k=1:numel(cf)
                if(cf(k)==obj.figurehandle.sev)
                    set(0,'currentfigure',cf(k));
                else
                    delete(cf(k)); %removes other children aside from this one
                end
            end;
            
            set(0,'showhiddenhandles','off');
            
            drawnow;
            
            %initialize axes
            set(obj.axeshandle.main,'Units','normalized',... %normalized allows it to resize automatically
                'drawmode','normal',... %fast does not allow alpha blending...
                'xgrid','on','ygrid','off',...
                'xminortick','on',...
                'xlimmode','manual',...
                'xtickmode','manual',...
                'xticklabelmode','manual',...
                'xtick',[],...
                'ytickmode','manual',...
                'ytick',[],...
                'nextplot','replacechildren','box','on',...
                'xlim',obj.sev_mainaxes_xlim,...
                'ylim',obj.sev_mainaxes_ylim,...  %avoid annoying resolution changes on first load
                'ydir',obj.SETTINGS.VIEW.yDir);
            
            set(obj.axeshandle.timeline,'Units','normalized',... %normalized allows it to resize automatically
                'xgrid','off','ygrid','off',...
                'xminortick','off',...
                'xlimmode','manual',...
                'xtickmode','manual',...
                'xticklabelmode','manual',...
                'xtick',[],...
                'ytickmode','manual',...
                'ytick',[],...
                'nextplot','replacechildren','box','on');

            seconds_per_epoch = obj.getSecondsPerEpoch();
            if(seconds_per_epoch == obj.SETTINGS.VIEW.standard_epoch_sec)
                %                 set(obj.axeshandle.main,'dataaspectratiomode','manual','d
                %                 ataaspectratio',[30 12 1]);
                set(obj.axeshandle.main,'plotboxaspectratiomode','manual','plotboxaspectratio',[30 12 1]);
            else
                %                     set(obj.axeshandle.main,'dataaspectratiomode','auto');
                set(obj.axeshandle.main,'plotboxaspectratiomode','auto');
            end
                

            
            set(obj.axeshandle.utility,'Units','normalized',... %normalized allows it to resize automatically
                'xgrid','off','ygrid','off',...
                'xminortick','off',...
                'ylimmode','auto',...
                'xlimmode','manual',...
                'xtickmode','manual',...
                'ytickmode','manual',...
                'xtick',[],...
                'ytick',[],...
                'nextplot','replacechildren','box','on');
            
            %show the PSD, ROC, events, etc.
            set(obj.axeshandle.utility,...
                'xtickmode','auto',...
                'ytickmode','auto',...
                'xtickmode','auto',...
                'ytickmode','auto',...
                'xlim',[0 obj.SETTINGS.VIEW.samplerate/2]);            
            
            if(~isfield(obj.linehandle,'x_minorgrid')||isempty(obj.linehandle.x_minorgrid)||~ishandle(obj.linehandle.x_minorgrid))
                obj.linehandle.x_minorgrid = line('xdata',[],'ydata',[],'parent',obj.axeshandle.main,'color',[0.8 0.8 0.8],'linewidth',0.5,'linestyle',':','hittest','off','visible','on');
            end
            
            %turn on the appropriate menu items still for initial use before any EDF's
            %are loaded
            handles = guidata(obj.figurehandle.sev);
            
            set(handles.menu_file_createEDF,'enable','on');
            set(handles.menu_file_load_EDF,'enable','on');
            set(handles.menu_file,'enable','on');
            set(handles.menu_file_export,'enable','on');
            set(handles.menu_file_import,'enable','on');
            
            set(handles.menu_tools,'enable','on');
            set(handles.menu_tools_roc_directory,'enable','on');
            
            set(handles.menu_settings,'enable','on');
            set(handles.menu_settings_power,'enable','on');
            set(handles.menu_settings_power_psd,'enable','on');
            set(handles.menu_settings_power_music,'enable','on');
%             set(handles.menu_settings_roc,'enable','on'); %wait until
%             there are at least two events to examine.
            set(handles.menu_settings_classifiers,'enable','on');
            set(handles.menu_settings_defaults,'enable','on');            
            
            set(handles.menu_batch_run,'enable','on');
            set(handles.menu_batch,'enable','on');
            
            set(handles.menu_help,'enable','on');
            set(handles.menu_help_defaults,'enable','on');
            set(handles.menu_help_restart,'enable','on');
            
            set(obj.toolbarhandle.loadedf_push,'enable','on');
            set(handles.radio_psd,'value',1);
            
            obj.restore_state();
        end
        function setAxesXlim(obj)  %called when there is a change to the xlimit to be displayed
            obj.sev_mainaxes_xlim = [obj.display_samples(1),obj.display_samples(end)];
            obj.refreshAxes();
            %axes1 - update
%             
%             %axes2
%             pos = get(obj.axeshandle.timeline,'position');
%             
%             startX = pos(1)+obj.current_epoch/(obj.num_epochs+1)*pos(3);
%             
%             %draw annotation/position line along the lower axes
%             if(isfield(obj.annotationhandle,'timeline')&&ishandle(obj.annotationhandle.timeline))
%                 set(obj.annotationhandle.timeline,'x',[startX startX],'y',[pos(2) pos(2)+pos(4)]);
%             else
%                 obj.annotationhandle.timeline = annotation(obj.figurehandle.sev,'line',[startX, startX], [pos(2) pos(2)+pos(4)],'hittest','off');
%             end;
%             
%             %axes3
            
        end
        
        function setEpoch(obj,new_epoch)  
            
            if(new_epoch>0 && new_epoch <=obj.num_epochs) %&& new_epoch~=obj.current_epoch
                obj.current_epoch = new_epoch;
                if(ishandle(obj.edit_epoch_h))
                    set(obj.edit_epoch_h,'string',num2str(new_epoch));
                end

                if(obj.getSecondsPerEpoch() > 0 )
                    
                    obj.display_samples = (new_epoch-1)*obj.getSamplesPerEpoch()+1:new_epoch*obj.getSamplesPerEpoch();                    
                end
            end
            
            obj.setAxesXlim();
            
        end
        
        function setEditEpochHandle(obj,edit_epoch_handle)
            if(ishandle(edit_epoch_handle))                
                obj.edit_epoch_h = edit_epoch_handle;
                set(obj.edit_epoch_h,'callback',@obj.edit_epoch_callback);
            end
        end
        
        function edit_epoch_callback(obj,hObject, eventdata)
            % Hints: get(hObject,'String') returns contents of edit_cur_epoch as text
            %        str2double(get(hObject,'String')) returns contents of edit_cur_epoch as a double
            epoch = str2double(get(hObject,'String'));
            
            if(epoch>obj.num_epochs || epoch<1)
                set(hObject,'string',num2str(obj.current_epoch));
            else
                obj.setEpoch(epoch);
            end;
        end
        function setEpochResolutionHandle(obj,time_scale_menu_h_in)
            %time_scale_menu_h_in is popup menu for epoch scales
            if(ishandle(time_scale_menu_h_in))
                
                %initialize controls
                %establish various time views in the SEV.
                obj.epoch_resolution.sec = [1 2 4 5 10 15 30];% [30 20 10 4 2 1];
                obj.epoch_resolution.min = [1 2 5 10 15 30];
                obj.epoch_resolution.hr = [1 2];
                obj.epoch_resolution.stage = 0:5;
                obj.epoch_resolution.all_night = 1;
                
                fields = fieldnames(obj.epoch_resolution);
                num_choices = 0;
                for f=1:numel(fields)
                    num_choices = num_choices+numel(obj.epoch_resolution.(fields{f}));
                end
                epoch_selection.units = '';
                epoch_selection.value_sec = [];
                epoch_selection.stage = [];
                epoch_selection = repmat(epoch_selection,num_choices,1);
                epoch_resolution_string = cell(num_choices,1);
                
                cur_index = 0;
                for f=1:numel(fields)
                    fname = fields{f};
                    if(strcmpi(fname,'all_night'))
                        cur_index = cur_index+1;
                        epoch_resolution_string{cur_index} = 'Entire Study';                    
                        epoch_selection(cur_index).units = fname;                        
                        epoch_selection(cur_index).value_sec = -1;
                    else
                        for k=1:numel(obj.epoch_resolution.(fname))
                            cur_index = cur_index+1;
                            
                            cur_value = obj.epoch_resolution.(fname)(k);
                            epoch_selection(cur_index).units = fname;                            

                            if(strcmpi(fname,'stage'))
                                epoch_selection(cur_index).stage = cur_value;
                                epoch_selection(cur_index).value_sec = -1;
                                epoch_resolution_string{cur_index} = sprintf('STAGE - %u',cur_value);
                            else
                                if(strcmpi(fname,'sec'))
                                    epoch_selection(cur_index).value_sec = cur_value;
                                elseif(strcmpi(fname,'min'))
                                    epoch_selection(cur_index).value_sec = cur_value*60;
                                elseif(strcmpi(fname,'hr'))
                                    epoch_selection(cur_index).value_sec = cur_value*3600;
                                end
                                epoch_resolution_string{cur_index} = sprintf('%u %s',cur_value,fname);
                            end
                        end
                    end
                end
                obj.epoch_resolution.selection_choices = epoch_selection;
                obj.epoch_resolution.current_selection_index = find(obj.epoch_resolution.sec==obj.SETTINGS.VIEW.standard_epoch_sec);
                
                
                obj.epoch_resolution.menu_h = time_scale_menu_h_in;
                set(obj.epoch_resolution.menu_h,'string',epoch_resolution_string,'value',obj.epoch_resolution.current_selection_index,'callback',@obj.epoch_resolution_callback);
            end
        end
        
        function refreshAxes(obj)
            obj.showBusy('Updating Plot');
            handles = guidata(obj.figurehandle.sev);
            
            obj.updateMainAxes();
            
            obj.updateTimelineAxes();
            
            %more of an initializeAxes type thing...
            
            obj.updateUtilityAxes();
            
            obj.showReady();
            set(handles.text_status,'string','');
        end
        
        function showBusy(obj,status_label)
            set(obj.figurehandle.sev,'pointer','watch');
            if(nargin>1)
                set(obj.texthandle.status,'string',status_label);
            end
            drawnow();
        end  
        
        function showReady(obj)
            set(obj.figurehandle.sev,'pointer','arrow');
            set(obj.texthandle.status,'string','');
            drawnow();
        end
        
        function updateMainAxes(obj)
            %limits and lines are set/drawn
            global CHANNELS_CONTAINER;
            
            set([obj.texthandle.previous_stage;obj.texthandle.current_stage;...
                obj.texthandle.next_stage],'string','');

            CHANNELS_CONTAINER.setCurrentSamples(obj.display_samples);
            
            samples_per_epoch = obj.getSamplesPerEpoch();
            
            if(samples_per_epoch>0)
                %handle outputting the current and next sleep stages as text onto the axes.
                previous_stage = obj.getStageAtSamplePt(obj.display_samples(1)-1);
                next_stage = obj.getStageAtSamplePt(obj.display_samples(end)+1);
                current_stage = obj.getStageAtSamplePt(obj.display_samples(1));
                set(obj.texthandle.current_stage,'position',[obj.sev_mainaxes_xlim(1)+samples_per_epoch*9/20,-240,0],'string',num2str(current_stage),'parent',obj.axeshandle.main,'color',[1 1 1]*.7,'fontsize',42);
                set(obj.texthandle.previous_stage,'position',[obj.sev_mainaxes_xlim(1)+samples_per_epoch/20,-240,0],'string',['< ', num2str(previous_stage)],'parent',obj.axeshandle.main,'color',[1 1 1]*.8,'fontsize',35);
                set(obj.texthandle.next_stage,'position',[obj.sev_mainaxes_xlim(1)+samples_per_epoch*9/10,-240,0],'string',[num2str(next_stage) ' >'],'parent',obj.axeshandle.main,'color',[1 1 1]*.8,'fontsize',35);
            end;
            
            x_ticks = obj.sev_mainaxes_xlim(1):samples_per_epoch/6:obj.sev_mainaxes_xlim(end);
            set(obj.axeshandle.main,'xlim',obj.sev_mainaxes_xlim,'ylim',obj.sev_mainaxes_ylim,...
                'xticklabel',obj.getTimestampAtSamplePt(x_ticks),'xtick',x_ticks);
            
            if(strcmp(get(obj.linehandle.x_minorgrid,'visible'),'on'))
                obj.draw_x_minorgrid();
            end;

        end
        
        function updateTimelineAxes(obj)
            %axes2 is for hypnogram (sleep stages) and detected events
            
            global EVENT_CONTAINER;
            

            cla(obj.axeshandle.timeline);  %do this so I don't have to have transition line handles and sleep stage line handles, etc.
            
                        %show hypnogram and such
            xticks = linspace(1,obj.num_epochs,min(obj.num_epochs,5));
            
            set(obj.axeshandle.timeline,...
                'xlim',[0 obj.num_epochs+1],... %add a buffer of one to each side of the x limit/axis
                'ylim',[0 10],...
                'xtick',xticks,...
                'xticklabel',obj.getTimestampAtSamplePt(xticks*obj.getSamplesPerEpoch(),'HH:MM'));

            ylim = get(obj.axeshandle.timeline,'ylim');
            events_to_plot = find(EVENT_CONTAINER.event_indices_to_plot);
            
            num_events = sum(events_to_plot>0);
            
            axes_buffer = 0.05;
            if(num_events==0)
                upper_portion_height_percent = axes_buffer;
                fontsize=10;
            else
                upper_portion_height_percent = min(0.5+axes_buffer,0.2*num_events);
                fontsize = 7;
            end;
            
            lower_portion_height_percent = 1-upper_portion_height_percent;
            y_delta = abs(diff(ylim))/(num_events+1)*upper_portion_height_percent; %just want the top part - the +1 is to keep it in the range a little above and below the portion set aside for it
            
            ylim(2) = ylim(2)-y_delta/2;
            for k = 1:num_events
                EVENT_CONTAINER.cell_of_events{events_to_plot(k)}.draw_all(obj.axeshandle.timeline,ylim(2)-k*y_delta,y_delta,obj.sev_adjusted_STAGES);
            end;
            
            y_max = 10*lower_portion_height_percent;
            adjustedStageLine = obj.sev_adjusted_STAGES.line;
            
            
            %expect stages to be 0, 1, 2, 3, 4, 5, 6, 7
            possible_stages = [7,6,5,4,3,2,1,0];
            tick = linspace(0,y_max,numel(possible_stages));
            
            for k=1:numel(tick)
%                 adjustedStageLine(obj.sev_STAGES.line==possible_stages(k))=tick(k);
                adjustedStageLine(obj.sev_adjusted_STAGES.line==possible_stages(k))=tick(k);
            end
            cycle_y = tick(2); %put the cycle label where stage 6 might be shown
            tick(2) = []; %don't really want to show stage 6 as a label
            set(obj.axeshandle.timeline,...
                'ytick',tick,...
                'yticklabel','7|5|4|3|2|1|0','fontsize',fontsize);
            
            
            %reverse the ordering so that stage 0 is at the top
            x = 0:obj.num_epochs-1;
            x = [x;x+1;nan(1,obj.num_epochs)];
            % y = [STAGES.line'; STAGES.line'; nan(1,num_epochs)]; %want three rows
            % y = y_max-(y(:)+1)*y_delta-axes_buffer;
            
            y = [adjustedStageLine'; adjustedStageLine'; nan(1,obj.num_epochs)]; %want three rows
            line('xdata',x(:),'ydata',y(:),'color',[1 1 1]*.4,'linestyle','-','parent',obj.axeshandle.timeline,'linewidth',1.5,'hittest','off');
            
            %update the vertical lines with sleep cycle information
            adjustedStageCycles = obj.sev_adjusted_STAGES.cycles;
            transitions = [0;find(diff(adjustedStageCycles)==1);numel(adjustedStageCycles)];
            
            cycle_z = -0.5; %put slightly back
            for k=3:numel(transitions)
                curCycle = k-2;
                cycle_x = floor(mean(transitions(k-1:k)));
                text('string',num2str(curCycle),'parent',obj.axeshandle.timeline,'color',[1 1 1]*.5,'fontsize',fontsize,'position',[cycle_x,cycle_y,cycle_z]);
                %     if(k<numel(transitions)) %don't draw the very last transition
                line('xdata',[transitions(k-1),transitions(k-1)],'ydata',ylim,'linestyle',':','parent',obj.axeshandle.timeline,'linewidth',1,'hittest','off','color',[1 1 1]*0.5);
                %     end
            end
            pos = get(obj.axeshandle.timeline,'position');
            
            startX = pos(1)+obj.current_epoch/(obj.num_epochs+1)*pos(3);
            
            %draw annotation/position line along the lower axes
            if(isfield(obj.annotationhandle,'timeline')&&ishandle(obj.annotationhandle.timeline))
                set(obj.annotationhandle.timeline,'x',[startX startX],'y',[pos(2) pos(2)+pos(4)]);
            else
                obj.annotationhandle.timeline = annotation(obj.figurehandle.sev,'line',[startX, startX], [pos(2) pos(2)+pos(4)],'hittest','off');
            end;  
        end
        
        function updateUtilityAxes(obj)
            global CHANNELS_CONTAINER;
            global EVENT_CONTAINER;
            handles = guidata(obj.figurehandle.sev);
            cur_radio = get(handles.bgroup_utility,'SelectedObject');
            switch get(cur_radio,'string')
                case 'PSD'
                    if(~isempty(CHANNELS_CONTAINER))
                        CHANNELS_CONTAINER.showPSD(obj.SETTINGS.PSD,obj.axeshandle.utility);
                    end
                case 'ROC'
                    if(EVENT_CONTAINER.roc_axes_needs_update)
                        if(~isempty(EVENT_CONTAINER.roc_truth_ind)&&~isempty(EVENT_CONTAINER.roc_estimate_ind))
                            comparisonStruct = EVENT_CONTAINER.getComparisonStruct();
                            Q = comparisonStruct.confusion_matrix_count./repmat(sum(comparisonStruct.confusion_matrix_count,2),1,4);
                            cla(obj.axeshandle.utility);
                            estimate_suffix = EVENT_CONTAINER.get_event_labels();
                            estimate_suffix = char(estimate_suffix{EVENT_CONTAINER.roc_estimate_ind});
                            drawROC(Q,comparisonStruct.FPR,comparisonStruct.TPR,obj.axeshandle.utility,estimate_suffix);
                            fprintf(1,'TPR=%0.2f\tFPR=%0.2f\tCohenKappa=%0.3f\tF=%0.3f\tPPV=%0.3f\tNPV=%0.3f\n',comparisonStruct.TPR*100,comparisonStruct.FPR*100,comparisonStruct.CohensKappa,comparisonStruct.f_measure,comparisonStruct.PPV,comparisonStruct.NPV);
                        end
                        EVENT_CONTAINER.roc_axes_needs_update = false;
                    end
                case 'EvtStats'
                    if(EVENT_CONTAINER.summary_stats_axes_needs_update)
                        if(EVENT_CONTAINER.num_events>0)
                            EVENT_CONTAINER.calculate_summary_stats();
                            if(~isempty(EVENT_CONTAINER.summary_stats))
                                EVENT_CONTAINER.draw_summary_stats(obj.axeshandle.utility);
                            end
                        end
                        EVENT_CONTAINER.summary_stats_axes_needs_update = false;
                    end
                otherwise
                    warndlg('unknown selection');
            end
        end
        
        function timeStrCell = getTimestampAtSamplePt(obj,sample_points,fmt)
            
            if(nargin<3)
                fmt = 'HH:MM:SS';
            end
            datetime = repmat(obj.startDateTime,numel(sample_points),1);
            datetime(:,end) = datetime(:,end)+sample_points(:)/obj.SETTINGS.VIEW.samplerate;
            
            timeStrCell = datestr(datenum(datetime),fmt);
            
        end
        
        function epoch =  getEpochAtSamplePt(obj,x)
            %returns the epoch that x occurs in based on current select
            %epoch scale reoslution
            epoch = obj.sample2epoch(x, obj.getSecondsPerEpoch());
        end
        
        function epoch =  getSEVEpochAtSamplePt(obj,x)
            %returns the epoch that x occurs in based on the standard epoch
            %length used in the sev (e.g. 30 seconds per epoch 
            epoch = obj.sample2epoch(x, obj.SETTINGS.VIEW.standard_epoch_sec);
        end
        
        function stage = getCurrentStage(obj)
            %returns the stage of teh currently displayed epoch
            stage = obj.getStageAtSamplePt(obj.display_samples(1));
        end
       
        function epoch = getCurrentEpoch(obj)
            %returns the currently displayed epoch in terms of elapsed
            %standard epochs (e.g. 30 s epoch sizes)
            epoch = sample2epoch(obj.display_samples(1));
        end
        function stage = getStageAtEpoch(obj, epoch)
            %returns the stage that x occurs in based on the standard epoch
            %length used in the sev (e.g. 30 seconds per epoch
            if(epoch<=0 || epoch> obj.num_epochs)
                stage = [];
            else
                stage = obj.sev_adjusted_STAGES.line(epoch);
            end
        end
        
        function stage = getStageAtSamplePt(obj, x)
            stage = obj.getStageAtEpoch(obj.getEpochAtSamplePt(x));
        end
        
        function epoch = sample2epoch(obj,index,epoch_dur_sec,sampleRate)
            % function epoch = sample2epoch(index,epoch_dur_sec,sampleRate)
            %returns the epoch for the given sample index of a signal that uses an
            %epoch size in seconds of epoch_dur_sec and that was sampled at a sample
            %rate of sampleRate - works with vectors of values as well.
            %[DEFAULT] = [VALUE]
            %[epoch_dur_sec] = [30]
            %[sampleRate] = [100]
            if(nargin<4)
                sampleRate = obj.SETTINGS.VIEW.samplerate;
            end
            if(nargin<3)
                epoch_dur_sec = obj.SETTINGS.VIEW.standard_epoch_sec;
            end;
            epoch = ceil(index/(epoch_dur_sec*sampleRate));
            
        end
        
        function epoch_resolution_callback(obj,hObject,~)            
            obj.epoch_resolution.current_selection_index = get(hObject,'value');             
            obj.setAxesResolution();
        end
        
        function seconds_per_epoch = getSecondsPerEpoch(obj)
            seconds_per_epoch = obj.epoch_resolution.selection_choices(obj.epoch_resolution.current_selection_index).value_sec;
        end
        function units_for_epoch = getEpochUnits(obj)
            units_for_epoch = obj.epoch_resolution.selection_choices(obj.epoch_resolution.current_selection_index).units;
        end
        function samples_per_epoch = getSamplesPerEpoch(obj)
            samples_per_epoch  = obj.getSecondsPerEpoch()*obj.SETTINGS.VIEW.samplerate;
        end
        
        function setAxesResolution(obj)
            global CHANNELS_CONTAINER;
            seconds_per_epoch = obj.getSecondsPerEpoch();
            if(seconds_per_epoch == obj.SETTINGS.VIEW.standard_epoch_sec)
                %                     set(obj.axeshandle.main,'dataaspectratiomode','manual','dataaspectratio',[30 12 1]);
                set(obj.axeshandle.main,'plotboxaspectratiomode','manual','plotboxaspectratio',[30 12 1]);
            else
                %                     set(obj.axeshandle.main,'dataaspectratiomode','auto');
                set(obj.axeshandle.main,'plotboxaspectratiomode','auto');
            end;

%             
%             if(seconds_per_epoch == obj.SETTINGS.VIEW.standard_epoch_sec)
%                 set(obj.axeshandle.main,'dataaspectratiomode','manual','dataaspectratio',[30 12 1]);
%             else
%                 set(obj.axeshandle.main,'dataaspectratiomode','auto');
%             end;

            if(seconds_per_epoch<0)
                set(obj.edit_epoch_h,'enable','off');
                epoch_units = obj.getEpochUnits();                              
                if(strcmpi(epoch_units,'stage'))
                    stage2show = obj.epoch_resolution.selection_choices(obj.epoch_resolution.current_selection_index).stage;
                    stage_epoch_ind = find(obj.sev_STAGES.line==stage2show);
                    epochs2samples = obj.SETTINGS.VIEW.samplerate*obj.SETTINGS.VIEW.standard_epoch_sec;
                    if(isempty(stage_epoch_ind))
                        warndlg('This stage does not exist for the current study - just showing first epoch');
                        obj.display_samples = 1:epochs2samples;
                        new_epoch = 1;
                    else
                        num_stage_epochs = numel(stage_epoch_ind);
                        obj.display_samples = zeros(num_stage_epochs,epochs2samples);
                        
                        for n=1:num_stage_epochs
                            obj.display_samples(n,:)=(stage_epoch_ind(n)-1)*epochs2samples+1:(stage_epoch_ind(n))*epochs2samples;
                        end;
                        obj.display_samples = reshape(obj.display_samples',1,[]);
                        new_epoch = stage2show;
                    end
                elseif(strcmpi(epoch_units,'all_night'))
                    obj.display_samples = 1:obj.study_duration_in_samples;
                    new_epoch = -1;
                end

            else
                set(obj.edit_epoch_h,'enable','on');                            
                obj.num_epochs = ceil(obj.study_duration_in_seconds/seconds_per_epoch);
                new_epoch = sample2epoch(obj.sev_mainaxes_xlim(1),seconds_per_epoch,obj.SETTINGS.VIEW.samplerate);
            end
            CHANNELS_CONTAINER.setDrawEvents();  %inform the channel container to notify all channels that their events need to be redrawn (to reflect change of axes);
            
            obj.sev_adjusted_STAGES.line = obj.sev_STAGES.line(round(linspace(1,numel(obj.sev_STAGES.line),obj.num_epochs)));
            obj.sev_adjusted_STAGES.cycles = obj.sev_STAGES.cycles(round(linspace(1,numel(obj.sev_STAGES.cycles),obj.num_epochs)));
            obj.setEpoch(new_epoch);
        end;        
                
        function obj = combo_selectEventLabel_callback(obj,hObject,eventdata)
            %             hObject is the jCombo box
            obj.event_label = get(hObject,'SelectedItem'); %hObject.getSelectedItem();            
        end
        
        function toggle_toolbar(obj,tag,state)
            if(strcmpi(tag,'marking'))
                toolbar_h = obj.toolbarhandle.marking_toggle;
                set(toolbar_h,'state',state);
                obj.toggle_marking_toolbar(toolbar_h,[]);
            elseif(strcmpi(tag,'general'))
                
            end
        end
        function toggle_marking_toolbar(obj,hObject,eventdata)
            onoff_state = get(hObject,'state');
            
            toolbar_data = get(hObject,'userdata');
            if(strcmpi(onoff_state,'on'))                
                obj.marking_state = 'marking';                
                obj.toolbarhandle.jCombo.setEnabled(true);
                
                set(obj.toolbarhandle.general_edit_toggle,'state','off');
                general_edit_data = get(obj.toolbarhandle.general_edit_toggle,'userdata');
                set(obj.toolbarhandle.general_edit_toggle,'cdata',general_edit_data.off_img,'state','off','tooltipstring','General Editing: Off');
            else
                obj.toolbarhandle.jCombo.setEnabled(false);
                obj.marking_state = 'off';
            end
            set(obj.toolbarhandle.marking_toggle,'cdata',toolbar_data.([onoff_state,'_img']),'state',onoff_state,'tooltipstring',sprintf('%s: %s',strrep(get(hObject,'tag'),'_',''),onoff_state));
        end
       
        function toggle_general_edit_toolbar(obj,hObject,eventdata)
            onoff_state = get(hObject,'state');
            toolbar_data = get(hObject,'userdata');
            if(strcmpi(onoff_state,'on'))                
                obj.marking_state = 'general';                
                obj.toolbarhandle.jCombo.setEnabled(false);
                set(obj.toolbarhandle.marking_toggle,'state','off');
                marking_data = get(obj.toolbarhandle.marking_toggle,'userdata');
                set(obj.toolbarhandle.marking_toggle,'cdata',marking_data.off_img,'state','off','tooltipstring','Marking: Off');
            else
                obj.marking_state = 'off';
            end
            set(obj.toolbarhandle.general_edit_toggle,'cdata',toolbar_data.([onoff_state,'_img']),'state',onoff_state,'tooltipstring',sprintf('General Edit: %s',onoff_state));
        end
        
        function obj = restore_state(obj)
            obj.clear_handles();
            
            set(obj.figurehandle.sev,'pointer','arrow');
            
            set(obj.figurehandle.sev,'WindowButtonMotionFcn',[]);
            set(obj.figurehandle.sev,'WindowScrollWheelFcn',[]);
            
            set(obj.figurehandle.sev,'WindowButtonDownFcn',@obj.sev_main_fig_WindowButtonDownFcn);
            set(obj.figurehandle.sev,'WindowButtonUpFcn',@obj.sev_main_fig_WindowButtonUpFcn);
            
            obj.marking_state = 'off';
        end
        
        function obj = clear_handles(obj)
            if(ishghandle(obj.hg_group))
                delete(obj.hg_group);
            end;
            if(ishandle(obj.drag_right_h))
                delete(obj.drag_right_h);
            end
            if(ishandle(obj.drag_left_h))
                delete(obj.drag_left_h);
            end
            obj.drag_right_h = [];
            obj.drag_left_h = [];
            
            obj.hg_group = [];

            if(~isempty(obj.current_linehandle))                
                if(ishandle(obj.current_linehandle))
                    set(obj.current_linehandle,'selected','off');
                end;
                obj.current_linehandle = [];
            end;
            obj.showReady();
        end

        function sev_main_fig_WindowButtonUpFcn(obj,hObject,eventdata)            
            obj.sev_button_up();
        end
        
        function sev_main_fig_WindowButtonDownFcn(obj,hObject,eventdata)
            obj.sev_button_down();            
        end
        
        function sev_button_up(obj)                        
            selected_obj = get(obj.figurehandle.sev,'CurrentObject');
            
            if ~isempty(selected_obj)
                if(selected_obj==obj.axeshandle.timeline)                    
                    if(obj.getSecondsPerEpoch()>0)
                        pos = round(get(obj.axeshandle.timeline,'currentpoint'));
                        clicked_epoch = pos(1);
                        obj.setEpoch(clicked_epoch);
                    end;
                end;
            end;
        end
        
        function obj = sev_button_down(obj)
            if(strcmpi(obj.marking_state,'off')) %don't want to reset the state if we are marking events
                if(~isempty(obj.current_linehandle))
                    obj.restore_state();
                end;
            else
                if(ishghandle(obj.hg_group))
                    if(~any(gco==allchild(obj.hg_group))) %did not click on a member of the object being drawn...
                        obj.clear_handles();
                    end;
                end;
            end;
            if(~isempty(obj.current_linehandle)&&ishandle(obj.current_linehandle) && strcmpi(get(obj.current_linehandle,'selected'),'on'))
                set(obj.current_linehandle,'selected','off');
            end
        end

        
        function setLinehandle(obj, line_h)
            obj.clear_handles();
            obj.current_linehandle = line_h;
            set(obj.current_linehandle,'selected','on');
        end
        

        function status = isActive(obj)
            status = ~strcmpi(obj.marking_state,'off');
        end
        
        function obj = set_channel_index(obj,channelIndex,channel_linehandle)
            %   previously implemented in SEV's...          line_buttonDownFcn(hObject, eventdata)
            global EVENT_CONTAINER;
            global CHANNELS_CONTAINER;
            
            obj.clear_handles();
            obj.current_linehandle = channel_linehandle;
            obj.class_channel_index = channelIndex;
            obj.channel_label = CHANNELS_CONTAINER.getChannelName(obj.class_channel_index);
            obj.event_index = EVENT_CONTAINER.eventExists(obj.event_label,obj.class_channel_index);
            EVENT_CONTAINER.cur_event_index = obj.event_index;
            obj.start_stop_matrix_index = 0;
        end

        function indices = getSelectedIndices(obj)
            if(ishghandle(obj.hg_group))
                rectangle_h = findobj(obj.hg_group,'tag','rectangle');
                rec_pos = floor(get(rectangle_h,'position'));
                start = rec_pos(1);
                stop = start+rec_pos(3);
                indices = start:stop;
            else
                indices = [];
            end
        end
        function data = getSelectedChannelData(obj)
            %returns the plotted data for the channel selection made by the
            %user as highlighed with a rectangular patch
            global CHANNELS_CONTAINER;
            ROI = obj.getSelectedIndices();
            if(isempty(ROI))
                data = [];
            else
                data = CHANNELS_CONTAINER.getData(obj.class_channel_index,ROI);
            end
        end
        function [varargout] = copyChannelData2clipboard(obj)
            global CHANNELS_CONTAINER;
            if(ishghandle(obj.hg_group))
                rectangle_h = findobj(obj.hg_group,'tag','rectangle');
                rec_pos = floor(get(rectangle_h,'position'));
                start = rec_pos(1);
                stop = start+rec_pos(3);
                channel_index = obj.class_channel_index;
                ROI = start:stop;
                data = CHANNELS_CONTAINER.copy2clipboard(channel_index,ROI);
                if(nargout==1)
                    varargout{1}=data;
                end
            else
                varargout{1}=[];
            end;
        end
    

        function obj = startMarking(obj,editing_flag)
            %called when a user begins to mark a line...see line_buttonDownFcn for
            %calling function
            global EVENT_CONTAINER;
            global CHANNELS_CONTAINER;
            y = get( obj.current_linehandle,'ydata' );
            obj.class_channel_index = get(obj.current_linehandle,'userdata');
            obj.channel_label = CHANNELS_CONTAINER.getChannelName(obj.class_channel_index);
            
            min_y = max(min(y),obj.sev_mainaxes_ylim(1));
            max_y = min(max(y),obj.sev_mainaxes_ylim(2));
            h = max_y-min_y; %height
            y_mid = CHANNELS_CONTAINER.cell_of_channels{obj.class_channel_index}.line_offset; %min_y+h/2;
            
            obj.clear_handles();
            %editing an existing event
            if(obj.start_stop_matrix_index && obj.event_index) %index exists
                start_stop=EVENT_CONTAINER.cell_of_events{obj.event_index}.start_stop_matrix(obj.start_stop_matrix_index,:);
                x = start_stop(1);
                xdata = [start_stop;start_stop];
                w = diff(start_stop);
                num_events = size(EVENT_CONTAINER.cell_of_events{obj.event_index}.start_stop_matrix,1);
                dur_sec = w/obj.SETTINGS.VIEW.samplerate;
                %status Text...
                set(obj.texthandle.status,'string',sprintf('%s (%s)[%u of %u]: %0.2f s',obj.event_label,obj.channel_label,obj.start_stop_matrix_index,num_events,dur_sec));
            %editing a new event
            else
                mouse_pos = get(obj.axeshandle.main,'currentpoint');
                x = mouse_pos(1,1);
                w = 0.01;
                xdata = [x,x+w;x,x+w];
            end;
            
            ydata = [min_y, min_y;max_y, max_y];
            
            
            rect_pos = [x,min_y,w,h];
            obj.hg_group = hggroup('parent',obj.axeshandle.main,'hittest','off','handlevisibility','off');
            
            uicontextmenu_handle = uicontextmenu('parent',obj.figurehandle.sev,'callback',[]);%,get(parentAxes,'parent'));
            uimenu(uicontextmenu_handle,'Label','Plot data','separator','off','callback',@obj.plotSelection_callback);
            uimenu(uicontextmenu_handle,'Label','Copy to Clipboard','separator','off','callback',@obj.copy2clipboard_callback);
            uimenu(uicontextmenu_handle,'Label','Show PSD','separator','off','callback',@obj.plotPSDofSelection_callback);
            uimenu(uicontextmenu_handle,'Label','Show MUSIC','separator','off','callback',@obj.plotMUSICofSelection_callback);
            
            surface('parent',obj.hg_group,'xdata',xdata,'ydata',ydata,'zdata',zeros(2),...
                'cdata',1,'hittest','on','tag','surface','facealpha',0.5,'uicontextmenu',uicontextmenu_handle);
            rectangle('parent',obj.hg_group,'position',rect_pos,...
                'hittest','on','handlevisibility','on','tag','rectangle'); %turn this on so as not to be interrupted by other mouse clicks on top of this one..
            zdata = 1;
            markersize=3;
            obj.drag_left_h = line('marker','square','linewidth',markersize,'zdata',zdata,'xdata',x,'ydata',y_mid,'parent',obj.hg_group,...
                'handlevisibility','on','hittest','on','tag','left','selected','off',...
                'buttondownfcn',@obj.enableDrag_callback);
            obj.drag_right_h =line('marker','square','linewidth',markersize,'zdata',zdata,'xdata',x+w,'ydata',y_mid,'parent',obj.hg_group,...
                'handlevisibility','on','hittest','on','tag','right','selected','off',...
                'buttondownfcn',@obj.enableDrag_callback);
            
            set(obj.figurehandle.sev,'currentobject',obj.drag_right_h);
            
            if(nargin<2)
                editing_flag=false;
            end
            if(~editing_flag)
                obj.enableDrag_callback(obj.drag_right_h);
            else
                %let the person click on something and start moving at that time
            end
            %     set(hObject,'WindowButtonMotionFcn',@dragEdge);
            %     set(hObject,'WindowButtonUpFcn',@disableDrag)
        end
        
        function dragEdge_callback(obj,hObject,eventdata)
            
            mouse_pos = get(obj.axeshandle.main,'currentpoint');            
            cur_obj = gco;  %findobj(allchild(rectangle_h),'flat','selected','on');
            side = get(cur_obj,'tag');
            
            rectangle_h = findobj(obj.hg_group,'tag','rectangle');
            surf_h = findobj(obj.hg_group,'tag','surface');
            rec_pos = get(rectangle_h,'position');
            w=0;
            if(strcmp(side,'left'))
                w = rec_pos(1)-mouse_pos(1)+rec_pos(3);
                rec_pos(1) = mouse_pos(1);
                if(w<0)
                    w=-w;
                    rightObj = findobj(obj.hg_group,'tag','right');
                    rightObj = rightObj(1);
                    rec_pos(1)=get(rightObj,'xdata');
                    set(cur_obj,'tag','right');
                    set(rightObj,'tag','left');
                else
                    set(cur_obj,'xdata',mouse_pos(1));
                end;
            elseif(strcmp(side,'right'))
                w = mouse_pos(1)-rec_pos(1);
                if(w<0)
                    rec_pos(1)=mouse_pos(1);
                    w=-w;
                    leftObj = findobj(obj.hg_group,'tag','left');
                    leftObj = leftObj(1);
                    set(leftObj,'tag','right');
                    set(cur_obj,'tag','left');
                else
                    set(cur_obj,'xdata',mouse_pos(1));
                end;
                
            else
                disp 'oops.';
            end;
            
            if(w==0)
                w=0.001;
            end;
            
            rec_pos(3) = w;
            set(rectangle_h,'position',rec_pos);
            set(surf_h,'xdata',repmat([rec_pos(1),rec_pos(1)+rec_pos(3)],2,1),'ydata',repmat([rec_pos(2);rec_pos(2)+rec_pos(4)],1,2));
            
            dur_sec = w/obj.SETTINGS.VIEW.samplerate;
            %status Text...
            set(obj.texthandle.status,'string',sprintf('%s (%s): %0.2f s',obj.event_label,obj.channel_label,dur_sec));
        end
        
        function enableDrag_callback(obj,hObject,eventdata)
            %called as part of interactive marking of the graph to annotate events
            %this is called when the user presses the left mouse button over a channel
%             obj.class_channel_index
            set(hObject,'selected','on');
            
            set(obj.figurehandle.sev,'WindowButtonMotionFcn',@obj.dragEdge_callback);
            set(obj.figurehandle.sev,'WindowButtonUpFcn',@obj.disableDrag_callback)            
        end
        
        function disableDrag_callback(obj,hObject,eventdata)
            %called as part of interactive marking of the graph to annotate events
            %this is called when the user releases the mouse button            
            global EVENT_CONTAINER;
            global CHANNELS_CONTAINER;
            
           
            
            cur_obj = gco; %findobj(allchild(rectangle_h),'flat','selected','on');
            
            if(ishandle(cur_obj))
                set(cur_obj,'selected','off');
                %         set(fig,'currentobject',rectangle_h); %this disables the current object...
            end;
            
            set(obj.figurehandle.sev,'WindowButtonUpFcn',@obj.sev_main_fig_WindowButtonUpFcn); %let the user move across again...            
            set(obj.figurehandle.sev,'WindowButtonMotionFcn','');
            
            rectangle_h = findobj(obj.hg_group,'tag','rectangle');
            if(~isempty(rectangle_h))
                rec_pos = floor(get(rectangle_h,'position'));
                
                start = rec_pos(1);
                stop = start+rec_pos(3);
                event_data = [start,stop];
                
                %use this to avoid adding events by mistake (which are too small)
                if(strcmpi(obj.marking_state,'marking'))
                    if(abs(diff(event_data))>.1*CHANNELS_CONTAINER.getSamplerate(obj.class_channel_index))  %WORKSPACE.samplerate?
                        
                        sourceStruct.algorithm = 'Manually_Entered';
                        sourceStruct.channel_indices = [];
                        sourceStruct.editor = 'none';
                        
                        
                        [obj.event_index,obj.start_stop_matrix_index] = EVENT_CONTAINER.updateSingleEvent(event_data,...
                            obj.class_channel_index,obj.event_label,...
                            obj.event_index,obj.start_stop_matrix_index,sourceStruct);
                        channel_obj = CHANNELS_CONTAINER.getChannel(obj.class_channel_index);
                        EVENT_CONTAINER.updateYOffset(obj.event_index,channel_obj.line_offset);
                        obj.refreshAxes();
                        
                    end;
                end
            end
        end
        
        %
        %Contextmenu functions for draggable selection
        %
        
        function varargout = copy2clipboard_callback(obj,varargin)
            %copy selected vector data to the clipboard, for access by pressing
            %control-V (paste) or str=clipboard('paste');
            % global CHANNELS_CONTAINER;
            
            data = obj.copyChannelData2clipboard();
            if(nargout==1)
                varargout{1}=data;
            else
                varargout{1}=[];
            end
        end
        
        function plotMUSICofSelection_callback(obj,varargin)
            global MUSIC;
            global CHANNELS_CONTAINER;

            f=figure;
            a = axes('parent',f);
            roi = obj.getSelectedIndices();
            
            if(~isempty(roi))
                CHANNELS_CONTAINER.showMUSIC(MUSIC,a,obj.class_channel_index,roi);
                try
                    waitforbuttonpress();
                catch ME
                    showME(ME);
                end;
                if(ishandle(f))
                    close(f);
                end
            end            
        end
        
        function plotPSDofSelection_callback(obj,varargin)
            global CHANNELS_CONTAINER;            
            f = figure;
            a = axes('parent',f);
            roi = obj.getSelectedIndices();
            
            if(~isempty(roi))
                CHANNELS_CONTAINER.showPSD(obj.SETTINGS.PSD,a,obj.class_channel_index,roi);
                try
                    waitforbuttonpress();
                catch ME
                    showME(ME);
                end;
                if(ishandle(f))
                    close(f);
                end
            end
        end;
        
        function plotSelection_callback(obj,varargin)
            y=obj.getSelectedChannelData();
            
            if(~isempty(y))
                f=figure;
                plot(y);
                waitforbuttonpress();
                if(ishandle(f))
                    close(f);
                end
                
            end;
            
        end
        
        function grid_handle = draw_x_minorgrid(obj)
            %plots minor grid lines using specified properties
            %y_lines is a vector containing sample points where y-grid lines should be
            %drawn
            %parent_axes is the handle to the axes that the grids will be drawn to
            %grid_handle is a graphics handle to the line
            parent_axes = obj.axeshandle.main;
            spacing_sec = 1.0;
            y_lines = obj.sev_mainaxes_xlim(1):spacing_sec*obj.SETTINGS.VIEW.samplerate:obj.sev_mainaxes_xlim(2);

            
            y_lim = get(parent_axes,'ylim');
            y_data = repmat([y_lim(:); nan],1,numel(y_lines));
            x_data = repmat(y_lines(:)',3,1);
            % z_data = x_data*0-1;
            
            np = get(parent_axes,'nextplot') ;
            set(parent_axes,'nextplot','add') ;
            
            % gh = line('parent',parent_axes);
            if(~isfield(obj.linehandle,'x_minorgrid')||isempty(obj.linehandle.x_minorgrid)||~ishandle(obj.linehandle.x_minorgrid))
                obj.linehandle.x_minorgrid = line(x_data(:),y_data(:),'parent',parent_axes,'color',[0.8 0.8 0.8],'linewidth',0.5,'linestyle',':','hittest','off');
            else
                set(obj.linehandle.x_minorgrid,'xdata',x_data(:),'ydata',y_data(:));
            end
            gh = obj.linehandle.x_minorgrid;
            
            uistack(gh,'bottom'); %move it below everything else
            
            set(parent_axes,'nextplot',np,'Layer','top') ;    % reset the nextplot state
            
            if(nargout==1)
                grid_handle = gh;
            end;
        end
        
        function detectMethodStruct = getDetectionMethodsStruct(obj)
           detectMethodStruct = CLASS_events_container.loadDetectionMethodsInf(fullfile(obj.SETTINGS.rootpathname,obj.SETTINGS.VIEW.detection_path),obj.SETTINGS.VIEW.detection_inf_file);
        end
        
    end
    methods(Static)
        % --------------------------------------------------------------------
        function popout_axes(~, ~, axes_h)
            % hObject    handle to context_menu_pop_out (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            fig = figure;
            copyobj(axes_h,fig); %or get parent of hObject's parent
        end
        

    end
end

