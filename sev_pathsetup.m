function sev_pathname = sev_pathsetup()
    
    import plist.*; %struct to xml plist format conversions and such
    import detection.*; %detection algorithms and such
    import filter.*;
    
    sev_pathname = fileparts(mfilename('fullpath'));
    addpath(sev_pathname);
    addpath(fullfile(sev_pathname,'auxiliary'));
    addpath(fullfile(sev_pathname,'widgets'));
    
    if ispc
        % To get the uigetfulldir.m
        widgets_pathname = fullfile(sev_pathname, '..\padaco\views\widgets\');
        addpath(widgets_pathname);
        
        sig_pathname = fullfile(sev_pathname, '..\matlab\signal');        
        addpath(sig_pathname);        
    end
    
end