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

% Last Modified by GUIDE v2.5 26-Aug-2013 00:34:05

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
global MARKING;

import plist.*; %struct to xml plist format conversions and such
import detection.*; %detection algorithms and such
import filter.*;

sev_pathname = fileparts(mfilename('fullpath'));
addpath(fullfile(sev_pathname,'auxiliary'));
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

%set some basic gui figure properties
initializeGUI(hObject);

%set default values
handles.user.annotationH = -1;

%to enable swapping and such...
handles.user.axes1_H = handles.axes1;
handles.user.axes2_H = handles.axes2;

sev_pathname = fileparts(mfilename('fullpath'));

guidata(hObject, handles);
try
    
    MARKING = CLASS_UI_marking(hObject,sev_pathname); 
    
catch me
    %     me.message
    %     me.stack(1)
    showME(me);
    fprintf(1,['The default settings file is corrupted.',...
        '  This can occur when installing the software on a new computer or from editing the settings file externally.',...
        '\nChoose OK in the popup dialog to correct the settings file.\n']);
    menu_help_defaults_Callback([],[],[]);   
end
    
if(numel(varargin)==1 &&  strcmpi(varargin{1},'batch'))
    MARKING.menu_batch_run_callback();
elseif(numel(varargin)>1)
        
    [path, name, ext] = fileparts(varargin{2});
    cur_filename =  strcat(name,ext);
    cur_pathname = path;
    MARKING.initializeView(); %don't want to do this if running through batch mode?
    
    MARKING.loadEDFintoSEV(cur_filename,cur_pathname);
else
    MARKING.initializeView(); %don't want to do this if running through batch mode?

end

% Update handles structure
guidata(hObject, handles);

function initializeGUI(hObject)

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
global MARKING;
 
try

    MARKING.close();
    MARKING = []; %remove the global reference count...
    delete(hObject);
catch ME
    showME(ME);
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
function menu_help_restart_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_restart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sev_restart();
