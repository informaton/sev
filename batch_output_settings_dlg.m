function varargout = batch_output_settings_dlg(varargin)
% BATCH_OUTPUT_SETTINGS_DLG M-file for batch_output_settings_dlg.fig
%      BATCH_OUTPUT_SETTINGS_DLG, by itself, creates a new BATCH_OUTPUT_SETTINGS_DLG or raises the existing
%      singleton*.
%
%      H = BATCH_OUTPUT_SETTINGS_DLG returns the handle to a new BATCH_OUTPUT_SETTINGS_DLG or the handle to
%      the existing singleton*.
%
%      BATCH_OUTPUT_SETTINGS_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BATCH_OUTPUT_SETTINGS_DLG.M with the given input arguments.
%
%      BATCH_OUTPUT_SETTINGS_DLG('Property','Value',...) creates a new BATCH_OUTPUT_SETTINGS_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before batch_process_dlg_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to batch_output_settings_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% Autogenerated by GUIDE and
% created by Hyatt Moore, IV (< 09-Jul-2012)

% Edit the above text to modify the response to help batch_output_settings_dlg

% Last Modified by GUIDE v2.5 04-Nov-2013 12:21:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @batch_output_settings_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @batch_output_settings_dlg_OutputFcn, ...
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


% --- Executes just before batch_output_settings_dlg is made visible.
function batch_output_settings_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to batch_output_settings_dlg (see VARARGIN)

% Choose default command line output for batch_output_settings_dlg
handles.output = [];

set(handles.check_save2DB,'value',0,'enable','off');
set(handles.menu_database,'enable','off');


%data structure coming in should be
if(numel(varargin)>0)
    var = varargin{1};
    
    %I save the file here so that it can be put back in when the function
    %closes, since the filename is not stored anywhere on the gui yet.
    %A better option may be to put it into the global variable DEFAULTS
    handles.user.database.filename = var.database.filename;
    
    %load DB parameter file if it exists
    %database_struct contains fileds 'name','user','password' for interacting with a mysql database
    database_struct = CLASS_events_container.loadDatabaseStructFromInf(var.database.filename);
    if(~isempty(database_struct))
        set(handles.check_save2DB,'value',var.database.save2DB,'enable','on');
        if(var.database.save2DB)
            set(handles.menu_database,'enable','on');
            set(handles.radio_manual_count,'enable','on');
            set(handles.radio_auto_count,'enable','on');
            if(var.database.auto_config==0)                
                set(handles.edit_evt_config_index_start,'enable','on');
            end
        end
        set(handles.radio_manual_count,'value',~var.database.auto_config);
        set(handles.edit_evt_config_index_start,'string',num2str(var.database.config_start));
        set(handles.menu_database,'string',database_struct.name,'value',var.database.choice);
    end
    
    %power spectrum analysis
    set(handles.edit_psd_filename,'string',var.output_files.psd_filename);
    set(handles.edit_music_filename,'string',var.output_files.music_filename);
    
    %artifacts and events
    set(handles.events_filename_edit,'string',var.output_files.events_filename);
    set(handles.artifacts_filename_edit,'string',var.output_files.artifacts_filename);
    set(handles.check_save2mat,'value',var.output_files.save2mat);
    set(handles.check_save2txt,'value',var.output_files.save2txt);    
    
    %summary information
    set(handles.check_cumulative_stats,'value',var.output_files.cumulative_stats_flag);
    set(handles.edit_cumulative_stats_filename,'string',var.output_files.cumulative_stats_filename);
    set(handles.check_individual_stats,'value',var.output_files.individual_stats_flag);
    set(handles.edit_individual_stats_filename_suffix,'string',var.output_files.individual_stats_filename_suffix);

    set(handles.check_log,'Value',var.output_files.log_checkbox);
    set(handles.edit_log_filename,'string',var.output_files.log_filename);
    
    %images
    set(handles.check_save2img,'value',var.images.save2img);    
    image_formats = get(handles.menu_images_format,'string');
    set(handles.menu_images_format,'value',max(find(strcmp(image_formats,var.images.format),1),1));
    set(handles.check_images_limit_cap,'value',var.images.limit_flag);
    set(handles.edit_images_limit_cap,'string',num2str(var.images.limit_count));
    set(handles.check_img_buffer,'value',var.images.buffer_flag);
    set(handles.edit_img_buffer_sec,'string',num2str(var.images.buffer_sec));
    
    
    %directories
    set(handles.edit_path_parent,'string',var.output_path.parent);
    set(handles.edit_path_power,'string',var.output_path.power);
    set(handles.edit_path_events,'string',var.output_path.events);
    set(handles.edit_path_artifacts,'string',var.output_path.artifacts);
    set(handles.edit_path_images,'string',var.output_path.images);
    set(handles.edit_path_roc,'string',var.output_path.roc);

else
    handles.user.database.filename = [];
    
    %power spectrum analysis
    set(handles.edit_psd_filename,'string','psd.txt');
    set(handles.edit_music_filename,'string','MUSIC');
    
    %artifacts and events
    set(handles.events_filename_edit,'string','evt.');
    set(handles.artifacts_filename_edit,'string','art.');
    set(handles.check_save2mat,'value',0);
    set(handles.check_save2DB,'value',0);
    
    %summary information
    set(handles.check_cumulative_stats,'value',0);
    set(handles.edit_cumulative_stats_filename,'string','SEV.cumulative_stats.txt');
    set(handles.check_individual_stats,'value',0);
    set(handles.edit_individual_stats_filename_suffix,'string','.stats.txt');
    
    set(handles.check_log,'Value',1);
    set(handles.edit_log_filename,'string','_log.txt');
    
    %images
%     set(handles.edit_images_format,'string','PNG');
    set(handles.edit_images_limit_cap,'string','100');
    set(handles.check_images_limit_cap,'Value',1); %automatically cap it at 100 images per directory

    %directories
    set(handles.edit_path_parent,'string',fullfile(fileparts(mfilename('fullpath')),'output'));
    set(handles.edit_path_power,'string','PSD');
    set(handles.edit_path_events,'string','events');
    set(handles.edit_path_artifacts,'string','artifacts');
    set(handles.edit_path_images,'string','images');
    set(handles.edit_path_roc,'string','ROC');

end;

% set(handles.edit_psd_filename,'enable','on');
% set(handles.edit_music_filename,'enable','on');
% set(handles.edit_events_filename,'enable','on');
% set(handles.edit_artifacts_filename,'enable','on');
% set(handles.edit_images_save_directory,'enable','on');
% set(handles.edit_images_format,'enable','on');

if(get(handles.check_cumulative_stats,'Value'))
    set(handles.edit_cumulative_stats_filename,'enable','on');
else
    set(handles.edit_cumulative_stats_filename,'enable','off');
end;
if(get(handles.check_individual_stats,'Value'))
    set(handles.edit_individual_stats_filename_suffix,'enable','on');
else
    set(handles.edit_individual_stats_filename_suffix,'enable','off');
end;

check_save2img_Callback(handles.check_save2img,[],handles);


if(get(handles.check_log,'Value'))
    set(handles.edit_log_filename,'enable','on');
else
    set(handles.edit_log_filename,'enable','off');
end;


%%%%%%%%%%%%%%%%%%%%%%%%%
    
% uicontrol(handles.push_done);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes batch_output_settings_dlg wait for user response (see UIRESUME)
uiwait(handles.batch_process_output_file_settings_fig);


% --- Outputs from this function are returned to the command line.
function varargout = batch_output_settings_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.batch_process_output_file_settings_fig);



% --- Executes on button press in check_cumulative_stats.
function check_cumulative_stats_Callback(hObject, eventdata, handles)
% hObject    handle to check_cumulative_stats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_cumulative_stats
if(get(handles.check_cumulative_stats,'Value'))
    set(handles.edit_cumulative_stats_filename,'enable','on');
else
    set(handles.edit_cumulative_stats_filename,'enable','off');
end;


% --- Executes on button press in push_done.
function push_done_Callback(hObject, eventdata, handles)
% hObject    handle to push_done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%power spectrum analysis
handles.output.output_files.psd_filename = get(handles.edit_psd_filename,'string');
handles.output.output_files.music_filename = get(handles.edit_music_filename,'string');

%artifacts and events
handles.output.output_files.events_filename = get(handles.events_filename_edit,'string');
handles.output.output_files.artifacts_filename = get(handles.artifacts_filename_edit,'string');
handles.output.output_files.save2txt = get(handles.check_save2txt,'value');
handles.output.output_files.save2mat = get(handles.check_save2mat,'value');

%database
handles.output.database.save2DB = get(handles.check_save2DB,'value');
handles.output.database.choice = get(handles.menu_database,'value');
handles.output.database.filename = handles.user.database.filename;
handles.output.database.auto_config = get(handles.radio_auto_count,'value')==1;
handles.output.database.config_start = str2double(get(handles.edit_evt_config_index_start,'string'));

%summary information
handles.output.output_files.cumulative_stats_flag = get(handles.check_cumulative_stats,'value');
handles.output.output_files.cumulative_stats_filename = get(handles.edit_cumulative_stats_filename,'string');
handles.output.output_files.individual_stats_flag = get(handles.check_individual_stats,'value');
handles.output.output_files.individual_stats_filename_suffix = get(handles.edit_individual_stats_filename_suffix,'string');

handles.output.output_files.log_checkbox = get(handles.check_log,'Value');
handles.output.output_files.log_filename = get(handles.edit_log_filename,'string');


%images
handles.output.images.save2img = get(handles.check_save2img,'value');
handles.output.images.limit_count = str2double(get(handles.edit_images_limit_cap,'string'));
handles.output.images.limit_flag = get(handles.check_images_limit_cap,'value');
image_formats = get(handles.menu_images_format,'string');
handles.output.images.format = image_formats{get(handles.menu_images_format,'value')};
handles.output.images.buffer_sec = str2double(get(handles.edit_img_buffer_sec,'string'));
handles.output.images.buffer_flag = get(handles.check_img_buffer,'value');


%directories
handles.output.output_path.parent = get(handles.edit_path_parent,'string');
handles.output.output_path.power = get(handles.edit_path_power,'string');
handles.output.output_path.events = get(handles.edit_path_events,'string');
handles.output.output_path.artifacts = get(handles.edit_path_artifacts,'string');
handles.output.output_path.images = get(handles.edit_path_images,'string');
handles.output.output_path.roc = get(handles.edit_path_roc,'string');

guidata(hObject,handles);
uiresume(handles.batch_process_output_file_settings_fig);


% --- Executes on button press in cancel_pushbutton.
function cancel_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = [];
guidata(hObject,handles);
uiresume(handles.batch_process_output_file_settings_fig);

% --- Executes on button press in check_log.
function check_log_Callback(hObject, eventdata, handles)
% hObject    handle to check_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_log
if(get(handles.check_log,'Value'))
    set(handles.edit_log_filename,'enable','on');
else
    set(handles.edit_log_filename,'enable','off');
end;


function edit_log_filename_Callback(hObject, eventdata, handles)
% hObject    handle to edit_log_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_log_filename as text
%        str2double(get(hObject,'String')) returns contents of edit_log_filename as a double



% --- Executes when user attempts to close batch_process_output_file_settings_fig.
function batch_process_output_file_settings_fig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to batch_process_output_file_settings_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = [];
guidata(hObject,handles);
uiresume(handles.batch_process_output_file_settings_fig);




function edit_psd_filename_Callback(hObject, eventdata, handles)
% hObject    handle to edit_psd_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_psd_filename as text
%        str2double(get(hObject,'String')) returns contents of edit_psd_filename as a double



function edit_music_filename_Callback(hObject, eventdata, handles)
% hObject    handle to edit_music_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_music_filename as text
%        str2double(get(hObject,'String')) returns contents of edit_music_filename as a double



function edit_cumulative_stats_filename_Callback(hObject, eventdata, handles)
% hObject    handle to edit_cumulative_stats_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cumulative_stats_filename as text
%        str2double(get(hObject,'String')) returns contents of edit_cumulative_stats_filename as a double


% --- Executes on button press in check_save2DB.
function check_save2DB_Callback(hObject, eventdata, handles)
% hObject    handle to check_save2DB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_save2DB
if(get(hObject,'value'))
    set(handles.menu_database,'enable','on');
    set(handles.radio_manual_count,'enable','on');
    set(handles.radio_auto_count,'enable','on');
    if(get(handles.radio_manual_count,'value'))
        set(handles.edit_evt_config_index_start,'enable','on');
    end

else
    set(handles.menu_database,'enable','off');
    set(handles.radio_manual_count,'enable','off');
    set(handles.radio_auto_count,'enable','off');
    set(handles.edit_evt_config_index_start,'enable','off');    
end

guidata(hObject,handles);

% --- Executes on button press in check_save2mat.
function check_save2mat_Callback(hObject, eventdata, handles)
% hObject    handle to check_save2mat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_save2mat



function edit_images_save_directory_Callback(hObject, eventdata, handles)
% hObject    handle to edit_images_save_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_images_save_directory as text
%        str2double(get(hObject,'String')) returns contents of edit_images_save_directory as a double



function edit_path_parent_Callback(hObject, eventdata, handles)
% hObject    handle to edit_path_parent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_path_parent as text
%        str2double(get(hObject,'String')) returns contents of edit_path_parent as a double




function edit_path_power_Callback(hObject, eventdata, handles)
% hObject    handle to edit_path_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_path_power as text
%        str2double(get(hObject,'String')) returns contents of edit_path_power as a double



function edit_path_events_Callback(hObject, eventdata, handles)
% hObject    handle to edit_path_events (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_path_events as text
%        str2double(get(hObject,'String')) returns contents of edit_path_events as a double



function edit_path_artifacts_Callback(hObject, eventdata, handles)
% hObject    handle to edit_path_artifacts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_path_artifacts as text
%        str2double(get(hObject,'String')) returns contents of edit_path_artifacts as a double



function edit_path_images_Callback(hObject, eventdata, handles)
% hObject    handle to edit_path_images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_path_images as text
%        str2double(get(hObject,'String')) returns contents of edit_path_images as a double


function edit_path_roc_Callback(hObject, eventdata, handles)
% hObject    handle to edit_path_roc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_path_roc as text
%        str2double(get(hObject,'String')) returns contents of edit_path_roc as a double


% --- Executes on button press in check_individual_stats.
function check_individual_stats_Callback(hObject, eventdata, handles)
% hObject    handle to check_individual_stats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_individual_stats
if(get(handles.check_individual_stats,'Value'))
    set(handles.edit_individual_stats_filename_suffix,'enable','on');
else
    set(handles.edit_individual_stats_filename_suffix,'enable','off');
end;


function edit_individual_stats_filename_suffix_Callback(hObject, eventdata, handles)
% hObject    handle to edit_individual_stats_filename_suffix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_individual_stats_filename_suffix as text
%        str2double(get(hObject,'String')) returns contents of edit_individual_stats_filename_suffix as a double


% --- Executes during object creation, after setting all properties.
function edit_individual_stats_filename_suffix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_individual_stats_filename_suffix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_images_limit_cap.
function check_images_limit_cap_Callback(hObject, eventdata, handles)
% hObject    handle to check_images_limit_cap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_images_limit_cap
if(get(handles.check_images_limit_cap,'Value'))
    set(handles.edit_images_limit_cap,'enable','on');
else
    set(handles.edit_images_limit_cap,'enable','off');
end;

function edit_images_limit_cap_Callback(hObject, eventdata, handles)
% hObject    handle to edit_images_limit_cap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_images_limit_cap as text
%        str2double(get(hObject,'String')) returns contents of edit_images_limit_cap as a double
numericVal = str2double(get(hObject,'String'));

%must be a positive value; ensure this is so
if(isempty(numericVal)|| numericVal<=0 )
    set(hObject,'string','100');
end;


% --- Executes on button press in check_save2txt.
function check_save2txt_Callback(hObject, eventdata, handles)
% hObject    handle to check_save2txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_save2txt


% --- Executes on selection change in menu_database.
function menu_database_Callback(hObject, eventdata, handles)
% hObject    handle to menu_database (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_database contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_database


% --- Executes when selected object is changed in bgroup_database.
function bgroup_database_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in bgroup_database 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if(eventdata.NewValue==handles.radio_manual_count)
    set(handles.edit_evt_config_index_start,'enable','on');
else
    set(handles.edit_evt_config_index_start,'enable','off');
end

function edit_evt_config_index_start_Callback(hObject, eventdata, handles)
% hObject    handle to edit_evt_config_index_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_evt_config_index_start as text
%        str2double(get(hObject,'String')) returns contents of edit_evt_config_index_start as a double


% --- Executes during object creation, after setting all properties.
function edit_evt_config_index_start_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_evt_config_index_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_images.
function check_images_Callback(hObject, eventdata, handles)
% hObject    handle to check_images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_images



% --- Executes on selection change in menu_images_format.
function menu_images_format_Callback(hObject, eventdata, handles)
% hObject    handle to menu_images_format (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_images_format contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_images_format


% --- Executes during object creation, after setting all properties.
function menu_images_format_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menu_images_format (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit_images_limit_cap_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_images_limit_cap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_save2img.
function check_save2img_Callback(hObject, eventdata, handles)
% hObject    handle to check_save2img (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_save2img
% Hint: get(hObject,'Value') returns toggle state of check_save2DB
% if(get(handles.check_save2img,'value'))
%     set(handles.check_images_limit_cap,'enable','on');
%     set(handles.menu_images_format,'enable','on');
%     if(get(handles.check_images_limit_cap,'Value'))
%         set(handles.edit_images_limit_cap,'enable','on');
%     else
%         set(handles.edit_images_limit_cap,'enable','off');
%     end;
%     set(handles.check_img_buffer,'enable','on');    
%     if(get(handles.check_img_buffer,'Value'))
%         set(handles.edit_img_buffer_sec,'enable','on');
%     else
%         set(handles.edit_img_buffer_sec,'enable','off');
%     end;
% end

if(get(hObject,'value'))
    set(handles.menu_images_format,'enable','on');
    
    set(handles.check_images_limit_cap,'enable','on');
    if(get(handles.check_images_limit_cap,'value'))
        set(handles.edit_images_limit_cap,'enable','on');
    end
    
    set(handles.check_img_buffer,'enable','on');    
    if(get(handles.check_img_buffer,'Value'))
        set(handles.edit_img_buffer_sec,'enable','on');
    else
        set(handles.edit_img_buffer_sec,'enable','off');
    end;
else
    set(handles.menu_images_format,'enable','off');
    set(handles.check_images_limit_cap,'enable','off');
    set(handles.edit_images_limit_cap,'enable','off');
    set(handles.check_img_buffer,'enable','off');    
    set(handles.edit_img_buffer_sec,'enable','off');
end

guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function menu_database_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menu_database (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_img_buffer_sec_Callback(hObject, eventdata, handles)
% hObject    handle to edit_img_buffer_sec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_img_buffer_sec as text
%        str2double(get(hObject,'String')) returns contents of edit_img_buffer_sec as a double
numericVal = str2double(get(hObject,'String'));

%must be a positive value; ensure this is so
if(isempty(numericVal)|| numericVal<0 )
    set(hObject,'string','0.5');
end;

% --- Executes during object creation, after setting all properties.
function edit_img_buffer_sec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_img_buffer_sec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_img_buffer.
function check_img_buffer_Callback(hObject, eventdata, handles)
% hObject    handle to check_img_buffer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of check_img_buffer
if(get(handles.check_img_buffer,'Value'))
    set(handles.edit_img_buffer_sec,'enable','on');
else
    set(handles.edit_img_buffer_sec,'enable','off');
end;

% --- Executes on button press in push_root.
function push_root_Callback(hObject, eventdata, handles)
% hObject    handle to push_root (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
path = get(handles.edit_path_parent,'string');
pathname = uigetdir(path,'Select the directory you wish to output to');
if(isdir(char(pathname)))
    set(handles.edit_path_parent,'string',pathname);
end
