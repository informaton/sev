%> @file CLASS_channels_container.m
%> @brief CLASS_channels_container is a wrapper class for CLASS_channels.
%> This keeps a collection of CLASS_channels as cell contents which are
%> stored in an instance variable.
% ======================================================================
%> @brief CLASS_channels_container exists for the purpose of organizing,
%> updating, and adjusting instances of CLASS_channels.
%
% 
% History
% Written by:
%   Hyatt Moore, IV
%   last modified: October 8, 2012
% ======================================================================
classdef CLASS_channels_container < handle
    properties
        %> The cell which holds CLASS_channel objects.
        cell_of_channels;
        %> size of cell_of_channels (and also channel_vector)
        num_channels;  
        %>sample space of the data currently being viewed
        current_samples; 
        %> index of the channel currently selected 
        current_channel_index; 
        %>index of psd channel to show/0 if off
        current_spectrum_channel_index;         
        %> @brief array of filter structures for applying filters to the data here.
        %> array struct of filter rules that are applied to the
        %> channel data.
        %> The filterStruct is obtained from prefilter_dlg and
        %> has the following fields
        %> outputStruct.src_channel_index = [];
        %> -            .src_channel_label = [];
        %> -            .m_file = [];
        %> -            .ref_channel_index = [];
        %> -            .ref_channel_label = {};
        filterArrayStruct;        
        %> .MAT filename which holds or will hold adjustable channel settings
        settingsFilename = []; 
        %> @brief Vector of structs (channelSettings) containing stored field values of children channel objects - useful for gui display preference tracking between sessions
        %> channelSettings is a struct with settings to load.
        storedChannelSettings = []; 
        %> axes handle to plot PSD results to when applicable
        psd_axes = []; 
        %> figure handle for results to go to and contextmenus to attach
        parent_fig = []; 
        %> where channels are drawn/rendered
        main_axes = [];  
        %> context menu handles to be used for added children
        mainline_contextmenu_h;
        %> 
        referenceline_contextmenu_h; 
        %> Sample rate to use when none is provided by a new CLASS_channel
        %> instance.
        default_samplerate;
        %> pointer to the current event_container instance
        EVENT_CONTAINER; 
        %> struct with sev related information for finding detection paths, files, etc.
        sevDefaults; 
    end
    methods        
        % =================================================================
        %> @brief CLASS_channels_container constructor.
        %> @param obj instance of CLASS_channels_container class.
        %> @param parent_fig Handle to SEV figure
        %> @param main_axes Handle to SEV axes where channels are displayed
        %> @param psd_axes Handle to SEV axes where PSD is displayed
        %> @param sevDefaults Structure of SEV settings
        %> @retval obj instance of CLASS_channels_container class.
        % =================================================================
        function obj = CLASS_channels_container(parent_fig,main_axes,psd_axes,sevDefaults)
            
            if(nargin>3)
                obj.default_samplerate = sevDefaults.samplerate;  %set this to 0 or -1 if you do not want a common sample rate
                
            else
                sevDefaults = [];
                obj.default_samplerate = [];
            end
            
            obj.sevDefaults = sevDefaults;
            obj.EVENT_CONTAINER = [];
            obj.cell_of_channels = {};
            obj.num_channels = 0;
            obj.current_samples = [];
            obj.filterArrayStruct = [];
            obj.current_channel_index = 0;
            obj.current_spectrum_channel_index = 0;
            obj.parent_fig = [];
            obj.main_axes = [];
            obj.psd_axes = [];
            obj.referenceline_contextmenu_h = [];
            
            if(nargin>1)
                obj.parent_fig = parent_fig;
                obj.main_axes = main_axes;
               if(nargin>2)
                   obj.psd_axes = psd_axes;
               end 
               obj.configure_contextmenu();
            end
        end
        
       % =================================================================
       %> @brief Sets the default sample rate of the object.
       %> @param obj instance of CLASS_channels_container.
       %> @param Sample rate to use as the default.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function setDefaultSamplerate(obj,samplerate)
           obj.default_samplerate = samplerate;
       end
       
       % =================================================================
       %> @brief Contextmenu callback for a channel's visibility.
       %> @note This is not implemented and may be *REMOVED* in future
       %> versions.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object.
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_visibility_Callback(obj,hObject,eventdata)
           disp('listening');
       end
       
       % =================================================================
       %> @brief Configure the channels contextmenus' callbacks.
       %> @param obj instance of CLASS_channels_container.
       % =================================================================       
       function configure_contextmenu(obj)
           
           obj.configureReferenceLineContextmenu();
           
           %%% main line contextmenu
           obj.configureChannelLineContextmenu();
           
       end
       
       %% -- Contextmenu configuration section
       
       % --------------------------------------------------------------------
       % Reference Line callback section
       % --------------------------------------------------------------------
       % =================================================================
       %> @brief Configure the channel's reference line contextmenu.  
       %> @param obj instance of CLASS_channels_container.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function configureReferenceLineContextmenu(obj)
           %%% reference line contextmenu
           contextmenu_ref_line_h = uicontextmenu('callback',@obj.contextmenu_ref_line_callback,'parent',obj.parent_fig);
           uimenu(contextmenu_ref_line_h,'Label','Change Color','separator','off','callback',@obj.contextmenu_ref_line_color_callback);
           uimenu(contextmenu_ref_line_h,'Label','Adjust Offset','separator','off','callback',@obj.contextmenu_line_referenceline_callback);
           uimenu(contextmenu_ref_line_h,'Label','Remove','separator','on','callback',@obj.contextmenu_ref_line_remove_callback);
           obj.referenceline_contextmenu_h = contextmenu_ref_line_h;
       end
       
       % =================================================================
       %> @brief The channel's reference line parent contextmenu callback.
       %> The parent context menu that pops up before any of the children contexts are
       %> drawn.           
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_ref_line_callback(obj,hObject,eventdata)
           linehandle = get(obj.parent_fig,'currentobject');
           obj.current_channel_index = get(linehandle,'userdata');
           %             set(linehandle,'selected','on');
           
       end
       % =================================================================
       %> @brief Reference lines' contextmenu color callback option for
       %> changing the lines display color.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_ref_line_color_callback(obj,hObject,eventdata)
           childobj = obj.getCurrentChild();
           c = uisetcolor(childobj.reference_line_color);
           if(numel(c)~=1)
               obj.setReferenceLineColor(obj.current_channel_index,c)
           end;
           set(gco,'selected','off');
       end
       
       % =================================================================
       %> @brief Remove reference line contextmenu callback.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_ref_line_remove_callback(obj,hObject,eventdata)
           reference_offset = 0;
           
           obj.adjust_reference_offset(obj.current_channel_index,reference_offset);
           set(gco,'selected','off');
       end
       
       
       % --------------------------------------------------------------------
       % Main Channel Line callback section
       % --------------------------------------------------------------------
       % =================================================================
       %> @brief Configure contextmenu for channel instances.
       %> @param obj instance of CLASS_channels_container.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function configureChannelLineContextmenu(obj)
           
           uicontextmenu_handle = uicontextmenu('callback',@obj.contextmenu_line_callback,'parent',obj.parent_fig);%,get(parentAxes,'parent'));
           uimenu(uicontextmenu_handle,'Label','Resize','separator','off','callback',@obj.contextmenu_line_resize_callback);
           uimenu(uicontextmenu_handle,'Label','Use Default Scale','separator','off','callback',@obj.contextmenu_line_default_callback);
           uimenu(uicontextmenu_handle,'Label','Move','separator','off','callback',@obj.contextmenu_line_move_callback);
           uimenu(uicontextmenu_handle,'Label','Add Reference Line','separator','on','callback',@obj.contextmenu_line_referenceline_callback);
           uimenu(uicontextmenu_handle,'Label','Change Color','separator','off','callback',@obj.contextmenu_line_color_callback);
           uimenu(uicontextmenu_handle,'Label','Align Channel','separator','off','callback',@obj.align_channels_on_axes);
           uimenu(uicontextmenu_handle,'Label','Hide','separator','on','callback',@obj.contextmenu_line_hide_callback);
           uimenu(uicontextmenu_handle,'Label','Duplicate','separator','off','callback',@obj.contextmenu_line_duplicate_callback);
           uimenu(uicontextmenu_handle,'Label','Copy epoch to clipboard','separator','off','callback',@obj.copy_epoch2clipboard,'tag','copy_epoch2clipboard');
           uimenu(uicontextmenu_handle,'Label','Export channel to workspace','separator','off','callback',@obj.copy_channel2workspace,'tag','copy_channel2workspace');
           uimenu(uicontextmenu_handle,'Label','Show PSD','separator','on','callback',@obj.contextmenu_line_show_psd_callback);
           uimenu(uicontextmenu_handle,'Label','Show MUSIC','separator','off','callback',@obj.contextmenu_line_show_music_callback);
           uimenu(uicontextmenu_handle,'Label','Epoch statistics','separator','on','callback',@obj.contextmenu_line_show_epoch_stats_callback);
           %             uimenu(uicontextmenu_handle,'Label','Open Event Toolbox','separator','off','callback',@obj.event_toolbox_callback,'tag','toolbox');
           uimenu(uicontextmenu_handle,'Label','Show Filtered','separator','off','tag','show_filtered','callback',@obj.contextmenu_line_show_filtered_callback,'checked','off');
           %             uimenu(uicontextmenu_handle,'Label','Compare Events','separator','off','callback',@obj.compare_events_callback,'tag','compare_events');
           
           max_num_sources = 1;  %maximum number of sources that can be drawn...
           
           if(~isfield(obj.sevDefaults,'detection_inf_file') && exist(obj.sevDefaults.detection_inf_file,'file'))
               [mfile, evt_label, num_reqd_indices, unused_param_gui, unused_batch_mode_label] = textread(obj.sevDefaults.detection_inf_file,'%s%s%n%s%c','commentstyle','shell');
               event_detector_uimenu = uimenu(uicontextmenu_handle,'Label','Apply Detector','separator','off','tag','event_detector');
               
               for k=1:numel(num_reqd_indices)
                   if(num_reqd_indices(k)==max_num_sources)
                       uimenu(event_detector_uimenu,'Label',evt_label{k},'separator','off','callback',{@obj.contextmenu_event_detector_callback,mfile{k}});
                   end;
               end
           end;
           obj.mainline_contextmenu_h = uicontextmenu_handle;
       end
       
       % =================================================================
       %> @brief Contextmenu callback for channel objects.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_callback(obj,hObject,eventdata)
           %parent context menu that pops up before any of the children contexts are
           %drawn...
           global MARKING;
           
           handles = guidata(hObject);
           
           obj_handle = get(obj.parent_fig,'currentobject');
           channel_index = get(obj_handle,'userdata');
           
           obj.current_channel_index = channel_index;
           channelObj = obj.getCurrentChild();
           
           set(channelObj.line_handle,'selected','on');
           MARKING.setLinehandle(channelObj.line_handle);
           
           child_menu_handles = get(hObject,'children');  %this is all of the handles of the children menu options
           default_scale_handle = child_menu_handles(find(~cellfun('isempty',strfind(get(child_menu_handles,'Label'),'Use Default Scale')),1));
           show_filtered_handle = findobj(child_menu_handles,'tag','show_filtered');
           % show_filtered_handle = child_menu_handles(find(~cellfun('isempty',strfind(get(child_menu_handles,'Label'),'Show Filtered')),1));
           
           if(channelObj.scale==1)
               set(default_scale_handle,'checked','on');
           else
               set(default_scale_handle,'checked','off');
           end;
           
           %show/hide the show filter handle
           if(isempty(channelObj.filter_data))
               set(show_filtered_handle,'visible','off');
           else
               set(show_filtered_handle,'visible','on');
               if(channelObj.show_filtered)
                   set(show_filtered_handle,'Label','Show Raw Data');
                   %         set(show_filtered_handle,'checked','on');
               else
                   set(show_filtered_handle,'Label','Show Filtered Data');
                   %         set(show_filtered_handle,'checked','off');
               end
           end
           
           guidata(hObject,handles);
       end
       
       % =================================================================
       %> @brief Resize callback for channel object contextmenu.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_resize_callback(obj,hObject,eventdata)
           handles = guidata(hObject);
           set(obj.parent_fig,'pointer','crosshair','WindowScrollWheelFcn',...
               {@obj.resize_WindowScrollWheelFcn,...
               obj.getCurrentChild(),handles.text_marker});
       end;
       
       
       % =================================================================
       %> @brief Copy current epoch of the selected channel to MATLAB
       %> clipboard.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function copy_epoch2clipboard(obj,hObject,eventdata)
           obj.copy2clipboard(obj.current_channel_index);
           set(gco,'selected','off');
       end
       
       
       % =================================================================
       %> @brief Copy current epoch of the selected channel to MATLAB
       %> workspace.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function copy_channel2workspace(obj,hObject,eventdata)
           obj.copy2workspace(obj.current_channel_index);
           set(gco,'selected','off');
       end
       
       % =================================================================
       %> @brief Channel contextmenu callback to duplicate selected
       %> channel.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_duplicate_callback(obj,hObject,eventdata)
           obj.duplicate(obj.current_channel_index);
           obj.align_channels_on_axes();
           set(gco,'selected','off');
       end
       
       
       % =================================================================
       %> @brief Channel contextmenu callback to hide the selected
       %> channel.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_hide_callback(obj,hObject,eventdata)
           obj.hide(obj.current_channel_index);
           set(gco,'selected','off');
       end
       
       % =================================================================
       %> @brief Channel contextmenu callback to move the selected
       %> channel's position in the SEV.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @param channel_object The CLASS_channel object being moved.
       %> @param ylim Y-axes limits; cannot move the channel above or below
       %> these bounds.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function move_line(obj,hObject,eventdata,channel_object,y_lim)
           %windowbuttonmotionfcn set by contextmenu_line_move_callback
           %axes_h is the axes that the current object (channel_object) is in
           pos = get(obj.main_axes,'currentpoint');
           channel_object.setLineOffset(max(min(pos(1,2),y_lim(2)),y_lim(1)));
       end
       
       
       % =================================================================
       %> @brief Mouse wheel callback to resize the selected channel.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Mouse scroll event data.
       %> @param channelObj The selected CLASS_channel object.
       %> @param text_h Text handle for outputing the channel's size/scale.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function resize_WindowScrollWheelFcn(obj,hObject,eventdata,channelObj,text_h)
           %the windowwheelscrollfcn set by contextmenu_line_resize_callback
           %it is used to adjust the size of the selected channel object (channelObj)
           scroll_step = 0.05;
           lowerbound = 0.01;
           channelObj.scale = max(lowerbound,channelObj.scale-eventdata.VerticalScrollCount*scroll_step);
           channelObj.draw();
           
           %update this text scale...
           click_str = sprintf('Scale: %0.2f',channelObj.scale);
           set(text_h,'string',click_str);
       end
       
       % --------------------------------------------------------------------
       % =================================================================
       %> @brief Contextmenu callback to smooth the selected channel's
       %> display.  Uses matlab's line handle 'linesmoothing' option.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @param handles Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function context_menu_line_smoothing_Callback(obj,hObject, eventdata, handles)
           % hObject    handle to context_menu_line_smoothing (see GCBO)
           % eventdata  reserved - to be defined in a future version of MATLAB
           % handles    structure with handles and user data (see GUIDATA)
           
           childObj = obj.getCurrentChild();
           
           if(strcmp(get(hObject,'Checked'),'on'))
               set(hObject,'Checked','off');
               set(childObj.line_handle,'linesmoothing','off');
           else
               set(hObject,'Checked','on')
               set(childObj.line_handle,'linesmoothing','on');
           end;
           set(gco,'selected','off');
       end
       
       % =================================================================
       %> @brief This context menu will allow the user to place or remove line labels as
       %> necessary.           
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject Handle of callback object (unused).
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_referenceline_callback(obj,hObject,eventdata)
           %the function str2double is implicitly used as an error check in
           %conjunction with the explecit if statement that follows it.
           
           childobj = obj.getCurrentChild();
           reference_line_offset_str = num2str(childobj.reference_line_offsets(1));
           
           %tried to change this, but does not work without the strvcat as of this
           %commenting.
           reference_offset_str = inputdlg(char({'Input desired line offset (in uV)','(0 turns off reference lines)'}),'Line Reference Input Dialog',1,{reference_line_offset_str});
           
           if(~isempty(reference_offset_str))
               reference_offset = str2double(reference_offset_str{1});
               
               if(~(isnan(reference_offset)))
                   obj.adjust_reference_offset(obj.current_channel_index,reference_offset);
               end
           end
           set(gco,'selected','off');
       end
       
       % =================================================================
       %> @brief configures a contextmenu selection to be hidden or to have
       %> attached uimenus with labels of hidden channels displayed.  
       %> @param obj instance of CLASS_channels_container.
       %> @param contextmenu_h Handle of parent contextmenu to unhide
       %> channels.
       %> @param eventdata Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function configure_contextmenu_unhidechannels(obj,contextmenu_h,eventdata)           
           delete(get(contextmenu_h,'children'));
           set(contextmenu_h,'enable','off');
           for k=1:obj.num_channels
               tmp = obj.cell_of_channels{k};
               if(tmp.hidden)
                   set(contextmenu_h,'enable','on');
                   uimenu(contextmenu_h,'Label',tmp.title,'separator','off','callback',@tmp.show);
               end;
           end;
           set(gco,'selected','off');
           
       end
       
       % =================================================================
       %> @brief Show MUSIC spectrum of a channel's selected data points.
       %> @param obj instance of CLASS_channels_container.
       %> @param spectrum_settings MUSIC settings.
       %> @param axes_h The axes handle to display the spectrum on.
       %> Default is obj.psd_axes
       %> @param channel_index Index of the CLASS_channel object to
       %> calculate spectrum of.
       %> @param sample_indices Channel's sample indices to calculate
       %> spectrum over.  Default is to use obj's
       %> current_spectrum_channel_index instance variable.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function showMUSIC(obj,spectrum_settings,axes_h, channel_index, sample_indices)
           if(nargin <5)
               sample_indices = obj.current_samples;
               if(nargin <4)
                   channel_index = obj.current_spectrum_channel_index;
                   if(nargin<3)
                       axes_h = obj.psd_axes;
                   end
               end
           end

           if(channel_index>0 && channel_index<=obj.num_channels) %just show this for one channel then...
               channelObj = obj.getChannel(channel_index);
               [S F] = channelObj.calculate_PMUSIC(spectrum_settings,sample_indices);
               
               %just look at a subset right now...
               freq_range = F<=spectrum_settings.freq_max & F>=spectrum_settings.freq_min;
               cla(axes_h);
               line('parent',axes_h,'xdata',F(freq_range),'ydata',S(freq_range));
               set(axes_h,'xlim',[spectrum_settings.freq_min,spectrum_settings.freq_max])
           end;
       end
       
       % =================================================================
       %> @brief Displays the PSD of the input channel index on the range
       %> of samples identified by sample_indices using the PSD settings
       %> listd in the input struct spectrum_settings.
       %> @param obj instance of CLASS_channels_container.
       %> @param spectrum_settings struct with PSD settings to use
       %> @param axes_h Axes handle to plot power spectrum to.
       %> @param channel_index Index of the channel object to calculate PSD
       %> of.
       %> @param sample_indices range of samples to calculate the PSD over.
       % =================================================================
       function showPSD(obj,spectrum_settings,axes_h,channel_index,sample_indices)
           if(nargin <5)
               sample_indices = obj.current_samples;
               if(nargin <4)
                   channel_index = obj.current_spectrum_channel_index;
                   if(nargin<3)
                       axes_h = obj.psd_axes;
                   end
               end
           end
           
           if(channel_index>0 && channel_index<=obj.num_channels) %just show this for one channel then...
               channelObj = obj.getChannel(channel_index);
               [S F] = channelObj.calculate_PSD(spectrum_settings,sample_indices);
               
               %just look at a subset right now...
               freq_range = F<=spectrum_settings.freq_max & F>=spectrum_settings.freq_min;
               
               F = F(freq_range);
               S = S(:,freq_range);
               S(:,1) = 0; %don't show the mean here b/c it can hold negative values for us (-dc offset), which makes it less intelligible due to matlab's auto scaling.
               cla(axes_h);
               bar(axes_h,F,sum(S,1)/size(S,1));               
               set(axes_h,'xlim',[spectrum_settings.freq_min,spectrum_settings.freq_max])
           end;
       end
       
       % =================================================================
       %> @brief Set color of the selected channels' referece line(s).  
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_indices Indices of the channels whose reference
       %> lines will be set.
       %> @param new_colors Color to set reference line to.  If
       %> channel_indices is an Nx1 vector, then new_colors is an Nx3 matrix.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function setReferenceLineColor(obj,channel_indices,new_colors)
           num_colors = size(new_colors,1);  %how many rows
           num_indices = numel(channel_indices);
           for k=1:num_indices
               if(num_colors<num_indices)
                   new_color = new_colors(1,:);
               else
                   new_color = new_colors(k,:);
               end
               channel_index = channel_indices(k);
               if(channel_index>0 && channel_index<=obj.num_channels)
                   obj.cell_of_channels{channel_index}.setReferenceLineColor(new_color);
               end
           end
       end
       
       % =================================================================
       %> @brief Set color of the selected channel's referece line.  
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index Index of the channel to set the reference line color of.
       %> @param c Color to use.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function obj = setColor(obj,channel_index,c)
           obj.cell_of_channels{channel_index}.setColor(c);
       end
       
       % =================================================================
       %> @brief Gets the color of the selected channel.
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index Index of the channel to return the line color of.
       %> @retval colorOut Color of the selected channel.
       % =================================================================
       function colorOut = getColor(obj,channel_index)
           colorOut = obj.cell_of_channels{channel_index}.color;
       end
       
       % =================================================================
       %> @brief Load settings from a file.
       %> @param obj instance of CLASS_channels_container.
       %> @param settingsFilename Name of file to load settings from.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function obj = loadSettings(obj, settingsFilename)
           if(exist(settingsFilename,'file'))
               x = load(settingsFilename);
               obj.storedChannelSettings = x.storedChannelSettings;
           end
       end
       
       % =================================================================
       %> @brief Channel's contextmenu line move callback.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject gui handle object
       %> @param eventdata unused
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_move_callback(obj,hObject,eventdata)
           y_lim = get(obj.main_axes,'ylim');
           
           set(obj.parent_fig,'pointer','hand',...
               'windowbuttonmotionfcn',...
               {@obj.move_line,obj.getCurrentChild(),y_lim}...
               );
       end;
       
       
       % =================================================================
       %> @brief Channel's contextmenu line default scale callback.
       %> Returns the channel's scale/size to 1.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject gui handle object
       %> @param eventdata unused
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_default_callback(obj,hObject,eventdata)
           
           if(strcmp(get(hObject,'checked'),'off'))
               set(hObject,'checked','on');
               childobj = obj.getCurrentChild();
               childobj.scale = 1;
               childobj.draw();
           end;
           set(gco,'selected','off');
       end
       
       % =================================================================
       %> @brief Channel's contextmenu option to display results of the
       %> applied filter(s).
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject gui handle object
       %> @param eventdata unused
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_show_filtered_callback(obj,hObject,eventdata)
           if(strcmp(get(hObject,'label'),'Show Filtered Data'))
               show_filtered = true;
           else
               show_filtered = false;
           end
           
           %if it is checked ('on') then we want to turn it off -> send false
           %and if it is 'off' then we want to turn it on -> send true
           obj.setShowFiltered(obj.current_channel_index,show_filtered);
           % CHANNELS_CONTAINER.setShowFiltered(channel_index,strcmp(get(hObject,'checked'),'off'));
           
           %set things back in order and update the plot...
           set(gco,'selected','off');
           %             updatePlot(guidata(hObject));
       end
       
       % =================================================================
       %> @brief Channel contextmenu option to display the channel's PSD.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject handle of the gui object
       %> @param eventdata unused
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_show_psd_callback(obj,hObject,eventdata) 
           global MARKING;
           obj.current_spectrum_channel_index = obj.current_channel_index;
           obj.showPSD(MARKING.SETTINGS.PSD);
           set(gco,'selected','off');
       end
       
       % =================================================================
       %> @brief Channel contextmenu option to display the channel's MUSIC
       %> spectrum.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject handle of the gui object
       %> @param eventdata unused
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_show_music_callback(obj,hObject,eventdata)
           global MARKING;
           obj.current_spectrum_channel_index = obj.current_channel_index;
           obj.showMUSIC(MARKING.SETTINGS.MUSIC);
           set(gco,'selected','off');           
       end
       
       % =================================================================
       %> @brief Channel contextmenu option to set the channel's line
       %> color.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject handle of the gui object
       %> @param eventdata unused
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_color_callback(obj,hObject,eventdata)
           
           channel_index = obj.current_channel_index;
           % channel_index = get(WORKSPACE.current_linehandle,'userdata');
           c = obj.getColor(channel_index);
           c = uisetcolor(c);
           if(numel(c)~=1)
               obj.setColor(channel_index,c);
           end;
           set(gco,'selected','off');
       end
       
       % =================================================================
       %> @brief Channel contextmenu option to run an event detector on the channel.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject gui handle object
       %> @param eventdata unused
       %> @param detection_mfile File that contains SEV compatible
       %> detection methods that can be selected from.
       %> @note This option will be deprecated in future releases and is
       %> flagged for removal (*REMOVE*).
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_event_detector_callback(obj,hObject,eventdata,detection_mfile)
           global MARKING;
           
           
           if(ishandle(MARKING.current_linehandle))
               showBusy();
               channelIndex = get(WORKSPACE.current_linehandle,'userdata');
               function_call = [obj.sevDefaults.detection_path(2:end),'.',detection_mfile];
               detectStruct = feval(function_call,channelIndex);
               %detectStruct has the fields
               % .new_data
               % .new_events
               % .paramStruct - parameters associated with detected events
               
               event_label = get(hObject,'label');
               sourceStruct.channel_indices = channelIndex;
               sourceStruct.algorithm = [obj.sevDefaults.detection_path(2:end),'.',detection_mfile];
               
               detection_struct = CLASS_settings.loadParametersInf(obj.sevDefaults.detection_path);
               %detection_struct has the fields that are contained/gridded in the
               %detection.inf file
               %
               
               sourceStruct.editor = detection_struct.param_gui{strcmp(detection_mfile,detection_struct.mfile)};
               
               event_index = obj.EVENT_CONTAINER.updateEvent(detectStruct.new_events,event_label,channelIndex,sourceStruct,detectStruct.paramStruct);
               if(~isempty(event_index))
                   obj.EVENT_CONTAINER.draw_events(event_index);
                   %                     handles = guidata(hObject);
                   
                   %                     updateAxes2(handles);
                   %                     updatePlot(handles);
               end;
           else
               warndlg('no valid line handle found');
               
           end;
           MARKING.restore_state();
           set(gco,'selected','off');
       end
       
       % =================================================================
       %> @brief Channel context menu to display statistics of the channel.
       %> @param obj instance of CLASS_channels_container.
       %> @param hObject gui handle object
       %> @param eventdata unused
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function contextmenu_line_show_epoch_stats_callback(obj,hobject,eventdata)
           global MARKING;
           
           cur_epoch = MARKING.current_epoch;
           childobj = obj.getCurrentChild();
           summary_stats = obj.getStats(obj.current_channel_index);
           summary_stats.description_str = sprintf('summary statistics for %s epoch (%u)',obj.getChannelName(obj.current_channel_index),cur_epoch);
           if(~isfield(childobj,'summarystats_h') || ~ishandle(childobj.summarystats_h))
               childobj.summary_stats_figure_h = figure('menubar','none','visible','off','name',summary_stats.description_str,'units','pixels','visible','on');
               childobj.summary_stats_uitable_h = uitable('parent',childobj.summary_stats_figure_h,'columnname',summary_stats.table_column_names,'data',summary_stats.table_data,'rowname',summary_stats.table_row_names,'units','pixels','visible','on');
           else
               set(childobj.summary_stats_uitable_h,'columnname',summary_stats.table_column_names,'data',summary_stats.table_data,'rowname',summary_stats.table_row_names);
           end
           drawnow;
           extent = get(childobj.summary_stats_uitable_h,'extent');
           figure_pos = get(childobj.summary_stats_figure_h,'position');
           set(childobj.summary_stats_uitable_h,'position',[0 0 extent(3:4)]);
           set(childobj.summary_stats_figure_h,'position',[figure_pos(1:2), extent(3:4)]);
           set(gco,'selected','off');
       end
       
       % =================================================================
       %> @brief Return the selected channel object.
       %> @param obj Instance of CLASS_channels_container.
       %> @retval childobj The selected CLASS_channel object.
       % =================================================================
       function childobj = getCurrentChild(obj)
           if(obj.current_channel_index>0 && obj.current_channel_index<=obj.num_channels)
               childobj = obj.cell_of_channels{obj.current_channel_index};
           else
               childobj = [];
           end
       end
       
       % =================================================================
       %> @brief Sets channel settings indicated by indices.
       %> @param obj instance of CLASS_channels_container.
       %> @param Indices are the indices of the children channels requesting
       %> setting adjustments if there is a match (if indices is empty
       %> then all channels with matching titles will be used.           
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function obj = setChannelSettings(obj,indices)
           %channelSettings is a struct with settings to load
           channelSettings = obj.storedChannelSettings;
           if(~isempty(channelSettings))
               if(nargin<2 || isempty(indices))
                   indices = 1:obj.num_channels;
               end
               
               storedEDF_labels = cell(numel(obj.storedChannelSettings),1);
               [storedEDF_labels{:}] = obj.storedChannelSettings.EDF_label;
               
               for k=1:numel(indices)
                   index = indices(k);
                   %now I can check if the label is already in existence or
                   %not...
                   channelName = obj.getChannelName(index);
                   match = find(strcmpi(channelName,storedEDF_labels),1);
                   if(~isempty(match))
                       %update the data from channelsettings
                       obj.cell_of_channels{index}.loadSettings(channelSettings(match));
                   end
               end
           end
       end
       % =================================================================
       %> @brief Save channel settings to file.
       %> @param obj instance of CLASS_channels_container.
       %> @param settingsFilename Name of the file to save settings to
       %> (string).
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function obj = saveSettings(obj, settingsFilename)
           %save the settings to the given filename as a .mat file
           %find any matches and replace, otherwise add to it.
           if(obj.num_channels>=1)
               if(nargin<2 || isempty(settingsFilename))
                   settingsFilename = obj.settingsFilename;
               end
               if(~isempty(settingsFilename))
                   obj.settingsFilename = settingsFilename;
                   if(isempty(obj.storedChannelSettings) && exist(settingsFilename,'file'))
                       obj.loadSettings(settingsFilename);  %make sure we don't accidentally delete otherwise stored settings
                   end
                   if(isempty(obj.storedChannelSettings))
                       obj.storedChannelSettings = repmat(obj.cell_of_channels{1}.getSettings(),obj.num_channels,1);
                       
                       for k=2:obj.num_channels
                           obj.storedChannelSettings(k) = obj.cell_of_channels{k}.getSettings();
                       end
                   else
                       for k=1:obj.num_channels
                           settings = obj.cell_of_channels{k}.getSettings();
                           storedEDF_labels = cell(numel(obj.storedChannelSettings),1);
                           [storedEDF_labels{:}] = obj.storedChannelSettings.EDF_label;
                           match = find(strcmpi(settings.EDF_label,storedEDF_labels),1);
                           if(~isempty(match))
                               obj.storedChannelSettings(match) = settings;
                           else
                               obj.storedChannelSettings(end+1) = settings;
                           end
                       end
                   end
                   storedChannelSettings = obj.storedChannelSettings;
                   save(settingsFilename,'storedChannelSettings','-mat');
               end
           end
       end
       % =================================================================
       %> @brief Adjust a channel's reference line offset.
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index Index of the channel to adjust.
       %> @param reference_offset Offset to adjust reference line to.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function adjust_reference_offset(obj,channel_index,reference_offset)
           if(channel_index<=obj.num_channels && channel_index>0)
               obj.cell_of_channels{channel_index}.setReferenceLineOffset(reference_offset);
           end
       end
       
       % =================================================================
       %> @brief Retrieves EDF indices that have been loaded and which are stored in the CLASS_channels_container instance.
       %> @param obj instance of CLASS_channels_container.
       %> @retval loadedEDFIndices Vector containing the indices of the PSG
       %> channels that have been loaded from the current EDF file.
       %> @note Synthetic channels are excluded (i.e. ones generated
       %> internally using SEV and which are not found in the original EDF
       %> file.
       % =================================================================
       function loadedEDFIndices = getLoadedEDFIndices(obj)
           loadedEDFIndices = zeros(obj.num_channels,1);
           for k=1:numel(loadedEDFIndices)
               loadedEDFIndices(k) = obj.cell_of_channels{k}.EDF_index;
           end;
           
           %exclude synthetic channels
           loadedEDFIndices = loadedEDFIndices(loadedEDFIndices>0);
       end
       
       %% sev menu callbacks
       % =================================================================
       %> @brief loadEDFchannels(obj,EDF_fullfilename,EDF_channel_indices,use_Default_Samplerate)
       %> @param obj instance of CLASS_channels_container.
       %> @param EDF_fullfilename Full path and filename of EDF to load
       %> @param EDF_channel_indices Vector of channel indices - 1 correspdonds to the
       %> first channel in the EDF
       %> @param use_Default_Samplerate - boolean (default is true)
       %> @retval obj instance of CLASS_channels_container.
       %> @retval EDF_HDR EDF's header
       % =================================================================
       function EDF_HDR = loadEDFchannels(obj,EDF_fullfilename,EDF_channel_indices,use_Default_Samplerate)
           try
               %default to using the default sample rate
               if(nargin<4)
                   use_Default_Samplerate= true;
               end
               HDR = loadEDF(EDF_fullfilename);
               EDF_channel_indices = EDF_channel_indices(EDF_channel_indices>0 &...
                   EDF_channel_indices<=numel(HDR.label));
               [HDR, signals] = ...
                   loadEDF(EDF_fullfilename,EDF_channel_indices);
               
               EDF_HDR = HDR;
               for k=1:numel(EDF_channel_indices)
                   EDF_index = EDF_channel_indices(k);
                   src_label = HDR.label{EDF_index}; %just stick with the EDF label as the title for now (default)
                   if(use_Default_Samplerate)
                       %use default samplerate (100Hz)
                       obj.addChannel(signals{k},...
                           src_label,EDF_index,HDR.samplerate(EDF_index));
                   else
                       %or use sample rate from Header
                       obj.addChannel(signals{k},...
                           src_label,EDF_index,HDR.samplerate(EDF_index),HDR.samplerate(EDF_index));
                   end
               end;
           catch ME
               ME.message
               ME.stack(1).line
               ME.stack(1).file
               EDF_HDR = [];
           end           
       end       
       
       % =================================================================
       %> @brief Load a single channel as defined by the input arguments
       %> @param obj instance of CLASS_channels_container.
       %> @param channelData Row vector of channel's sample values
       %> @param samplerate Sampling frequency used for the data.
       %> @param channelLabel Label to describe the channel (string)
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function HDR = loadGenericChannel(obj,channelData,samplerate,channelLabel)
           try
               EDF_index = -1;
               obj.addChannel(channelData,channelLabel,EDF_index,samplerate);
               HDR.duration_sec = numel(channelData)/samplerate;
               HDR.T0 = [2020 7 31 00 00 00];
               HDR.label = {channelLabel};
               HDR.fs = samplerate;
               HDR.samplerate = samplerate;
               HDR.duration_samples = numel(channelData);
           catch ME
               showME(ME);
               HDR = [];
           end
       end
       
       % =================================================================
       %> @brief Evenly distributes non-hidden channels on the current
       %> axes.  Variable arguments allow to be used as a callback function if necessary
       %> @param obj instance of CLASS_channels_container.
       %> @param varargin (e.g. hObject, eventdata) Unused.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function align_channels_on_axes(obj,varargin)
           
           if(obj.num_channels>0)
               indices_to_draw = zeros(obj.num_channels,1);
               for k = 1:obj.num_channels
                   childObj = obj.getChannel(k);
                   indices_to_draw(k)=~childObj.hidden;
               end;
               indices_to_draw = find(indices_to_draw>0);
               
               num_channels_to_draw = numel(indices_to_draw);
               if(num_channels_to_draw>0)
                   lim = ylim(obj.main_axes);
                   line_delta = diff(lim)/num_channels_to_draw;
                   line_offset = lim(2)+line_delta/2;
                   
                   for k=1:num_channels_to_draw
                       obj.current_channel_index = indices_to_draw(k);
                       line_offset = line_offset-line_delta;
                       childObj = obj.getCurrentChild();
                       childObj.setLineOffset(line_offset);
                   end
               end;
           end;
       end
       
       % =================================================================
       %> @brief Presents a dialog box (UI) of available channel names for the user to select.
       %> @param obj instance of CLASS_channels_container.
       %> @retval channel_indices Channel indices (cell_of_channels) that
       %> the user selected.  This is empty for no selection or if the user
       %> cancels.
       % =================================================================
       function channel_indices = channelSelection_dlg(obj) %dialog of channels to select
           channel_names = obj.getChannelNames();
           channel_indices = listdlg('PromptString','Select channel(s) to export',...
               'ListString',channel_names,'name','Channel Selector',...
               'SelectionMode','multiple');
       end
       % =================================================================
       %> @brief
       %> @param obj instance of CLASS_channels_container.
       %> @param
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function savePSD2txt(obj, studyname,optional_src_channels,optional_pathname)
           if(nargin<=2)
               channels = obj.channelSelection_dlg();
           else
               channels = optional_src_channels;
           end
           if(nargin<=3)
               pathname = uigetdir(pwd,'Output directory');
           else
               pathname = optional_pathname;
           end
           
           studyname = strrep(studyname,'.EDF','');
           
           for c=1:numel(channels)
               ch = channels(c);
               chan_name = obj.getChannelName(ch);
               save_studyname = [studyname,'.',chan_name,'.txt'];
               save_filename = fullfile(pathname,save_studyname);
               obj.cell_of_channels{ch}.savePSD2txt(save_filename);
           end
           
       end
       
       % =================================================================
       %> @brief getChannel returns the CLASS_channel object found in the
       % cell parameter cell_of_channels at index container_index
       %> @param obj instance of CLASS_channels_container.
       %> @param container_index Index of the channel to obtain from the
       %> parameter cell_of_channels.
       %> @retval channel_obj instance of CLASS_channel class.
       % =================================================================
       function channel_obj = getChannel(obj,container_index)
           if(iscell(container_index))
               container_index  = container_index{1};
           end
           if(container_index>0 && container_index<=obj.num_channels)
               channel_obj = obj.cell_of_channels{container_index};
           else
               channel_obj = [];
           end
       end
       
       % =================================================================
       %> @brief Duplicate the channel at channel_index by copying the CLASS_channel object
       %> at the provided index and updating relevant fields.
       %> @param obj instance of CLASS_channels_container.
       %> @param src_container_index Index of the channel to duplicate.
       %> @param optional_new_title (Optional) string label of the
       %> duplicated channel.  Default is to append '_duplicate' to the
       %> original channel's label.
       %> @param optional_dest_container_index (Optional) container index for synthesized channel
       %> to be placed at.  This is useful in batch mode when everything is
       %>preallocated
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function duplicate(obj,src_container_index,optional_new_title,optional_dest_container_index)

           if(src_container_index>0 && src_container_index<=obj.num_channels)
               %                 src_channel = obj.cell_of_channels{channel_index};
               %                 src_channel.title = [src_channel.title,'_duplicate'];
               %                 offset = src_channel.offset;
               %                 if(offset>0)
               %                     src_channel.offset = offset-25;
               %                 else
               %                     src_channel.offset = offset+25;
               %                 end
               %                 obj.num_channels = obj.num_channels+1;
               %                 src_channel.channel_index = obj.num_channels;
               %                 obj.cell_of_channels{obj.num_channels}=src_channel;
               
               %this approach avoids the sticky problem of events
               %associated with the channel
               srcChannel= obj.getChannel(src_container_index);
               
               if(nargin>2 && ~isempty(optional_new_title))
                   title = optional_new_title;
               else
                   %establish new name
                   title = [strrep(srcChannel.title,'_duplicate',''),'_duplicate'];
                   
                   numDuplicates = 1; %start with one duplicate - this one.
                   channel_titles = obj.getChannelNames();
                   for k=1:obj.num_channels
                       if(strncmp(title,channel_titles{k},numel(title)))
                           numDuplicates = numDuplicates+1;
                       end
                   end
                   title = strcat(title,' ',int2str(numDuplicates));
               end
               
               if(nargin>3 && ~isempty(optional_dest_container_index))
                   obj.replaceChannel(optional_dest_container_index,[],title, src_container_index,srcChannel.src_samplerate,srcChannel.samplerate);
               else
                   obj.addChannel([],title, src_container_index,srcChannel.src_samplerate,srcChannel.samplerate);
               end
               new_channel = obj.getCurrentChild();
               
               propertiesToDuplicate = {'show_filtered','samplerate','src_samplerate','hidden','MUSIC',...
                   'PSD','current_samples','scale','color','reference_line_offsets','reference_line_color',...
                   'raw_data','filter_data','filterStruct','show_filtered'};
               
               for p=1:numel(propertiesToDuplicate)
                   new_channel.(propertiesToDuplicate{p}) = srcChannel.(propertiesToDuplicate{p});
               end
               
               new_channel.synth_src_container_indices = src_container_index;
               
           end
           
       end
       
       % =================================================================
       %> @brief Synthesize a new channel object (CLASS_channel) and add it
       %> to the private cell variable 'cell_of_channels'.
       %> @param obj instance of CLASS_channels_container.
       %> @param src_container_channel_indices 
       %> @param filterStructs A cell of filterStruct arrays.  The filter
       %> structs are applied to the source channels during synthesis.
       %> filterStruct is a struct with the following fields
       %> - filter_path (the path where the filter functions are; e.g. sev.filter_path
       %> - src_channel_index   The index of the event_container EDF channel)
       %> - src_channel_label   Cell label of the string that holds the EDF channel label
       %> - m_file              MATLAB filename to use for the filtering (feval)
       %> - ref_channel_index   The index or indices of additional channels to use as a reference when and where necessary
       %> - ref_channel_label   Cell of strings that hold the EDF channel label associated with the ref_channel_index
       %> - src_channel_index: 1
       %> - src_channel_label: 'C3-M2'
       %> - filter: 'anc_rls.m'
       %> - ref_channel_index: [1 1]
       %> - ref_channel_label: {'C3-M2'  'C3-M2'}
       %> @note The filter struct should be verified against the existing
       %> structure for each event and only applied if/as different.
       %> This checking is carried out at the next level down in the
       %> channel_class objects.           
       %> @param synth_titles Synthetic channel's label.
       %> @param optional_dest_container_indices  Optional container_index for synthesized channel
       %> to be placed at - useful in batch mode when everything is preallocated
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function synthesize(obj,src_container_channel_indices, filterStructs, synth_titles,optional_dest_container_indices)
           %work with cells
           if(~iscell(filterStructs))
               filterStructs = {filterStructs};
               synth_titles ={synth_titles};
           end
           
           %duplicate src channel and then filter
           %modified 5/21/12 - changed synth_title{1} to synth_titles{1}
           %to avoid crashing when multiple sources, but same  title...
           for k=1:numel(src_container_channel_indices)
               if(nargin>3 && numel(optional_dest_container_indices)>=k)
                   obj.duplicate(src_container_channel_indices(k),synth_titles{k},optional_dest_container_indices(k)); %calls synthesizeChannel which calls addChannel
               else
                   obj.duplicate(src_container_channel_indices(k),synth_titles{k}); %calls synthesizeChannel which calls addChannel
               end
               src_channel_indices = zeros(size(filterStructs{k}));
               for m=1:numel(filterStructs{k})
                   if(nargin>3 && numel(optional_dest_container_indices)>=k)
                       filterStructs{k}(m).src_channel_index = optional_dest_container_indices(k);
                   else
                       filterStructs{k}(m).src_channel_index = obj.num_channels; %it was just duplicated, so use the most recent addition for the source filtering now
                   end
                   src_channel_indices = filterStructs{k}(m).src_channel_index;
               end
               
               obj.filter(filterStructs{k});
               
               %now go through and update unique source channels that were
               %synthesized;
               src_channel_indices = unique(src_channel_indices);
               for m=1:numel(src_channel_indices)
                   src_channel_index = src_channel_indices(m);
                   new_channel = obj.getChannel(src_channel_index);
                   new_channel.raw_data = []; %have to do this instead of a straight copy al la new_channel.raw_data = new_channel.filter_data which does not actually overwrite the raw_data.
                   new_channel.raw_data = new_channel.filter_data;
                   new_channel.filter_data = [];
                   new_channel.show_filtered = 0;
               end
           end
       end
       
       % =================================================================
       %> @brief Synthesize a new channel (i.e. instance of CLASS_channel)
       %> @param obj instance of CLASS_channels_container.
       %> @param data Synthetic channels signal data.  
       %> @param src_container_channel_indices cell_of_channels indices that the synthetic channel is derived from.
       %> @param src_label Label to use as the channel's source.
       %> @param optional_container_placement_index (Optional) index of another channel that should be replaced by the synthesized channel.
       %> A new channel is simply added to cell_of_channels if this
       %> parameter is not included.
       %> @note Synthetic channels show a PSG index of -1.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function obj = synthesizeChannel(obj,data, src_container_channel_indices,src_label,optional_container_placement_index)
           %if varargin{1} then the channel space in this container class
           %has already been preallocated (likely in batch.load_file.m for
           %batch processing, and the number of channels does not need
           %updating
           EDF_index = -1; %this is synthesized, and not from the EDF
           if(src_container_channel_indices(1)<obj.num_channels)
               src_samplerate = obj.getSamplerate(src_container_channel_indices(1));
           else
               src_samplerate = obj.default_samplerate;
           end
           
           %when working in single study mode for instance...
           if(nargin>4 && ~isempty(optional_container_placement_index))
               obj.replaceChannel(optional_container_placement_index,sdata,src_label,EDF_index,src_samplerate);
           else
               obj.addChannel(data,src_label,EDF_index,src_samplerate);
           end
           
           %account for channel synthesis.
           obj.cell_of_channels{obj.current_channel_index}.synth_src_container_indices = src_container_channel_indices;
           
       end
       
       % =================================================================
       %> @brief addChannel(obj,data,src_label, source_indices,src_samplerate,desired_samplerate)
       %> @param obj instance of CLASS_channels_container class.
       %> @param data Signal data of channel to be added (a vector)
       %> @param src_label Name of the channel to be added (a string)
       %> @param source_indices Index of the source PSG file that the newly
       %> added channel corresponds to.
       %> @note Synthetic channels have a source_indices of -1
       %> @param src_samplerate Samplerate of the channel being added
       %> (optional)
       %> @note CLASS_channels_container default samplerate is used if the source samplerate is not provided
       %> @param desired_samplerate Desired samplerate of new channel (optional)
       %> @note @c src_samplerate is used if @c desired_samplerate is not provided
       %> @retval obj instance of CLASS_channels_container class.
       %> @retval index_added Index of the cell position where the new
       %> CLASS_channel object was added/inserted.
       % =================================================================
       function index_added = addChannel(obj,data,src_label, source_indices,src_samplerate,desired_samplerate)
           if(nargin<=5)
               if(obj.default_samplerate>0)
                   desired_samplerate = obj.default_samplerate;
               else
                   desired_samplerate = src_samplerate;
               end
           end
           obj.num_channels =obj.num_channels+1;
           container_index = obj.num_channels;
           obj.current_channel_index = container_index;
           
           if(~isempty(obj.parent_fig)&&~isempty(obj.main_axes) && all(ishandle([obj.parent_fig;obj.main_axes])))
               obj.cell_of_channels{obj.current_channel_index} = CLASS_channel(...
                   data,...
                   src_label, source_indices,...
                   src_samplerate,desired_samplerate,...
                   container_index,...
                   obj.parent_fig,obj.main_axes);
               
               childobj = obj.getCurrentChild();
               childobj.current_samples = obj.current_samples; %or childobj.setCurrentSamples(obj.current_smaples), but this calls a draw which may not be wanted
               childobj.setupReferenceLines(obj.referenceline_contextmenu_h);
               childobj.setupMainLine(obj.mainline_contextmenu_h);
               
           else
               obj.cell_of_channels{obj.current_channel_index} = CLASS_channel(...
                   data,...
                   src_label, source_indices,...
                   src_samplerate,desired_samplerate,...
                   container_index);
           end
           index_added = container_index;
       end
       
       % =================================================================
       %> @brief Replace a channel in the cell_of_channels with a
       %> different channel.
       %> @note created for batch mode processing with synthetic channel
       %> support.  Not finished yet for individual study mode
       %> processing since I have not implemented clean-up of past
       %> channel at index2replace yet.
       %> @param obj instance of CLASS_channels_container.
       %> @param index2replace Index of channel to be replaced.
       %> @param data Vector of channel's signal data.
       %> @param src_label PSG label of channel.
       %> @param source_indices PSG index of channel. 
       %> @param src_samplerate Original sample rate of source channel.
       %> @param desired_samplerate New sample rate.
       %> @retval index_added Index of the channel that was added or empty if it could not be replaced
       %> (e.g. an invalid index2replace).
       % =================================================================
       function index_added = replaceChannel(obj,index2replace,data,src_label, source_indices,src_samplerate,desired_samplerate)
           if(nargin<=6)
               if(obj.default_samplerate>0)
                   desired_samplerate = obj.default_samplerate;
               else
                   desired_samplerate = src_samplerate;
               end
           end
           if(index2replace>0 && index2replace<=obj.num_channels)
               container_index = index2replace;
               obj.current_channel_index = container_index;
               
               if(~isempty(obj.parent_fig)&&~isempty(obj.main_axes) && all(ishandle([obj.parent_fig;obj.main_axes])))
                   obj.cell_of_channels{obj.current_channel_index} = CLASS_channel(...
                       data,...
                       src_label, source_indices,...
                       src_samplerate,desired_samplerate,...
                       container_index,...
                       obj.parent_fig,obj.main_axes);
                   
                   childobj = obj.getCurrentChild();
                   childobj.current_samples = obj.current_samples; %or childobj.setCurrentSamples(obj.current_smaples), but this calls a draw which may not be wanted
                   childobj.setupReferenceLines(obj.referenceline_contextmenu_h);
                   childobj.setupMainLine(obj.mainline_contextmenu_h);
                   
               else
                   obj.cell_of_channels{obj.current_channel_index} = CLASS_channel(...
                       data,...
                       src_label, source_indices,...
                       src_samplerate,desired_samplerate,...
                       container_index);
               end
               index_added = container_index;
           else
               index_added = [];
           end
       end
       
       % =================================================================
       %> @brief Sets current samples of all channel object instances,
       %> which internally refreshes the display.
       %> @param obj instance of CLASS_channels_container.
       %> @param new_samples indices to set current_samples to.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function setCurrentSamples(obj,new_samples)
           obj.current_samples = new_samples;
           for cur_index = 1:obj.num_channels
               obj.cell_of_channels{cur_index}.setCurrentSamples(new_samples); %calls draw internally
           end
       end
       
       % =================================================================
       %> @brief Refresh display of all non-hidden channels.
       %> @param obj instance of CLASS_channels_container.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function draw_all(obj)
           %draw all unhidden channels
           for cur_index = 1:obj.num_channels
               if(~obj.cell_of_channels{cur_index}.hidden)
                   obj.cell_of_channels{cur_index}.draw();
               end;
           end;
       end
       
       % =================================================================
       %> @brief Specify if a channel should display filtered data or not.
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index Index of channel to draw events for.
       %> @param show_boolean TRUE to show filtered, False otherwise.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function setShowFiltered(obj, channel_index, show_boolean)
           channelObj = obj.getChannel(channel_index);
           if(~isempty(channelObj))
               channelObj.set_show_filtered(show_boolean);
           end
       end
       
       % =================================================================
       %> @brief Flags a channel's events for display.
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index Index of channel to draw events for.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function setDrawEvents(obj,channel_index)
           if(nargin>1)
               if(channel_index<=obj.num_channels && channel_index>0)
                   channelObj = obj.getChannel(channel_index);
                   channelObj.draw_events = true;
               end
           else
               for channel_index =1:obj.num_channels
                   channelObj = obj.getChannel(channel_index);
                   channelObj.draw_events = true;
               end
           end
       end
       
       % =================================================================
       %> @brief getCurrentData returns the data for the current samples
       %> (e.g. the epoch shown).
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index - the index of the channel to retrieve data
       %> from
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function data = getCurrentData(obj, channel_index)
           %returns data for the current epoch
           data = obj.getData(channel_index, obj.current_samples);
       end
       
       % =================================================================
       %> @brief getData - returns the signal data for the specified
       %> channel.
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index - index of the channel to get data from
       %> @param optional_range - a range to pull data from if desired
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function data = getData(obj, channel_index, optional_range)
           %returns filter_data from channel at channel_index if it exists
           %otherwise returns raw_data from that channel
           channelObj = obj.getChannel(channel_index);
           if(~isempty(channelObj))
               %made this  a separate section of code rather than just
               %putting a data = data(optional_range) at the bottom since
               %we are dealing with so much memory here, I want to cut back
               %on the overhead processing when it is not necessary and can
               %be handled with a little extra code ~duplication.
               if(nargin==3 && ~isempty(optional_range))
                   data = channelObj.getData(optional_range);
               else
                   data = channelObj.getData();
               end
           else
               data =[];
           end
           
       end
       % =================================================================
       %> @brief getSamplerate returns the sample rate of specfied channel
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index index of the channel to get sample rate
       %> from.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function samplerate = getSamplerate(obj, channel_index)
           %returns samplerate from channel at channel_index
           if(channel_index<=obj.num_channels && channel_index>0)
               samplerate = obj.cell_of_channels{channel_index}.samplerate;
           else
               samplerate = [];
           end
           
       end
       
       % =================================================================
       %> @brief Apply a digital signal processing filter to a channel
       %> object.  
       %> @param obj instance of CLASS_channels_container.
       %> @param filterArrayStruct A vector of filterStructs. 
       %> filterStruct is a struct with the following fields
       %> - filter_path (the path where the filter functions are; e.g. sev.filter_path
       %> - src_channel_index   The index of the event_container EDF channel)
       %> - src_channel_label   Cell label of the string that holds the EDF channel label
       %> - m_file              MATLAB filename to use for the filtering (feval)
       %> - ref_channel_index   The index or indices of additional channels to use as a reference when and where necessary
       %> - ref_channel_label   Cell of strings that hold the EDF channel label associated with the ref_channel_index
       %> - src_channel_index: 1
       %> - src_channel_label: 'C3-M2'
       %> - filter: 'anc_rls.m'
       %> - ref_channel_index: [1 1]
       %> - ref_channel_label: {'C3-M2'  'C3-M2'}
       %> @note The filter struct should be verified against the existing
       %> structure for each event and only applied if/as different.
       %> This checking is carried out at the next level down in the
       %> channel_class objects.           
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function filter(obj, filterArrayStruct)
           global MARKING;
           src_indices = cell(numel(filterArrayStruct),1);
           [src_indices{:}]=filterArrayStruct.src_channel_index;
           src_indices = cell2mat(src_indices);
           
           for chan_index = 1:obj.num_channels
               filterS = filterArrayStruct(src_indices==chan_index);
               if(~isempty(filterS))
                   emptyFilters = false(size(filterS));
                   
                   for f=1:numel(filterS) %multiple filters per channel allowed
                       
                       %go through any reference channels required by the
                       %filter struct (e.g. adaptive noise cancellation
                       %requires a reference channel to adapt with
                       refs = filterS(f).ref_channel_index;
                       num_refs = numel(refs);
                       if(num_refs>0)
                           ref_data = zeros(numel(obj.getChannel(refs(1)).raw_data),num_refs);
                           for r=1:num_refs
                               ref_data(:,r) = obj.getData(refs(r));
                           end
                           filterS(f).ref_data = ref_data;
                       else
                           filterS(f).ref_data = [];
                       end
                       emptyFilters(f) = isempty(filterS(f).m_file);
                   end
                   filterS = filterS(~emptyFilters);
                   obj.cell_of_channels{chan_index}.filter(filterS);
                   %if not in batch mode then update the events for adjusted
                   %channels....
                   if(~isfield(MARKING.STATE,'batch_process_running') || isfield(MARKING.STATE,'batch_process_running')&&~MARKING.STATE.batch_process_running)
                       event_indices = obj.cell_of_channels{chan_index}.event_indices_vector;
                       for k = 1:numel(event_indices)
                           %run the update event callback
                           disp('update events manually to reflect changes due to filtering');
                           %                          obj.EVENT_CONTAINER.refresh(event_indices(k));
                       end
                   end
               end
           end
           
           emptyFilterInputs = false(size(filterArrayStruct));
           for f=1:numel(emptyFilterInputs)
               emptyFilterInputs(f) = isempty(filterArrayStruct(f).m_file);
           end
           obj.filterArrayStruct = filterArrayStruct(~emptyFilterInputs);
       end
       
       
       
       % =================================================================
       %> @brief Removes a CLASS_event object's association with a CLASS_channel object.
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index Index of the channel to remove the event
       %> from.
       %> @param event_index Index of the CLASS_events_container event to
       %> disassociate from the channel at channel_index.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function remove_event(obj,channel_index,event_index)
           %removes the event at event_index in the channel at channel_index
           obj.cell_of_channels{channel_index}.remove_event(event_index);
       end
       
       % =================================================================
       %> @brief Associates a CLASS_event object with a CLASS_channel object.
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index Index of the channel to add an event to.
       %> @param event_index Index of the CLASS_events_container event to
       %> associate with the channel at channel_index.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function add_event(obj,channel_index,event_index)
           obj.cell_of_channels{channel_index}.add_event(event_index);
           obj.cell_of_channels{channel_index}.draw();  %we just added an event, so update the view
       end
       
       % =================================================================
       %> @brief Compute statistic of a selected region of chanel data.
       %> @param obj instance of CLASS_channels_container.
       %> @param chanel_index Index of the channel to copy from.
       %> @param ROI vector of sample indices to copy (optional)
       %> @note If not used, the default is current_samples.
       %> @retval stats is a struct with the fields
       %> - table_data - for putting into a uitable
       %> - table_row_names - string labels for each row
       %> - table_column_names - column_names
       % =================================================================
       function stats = getStats(obj,channel_index,ROI)
           %ROI is the region of interest
           
           if(channel_index<=obj.num_channels)
               if(nargin>2)
                   range=ROI;
               else
                   range = obj.current_samples;
               end
               data = obj.getData(channel_index,range);
               stats = CLASS_channel.data2stats(data);
               for r=1:numel(stats.table_row_names)
                   stats.table_row_names{r} = strrep(stats.table_row_names{r},'Data',obj.getChannelName(channel_index));
               end
           else
               stats = []; %fail silently
           end;
           
       end
       % =================================================================
       %> @brief Copy a selected region of chanel data to the clipboard.
       %> @param obj instance of CLASS_channels_container.
       %> @param chanel_index Index of the channel to copy from.
       %> @param ROI vector of sample indices to copy (optional)
       %> @note If not used, the default is current_samples.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function varargout = copy2clipboard(obj,channel_index,ROI)
           if(channel_index<=obj.num_channels)
               if(nargin>2)
                   range=ROI;
               else
                   
                   range = obj.current_samples;
               end
               data = obj.getData(channel_index,range);
               clipboard('copy',data);
               disp([num2str(numel(range)),' items copied to the clipboard.  Press Control-V to access data items, or type "str=clipboard(''paste'')"']);
               if(nargout==1)
                   varargout{1}=data;
               end;
           else
               
           end;
           
       end
       % =================================================================
       %> @brief Copy a channel's data to workspace.
       %> Send the channel at index channel_index to the workspace
       %> variable.
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index Index of the channel to copy from.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function copy2workspace(obj,channel_index)
           
           if(channel_index<=obj.num_channels)
               data = obj.getData(channel_index);
               chanName = obj.getChannelName(channel_index);
               chanName = strrep(chanName,'/','_');
               chanName = strrep(chanName,'\','_');
               chanName = strrep(chanName,' ','_');
               assignin('base',chanName,data);
               uiwait(msgbox(sprintf('Channel data saved to workspace variable %s',chanName)));
           else
               errordlg(sprintf('The channel index (%u) is not in an acceptable range',channel_index));
           end;
           
       end
       % =================================================================
       %> @brief Hide channels from view.
       %> @param obj instance of CLASS_channels_container.
       %> @param channels2hide Vector of channel indices to hide.
       %> @retval obj instance of CLASS_channels_container.
       % =================================================================
       function hide(obj,channels2hide)
           for k=1:numel(channels2hide)
               channel_index = channels2hide(k);
               if(channel_index <=obj.num_channels)
                   obj.cell_of_channels{channel_index}.hide;
               end;
           end;
       end
       
       % =================================================================
       %> @brief getChannelName - return the name/label of a channel
       %> @param obj instance of CLASS_channels_container.
       %> @param channel_index index of the channel to get name of
       %> @retval channelName - string of the channel name
       % =================================================================
       function channelName = getChannelName(obj, channel_index)
           %get the name of a single, selected channel at channel_index
           if(channel_index>0 && channel_index <=obj.num_channels)
               channelName = obj.cell_of_channels{channel_index}.EDF_label;
           else
               channelName = [];
           end
       end
       
       % =================================================================
       %> @brief getChannelNames return names of all channels
       %> @param obj instance of CLASS_channels_container.
       %> @retval cell_of_names = cell of channel names
       % =================================================================
       function cell_of_names = getChannelNames(obj)
           %get a cell of the channel names avaialable;
           %an alias for get_labels
           cell_of_names = obj.get_labels();
       end
       
       % =================================================================
       %> @brief get_labels same as getChannelNames
       %> @param obj instance of CLASS_channels_container.
       %> @retval cell_of_names = a cell of channel names as strings
       % =================================================================
       function cell_of_names = get_labels(obj)
           cell_of_names = cell(obj.num_channels,1);
           for k = 1:obj.num_channels
               cell_of_names{k} = obj.cell_of_channels{k}.EDF_label;
           end
       end
       
       
       
    end
end