%> @file CLASS_compareEvents_dialog.m
%> @brief CLASS_compareEvents_dialog creates a dialog to access marking parameters.
% ======================================================================
%> @brief CLASS_compareEvents_dialog provides backbone for creating gui
%> to select events for comparison within the SEV's single study mode.
%>
%> Use run() method to create the dialog to access marking parameters.
%> @note Uses global instance of CLASS_events_container and should be
%> updated.
% History
% Written by: Hyatt Moore, IV (< June, 2013)
% ======================================================================
classdef CLASS_compareEvents_dialog < handle
    properties
        %> handle to the GUI dialog figure created by <b>run</b> method
        dialog_handle;
        %>cell containing labels that can be used; obtained from global instance
        %of CLASS_events_container.
        event_labels; 
        %> @brief cell of labels for the bounds that can be chosen with a dropdown
        %widget; defaults to 'Entire night' and 'Current View'
        bounds_labels; 
        %> index of the boundary label that was selected
        selected_events; 
        %> index of the event labels that were selected for comparison
        selected_bounds; 
        %> @brief how many different events to compare against each other
        %at once (currently, just 2)
        num_events_to_compare; 
    end;
    
    methods
        
        % =================================================================
        %> @brief class constructor
        %> @retval obj instance of CLASS_compareEvents_dialog class.
        %> @note uses a global reference to <b>EVENT_CONTAINER</b> to obtain event labels, and
        %> needs updating.
        % =================================================================
        function obj = CLASS_compareEvents_dialog()
            global EVENT_CONTAINER;
%             obj.event_labels = {'Create New','HP_20Hz','Ocular Movement'};
            obj.bounds_labels = {'Entire night','Current View'};
            obj.dialog_handle = [];            
            obj.num_events_to_compare = 2;
            event_list = cell(EVENT_CONTAINER.num_events,1);
            for k=1:EVENT_CONTAINER.num_events
                event_list{k} = [EVENT_CONTAINER.cell_of_events{k}.label,' (',num2str(EVENT_CONTAINER.channel_vector(k)),')'];
            end
            obj.event_labels = event_list;
            obj.selected_bounds = 2;

        end;
        % =================================================================
        %> @brief Starts the GUI to compare events found in the SEV.
        %> @param obj instance of CLASS_compareEvents_dialog class.
        %> @param varargin - ?
        %> @retval selected_event_indices indices of the selected events
        %(defaults to null)
        %> @retval selected_bounds selected bounds for comparing events
        %> across.
        % =================================================================
        function [selected_event_indices, selected_bounds] = run(obj,varargin)
            selected_event_indices = []; %default to 0
            selected_bounds = [];
            if(isempty(obj.dialog_handle)||~ishandle(obj.dialog_handle))
                
                max_width = 0; %keep track of the width and get the largest chunk as the dialog grows/changes
                delta = 20;
                cur_pos = [delta, delta, 0 0]; %bottom left position
                units = 'points';
                
                obj.dialog_handle = dialog('visible','off','units',units,'name','Event Comparison Selection','position',[0 0 0.1 0.1]);
                
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
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
                %II Figure out how much   
                
                set(obj.dialog_handle,'visible','on');
                
                pan_results = uipanel('title','Results','parent',obj.dialog_handle,'units',units);
                
                %make room for the panel...
                
                columnnames = {obj.event_labels{2},['NOT ',obj.event_labels{2}]};
                rownames = {obj.event_labels{1},['NOT ',obj.event_labels{1}]};
                table_results = uitable('parent',pan_results,'units',units,'data',[1 2; 3 4],'columnName',columnnames,...
                    'rowName',rownames);
                
                extent = get(table_results,'extent');
                
                pan_pos = cur_pos;
                cur_pos(1:2) = cur_pos(1:2)+delta*2+extent(3:4);
                
                
                pan_pos(3:4) = cur_pos(1:2)-pan_pos(1:2);
                set(pan_results,'position',pan_pos);


                set(table_results,'position',[delta, delta, extent(3:4)]),
                
                
                extent = [0 0 delta 0];
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %III Boundaries of Comparison
                pan_bounds = uipanel('title','Boundary of Comparison','parent',obj.dialog_handle,'units',units);
                %make room for the panel...
                pan_pos = cur_pos;
                cur_pos(1:2) = cur_pos(1:2)+delta;
                
                popup.bounds=uicontrol('style','popupmenu','units',units,...
                        'parent',pan_bounds,'string',obj.bounds_labels,...
                        'horizontalalignment','left','value',obj.selected_bounds);
                extent = get(popup.bounds,'extent')+[0 0 65 0];
                    
                set(popup.bounds,'units',units','position',[delta, delta,extent(3:4)]);
                
                cur_pos(1:2)=cur_pos(1:2)+extent(3:4)+delta; %at the far, top-right, corner of the panel's position now
                
                pan_pos(3:4) = cur_pos(1:2)-pan_pos(1:2);
                set(pan_bounds,'position',pan_pos);

                extent = [0 0 delta 0];
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                pan_compare = uipanel('title','Events To Compare','parent',obj.dialog_handle,'units',units);
                %make room for the panel...
                pan_pos = cur_pos;
                cur_pos(1:2) = cur_pos(1:2)+delta;
                
                
                
                %IV Source Labels for Event Selection
                for k=1:obj.num_events_to_compare
                    popup.sources(k)=uicontrol('style','popupmenu','units',units,...
                        'parent',obj.dialog_handle,'string',obj.event_labels,...
                        'horizontalalignment','left','value',k);
                    extent = get(popup.sources(k),'extent')+[0 0 65 0];
                    
                    set(popup.sources(k),'units',units','position',[cur_pos(1:2),extent(3:4)]);
                    cur_pos(1)=cur_pos(1)+extent(3)+delta;  %move to the right...
                    
                end;
                
                set(popup.sources,'callback',{@source_selection_callback,popup.sources,table_results});
                
                %get the right selection for the first look...
                source_selection_callback(popup.sources(1),[],popup.sources,table_results);
                
                
                max_width = max(max_width,cur_pos(1));
                
                cur_pos(2)=cur_pos(2)+extent(4)+delta;  %move up to the next row
                
                pan_pos(3:4) = cur_pos(1:2)-pan_pos(1:2);
                set(pan_compare,'position',pan_pos);

                extent = [0 0 delta 0];
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta);
                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                
                
                %center the buttons
                button.OKpos=get(button.OK,'position');
                button.Cancelpos=get(button.Cancel,'position');
                button.OKpos(1)=max_width/2-delta/2-button.OKpos(3);
                button.Cancelpos(1)=max_width/2+delta/2;
                set(button.OK,'position',button.OKpos);
                set(button.Cancel,'position',button.Cancelpos);
                
                set(0,'Units',units)
                scnsize = get(0,'ScreenSize');
                set(obj.dialog_handle,'position',[scnsize(3:4)/2-[max_width/2 cur_pos(2)/2] max_width cur_pos(2)],'visible','on');
                
                uiwait(obj.dialog_handle);
                
                
                %output will contain a boolean matrix containing the on/off selection
                %values for each label that was created.  This is changed to just indices of the true values so
                %they can be used to determine
                %which values should be drawn along the entire night axes (axes2) in
                %updateAxes2 function
                if(ishghandle(obj.dialog_handle)) %if it is still a graphic, then...
                    selected_event_indices = cell2mat(get(popup.sources,'value'));
                    obj.selected_events = selected_event_indices;
                    selected_bounds = get(popup.bounds,'value');
                    obj.selected_bounds = selected_bounds;
                    delete(obj.dialog_handle);
                    obj.dialog_handle = [];
                else
                    disp('Selection was cancelled');                    
                    obj.dialog_handle = [];
                end;
            end;

        end; %end run
        
    end %end methods
       
end%end class definition

function source_selection_callback(hObject,eventdata,source_handles,table_handle)
    global EVENT_CONTAINER;
    selections = cell2mat(get(source_handles,'value'));
    event_labels = get(hObject,'string');
    
    columnnames = {event_labels{selections(2)},['NOT ',event_labels{selections(2)}]};
    rownames = {event_labels{selections(1)},['NOT ',event_labels{selections(1)}]};
    data = EVENT_CONTAINER.calculateQuadAnalysis(selections);
    set(table_handle,'columnName',columnnames,'rowName',rownames,'data',data);
    extent = get(table_handle,'extent');
    pos = get(table_handle,'position');
    set(table_handle,'position',[pos(1:2), extent(3:4)]);
                        
end



function [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta)
    %move up and align left
    cur_pos(1) = cur_pos(1)+extent(3)+delta;
    max_width = max(max_width,cur_pos(1));
    cur_pos(2)=cur_pos(2)+delta/2+extent(4);
    cur_pos(1) = delta;
end
