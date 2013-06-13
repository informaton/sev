%graphic helper functions
% Hyatt Moore (< June 2013)
% June 13, 2013 note: these may not be used anymore - an older style from what I can tell
function interaction
    close all;
    f=figure;
    set(f,'windowbuttondownfcn',@startMarking);
    units = get(f,'units');
    axes('units',units,'xlimmode','manual','ylimmode','manual','xlim',[-1 1],'ylim',[0 2]);

%     rectangle = annotation('rectangle',position,'units',get(f,'units'));
%     overlay= get(rectangle,'parent');
%     set(overlay,'units',get(gca,'units'),'position',get(gca,'position'),...
%         'outerposition',get(gca,'outerposition'));
%     set(rectangle,'handlevisibility','off','hittest','off');
%     tags2delete = {'center','top','topleft','topright',...
%         'bottom','bottomright','bottomleft'};
%     
%     for k=1:numel(tags2delete)
%         delete(findobj(allchild(rectangle),'flat','tag',tags2delete{k}));
%     end;
%     
%     tags2set = {'left','right'};
%     for k=1:numel(tags2set)
%         set(findobj(allchild(rectangle),'flat','tag',tags2set{k}),'hittest','on',...
%             'buttondownfcn',@enableDrag,'visible','on','handlevisibility','on');
%     end
end

function startMarking(hObject,eventdata)


    if(strcmp(get(gco,'type'),'axes'))
        mouse_pos = get(gca,'currentpoint');
        mouse_pos = mouse_pos(1,:);
        w = 0.01;
        h = 0.1;
        rect_pos = [mouse_pos(1),mouse_pos(2)-h/2,w,h];
        hg_group = hggroup('parent',gca,'hittest','off','handlevisibility','off');
        %     set(gca,'handlevisibility','off','hittest','off');
        % hg_group = gca;
        surface('parent',hg_group,'xdata',repmat(mouse_pos(1),2,2),'ydata',repmat([rect_pos(2);rect_pos(2)+rect_pos(4)],1,2),'zdata',zeros(2),'cdata',1,'hittest','on','tag','surface');
        rectangle('parent',hg_group,'position',rect_pos,...
            'hittest','on','handlevisibility','on','tag','rectangle'); %turn this on so as not to be interrupted by other mouse clicks on top of this one..
        
        line('marker','o','xdata',mouse_pos(1),'ydata',mouse_pos(2),'parent',hg_group,...
            'handlevisibility','on','hittest','on','tag','left','selected','off',...
            'userdata',hg_group,'buttondownfcn',@enableDrag);
        hr =line('marker','o','xdata',mouse_pos(1),'ydata',mouse_pos(2),'parent',hg_group,...
            'handlevisibility','on','hittest','on','tag','right','selected','on',...
            'userdata',hg_group,'buttondownfcn',@enableDrag);
        
        set(hObject,'currentobject',hr);
        set(hObject,'WindowButtonMotionFcn',@dragEdge);
        set(hObject,'WindowButtonUpFcn',@disableDrag)
    end;
end

function dragEdge(hObject,eventdata)
    mouse_pos = get(gca,'currentpoint');
   
    cur_obj = gco;  %findobj(allchild(rectangle_h),'flat','selected','on');
    side = get(cur_obj,'tag');

    h_group = get(cur_obj,'userdata');
    rectangle_h = findobj(h_group,'tag','rectangle');
    surf_h = findobj(h_group,'tag','surface');
    rec_pos = get(rectangle_h,'position');
    w=0;
    if(strcmp(side,'left'))
        w = rec_pos(1)-mouse_pos(1)+rec_pos(3);
        rec_pos(1) = mouse_pos(1);
        if(w<0)
            w=-w;
            rightObj = findobj(h_group,'tag','right');
            rightObj = rightObj(1);
            rec_pos(1)=get(rightObj,'xdata');
            set(cur_obj,'tag','right');
            set(rightObj,'tag','left');            
        else
            set(cur_obj,'xdata',mouse_pos(1));
        end;
    elseif(strcmp(side,'right'))
        w = mouse_pos(1)-rec_pos(1);
        if(w<0)
            rec_pos(1)=mouse_pos(1);
            w=-w;
            leftObj = findobj(h_group,'tag','left');
            leftObj = leftObj(1);
            set(leftObj,'tag','right');
            set(cur_obj,'tag','left');            
        else
            set(cur_obj,'xdata',mouse_pos(1));            
        end;

    else
        disp 'oops.';
    end;

    if(w==0) 
        w=0.001;
    end;

    rec_pos(3) = w;
    set(rectangle_h,'position',rec_pos);
    set(surf_h,'xdata',repmat([rec_pos(1),rec_pos(1)+rec_pos(3)],2,1),'ydata',repmat([rec_pos(2);rec_pos(2)+rec_pos(4)],1,2));

    
    
end

function enableDrag(hObject,eventdata)
    disp 'hello'
    fig = gcf;
    set(hObject,'selected','on');
    set(fig,'WindowButtonMotionFcn',@dragEdge); 
    set(fig,'WindowButtonUpFcn',@disableDrag)
    
end

function disableDrag(hObject,eventdata)
    disp 'goodbye'
    fig = gcf;
    
    cur_obj = gco; %findobj(allchild(rectangle_h),'flat','selected','on');
    
    if(ishandle(cur_obj))
        set(cur_obj,'selected','off');
%         set(fig,'currentobject',rectangle_h); %this disables the current object...
    end;
    set(fig,'WindowButtonUpFcn','');
    set(fig,'WindowButtonMotionFcn','');
end
