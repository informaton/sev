%> @file CLASS_events.m
%> @brief CLASS_events used by SEV for characterizing pattern recognition algorithms.
% ======================================================================
%> @brief The constructor for this class takes the EDF index (i.e. chan_num) and
%> corresponding channel name (chan_name) with a two column matrix that
%> contains the start and stop indices for the events provided in the cell
%> message.  
%
%> Typically the constructor will receive a messageStr or cell with each
%> string being of the form source.event.quality
%> This message is parsed into its different elements based on the '.' token.
%> The start_stop_matrix 2 column matrix contains the start and stop sample
%> points of each event being listed.  To use memory efficiently, separate
%> parameters for each message portion are created of the same row length of
%> start_stop_matrix and contain the index into the msg_x_list that
%> corresponds to the event that occurred at that index.
% ======================================================================

% Written: Hyatt Moore IV
% last modified: 10/1/2012 - updated save2___ functions to include
% STAGES.cycles field

classdef CLASS_events < handle
    
    properties
        
        %> specifies the 0 position on the y-axes for the event to use as a
        %> reference when plotting
        vertical_offset_delta; 
        
        %> as seen in the EDF header
        channel_number;
        
        %> as seen in the EDF header
        channel_name;
        
        %> index into a parent CLASS_channel object that is associating with
        %> this event
        class_channel_index;
        
        %> sampling rate
        samplerate; 
        label;        
        
        %> the index of this event in terms of the event container object
        current_event_index;
        start_stop_matrix;
        batch_mode_label;        
        
        %> @brief the configuration identifier (1..M) for this event.  Output from
        %> detectors with configurable parameter settings can be uniquely identified in conjunction with this ID and the batch.saveDetectorConfigLegend.m function
        configID;
        
        %> @brief primary key for detectorinfo_t record an instance of this class
        %> is associated with
        detectorID;
        
        %> distance between patches/lines in an instance of this class
        evt_patch_spacing; 
        
        %> y value to draw the event patch at.
        evt_patch_y;
        
        %> @brief starting sample of the current sev display, where all of the
        %> channels and events begin from on the x-axis
        epoch_start_x; 
        evt_patch_height;
        
        %> @brief range over which to apply an roc comparison to between events -
        %> normally for manually loaded events
        roc_comparison_range; 
        
        %> where these things will be plotted too.
        parent_axes; 
        parent_fig;
        
        %> @brief vector of handles to lines (one for each source) - defined
        %> outside of the class and then assigned directly to this property
        evt_patch_h; 
        cur_color;
        
        %> @brief vector of handles to the textboxes that will contain the
        %> descriptions of these patches...
        label_h;
        
        %> handle to the context menu associated with this event
        contextmenu_evt_patch_h;
        
        %> @brief whether the element is visible or not (patch and labelhandle
        %> specifically)
        hidden; 
        
        %> @brief this is the parameters of interest for this event that will
        %> likely be saved later for post analysis
        paramStruct;
        
        %> handle to textbox that displays paramStruct values
        paramtexthandle;
        
        %> index of the fieldname to use
        paramFieldIndex;
        
        %> cell of fieldnames in paramStruct
        paramFieldNames;
        
        %> @brief structure of summary statistics calculated in
        %> calculate_summary_stats method and returned by get_summary_stats() method
        summary_stats_Struct; 
        %> @brief set to true whenever the object's event has been updated so that
        %> a new summary stats will be calculated before being returned
        summary_stats_needs_updating_Bool; 
        
        %> @brief struct that contains the following fields
        %> - .algorithm :  .m file/function call associated with creating this event...
        %> - .channel_indices : the channels that were used in creating
        %>   this event - as passed to the source.algorithm
        %> - .editor = 'none';
        %> - .sourceStruct.pStruct = pStruct;
        %>   pStruct is a plist struct whose fields and associated
        %>   values are specific to the parameters used in creating
        %>   the event when there is a .plist associated with the
        %>   event's creation detection algorithm.
        %>   pBatchStruct has the fields
        %>  -     .start -> start parameter value
        %>  -     .stop -> stop parameter value
        %>  -     .key -> name of the parameter/property field
        %>  -     .num_steps -> number of steps to take between the
        %>       start and stop value
        source;
    end
        
    methods
        
        % ======================================================================
        %> @brief Class constructor
        %>
        %> More detailed description of what the constructor does.
        %>
        %> @param param1 Description of first parameter
        %> @param anotherParam Description of the second parametere
        %>
        %> @return instance of the CLASS_events class.
        % =====================================================================        
        function obj = CLASS_events(events_start_stop_matrix,...
                event_label,...
                chan_name,...
                samplerate,...
                event_index,...
                num_events_in_channel,...
                parent_color,...
                EDF_channel_number,...
                class_channel_index,...
                source,...
                paramStruct,...
                parent_fig,...
                parent_axes)
            
            obj.configID = 0; %default is zero, this gets set externally in the batch_run function when there are 1 or more adjustable parameters for the parent event-detection method
            obj.detectorID = []; %default to null
            obj.channel_number = EDF_channel_number; 
            obj.class_channel_index =class_channel_index;

            obj.summary_stats_Struct = []; %default to empty
            obj.summary_stats_needs_updating_Bool = true; %updating necessary, since no summary stats calculated yet.
            obj.current_event_index = event_index;
            obj.label = event_label;
            obj.start_stop_matrix = events_start_stop_matrix;
            obj.samplerate = samplerate;
            
            obj.roc_comparison_range = [];
            obj.evt_patch_spacing = 12.5;
            obj.evt_patch_height = 10;
            obj.vertical_offset_delta = 50+(num_events_in_channel)*obj.evt_patch_spacing;  %num_events_in_channel does not include this event which is currently being added/assigned
            obj.evt_patch_y = obj.vertical_offset_delta+0; %0 will be replaced by the parent/channel position
            obj.epoch_start_x = 0;  %start at 0;
            obj.channel_name = chan_name;
            obj.batch_mode_label = '_';
            obj.hidden = false;
%             colorchoices = ['g','r','b','y','k'];
%             cur_color = colorchoices(mod(num_events_in_channel,5)+1);
%             
            obj.cur_color = parent_color;
            
            if(nargin>=10)
                obj.source = source;
                if(~isfield(source,'pStruct'))
                    obj.source.pStruct = [];
                end;
            else                
                obj.source.algorithm = 'unknown';
                obj.source.channel_indices = [];
                obj.source.editor = 'none';
                obj.source.pStruct = [];
            end
            
            obj.paramtexthandle =[]; %handle to textbox that displays paramStruct values
                
            if(nargin>=11)
                
                obj.paramStruct = paramStruct;
                obj.paramFieldIndex = 1; %index of the fieldname to use
                if(isstruct(paramStruct))
                    obj.paramFieldNames = fieldnames(paramStruct);
                else
                    obj.paramFieldNames = [];
                end
            else
                obj.paramFieldNames = [];
                obj.paramFieldIndex = 0;
                obj.paramStruct = [];
            end
            obj.parent_fig = [];
            obj.parent_axes = [];
%             obj.label_contextmenu_h = [];
            
            if(nargin>=13)
                if(~isempty(parent_fig)&&ishandle(parent_fig))
                    obj.parent_fig = parent_fig;
                end
                if(~isempty(parent_axes)&&ishandle(parent_axes))
                    obj.parent_axes = parent_axes;
                end
            end
            
            if(~isempty(obj.parent_fig) && ~isempty(obj.parent_axes))
                obj.hidden = false; %make sure it becomes visible at the corect time
                xdata = [];
                ydata = [];
                
                obj.evt_patch_h = patch('parent',obj.parent_axes,'visible','off',...
                'facecolor',obj.cur_color,'edgecolor',obj.cur_color,'facealpha',0.5,...
                'userdata',obj.current_event_index,'handlevisibility','off',...
                'xdata',xdata,'ydata',ydata,'buttondownfcn',@obj.buttondown_patch_callback);
                
            obj.label_h = text('parent',obj.parent_axes,'visible','off',...
                'handlevisibility','off','userdata',obj.current_event_index,...
                'color',obj.cur_color,'string',obj.label,...
                'uicontextmenu',[],'interpreter','none');

                enterFcn = @(figHandle, currentPoint)...
                    set(figHandle, 'Pointer', 'crosshair');
                iptSetPointerBehavior(obj.evt_patch_h, enterFcn);
                iptPointerManager(obj.parent_fig);
            else
                obj.label_h = [];
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_channel class.
        %> @param
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = setContextmenus(obj,contextmenu_patch_h, contextmenu_label_h,updateEvent_callback)
            %the contextmenu here is for the patches that represent the
            %discrete start stop sample events of an instance of this
            %class
            userdata = obj.current_event_index;
            if(ishandle(contextmenu_patch_h))
                set(contextmenu_patch_h,'userdata',userdata);
                set(obj.evt_patch_h,'uicontextmenu',contextmenu_patch_h);
            end
            
            
            %here come the label methods - these are off to the left
            %hand side of the events
            if(ishandle(contextmenu_label_h))

                set(contextmenu_label_h,'userdata',userdata);
                
                if(isstruct(obj.paramStruct))
                    param_contextsubmenu_h = uimenu(contextmenu_label_h,'Label','Parameter',...
                        'userdata',userdata,'separator','on',...
                        'callback',@obj.contextmenu_parameter_selection_prep_callback);
                    
                    for k=1:numel(obj.paramFieldNames)
                        uimenu(param_contextsubmenu_h,'Label',obj.paramFieldNames{k},'userdata',userdata,'separator','off','callback',{@obj.contextmenu_parameter_selection_callback,k});
                    end
                    uimenu(param_contextsubmenu_h,'Label','None','separator','off','userdata',userdata,'callback',{@obj.contextmenu_parameter_selection_callback,0});
                end
                
                if(~isempty(obj.source.channel_indices) && ~strcmp(obj.source.editor,'none'))
                    uimenu(contextmenu_label_h,'label','Update Event',...
                        'separator','on',...
                        'callback',updateEvent_callback,'userdata',userdata);
                end
                set(obj.label_h,'uicontextmenu',contextmenu_label_h);
                
            end

        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_channel class.
        %> @param
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = updateColor(obj,newColor)
            obj.cur_color = newColor;
            set(obj.evt_patch_h,'edgecolor',newColor,'facecolor',newColor);
            set(obj.label_h,'color',newColor);
            
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_channel class.
        %> @param
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function summary_stats = get_summary_stats(obj,stageStruct)
            if(isempty(obj.summary_stats_Struct) || obj.summary_stats_needs_updating_Bool)
                obj.summary_stats_Struct = obj.calculate_summary_stats(obj.samplerate,obj.start_stop_matrix,stageStruct);
            end
            summary_stats = obj.summary_stats_Struct;
            obj.summary_stats_needs_updating_Bool = false;  %it has been updated, and does not need further updating.  
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_channel class.
        %> @param
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = delete(obj)
            %deconstructor for this class
            %             global CHANNELS_CONTAINER;
            %             CHANNELS_CONTAINER.remove_event(channel_index,obj.current_event_index);
            %             channel_index = obj.class_channel_index;
            remove_handles= [
                obj.label_h
                obj.evt_patch_h
                obj.contextmenu_evt_patch_h
                obj.paramtexthandle(:)];
            for r=1:numel(remove_handles)
                if(ishandle(remove_handles(r)))
                    delete(remove_handles(r));
                end
            end
         
            obj = [];
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_channel class.
        %> @param
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = hide(obj)
            obj.hidden = true;
            set(obj.evt_patch_h,'handlevisibility','off','visible','off');
            set(obj.label_h,'handlevisibility','off','visible','off');
            if(~isempty(obj.paramtexthandle) && any(ishandle(obj.paramtexthandle)))                
                set(obj.paramtexthandle,'handlevisibility','off','visible','off');
            end

        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_channel class.
        %> @param
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function obj = show(obj)
            obj.hidden = false;
            set(obj.evt_patch_h,'handlevisibility','on','visible','on');
            obj.showLabel();
            obj.showParameterValues();
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_channel class.
        %> @param
        %> @retval obj instance of CLASS_channel class.
        % =================================================================
        function detectStruct = rerun(obj,detection_path)
            %rerun the detectionStruct for the current method, likely called when the channel
            %changes due to filtering

%             function_call = fullfile(detection_path,strrep(obj.source.algorithm,'detection.',''));
%             detectStruct = feval(function_call,obj.source.channel_indices,obj.source.pStruct);
            detectStruct = feval(obj.source.algorithm,obj.source.channel_indices,obj.source.pStruct);
            
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function obj = draw_all(obj,parentH,y_offset,max_height,stagesStruct)
            %plots on the overall lower axes, the artifacts listed in art, which is a vector containing 1's where
            %an artifact should be drawn and 0 otherwise.
            %parentH is the handle to
            %the figure axis the line will be plotted too.  color is the color of the
            %line as a string, and style is the style.  x_offset is a sample offset
            %which a subset of a bigger range is sent as input and the starting point
            %does not accurately represent the starting index desired given the limits
            %of the plot
            
            standard_epoch_count = numel(stagesStruct.line);
            
            %can adjust this to go through each patchhandle line... instead
            %of the first one.
            
%             color = get(obj.evt_patch_h(1),'edgecolor');
%             indices = get(obj.patchhandle(1),'userdata');
            
            
            starts = obj.start_stop_matrix(:,1);
            stops = obj.start_stop_matrix(:,2);
%           each_dur_sec = (stops-starts)/obj.samplerate;
            style = '-';
            start_epochs = sample2epoch(starts,stagesStruct.standard_epoch_sec,obj.samplerate);
            end_epochs = sample2epoch(stops,stagesStruct.standard_epoch_sec,obj.samplerate);
            
            %remove problem when stages.line is too small. 
            start_epochs(end_epochs>standard_epoch_count)=[];
            end_epochs(end_epochs>standard_epoch_count)=[];
            
            duration_by_epoch_in_seconds = zeros(1,standard_epoch_count);
            for k=1:numel(start_epochs)
                cur_epoch = start_epochs(k);
                cur_start = starts(k);
                while(cur_epoch<end_epochs(k))
                    cur_end = cur_epoch*stagesStruct.standard_epoch_sec*obj.samplerate;
                    duration_by_epoch_in_seconds(cur_epoch)=duration_by_epoch_in_seconds(cur_epoch)+(cur_end-cur_start+1);
                    cur_epoch=cur_epoch+1;
                    cur_start = cur_end+1;
                end
                cur_end = stops(k);
                duration_by_epoch_in_seconds(cur_epoch)=duration_by_epoch_in_seconds(cur_epoch)+(cur_end-cur_start+1);
            end;
            y_art = duration_by_epoch_in_seconds/obj.samplerate/stagesStruct.standard_epoch_sec*max_height; %the height is proportional to the amount of artifact in the stage.
            art_ind = find(y_art);
            x = [art_ind;art_ind;art_ind];
            y = [zeros(size(art_ind)); y_art(art_ind); nan(size(art_ind))];
            line(x(:),y(:)+y_offset,'color',obj.cur_color,'linestyle',style,'parent',parentH,'erasemode','normal','linewidth',1,'hittest','off');
            h = text('parent',parentH,'fontsize',7,'string',[obj.channel_name,' ',obj.label],'units','data','horizontalalignment','left','verticalalignment','baseline','interpreter','none');
            text_extent = get(h,'extent');
            label_position = [-text_extent(3), y_offset, 0];
            set(h,'position',label_position);
        end;

        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function setCurrentEpochStartX(obj,start_x)
            if(obj.epoch_start_x~=start_x)
                obj.epoch_start_x = start_x;
                obj.showLabel();
                obj.showParameterValues();
            end
        end

        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function setYOffset(obj,parent_y_offset)
            %update the y position of our event patch based on the input
            %parent y offset.  If it is different from before, then draw it
            new_y = obj.vertical_offset_delta+parent_y_offset;
            if(obj.evt_patch_y~=new_y)
                obj.evt_patch_y = new_y;
                obj.draw();
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function draw(obj)
            %range is a vector containing the x-values to be examined over
            %for events (i.e. the time line in samples)
            %parent_y_offset is the y offset that these events should be
            %referenced/offset from (it is where the parent object is
            %drawing its data at).
            if(~obj.hidden && ~isempty(obj.evt_patch_h))
                obj.show();
                if(~isempty(obj.start_stop_matrix))
                    r = size(obj.start_stop_matrix,1);                    
                    xdata = [obj.start_stop_matrix,fliplr(obj.start_stop_matrix)]';
                    ydata = [repmat(obj.evt_patch_y,r,2), repmat(obj.evt_patch_height+obj.evt_patch_y,r,2)]'; %not important until it is time to draw these...
                    set(obj.evt_patch_h,'xdata',xdata,'ydata',ydata);
                end
            end
        end;
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function showLabel(obj)
            if(~obj.hidden && ~isempty(obj.evt_patch_h))                
                text_extent = get(obj.label_h(1),'extent');
                
                label_position = [obj.epoch_start_x-text_extent(3)-10, obj.evt_patch_y+obj.evt_patch_height/2,0];
                set(obj.label_h,'position',label_position,'handlevisibility','on','visible','on');
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function showParameterValues(obj)
            %makes textboxes to display parameter values in for the current
            %epoch...
            if(~isempty(obj.paramtexthandle) && any(ishandle(obj.paramtexthandle)))
                delete(obj.paramtexthandle(:));
                obj.paramtexthandle = [];
            end
            if(~isempty(obj.paramStruct) && obj.paramFieldIndex>0) %it exists and a field is selected to be shown
                event_indices = obj.getEventIndicesInEpoch();
                if(~isempty(event_indices))
%                     fn = fieldnames(obj.paramStruct);
                    values= obj.paramStruct.(obj.paramFieldNames{obj.paramFieldIndex})(event_indices);
                    obj.paramtexthandle = -ones(numel(values),1); %-1 so we don't get mixed up with 0, the root handle
                    xposDelta = diff(obj.start_stop_matrix(event_indices,:)')';
                    xpos = obj.start_stop_matrix(event_indices,1)+xposDelta/3; %have the parameters start 1/3 of the way through the patch
                    ypos = repmat(obj.evt_patch_y+obj.evt_patch_height*2,size(xpos));
                    zpos = zeros(size(xpos));
                    pos = [xpos,ypos,zpos];
                    if(numel(values)>20)
                        for k=1:numel(values)
                            obj.paramtexthandle(k) = text('parent',obj.parent_axes,'position',pos(k,:),'string',num2str(values(k),'%0.0f'));
                        end
                    else
                        for k=1:numel(values)
%                             obj.paramtexthandle(k) = text('parent',obj.parent_axes,'position',pos(k,:),'string',num2str(values(k),'%0.1f'));
                            obj.paramtexthandle(k) = text('parent',obj.parent_axes,'position',pos(k,:),'string',num2str(values(k),'%0.1f'));
                        end
                    end
                end
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function obj = changeEventIndex(obj,new_event_index)

            obj.current_event_index = new_event_index;
            if(ishandle(obj.contextmenu_evt_patch_h))                
                set(obj.contextmenu_evt_patch_h,'userdata',obj.current_event_index);
                set(allchild(obj.contextmenu_evt_patch_h),'userdata',obj.current_event_index);
            end
            if(ishandle(obj.label_h))
                set(obj.label_h,'userdata',obj.current_event_index);
            end
            if(ishandle(obj.evt_patch_h))
                set(obj.evt_patch_h,'userdata',obj.current_event_index);
            end
            
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function event_indices = getEventIndicesInEpoch(obj,epoch_x_lim)
            %returns the indices of the events for this object that occur
            %at the epoch which starts at the sample point x_pos and is of
            %length/duration defined by the MARKING global and the objects
            %samplerate defined at construction.
            %This function is helpful in showing textboxes for a single
            %epoch that give parameter values
            global MARKING
            if(nargin<2)
                epoch_x_lim = MARKING.sev_mainaxes_xlim;
            end
            event_indices = find(obj.start_stop_matrix(:,1)>=epoch_x_lim(1)&obj.start_stop_matrix(:,1)<=epoch_x_lim(2));
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function event_index = findNearestEvent(obj,epoch_sample_start)
            global MARKING;
            if(nargin<2)
                epoch_sample_start = MARKING.sev_mainaxes_xlim(1);
            end
            event_index = find(obj.start_stop_matrix(:,1)<=epoch_sample_start&obj.start_stop_matrix(:,2)>=epoch_sample_start,1);
            if(isempty(event_index))
                event_index = find(obj.start_stop_matrix(:,1)>=epoch_sample_start,1);
            end
            if(isempty(event_index))
                event_index = 1; %I give up
            end            
        end;
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function obj = save2images(obj,full_filename_prefix,settings)
            %this method saves the events to individual files
            global CHANNELS_CONTAINER;
            
            cur_channel = CHANNELS_CONTAINER.cell_of_channels{obj.source.channel_indices(1)};
            if(nargin<=2)
               settings.format = 'PNG';
               settings.limit_count = 0;
               settings.buffer_sec = 0.5;
               settings.standard_epoch_sec = 30;
            end


            buffer_samples = floor(obj.samplerate*settings.buffer_sec);
            range_start = max(obj.start_stop_matrix(:,1)-buffer_samples,1);
            range_end = min(obj.start_stop_matrix(:,2)+buffer_samples,numel(cur_channel.raw_data));

            epoch_start = sample2epoch(range_start,settings.standard_epoch_sec,obj.samplerate);
            
            
            settings.amplitude_ceiling = 75;%75 uVolts total
            height = settings.amplitude_ceiling; 
            x_tick_delta = ceil(0.5*obj.samplerate); %put ticks every .5 seconds
            y_tick_delta = 10; %go for every 10 microvolts;
            
            tmp_fig =figure('visible','off','toolbar','none','menubar','none','units','points','paperpositionmode','manual','inverthardcopy','off');
%             ,'paperpositionmode','manual','paperposition',[0 0 max_dur/100 height*2/100]);
%                 
%set(tmp_fig,'units','normalized','clipping','off');
            a = axes('parent',tmp_fig,...
                'ytickmode','manual','ytick',-height:y_tick_delta:height,'yticklabel',[],...
                'units','normalized','activepositionproperty','position','position',[0.01 0.01 0.98 0.98],'xticklabel',[],'box','on',...
                'xtickmode','manual','xtick',[],'ylim',[-height, height]); %,'dataaspectratiomode','auto','plotboxaspectratiomode','auto','cameraviewanglemode','auto');
            
            % ,'xdata',x,'ydata',x);
            
%             map = [0 0 0; 1 1 1]; %black; white
%             print(h,'-djpeg','fname.jpeg')%

% h = figure('Visible','Off'); % Creating a figure and not displaying it
% ax = axes; % Create an Axes;
% plt = plot(ax,1:10,1:10,'r'); % Plot an arbitrary line in the axes 
% set(h,'CurrentAxes',ax); % Set current Axes of figure to 'ax'
% print(h,'-djpeg','fname.jpeg')% Print the plot to file 'fname.jpeg'

%             map = colormap;
            
            numPics = min(size(obj.start_stop_matrix,1),settings.limit_count);
            
            %put a file named note at the top of the directory in cases
            %where the limit is reached
            if(numPics == settings.limit_count)
                [pathstr,~,~] = fileparts(full_filename_prefix);
                fclose(fopen(fullfile(pathstr,sprintf('_cap_limit_of_%u_reached.txt',settings.limit_count)),'w'));
            end

            for k = 1:numPics
                filename = sprintf('%s_%s_%u_epoch%u.%s',full_filename_prefix,cur_channel.title,k,epoch_start(k),settings.format);
%                print_filename = sprintf('%s_%s_%u_epoch%u_print.%s',full_filename_prefix,cur_channel.title,k,epoch_start(k),settings.format);
                x = range_start(k):range_end(k);
                try
                    l_h = line('parent',a);
                    set(a,'xtick',range_start(k):x_tick_delta:range_end(k),'xlim',[range_start(k),range_end(k)]);
                    set(l_h,'ydata',cur_channel.raw_data(x),'xdata',x);  
                    set(tmp_fig,'position',[0 0 range_end(k)-range_start(k)+1 height*2]);
                    
%                     print(tmp_fig,['-d',lower(settings.format)],'-r1',filename); %r0 is screen resolution; r50 is 50 dpi
%                     f = getframe(tmp_fig);
%                    print(tmp_fig,['-d',lower(settings.format)],'-r75',print_filename);
                    f = getframe(a);
                    if(k==1)
                        f=getframe(a);
                    end
                    imwrite(f.cdata(:,:,1),filename,settings.format,'bitdepth',1);
                    cla(a);

                    
                catch ME
                    showME(ME);
                    disp([filename,' failed to save.  Likely boundary condition fault.']);
                end
%                 imwrite(cur_event,map,filename,format);
            end
            close(tmp_fig);
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        %> adds a single event start_stop vector to the current
        %> start_stop_matrix and updates the data to be drawn...
        function appendEvent(obj,single_event)
            if(~isempty(single_event)&&all(single_event))
                obj.start_stop_matrix(end+1,:)=single_event;
%                 obj.updatePatchHandleData();
%                 xdata = [obj.start_stop_matrix(:,1),obj.start_stop_matrix(:,2),nan(size(obj.start_stop_matrix,1),1)]';
%                 ydata=get(obj.patchhandle,'ydata');
%                 ydata = [ydata(:);ydata(end-2:end)];
%                 set(obj.patchhandle,'xdata',xdata,'ydata',ydata);
            end            
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function deleteDatabaseRecords(obj,DBtable,optional_PatStudyKey)
            %remove the events with the same label and detector ID as this
            %one (i.e. obj).  If optional_PatStudyKey is included, then the
            %event records are only removed for that PatStudyKey
            %DBstruct contains fields 'name','user','password', and 'table' for interacting with a mysql database            
            %removes the database events when necessary.
            %The database must already be open for this function to work.
            if(nargin>2)
                mym('DELETE FROM %s WHERE detectorID=%d and patstudykey="%s"',DBtable,obj.detectorID,optional_PatStudyKey);
            else
                mym('DELETE FROM %s WHERE detectorID=%d',DBtable,Q.DetectorID);                
            end
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function save2DB(obj,DBtable,PatStudyKey,stagesStruct)
            %DBtable is the table name to load the events into
            %patidkey is the patidkey the events are associated with and
            %assigned to.
            
            preInsertStrNoParams = ['INSERT INTO ',DBtable, ' (PatStudyKey, DetectorID, '...
                'Start_sample, Stop_sample, Duration_seconds, Epoch, Stage, cycle) VALUES(',...
                '%d,%d,%d,%d,%0.3f,%d,''%d'',%d)'];
            
            preInsertStrWithParams = ['insert into ',DBtable, ' (patstudykey, detectorid, '...
                'start_sample, stop_sample, duration_seconds, epoch, stage, cycle, params) values(',...
                '%d,%d,%d,%d,%0.3f,%d,''%d'',%d,"{M}")'];
           
%             y = mym('SELECT DetectorID FROM DetectorInfo_T WHERE detectorLabel="{S}" and configid={S0}',obj.label,obj.configID);
            DetectorID = obj.detectorID;            
            Start_sample = obj.start_stop_matrix(:,1);
            Stop_sample = obj.start_stop_matrix(:,2);
            Epoch = sample2epoch(obj.start_stop_matrix(:,1),stagesStruct.standard_epoch_sec,obj.samplerate);
%             bad_ind = Epoch>numel(stagesStruct.line);
            Stage = stagesStruct.line(Epoch);
            Cycle = stagesStruct.cycles(Epoch);
            Duration_seconds = (Stop_sample-Start_sample)/obj.samplerate;
            Params = obj.paramStruct;
            numEvts = size(obj.start_stop_matrix,1);
            if(isempty(Params))
                for e=1:numEvts
                    InsertStr = sprintf(preInsertStrNoParams,PatStudyKey,DetectorID,...
                        Start_sample(e), Stop_sample(e),...
                        Duration_seconds(e), Epoch(e),...
                        Stage(e),Cycle(e));
                    try
                        mym(InsertStr);
                    catch ME
                        showME(ME);
                    end
                end
            else
                for j = 1:numel(obj.paramFieldNames)
                    pStruct.(obj.paramFieldNames{j}) = [];
                end
                
                for e=1:numEvts
                    try
                    for j = 1:numel(obj.paramFieldNames)
                        pStruct.(obj.paramFieldNames{j}) = Params.(obj.paramFieldNames{j})(e,:); %add the (e,:) for the case with parameters of arrays
                    end
                    catch ME                   
                        showME(ME);
                    end
                    InsertStr = sprintf(preInsertStrWithParams,PatStudyKey,DetectorID,...
                        Start_sample(e), Stop_sample(e),...
                        Duration_seconds(e), Epoch(e),...
                        Stage(e), Cycle(e));
                    try
                        mym(InsertStr,pStruct);
                    catch ME
                        showME(ME);
                    end
                end
            end
            
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function save2mat(obj,filename,stagesStruct)
            %this function requires filename to meet OS file naming requirements
            %or it will crash - it overwrites any preexisting file with the
            %same name
            event_start_stop = obj.start_stop_matrix;
            source = obj.source;
            paramStruct = obj.paramStruct;
            label = obj.label;
            
            if(iscell(obj.label))
                obj.label = char(obj.label);
            end
            if(iscell(obj.channel_name))
                obj.channel_name = obj.channel_name{1};
            end
            
            starts = obj.start_stop_matrix(:,1);
            
            %subtract 1 below, since the 1st sample technically starts at
            %           %t0 and thus the first sample in matlab would otherwise be listed as 1/fs seconds after t0
%             start_offset_sec = (starts-1)/obj.samplerate; %add the seconds here
            
%             start_times = datenum([zeros(numel(start_offset_sec),numel(t0)-1),start_offset_sec(:)])+datenum(t0);
%             start_times = datestr(start_times,'HH:MM:SS.FFF');
            
            
            start_epochs = sample2epoch(starts,stagesStruct.standard_epoch_sec,obj.samplerate);
            start_stages = stagesStruct_STAGES.line(start_epochs);
            start_cycle = stagesStruct_STAGES.cycles(start_epochs);
            
            duration = (event_start_stop(:,2)-event_start_stop(:,1))/obj.samplerate;
            %             y = [obj.start_stop_matrix, duration(:)];
%             y = [duration(:),start_epochs(:),start_stages(:)];
            
            start_stop_matrix = obj.start_stop_matrix;
            filename = [filename,'.',obj.channel_name,'.',obj.label,'.',num2str(obj.configID),'.mat'];
            save(filename,'event_start_stop','source','paramStruct','label','duration','start_stages','start_epochs','start_cycle','start_stop_matrix');
        end

        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function obj = remove(obj,start_stop_matrix_index)
           %removes the event entry in start_stop_matrix found at row index start_stop_matrix_index
           if(start_stop_matrix_index>0 && start_stop_matrix_index <= size(obj.start_stop_matrix,1))
              obj.start_stop_matrix(start_stop_matrix_index,:) = []; 
              obj.draw();              
           end            
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function result = isempty(obj)
            result = isempty(obj.start_stop_matrix);
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function save2text(obj,filename,studyStruct)
            %this function requires filename to meet OS file naming requirements
            %or it will crash - it appends to the file if filename already
            %exists, otherwise a new one is created.  The file is closed at            
            %the end of this function call
            %filename is the file to save the data to
            %studyStruct is a struct with the following fields
            %    .startDateTime
            %    .standard_epoch_sec
            global MARKING;
            
            if(~isempty(obj.start_stop_matrix))
                
                if(nargin<3 || isempty(studyStruct))
                    studyStruct = MARKING.sev;
                    studyStruct.startDateTime = MARKING.startDateTime;
                    studyStruct.STAGES = MARKING.sev_STAGES;

                end
                
                t0 = studyStruct.startDateTime;
                STAGES = studyStruct.STAGES;
                
                event_start_stop = obj.start_stop_matrix;
%                 if(obj.batch_mode_label ~= '_')
%                     if(iscell(obj.batch_mode_label))
%                         filename = [filename,'.',char(obj.batch_mode_label),'.',num2str(obj.configID),'.txt'];
%                     else
%                         filename = [filename,'.',obj.batch_mode_label,'.',num2str(obj.configID),'.txt'];
%                     end
%                 else
%                     filename = [filename,'.txt'];
%                 end
                filename = [filename,'.',obj.label,'.',num2str(obj.configID),'.txt'];
                fid = fopen(filename,'w');
                
                %             hdr = {['#Event Label  = ',obj.label],...
                %                 ['#EDF Channel Label(number) = ',obj.channel_name,' (',num2str(obj.channel_number),')']};
                hdr = {obj.label,...
                    [obj.channel_name,' (',num2str(obj.channel_number),')']};
                fprintf(fid,'#Event Label =\t%s\r\n#EDF Channel Label(number) = \t%s\r\n',hdr{1},hdr{2});
                fprintf(fid,'#Start_time\tDuration_seconds\tStart_sample\tStop_sample\tEpoch\tStage\tCycle');
                
                starts = obj.start_stop_matrix(:,1);
                
                %subtract 1 below, since the 1st sample technically starts at
                %           %t0 and thus the first sample in matlab would otherwise be listed as 1/fs seconds after t0
                start_offset_sec = (starts-1)/obj.samplerate; %add the seconds here
                
                start_times = datenum([zeros(numel(start_offset_sec),numel(t0)-1),start_offset_sec(:)])+datenum(t0);
                start_times = datestr(start_times,'HH:MM:SS.FFF');
                
                
                start_epochs = sample2epoch(starts,studyStruct.standard_epoch_sec,obj.samplerate);
                start_stages = STAGES.line(start_epochs);
                start_cycle = STAGES.cycles(start_epochs);
                
                duration = (event_start_stop(:,2)-event_start_stop(:,1)+1)/obj.samplerate;
                %             y = [obj.start_stop_matrix, duration(:)];
                y = [duration(:),obj.start_stop_matrix,start_epochs(:),start_stages(:),start_cycle(:)];
                
                if(~isempty(obj.paramStruct))
                    paramNames = fieldnames(obj.paramStruct);
                    if(~iscell(paramNames))
                        paramNames = {paramNames};
                    end;
                    paramValues = zeros(size(y,1),numel(paramNames));
                    for k = 1:numel(paramNames)
                        fprintf(fid,'\t%s',paramNames{k});
                        paramValues(:,k) = obj.paramStruct.(paramNames{k})(:);
                    end
                    
                    y = [y,paramValues];
                end
                
                fprintf(fid,'\r\n');
                
                
                %the older way of doing this...
                %             fclose(fid);
                %             save(filename,'y','-ascii','-tabs','-append');
                
                
                %t0 is a date vector
                %             A date vector contains six elements, specifying year, month, day, hour,
                %  	minute, and second.
                format_str = [repmat('%c',1,size(start_times,2)),'\t',repmat('%0.4f\t',1,size(y,2)),'\n'];
                
                fprintf(fid,format_str,[start_times+0,y]');
                fclose(fid);
            end
            
        end
        

        
        % --------------------------------------------------------------------

        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function obj = rename(obj,new_label)
            if(ischar(new_label))
                obj.label = new_label;
            end
            set(obj.label_h,'string',...
                obj.label);
        end

        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function contextmenu_parameter_selection_callback(obj,hObject,~,selection_index)
            obj.paramFieldIndex = selection_index;
            set(hObject,'checked','on');         
            obj.showParameterValues();
        end
        
        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function contextmenu_parameter_selection_prep_callback(obj,hObject,~)
            child_h = flipud(get(hObject,'children'));
            set(child_h,'checked','off');
            if(obj.paramFieldIndex==0)
                set(child_h(end),'checked','on');
            else
                set(child_h(obj.paramFieldIndex),'checked','on');
            end
        end

        % =================================================================
        %> @brief
        %> @param obj instance of CLASS_events class.
        %> @param
        %> @retval obj instance of CLASS_events class.
        % =================================================================
        function buttondown_patch_callback(obj,hObject,event_data)
            global MARKING;
            global CHANNELS_CONTAINER;
            
            selectionType = get(gcbf, 'SelectionType');
            
            MARKING.clear_handles();
            
            mouse_pos = get(gca,'currentpoint');
%             obj.startstop_matrix_index = obj.findNearEvent(mouse_pos(1));
            MARKING.start_stop_matrix_index = ...
                obj.findNearestEvent(mouse_pos(1));
            
            if(strcmp(selectionType,'normal'))
                MARKING.event_label = obj.label;
                MARKING.event_index = obj.current_event_index;
                MARKING.class_channel_index = obj.class_channel_index; %get the associated channel
                
                MARKING.current_linehandle = CHANNELS_CONTAINER.cell_of_channels{obj.class_channel_index}.line_handle;
                
                %turn the editor icon and states on                
                MARKING.toggle_toolbar('marking','on');
                editing = true;
                MARKING.startMarking(editing); 
            else
                %a context menu should pop-up otherwise
            end;
        end
    end
    
    methods(Static)
        
        % =================================================================
        %> @brief
        %> @param
        %> @retval 
        % =================================================================
        function params = loadXMLparams(pfile)
            [pathstr,filename, ext] = fileparts(pfile);
            if(~strcmp(ext,'.plist'))
                ext = '.plist';
            end
            pfile = [filename,ext];
            
            if(isempty(strfind(pathstr,'+filter')))
                pathstr = fullfile(pathstr,'+filter');
            end
            
            pfile = fullfile(pathstr,pfile);
            
            if(exist(pfile,'file'))
                %load it
                params = plist.loadXMLPlist(pfile);
            else
                params = [];
            end
        end

        % =================================================================
        %> @brief
        %> @param
        %> @retval 
        % =================================================================
        function summary_stats = calculate_summary_stats(samplerate,start_stop_matrix, stage_struct)
            %stage_struct is a structure with fields count and line which is a 
            % vector of size size(start_stop_matrix,1) that 
            %contains integer stage values per epoch (i.e. epoch_dur_sec seconds per epoch) 
            %summary_stats contains the following fields
            % count
            % dur_sec
            % table_column_names
            % table_row_names
            % table_data
            %
            % count is a struct with the following fields
            %    evt_all - numeric count of all event_start_stop
            %    evt_stage = vector with numeric event count by stage 
            % dur_sec is a struct with the following fields
            %    evt_all - duration in seconds of all event_start_stop
            %    evt_stage = vector with duration of event_start_stop by stage in seconds
            %    study_all - duration of entire study in seconds
            %    study_stage = vector of stage durations in seconds
            starts = start_stop_matrix(:,1);
            stops =  start_stop_matrix(:,2);
            all_count = numel(starts);
            all_dur_sec = sum(stops-starts)/samplerate;
            start_epochs = sample2epoch(starts,stage_struct.standard_epoch_sec,samplerate);
            start_stages = stage_struct.line(start_epochs);
            
            summary_stats.count.evt_all = all_count; %number of event_start_stop total
            summary_stats.count.evt_stage = zeros(size(stage_struct.count)); %number of events grouped by stage
            summary_stats.dur_sec.evt_all = all_dur_sec; %duration of all events
            summary_stats.dur_sec.evt_stage = zeros(size(stage_struct.count)); %duration of events grouped by stage
            summary_stats.dur_sec.study_all = stage_struct.study_duration_in_seconds;
            summary_stats.dur_sec.study_stage = stage_struct.count*stage_struct.standard_epoch_sec; %duration of 
            
            %the table data and table labels are intended to be used with
            %uitable so that columns correspond to the table_labels and
            %rows correspond to the entire study followed by a breakdown of each stage
            summary_stats.table_column_names = {'Count','Count/hour','Duration(sec)','Duration Index (sec/hour)','Pct Count','Pct of Duration'};
            summary_stats.table_row_names = cell(numel(stage_struct.count)+1,1);
            summary_stats.table_data = zeros(numel(summary_stats.table_row_names),numel(summary_stats.table_column_names));
            
            summary_stats.table_data(1,:) = [summary_stats.count.evt_all,summary_stats.count.evt_all/(summary_stats.dur_sec.study_all/3600),...
                summary_stats.dur_sec.evt_all,summary_stats.dur_sec.evt_all/(summary_stats.dur_sec.study_all/3600),...
                100.0,100.0];
            summary_stats.table_row_names{1} = 'All';
            
            if(~isempty(start_stop_matrix))
                for k = 1:numel(stage_struct.count)
                    summary_stats.table_row_names{k+1} = ['Stage ',num2str(k-1)];

                    if(stage_struct.count(k)>0)
                        stage_dur_hr = summary_stats.dur_sec.study_stage(k)/3600;
                        if(stage_dur_hr>0)
                            stage_indices = start_stages==(k-1); %k-1 because staging starts at 0 (awake)                            
                            stage_starts = start_stop_matrix(stage_indices,1);
                            stage_stops = start_stop_matrix(stage_indices,2);
                            summary_stats.count.evt_stage(k) = numel(stage_starts);
                            summary_stats.dur_sec.evt_stage(k) = sum(stage_stops-stage_starts)/samplerate;
                            summary_stats.table_data(k+1,:) = [summary_stats.count.evt_stage(k),summary_stats.count.evt_stage(k)/stage_dur_hr,...
                                summary_stats.dur_sec.evt_stage(k),summary_stats.dur_sec.evt_stage(k)/stage_dur_hr,...
                                summary_stats.count.evt_stage(k)/summary_stats.count.evt_all*100,summary_stats.dur_sec.evt_stage(k)/summary_stats.dur_sec.evt_all*100];
                        end
                    end
                end
            end
        end
        
        % =================================================================
        %> @brief
        %> @param
        %> @retval 
        % =================================================================
        function [merged_events, merged_indices] = buffer_then_merge_nearby_events(event_mat_in,min_samples,additional_buffer_samples,max_samples)
            %add additional buffer before and after each event and then
            %merge if within min_samples of each other using
            %merge_nerarby_events function below
            event_mat_in = [event_mat_in(:,1)-additional_buffer_samples,event_mat_in(:,2)+additional_buffer_samples];
            event_mat_in(:,1) = max(event_mat_in(:,1),1);
            event_mat_in(:,2) = min(event_mat_in(:,2),max_samples);
            [merged_events, merged_indices] = CLASS_events.merge_nearby_events(event_mat_in,min_samples);
        end

        % ======================================================================
        %> @brief Brief description of the merge_nearby_events method
        %>
        %> This method is static
        %> @param event_mat_in Description of event_mat_in
        %> @param min_samples Description of min_samples
        %> @retval merged_events first return value of this method
        %> @retval merged_indices second return value of this method
        % =================================================================
        function [merged_events, merged_indices] = merge_nearby_events(event_mat_in,min_samples)
            %merge events that are within min_samples of each other, into a
            %single event that stretches from the start of the first event
            %and spans until the last event
            %event_mat_in is a two column matrix
            %min_samples is a scalar value
            %merged_indices is a logical vector of the row indices that
            %were merged from event_mat_in. - these are the indices of the
            %in event_mat_in that are removed/replaced
            
            if(nargin==1)
                min_samples = 100;
            end
            
            merged_indices = false(size(event_mat_in,1),1);

            if(~isempty(event_mat_in))
                merged_events = zeros(size(event_mat_in));
                num_events_out = 1;
                num_events_in = size(event_mat_in,1);
                merged_events(num_events_out,:) = event_mat_in(1,:);
                for k = 2:num_events_in
                    if(event_mat_in(k,1)-merged_events(num_events_out,2)<min_samples)
                        merged_events(num_events_out,2) = event_mat_in(k,2);
                        merged_indices(k) = true;
                    else
                        num_events_out = num_events_out + 1;
                        merged_events(num_events_out,:) = event_mat_in(k,:);
                    end                    
                end;
                merged_events = merged_events(1:num_events_out,:);
            else
                merged_events = event_mat_in;
            end;
        end
        
        % =================================================================
        %> @brief
        %> @param
        %> @retval 
        % =================================================================
        function clean_events = cleanup_events(event_mat_in,min_samples)
            %extract only those events (from event_mat_in) that exceed a minimum duration
            %(min_samples)
            %event_mat_in is a two column matrix
            %min_samples is a scalar value
            if(nargin==1)
                min_samples = 100;
            end
            if(~isempty(event_mat_in))
                clean_indices = (event_mat_in(:,2)-event_mat_in(:,1))>min_samples;
                clean_events = event_mat_in(clean_indices,:);
            else
                clean_events = event_mat_in;
            end;
        end
        
        % =================================================================
        %> @brief
        %> @param
        %> @retval 
        % =================================================================
        function filled_events = fill_bins_with_events(event_mat_start_stop, num_samples)
            %this function breaks a timeline into num_samples chunks, and fills the
            %entire chunck with 1's if it contains at least one event that is not 0
            %event_mat_start_stop is a two column matrix of start and stop indices (columns 1 and 2)
            %for the event_mat_start_stop
            num_samples = floor(num_samples);            
            if(isempty(event_mat_start_stop)||num_samples<=1)
                filled_events = event_mat_start_stop;
            else
                first_events = [floor(event_mat_start_stop(:,1)/num_samples)*num_samples+1,ceil(event_mat_start_stop(:,2)/num_samples)*num_samples];
                filled_events = zeros(size(first_events));
                
                %clean up any overlapping portions...
                % 10  40 -> 1 200
                % 60 100 -> 1 200
                %202 205 -> 201 400
                
                %this then gets converted to an output of
                %1 200
                %201 400
                
                num_events = size(first_events,1);
                
                cur_event = 1;
                filled_events(cur_event,:) = first_events(cur_event,:);
                
                for k = 2:num_events
                    
                    if(filled_events(cur_event,1)==first_events(k,1))
                        if(filled_events(cur_event,2)~=first_events(k,2))
                            filled_events(cur_event,2) = max(filled_events(cur_event,2),first_events(k,2));
                            %else skip this one and move onto the next event since this is
                            %a duplicate
                        end
                    else
                        if(first_events(k,2)>filled_events(cur_event,2) && first_events(k,1)<filled_events(cur_event,2))
                            filled_events(cur_event,2) = first_events(k,2);
                        elseif(filled_events(cur_event,2)~=first_events(k,2))
                            cur_event = cur_event+1;
                            filled_events(cur_event,:) = first_events(k,:);
                        end
                    end
                end
                
                %just grab the ones we need - that were not duplicated..
                filled_events = filled_events(1:cur_event,:);            
            end
        end
    end
            
end
