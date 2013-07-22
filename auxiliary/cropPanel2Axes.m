function cropPanel2Axes(fig_h,axes_h)
%places axes_h in middle of figure with handle fig_h
%useful for prepping screen captures

% Hyatt Moore IV
% 2/21/2013

fig_units_in = get(fig_h,'units');
axes_units_in = get(axes_h,'units');

set(fig_h,'units','pixels');
set(axes_h,'units','pixels');


a_pos = get(axes_h,'position'); %x, y, width, height
f_pos = get(fig_h,'position');

a_width = a_pos(3);
a_height = a_pos(4);

set(axes_h,'position',[a_width*0.025,a_height*0.2,a_width,a_height]);
set(fig_h,'position',[f_pos(1),f_pos(2),a_width*1.05,a_height*1.3]);


%reset units to original
set(fig_h,'units',fig_units_in);
set(axes_h,'units',axes_units_in);

