%userful for taking screenshots of the current figure in vector format

% Hyatt Moore IV
% < June, 2013

h = allchild(0);
fig_tag = 'sev_main_fig';
sev_h = strfind(get(h,'tag'),fig_tag);

if(~isempty(sev_h) && sev_h~=0)
    sev_h = h(sev_h);
%     screencapture('toolbar',sev_h);
    set(sev_h,'inverthardcopy','off'); %don't try to save toner ink here
    fmt = 'epsc';
    ext = '.eps';
    this_path = fileparts(mfilename('fullpath'));
    save_filename =  fullfile(this_path,strcat(fig_tag,ext));
    
    print(sev_h,strcat('-d',fmt),save_filename);
    
end