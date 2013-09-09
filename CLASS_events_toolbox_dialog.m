%> @file CLASS_events_toolbox_dialog.m
%> @brief CLASS_events_toolbox_dialog GUI creation class for SEV's event toolbox.
% ======================================================================
%> @brief CLASS_events_toolbox_dialog provides the backbone for creating gui's of 
%> different events using a few selectable parameters
%
%> Envision this class being used in the following manner
%> 1.  The calling program will instatiate an object.  It will then 
%>     - if there is more than one channel to use then allow the selection of multichannel algorithms (lms filtering, ocular detection, etc.).
%>     - drop down list of avaialble channels to choose from for source, and possibly destination (if multichannel selected)
%>     - select if this will be a new channel created, or if artifacts are to be added only
%>     - select destination for artifacts
%>     - list name of artifact 'SEV.ocular.llll'
%>     - 
%>     - Event detection
%>         - criteria method - mean/median
%>         - greater than less than, equal, etc
%>         - moving filter.... (time delay for each)
% ======================================================================
%     
% History 
% Written by Hyatt Moore IV
% Modified: 10.9.12 - put in MARKING global and removed sev('fcnCalls');
classdef CLASS_events_toolbox_dialog < handle
    properties
        channel_names;% CHANNELS_CONTAINER will probably be fine...
        types; %{filter/detection/synthesis}
        types_index;
        num_sources; %how many channels to be used as comparison
        detection_methods; % {'mean','median'}; 
        detection_methods_index;
        
        detection_thresholds; %{'<','<=','~=','==','>=','>'};
        detection_threshold_index;
        dialog_handle;
        channel_selections; %vector of indexes of selected sources size is num_sourcesx1
        detection_path; %directory where detections are stored 
        detection_inf_file;  %filename that contains detector information
        updated_event_index; %index of the newly added/updated event, if any..
    end;
    
    methods
        function obj = CLASS_events_toolbox_dialog()
               global CHANNELS_CONTAINER;
               n= CHANNELS_CONTAINER.num_channels;
%                obj.channel_names = cell(n,1);
%                for k=1:n
%                    obj.channel_names{k} = CHANNELS_CONTAINER.cell_of_channels{k}.title;
%                end
%                obj.channel_names = char(obj.channel_names);
               obj.channel_names = char(CHANNELS_CONTAINER.getChannelNames());

               obj.types_index = 2;
               obj.types = {'Filter','Detection','Synthesis'};
               obj.num_sources = n;
               obj.detection_methods_index = 1;
               obj.detection_methods = {'mean','median'};               
               obj.detection_methods = {'<','<=','~=','==','>=','>'};
               obj.detection_methods_index = 5;
               obj.dialog_handle = [];
               obj.channel_selections = 1;
               obj.detection_path = '+detection';
               obj.detection_inf_file = 'detection.inf';
               obj.updated_event_index = [];
%                obj.filter_path
        end;
        
        function obj = run(obj)
            global EVENT_CONTAINER;
            global CHANNELS_CONTAINER;
            global MARKING;
            obj.updated_event_index = [];
%             uncoment this for debugging purposes
%             obj.channel_names = char({'eeg','ecg','emg'});
            if(isempty(obj.channel_names))
                warndlg({'No source files loaded.','Please load channels first'},'Warning');
            elseif(isempty(obj.dialog_handle)||~ishandle(obj.dialog_handle))
                max_num_sources = 3;  %maximum number of sources that can be drawn...
                max_width = 0; %keep track of the width and get the largest chunk as the dialog grows/changes
                delta = 15;
                cur_pos = [delta, delta, 0 0]; %bottom left position 
                units = 'points';
                
                
                methods = CLASS_events_container.loadDetectionMethodsInf(obj.detection_path,obj.detection_inf_file);
                
                methods.mfile{end+1} = '';
                methods.evt_label{end+1} = 'Create New';
                methods.param_gui{end+1} = 'none';
                methods.num_reqd_indices(end+1)=0;
                
                
                obj.dialog_handle = dialog('visible','off','units',units,'name','Event toolbox');
                
                %work way up from the bottom....
                %I.  Establish Buttons
                %buttons to say cancel or OK
                button.OK = uicontrol('parent',obj.dialog_handle,'style','pushbutton','string','OK',...
                    'units',units,'callback','uiresume(gcbf)');
                button.Cancel = uicontrol('parent',obj.dialog_handle,'style','pushbutton','string','Cancel',...
                    'units',units,'callback','output = [],close(gcbf)');
                button_extent = max(get(button.OK,'extent'),get(button.Cancel,'extent'))*1.2;
                
                cur_pos(1)=delta;
                set(button.OK,'position',[cur_pos(1:2),button_extent(3:4)]);
                cur_pos(1)=cur_pos(1)+button_extent(3)+delta;
                set(button.Cancel,'position',[cur_pos(1:2),button_extent(3:4)]);
                
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,button_extent,delta);

                                
                %II.  Assign events to a channel or not...
                text.event_label = uicontrol('style','text','parent',obj.dialog_handle,...
                    'string','Events Label:','units',units);
                extent = get(text.event_label,'extent');
                set(text.event_label,'position',[cur_pos(1:2),extent(3:4)]);
                cur_pos(1) = cur_pos(1)+extent(3)+delta/2;
                
                extent = extent.*[1 1 2 1.5];
                edit.event_label = uicontrol('style','edit','parent',obj.dialog_handle,...
                    'string','','units',units,'position',[cur_pos(1:2), extent(3:4)],...
                    'backgroundcolor','w');
                
                cur_pos(1) = cur_pos(1)+extent(3)+delta;
                max_width = max(max_width,cur_pos(1));
                %move up and align left
                cur_pos(2)=cur_pos(2)+delta/2+extent(4); %only go up 1/2 a row 
                cur_pos(1) = delta; %reallign to left
                
                text.event_channel = uicontrol('style','text','parent',obj.dialog_handle,...
                    'string','Assign Events To:','units',units);
                extent = get(text.event_channel,'extent');
                set(text.event_channel,'position',[cur_pos(1:2),extent(3:4)]);
                
                cur_pos(1) = cur_pos(1)+extent(3)+delta/2;
                
                popup.event_source=uicontrol('style','popupmenu','units',units,...
                    'parent',obj.dialog_handle,'string',char({obj.channel_names,'Synthesized Channel'}),...
                    'horizontalalignment','left','value',1);
                extent = get(popup.event_source,'extent')+[0 0 65 0];
                    
                set(popup.event_source,'units',units','position',[cur_pos(1:2),extent(3:4)]);
                
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta);
                
                %III.  Synthesize the channel or not...
                text.synth_channel = uicontrol('style','text','parent',obj.dialog_handle,...
                    'string','Channel Name:','units',units,'enable','off');
                extent = get(text.synth_channel,'extent');
                set(text.synth_channel,'position',[cur_pos(1:2),extent(3:4)]);
                cur_pos(1) = cur_pos(1)+extent(3)+delta/2;
                
                extent = extent.*[1 1 1 1.5];
                edit.synth_channel = uicontrol('style','edit','parent',obj.dialog_handle,...
                    'string','','units',units,'position',[cur_pos(1:2), extent(3:4)],...
                    'enable','off','backgroundcolor','w');
                
                cur_pos(1) = cur_pos(1)+extent(3)+delta;
                max_width = max(max_width,cur_pos(1));
                %move up and align left
                cur_pos(2)=cur_pos(2)+delta/2+extent(4); %only go up 1/2 a row 
                cur_pos(1) = delta; %reallign to left
                
                checkbox.synth_channel = uicontrol('style','checkbox','value',0,...
                    'string','Synthesize New Channel','units',units,...
                    'parent',obj.dialog_handle);
                extent = get(checkbox.synth_channel,'extent')+[0 0 20 0];
                set(checkbox.synth_channel,'position',[cur_pos(1:2), extent(3:4)]);
                
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta);

                                
                %IV. Source Labels for Selection
                %source labels for selection
                popup.sources = zeros(max_num_sources,1);
                if(numel(obj.channel_selections)~=obj.num_sources)
                    obj.channel_selections = ones(obj.num_sources,1); %set them all to the first element then.
                end;
                for k=1:min(obj.num_sources,max_num_sources)
                    popup.sources(k)=uicontrol('style','popupmenu','units',units,...
                        'parent',obj.dialog_handle,'string',obj.channel_names,...
                        'horizontalalignment','left','value',min(obj.num_sources ,k));
                    extent = get(popup.sources(k),'extent')+[0 0 65 0];
                    
                    set(popup.sources(k),'units',units','position',[cur_pos(1:2),extent(3:4)]);
                    cur_pos(1)=cur_pos(1)+extent(3)+delta;  %move to the right...
                    
                end;
                
                max_width = max(max_width,cur_pos(1));
                
                %create the invisible ones now...
                for k=obj.num_sources+1:max_num_sources
                    popup.sources(k)=uicontrol('style','popupmenu','units',units,...
                        'parent',obj.dialog_handle,'string',obj.channel_names,...
                        'horizontalalignment','left','value',min(obj.num_sources,k),'visible','off');
                    extent = get(popup.sources(k),'extent')+[0 0 65 0];
                    
                    set(popup.sources(k),'units',units','position',[cur_pos(1:2),extent(3:4)]);
                    cur_pos(1)=cur_pos(1)+extent(3)+delta;  %move to the right...
                    
                end;
                
                cur_pos(2)=cur_pos(2)+extent(4)+delta;  %move up to the next row
                cur_pos(1) = delta;
                
                
                %V. Popup to select the number of sources needed for this particular method
                %of detection or filtering...
                text.num_sources = uicontrol('style','text','parent',obj.dialog_handle,...
                    'string','Number of Sources:','units',units);
                extent = get(text.num_sources,'extent');
                set(text.num_sources,'position',[cur_pos(1:2),extent(3:4)]);
                
                cur_pos(1) = cur_pos(1)+extent(3)+delta/2;
                
                popup.num_sources = uicontrol('style','popupmenu','units',units,...
                    'parent',obj.dialog_handle,'string',num2str([1:max_num_sources]'),'value',obj.num_sources,...
                    'horizontalalignment','left');
                extent = get(popup.num_sources,'extent')+[0 0 40 0];
                    
                set(popup.num_sources,'units',units','position',[cur_pos(1:2),extent(3:4)]);
                
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta);

                
                %VI. Matlab function selection
                text.matlab_function = uicontrol('style','text','parent',obj.dialog_handle,...
                    'string','Matlab Function:','units',units,'visible','off');
                extent = get(text.matlab_function,'extent');
                set(text.matlab_function,'position',[cur_pos(1:2),extent(3:4)]);
                
                cur_pos(1) = cur_pos(1)+extent(3)+delta/2;
                
                extent = extent.*[1 1 1 1.5];
                edit.matlab_function = uicontrol('style','edit','parent',obj.dialog_handle,...
                    'string','','units',units,'position',[cur_pos(1:2), extent(3:4)],...
                    'backgroundcolor','w','visible','off');
                
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta);
                
                
                %VII. Method selection
                
                cur_pos(2) = cur_pos(2)-delta; %move back to the line we were just on
                
                text.method_select = uicontrol('style','text','parent',obj.dialog_handle,...
                    'string','Method:','units',units);
                extent = get(text.method_select,'extent');
                set(text.method_select,'position',[cur_pos(1:2),extent(3:4)]);
                
                cur_pos(1) = cur_pos(1)+extent(3)+delta/2;
              
                popup.method = uicontrol('style','popupmenu','units',units,...
                    'parent',obj.dialog_handle,'string',methods.evt_label,'value',1,...
                    'horizontalalignment','left');
                
                extent = get(popup.method,'extent')+[0 0 40 0];
                    
                set(popup.method,'units',units','position',[cur_pos(1:2),extent(3:4)]);

                cur_pos(1) = cur_pos(1)+extent(3)+delta/2;
                
                button.method_properties = uicontrol('style','pushbutton',...
                    'units',units,'parent',obj.dialog_handle,...
                    'string','properties');
                
                extent = get(button.method_properties,'extent')*1.2;
                cur_pos(2) = cur_pos(2)-delta/2;
                    
                set(button.method_properties,'position',[cur_pos(1:2),extent(3:4)]);
    
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta);

                set(0,'Units',units)
                scnsize = get(0,'ScreenSize');
                set(obj.dialog_handle,'position',[scnsize(3:4)/2-[max_width/2 cur_pos(2)/2] max_width cur_pos(2)],'visible','on');

                handles.checkbox = checkbox;
                handles.text = text;
                handles.edit = edit;
                handles.popup = popup;
                handles.delta = delta;
                handles.max_width = max_width;
                handles.button = button;
                handles.dialog = obj.dialog_handle;
                
                handles.user.methods = methods;
                
                set(popup.sources(1),'callback',{@popup_channel_source_callback,handles});
                set(popup.event_source,'callback',{@popup_event_source_callback,handles,size(obj.channel_names,1)+1});
                set(popup.method,'callback',{@method_popupCallback,handles});
                set(popup.num_sources,'callback',{@num_sources_popupCallback,handles});
                set(checkbox.synth_channel,'callback',{@checkbox_synth_channelCallback,handles});
                set(button.method_properties,'callback',{@method_propertiesCallback,handles});

                
                method_popupCallback(popup.method,[],handles);
                obj.num_sources = get(popup.num_sources,'value');
                if(obj.num_sources ==3)
                    set(popup.sources(1),'value',2);
                    set(popup.sources(2),'value',1);
                end
                
                uiwait(obj.dialog_handle);
                
                %output will contain a boolean matrix containing the on/off selection
                %values for each label that was created.  This is changed to just indices of the true values so
                %they can be used to determine
                %which values should be drawn along the entire night axes (axes2) in
                %updateAxes2 function
                if(ishghandle(obj.dialog_handle)) %if it is still a graphic, then...
                    
                    obj.num_sources = get(popup.num_sources,'value');
                    %create a new class if there is a synthesized name...
                    
                    % Synthesize channel based on previous channels..
                    
                    function_name = get(edit.matlab_function,'string');
                    source_indices = zeros(1,obj.num_sources);
                    
                    for k = 1:obj.num_sources
                        source_indices(k) = get(popup.sources(k),'value');
                    end;
                    
                    if(~isempty(function_name))
                        MARKING.showBusy();
                        set(obj.dialog_handle,'pointer','watch');
                        drawnow();

                        %                         function_call = [obj.detection_path(2:end),'.',function_name];
                        %                         detectStruct = feval(function_call,source_indices);

                        [detectStruct, detectorParams] = EVENT_CONTAINER.evaluateDetectFcn(function_name,source_indices);
                                                    
                        %detectStruct has the fields
                        %  .new_data
                        %  .new_events
                        %  .paramStruct
                        synth_new_channel = get(checkbox.synth_channel,'value');
                        channelIndex = get(popup.event_source,'value'); %this works in the case that the newly synthesized channel was chosen, since it is +1 than number of channels previously in existence
                        if(synth_new_channel)
                            synth_channel_name = get(edit.synth_channel,'string');
                            if(isempty(synth_channel_name))
                                synth_channel_name = 'Default Name';
                            end;
                            CHANNELS_CONTAINER.synthesizeChannel(detectStruct.new_data,source_indices,synth_channel_name);
                            CHANNELS_CONTAINER.align_channels_on_axes();
                        end;
                        
                        event_label = get(edit.event_label,'string');
                        if(isempty(event_label))
                            event_label = [synth_channel_name,'.',function_name,'.X'];
                        end;
                        source.channel_indices = source_indices;
                        source.algorithm = function_name;
                        preference_function = get(handles.button.method_properties,'userdata');
                        source.editor =  preference_function;
                        source.pStruct = detectorParams;
                        obj.updated_event_index = EVENT_CONTAINER.updateEvent(detectStruct.new_events,event_label,channelIndex,source,detectStruct.paramStruct);       
                        MARKING.showReady();
                    else
                        disp 'nothing happened';
                    end;
                    
                    disp('the dialog was closed');
                    delete(obj.dialog_handle);
                    obj.dialog_handle = [];
                else
                    disp('the dialog was closed');
                    obj.dialog_handle = [];
                end;
            end;
        end;
        
    end %end methods
       
end%end class definition

function method_propertiesCallback(hObject,eventdata,handles)
    preference_function = get(handles.button.method_properties,'userdata'); %or get(hObject,...)
    detection_labels = get(handles.popup.method,'string');
    method_index = get(handles.popup.method,'value');
    detection_label = detection_labels{method_index};
    if(~isempty(preference_function))
        try
            feval(preference_function,detection_label); %saves changes
        catch me1
            %perhaps their is no .plist file?
            try
               %run the detection method with no arguments to produce the
               %.plist data
               feval(strcat('detection.',handles.user.methods.mfile{method_index})); 
            catch me2
                %perhaps it failed, but the .plist data may exist now
                feval(preference_function,detection_label); %saves changes %let current error be thrown if still have problems at this point.
                %if not then just go ahead and crash here with me3
            end
        end
    end
end

function checkbox_synth_channelCallback(hObject,eventdata,handles)
    
    handles_to_change = [handles.text.synth_channel,handles.edit.synth_channel];

    synth_channel_index = size(get(handles.popup.event_source,'string'),1);
        
    if(get(hObject,'value'))
        set(handles_to_change,'enable','on');
        event_source_index = synth_channel_index;
    else
        set(handles_to_change,'enable','off');
        
        cur_index = get(handles.popup.event_source,'value');
        if(cur_index~=synth_channel_index)
            event_source_index = cur_index;
        else
            event_source_index = synth_channel_index;
        end;
        
    end;
    
    set(handles.popup.event_source,'value',event_source_index);

end


function popup_channel_source_callback(hObject,eventdata,handles)
%the destination channel that the event is attached to is automatically
%set to be the same as the parent channel (i.e. hObject's selection)
%so long as the "synthesize channel" option has not been clicked/selected
    if(get(handles.checkbox.synth_channel,'value')==0)
        set(handles.popup.event_source,'value',get(hObject,'value'));
    end
end

function popup_event_source_callback(hObject,eventdata,handles,synth_channel_index)
%the intent of this function is to simplify things for the user when they
%choose a synthesized channel to assign an event to, the synth channel box
%is automatically checked.
    if(get(hObject,'value')==synth_channel_index)
        set(handles.checkbox.synth_channel,'value',1);
    end;
end


function num_sources_popupCallback(hObject,eventdata,handles)
    resize(handles);            
end

function method_popupCallback(hObject,eventdata,handles)
%handles chaqnges in the selection of which method to apply to the given
%channels and adjusts the gui accordingly with the correct parameters for
%the given selection
    view_options = get(hObject,'string');
    current_selection = get(hObject,'value');

    methods = handles.user.methods;  %methods is a struct with the following fields
            %mfile = matlab file with the function
            %evt_label = label to assign to the event
            %num_reqd_indices = number of indices required/ 0 is no limit
            %params = parameter gui to use
            
%     set(handles.checkbox.synth_channel,'enable','on');


    set(handles.popup.num_sources,'enable','on');
        
    if(current_selection==numel(view_options)) %i.e. current_view,'Create New'))
        set([handles.text.matlab_function,handles.edit.matlab_function],'visible','on');
        set(hObject,'TooltipString','Enter your a matlab function name in the adjacent box');
    else
        set([handles.text.matlab_function,handles.edit.matlab_function],'visible','off');
        set(hObject,'TooltipString',help(fullfile('+detection',[methods.mfile{current_selection},'.m'])));        
    end;
    
    
    if(methods.num_reqd_indices(current_selection)==0)
        set(handles.popup.num_sources,'value',1,'enable','on');
    else
        set(handles.popup.num_sources,'value',methods.num_reqd_indices(current_selection),'enable','off');
    end;
    set(handles.edit.synth_channel,'string',methods.evt_label{current_selection});
    set(handles.edit.event_label,'string',methods.evt_label{current_selection});
    set(handles.edit.matlab_function,'string',methods.mfile{current_selection});
    
    set(handles.popup.event_source,'value',get(handles.popup.sources(1),'value')); %default to the current channel
        
    preference_function = methods.param_gui{current_selection};
    if(isempty(preference_function) || strcmp(preference_function,'none'))
        set(handles.button.method_properties,'visible','off');
        preference_function = [];
    else
        set(handles.button.method_properties,'visible','on');
    end
        
    
    set(handles.button.method_properties,'userdata',preference_function);
    checkbox_synth_channelCallback(handles.checkbox.synth_channel,[],handles);
    resize(handles);
end

function resize(handles)
    num_sources = get(handles.popup.num_sources,'value');
    sources_extent = get(handles.popup.sources(1),'position');
    delta = handles.delta;
    max_width = max(handles.max_width,num_sources*(delta+sources_extent(3))+delta);
    button = handles.button;
    for k=1:numel(handles.popup.sources)
        if(k<=num_sources)
            set(handles.popup.sources(k),'visible','on');
        else
            set(handles.popup.sources(k),'visible','off');
            
        end
    end
    
    %center the buttons
    button.OKpos=get(button.OK,'position');
    button.Cancelpos=get(button.Cancel,'position');
    button.OKpos(1)=max_width/2-delta/2-button.OKpos(3);
    button.Cancelpos(1)=max_width/2+delta/2;
    set(button.OK,'position',button.OKpos);
    set(button.Cancel,'position',button.Cancelpos);
    
    %handle the height of this place now...
    text_method_pos = get(handles.text.method_select,'position');
    popup_method_pos = get(handles.popup.method,'position');
    extent = get(handles.text.matlab_function,'extent');    
    
    %case 1: user is entering a matlab function to use
    if(strcmp(get(handles.text.matlab_function,'visible'),'on'))
        reference_pos = get(handles.text.matlab_function,'position');
        %then move the method selection above it.. 
        text_method_pos(2) = reference_pos(2)+delta+reference_pos(4);
        popup_method_pos(2) = reference_pos(2)+delta+reference_pos(4);
        set(handles.text.method_select,'position',text_method_pos);
        set(handles.popup.method,'position',popup_method_pos);        
        
    %case 2: user has selected a drop down menu list..
    else
        reference_pos = get(handles.text.num_sources,'position');
        %then move the method selection above it.. 
        text_method_pos(2) = reference_pos(2)+delta+reference_pos(4);
        popup_method_pos(2) = reference_pos(2)+delta+reference_pos(4);
        set(handles.text.method_select,'position',text_method_pos);
        set(handles.popup.method,'position',popup_method_pos);        
    end;
   
    dlg_pos = get(handles.dialog,'position'); %resize the dialog
    dlg_pos(4) = popup_method_pos(2)+delta+extent(4);
    dlg_pos(3) = max_width;
    set(handles.dialog,'position',dlg_pos);

end
                


function [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta)
    %move up and align left
    cur_pos(1) = cur_pos(1)+extent(3)+delta;
    max_width = max(max_width,cur_pos(1));
    cur_pos(2)=cur_pos(2)+delta/2+extent(4);
    cur_pos(1) = delta;
end
