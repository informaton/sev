function disableFigureHandles(figure_handle)
%disable figure's handles as specified by guidata call

%Author Hyatt Moore
%10.5.12
if(ishandle(figure_handle))
    
    handles = guidata(figure_handle);
    names = fieldnames(handles);
    for k = 1:length(names)
        cur_handle = handles.(names{k});
        if(~isstruct(cur_handle))
            setDisable(cur_handle)
        else
            if(isstruct(cur_handle))
                childnames = fieldnames(cur_handle);
                for c = 1:numel(childnames)
                    cur_child_handle = cur_handle.(childnames{c});
                    if(ishandle(cur_child_handle))
                        setDisable(cur_child_handle);
                    end
                end
            end
        end
    end
end

toolbar_h = findobj(allchild(figure_handle),'type','uitoolbar');
if(all(ishandle(toolbar_h)))
    setDisable(allchild(toolbar_h));
end
    

function setDisable(handle)
if(isprop(handle,'enable'))
    set(handle,'enable','off');
end
