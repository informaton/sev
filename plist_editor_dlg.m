function varargout = plist_editor_dlg(varargin)
% PLIST_EDITOR_DLG M-file for plist_editor_dlg.fig
%      PLIST_EDITOR_DLG, by itself, creates a new PLIST_EDITOR_DLG or raises the existing
%      singleton*.
%
%      H = PLIST_EDITOR_DLG returns the handle to a new PLIST_EDITOR_DLG or the handle to
%      the existing singleton*.
%
%      PLIST_EDITOR_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLIST_EDITOR_DLG.M with the given input arguments.
%
%      PLIST_EDITOR_DLG('Property','Value',...) creates a new PLIST_EDITOR_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plist_editor_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plist_editor_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Written by Hyatt Moore IV
% last modified: 10.9.12
% Edit the above text to modify the response to help plist_editor_dlg

% Last Modified by GUIDE v2.5 17-Sep-2012 08:38:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plist_editor_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @plist_editor_dlg_OutputFcn, ...
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


% --- Executes just before plist_editor_dlg is made visible.
function plist_editor_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plist_editor_dlg (see VARARGIN)
%
% varargin{1} = string label for specific settings that are being adjusted
% this is a filter, artifact, or event detector
% varargin{2} = this is the directory of the filter or detector path
% varargin{3} = parameters to be used instead of the ones loaded from the
% xml file, when included

% Choose default command line output for plist_editor_dlg

handles.output = [];
if(numel(varargin)>2)
    input_pStruct = varargin{3};
else
    input_pStruct = [];
end
if(numel(varargin)>1)
    handles.user.detection_path = varargin{2};
else
    handles.user.detection_path = '+detection';
end
methods = CLASS_events_container.loadDetectionMethodsInf(handles.user.detection_path);

%just use the ones that I have already
good_ind = strcmp('plist_editor_dlg',methods.param_gui);
f_names = fieldnames(methods);
for k=1:numel(f_names)
    handles.user.methods.(f_names{k}) = methods.(f_names{k})(good_ind);
end

%find the event that is being classified here...
if(numel(varargin)>0)
    selected_method_label = varargin{1};
    selected_method_ind = find(strcmp(selected_method_label,handles.user.methods.evt_label));
    
    if(isempty(selected_method_ind))
        %is the algorithm input instead of the label? - try again
        selected_method_label = strrep(selected_method_label,'detection.','');
        selected_method_ind = find(strcmp(selected_method_label,handles.user.methods.mfile));
    
        if(isempty(selected_method_ind))
            selected_method_ind = 1;
    
        else
%             selected_method_label = handles.user.methods.evt_label{selected_method_ind};
            set(handles.menu_methods,'enable','inactive');
        end
    else
        set(handles.menu_methods,'enable','inactive');
%         set(handles.menu_methods,'style','text','string',selected_method_label,'fontWeight','bold')
    end;
else
    selected_method_ind = 1;
end

set(handles.menu_methods,'string',handles.user.methods.evt_label,'value',selected_method_ind);
handles.user.selected_method_ind = selected_method_ind;
handles.user.MAX_NUM_PROPERTIES = 7; %used to be 7; still is 7
handles.user.modified = false;
if(~isempty(input_pStruct))
    %ensure that the input_pStruct has the same fields as the property I
    %want....
    handles.user.cur_num_properties = set_method_fields(handles,input_pStruct);
else
    handles = menu_methods_Callback(handles.menu_methods,[],handles);
end

handles.output = get_params(handles);
set(gcf,'visible','on');
% resizePanelForAddedControls(handles.pan_properties,2,20);
% resizePanelAndParentForAddedControls(handles.pan_properties,2);
% sizePanelAndParentForUIControls(handles.pan_properties,9,handles);
sizePanelAndParentForUIControls(handles.pan_properties,handles.user.cur_num_properties,handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes plist_editor_dlg wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = plist_editor_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

if(nargout>0)
    varargout{1} = handles.output;
end
delete(gcf);


function pStruct = save_plist(handles)
%saves the params and returns as output argument, pStruct
pfilename=fullfile(handles.user.detection_path,...
    [handles.user.methods.mfile{handles.user.selected_method_ind},'.plist']);
pStruct = get_params(handles);
plist.saveXMLPlist(pfilename,pStruct);

function pStruct = get_params(handles)
for k=1:handles.user.cur_num_properties
    handles_key_name = ['handles.text_key_',num2str(k)];
    handles_value_name = ['handles.edit_value_',num2str(k)];
    key = get(eval(handles_key_name),'string');
    str_value = get(eval(handles_value_name),'string');
    num_value = str2num(str_value);
    if(isempty(num_value))
        pStruct.(key) = str_value;
    else
        pStruct.(key) = num_value;
    end
    
end


% --- Executes on selection change in menu_methods.
function handles = menu_methods_Callback(hObject, eventdata, handles)
% hObject    handle to menu_methods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns menu_methods contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_methods

%change any values as necessary
if(handles.user.modified)
    save_plist(handles);
    handles.user.modified = false;
end

selection_ind = get(hObject,'value');
handles.user.selected_method_ind = selection_ind;

selected_plist_filename = fullfile(handles.user.detection_path,[handles.user.methods.mfile{selection_ind},'.plist']);
settings = plist.loadXMLPlist(selected_plist_filename);
handles.user.cur_num_properties = set_method_fields(handles,settings);
guidata(hObject,handles);


function num_properties = set_method_fields(handles,settings)
%fill in the available properties
names = fieldnames(settings);


num_properties = min(numel(names),handles.user.MAX_NUM_PROPERTIES);
for k=1:num_properties
    set(eval(['handles.text_key_',num2str(k)]),'string',names{k},'enable','on');
    set(eval(['handles.edit_value_',num2str(k)]),'string',settings.(names{k}),'enable','on');
end

% %disable the remaining uicontrols
% for k=num_properties+1:handles.user.MAX_NUM_PROPERTIES
%     handles_key_name = ['handles.text_key',num2str(k)];
%     handles_value_name = ['handles.edit_value',num2str(k)];
%     set(eval(handles_key_name),'string',['key ',num2str(k)],'enable','off');
%     set(eval(handles_value_name),'string',['value ',num2str(k)],'enable','off');
% end

% --- Executes during object creation, after setting all properties.
function menu_methods_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menu_methods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in push_close.
function push_close_Callback(hObject, eventdata, handles)
% hObject    handle to push_close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(handles.user.modified)
    try
        handles.output = save_plist(handles);
    catch me
        showME(me); 
        disp('You are most likely not in the sev directory.  Check that you are in directory containing sev.m and try again.');
    end
end
guidata(hObject,handles);
uiresume();


function edit_value_1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_value_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_value_1 as text
%        str2double(get(hObject,'String')) returns contents of edit_value_1 as a double
handles.user.modified = true;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_value_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_value_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_value_2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_value_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_value_2 as text
%        str2double(get(hObject,'String')) returns contents of edit_value_2 as a double
handles.user.modified = true;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_value_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_value_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_value_3_Callback(hObject, eventdata, handles)
% hObject    handle to edit_value_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_value_3 as text
%        str2double(get(hObject,'String')) returns contents of edit_value_3 as a double
handles.user.modified = true;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_value_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_value_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_value_4_Callback(hObject, eventdata, handles)
% hObject    handle to edit_value_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_value_4 as text
%        str2double(get(hObject,'String')) returns contents of edit_value_4 as a double
handles.user.modified = true;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_value_4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_value_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_value_5_Callback(hObject, eventdata, handles)
% hObject    handle to edit_value_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_value_5 as text
%        str2double(get(hObject,'String')) returns contents of edit_value_5 as a double
handles.user.modified = true;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_value_5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_value_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
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
% if(handles.user.modified)
%     save_plist(handles);
% end;
uiresume();



function edit_value_6_Callback(hObject, eventdata, handles)
% hObject    handle to edit_value_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_value_6 as text
%        str2double(get(hObject,'String')) returns contents of edit_value_6 as a double
handles.user.modified = true;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_value_6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_value_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_value_7_Callback(hObject, eventdata, handles)
% hObject    handle to edit_value_7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_value_7 as text
%        str2double(get(hObject,'String')) returns contents of edit_value_7 as a double
handles.user.modified = true;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_value_7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_value_7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
