function varargout = importDBaseEvents_dlg(varargin)
% IMPORTDBASEEVENTS_DLG MATLAB code for importDBaseEvents_dlg.fig
%      IMPORTDBASEEVENTS_DLG, by itself, creates a new IMPORTDBASEEVENTS_DLG or raises the existing
%      singleton*.
%
%      H = IMPORTDBASEEVENTS_DLG returns the handle to a new IMPORTDBASEEVENTS_DLG or the handle to
%      the existing singleton*.
%
%      IMPORTDBASEEVENTS_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMPORTDBASEEVENTS_DLG.M with the given input arguments.
%
%      IMPORTDBASEEVENTS_DLG('Property','Value',...) creates a new IMPORTDBASEEVENTS_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before importDBaseEvents_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to importDBaseEvents_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Written by Hyatt Moore IV
% Stanford University, Stanford, CA
% Creation Date: August 17, 2012
% updated November 28, 2012 to change the detector channel config import
% label which used to be a string, and can now be a struct.
% modified - April 19, 2013 - saves settings to .mat file for easier,
% between-session use.
% Edit the above text to modify the response to help importDBaseEvents_dlg

% Last Modified by GUIDE v2.5 17-Aug-2012 12:42:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @importDBaseEvents_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @importDBaseEvents_dlg_OutputFcn, ...
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

% --- Executes just before importDBaseEvents_dlg is made visible.
function importDBaseEvents_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to importDBaseEvents_dlg (see VARARGIN)

handles.output = [];

if(numel(varargin)>0)
    channel_names = varargin{1};
else
    channel_names = 'No channels provided';
end
set(handles.menu_assign,'string',channel_names);

handles.save_settings_filename = 'DBase_dlg.mat';

DBfilename = 'database.inf';
handles.DBase = loadDatabaseStructFromInf(DBfilename);
handles.DB = [];

set(handles.table_detectconfig,'columnformat',{'char','char'},'units','normalized');
set(handles.figure1,'units','normalized');
set(handles.panel_dbase,'units','normalized');
fig_pos = get(handles.figure1,'position');
fig_width = fig_pos(3);

panel_pos = get(handles.panel_dbase,'position');
panel_width = panel_pos(3);
table_pos = get(handles.table_detectconfig,'position');
table_width = table_pos(3);
parent_width = fig_width* panel_width*table_width;

% columnwidth = {120,60};
columnwidth = {floor(normalized2pixel(0.7*parent_width)),floor(normalized2pixel(0.25*parent_width))};
set(handles.table_detectconfig,'columnwidth',columnwidth); %MATLAB still needs to get the table stuff figured out s the column is more accurate than row width as a freference
drawnow();

if(~isempty(handles.DBase))
    
    if(exist(handles.save_settings_filename,'file'))
        menu_selections = load(handles.save_settings_filename);
        preloaded = true;
        if(menu_selections.dbase<=numel(handles.DBase.name))
            handles.DBase.choice = menu_selections.dbase;
            set(handles.pmenu_db_select,'string',handles.DBase.name,'value',handles.DBase.choice);
            populateDBinfo(handles)
            if(menu_selections.classifier<=numel(get(handles.pmenu_classifier,'string')))
                set(handles.pmenu_classifier,'value',menu_selections.classifier);
                populateDetectorConfigMenu(handles);
                if(menu_selections.config<=numel(get(handles.pmenu_channel,'string')))
                    set(handles.pmenu_channel,'value',menu_selections.config)
                end
            end
        else
            preloaded = false;
        end
    else
        preloaded = false;
    end
    if(~preloaded)
        handles.DBase.choice = 1;
        set(handles.pmenu_db_select,'string',handles.DBase.name,'value',handles.DBase.choice);
        populateDBinfo(handles);
    end
    enableAll(handles);
else
    disableAll(handles);
    warndlg(sprintf('No database information found in the file %s\nCannot import database events.',DBfilename));
    guidata(hObject,handles);
    delete(hObject);
end

% drawnow()
% pos = get(handles.table_detectconfig,'position')
% extent = get(handles.table_detectconfig,'extent')
% 
% set(handles.table_detectconfig,'position',[pos(1:2), extent(3:4)]);
% set(handles.table_detectconfig,'position',[pos(1:2), extent(3), pos(4)]);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes importDBaseEvents_dlg wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = importDBaseEvents_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1);

%------------------------------------------------------------
% string = getMenuItem(hObject)
%
% returns the label of the current selected menu choice of
% hObject
%------------------------------------------------------------
function fieldName = getMenuItem(hObject)

menu_strings = get(hObject,'string');
if(iscell(menu_strings))
    fieldName = menu_strings{get(hObject,'value')};
else  %only one way to pull this off
    fieldName = menu_strings;
end
%------------------------------------------------------------
% Database specific loading/populate functions
%   populateDBinfo(handles)
%   populateDetectorMenu(handles)
%   populateDetectorConfigMenu(handles)
%   updateDetectorConfigTable(handles)
%   openDB(handles)
%------------------------------------------------------------

%------------------------------------------------------------
% populateDBinfo(handles)
%------------------------------------------------------------
function populateDBinfo(handles)

openDB(handles);
populateDetectorMenu(handles);

%------------------------------------------------------------
% populateDetectorMenu(handles)
%------------------------------------------------------------
function populateDetectorMenu(handles)

d_q = mym('select distinct DetectorLabel from detectorinfo_t'); %detector/database_query
set(handles.pmenu_classifier,'string',d_q.DetectorLabel,'value',1);
populateDetectorConfigMenu(handles);

%------------------------------------------------------------
% populateDetectorConfigMenu(handles)
%------------------------------------------------------------
function populateDetectorConfigMenu(handles)

detectorStr = getMenuItem(handles.pmenu_classifier);

dq = mym('select detectorid, configchannelLabels as channels from detectorinfo_t where detectorlabel="{S}"',detectorStr); %detector/database_query

channelCell = cell(numel(dq.detectorid),1);
for k = 1:numel(dq.detectorid)
    for j=1:numel(dq.channels{k})
        cur_channel = dq.channels{k}(j);
        if(~iscell(cur_channel))
            channelCell{k} = cur_channel;
        else
            channelconfig = cur_channel{1};
            if(iscell(channelconfig))
                channelconfig = channelconfig{1};
            end
            if(isstruct(channelconfig))
                if(isfield(channelconfig,'channel_label'))
                    channelconfig = channelconfig.channel_label;
                elseif(isfield(channelconfig,'src_channel_label'))
                    channelconfig = strcat('synthetic ',channelconfig.src_channel_label);
                else
                    channelconfig = 'unknown';
                end
            end
            if(j==1)
                channelCell{k} = sprintf('{%u} %s',dq.detectorid(k),channelconfig);
            else
                channelCell{k} =  sprintf('%s, %s',channelCell{k},channelconfig);
            end
        end
    end
end

set(handles.pmenu_channel,'string',channelCell,'value',1,'userdata',dq.detectorid);
updateDetectorConfigTable(handles);


%------------------------------------------------------------
% updateDetectorConfigTable(handles)
%------------------------------------------------------------
function updateDetectorConfigTable(handles)

detectorIDvec = get(handles.pmenu_channel,'userdata');
detectorID = detectorIDvec(get(handles.pmenu_channel,'value'));
dq = mym('select configparamstruct as config from detectorinfo_t where detectorid={Si}',detectorID);
if(isempty(dq.config{1}))
    table_data = [];
else
    fields = fieldnames(dq.config{1});
    values = struct2cell(dq.config{1});
    table_data = [fields,values];
    set(handles.table_detectconfig,'data',table_data);
end

set(handles.table_detectconfig,'data',table_data);

%------------------------------------------------------------
% openDB(handles)
%------------------------------------------------------------
function openDB(handles)
DB_choice = handles.DBase.choice;
mym('close');
DBname = handles.DBase.name{DB_choice};
DBuser = handles.DBase.user{DB_choice};
DBpassword = handles.DBase.password{DB_choice};
mym('open','localhost',DBuser,DBpassword);
mym(['USE ',DBname]);

%------------------------------------------------------------
% Display helper functions:
%   disableAll(handles)
%   enableAll(handles)
%   showBusy()
%   showReady()
%------------------------------------------------------------
function disableAll(handles)
names = fieldnames(handles);
for k = 1:length(names)
    if(isprop(handles.(names{k}),'enable'))
        set(handles.(names{k}),'enable','off');
    end;
end;
drawnow();

function enableAll(handles)
%this enables all GUI components, and should be called once a legitimate
%file has been loaded.

names = fieldnames(handles);
for k = 1:length(names)
    if(isprop(handles.(names{k}),'enable'))
        set(handles.(names{k}),'enable','on');
    end;
end;
drawnow();



% --- Executes on selection change in menu_dbase.
function menu_dbase_Callback(hObject, eventdata, handles)
% hObject    handle to menu_dbase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_dbase contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_dbase


% --- Executes during object creation, after setting all properties.
function menu_dbase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menu_dbase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in menu_detector.
function menu_detector_Callback(hObject, eventdata, handles)
% hObject    handle to menu_detector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_detector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_detector


% --- Executes during object creation, after setting all properties.
function menu_detector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menu_detector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in push_import.
function push_import_Callback(hObject, eventdata, handles)
% hObject    handle to push_import (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
detectorIDvec = get(handles.pmenu_channel,'userdata');
detectorID = detectorIDvec(get(handles.pmenu_channel,'value'));
handles.output.detectorID = detectorID;
handles.output.database_choice = handles.DBase.choice;
handles.output.channel_index = get(handles.menu_assign,'value');

selection.dbase = get(handles.pmenu_db_select,'value');
selection.config = get(handles.pmenu_channel,'value');
selection.classifier = get(handles.pmenu_classifier,'value');
save(handles.save_settings_filename,'-struct','selection','dbase','config','classifier');
guidata(hObject,handles);
uiresume(handles.figure1);

% --- Executes on button press in push_cancel.
function push_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to push_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);


% --- Executes on selection change in menu_assign.
function menu_assign_Callback(hObject, eventdata, handles)
% hObject    handle to menu_assign (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_assign contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_assign


% --- Executes during object creation, after setting all properties.
function menu_assign_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menu_assign (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pmenu_channel.
function pmenu_channel_Callback(hObject, eventdata, handles)
% hObject    handle to pmenu_channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pmenu_channel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pmenu_channel
updateDetectorConfigTable(handles);

% --- Executes during object creation, after setting all properties.
function pmenu_channel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pmenu_channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pmenu_classifier.
function pmenu_classifier_Callback(hObject, eventdata, handles)
% hObject    handle to pmenu_classifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pmenu_classifier contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pmenu_classifier
populateDetectorConfigMenu(handles);


% --- Executes during object creation, after setting all properties.
function pmenu_classifier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pmenu_classifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pmenu_db_select.
function pmenu_db_select_Callback(hObject, eventdata, handles)
% hObject    handle to pmenu_db_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pmenu_db_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pmenu_db_select
handles.DBase.choice = get(hObject,'value');
populateDBinfo(handles); %handles, DB_choice;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function pmenu_db_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pmenu_db_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(handles.figure1);
