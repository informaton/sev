function [handles] = sizePanelAndParentForUIControls(panel_h,numControls,handles)
%panel_h is the handle of the panel that is to be resized
%numControls is a scalar containing the number of rows of controls to be set in the
%panel
%panel_h must have at least one row of uicontrols present with the suffix _1
%addedHandles is the handles added
%
%written by Hyatt Moore IV
%modified: 10.16.2012

parent_h = get(panel_h,'parent');
peer_h = get(parent_h,'children');
pan_children = get(panel_h,'children');

pan_children_tag = get(pan_children,'tag');
f=regexp(pan_children_tag,'.*_(?<suffix>\d+)','names');
suffixes = zeros(numel(f),1);

for k=1:numel(f)
    if(isempty(f{k}))
        suffixes(k)=-1;
    else
        suffixes(k) = str2double(f{k}.suffix);
    end
end

max_suffix = max(suffixes);


if(max_suffix~=numControls)  %need to adjust up or down, otherwise no change is needed
    %get the units so we can restore later
    parent_units0 = get(parent_h,'units');
    peer_units0 = get(peer_h,'units');
    pan_children_units0 = get(pan_children,'units');
    if(numel(peer_h)==1) %only dealing with the panel itself, so don't worry about things
        peer_units0 = {peer_units0};
    end
    if(~iscell(pan_children_units0))
        pan_children_units0 =  {pan_children_units0};
    end
    
    %normalize the units to pixels
    set([parent_h;peer_h;pan_children],'units','pixels');
    
    panel_pos = get(panel_h,'position');
    parent_pos = get(parent_h,'position');
    peer_pos = get(peer_h,'position');
    
    if(iscell(peer_pos))
        peer_pos = cell2mat(peer_pos);
    end
    
    first_uicontrol_h = findobj(pan_children,'-regexp','tag','.*_1');
    first_templates = createTemplatesFromHandles(first_uicontrol_h);
    first_uicontrol_pos = get(first_uicontrol_h,'position');
    
    if(iscell(first_uicontrol_pos))
        first_uicontrol_pos = cell2mat(first_uicontrol_pos);
    end
    
    %get the bottom most ui controls, these have good position
    last_uicontrol_h = findobj(pan_children,'-regexp','tag',['.*',num2str(max_suffix)]);
    last_templates = createTemplatesFromHandles(last_uicontrol_h);
    last_uicontrol_pos = get(last_uicontrol_h,'position');
    
    if(iscell(last_uicontrol_pos))
        last_uicontrol_pos = cell2mat(last_uicontrol_pos);
    end
    
    pan_children_pos = cell2mat(get(pan_children,'position'));
    
    height_offset = max(first_uicontrol_pos(:,4));
    peers_above = peer_pos(:,2)>panel_pos(2);  %peers above

    if(max_suffix>numControls) %remove controls and shrink
%         peers_diff = peer_pos(:,2)<panel_pos(2); %peers below - not
%         important here
%         total_height_change  =-height_offset*(max_suffix-numControls);
        templates = first_templates;
        for k=1:max_suffix %numControls+1:max_suffix
            for h=1:numel(templates)
                tag = get(first_uicontrol_h(h),'tag');
                tag = strrep(tag,'_1',['_',num2str(k)]);
                if(k>numControls)
                    pan_children_pos(pan_children==handles.(tag),:) = [];
                    pan_children(pan_children==handles.(tag)) = [];
                    delete(handles.(tag));
                    handles = rmfield(handles,tag);
                else
                    cur_ind = pan_children==handles.(tag);
                    pan_children_pos(cur_ind,2) = pan_children_pos(cur_ind,2)-(max_suffix-numControls+1)*height_offset; 
                end
            end
        end
                
    elseif(max_suffix<numControls) %add controls and grow
        % concerned about children that are higher than the panel, as the panel height increases here.
        %so get the peers that are higher than the panel, as these will need to be
        %adjusted up as well with the panels resizing as the figure's height
        %increases.
%         total_height_change = height_offset*(numControls-max_suffix+1);
        templates = last_templates;
        for k=max_suffix+1:numControls
            for h=1:numel(templates)
                tag = get(last_uicontrol_h(h),'tag');
                tag = strrep(tag,['_',num2str(max_suffix)],['_',num2str(k)]);
                templates{h}.tag = tag;
                templates{h}.position(:,2) = templates{h}.position(:,2)-height_offset*(numControls-k+0); %put it right where the old one used to be
                handles.(tag) = uicontrol(templates{h});
                pan_children_units0 = [pan_children_units0;templates{h}.Units];
                pan_children = [pan_children;handles.(tag)];
                pan_children_pos = [pan_children_pos;templates{h}.position];
                %             handles.(tag) = addedhandles(h);
            end
        end        
    end
    
    total_height_change= -panel_pos(4)+(numControls+1.5)*height_offset;
    panel_pos(4) = (numControls+1.5)*height_offset; %panel_pos(4)+total_height_change; %shrink it...
    parent_pos(4) = parent_pos(4)+total_height_change; %shrink it...
    parent_pos(2) = parent_pos(2)-total_height_change; %move it up...

    
    %move the peers above up according to the changed shape...
    peer_pos(peers_above,2) = peer_pos(peers_above,2)+(total_height_change);

    set(parent_h,'position',parent_pos);
    peer_pos(peer_h==panel_h,:) = panel_pos;


    for k=1:numel(peer_h)
        %         if(peer_h(k)~=panel_h)
        set(peer_h(k),'position',peer_pos(k,:),'units',peer_units0{k})
        %else
        %             set(panel_h,'position',panel_pos);
        %         end
    end
%     
%     %pan_children_pos(:,2)=pan_children_pos(:,2)+total_height_change;
%     for k=1:numControls
%         for h=1:numel(templates)
%             tag = get(last_uicontrol_h(h),'tag');
%             tag = strrep(tag,['_',num2str(max_suffix)],['_',num2str(k)]);
%             pos = last_uicontrol_pos{h};
%             pos(2) = pos(2)+k*height_offset;
%             set(handles.(tag),'position',pos);
%             set(handles.(tag),'units',
%         end
%     end

    
    %adjust everything up the newly resized panel
    for k=1:numel(pan_children)
        set(pan_children(k),'position',pan_children_pos(k,:),'units',pan_children_units0{k});
    end
    
    set(parent_h,'units',parent_units0);
end