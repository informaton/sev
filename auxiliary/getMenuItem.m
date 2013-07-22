function str = getMenuItem(hObject)
% str = getMenuItem(hObject)
% helper function to get the current string line for the passed
% uimenu handle (hObject)

% Hyatt Moore IV (< June, 2013)

choices=get(hObject,'string');
if(iscell(choices))
    str = choices{get(handles.(menu_fieldLogic_tag),'value')};
else
    str = choices; 
end
        