function varargout = settings_roc_dlg(varargin)
% SETTINGS_ROC_DLG M-file for settings_roc_dlg.fig
%      SETTINGS_ROC_DLG, by itself, creates a new SETTINGS_ROC_DLG or raises the existing
%      singleton*.
%
%      H = SETTINGS_ROC_DLG returns the handle to a new SETTINGS_ROC_DLG or the handle to
%      the existing singleton*.
%
%      SETTINGS_ROC_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETTINGS_ROC_DLG.M with the given input arguments.
%
%      SETTINGS_ROC_DLG('Property','Value',...) creates a new SETTINGS_ROC_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before settings_roc_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to settings_roc_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% Written by Hyatt Moore IV
% modified: 10.16.2012 to account for MARKING global
% Edit the above text to modify the response to help settings_roc_dlg

% Last Modified by GUIDE v2.5 03-Aug-2012 15:11:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @settings_roc_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @settings_roc_dlg_OutputFcn, ...
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


% --- Executes just before settings_roc_dlg is made visible.
function settings_roc_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to settings_roc_dlg (see VARARGIN)
global EVENT_CONTAINER;
global MARKING;
% Choose default command line output for settings_roc_dlg
handles.output = [];

if(isa(EVENT_CONTAINER,'CLASS_events_container'))
    event_labels = EVENT_CONTAINER.get_event_labels();
    set([handles.list_truth,handles.list_estimate],'string',event_labels);
    set(handles.list_artifact,'string',[event_labels;{'NONE'}]);
    if(~isempty(EVENT_CONTAINER.roc_truth_ind))
        set(handles.list_truth,'value',EVENT_CONTAINER.roc_truth_ind);
        set(handles.list_estimate,'value',EVENT_CONTAINER.roc_estimate_ind);
    else
        set(handles.list_truth,'value',1);
        set(handles.list_estimate,'value',2);       
    end
    if(~isempty(EVENT_CONTAINER.roc_artifact_ind))
        set(handles.list_artifact,'value',EVENT_CONTAINER.roc_artifact_ind);
    else
        set(handles.list_artifact,'value',numel(event_labels)+1); %default to NONE
    end
else
    warndlg('Global variable EVENT_CONTAINER has not been instantiated yet.  Exiting.');
end;

if(~isempty(MARKING) && ~isempty(MARKING.sev_STAGES))
    set(handles.list_stage,'string',{'Stage 0','Stage 1','Stage 2','Stage 3','Stage 4','Stage 5'},'value',1:6);
    if(~isempty(EVENT_CONTAINER.roc_stage_selection))
        set(handles.list_stage,'value',EVENT_CONTAINER.roc_stage_selection)
    end
else
    set(handles.list_stage,'string','','enable','off');
end
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes settings_roc_dlg wait for user response (see UIRESUME)
uiwait(handles.roc_figure);


% --- Outputs from this function are returned to the command line.
function varargout = settings_roc_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(hObject);

% --- Executes on button press in push_cancel.
function push_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to push_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: delete(hObject) closes the figure
if( isequal(get(handles.roc_figure,'waitstatus'),'waiting'))
    handles.output = [];
    guidata(hObject,handles);
    uiresume(handles.roc_figure);
else
    %the GUI isn't waiting for anything, just close it
    delete(handles.roc_figure);
end;
% uiresume(handles.roc_figure);
% delete(gcf);


% --- Executes on selection change in list_truth.
function list_truth_Callback(hObject, eventdata, handles)
% hObject    handle to list_truth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_truth contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_truth


% --- Executes during object creation, after setting all properties.
function list_truth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_truth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in list_estimate.
function list_estimate_Callback(hObject, eventdata, handles)
% hObject    handle to list_estimate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_estimate contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_estimate


% --- Executes during object creation, after setting all properties.
function list_estimate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_estimate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in push_ok.
function push_ok_Callback(hObject, eventdata, handles)
% hObject    handle to push_ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% handles.output = cell2mat(get([handles.list_truth,handles.list_estimate,handles.list_artifact],'value'));
handles.output.truth = get(handles.list_truth,'value');
handles.output.estimate = get(handles.list_estimate,'value');
handles.output.artifact = get(handles.list_artifact,'value');

if(handles.output.artifact(end)==numel(get(handles.list_artifact,'string')))
    handles.output.artifact = [];
end

handles.output.stage = get(handles.list_stage,'value');
guidata(hObject,handles);
uiresume();


% --- Executes when user attempts to close roc_figure.
function roc_figure_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to roc_figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
% Hint: delete(hObject) closes the figure
if( isequal(get(handles.roc_figure,'waitstatus'),'waiting'))
    handles.output = [];
    guidata(hObject,handles);
    uiresume(handles.roc_figure);
else
    %the GUI isn't waiting for anything, just close it
    delete(handles.roc_figure);
end;


% --- Executes on selection change in list_artifact.
function list_artifact_Callback(hObject, eventdata, handles)
% hObject    handle to list_artifact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_artifact contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_artifact


% --- Executes during object creation, after setting all properties.
function list_artifact_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_artifact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in list_stage.
function list_stage_Callback(hObject, eventdata, handles)
% hObject    handle to list_stage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_stage contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_stage


% --- Executes during object creation, after setting all properties.
function list_stage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_stage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
