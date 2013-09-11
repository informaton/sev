%> @file CLASS_marking_dialog.m
%> @brief CLASS_marking_dialog creates a dialog to access marking parameters.
% ======================================================================
%> @brief CLASS_marking_dialog may not be supported.  See
%CLASS_compareEvents_dialog which has similar documentation in source file.
%
%> run method creates a dialog to access marking parameters.
%> @note Uses global instance of CLASS_UI_marking and should be
%> updated.
% 
% 
% History
% Written by: Hyatt Moore, IV (< June, 2013)
% ======================================================================
classdef CLASS_marking_dialog < handle

    properties
        %> handle to the GUI (i.e. figure)
        dialog_handle;
        %>cell containing labels that can be used 
        event_labels; 
        %>string containing the selected label
        selected_label; 
    end;
    
    methods
        % =================================================================
        %> @brief class constructor for CLASS_marking_dialog class
        %> @retval obj instance of CLASS_marking_dialog class.
        %> @note uses a global reference to <b>MARKING</b> to obtain event labels, and
        %> needs updating.
        % =================================================================
        function obj = CLASS_marking_dialog()
            obj.dialog_handle = [];            
        end;
        
        function [selected_label] = run(obj,varargin)
            global MARKING;
            obj.event_labels = MARKING.event_label_cell;
            
            if(isempty(obj.dialog_handle)||~ishandle(obj.dialog_handle))
                
                event_choice = numel(obj.event_labels);
                
                %use a previously loaded selection...
                if(numel(varargin)>0)
                    tmp_event_choice = find(strcmp(obj.event_labels,varargin{1}),1);
                    if(tmp_event_choice)
                        event_choice = tmp_event_choice;
                    end;
                end;
                max_width = 0; %keep track of the width and get the largest chunk as the dialog grows/changes
                delta = 15;
                cur_pos = [delta, delta, 0 0]; %bottom left position 
                units = 'points';
                
                obj.dialog_handle = dialog('visible','off','units',units,'name','Marking Label');
                
                %work way up from the bottom....
                %I.  Establish Buttons
                %buttons to say cancel or OK
                button.OK = uicontrol('parent',obj.dialog_handle,'style','pushbutton','string','OK',...
                    'units',units,'callback','uiresume(gcbf)');
                button.Cancel = uicontrol('parent',obj.dialog_handle,'style','pushbutton','string','Cancel',...
                    'units',units,'callback','output = false,close(gcbf)');
                button_extent = max(get(button.OK,'extent'),get(button.Cancel,'extent'))*1.2;
                
                cur_pos(1)=delta;
                set(button.OK,'position',[cur_pos(1:2),button_extent(3:4)]);
                cur_pos(1)=cur_pos(1)+button_extent(3)+delta;
                set(button.Cancel,'position',[cur_pos(1:2),button_extent(3:4)]);
                
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,button_extent,delta);

                                
                %II.  New Label (text - edit)
                text.event_label = uicontrol('style','text','parent',obj.dialog_handle,...
                    'string','New labell:','units',units);
                extent = get(text.event_label,'extent');
                set(text.event_label,'position',[cur_pos(1:2),extent(3:4)]);
                cur_pos(1) = cur_pos(1)+extent(3)+delta/2;
                
                extent = extent.*[1 1 2 1.5];
                edit.event_label = uicontrol('style','edit','parent',obj.dialog_handle,...
                    'string','','units',units,'position',[cur_pos(1:2), extent(3:4)],...
                    'backgroundcolor','w');
                
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta);

                popup.event_label=uicontrol('style','popupmenu','units',units,...
                    'parent',obj.dialog_handle,'string',char(obj.event_labels),...
                    'horizontalalignment','left','value',event_choice);
                
                extent = get(popup.event_label,'extent')+[0 0 65 0];                    
                set(popup.event_label,'units',units','position',[cur_pos(1:2),extent(3:4)]);
                
                [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta);

                set(0,'Units',units)
                scnsize = get(0,'ScreenSize');
                set(obj.dialog_handle,'position',[scnsize(3:4)/2-[max_width/2 cur_pos(2)/2] max_width cur_pos(2)],'visible','on');

                handles.text = text;
                handles.edit = edit;
                handles.popup = popup;
                handles.delta = delta;
                handles.max_width = max_width;
                handles.button = button;
                handles.dialog = obj.dialog_handle;
                                
                set(popup.event_label,'callback',{@event_label_popupCallback,handles});
                
                event_label_popupCallback(popup.event_label,[],handles)

                uiwait(obj.dialog_handle);
                
                %output will be true or false based on success of update
                if(ishghandle(obj.dialog_handle)) %if it is still a graphic, then...
                    event_selection = get(handles.popup.event_label,'value');
                    if(event_selection==1)
                        obj.selected_label = get(handles.edit.event_label,'string');
                    else
                        obj.selected_label = obj.event_labels{event_selection};
                    end;
                    
                    delete(obj.dialog_handle);
                    obj.dialog_handle = [];
                else
                    obj.selected_label = '';
                    obj.dialog_handle = [];
                end;
                selected_label = obj.selected_label;
                
                if(~isempty(selected_label))
                    %update the global variable that holds the possible labels
                    if(~any(strcmp(selected_label,MARKING.event_label_cell)))
                        MARKING.event_label_cell{end+1}=selected_label;
                    end;
                end
                
            end;
        end;
        
    end %end methods
       
end%end class definition


%supporting functions...
function event_label_popupCallback(hObject,eventdata,handles)
    if(get(hObject,'value')==1) 
        set([handles.text.event_label,handles.edit.event_label],'visible','on');
    else
        set([handles.text.event_label,handles.edit.event_label],'visible','off');
    end
end

function [max_width, cur_pos] = move_a_row_up(max_width,cur_pos,extent,delta)
    %move up and align left
    cur_pos(1) = cur_pos(1)+extent(3)+delta;
    max_width = max(max_width,cur_pos(1));
    cur_pos(2)=cur_pos(2)+delta/2+extent(4);
    cur_pos(1) = delta;
end
