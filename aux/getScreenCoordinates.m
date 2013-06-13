function pixel_coord = getScreenCoordinates(ghandle)
% pixel_coord = getScreenCoordinates(ghandle)
% returns the absolute screen coordinates of the passed
% graphic handle (ghandle)


% Written by: Hyatt Moore IV, < June, 2013

if(ishandle(ghandle))
    %     screen_size = get(0,'Screensize');
    %     width = screen_size(3);
    %     height = screen_size(4);
    %
    g_units = get(ghandle,'units');
    set(ghandle,'units','pixels');
    pixel_coord = get(ghandle,'position');
    set(ghandle,'units',g_units);
    parenth = get(ghandle,'parent');

    while(parenth~=0)
        tmp_units = get(parenth,'units');
        set(parenth,'units','pixels');
        tmp_pos = get(parenth,'position');
        set(parenth,'units',tmp_units);
        pixel_coord(1:2) = tmp_pos(1:2)+pixel_coord(1:2);  %track back to the beginning
        parenth = get(parenth,'parent');  %go up
    end
        
end