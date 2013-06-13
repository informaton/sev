function varargout = wavelet_dlg(varargin)
% WAVELET_DLG MATLAB code for wavelet_dlg.fig
%      WAVELET_DLG, by itself, creates a new WAVELET_DLG or raises the existing
%      singleton*.
%
%      H = WAVELET_DLG returns the handle to a new WAVELET_DLG or the handle to
%      the existing singleton*.
%
%      WAVELET_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WAVELET_DLG.M with the given input arguments.
%
%      WAVELET_DLG('Property','Value',...) creates a new WAVELET_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before wavelet_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to wavelet_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% written by Hyatt Moore IV (<= 27-Nov-2012 15:59:01)

% Edit the above text to modify the response to help wavelet_dlg

% Last Modified by GUIDE v2.5 27-Nov-2012 15:59:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @wavelet_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @wavelet_dlg_OutputFcn, ...
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


% --- Executes just before wavelet_dlg is made visible.
function wavelet_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to wavelet_dlg (see VARARGIN)

% Choose default command line output for wavelet_dlg
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
handles.user.max_decompositions = 10;

handles.user.wavelet_names = get_wavelet_names();
handles.user.samplerate = 100;

if(numel(varargin)>=1 && ~isempty(varargin{1}))
    handles.output = varargin{1};
else
    matfile = fullfile(fileparts(mfilename('fullpath')),'+filter','decompose_wavelet.mat');
    
    if(exist(matfile,'file'))
        %load it
        mStruct= load(matfile);
        handles.output = mStruct.params;
    else
        handles.output.wname = 'db1';
        handles.output.threshhold = 50;
        handles.output.num_levels = 5;
        handles.output.soft_threshhold = 1;        
        handles.output.decomposition_levels = true(handles.user.max_decompositions); 
        handles.output.approximation_level = true;
        params = handles.output;
        save(matfile,'params');
    end
end

if(numel(varargin)>=2 && ~isempty(varargin{2}))
    handles.user.data = varargin{2};
else
    handles.user.data = rand(1,1024)*100;
end

if(handles.output.num_levels>handles.user.max_decompositions || handles.output.num_levels<1)
    handles.output.num_levels =1;
    handles.output.decomposition_levels = false(handles.user.max_decompositions,1);    
end

set(handles.menu_decomposition_levels,'string',num2str(transpose(1:handles.user.max_decompositions),'%u'),'value',handles.output.num_levels);

value = find(strcmp(handles.output.wname,handles.user.wavelet_names));
if(isempty(value))
    value = 1;
end
set(handles.menu_wavelet,'string',handles.user.wavelet_names,'value',value);
set(handles.edit_threshhold,'string',num2str(handles.output.threshhold));
set(handles.check_softthreshhold,'value',handles.output.soft_threshhold);
handles.user.data = handles.user.data-mean(handles.user.data);
y=handles.user.data;
x=1:numel(handles.user.data);
y_max = max(y);
y_min = min(y);
delta_y = y_max - y_min;
handles.user.signal.offset = -y_min;
handles.user.wavelet.offset = -delta_y/2;
handles.user.signal.line_h = line('xdata',x,'ydata',y+handles.user.signal.offset,'color','k','parent',handles.axes_main);
handles.user.wavelet.line_h = line('xdata',x,'ydata',y+handles.user.wavelet.offset,'color','b','parent',handles.axes_main);

set(handles.axes_main,'box','on','xtick',[],'ytick',[],'xlim',[1,x(end)],'ylim',[-delta_y,delta_y]);

handles.user.decomposition.line_h = zeros(handles.user.max_decompositions,1);

for d=1:handles.user.max_decompositions
    handles.user.decomposition.line_h(d) = line('xdata',x,'ydata',zeros(size(x)),'color',[0.25 0.25 1],'parent',handles.(sprintf('axes_%u',d)));
    set(handles.(sprintf('checkbox_decomp_%u',d)),'value',handles.output.decomposition_levels(d),'userdata',d,'callback',{@decomposition_checkbox_Callback,d});
    set(handles.(sprintf('axes_%u',d)),'box','on','xtick',[],'ytick',[],'xlim',[1,x(end)],'ylim',[-delta_y/2,delta_y/2]);
end

handles.user.approximation.line_h = line('xdata',x,'ydata',zeros(size(x)),'color',[0.25 0.25 1],'parent',handles.axes_approximation);
set(handles.checkbox_approximation,'value',handles.output.approximation_level,'userdata',1,'callback',@approximation_checkbox_Callback);
set(handles.axes_approximation,'box','on','xtick',[],'ytick',[],'xlim',[1,x(end)],'ylim',[-delta_y/2,delta_y/2]);

update_num_levels(handles);

guidata(hObject,handles);

uiwait(hObject);

function update_num_levels(handles)
%update the number of levels based on the configuration choice given
top_freq = handles.user.samplerate/2;
for d=1:handles.user.max_decompositions
    if(d==handles.output.num_levels)
        bottom_freq = 0;
    else
        bottom_freq = top_freq/2;
    end
    if(d<=handles.output.num_levels)
        set(handles.(sprintf('checkbox_decomp_%u',d)),'enable','on','string',sprintf('%u.  Decomposition (%0.4g - %0.4g Hz)',d,bottom_freq,top_freq));
        set(handles.(sprintf('axes_%u',d)),'color',[1 1 1]);
        set(handles.user.decomposition.line_h(d),'visible','on');
    else
        set(handles.(sprintf('checkbox_decomp_%u',d)),'enable','off','string',sprintf('%u.  Decomposition',d));
        set(handles.(sprintf('axes_%u',d)),'color',[1 1 1]*0.85);
        set(handles.user.decomposition.line_h(d),'visible','off');
    end
    top_freq = bottom_freq;
end
try_wavelet(handles);

function decomposition_checkbox_Callback(hObject,eventdata,decomp_level)

handles = guidata(hObject);
handles.output.decomposition_levels(decomp_level) = get(hObject,'value');
try_wavelet(handles);
guidata(hObject,handles);

function approximation_checkbox_Callback(hObject,eventdata)

handles = guidata(hObject);
handles.output.approximation_level = get(hObject,'value');
try_wavelet(handles);
guidata(hObject,handles);


function output = getOutput(handles)
output.wavelet_names = get_wavelet_names();
output.wname = handles.user.wavelet_names{get(handles.menu_wavelet,'value')};
output.threshhold = str2double(get(handles.edit_threshhold,'string'));
output.num_levels = get(handles.menu_decomposition_levels,'value');
output.soft_threshhold = get(handles.check_softthreshhold,'value');
output.samplerate = 100;

for d=1:handles.user.max_decompositions
    output.decomposition_levels(d) = get(handles.(sprintf('checkbox_decomp_%u',d)),'value');    
end

output.approximation_level = get(handles.checkbox_approximation,'value');


function wnames =  get_wavelet_names()
wnames = {'db1','haar','db2','db45',...
    'coif1','coif2','coif3','coif4','coif5',...
    'sym2','sym8','sym45',...
    'dmey',...
    'bior1.1', 'bior1.3' , 'bior1.5',...
        'bior2.2', 'bior2.4' , 'bior2.6', 'bior2.8',...
        'bior3.1', 'bior3.3' , 'bior3.5', 'bior3.7',...
        'bior3.9', 'bior4.4' , 'bior5.5', 'bior6.8',...
        'rbio1.1', 'rbio1.3' , 'rbio1.5',...
        'rbio2.2', 'rbio2.4' , 'rbio2.6', 'rbio2.8',...
        'rbio3.1', 'rbio3.3' , 'rbio3.5', 'rbio3.7',...
        'rbio3.9', 'rbio4.4' , 'rbio5.5', 'rbio6.8'};

% --- Outputs from this function are returned to the command line.
function varargout = wavelet_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(hObject);

% --- Executes on button press in push_accept.
function push_accept_Callback(hObject, eventdata, handles)
% hObject    handle to push_accept (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = getOutput(handles);

matfile = fullfile(fileparts(mfilename('fullpath')),'+filter','decompose_wavelet.mat');
params = handles.output;
save(matfile,'params');


guidata(hObject,handles);
uiresume;


% --- Executes on button press in push_cancel.
function push_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to push_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = [];
guidata(hObject,handles)
uiresume(gcf);

% --- Executes on selection change in menu_wavelet.
function menu_wavelet_Callback(hObject, eventdata, handles)
% hObject    handle to menu_wavelet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_wavelet contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_wavelet
try_wavelet(handles);

% --- Executes during object creation, after setting all properties.
function menu_wavelet_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menu_wavelet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in menu_decomposition_levels.
function menu_decomposition_levels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_decomposition_levels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_decomposition_levels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_decomposition_levels
handles.output.num_levels =get(hObject,'value');
guidata(hObject,handles);
update_num_levels(handles)


% --- Executes on button press in check_softthreshhold.
function check_softthreshhold_Callback(hObject, eventdata, handles)
% hObject    handle to check_softthreshhold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_softthreshhold
try_wavelet(handles);


function edit_threshhold_Callback(hObject, eventdata, handles)
% hObject    handle to edit_threshhold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_threshhold as text
%        str2double(get(hObject,'String')) returns contents of edit_threshhold as a double
tmp_value = str2double(get(hObject,'string'));
if(tmp_value>=0)
    try_wavelet(handles);
else
    set(hObject,'string',num2str(handles.output.threshhold));
end


% --- Executes on button press in push_try.
function push_try_Callback(hObject, eventdata, handles)
% hObject    handle to push_try (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try_wavelet(handles);
    
function try_wavelet(handles)
set(gcf,'pointer','watch');
drawnow;
params = getOutput(handles);
data = handles.user.data;
len = numel(data);
pow = 2^params.num_levels;

%zeropad if necessary
if rem(len,pow)>0
    sOK = ceil(len/pow)*pow;
    data = [data(:);zeros(sOK-len,1)];
end
x = 1:numel(data);

wav_sig = swt(data,params.num_levels,params.wname);
%go through the detail coefficients %1 = details, 5 = details 5, 6 = approx
%5?
for d=1:size(wav_sig,1)-1
    if(params.decomposition_levels(d))
        rejects = abs(wav_sig(d,:))<params.threshhold;
        
        wav_sig(d,rejects) = 0;
        
        if(params.soft_threshhold)
            wav_sig(d,~rejects) = sign(wav_sig(d,~rejects)).*(abs(wav_sig(d,~rejects))-params.threshhold);
        end
    else
        wav_sig(d,:) = 0;
    end
    set(handles.user.decomposition.line_h(d),'ydata',wav_sig(d,:),'xdata',x);
end
if(~params.approximation_level)
    wav_sig(end,:) = 0;
end

set(handles.user.approximation.line_h,'ydata',wav_sig(end,:),'xdata',x);


filtsig = iswt(wav_sig,params.wname);

%adjust zero-padding as necessary
if rem(len,pow)>0
    filtsig  = filtsig(1:len);
    x=1:numel(filtsig);
end
set(handles.user.wavelet.line_h,'ydata',filtsig+handles.user.wavelet.offset,'xdata',x);
set(gcf,'pointer','arrow');

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
handles.output = [];
guidata(hObject,handles);
uiresume(gcf);


% --- Executes on button press in checkbox_approximation.
function checkbox_approximation_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_approximation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_approximation
