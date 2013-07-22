function [addedRowIndex,addedHandles] = resizePanelAndParentForAddedControls(panel_h,lowest_tag_suffix_index)
% [addedRowIndex,addedHandles] = resizePanelAndParentForAddedControls(panel_h,lowest_tag_suffix_index)
%
% panel_h is the handle of the panel that is to be resized
% lowest_tag_suffix_value is the integer number that is a suffix for the tags of all
% uicontrols that are to have added copies made below.  
% addedRowIndex is lowest_tag_suffix_index+1;

% Hyatt Moore, IV (< June, 2013)
parent_h = get(panel_h,'parent');
peer_h = get(parent_h,'children');
pan_children = get(panel_h,'children');

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

%get the peers that are higher than the panel, as these will need to be
%adjusted up as well with the panels resizing as the figure's height
%increases.
peers_above = peer_pos(:,2)>panel_pos(2);

% concerned about children that are higher than the panel, as the panel height increases here.

old_tag_suffix = sprintf('_%u',lowest_tag_suffix_index);
new_tag_suffix = sprintf('_%u',lowest_tag_suffix_index+1);

uicontrol_h = findobj(pan_children,'-regexp','tag',['.*',old_tag_suffix]);
templates = createTemplatesFromHandles(uicontrol_h);

first_uicontrol_h = findobj(pan_children,'-regexp','tag',['.*_1']);
first_uicontrol_pos = get(first_uicontrol_h,'position');
if(iscell(first_uicontrol_pos))
    first_uicontrol_pos = cell2mat(first_uicontrol_pos);
end

height_offset = max(first_uicontrol_pos(:,4));

pan_children_pos = cell2mat(get(pan_children,'position'));
pan_children_pos(:,2)=pan_children_pos(:,2)+height_offset;

panel_pos(4) = panel_pos(4)+height_offset; %grow it...
parent_pos(4) = parent_pos(4)+height_offset; %grow it...
parent_pos(2) = parent_pos(2)-height_offset; %move it down...

set(parent_h,'position',parent_pos);
set(panel_h,'position',panel_pos);

%adjust everything up the newly resized panel
for k =1:numel(pan_children)
    if(pan_children_pos(4)>0)
        set(pan_children(k),'position',pan_children_pos(k,:));
    end;
    set(pan_children(k),'units',pan_children_units0{k}); 
end

addedHandles = zeros(size(uicontrol_h));
for h=1:numel(uicontrol_h)
    tag = get(uicontrol_h(h),'tag');
    tag = strrep(tag,old_tag_suffix,new_tag_suffix);
    templates{h}.tag = tag;    
    templates{h}.position(:,2)=  templates{h}.position(:,2); %put it right where the old one used to be
    addedHandles(h) = uicontrol(templates{h});
end

addedRowIndex = lowest_tag_suffix_index+1;
set(parent_h,'units',parent_units0);
for k=1:numel(peer_h)
    if(peers_above(k))
        set(peer_h(k),'position',peer_pos(k,:)+[0 height_offset 0 0]);
    end
    set(peer_h(k),'units',peer_units0{k})
end
