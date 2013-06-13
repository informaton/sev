function [addedRowIndex,addedHandles] = addControlsRowToPanel(panel_h,lowest_tag_suffix_index,height_offset)
%panel_h is the handle of the panel that is to be resized
%lowest_tag_suffix_value is the integer number that is a suffix for the tags of all
%uicontrols that are to have added copies made below.  
%addedRowIndex is lowest_tag_suffix_index+1;
%Written by : Hyatt Moore IV

if(nargin<3)
    height_offset = 0.1;
end
old_tag_suffix = sprintf('_%u',lowest_tag_suffix_index);
new_tag_suffix = sprintf('_%u',lowest_tag_suffix_index+1);

uicontrol_h = findobj(allchild(panel_h),'-regexp','tag',['.*',old_tag_suffix]);
templates = createTemplatesFromHandles(uicontrol_h);


addedHandles = zeros(size(uicontrol_h));
for h=1:numel(uicontrol_h)
    tag = get(uicontrol_h(h),'tag');
    tag = strrep(tag,old_tag_suffix,new_tag_suffix);
    templates{h}.tag = tag;    
    templates{h}.position(:,2)=  templates{h}.position(:,2)-height_offset;
    addedHandles(h) = uicontrol(templates{h});
end

addedRowIndex = lowest_tag_suffix_index+1;

