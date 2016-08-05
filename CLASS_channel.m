%> @file CLASS_channel.cpp
%> @brief CLASS_channel used by SEV for handling polysomnogram channels.
% ======================================================================
%> @brief CLASS_channel used by SEV for handling polysomnogram channels.
%> The CLASS_channel class is designed for storage and manipulation of
%> PSG channel data for use with the SEV.
%
%> channel_class will be used by the SEV.  It will hold the different
%> EEG/channels that have been loaded by an EDF.
%> Written by Hyatt Moore IV
%> modified 10.6.2012
%> modified 11.20.2012 - filter() updated to pass getData() directly to
%> feval(filterFcn,... to avoid global CLASS_Channels_container usage in
%> the filterFcn which references the index, but does not yet exist
%> globally when using batch mode since the batch mode processing is
%> creating the synthetic file first.
% ======================================================================
classdef CLASS_channel < handle
    %look for *REMOVE* to remove older files that may no longer be in use.
    % The were removed on 6/13/2014            
    % 1.  function obj = update_file_events_cell(obj,new_event_from_file_obj)
    % 2.  function savePSD2txt(obj, savefilename,optional_PSD_settings)
        
    properties
        %> sets 0 position of the data along the y-axes.
        line_offset; 
        %> user defined title
        title; 
        %> @brief label from the edf for this channel when applicable (i.e.
        %> non-synthetic channel)
        EDF_label; 
        %> @brief numeric index (start at 1) for this channel in the EDF  when
        %> applicable (i.e. non-synthetic channel)
        EDF_index;
        %> index of this object in a cell of objects of this class
        channel_index;
        %> when a channel is synthesized, I want to know from where
        synth_src_container_indices;  
        %> the EDF channel data that was loaded
        raw_data; 
        %> used to store raw_data that has been filtered
        filter_data;
        %> @brief array struct of filter rules that are applied to the raw data
        %> the filterStruct is obtained from prefilter_dlg and
        %> has the following fields
        %> - outputStruct.src_channel_index = [];
        %> - src_channel_label = [];
        %> - m_file = [];
        %> - ref_channel_index = [];
        %> - ref_channel_label = {};
        filterStruct;
        %> boolean value, set to true when the user wants to see fitered version of signal             
        show_filtered; 
        %> sampling rate that it was loaded at in Hz
        samplerate; 
        %> initial sampling rate obtained from the PSG source file (e.g. EDF)
        src_samplerate; 
        %> boolean for whether it is displayed or not...
        hidden; 
        %> stores the pmusic spectrum when applicable
        MUSIC; 
        %> stores the power spectral density values and parameters used...
        PSD;
        %> @brief vector into a global instance of events_container_class of the
        %> events associated with this channel
        event_indices_vector; 
        %> for the actual line that will be drawn.
        line_handle; 
        %> @brief current_samples selected for display   (used to be range)
        %> range of values currently used for drawing (range(1) is the leftmost sample, range(end) is the right most sample)
        current_samples; 
        %> scales the raw_data by this value when plotted
        scale;  
        %> color of the lines/text when plotted
        color; 
        %> for the label
        text_handle; 
        %> used for how far away the label/title will be        
        label_offset; 
        %> @brief 3 element vector (x,y,z) for the label's position relative to the
        %> axes...
        label_position; 
        %> @brief The offset (in uV) to draw reference lines up and below the
        %channel's signal.  A value of 0 indicates on reference lines are
        %drawn (numeric).  
        reference_line_offsets;
        %> Color of the reference line (string)
        reference_line_color;
        %> MATLAB line handles for the reference lines
        reference_line_handles;
        %> @brief two element vector of text handles that describe the position of
        %> the reference lines
        reference_text_handles; 
        %> @brief flag that indicates whether this channel is being repositioned
        %> by the user (useful to know if the events needed to be updated because of a new offset -  or settings applied
        repositioning; 
         %> flag to draw_events;
        draw_events;
        %> axes to render to 
        parent_axes; 
        %> handle of parent figure where mouse events are assigned
        parent_fig; 
        %> @brief handle to the figure used to display summary_stats for this
        %> channel, if necessary
        summary_stats_figure_h; 
        %> handle to the table which holds the summary_stats structure
        summary_stats_uitable_h; 
    end;
    
    methods      
        
        % =================================================================
        %> @brief Constructor
        %> @param raw_data Time series signal data for the channel (numeric vector)
        %> @param src_title Name of the channel as obtained from a source file (e.g. .EDF) (string)
        %> @param src_channel_index Index of the channel data as obtained
        %> from the source file (e.g. an .EDF file is a multiplexed file with
        %> many signals; src_channel_index is the index of the channel that raw_data is obtained from in that file)
        %> @param src_samplerate Sample rate of data as determined/obtained
        %> from the source file (e.g. .EDF).  Use 0 if the channel is synthesized and does not have a source file (numeric, unsigned integer)
        %> @param desired_samplerate Sample rate that the channel should be
        %> converted to (unsigned numeric)
        %> @param container_index Index of channel instance as stored in a
        %> container object (i.e. CLASS_events_container).
        %> @param parent_fig MATLAB figure handle for displaying and interacting with the channel data
        %> @param parent_axes MATLAB axes handle where the data is
        %> displayed and interacted with (i.e. to hold the line handle and
        %> context menus of the channel).
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        % only first four parameters are required if not using graphics -
        % i.e. just doing a batch mode processing and want a lite
        % constructor
        function obj = CLASS_channel(raw_data,...
                src_title,src_channel_index,...
                src_samplerate,desired_samplerate,...
                container_index,...
                parent_fig,parent_axes)
            %userdata is a unique identifier (index) to an instantiation of this obj
            %to be used with line and tex handles so that it can reference
            %this object from other callbacks.
            obj.repositioning = false; %the channel is not being repositioned by the user at time of construction
            obj.draw_events = false; %don't need to draw any events at construction - no events associated at time of construction
            obj.PSD = [];
            obj.MUSIC = [];
            obj.src_samplerate = src_samplerate;
            
            [N,D] = rat(desired_samplerate/src_samplerate);
            if(N~=D)
                if(numel(raw_data)>0)
                    %                     b = fir1(100,0.5);
                    %                     raw_data2 = filtfilt(b,1,raw_data);
                    raw_data = resample(raw_data,N,D); %resample to get the desired sample rate
                end;
            end;
            
            obj.title = src_title;
            obj.EDF_label = src_title;
            obj.EDF_index = src_channel_index;
            obj.raw_data = raw_data;
            obj.src_samplerate = src_samplerate;
            obj.samplerate = desired_samplerate;
            obj.filter_data = [];
            obj.summary_stats_figure_h = [];
            obj.summary_stats_uitable_h=[];
            obj.channel_index = container_index;
            obj.event_indices_vector = [];
            obj.synth_src_container_indices = []; %if a channel is synthesized, I want to know from what/where
            obj.show_filtered = false;

            if(nargin>=8 && all(ishandle([parent_fig;parent_axes])))
                obj.parent_fig = parent_fig;
                obj.parent_axes = parent_axes;
                
                map = colormap(obj.parent_axes);
                obj.color = map(obj.channel_index*2,:);
                obj.line_offset = 0;
                obj.reference_line_offsets = [0;0]; %these are little lines that you can draw next to the main signal to use as a reference value
                obj.hidden = false;
                obj.scale = 1;
                obj.label_offset = 30;
               
                obj.reference_line_color = [0.23 0.44 0.34];

                obj.text_handle = text('parent',obj.parent_axes,'visible','on',...
                    'handlevisibility','on','ButtonDownFcn',@obj.text_buttonDownFcn,...
                    'color',obj.color,'string',obj.title,'interpreter','none',...
                    'userdata',obj.channel_index,'position',[0 0 0]);
            end
        end
        
        
        
        % =================================================================
        %> @brief filter channel according to properties of filterStructIn.
        %> filtered data is stored in obj.filter_data
        %> @param obj instance of CLASS_channel class.
        %> @param filterStruct is an array structure with the following fields
        %> @li @c .src_channel_index = [];
        %> @li @c .src_channel_label = [];
        %> @li @c .m_file = [];
        %> @li @c .ref_channel_index = [];
        %> @li @c .ref_channel_label = {};
        %> @li @c .params
        %> @note side effect is to set draw_filtered boolean variable depending
        %> on wether filterStruct is empty or not.
        % =================================================================
        function obj = filter(obj, filterStructIn)
          
            try
                if(isempty(filterStructIn))
                    
                    obj.filterStruct = filterStructIn;
                    obj.filter_data = [];
                    obj.show_filtered = false;
                else
                    %check if I have a filterStruct already and then only update if
                    %it is different,
                    numNewFilters = numel(filterStructIn);
                    numOldFilters = numel(obj.filterStruct);
                    %               firstDifference = numel(obj.filterStruct)+1; % will be 1 if obj.filterStruct is empty, which is what we want
                    filterdifferences = false(numNewFilters,1);
                    %check if we have the same filterStruct coming is as already
                    %an instance variable of our class.  If so, we do not want to
                    %repeat our work.
                    if(~isempty(obj.filterStruct))
                        if(numNewFilters<numOldFilters)
                            filterdifferences = true;
                        else
                            if(numNewFilters>numOldFilters)
                                filterdifferences(numOldFilters+1) = true; %there is guaranteed to be a difference the newest filter addition
                            end
                            for k=1:min(numNewFilters,numOldFilters)
                                if(~isequal(obj.filterStruct(k),filterStructIn(k)))
                                    filterdifferences(k) = true;
                                end
                            end
                        end
                        
                        %if no obj.filterStruct, then use the new one coming in.
                    else
                        filterdifferences = true; %just set to the first one
                    end
                    firstDifference = find(filterdifferences,1,'first');
                    
                    %if it is empty, then there is nothing different and no need
                    %to filter again.
                    if(~isempty(firstDifference))
                        if(firstDifference<=numel(obj.filterStruct))
                            firstDifference = 1;
                            obj.filter_data = [];
                        end
                        obj.show_filtered = true;
                        obj.filterStruct = filterStructIn;
                        for k=firstDifference:numNewFilters %just handle the new cases, or starting from number 1;
                            filterS = obj.filterStruct(k);
                            if(obj.channel_index==filterS.src_channel_index)
                                
                                filterFcn = [filterS.filter_path(2:end),'.',filterS.m_file];
                                
                                % handle case where parameters are not seen
                                % or passed in yet.
                                if(isempty(filterS.params))
                                    filterS.params = feval(filterFcn);
                                end
                                filterS.params.samplerate = obj.samplerate; %needed at times in filters where the data is sent directly - otherwise a blank argument is passed to the function which then loads the data itself
                                if(isempty(filterS.ref_channel_index))
                                    obj.filter_data =feval(filterFcn,obj.getData(),filterS.params);
                                else
                                    obj.filter_data =feval(filterFcn,obj.getData(),filterS.ref_data,filterS.params);
                                end
                                    
                                
                                
                                %make sure we stay with row vectors for
                                %consistency throughout gsev
                                if(size(obj.filter_data,2)>size(obj.filter_data,1))
                                    obj.filter_data = obj.filter_data';
                                end
                            end
                        end
                    end
                end
            catch me
                showME(me);
                obj.show_filtered = false;
                obj.filterStruct = [];
                rethrow(me);
            end
        end
        
        % =================================================================
        %> @brief assign class color property.
        %> @param obj instance of CLASS_channel class.
        %> @param newColor new color to assign, must be of handle property
        %> <i>color</i> type
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = setColor(obj,newColor)
            obj.color = newColor;
            set(obj.line_handle,'color',newColor);
            set(obj.text_handle,'color',newColor);
        end
        
        % =================================================================
        %> @brief Add reference of an existing CLASS_events instance.
        %> Newly added events will be associated and displayed with the
        %> channel object.
        %> @param obj instance of CLASS_channel class.
        %> @param event_index scalar index of the CLASS_event as maintained by an
        %> instance of CLASS_events_container.
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = add_event(obj,event_index)
            obj.draw_events = true;  
            if(~any(obj.event_indices_vector==event_index))
                obj.event_indices_vector(end+1)=event_index;
            end
        end;
        
        % =================================================================
        %> @brief Remove a reference of a CLASS_events instance by setting
        %> event_index of the event_indices_vector to null ([]).
        %> @param obj instance of CLASS_channel class.
        %> @param event_index index of the CLASS_event to be removed, as maintained by an
        %> instance of CLASS_events_container.
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = remove_event(obj,event_index)
           obj.event_indices_vector(obj.event_indices_vector==event_index)=[]; 
        end
        
        
        % =================================================================
        %> @brief Updates object parameters directly from the field/value
        %parameters provided in the input struct @e settings
        %> @param obj instance of CLASS_channel class.
        %> @param settings Struct with field-value pairs that are written
        %> directly into obj.
        %> @retval obj instance of CLASS_channel class.
        % =================================================================        
        function obj = loadSettings(obj,settings)
            fields = fieldnames(settings);
            for f=1:numel(fields)
                obj.(fields{f}) = settings.(fields{f});
            end
            obj.repositioning = true;
            if(~obj.hidden)
                obj.draw();
            end
        end
        
        % =================================================================
        %> @brief Returns a struct with saveable object parameter values.
        %> This is useful in saving settings between SEV calls.  See
        %> @e loadSettings
        %> @param obj Instance of CLASS_channel class.
        %> @retval settings Struct containing current parameter value pairs of obj
        % =================================================================
        function settings = getSettings(obj)
            settings.line_offset = obj.line_offset;
            settings.color = obj.color;
            settings.scale = obj.scale;
            settings.EDF_label = obj.EDF_label;
            settings.title = obj.title;
            settings.label_offset = obj.label_offset;
            settings.label_position = obj.label_position;
            settings.reference_line_offsets = obj.reference_line_offsets;
            settings.reference_line_color = obj.reference_line_color;
        end
        
        % =================================================================
        %> @brief Return raw or filtered signal data of the CLASS_channel
        %> instance.  All data may be returned or data in a range of
        %> interest.  Filtered data is returned if obj.show_filtered is
        %> true, otherwise raw data is returned (i.e. unfiltered).
        %> @param obj instance of CLASS_channel class.
        %> @param range_of_interest Vector of indices that include a range
        %> of indices to take data from (e.g. a start stop pair).
        %> @retval data
        % =================================================================
        function data = getData(obj, range_of_interest)
            if(nargin==2 && ~isempty(range_of_interest))                
                if(obj.show_filtered && ~isempty(obj.filter_data))
                    data = obj.filter_data(range_of_interest);
                else
                    data = obj.raw_data(range_of_interest);
                end
            else
                if(obj.show_filtered && ~isempty(obj.filter_data))
                    data = obj.filter_data;
                else
                    data = obj.raw_data;
                end
            end
        end
        
        % =================================================================
        %> @brief Calculates the power spectral density for this instance 
        %> of CLASS_channel using modified window, periodogram averaging.
        %> @param obj instance of CLASS_channel class.
        %> @param PSD_settings PSD settings to use.
        %> @param optional_sample_range Optional range to calculate the PSD
        %> over.  Otherwise the entire data set is calculated.  
        %> @retval S Vector of spectrum values corresponding to frequencies
        %> at F
        %> @retval F Vector of frequency values that the spectrum S is
        %> calculated at.
        %> @retval nfft Number of fast fourier transform taps used to calculate
        %> PSD with.
        % =================================================================
        %calculates the PSD for the entire data set
        function [S,F,nfft] = calculate_PSD(obj,PSD_settings,optional_sample_range)
            
            if(nargin<=2 || isempty(optional_sample_range))
                psd_range = 1:numel(obj.raw_data);
            else
                psd_range = optional_sample_range;
            end
            
            obj.PSD = PSD_settings;
            [obj.PSD.magnitude, obj.PSD.x, obj.PSD.nfft, obj.PSD.U_psd, obj.PSD.U_power] = calcPSD(obj.getData(psd_range),obj.samplerate,obj.PSD);
            if(nargout>0)
                S = obj.PSD.magnitude;
                if(nargout>1)
                    F = obj.PSD.x;
                    if(nargout>2)
                        nfft = obj.PSD.nfft;
                    end
                end
            end
            
        end
        
        % =================================================================
        %> @brief Calculates the power spectral density for the instance 
        %> of CLASS_channel using MUSIC.
        %> @param obj instance of CLASS_channel class.
        %> @param MUSIC_settings Struct of MUSIC settings to use.
        %> @param optional_sample_range Optional range to calculate the PSD
        %> over.  Otherwise the entire data set is calculated.  
        %> @retval S Vector of spectrum values corresponding to frequencies
        %> at F
        %> @retval F Vector of frequency values that the spectrum S is
        %> calculated at.
        %> @retval winlen Number of samples used to calculate spectrum from (i.e. the window length)
        %> @note obj.MUSIC is set to MUSIC_settings parameter.
        % =================================================================
         %calculates the power spectrum using MUSIC for the entire data set
        function [S,F,winlen] = calculate_PMUSIC(obj,MUSIC_settings,optional_sample_range)
           
            if(nargin<=2 || isempty(optional_sample_range))
                music_range = 1:numel(obj.raw_data);
            else
                music_range = optional_sample_range;
            end
            
            obj.MUSIC = MUSIC_settings;
            [obj.MUSIC.magnitudes obj.MUSIC.freq_vec obj.MUSIC.winlen] = calcPMUSIC(obj.getData(music_range),obj.samplerate,obj.MUSIC);
            if(nargout>0)
                S = obj.MUSIC.magnitudes;
                if(nargout>1)
                    F = obj.MUSIC.freq_vec;
                    if(nargout>2)
                        winlen = obj.MUSIC.winlen;
                    end
                end
            end
        end

        % =================================================================
        %> @brief Initialize reference line properties
        %> @param obj instance of CLASS_channel class.
        %> @param contextmenu_ref_line_h MATLAB contextmenu handle assigned
        %> to the reference lines that are created/configured.
        %> @retval obj instance of CLASS_channel class.
        %> @note obj parameter @e reference_line_handles and @e
        %> reference_text_handles are created and initialized.
        % =================================================================
        function obj = setupReferenceLines(obj,contextmenu_ref_line_h)
            obj.reference_line_handles = zeros(2,1);
            obj.reference_text_handles = zeros(2,1);

            set(contextmenu_ref_line_h,'userdata',obj.channel_index);
            
            obj.reference_line_handles(1) = line('uicontextmenu',contextmenu_ref_line_h,'parent',obj.parent_axes,'color',obj.reference_line_color,...
                'linestyle',':','visible','off','handlevisibility','on','userdata',obj.channel_index);
            obj.reference_line_handles(2) = line('uicontextmenu',contextmenu_ref_line_h,'parent',obj.parent_axes,'color',obj.reference_line_color,...
                'linestyle',':','visible','off','handlevisibility','on','userdata',obj.channel_index);
            obj.reference_text_handles(1) = text('parent',obj.parent_axes,'color',obj.reference_line_color,...
                'string',[],'visible','off','handlevisibility','on','interpreter','none','userdata',obj.channel_index);
            obj.reference_text_handles(2) = text('parent',obj.parent_axes,'color',obj.reference_line_color,...
                'string',[],'visible','off','handlevisibility','on','interpreter','none','userdata',obj.channel_index);
        end

        % =================================================================
        %> @brief Sets the current range of samples (i.e. the samples that
        %> are currently displayed on the screen to the user)
        %> @param obj instance of CLASS_channel class.
        %> @param current_samples Range of samples to set active (vector)
        %> @note Channel data in the range of @e current_samples is drawn
        %> if obj is not @e hidden.
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = setCurrentSamples(obj,current_samples)
            %could do checking here, but do not want the slowdown...
            obj.current_samples = current_samples;
            if(~obj.hidden)
                obj.draw();
            end
        end
        
        % =================================================================
        %> @brief Create and setup the line handle for displaying and
        %interacting with the raw data contained in obj.
        %> @param obj instance of CLASS_channel class.
        %> @param contextmenu_mainline_h MATLAB contextmenu handle for the
        %> main line (i.e. the channel data) (handle).
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = setupMainLine(obj,contextmenu_mainline_h)
            set(contextmenu_mainline_h,'userdata',obj.channel_index);  
            obj.line_handle = line('parent',obj.parent_axes,'color',obj.color,'linestyle','-','visible','on',...
                'handlevisibility','on','userdata',obj.channel_index,'ButtonDownFcn',@obj.line_buttonDownFcn,'uicontextmenu',contextmenu_mainline_h,...
                'xdata',[],'ydata',[]);
            set(obj.text_handle,'uicontextmenu',contextmenu_mainline_h);
        end
            
        
        % =================================================================
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function line_buttonDownFcn(obj,hObject, eventdata)
            %callback function used by CLASS_channel objects
            global CHANNELS_CONTAINER;
            global MARKING;
            CHANNELS_CONTAINER.current_channel_index = obj.channel_index;
            %             if(~strcmp(get(obj.parent_fig,'selectiontype'),'alt')) %'alt' refers to a ctrl-left mouse click or a right mouse click - which will activate the uicontextmenu
            
            if(strcmp(get(obj.parent_fig,'selectiontype'),'extend')) %if they are pressing shift or something...
                disp 'You are pressing shift or something like that';
            else
                
                if(MARKING.isActive())
                    MARKING.set_channel_index(obj.channel_index,hObject);
                    MARKING.startMarking();
                else
                    cur_pos = get(obj.parent_axes,'currentpoint');
                    %                                 function t = timeStamp(samplePt)
                    %samplePt is the current place within the sampled signal, it is the index
                    %handles are handles for the gui being used here
                    %t = is the datenum value returned for this place in time.
                    %             global WORKSPACE;
                    %             global DEFAULTS
                    %
                    samplePt = round(cur_pos(1));
                    t = MARKING.startDateTime;
                    t(end) = t(end) + samplePt/obj.samplerate;
                    t = datenum(t);
                    
                    timeStampStr = datestr(t,'HH:MM:SS.FFF');
                    disp(['You selected time '  timeStampStr]);
                    
                    if(obj.show_filtered && ~isempty(obj.filter_data))
                        value = obj.filter_data(samplePt);                        
                    else
                        value = obj.raw_data(samplePt);
                    end
                    click_str = sprintf('Time: %s \tValue: %0.1f \tIndex: %u\tScale: %0.2f',timeStampStr,value,samplePt,obj.scale);
                    handles = guidata(hObject);
                    set(handles.text_marker,'string',click_str);
                end;
            end;
            %             else
            %                 %a contextmenu will popup
            %             end;
        end


        

        % =================================================================
        %> @brief Set color of the channel's reference line.
        %> @param obj instance of CLASS_channel class.
        %> @param new_color Color to set reference line to (can be RGB
        %> vector or string with color name).
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = setReferenceLineColor(obj,new_color)
            reference_handles = [obj.reference_line_handles;obj.reference_text_handles];            
            if(all(ishandle(reference_handles)))
                set(reference_handles,'color',new_color);
            end            
        end
        
        % =================================================================
        %> @brief Enables editing of the current text label                
        %> @param obj instance of CLASS_channel class.
        %> @param hObject MATLAB callback object.
        %> @param eventdata Not used.
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function text_buttonDownFcn(obj, hObject,eventdata)
            %check to make sure we are not a contextmenu
        
            if(~strcmp(get(obj.parent_fig,'selectiontype'),'alt'))
                originalStr = get(hObject,'string');
                set(hObject,'editing','on');
                
                waitfor(hObject,'editing','off');
                
                newStr = deblank(get(hObject,'string'));
                if(isequal('',newStr))
                    set(hObject,'string',originalStr)
                else
                    set(hObject,'string',newStr);
                    obj.title = newStr;
                end;
            end
        end
        % =================================================================
        %> @brief Set choice to show filtered data or not show it.
        %> @param obj instance of CLASS_channel class.
        %> @param show_boolean (boolean) True is to show filtered data,
        %> otherwise it is not shown (raw data is shown)
        %> @retval obj instance of CLASS_channel class.
        %> @note draw() is called.
        % =================================================================
        function set_show_filtered(obj,show_boolean)
            obj.show_filtered = show_boolean==1;
            obj.draw();
        end
        
        % =================================================================
        %> @brief Draw filtered data to the screen.
        %> @param obj instance of CLASS_channel class.
        %> @param varargin
        %>    @le varargin{1} = x range of data to show
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function draw_filtered(obj, varargin)            
            obj.show();
            if(~isempty(obj.filter_data))
                if(numel(varargin)>0 && ~isempty(varargin{1}))
                    x = varargin{1};
                    y = obj.filter_data*obj.scale+obj.line_offset;
                else
                    x = obj.current_samples;
                    if(x(1)>numel(obj.filter_data)) %don't want to access something that is out of bounds
                        y = obj.filter_data*obj.scale+obj.line_offset;
                    else
                        y = obj.filter_data(x)*obj.scale+obj.line_offset;
                    end;
                end;
                obj.current_samples = x; %stores the last range that was used...
                
                set(obj.line_handle,'xdata',x,'ydata',y);
                
                text_extent = get(obj.text_handle,'extent');
                obj.label_position = [x(1)-text_extent(3)-10, obj.line_offset, 0];
                set(obj.text_handle,'position',obj.label_position);
                
                obj.draw_attached_events();
            else
                obj.show_filtered = false;
                obj.draw_raw(varargin{:});
            end
        end
        % =================================================================
        %> @brief Sets the vertical position of the channel data on the
        %> screen (i.e. vertical repositionning)
        %> @param obj instance of CLASS_channel class.
        %> @param new_lineoffset Vertical offset of channel data to use.
        %> @note obj.repositioning is set to @true and @obj.draw is called.
        % =================================================================
        function setLineOffset(obj,new_lineoffset)
            obj.line_offset = new_lineoffset;
            obj.repositioning = true;
            obj.draw()
        end
        
        % =================================================================
        %> @brief Draw filtered or raw data to the screen depending on the
        %> boolean parameter value .show_filtered
        %> @param obj instance of CLASS_channel class.
        %> @param varargin Passed to draw_filtered or draw_raw.
        % =================================================================
        function draw(obj,varargin)
            if(obj.show_filtered)
                obj.draw_filtered(varargin{:});
            else
                obj.draw_raw(varargin{:});
            end
        end
        % =================================================================
        %> @brief Draw raw signal data (i.e. data initially loaded to constructor from
        %> a source file or as synthesized).
        %> @param obj instance of CLASS_channel class.
        %> @param varargin
        %> @li varargin{1} current samples to draw.  If empty, then just
        %> use the object's @e current_samples parameter.
        % =================================================================
        function draw_raw(obj, varargin)
            if(obj.hidden)
                obj.show();
            end
            if(~isempty(obj.raw_data))
                if(numel(varargin)>0 && ~isempty(varargin{1}))
                    sample_indices = varargin{1};
                    obj.current_samples = sample_indices; %stores the last range that was used...  
                end
                sample_indices = obj.current_samples;
                
                if(sample_indices(end)>numel(obj.raw_data)) %don't want to access something that is out of bounds
                    y = NaN(size(sample_indices)); %don't draw anything...
                    ygood = obj.raw_data(sample_indices(1):numel(obj.raw_data))*obj.scale+obj.line_offset;
                    y(1:numel(ygood)) = ygood;
                else
                    y = obj.raw_data(sample_indices)*obj.scale+obj.line_offset;
                end;
                set(obj.line_handle,'ydata',y,'xdata',sample_indices,'color',obj.color);
                
                text_extent = get(obj.text_handle,'extent');
                obj.label_position = [sample_indices(1)-text_extent(3)-10, obj.line_offset, 0];
                set(obj.text_handle,'position',obj.label_position,'color',obj.color);                
                obj.draw_attached_events(); 
            end
        end

        % =================================================================
        %> @brief Draw events attached to the channel instance.
        %> @param obj instance of CLASS_channel class.
        %> @note Global EVENT_CONTAINER is used
        % =================================================================
        %show the events associated with this channel
        function draw_attached_events(obj)
            global EVENT_CONTAINER;
            if(obj.reference_line_offsets(1)>0)
                obj.draw_reference_lines();
            end;            
            
            %only draw/redraw when necessary - otherwise the events are
            %laid out already and do not need updating.
            if(obj.repositioning||obj.draw_events)
                EVENT_CONTAINER.updateYOffset(obj.event_indices_vector,obj.line_offset);
                obj.draw_events = false;
                obj.repositioning = false;
            end
            EVENT_CONTAINER.updateCurrentEpochStartX(obj.event_indices_vector,obj.current_samples(1));
        end;

        % =================================================================
        %> @brief Set the offset of the reference line associated with the
        %> channel class instance, obj.
        %> @param obj instance of CLASS_channel class.
        %> @param reference_offset Value of the offset reference lines; Use
        %> 0  to turn off (not draw).  A positive value is shown as +/- offset. 
        % =================================================================
        function setReferenceLineOffset(obj,reference_offset)
            if(nargin==2)
                obj.reference_line_offsets = [1; -1]*reference_offset;
            end
            if(all(obj.reference_line_offsets)==0)
                set(obj.reference_text_handles,'visible','off');
                set(obj.reference_line_handles,'visible','off');
            else
                set(obj.reference_text_handles(1),'string',[num2str(obj.reference_line_offsets(1)),' uV']);
                set(obj.reference_text_handles(2),'string',[num2str(obj.reference_line_offsets(2)),' uV']);
                set(obj.reference_text_handles,'visible','on');
                set(obj.reference_line_handles,'visible','on');
                
                obj.draw_reference_lines();
            end
        end
        
        % =================================================================
        %> @brief Draw the reference lines of the channel data.
        %> @param obj instance of CLASS_channel class.
        % =================================================================
        function draw_reference_lines(obj)
%             x = 1:numel(obj.current_samples);
            x = obj.current_samples;
            y = obj.reference_line_offsets(:)*ones(size(x))*obj.scale;  %2xnumel(obj.current_samples) matrix
            set(obj.reference_line_handles(1),'xdata',x,'ydata',obj.line_offset+y(1,:));
            set(obj.reference_line_handles(2),'xdata',x,'ydata',obj.line_offset+y(2,:));
            
            text_extent = get(obj.reference_text_handles(2),'extent');
            ref_label_position = [x(1)-text_extent(3)-20, obj.line_offset+y(1), 0];
            set(obj.reference_text_handles(1),'position',ref_label_position);
            ref_label_position = [x(1)-text_extent(3)-20, obj.line_offset+y(2), 0];
            set(obj.reference_text_handles(2),'position',ref_label_position);
        end
        
        % =================================================================
        %> @brief Show the channel data, reference line, and text handles
        %> (i.e. make sure their @e visible and @e handlevisibility
        %properties are set to @e on.
        %> @param obj instance of CLASS_channel class.
        %> @param varargin MATAB callback arguments (e.g. hObject,
        %> event_data, handles). - May not be necessary in current
        %> implementation.
        %> @retval obj instance of CLASS_channel class.
        %> @note global EVENT_CONTAINER is used and it's @e show method
        %> also called with the objects @e event_indices_vector.
        % =================================================================
        function obj = show(obj,varargin)
            %varargin so we can use this for a callback
            global EVENT_CONTAINER;
            obj.hidden = false;
            set(obj.line_handle,'handlevisibility','on','visible','on');
            set(obj.text_handle,'handlevisibility','on','visible','on');
            set(obj.reference_line_handles,'handlevisibility','on');
            set(obj.reference_text_handles,'handlevisibility','on');            
            obj.setReferenceLineOffset();            
            EVENT_CONTAINER.show(obj.event_indices_vector);                
        end
        
        % =================================================================
        %> @brief Hide the channel data, reference line, and text handles
        %> (i.e. make sure their @e visible and @e handlevisibility
        %> properties are set to @e off.
        %> @param obj instance of CLASS_channel class.
        %> @retval obj instance of CLASS_channel class.
        %> @note global EVENT_CONTAINER is used and it's @e hide method
        %> also called with the objects @e event_indices_vector.
        % =================================================================
        function obj = hide(obj)
            global EVENT_CONTAINER;
            obj.hidden = true;
            set(obj.line_handle,'handlevisibility','off','visible','off');
            set(obj.text_handle,'handlevisibility','off','visible','off');
            set(obj.reference_line_handles(1),'handlevisibility','off','visible','off');
            set(obj.reference_line_handles(2),'handlevisibility','off','visible','off');
            set(obj.reference_text_handles(1),'handlevisibility','off','visible','off');
            set(obj.reference_text_handles(2),'handlevisibility','off','visible','off');
            EVENT_CONTAINER.hide(obj.event_indices_vector);
        end
        
    
    end %end methods
    
    

    methods(Static)
        
        % ======================================================================
        %> @brief obtain struct of statistics and characterization from input data vector.
        %> Very useful for preparing data for description and presentation
        %in a uitable.
        %> @param data vector of values to calculate statistics over.
        %> @retval stats struct of statistics for the input data.  Fieldnames are:
        %> - table_row_names ({'Data', 'Abs(Data)'})
        %> - table_data for storing in 'data' field of a uitable (cell with
        %> stats taken from data as is and from absolute valued data.
        %> - table_column_names column labels for describing statistics,
        %which include:
        %> - <b>median</b>
        %> - <b>mean</b>
        %> - <b>avg_power</b> average power
        %> - <b>rms</b> root mean square
        %> - <b>variance</b>
        %> - <b>std</b> standard deviation
        %> - <b>entropy</b>
        % =================================================================
        function stats = data2stats(data)
            %ROI is the region of interest
            %stats is a struct with the fields
            %table_data - for putting into a uitable
            %table_row_names - string labels for each row
            %table_column_names - column_names
            table_column_names = {'median','mean','avg_power','rms','variance','std','entropy'};
            stats.table_data = cell(1,numel(table_column_names));
            stats.table_row_names = {'Data','Abs(Data)'};
            for r=1:numel(stats.table_row_names)
                
                for c=1:numel(table_column_names)
                    fname = table_column_names{c};
                    switch(fname)
                        case 'median'
                            datum = median(data);
                        case 'mean'
                            datum = mean(data);
                        case 'rms'
                            datum = sqrt(mean(data.*data));
                        case 'avg_power'                            
                            datum = mean(data.*data);                        
                        case 'variance'
                            datum = var(data);
                        case 'std'
                            datum = std(data);
                        case 'entropy'
                            p = abs(data)/sum(abs(data));
                            datum = sum(p.*log(p));
                        otherwise
                            fprintf(1,'%s unahndled\n',fname);
                            datum = [];
                    end
                    stats.table_data{r,c} = datum;
                end
                data = abs(data);
            end
            stats.table_column_names = table_column_names;
            
        end
        
    end
    
end%end class definition

% 
%       % Make a copy of a handle object.
%         function new = copy(this)
%             % Instantiate new object of the same class.
%             new = feval(class(this));
%  
%             % Copy all non-hidden properties.
%             p = properties(this);
%             for i = 1:length(p)
%                 new.(p{i}) = this.(p{i});
%             end
%         end
