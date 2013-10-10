function varargout = psd_dlg(varargin)
% PSD_DLG M-file for psd_dlg.fig
%      PSD_DLG, by itself, creates a new PSD_DLG or raises the existing
%      singleton*.
%
%      H = PSD_DLG returns the handle to a new PSD_DLG or the handle to
%      the existing singleton*.
%
%      PSD_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PSD_DLG.M with the given input arguments.
%
%      PSD_DLG('Property','Value',...) creates a new PSD_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before psd_dlg_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to psd_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% 
% out = psd_dlg(varargin)
% varargin can consist of a valid window type (e.g. 'Hann'), the window
% length in seconds, and the fft interval in seconds
%out is a cell with the following properties
%out.wintype - window type as a string (e.g. 'Hamming')
%out.winlen - window length in seconds
%out.fftint (FFT interval in seconds)
%out.modified (FALSE if no changes were made or if the user cancels or
%closes the dialog without pressing the 'OK' button

% windowlength_edit the above text to modify the response to help psd_dlg

%written by Hyatt Moore
%updated on 10.8.2012 - changed format of .modified field from 'true' and
%'false' to true and false
% Last Modified by GUIDE v2.5 29-Oct-2012 18:17:07

% Begin initialization code - DO NOT WINDOWLENGTH_EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @psd_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @psd_dlg_OutputFcn, ...
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
% End initialization code - DO NOT WINDOWLENGTH_EDIT

% --- Executes just before psd_dlg is made visible.
function psd_dlg_OpeningFcn(hObject, eventdata, handles, PSDstruct)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% PSDstruct - struct with the following fields
%    wintype: 'hann'
%     FFT_window_sec: 2
%           interval: 2
%        channel_ind: 4
%         removemean: 1
%           freq_min: 0
%           freq_max: 30
global CHANNELS_CONTAINER;

channel_list_value = 1;

if(isa(CHANNELS_CONTAINER,'CLASS_channels_container')&& CHANNELS_CONTAINER.num_channels>0)
    channel_labels = CHANNELS_CONTAINER.get_labels();
    if(~isempty(CHANNELS_CONTAINER.current_spectrum_channel_index) && CHANNELS_CONTAINER.current_spectrum_channel_index~=0)
        handles.user.channel_ind = CHANNELS_CONTAINER.current_spectrum_channel_index;
    end
else
    channel_labels = 'No Channels Loaded';
    set(handles.list_psg_channels,'enable','off');
    handles.user.channel_ind = 0;
end

set(handles.list_psg_channels,'string',channel_labels,'value',channel_list_value);

handles.user.wintype = 'hanning';
handles.user.winlen = 2.0;
handles.user.fftint = 2.0;
handles.user.freq_min = 0;
handles.user.sampling_rate = 100;
handles.user.freq_max = 50;

if(nargin>3 && ~isempty(PSDstruct))
    fnames = fieldnames(PSDstruct);
    for f=1:numel(fnames)
        handles.user.(fnames{f}) = PSDstruct.(fnames{f});
    end
end

handles.user.modified = false;

% Choose default command line output for psd_dlg
% handles.output = hObject;

% p_str = [num2str(epoch_scales(1)) ' s'];
p_str = 'hanning|hann|hamming|triang|rectwin|barthannwin|bartlett|blackman|blackmanharris|bohmanwin|chebwin|flattopwin|gausswin|kaiser|nuttallwin|parzenwin|taylorwin|tukeywin';

p_ind = strfind(p_str,handles.user.wintype);

%i.e. it wasn't there.
if(isempty(p_ind))
    p_str = [handles.user.wintype '|' p_str];
    p_ind = 1;
else
    p_ind = numel(regexp(p_str(1:p_ind(1)),'\|'))+1; %do all this to check if the person is passing in a different wintype that they want used
end;

set(handles.windowtype_popupmenu,'value',p_ind);

set(handles.windowtype_popupmenu,'string',p_str);

set(handles.windowlength_edit,'string',num2str(handles.user.winlen));
set(handles.fft_interval_edit,'string',num2str(handles.user.fftint));
set(handles.edit_min_hz,'string',num2str(handles.user.freq_min));
set(handles.edit_max_hz,'string',num2str(handles.user.freq_max));

set(handles.axes1,'Units','normalized',... %normalized allows it to resize automatically
    'xlim',[0.5 100.5],...
    'box','on',...
    'xgrid','off','ygrid','off',...
    'ylim',[0 1.1],...
    'xlimmode','manual',...
    'xtick',[],...
    'ytick',[],...
    'nextplot','replacechildren');

line('parent',handles.axes1,'xdata',(1:100),'ydata',window(eval(['@' handles.user.wintype]),100));
% Update handles structure
guidata(hObject, handles);

uiwait(handles.psd_figure);

% --- Outputs from this function are returned to the command line.
function varargout = psd_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;
handles.user.wintype = deblank(handles.user.wintype);
PSD.wintype = handles.user.wintype;
PSD.modified = handles.user.modified;
PSD.FFT_window_sec = handles.user.winlen;

PSD.interval = handles.user.fftint;

if(~isfield(handles.user,'channel_ind'))
    PSD.channel_ind = 0;
else    
    PSD.channel_ind = handles.user.channel_ind;
end
    
PSD.freq_min = handles.user.freq_min;
PSD.freq_max = handles.user.freq_max;

PSD.removemean = true;
varargout{1} = PSD;

delete(handles.psd_figure);

% --- Executes on selection change in windowtype_popupmenu.
function windowtype_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to windowtype_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns windowtype_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from windowtype_popupmenu
handles.user.modified = true;
contents = get(hObject,'string');
handles.user.wintype = deblank(contents(get(hObject,'value'),:));
cla(handles.axes1);
line('parent',handles.axes1,'xdata',1:100,'ydata',window(eval(['@' handles.user.wintype]),100));

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function windowtype_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to windowtype_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fft_interval_edit_Callback(hObject, eventdata, handles)
% hObject    handle to fft_interval_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fft_interval_edit as text
%        str2double(get(hObject,'String')) returns contents of fft_interval_edit as a double
fftint = str2double(get(hObject,'String'));
fftintmin = 0;
fftintmax = 30;

if(fftint<=fftintmin || fftint>fftintmax || isequal(fftint,handles.user.fftint))
    set(hObject,'string',num2str(handles.user.fftint));
else
    handles.user.fftint = fftint;
    handles.user.modified = true;
end;

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function fft_interval_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fft_interval_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: windowlength_edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function windowlength_edit_Callback(hObject, eventdata, handles)
% hObject    handle to windowlength_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of windowlength_edit as text
%        str2double(get(hObject,'String')) returns contents of windowlength_edit as a double
winlen = str2double(get(hObject,'String'));
winlenmin = 0;
winlenmax = 30;

if(winlen<=winlenmin || winlen>winlenmax || isequal(winlen,handles.user.winlen))
    set(hObject,'string',num2str(handles.user.winlen));
else
    handles.user.winlen = winlen;
    handles.user.modified = true;
%     updatePlot(hObject,handles);
end;

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function windowlength_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to windowlength_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: windowlength_edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ok_pushbutton.
function varargout = ok_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ok_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(handles.psd_figure);


% --- Executes on button press in cancel_pushbutton.
function cancel_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.user.modified = false;
guidata(hObject,handles);
uiresume(handles.psd_figure);
% delete(handles.psd_figure);
% delete(gcf);
% delete(get(hObject,'parent'));



% --- Executes when user attempts to close psd_figure.
function psd_figure_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to psd_figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if( isequal(get(handles.psd_figure,'waitstatus'),'waiting'))
    handles.user.modified  = false;
    guidata(hObject,handles);
    uiresume(handles.psd_figure);
else
    %the GUI isn't waiting for anything, just close it
    delete(handles.psd_figure);
end;
% uiresume(handles.psd_figure);
% delete(gcf);


% --- Executes on key press with focus on psd_figure and no controls selected.
function psd_figure_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to psd_figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%check for 'enter' or 'escape'
if isequal(get(hObject,'CurrentKey'),'escape')
    handles.user.modified = false;
    guidata(hObject,handles);
    uiresume(handles.psd_figure);
end;
if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.psd_figure);
end;


% --- Executes on selection change in list_psg_channels.
function list_psg_channels_Callback(hObject, eventdata, handles)
% hObject    handle to list_psg_channels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_psg_channels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_psg_channels
handles.user.modified = true;

handles.user.channel_ind = get(hObject,'value');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function list_psg_channels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_psg_channels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_max_hz_Callback(hObject, eventdata, handles)
% hObject    handle to edit_max_hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_max_hz as text
%        str2double(get(hObject,'String')) returns contents of edit_max_hz as a double
max_hz = round(str2double(get(hObject,'String')));
if(max_hz>handles.user.freq_min && max_hz<=handles.user.sampling_rate/2) %should be less than nyquist, but we are just setting the axes here...
    handles.user.freq_max = max_hz;
    handles.user.modified = true;
end
set(hObject,'string',num2str(handles.user.freq_max));
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_max_hz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_max_hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_min_hz_Callback(hObject, eventdata, handles)
% hObject    handle to edit_min_hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_min_hz as text
%        str2double(get(hObject,'String')) returns contents of edit_min_hz as a double
min_hz = round(str2double(get(hObject,'String')));
if(min_hz<handles.user.freq_max && min_hz>=0)
    handles.user.freq_min = min_hz;
    handles.user.modified = true;
end
set(hObject,'string',num2str(handles.user.freq_min));
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_min_hz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_min_hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
