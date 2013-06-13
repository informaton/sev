function varargout = plist_batch_editor_dlg(varargin)
% plist_batch_editor_DLG M-file for plist_batch_editor_dlg.fig
%      plist_batch_editor_DLG, by itself, creates a new plist_batch_editor_DLG or raises the existing
%      singleton*.
%
%      H = plist_batch_editor_DLG returns the handle to a new plist_batch_editor_DLG or the handle to
%      the existing singleton*.
%
%      plist_batch_editor_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in plist_batch_editor_DLG.M with the given input arguments.
%
%      plist_batch_editor_DLG('Property','Value',...) creates a new plist_batch_editor_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plist_batch_editor_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plist_batch_editor_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plist_batch_editor_dlg

% Hyatt Moore IV (Last Modified by GUIDE v2.5 21-Jul-2011 15:50:03)

% Last Modified by GUIDE v2.5 21-Jul-2011 15:50:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plist_batch_editor_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @plist_batch_editor_dlg_OutputFcn, ...
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


% --- Executes just before plist_batch_editor_dlg is made visible.
function plist_batch_editor_dlg_OpeningFcn(hObject, ~, handles, selected_method_label,varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plist_batch_editor_dlg (see VARARGIN)

% Choose default command line output for plist_batch_editor_dlg
global DEFAULTS;


handles.output = []; %default to null output, in which case the user cancels this decision..
if(~isfield(DEFAULTS,'roc_truth_directory'))
    DEFAULTS.roc_truth_directory = pwd;
end
% if(numel(varargin)>1 && ~isempty(varargin{2}))
%     handles.user.detection_path = varargin{2};
% 
% else
%     handles.user.detection_path = '+detection';
% end
handles.user.detection_path = '+detection';

methods = CLASS_events_container.loadDetectionMethodsInf(handles.user.detection_path);

%just use the ones that I have already
good_ind = strcmp('plist_editor_dlg',methods.param_gui);
f_names = fieldnames(methods);
for k=1:numel(f_names)
    handles.user.methods.(f_names{k}) = methods.(f_names{k})(good_ind);
end

%find the event that is being classified here...
selected_method_ind = find(strcmp(selected_method_label,handles.user.methods.evt_label));
if(isempty(selected_method_ind))
    selected_method_ind = 1;
else
    set(handles.menu_methods,'enable','inactive');
end;


set(handles.menu_methods,'string',handles.user.methods.evt_label,'value',selected_method_ind);
handles.user.selected_method_ind = selected_method_ind;
handles.user.MAX_NUM_PROPERTIES = 7;


handles.user.selected_method_ind = selected_method_ind;

if(numel(varargin)>0 && ~isempty(varargin{1}.pBatchStruct))
   settings = varargin{1}.pBatchStruct; 
else
    selected_plist_filename = fullfile(handles.user.detection_path,[handles.user.methods.mfile{selected_method_ind},'.plist']);
    plist_settings = plist.loadXMLPlist(selected_plist_filename);
    
    names = fieldnames(plist_settings);
    settings = cell(numel(names),1);
    for k=1:numel(names)
        settings{k}.key = names{k};
        settings{k}.start = plist_settings.(names{k});
        settings{k}.stop = plist_settings.(names{k});
        settings{k}.num_steps = 1;
    end
    
end

handles = menu_methods_Callback(handles.menu_methods,[],handles,settings);

if(numel(varargin)>0 && ~isempty(varargin{1}.rocStruct))
    check_roc_Callback(handles.check_roc, [], handles, varargin{1}.rocStruct);
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes plist_batch_editor_dlg wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = plist_batch_editor_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

if(isempty(handles))
    varargout{1} = [];
    varargout{2} = [];
else
    pStruct = cell(handles.user.cur_num_properties,1);
    for k=1:handles.user.cur_num_properties
        handles_key_name = ['handles.text_key',num2str(k)];
        key = get(eval(handles_key_name),'string');
        pStruct{k}.key = key;
        
        handles_start_value_name = ['handles.edit_start_value',num2str(k)];
        str_start_value = get(eval(handles_start_value_name),'string');
        num_start_value = str2num(str_start_value);
        if(isempty(num_start_value))
            pStruct{k}.start = str_start_value;
        else
            pStruct{k}.start = num_start_value;
        end
        
        handles_stop_value_name = ['handles.edit_stop_value',num2str(k)];
        str_stop_value = get(eval(handles_stop_value_name),'string');
        num_stop_value = str2num(str_stop_value);
        if(isempty(num_stop_value))
            pStruct{k}.stop = str_stop_value;
        else
            pStruct{k}.stop = num_stop_value;
        end
        
        handles_num_steps_name = ['handles.edit_num_steps',num2str(k)];
        num_steps = str2double(get(eval(handles_num_steps_name),'string'));
        pStruct{k}.num_steps = num_steps;
    end
    
    varargout{1} = pStruct;
    
    if(get(handles.check_roc,'value'))
        rocStruct.truth_pathname = get(handles.text_roc_true_pathname,'string');
        contents = cellstr(get(handles.pop_roc_truth,'String')); % returns pop_roc_truth contents as cell array
        rocStruct.truth_evt_suffix = contents{get(handles.pop_roc_truth,'value')};
        varargout{2} = rocStruct;
    else
        varargout{2} = [];
    end
end

delete(gcf);


% --- Executes on selection change in menu_methods.
function handles = menu_methods_Callback(hObject, eventdata, handles, settings)
% hObject    handle to menu_methods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_methods contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_methods

% selection_ind = get(hObject,'value');

%fill in the available properties
handles.user.cur_num_properties = numel(settings);
for k=1:handles.user.cur_num_properties
    set(eval(['handles.text_key',num2str(k)]),'string',settings{k}.key,'enable','on');
    set(eval(['handles.edit_start_value',num2str(k)]),'string',num2str(settings{k}.start),'enable','on');
    set(eval(['handles.edit_stop_value',num2str(k)]),'string',num2str(settings{k}.stop),'enable','on');
    set(eval(['handles.edit_num_steps',num2str(k)]),'string',num2str(settings{k}.num_steps),'enable','on');
end

%disable the remaining uicontrols
for k=handles.user.cur_num_properties+1:handles.user.MAX_NUM_PROPERTIES
    handles_key_name = ['handles.text_key',num2str(k)];
    handles_start_value_name = ['handles.edit_start_value',num2str(k)];
    handles_stop_value_name = ['handles.edit_stop_value',num2str(k)];
    handles_num_steps_name = ['handles.edit_num_steps',num2str(k)];
    
    set(eval(handles_key_name),'string',['key ',num2str(k)],'enable','off');
    set(eval(handles_start_value_name),'string',['value ',num2str(k)],'enable','off');
    set(eval(handles_stop_value_name),'string',['value ',num2str(k)],'enable','off');
    set(eval(handles_num_steps_name),'string',['value ',num2str(k)],'enable','off');
end
guidata(hObject,handles);

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
if(~get(handles.check_roc,'value')) %they did not check the roc box
    uiresume();
elseif(exist(get(handles.text_roc_true_pathname,'string'),'dir')) %the roc box is checked and the filename exists...
    uiresume();
else
    warndlg('ROC Directory does not exist!','Cannot continue');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
handles = [];
guidata(hObject,handles);
uiresume();

% --- Executes on button press in check_roc.
function check_roc_Callback(hObject, eventdata, handles,optional_rocStruct)
%if optional pathname is included then the hObject is initialized to be
%checked and the function will then try to continue using the
%optional_pathname, by passing the user selection for a pathname...
%optional_suffix is a unique suffix that should be found in the
%optional_pathname directory and will be used to search for the matching
%index if it is included
% hObject    handle to check_roc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_roc
global DEFAULTS;

if(nargin==4 && ~isempty(optional_rocStruct))
    set(hObject,'value',1);
    pathname = optional_rocStruct.truth_pathname;
    optional_suffix = optional_rocStruct.truth_evt_suffix;
else
    pathname = [];
    optional_suffix = '';
end

if(get(hObject,'value'))
    
    if(isempty(pathname))
        suggested_pathname = DEFAULTS.roc_truth_directory;
        if(isdir(fullfile(suggested_pathname,'output')))
            suggested_pathname = fullfile(suggested_pathname,'output');
        end
        if(isdir(fullfile(suggested_pathname,'events')))
            suggested_pathname = fullfile(suggested_pathname,'events');
        end
        
        pathname=uigetdir(suggested_pathname,'Pick Directory with Truth Events');
    end

    popup_true_items = [];

    if(pathname~=0)
        files = dir(pathname);
        DEFAULTS.roc_truth_directory = pathname;
        if(numel(files)>0)
            files_c = cell(numel(files),1);
            [files_c{:}] = files(:).name;
            %     evt=cell2mat(regexp(files_c,'evt\..+\.(?<channel>[^\.]+)\.(?<suffix>.+)','names'));
            evt=cell2mat(regexp(files_c,'evt\..+\.(?<suffix>([^\.]\.+)?.+)','names'));
            suffix_c = cell(numel(evt),1);
            [suffix_c{:}]=evt(:).suffix;
            popup_true_items = unique(suffix_c);
        end
    end
    
    if(~isempty(popup_true_items))        
        set(handles.text_roc_true_pathname,'enable','on','string',pathname);
        set(handles.pop_roc_truth,'string',popup_true_items,'visible','on');
        ind = find(strcmp(optional_suffix,popup_true_items)); %find the matching optional index
        if(~isempty(ind))
            set(handles.pop_roc_truth,'value',ind);
        end;
    else
        set(hObject,'value',0); %turn it off if there is no good filename
        set(handles.text_roc_true_pathname,'enable','inactive');
        set(handles.pop_roc_truth,'visible','off');
        set(handles.text_roc_true_pathname,'string','No events found');
    end
else
    set(handles.text_roc_true_pathname,'enable','inactive');
    set(handles.pop_roc_truth,'visible','off');
end;

guidata(hObject,handles);

% --- Executes on selection change in pop_roc_truth.
function pop_roc_truth_Callback(hObject, eventdata, handles)
% hObject    handle to pop_roc_truth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_roc_truth contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_roc_truth


% --- Executes during object creation, after setting all properties.
function pop_roc_truth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_roc_truth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_start_value6_Callback(hObject, eventdata, handles)
% hObject    handle to edit_start_value6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_start_value6 as text
%        str2double(get(hObject,'String')) returns contents of edit_start_value6 as a double


% --- Executes during object creation, after setting all properties.
function edit_start_value6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_start_value6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_stop_value6_Callback(hObject, eventdata, handles)
% hObject    handle to edit_stop_value6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_stop_value6 as text
%        str2double(get(hObject,'String')) returns contents of edit_stop_value6 as a double


% --- Executes during object creation, after setting all properties.
function edit_stop_value6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_stop_value6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_num_steps6_Callback(hObject, eventdata, handles)
% hObject    handle to edit_num_steps6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_num_steps6 as text
%        str2double(get(hObject,'String')) returns contents of edit_num_steps6 as a double


% --- Executes during object creation, after setting all properties.
function edit_num_steps6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_num_steps6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_start_value7_Callback(hObject, eventdata, handles)
% hObject    handle to edit_start_value7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_start_value7 as text
%        str2double(get(hObject,'String')) returns contents of edit_start_value7 as a double


% --- Executes during object creation, after setting all properties.
function edit_start_value7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_start_value7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_stop_value7_Callback(hObject, eventdata, handles)
% hObject    handle to edit_stop_value7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_stop_value7 as text
%        str2double(get(hObject,'String')) returns contents of edit_stop_value7 as a double


% --- Executes during object creation, after setting all properties.
function edit_stop_value7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_stop_value7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_num_steps7_Callback(hObject, eventdata, handles)
% hObject    handle to edit_num_steps7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_num_steps7 as text
%        str2double(get(hObject,'String')) returns contents of edit_num_steps7 as a double


% --- Executes during object creation, after setting all properties.
function edit_num_steps7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_num_steps7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
