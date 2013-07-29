function varargout = sev(varargin)
% sev M-file for sev.fig
%      sev, by itself, creates a new sev or raises the existing
%      singleton*.
%
%      H = sev returns the handle to a new sev or the handle to
%      the existing singleton*.
%
%      sev('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in sev.M with the given input arguments.
%
%      sev('Property','Value',...) creates a new sev or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sev_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sev_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
%varargin{1} = text file to load SEV parameters from (default is to check
%'sev_parameters.txt'
%
%  Author: Hyatt Moore IV
% edits:
% 9/30-10/1/2012 incorporated CLASS_events_marking and removed the
% WORKSPACE.MARKING and STATE references
%
% 9/26/12 - updated STAGES initialization to call
% loadSTAGES(stages_filename,num_epochs)
% Edit the above text to modify the response to help sev

% Last Modified by GUIDE v2.5 21-Jan-2013 09:26:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @sev_OpeningFcn, ...
                   'gui_OutputFcn',  @sev_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before sev is made visible.
function sev_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sev (see VARARGIN)

%-power? - free memory function?  to clear up any used handles?)

 
% Choose default command line output for sev
clear global;
global DEFAULTS;
global MARKING;

import plist.*; %struct to xml plist format conversions and such
import detection.*; %detection algorithms and such
import filter.*;

sev_path = fileparts(mfilename('fullpath'));
addpath(fullfile(sev_path,'auxiliary'));
% filter_inf = fullfile(DEFAULTS.filter_path,'filter.inf');
% if(exist(filter_inf,'file'))
%     [mfile, evt_label, num_reqd_indices, unused_param_gui, unused_batch_mode_label] = textread(filter_inf,'%s%s%n%s%c','commentstyle','shell');
%     event_detector_uimenu = uimenu(uicontextmenu_handle,'Label','Apply Detector','separator','off','tag','event_detector');
% 
%     for k=1:numel(num_reqd_indices)
%         if(num_reqd_indices(k)==max_num_sources)
%             uimenu(event_detector_uimenu,'Label',evt_label{k},'separator','off','callback',{@contextmenu_filter_callback,mfile{k}});
%         end;
%     end
% end;


handles.output = hObject;


%did someone try to load a previous settings file at startup
if(numel(varargin)<1)
    DEFAULTS.parameters_filename = '_sev.parameters.txt';  
% including the working directory problems when it comes time to save the
% parameters to disk later on if the sev is copied to a new directory,
% since the old directory name is loaded as part of the _sevparameters
%     DEFAULTS.parameters_filename = fullfile(pwd,'_sev.parameters.txt');

else
    DEFAULTS.parameters_filename = varargin{1};
end;

DEFAULTS.rootpathname = fileparts(mfilename('fullpath'));

%initialize GLOBAL variables...
settingsStruct = initializeGLOBALs();

DEFAULTS.rootpathname = fileparts(mfilename('fullpath'));

initializeGUI(hObject);

%set default values

handles.user.annotationH = -1;


%to enable swapping and such...
handles.user.axes1_H = handles.axes1;
handles.user.axes2_H = handles.axes2;

guidata(hObject, handles);
try
    
    MARKING = CLASS_UI_marking(hObject,settingsStruct.SEV); %handles.sev_main_fig; these two are equivalent
    MARKING.initializeSEV();
catch me
    %     me.message
    %     me.stack(1)
    showME(me);
    fprintf(1,['The default settings file is corrupted.',...
        '  This can occur when installing the software on a new computer or from editing the settings file externally.',...
        '\nChoose OK in the popup dialog to correct the settings file.\n']);
    menu_help_defaults_Callback([],[],[]);   
end
    
    
if(numel(varargin)>1)
    [path, name, ext] = fileparts(varargin{2});
    cur_filename =  strcat(name,ext);
    cur_pathname = path;
    MARKING.loadEDFintoSEV(cur_filename,cur_pathname);
end

% Update handles structure
guidata(hObject, handles);


function initializeGUI(hObject,handles)

% set(hObject,'visible','on');
figColor = get(hObject,'color');

ch = findall(hObject,'type','uipanel');
set(ch,'backgroundcolor',figColor);

ch = findobj(hObject,'-regexp','tag','text.*');

set(ch,'backgroundcolor',figColor);

ch = findobj(hObject,'-regexp','tag','axes.*');
set(ch,'units','normalized');

% --- Outputs from this function are returned to the command line.
function varargout = sev_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


   
% --- Executes on key press with focus on sev_main_fig and no controls selected.
function sev_main_fig_KeyPressFcn(hObject, eventdata, handles)
% function figure1_KeyPressFcn(hObject, eventdata)
% hObject    handle to sev_main_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% key=double(get(hObject,'CurrentCharacter')); % compare the values to the list
global MARKING;
epoch = MARKING.current_epoch;
key=eventdata.Key;
handles = guidata(hObject);
if(epoch>0)
    epoch_in = epoch;
    if(strcmp(key,'add'))
        MARKING.increaseStartSample();        
    elseif(strcmp(key,'subtract'))
        MARKING.decreaseStartSample();
    else
        if(strcmp(key,'leftarrow')||strcmp(key,'pagedown'))
            
            if(epoch>1)
                epoch = epoch-1;
            end;
            
            %go forward 1 epoch
        elseif(strcmp(key,'rightarrow')||strcmp(key,'pageup'))
            if(epoch<MARKING.num_epochs)
                epoch = epoch+1;
            end
            
            %go forward 10 epochs
        elseif(strcmp(key,'uparrow'))
            
            if(epoch<=MARKING.num_epochs-10)
                epoch = epoch+10;
            end
            
            %go back 10 epochs
        elseif(strcmp(key,'downarrow'))
            if(epoch>10)
                epoch = epoch-10;
            end
        end
        if(epoch_in~=epoch)
            MARKING.setEpoch(epoch);
        end
    end
end
    
if(strcmp(eventdata.Key,'shift'))
    set(handles.sev_main_fig,'pointer','ibeam');
end
    %go back 1 epoch
%copy to clipboard
if(strcmp(eventdata.Modifier,'control'))
    if(strcmp(eventdata.Key,'x'))
        delete(hObject);
        %take screen capture of figure
    elseif(strcmp(eventdata.Key,'p'))
        screencap(hObject);
    %take screen capture of main axes
    elseif(strcmp(eventdata.Key,'a'))
        screencap(handles.axes1);        
    elseif(strcmp(eventdata.Key,'h'))
        screencap(handles.axes2);        
    elseif(strcmp(eventdata.Key,'u'))
        screencap(handles.axes3);        
    end
    
%         if(strcmp(eventdata.Key,'c'))
%         copy2clipboard();
% 
        %pop up to view more in a plot
%     elseif(strcmp(eventdata.Key,'p'))
%         plotSelection();


end;



%This is necessary header for backward compatibility
% function figure1_KeyReleaseFcn(hObject,eventdata)
% handles = guidata(hObject);

function sev_main_fig_KeyReleaseFcn(hObject, eventdata, handles)

key=eventdata.Key;
if(strcmp(key,'shift'))
    set(handles.sev_main_fig,'pointer','arrow');
end;



% --- Executes when user attempts to close sev_main_fig.
function sev_main_fig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to sev_main_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global DEFAULTS;
% global MARKING;
% global PSD;
% global CHANNELS_CONTAINER;
% global EVENT_CONTAINER;
% global MARKING;
try

saveParametersToFile(fullfile(DEFAULTS.rootpathname,DEFAULTS.parameters_filename));
% Hint: delete(hObject) closes the figure

%close other children too? - kill all?

% delete(MARKING);
% clear MARKING;
% clear ans;
% clear PSD;
% clear CHANNELS_CONTAINER;
% clear EVENT_CONTAINER;
% clear MARKING;
delete(hObject);


catch ME
    ME.stack(1).line
    ME.stack(1).file
    disp(ME.message);
    killall;
end


function recoverFromError(handles,cur_error)
%recovers from any errors that were encountered and removes any extra
%windows that were opened

disp(['an error was encountered at time: ', datestr(now)]);

warnmsg = cur_error.message;

for s = 1:numel(cur_error.stack)
    %                         disp(['<a href="matlab:opentoline(''',file,''',',linenum,')">Open Matlab to this Error</a>']);
    stack_error = cur_error.stack(s);
    warnmsg = sprintf('%s\r\n\tFILE: %s\f<a href="matlab:opentoline(''%s'',%s)">LINE: %s</a>\fFUNCTION: %s', warnmsg,stack_error.file,stack_error.file,num2str(stack_error.line),num2str(stack_error.line), stack_error.name);
    
end

disp(warnmsg)

resetSEV(handles);


% --- Executes on mouse motion over figure - except title and menu.
function sev_main_fig_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to sev_main_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)






% --------------------------------------------------------------------
function menu_help_defaults_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_defaults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Construct a questdlg with three options
global DEFAULTS;

choice = questdlg({'Click OK to reset setting parameters.';' ';
                   ' This may be necessary when copying ';
                   ' the SEV to a new computer or when  '
                   ' a parameter file becomes corrupted.'; ' '},...
               'Set Defaults', ...
	'OK','Cancel','Cancel');
% Handle response
if(strncmp(choice,'OK',2))    
    delete(DEFAULTS.parameters_filename);
%     helpdlg(sprintf('Parameter settings (%s) have been removed.\n\nThe SEV must now restart.',DEFAULTS.parameters_filename));
    sev_restart();
end

% --------------------------------------------------------------------
function marking_parameters = initializeGLOBALs()
%initialize global variables in SEV....

global DEFAULTS;
global BATCH_PROCESS;
global PSD;
global MUSIC;

full_paramsFile = fullfile(DEFAULTS.rootpathname,DEFAULTS.parameters_filename);

if(exist(full_paramsFile,'file'))
    marking_parameters = loadParametersFromFile(full_paramsFile);    
else
    DEFAULTS.src_edf_pathname = '.'; %initial directory to look in for EDF files to load
    DEFAULTS.src_edf_filename = ''; %initial filename to suggest when trying to load an .EDF
    DEFAULTS.src_event_pathname = '.'; %initial directory to look in for EDF files to load
    DEFAULTS.batch_folder = '.'; %'/Users/hyatt4/Documents/Sleep Project/EE Training Set/';
    DEFAULTS.yDir = 'normal';  %or can be 'reverse'
    DEFAULTS.standard_epoch_sec = 30; %perhaps want to base this off of the hpn file if it exists...
    DEFAULTS.samplerate = 100;
    DEFAULTS.screenshot_path = DEFAULTS.rootpathname; %initial directory to look in for EDF files to load
    
    DEFAULTS.channelsettings_file = 'channelsettings.mat'; %used to store the settings for the file
    DEFAULTS.output_pathname = 'output';
    DEFAULTS.detectionInf_file = 'detection.inf';
    DEFAULTS.detection_path = '+detection';
    DEFAULTS.filter_path = '+filter';
    DEFAULTS.filterInf_file = 'filter.inf';
    DEFAULTS.databaseInf_file = 'database.inf';
    DEFAULTS.parameters_filename = '_sev.parameters.txt';

    MUSIC.window_length_sec = 2;
    MUSIC.interval_sec = 2;
    MUSIC.num_sinusoids = 6;
    MUSIC.modified = false;
    MUSIC.freq_min = 0; %display min
    MUSIC.freq_max = 30; %display max
    
    PSD.wintype = 'hann';
    PSD.removemean = 'true';
    PSD.FFT_window_sec = 2; %length in second over which to calculate the PSD
    PSD.interval = 2; %how often to take the FFT's
    PSD.freq_min = 0; %display min
    PSD.freq_max = 30; %display max
    
    
    BATCH_PROCESS.output_path.parent = 'output';
    BATCH_PROCESS.output_path.roc = 'ROC';
    BATCH_PROCESS.output_path.power = 'PSD';
    BATCH_PROCESS.output_path.events = 'events';
    BATCH_PROCESS.output_path.artifacts = 'artifacts';
    BATCH_PROCESS.output_path.images = 'images';
    
    %power spectrum analysis
    BATCH_PROCESS.output_files.psd_filename = 'psd.txt';
    BATCH_PROCESS.output_files.music_filename = 'MUSIC';
    
    %artifacts and events
    BATCH_PROCESS.output_files.events_filename = 'evt.';
    BATCH_PROCESS.output_files.artifacts_filename = 'art.';
    BATCH_PROCESS.output_files.save2txt = 1;
    BATCH_PROCESS.output_files.save2mat = 0;
    
    %database supplement
    BATCH_PROCESS.database.save2DB = 0;
    BATCH_PROCESS.database.filename = 'database.inf';
    BATCH_PROCESS.database.choice = 1;
    BATCH_PROCESS.database.auto_config = 1;
    BATCH_PROCESS.database.config_start = 1;
    
    %summary information
    BATCH_PROCESS.output_files.cumulative_stats_flag = 0;
    BATCH_PROCESS.output_files.cumulative_stats_filename = 'SEV.cumulative_stats.txt';
    
    BATCH_PROCESS.output_files.individual_stats_flag = 0;
    BATCH_PROCESS.output_files.individual_stats_filename_suffix = '.stats.txt';
    
    
    BATCH_PROCESS.output_files.log_checkbox = 1;
    BATCH_PROCESS.output_files.log_filename = '_log.txt';
    
    %images
    BATCH_PROCESS.images.save2img = 1;
    BATCH_PROCESS.images.format = 'PNG';
    BATCH_PROCESS.images.limit_count = 100;
    BATCH_PROCESS.images.limit_flag = 1;
    BATCH_PROCESS.images.buffer_sec = 0.5;
    BATCH_PROCESS.images.buffer_flag = 1;
    
    marking_parameters.DEFAULTS = DEFAULTS;
    marking_parameters.PSD = PSD;
    marking_parameters.MUSIC = MUSIC;
    marking_parameters.SEV = DEFAULTS;
    
end;


% --------------------------------------------------------------------
function menu_help_restart_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_restart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sev_restart();
