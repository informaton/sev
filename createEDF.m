function varargout = createEDF(varargin)
% CREATEEDF M-file for createEDF.fig
%      CREATEEDF, by itself, creates a new CREATEEDF or raises the existing
%      singleton*.
%
%      H = CREATEEDF returns the handle to a new CREATEEDF or the handle to
%      the existing singleton*.
%
%      CREATEEDF('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CREATEEDF.M with the given input arguments.
%
%      CREATEEDF('Property','Value',...) creates a new CREATEEDF or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before createEDF_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to createEDF_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% contracted to Adam Rhine by Hyatt Moore (not for commercial use)
% 31-May-2011

% Edit the above text to modify the response to help createEDF

% Last Modified by GUIDE v2.5 31-May-2011 13:00:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @createEDF_OpeningFcn, ...
                   'gui_OutputFcn',  @createEDF_OutputFcn, ...
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


% --- Executes just before createEDF is made visible.
function createEDF_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version1 of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to createEDF (see VARARGIN)

% Choose default command line output for createEDF
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if(isstruct(get(handles.figure1,'UserData'))==0)
    HDR.ver = 0;
    HDR.patient = 'Unknown';
    HDR.local = 'Unknown';
    
    now_0 = now;
    HDR.startdate = datestr(now_0,'mm.dd.yy');
    HDR.starttime = datestr(now_0,'HH.MM.SS');

%     HDR.startdate = 'mm.dd.yy';
%     HDR.starttime = 'hh.mm.ss';
    HDR.number_of_data_records = 1;
    HDR.duration_of_data_record_in_seconds = 1;
    HDR.HDR_size_in_bytes = 700;
    HDR.num_signals = 1;
    HDR.label = {'Blank1'};
    HDR.transducer = {'unknown'};
    HDR.physical_dimension = {''};
    HDR.physical_minimum = [-250];
    HDR.physical_maximum = [250];
    HDR.digital_minimum = [-2048];
    HDR.digital_maximum = [2047];
    HDR.prefiltering = {'BP: 0.1HZ -100HZ'};
    HDR.number_samples_in_each_data_record = [100];
else
    HDR = get(handles.figure1,'UserData');
end

set(handles.version1,'String',num2str(HDR.ver));
set(handles.patient_id,'String',HDR.patient);
set(handles.local_id,'String',HDR.local);
set(handles.start_date,'String',HDR.startdate);
set(handles.start_time,'String',HDR.starttime);
set(handles.num_data_records,'String',num2str(HDR.number_of_data_records));
set(handles.duration_data_record,'String',num2str(HDR.duration_of_data_record_in_seconds));
set(handles.num_sigs,'Value',HDR.num_signals);
set(handles.figure1,'UserData',HDR);
% UIWAIT makes createEDF wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = createEDF_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version1 of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function version1_Callback(hObject, eventdata, handles)
% hObject    handle to version1 (see GCBO)
% eventdata  reserved - to be defined in a future version1 of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of version1 as text
%        str2double(get(hObject,'String')) returns contents of version1 as a double


% --- Executes during object creation, after setting all properties.
function version1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to version1 (see GCBO)
% eventdata  reserved - to be defined in a future version1 of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function patient_id_Callback(hObject, eventdata, handles)
% hObject    handle to patient_id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of patient_id as text
%        str2double(get(hObject,'String')) returns contents of patient_id as a double


% --- Executes during object creation, after setting all properties.
function patient_id_CreateFcn(hObject, eventdata, handles)
% hObject    handle to patient_id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function local_id_Callback(hObject, eventdata, handles)
% hObject    handle to local_id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of local_id as text
%        str2double(get(hObject,'String')) returns contents of local_id as a double


% --- Executes during object creation, after setting all properties.
function local_id_CreateFcn(hObject, eventdata, handles)
% hObject    handle to local_id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function start_date_Callback(hObject, eventdata, handles)
% hObject    handle to start_date (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of start_date as text
%        str2double(get(hObject,'String')) returns contents of start_date as a double


% --- Executes during object creation, after setting all properties.
function start_date_CreateFcn(hObject, eventdata, handles)
% hObject    handle to start_date (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function start_time_Callback(hObject, eventdata, handles)
% hObject    handle to start_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of start_time as text
%        str2double(get(hObject,'String')) returns contents of start_time as a double


% --- Executes during object creation, after setting all properties.
function start_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to start_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in num_sigs.
function num_sigs_Callback(hObject, eventdata, handles)
% hObject    handle to num_sigs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns num_sigs contents as cell array
%        contents{get(hObject,'Value')} returns selected item from num_sigs


% --- Executes during object creation, after setting all properties.
function num_sigs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_sigs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_data_records_Callback(hObject, eventdata, handles)
% hObject    handle to num_data_records (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_data_records as text
%        str2double(get(hObject,'String')) returns contents of num_data_records as a double


% --- Executes during object creation, after setting all properties.
function num_data_records_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_data_records (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function duration_data_record_Callback(hObject, eventdata, handles)
% hObject    handle to duration_data_record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of duration_data_record as text
%        str2double(get(hObject,'String')) returns contents of duration_data_record as a double


% --- Executes during object creation, after setting all properties.
function duration_data_record_CreateFcn(hObject, eventdata, handles)
% hObject    handle to duration_data_record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in nextbutton.
function nextbutton_Callback(hObject, eventdata, handles)
HDR = get(handles.figure1,'UserData');
HDR.ver = str2double(get(handles.version1,'String'));
HDR.patient = get(handles.patient_id,'String');
HDR.local = get(handles.local_id,'String');
HDR.startdate = get(handles.start_date,'String');
now_0 = now;
if(strcmp(HDR.startdate,'mm.dd.yy'))
    HDR.startdate = datestr(now_0,'mm.dd.yy');
end
HDR.starttime = get(handles.start_time,'String');
if(strcmp(HDR.starttime,'hh.mm.ss'))
    HDR.starttime = datestr(now_0,'HH.MM.SS');
end

HDR.number_of_data_records = str2double(get(handles.num_data_records,'String'));
HDR.duration_of_data_record_in_seconds = str2double(get(handles.duration_data_record,'String'));
contents = get(handles.num_sigs,'String');
HDR.num_signals = str2double(contents{get(handles.num_sigs,'Value')});
HDR.HDR_size_in_bytes = 700;

posit = get(handles.figure1,'Position');
if (HDR.num_signals<4)
    posit(3) = 60;
else
    posit(3) = 120;
end
if (HDR.num_signals==1)
    posit(4) = 21;
elseif (HDR.num_signals==2)||(HDR.num_signals==4)
    posit(4) = 36;
else
    posit(4) = 51;
end
close();
createEDFSignal('Position',posit,'UserData',HDR);
% hObject    handle to nextbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


