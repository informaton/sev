%> @file CLASS_channel.m
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
    properties
        %> sets 0 position of the data along the y-axes.
        line_offset; 
        %> user defined title
        title; 
        %> label from the edf for this channel when applicable (i.e.
        %> non-synthetic channel)
        EDF_label; 
        %> numeric index (start at 1) for this channel in the EDF  when
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
        %> outputStruct.src_channel_index = [];
        %>            .src_channel_label = [];
        %>            .m_file = [];
        %>            .ref_channel_index = [];
        %>            .ref_channel_label = {};
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
        %> vector into a global instance of events_container_class of the
        %> events associated with this channel
        event_indices_vector; 
        %> for the actual line that will be drawn.
        line_handle; 
        %> current_samples selected for display   (used to be range)
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
        %> 3 element vector (x,y,z) for the label's position relative to the
        %> axes...
        label_position; 
        reference_line_offsets;
        reference_line_color;
        reference_line_handles;
        %> two element vector of text handles that describe the position of
        %> the reference lines
        reference_text_handles; 
        %> flag that indicates whether this channel is being repositioned
        %by the user (useful to know if the events needed to be updated because of a new offset -  or settings applied
        repositioning; 
         %> flag to draw_events;
        draw_events;
        %> axes to render to 
        parent_axes; 
        %> handle of parent figure where mouse events are assigned
        parent_fig; 
        %> handle to the figure used to display summary_stats for this
        %> channel, if necessary
        summary_stats_figure_h; 
        %> handle to the table which holds the summary_stats structure
        summary_stats_uitable_h; 
    end;
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
    methods        
        %> @brief filter channel according to properties of filterStructIn.
        %> filtered data is stored in obj.filter_data
        %> @param obj instance of CLASS_channel class.
        %> @param filterStruct is an array structure with the following fields
        %>   - .src_channel_index = [];
        %>   - .src_channel_label = [];
        %>   - .m_file = [];
        %>   - .ref_channel_index = [];
        %>   - .ref_channel_label = {};
        %>   - .params
        %> @note side effect is to set draw_filtered boolean variable depending
        %> on wether filterStruct is empty or not.
        function obj = filter(obj, filterStructIn)
          
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
                          
                          %handle the case where parameters are passed in
                          %from previous settings
                          if(~isempty(filterS.params)) 
                              filterS.params.samplerate = obj.samplerate; %needed at times in filters where the data is sent directly - otherwise a blank argument is passed to the function which then loads the data itself
                              if(isempty(filterS.ref_channel_index))
                                  obj.filter_data =feval([filterS.filter_path(2:end),'.',filterS.m_file],obj.getData(),filterS.params);
                              else
                                  obj.filter_data =feval([filterS.filter_path(2:end),'.',filterS.m_file],obj.getData(),filterS.ref_data,filterS.params);
                              end
                          else
                              if(isempty(filterS.ref_channel_index))
                                  obj.filter_data =feval([filterS.filter_path(2:end),'.',filterS.m_file],obj.channel_index);
                              else
                                  obj.filter_data =feval([filterS.filter_path(2:end),'.',filterS.m_file],obj.channel_index,filterS.ref_channel_index);
                              end
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
        end;
        
        % =================================================================
        %> @brief assign class color property.
        %>
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
        %> @brief Remove a reference of a CLASS_events instance.
        %> @param obj instance of CLASS_channel class.
        %> @param event_index index of the CLASS_event to be removed, as maintained by an
        %> instance of CLASS_events_container.
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = remove_event(obj,event_index)
           obj.event_indices_vector(obj.event_indices_vector==event_index)=[]; 
        end
        
        % =================================================================
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = update_file_events_cell(obj,new_event_from_file_obj)
            if(~isempty(new_event_from_file_obj))
                if(isempty(obj.file_events_cell.start_stop_matrix))                    
                    obj.file_events_cell = new_event_from_file_obj;
                    if(~isempty(obj.file_events_cell))
                        obj.file_events_cell.create_linehandles(get(obj.line_handle,'parent'),'k');
                    end;
                 else
                     obj.event_object_cell.merge_new_object(new_event_from_file_obj);
                end;
            end;
        end;
        
        % =================================================================
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
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
        %> of CLASS_channel.
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
            [obj.PSD.magnitude obj.PSD.x obj.PSD.nfft] = calcPSD(obj.getData(psd_range),obj.samplerate,obj.PSD);
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
         %calculates the power spectrum using MUSIC for the entire data set
        function [S,F,nfft] = calculate_PMUSIC(obj,optional_range,optional_MUSIC_settings)
            global MUSIC;
            if(nargin<=1)
                MUSIC_range = 1:numel(obj.raw_data);
            else
            
                if(isempty(optional_range))
                    MUSIC_range = 1:numel(obj.raw_data);
                else
                    MUSIC_range = optional_range;
                end
            end;
            if(nargin<=3)
                MUSIC_settings = optional_MUSIC_settings;
            else
                MUSIC_settings = MUSIC;
            end
            obj.MUSIC = MUSIC_settings;
            [obj.MUSIC.magnitudes obj.MUSIC.freq_vec obj.MUSIC.nfft] = calcPMUSIC(obj.getData(MUSIC_range),obj.samplerate,obj.MUSIC);
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        %only first four parameters are required if not using graphics -
        %i.e. just doing a batch mode processing and want a lite
        %constructor
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
                    b = fir1(100,0.5);
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
                    'userdata',obj.channel_index,'position',[nan nan 0]);
            end
        end

        % =================================================================
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function setCurrentSamples(obj,current_samples)
            %could do checking here, but do not want the slowdown...
            obj.current_samples = current_samples;
            if(~obj.hidden)
                obj.draw();
            end
        end
        % =================================================================
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = setReferenceLineColor(obj,new_color)
            reference_handles = [obj.reference_line_handles;obj.reference_text_handles];            
            if(all(ishandle(reference_handles)))
                set(reference_handles,'color',new_color);
            end            
        end
        
        % =================================================================
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function text_buttonDownFcn(obj, hObject,eventdata)
            %enables editing of the current text label            
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function set_show_filtered(obj,show_boolean)
            obj.show_filtered = show_boolean==1;
            obj.draw();
        end
        % =================================================================
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function setLineOffset(obj,new_lineoffset)
            obj.line_offset = new_lineoffset;
            obj.repositioning = true;
            obj.draw()
        end
        
        % =================================================================
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function draw(obj,varargin)
            if(obj.show_filtered)
                obj.draw_filtered(varargin{:});
            else
                obj.draw_raw(varargin{:});
            end
        end
        % =================================================================
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
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
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
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
        
        % =================================================================
        %> @brief 
        %> @param obj instance of CLASS_channel class.
        %> @param 
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function savePSD2txt(obj, savefilename,optional_PSD_settings)
            global BATCH_PROCESS;
            global EVENT_CONTAINER;
            global STATE;
            global ARTIFACT_CONTAINER;
            global MARKING;
            if(~isempty(STATE) && isfield(STATE,'batch_process_running' && STATE.batch_process_running))
                BATCH_JOB = true;
            else
                BATCH_JOB = false;
            end
            if(BATCH_JOB)
                standard_epoch_sec = BATCH_PROCESS.standard_epoch_sec;
                batch_id = BATCH_PROCESS.start_time;
                num_events = ARTIFACT_CONTAINER.num_events;
            else
                batch_id = '0';
                standard_epoch_sec = MARKING.sev.standard_epoch_sec;
                num_events = numel(obj.event_indices_vector); %number of events associated with this channel...  %this would be different for batch processing where all events might be desired
            end
            try
                if(isempty(obj.PSD)||nargin>2)
                    if(nargin<=2)
                        obj.calculate_PSD();
                    else
                        obj.calculate_PSD(optional_PSD_settings);  
                    end
                end;
                
                y = obj.PSD.magnitude;
                rows = size(y,1);
                
                study_duration_in_seconds = numel(obj.raw_data)/obj.samplerate;
                E = floor(0:obj.PSD.interval/standard_epoch_sec:(study_duration_in_seconds-obj.PSD.FFT_window_sec)/standard_epoch_sec)'+1;
                S = MARKING.sev_STAGES.line(E);
                
                %     no_artifact_label = '-';

                evt_ind = false(numel(E),num_events);
                evtLabels=repmat('_',size(evt_ind)); %initialize to blanks
                for k = 1:num_events
                    if(BATCH_JOB)
                        eventMat = ARTIFACT_CONTAINER.cell_of_events{k}.start_stop_matrix;
                    else
                        eventMat = EVENT_CONTAINER.cell_of_events{obj.event_indices_vector(k)}.start_stop_matrix;
                    end
                    
                    %periodogram_epoch refers to an epoch that is measured in terms of
                    %the periodogram length and not a 30-second length
                    evts_per_periodogram_epoch = sample2epoch(eventMat,obj.PSD.interval,obj.samplerate);
                    
                    %need to handle the overlapping case differently here...
                    if(obj.PSD.FFT_window_sec~=obj.PSD.interval)
                        %window_sec must be greater than interval_sec if they are not
                        %equal - this is ensured in the PSD settings GUI - though
                        %adjusting the parametes externally may cause trouble!
                        overlap_sec = ceil(obj.PSD.FFT_window_sec-obj.PSD.interval);
                        evts_per_periodogram_epoch(2:end,1) = evts_per_periodogram_epoch(2:end,1)-overlap_sec;
                    end;
                    
                    %assign the corresponding column of A to the artifacts indices
                    %found in the current artifact method
                    for r = 1:size(evts_per_periodogram_epoch,1)
                        evt_ind(evts_per_periodogram_epoch(r,1):evts_per_periodogram_epoch(r,2),k)=true; %ARTIFACT_CONTAINER.cell_of_events{k}.batch_mode_score;                        
                    end;
                    evtLabels(evt_ind(:,k),k) = 'X'; % EVENT_CONTAINER.getLabel();
                    %         ArtifactBool(A_ind(:,k)) = 1;
                end
                
                evtBool = sum(evt_ind,2)>0;
                
                if(BATCH_JOB)
                    samples_per_artifact = obj.PSD.interval*obj.samplerate;
                    artifact_mat = find(evtBool);
                    artifact_mat = [(artifact_mat-1)*samples_per_artifact+1,artifact_mat*samples_per_artifact];
                    if(BATCH_PROCESS.output_files.cumulative_stats_flag)
                        batch.updateBatchStatisticsTally(obj.samplerate,artifact_mat);
                    end
                    if(BATCH_PROCESS.output_files.individual_stats_flag) %artifact statistics
                        batch.saveArtifactandStageStatistics(obj.samplerate,artifact_mat);
                    end
                end

                fout = fopen(savefilename,'w');
                
                analysis_CHANNEL_label = obj.EDF_label;
                fprintf(fout,['#Power Spectral Density values from FFTs with the following parameters: (Batch ID: %s)\r\n'...
                    ,'#\tCHANNEL:\t%s\r\n'...
                    ,'#\twindow length (seconds):\t%0.1f\r\n'...
                    ,'#\tFFT length (samples):\t%i\r\n'...
                    ,'#\tFFT interval (taken every _ seconds):\t%0.1f\r\n'...
                    ,'#\tInitial Sample Rate(Hz):\t%i\r\n'...
                    ,'#\tFinal Sample Rate(Hz):\t%i\r\n'...
                    ,'%s\tSlow\tDelta\tTheta\tAlpha\tSigma\tBeta\tGamma\tMean0_30\tSum0_30\tA\tA_type\tS\tE\r\n'],batch_id,analysis_CHANNEL_label,obj.PSD.FFT_window_sec,obj.PSD.nfft,obj.PSD.interval...
                    ,obj.src_samplerate,obj.samplerate...
                    ,num2str(obj.PSD.x,'\t%0.001f'));%'\t%0.1f'
                %     fclose(fout);
                
                %obj.PSD.x is a row vector, delivered by calcPSD
                freqs = obj.PSD.x;
                slow = mean(y(:,freqs>0&freqs<4),2); %mean across the rows to produce a column vector
                
                delta = sum(y(:,freqs>=0.5&freqs<4),2); %mean across the rows to produce a column vector
                theta = sum(y(:,freqs>=4&freqs<8),2);
                alpha = sum(y(:,freqs>=8&freqs<12),2);
                sigma = sum(y(:,freqs>=12&freqs<16),2);
                beta  = sum(y(:,freqs>=16&freqs<30),2);
                gamma = sum(y(:,freqs>=30),2);
                
                mean0_30  = mean(y(:,freqs>0&freqs<=30),2);
                sum0_30  = sum(y(:,freqs>0&freqs<=30),2);
                
                y = [y, slow, delta, theta, alpha, sigma, beta, gamma, mean0_30, sum0_30, evtBool];
                
                numeric_output_str = [repmat('%0.4f\t',1,size(y,2)),repmat('%c',1,size(evtLabels,2)),'\t%u\t%u\r\n'];
                
                yall = [y,evtLabels+0,S,E];
                
                fprintf(fout,numeric_output_str,yall');
                
                %     tic
                %     for row = 1:r
                %         fprintf(fout,numeric_output_str,y(row,:),ArtifactLabels(row,:),S(row),E(row));
                %     end;
                %     toc
                
                fclose(fout);
                %     tic
                %     save(fullfile(BATCH_PROCESS.output_path,filename_out),'y','-tabs','-ASCII','-append');
                %     toc
                fprintf(1,'%i %0.04f-second periodograms saved to %s\n',rows,obj.PSD.FFT_window_sec,savefilename);
                
                
            catch ME
                %     warnmsg = ME.message;
                %     stack_error = ME.stack(1);
                %     warnmsg = sprintf('%s\r\n\tFILE: %s\f<a href="matlab:opentoline(''%s'',%s)">LINE: %s</a>\fFUNCTION: %s', warnmsg,stack_error.file,stack_error.file,num2str(stack_error.line),num2str(stack_error.line), stack_error.name);
                %     disp(warnmsg);
                rethrow(ME);
            end;
        end        
    end %end methods
    
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
