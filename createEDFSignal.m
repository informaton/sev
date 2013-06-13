function varargout = createEDFSignal(varargin)
% CREATEEDFSIGNAL M-file for createEDFSignal.fig
%      CREATEEDFSIGNAL, by itself, creates a new CREATEEDFSIGNAL or raises the existing
%      singleton*.
%
%      H = CREATEEDFSIGNAL returns the handle to a new CREATEEDFSIGNAL or the handle to
%      the existing singleton*.
%
%      CREATEEDFSIGNAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CREATEEDFSIGNAL.M with the given input arguments.
%
%      CREATEEDFSIGNAL('Property','Value',...) creates a new CREATEEDFSIGNAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before createEDFSignal_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to createEDFSignal_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% contracted to Adam Rhine by Hyatt Moore (not for commercial use),
% 09-Jun-2011
%
% Edit the above text to modify the response to help createEDFSignal

% Last Modified by GUIDE v2.5 09-Jun-2011 11:19:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @createEDFSignal_OpeningFcn, ...
                   'gui_OutputFcn',  @createEDFSignal_OutputFcn, ...
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


% --- Executes just before createEDFSignal is made visible.
function createEDFSignal_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to createEDFSignal (see VARARGIN)

% Choose default command line output for createEDFSignal
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if(isstruct(get(handles.figure1,'UserData'))==0)
    HDR.ver = 0;
    HDR.patient = 'Unknown';
    HDR.local = 'Unknown';
    HDR.startdate = 'mm.dd.yy';
    HDR.starttime = 'hh.mm.ss';
    HDR.number_of_data_records = 1;
    HDR.duration_of_data_record_in_seconds = 1;
    HDR.num_signals = 1;
    HDR.HDR_size_in_bytes = 700;
    HDR.label = {'Blank1'};
    HDR.transducer = {'unknown'};
    HDR.physical_dimension = {''};
    HDR.physical_minimum = [-250];
    HDR.physical_maximum = [250];
    HDR.digital_minimum = [-2048];
    HDR.digital_maximum = [2047];
    HDR.prefiltering = {'BP: 0.1HZ -100HZ'};
    HDR.number_samples_in_each_data_record = [100];
    set(handles.figure1,'UserData',HDR);
else
    HDR = get(handles.figure1,'UserData');
end

if (numel(HDR.label)~=HDR.num_signals)
    HDR.label = cell(HDR.num_signals,1);
    HDR.transducer = cell(HDR.num_signals,1);
    HDR.physical_dimension = cell(HDR.num_signals,1);
    HDR.physical_minimum = zeros(HDR.num_signals,1);
    HDR.physical_maximum = zeros(HDR.num_signals,1);
    HDR.digital_minimum = zeros(HDR.num_signals,1);
    HDR.digital_maximum = zeros(HDR.num_signals,1);
    HDR.prefiltering = cell(HDR.num_signals,1);
    HDR.number_samples_in_each_data_record = zeros(HDR.num_signals,1);

    for k=1:HDR.num_signals
        HDR.label{k} = strcat('Label',num2str(k));
        HDR.transducer{k} = 'unknown';
        HDR.physical_dimension{k} = '';
        HDR.physical_minimum(k) = -250;
        HDR.physical_maximum(k) = 250;
        HDR.digital_minimum(k) = -2048;
        HDR.digital_maximum(k) = 2047;
        HDR.prefiltering{k} = 'BP: 0.1HZ -100HZ';
        HDR.number_samples_in_each_data_record(k) = 100;
    end
end


k = HDR.num_signals;

if(k<4)
    posit = get(handles.backbutton,'Position');
    posit(1) = 3.5;
    set(handles.backbutton,'Position',posit);
    posit = get(handles.filenametext,'Position');
    posit(1) = 23;
    set(handles.filenametext,'Position',posit);
    posit = get(handles.filename,'Position');
    posit(1) = 19.5;
    set(handles.filename,'Position',posit);
    posit = get(handles.createbutton,'Position');
    posit(1) = 41.5;
    set(handles.createbutton,'Position',posit);
else
    posit = get(handles.backbutton,'Position');
    posit(1) = 35;
    set(handles.backbutton,'Position',posit);
    posit = get(handles.filenametext,'Position');
    posit(1) = 54.5;
    set(handles.filenametext,'Position',posit);
    posit = get(handles.filename,'Position');
    posit(1) = 51;
    set(handles.filename,'Position',posit);
    posit = get(handles.createbutton,'Position');
    posit(1) = 73;
    set(handles.createbutton,'Position',posit);
end

for k = 1:HDR.num_signals
    if (k==1)
        set(handles.label1,'String',HDR.label{k});
        set(handles.transducer1,'String',HDR.transducer{k});
        set(handles.physdim1,'String',HDR.physical_dimension{k});
        set(handles.physmin1,'String',HDR.physical_minimum(k));
        set(handles.physmax1,'String',HDR.physical_maximum(k));
        set(handles.digimin1,'String',HDR.digital_minimum(k));
        set(handles.digimax1,'String',HDR.digital_maximum(k));
        set(handles.prefiltering1,'String',HDR.prefiltering{k});
        set(handles.numsam1,'String',HDR.number_samples_in_each_data_record(k));
        set(handles.signal1,'Visible','on');
        posit = get(handles.signal1,'Position');
        posit(1) = 1;
        posit(2) = 6;
        set(handles.signal1,'Position',posit);
        set(handles.signal2,'Visible','off');
        set(handles.signal3,'Visible','off');
        set(handles.signal4,'Visible','off');
        set(handles.signal5,'Visible','off');
        set(handles.signal6,'Visible','off');
    elseif (k==2)
        set(handles.label2,'String',HDR.label{k});
        set(handles.transducer2,'String',HDR.transducer{k});
        set(handles.physdim2,'String',HDR.physical_dimension{k});
        set(handles.physmin2,'String',HDR.physical_minimum(k));
        set(handles.physmax2,'String',HDR.physical_maximum(k));
        set(handles.digimin2,'String',HDR.digital_minimum(k));
        set(handles.digimax2,'String',HDR.digital_maximum(k));
        set(handles.prefiltering2,'String',HDR.prefiltering{k});
        set(handles.numsam2,'String',HDR.number_samples_in_each_data_record(k));
        set(handles.signal1,'Visible','on');
        posit = get(handles.signal1,'Position');
        posit(1) = 1;
        posit(2) = 21;
        set(handles.signal1,'Position',posit);
        set(handles.signal2,'Visible','on');
        posit(1) = 1;
        posit(2) = 6;
        set(handles.signal2,'Position',posit);
        set(handles.signal3,'Visible','off');
        set(handles.signal4,'Visible','off');
        set(handles.signal5,'Visible','off');
        set(handles.signal6,'Visible','off');
    elseif (k==3)
        set(handles.label3,'String',HDR.label{k});
        set(handles.transducer3,'String',HDR.transducer{k});
        set(handles.physdim3,'String',HDR.physical_dimension{k});
        set(handles.physmin3,'String',HDR.physical_minimum(k));
        set(handles.physmax3,'String',HDR.physical_maximum(k));
        set(handles.digimin3,'String',HDR.digital_minimum(k));
        set(handles.digimax3,'String',HDR.digital_maximum(k));
        set(handles.prefiltering3,'String',HDR.prefiltering{k});
        set(handles.numsam3,'String',HDR.number_samples_in_each_data_record(k));
        set(handles.signal1,'Visible','on');
        posit = get(handles.signal1,'Position');
        posit(1) = 1;
        posit(2) = 36;
        set(handles.signal1,'Position',posit);
        set(handles.signal2,'Visible','on');
        posit(1) = 1;
        posit(2) = 21;
        set(handles.signal2,'Position',posit);
        set(handles.signal3,'Visible','on');
        posit(1) = 1;
        posit(2) = 6;
        set(handles.signal3,'Position',posit);
        set(handles.signal4,'Visible','off');
        set(handles.signal5,'Visible','off');
        set(handles.signal6,'Visible','off');
    elseif (k==4)
        set(handles.label4,'String',HDR.label{k});
        set(handles.transducer4,'String',HDR.transducer{k});
        set(handles.physdim4,'String',HDR.physical_dimension{k});
        set(handles.physmin4,'String',HDR.physical_minimum(k));
        set(handles.physmax4,'String',HDR.physical_maximum(k));
        set(handles.digimin4,'String',HDR.digital_minimum(k));
        set(handles.digimax4,'String',HDR.digital_maximum(k));
        set(handles.prefiltering4,'String',HDR.prefiltering{k});
        set(handles.numsam4,'String',HDR.number_samples_in_each_data_record(k));
        set(handles.signal1,'Visible','on');
        posit = get(handles.signal1,'Position');
        posit(1) = 1;
        posit(2) = 21;
        set(handles.signal1,'Position',posit);
        set(handles.signal2,'Visible','on');
        posit(1) = 1;
        posit(2) = 6;
        set(handles.signal2,'Position',posit);
        set(handles.signal3,'Visible','on');
        posit(1) = 60;
        posit(2) = 21;
        set(handles.signal3,'Position',posit);
        set(handles.signal4,'Visible','on');
        posit(1) = 60;
        posit(2) = 6;
        set(handles.signal4,'Position',posit);
        set(handles.signal5,'Visible','off');
        set(handles.signal6,'Visible','off');
    elseif (k==5)
        set(handles.label5,'String',HDR.label{k});
        set(handles.transducer5,'String',HDR.transducer{k});
        set(handles.physdim5,'String',HDR.physical_dimension{k});
        set(handles.physmin5,'String',HDR.physical_minimum(k));
        set(handles.physmax5,'String',HDR.physical_maximum(k));
        set(handles.digimin5,'String',HDR.digital_minimum(k));
        set(handles.digimax4,'String',HDR.digital_maximum(k));
        set(handles.prefiltering5,'String',HDR.prefiltering{k});
        set(handles.numsam5,'String',HDR.number_samples_in_each_data_record(k));
        set(handles.signal1,'Visible','on');
        posit = get(handles.signal1,'Position');
        posit(1) = 1;
        posit(2) = 36;
        set(handles.signal1,'Position',posit);
        set(handles.signal2,'Visible','on');
        posit(1) = 1;
        posit(2) = 21;
        set(handles.signal2,'Position',posit);
        set(handles.signal3,'Visible','on');
        posit(1) = 60;
        posit(2) = 36;
        set(handles.signal3,'Position',posit);
        set(handles.signal4,'Visible','on');
        posit(1) = 60;
        posit(2) = 21;
        set(handles.signal4,'Position',posit);
        set(handles.signal5,'Visible','on');
        posit(1) = 30;
        posit(2) = 6;
        set(handles.signal5,'Position',posit);
        set(handles.signal6,'Visible','off');
    elseif (k==6)
        set(handles.label6,'String',HDR.label{k});
        set(handles.transducer6,'String',HDR.transducer{k});
        set(handles.physdim6,'String',HDR.physical_dimension{k});
        set(handles.physmin6,'String',HDR.physical_minimum(k));
        set(handles.physmax6,'String',HDR.physical_maximum(k));
        set(handles.digimin6,'String',HDR.digital_minimum(k));
        set(handles.digimax6,'String',HDR.digital_maximum(k));
        set(handles.prefiltering6,'String',HDR.prefiltering{k});
        set(handles.numsam6,'String',HDR.number_samples_in_each_data_record(k));
        set(handles.signal1,'Visible','on');
        posit = get(handles.signal1,'Position');
        posit(1) = 1;
        posit(2) = 36;
        set(handles.signal1,'Position',posit);
        set(handles.signal2,'Visible','on');
        posit(1) = 1;
        posit(2) = 21;
        set(handles.signal2,'Position',posit);
        set(handles.signal3,'Visible','on');
        posit(1) = 1;
        posit(2) = 6;
        set(handles.signal3,'Position',posit);
        set(handles.signal4,'Visible','on');
        posit(1) = 60;
        posit(2) = 36;
        set(handles.signal4,'Position',posit);
        set(handles.signal5,'Visible','on');
        posit(1) = 60;
        posit(2) = 21;
        set(handles.signal5,'Position',posit);
        set(handles.signal6,'Visible','on');
        posit(1) = 60;
        posit(2) = 6;
        set(handles.signal6,'Position',posit);
    end
end
set(handles.figure1,'UserData',HDR);
% UIWAIT makes createEDFSignal wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = createEDFSignal_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in backbutton.
function backbutton_Callback(hObject, eventdata, handles)
HDR = get(handles.figure1,'UserData');
for k=1:HDR.num_signals
    if k==1
        HDR.label{k} = get(handles.label1,'String');
        HDR.transducer{k} = get(handles.transducer1,'String');
        HDR.physical_dimension{k} = get(handles.physdim1,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin1,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax1,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin1,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax1,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering1,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam1,'String'));
    elseif k==2
        HDR.label{k} = get(handles.label2,'String');
        HDR.transducer{k} = get(handles.transducer2,'String');
        HDR.physical_dimension{k} = get(handles.physdim2,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin2,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax2,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin2,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax2,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering2,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam2,'String'));
    elseif k==3
        HDR.label{k} = get(handles.label3,'String');
        HDR.transducer{k} = get(handles.transducer3,'String');
        HDR.physical_dimension{k} = get(handles.physdim3,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin3,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax3,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin3,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax3,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering3,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam3,'String'));
    elseif k==4
        HDR.label{k} = get(handles.label4,'String');
        HDR.transducer{k} = get(handles.transducer4,'String');
        HDR.physical_dimension{k} = get(handles.physdim4,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin4,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax4,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin4,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax4,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering4,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam4,'String'));
    elseif k==5
        HDR.label{k} = get(handles.label5,'String');
        HDR.transducer{k} = get(handles.transducer5,'String');
        HDR.physical_dimension{k} = get(handles.physdim4,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin5,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax5,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin5,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax5,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering5,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam5,'String'));
    elseif k==6
        HDR.label{k} = get(handles.label6,'String');
        HDR.transducer{k} = get(handles.transducer6,'String');
        HDR.physical_dimension{k} = get(handles.physdim6,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin6,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax6,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin6,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax6,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering6,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam6,'String'));
    end
end

posit = get(handles.figure1,'Position');
posit(3) = 36;
posit(4) = 25;
close();
createEDF('UserData',HDR,'Position',posit);
% hObject    handle to backbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function filename_Callback(hObject, eventdata, handles)
% hObject    handle to filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filename as text
%        str2double(get(hObject,'String')) returns contents of filename as a double


% --- Executes during object creation, after setting all properties.
function filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in createbutton.
function createbutton_Callback(hObject, eventdata, handles)
HDR = get(handles.figure1,'UserData');
for k=1:HDR.num_signals
    if k==1
        HDR.label{k} = get(handles.label1,'String');
        HDR.transducer{k} = get(handles.transducer1,'String');
        HDR.physical_dimension{k} = get(handles.physdim1,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin1,'String'));
        HDR.physical_maximum(k) = str2double(get(handles.physmax1,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin1,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax1,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering1,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam1,'String'));
    elseif k==2
        HDR.label{k} = get(handles.label2,'String');
        HDR.transducer{k} = get(handles.transducer2,'String');
        HDR.physical_dimension{k} = get(handles.physdim2,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin2,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax2,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin2,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax2,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering2,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam2,'String'));
    elseif k==3
        HDR.label{k} = get(handles.label3,'String');
        HDR.transducer{k} = get(handles.transducer3,'String');
        HDR.physical_dimension{k} = get(handles.physdim3,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin3,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax3,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin3,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax3,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering3,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam3,'String'));
    elseif k==4
        HDR.label{k} = get(handles.label4,'String');
        HDR.transducer{k} = get(handles.transducer4,'String');
        HDR.physical_dimension{k} = get(handles.physdim4,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin4,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax4,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin4,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax4,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering4,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam4,'String'));
    elseif k==5
        HDR.label{k} = get(handles.label5,'String');
        HDR.transducer{k} = get(handles.transducer5,'String');
        HDR.physical_dimension{k} = get(handles.physdim4,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin5,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax5,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin5,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax5,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering5,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam5,'String'));
    elseif k==6
        HDR.label{k} = get(handles.label6,'String');
        HDR.transducer{k} = get(handles.transducer6,'String');
        HDR.physical_dimension{k} = get(handles.physdim6,'String');
        HDR.physical_minimum(k) = str2double(get(handles.physmin6,'String'));
        HDR.phsyical_maximum(k) = str2double(get(handles.physmax6,'String'));
        HDR.digital_minimum(k) = str2double(get(handles.digimin6,'String'));
        HDR.digital_maximum(k) = str2double(get(handles.digimax6,'String'));
        HDR.prefiltering{k} = get(handles.prefiltering6,'String');
        HDR.number_samples_in_each_data_record(k) = str2double(get(handles.numsam6,'String'));
    end
end

for k=1:HDR.num_signals
    if k==1
        sigtype = get(handles.signaltype1,'Value');
        signame = get(handles.signalname1,'String');
    elseif k==2
        sigtype = get(handles.signaltype2,'Value');
        signame = get(handles.signalname2,'String');
    elseif k==3
        sigtype = get(handles.signaltype3,'Value');
        signame = get(handles.signalname3,'String');
    elseif k==4
        sigtype = get(handles.signaltype4,'Value');
        signame = get(handles.signalname4,'String');
    elseif k==5
        sigtype = get(handles.signaltype5,'Value');
        signame = get(handles.signalname5,'String');
    else
        sigtype = get(handles.signaltype6,'Value');
        signame = get(handles.signalname6,'String');
    end
    
    if (sigtype == 1)
        if (strcmp(signame,'None')==1)
            signals{k} = repmat(5000*k,1852200,1);
        else
            signal{k} = evalin('base',signame);
        end
    else
        if (strcmp(signame,'0')==1)
            signals{k} = repmat(5000*k,1852200,1);
        else
            signal{k} = load(sigfile);
        end
    end
end
writeEDF(get(handles.filename,'String'),HDR,signal);
close();
% hObject    handle to createbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function backbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to backbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function filenametext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filenametext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function createbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to createbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function signal4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signal4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function label1_Callback(hObject, eventdata, handles)
% hObject    handle to label1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of label1 as text
%        str2double(get(hObject,'String')) returns contents of label1 as a double


% --- Executes during object creation, after setting all properties.
function label1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to label1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmin1_Callback(hObject, eventdata, handles)
% hObject    handle to physmin1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmin1 as text
%        str2double(get(hObject,'String')) returns contents of physmin1 as a double


% --- Executes during object creation, after setting all properties.
function physmin1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmin1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmax1_Callback(hObject, eventdata, handles)
% hObject    handle to physmax1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmax1 as text
%        str2double(get(hObject,'String')) returns contents of physmax1 as a double


% --- Executes during object creation, after setting all properties.
function physmax1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmax1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimin1_Callback(hObject, eventdata, handles)
% hObject    handle to digimin1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimin1 as text
%        str2double(get(hObject,'String')) returns contents of digimin1 as a double


% --- Executes during object creation, after setting all properties.
function digimin1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimin1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimax1_Callback(hObject, eventdata, handles)
% hObject    handle to digimax1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimax1 as text
%        str2double(get(hObject,'String')) returns contents of digimax1 as a double


% --- Executes during object creation, after setting all properties.
function digimax1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimax1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numsam1_Callback(hObject, eventdata, handles)
% hObject    handle to numsam1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numsam1 as text
%        str2double(get(hObject,'String')) returns contents of numsam1 as a double


% --- Executes during object creation, after setting all properties.
function numsam1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numsam1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physdim1_Callback(hObject, eventdata, handles)
% hObject    handle to physdim1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physdim1 as text
%        str2double(get(hObject,'String')) returns contents of physdim1 as a double


% --- Executes during object creation, after setting all properties.
function physdim1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physdim1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function transducer1_Callback(hObject, eventdata, handles)
% hObject    handle to transducer1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of transducer1 as text
%        str2double(get(hObject,'String')) returns contents of transducer1 as a double


% --- Executes during object creation, after setting all properties.
function transducer1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transducer1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function prefiltering1_Callback(hObject, eventdata, handles)
% hObject    handle to prefiltering1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prefiltering1 as text
%        str2double(get(hObject,'String')) returns contents of prefiltering1 as a double


% --- Executes during object creation, after setting all properties.
function prefiltering1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prefiltering1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function label2_Callback(hObject, eventdata, handles)
% hObject    handle to label2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of label2 as text
%        str2double(get(hObject,'String')) returns contents of label2 as a double


% --- Executes during object creation, after setting all properties.
function label2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to label2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmin2_Callback(hObject, eventdata, handles)
% hObject    handle to physmin2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmin2 as text
%        str2double(get(hObject,'String')) returns contents of physmin2 as a double


% --- Executes during object creation, after setting all properties.
function physmin2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmin2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmax2_Callback(hObject, eventdata, handles)
% hObject    handle to physmax2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmax2 as text
%        str2double(get(hObject,'String')) returns contents of physmax2 as a double


% --- Executes during object creation, after setting all properties.
function physmax2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmax2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimin2_Callback(hObject, eventdata, handles)
% hObject    handle to digimin2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimin2 as text
%        str2double(get(hObject,'String')) returns contents of digimin2 as a double


% --- Executes during object creation, after setting all properties.
function digimin2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimin2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimax2_Callback(hObject, eventdata, handles)
% hObject    handle to digimax2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimax2 as text
%        str2double(get(hObject,'String')) returns contents of digimax2 as a double


% --- Executes during object creation, after setting all properties.
function digimax2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimax2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numsam2_Callback(hObject, eventdata, handles)
% hObject    handle to numsam2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numsam2 as text
%        str2double(get(hObject,'String')) returns contents of numsam2 as a double


% --- Executes during object creation, after setting all properties.
function numsam2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numsam2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physdim2_Callback(hObject, eventdata, handles)
% hObject    handle to physdim2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physdim2 as text
%        str2double(get(hObject,'String')) returns contents of physdim2 as a double


% --- Executes during object creation, after setting all properties.
function physdim2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physdim2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function transducer2_Callback(hObject, eventdata, handles)
% hObject    handle to transducer2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of transducer2 as text
%        str2double(get(hObject,'String')) returns contents of transducer2 as a double


% --- Executes during object creation, after setting all properties.
function transducer2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transducer2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function prefiltering2_Callback(hObject, eventdata, handles)
% hObject    handle to prefiltering2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prefiltering2 as text
%        str2double(get(hObject,'String')) returns contents of prefiltering2 as a double


% --- Executes during object creation, after setting all properties.
function prefiltering2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prefiltering2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function label3_Callback(hObject, eventdata, handles)
% hObject    handle to label3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of label3 as text
%        str2double(get(hObject,'String')) returns contents of label3 as a double


% --- Executes during object creation, after setting all properties.
function label3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to label3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit21_Callback(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit21 as text
%        str2double(get(hObject,'String')) returns contents of edit21 as a double


% --- Executes during object creation, after setting all properties.
function edit21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmax3_Callback(hObject, eventdata, handles)
% hObject    handle to physmax3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmax3 as text
%        str2double(get(hObject,'String')) returns contents of physmax3 as a double


% --- Executes during object creation, after setting all properties.
function physmax3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmax3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimin3_Callback(hObject, eventdata, handles)
% hObject    handle to digimin3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimin3 as text
%        str2double(get(hObject,'String')) returns contents of digimin3 as a double


% --- Executes during object creation, after setting all properties.
function digimin3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimin3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimax3_Callback(hObject, eventdata, handles)
% hObject    handle to digimax3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimax3 as text
%        str2double(get(hObject,'String')) returns contents of digimax3 as a double


% --- Executes during object creation, after setting all properties.
function digimax3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimax3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numsam3_Callback(hObject, eventdata, handles)
% hObject    handle to numsam3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numsam3 as text
%        str2double(get(hObject,'String')) returns contents of numsam3 as a double


% --- Executes during object creation, after setting all properties.
function numsam3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numsam3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physdim3_Callback(hObject, eventdata, handles)
% hObject    handle to physdim3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physdim3 as text
%        str2double(get(hObject,'String')) returns contents of physdim3 as a double


% --- Executes during object creation, after setting all properties.
function physdim3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physdim3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmin3_Callback(hObject, eventdata, handles)
% hObject    handle to physmin3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmin3 as text
%        str2double(get(hObject,'String')) returns contents of physmin3 as a double


% --- Executes during object creation, after setting all properties.
function physmin3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmin3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function prefiltering3_Callback(hObject, eventdata, handles)
% hObject    handle to prefiltering3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prefiltering3 as text
%        str2double(get(hObject,'String')) returns contents of prefiltering3 as a double


% --- Executes during object creation, after setting all properties.
function prefiltering3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prefiltering3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function label4_Callback(hObject, eventdata, handles)
% hObject    handle to label4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of label4 as text
%        str2double(get(hObject,'String')) returns contents of label4 as a double


% --- Executes during object creation, after setting all properties.
function label4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to label4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmin4_Callback(hObject, eventdata, handles)
% hObject    handle to physmin4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmin4 as text
%        str2double(get(hObject,'String')) returns contents of physmin4 as a double


% --- Executes during object creation, after setting all properties.
function physmin4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmin4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmax4_Callback(hObject, eventdata, handles)
% hObject    handle to physmax4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmax4 as text
%        str2double(get(hObject,'String')) returns contents of physmax4 as a double


% --- Executes during object creation, after setting all properties.
function physmax4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmax4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimin4_Callback(hObject, eventdata, handles)
% hObject    handle to digimin4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimin4 as text
%        str2double(get(hObject,'String')) returns contents of digimin4 as a double


% --- Executes during object creation, after setting all properties.
function digimin4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimin4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimax4_Callback(hObject, eventdata, handles)
% hObject    handle to digimax4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimax4 as text
%        str2double(get(hObject,'String')) returns contents of digimax4 as a double


% --- Executes during object creation, after setting all properties.
function digimax4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimax4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numsam4_Callback(hObject, eventdata, handles)
% hObject    handle to numsam4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numsam4 as text
%        str2double(get(hObject,'String')) returns contents of numsam4 as a double


% --- Executes during object creation, after setting all properties.
function numsam4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numsam4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physdim4_Callback(hObject, eventdata, handles)
% hObject    handle to physdim4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physdim4 as text
%        str2double(get(hObject,'String')) returns contents of physdim4 as a double


% --- Executes during object creation, after setting all properties.
function physdim4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physdim4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function transducer4_Callback(hObject, eventdata, handles)
% hObject    handle to transducer4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of transducer4 as text
%        str2double(get(hObject,'String')) returns contents of transducer4 as a double


% --- Executes during object creation, after setting all properties.
function transducer4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transducer4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function prefiltering4_Callback(hObject, eventdata, handles)
% hObject    handle to prefiltering4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prefiltering4 as text
%        str2double(get(hObject,'String')) returns contents of prefiltering4 as a double


% --- Executes during object creation, after setting all properties.
function prefiltering4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prefiltering4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function signalname1_Callback(hObject, eventdata, handles)
% hObject    handle to signalname1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of signalname1 as text
%        str2double(get(hObject,'String')) returns contents of signalname1 as a double


% --- Executes during object creation, after setting all properties.
function signalname1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signalname1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function transducer3_Callback(hObject, eventdata, handles)
% hObject    handle to transducer3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of transducer3 as text
%        str2double(get(hObject,'String')) returns contents of transducer3 as a double


% --- Executes during object creation, after setting all properties.
function transducer3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transducer3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function signal1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signal1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on selection change in signaltype1.
function signaltype1_Callback(hObject, eventdata, handles)
signaltype = get(hObject,'Value');
if (signaltype == 1)
    set(handles.signalbrowse1,'Visible','off');
    set(handles.signalname1,'String','None');
    posit = get(handles.signalname1,'Position');
    posit(1) = 32;
    posit(3) = 22;
    set(handles.signalname1,'Position',posit);
else
    set(handles.signalbrowse1,'Visible','on');
    set(handles.signalname1,'String','0');
    posit = get(handles.signalname1,'Position');
    posit(1) = 40.5;
    posit(3) = 13.5;
    set(handles.signalname1,'Position',posit);
end
% hObject    handle to signaltype1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns signaltype1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from signaltype1


% --- Executes during object creation, after setting all properties.
function signaltype1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signaltype1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in signalbrowse1.
function signalbrowse1_Callback(hObject, eventdata, handles)
[sigfilename,sigpathname] = uigetfile('*.txt','Signal File');
set(handles.signalname1,'String',sigfilename);
% hObject    handle to signalbrowse1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function signalbrowse1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signalbrowse1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function signalname2_Callback(hObject, eventdata, handles)
% hObject    handle to signalname2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of signalname2 as text
%        str2double(get(hObject,'String')) returns contents of signalname2 as a double


% --- Executes during object creation, after setting all properties.
function signalname2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signalname2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in signaltype2.
function signaltype2_Callback(hObject, eventdata, handles)
signaltype = get(hObject,'Value');
if (signaltype == 1)
    set(handles.signalbrowse2,'Visible','off');
    set(handles.signalname2,'String','None');
    posit = get(handles.signalname2,'Position');
    posit(1) = 32;
    posit(3) = 22;
    set(handles.signalname2,'Position',posit);
else
    set(handles.signalbrowse2,'Visible','on');
    set(handles.signalname2,'String','0');
    posit = get(handles.signalname2,'Position');
    posit(1) = 40.5;
    posit(3) = 13.5;
    set(handles.signalname2,'Position',posit);
end
% hObject    handle to signaltype2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns signaltype2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from signaltype2


% --- Executes during object creation, after setting all properties.
function signaltype2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signaltype2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in signalbrowse2.
function signalbrowse2_Callback(hObject, eventdata, handles)
[sigfilename,sigpathname] = uigetfile('*.txt','Signal File');
set(handles.signalname2,'String',sigfilename);
% hObject    handle to signalbrowse2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function signalname3_Callback(hObject, eventdata, handles)
% hObject    handle to signalname3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of signalname3 as text
%        str2double(get(hObject,'String')) returns contents of signalname3 as a double


% --- Executes during object creation, after setting all properties.
function signalname3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signalname3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in signaltype3.
function signaltype3_Callback(hObject, eventdata, handles)
signaltype = get(hObject,'Value');
if (signaltype == 1)
    set(handles.signalbrowse3,'Visible','off');
    set(handles.signalname3,'String','None');
    posit = get(handles.signalname3,'Position');
    posit(1) = 32;
    posit(3) = 22;
    set(handles.signalname3,'Position',posit);
else
    set(handles.signalbrowse3,'Visible','on');
    set(handles.signalname3,'String','0');
    posit = get(handles.signalname3,'Position');
    posit(1) = 40.5;
    posit(3) = 13.5;
    set(handles.signalname3,'Position',posit);
end
% hObject    handle to signaltype3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns signaltype3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from signaltype3


% --- Executes during object creation, after setting all properties.
function signaltype3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signaltype3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in signalbrowse3.
function signalbrowse3_Callback(hObject, eventdata, handles)
[sigfilename,sigpathname] = uigetfile('*.txt','Signal File');
set(handles.signalname3,'String',sigfilename);
% hObject    handle to signalbrowse3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function signalname4_Callback(hObject, eventdata, handles)
% hObject    handle to signalname4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of signalname4 as text
%        str2double(get(hObject,'String')) returns contents of signalname4 as a double


% --- Executes during object creation, after setting all properties.
function signalname4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signalname4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in signaltype4.
function signaltype4_Callback(hObject, eventdata, handles)
signaltype = get(hObject,'Value');
if (signaltype == 1)
    set(handles.signalbrowse4,'Visible','off');
    set(handles.signalname4,'String','None');
    posit = get(handles.signalname4,'Position');
    posit(1) = 32;
    posit(3) = 22;
    set(handles.signalname4,'Position',posit);
else
    set(handles.signalbrowse4,'Visible','on');
    set(handles.signalname4,'String','0');
    posit = get(handles.signalname4,'Position');
    posit(1) = 40.5;
    posit(3) = 13.5;
    set(handles.signalname4,'Position',posit);
end
% hObject    handle to signaltype4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns signaltype4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from signaltype4


% --- Executes during object creation, after setting all properties.
function signaltype4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signaltype4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in signalbrowse4.
function signalbrowse4_Callback(hObject, eventdata, handles)
[sigfilename,sigpathname] = uigetfile('*.txt','Signal File');
set(handles.signalname4,'String',sigfilename);
% hObject    handle to signalbrowse4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function label5_Callback(hObject, eventdata, handles)
% hObject    handle to label5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of label5 as text
%        str2double(get(hObject,'String')) returns contents of label5 as a double


% --- Executes during object creation, after setting all properties.
function label5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to label5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmin5_Callback(hObject, eventdata, handles)
% hObject    handle to physmin5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmin5 as text
%        str2double(get(hObject,'String')) returns contents of physmin5 as a double


% --- Executes during object creation, after setting all properties.
function physmin5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmin5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmax5_Callback(hObject, eventdata, handles)
% hObject    handle to physmax5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmax5 as text
%        str2double(get(hObject,'String')) returns contents of physmax5 as a double


% --- Executes during object creation, after setting all properties.
function physmax5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmax5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimin5_Callback(hObject, eventdata, handles)
% hObject    handle to digimin5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimin5 as text
%        str2double(get(hObject,'String')) returns contents of digimin5 as a double


% --- Executes during object creation, after setting all properties.
function digimin5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimin5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimax5_Callback(hObject, eventdata, handles)
% hObject    handle to digimax5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimax5 as text
%        str2double(get(hObject,'String')) returns contents of digimax5 as a double


% --- Executes during object creation, after setting all properties.
function digimax5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimax5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numsam5_Callback(hObject, eventdata, handles)
% hObject    handle to numsam5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numsam5 as text
%        str2double(get(hObject,'String')) returns contents of numsam5 as a double


% --- Executes during object creation, after setting all properties.
function numsam5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numsam5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physdim5_Callback(hObject, eventdata, handles)
% hObject    handle to physdim5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physdim5 as text
%        str2double(get(hObject,'String')) returns contents of physdim5 as a double


% --- Executes during object creation, after setting all properties.
function physdim5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physdim5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function transducer5_Callback(hObject, eventdata, handles)
% hObject    handle to transducer5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of transducer5 as text
%        str2double(get(hObject,'String')) returns contents of transducer5 as a double


% --- Executes during object creation, after setting all properties.
function transducer5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transducer5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function prefiltering5_Callback(hObject, eventdata, handles)
% hObject    handle to prefiltering5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prefiltering5 as text
%        str2double(get(hObject,'String')) returns contents of prefiltering5 as a double


% --- Executes during object creation, after setting all properties.
function prefiltering5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prefiltering5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function signalname5_Callback(hObject, eventdata, handles)
% hObject    handle to signalname5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of signalname5 as text
%        str2double(get(hObject,'String')) returns contents of signalname5 as a double


% --- Executes during object creation, after setting all properties.
function signalname5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signalname5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in signaltype5.
function signaltype5_Callback(hObject, eventdata, handles)
signaltype = get(hObject,'Value');
if (signaltype == 1)
    set(handles.signalbrowse5,'Visible','off');
    set(handles.signalname5,'String','None');
    posit = get(handles.signalname5,'Position');
    posit(1) = 32;
    posit(3) = 22;
    set(handles.signalname5,'Position',posit);
else
    set(handles.signalbrowse5,'Visible','on');
    set(handles.signalname5,'String','0');
    posit = get(handles.signalname5,'Position');
    posit(1) = 40.5;
    posit(3) = 13.5;
    set(handles.signalname5,'Position',posit);
end
% hObject    handle to signaltype5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns signaltype5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from signaltype5


% --- Executes during object creation, after setting all properties.
function signaltype5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signaltype5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in signalbrowse5.
function signalbrowse5_Callback(hObject, eventdata, handles)
[sigfilename,sigpathname] = uigetfile('*.txt','Signal File');
set(handles.signalname5,'String',sigfilename);
% hObject    handle to signalbrowse5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function label6_Callback(hObject, eventdata, handles)
% hObject    handle to label6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of label6 as text
%        str2double(get(hObject,'String')) returns contents of label6 as a double


% --- Executes during object creation, after setting all properties.
function label6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to label6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmin6_Callback(hObject, eventdata, handles)
% hObject    handle to physmin6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmin6 as text
%        str2double(get(hObject,'String')) returns contents of physmin6 as a double


% --- Executes during object creation, after setting all properties.
function physmin6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmin6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physmax6_Callback(hObject, eventdata, handles)
% hObject    handle to physmax6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physmax6 as text
%        str2double(get(hObject,'String')) returns contents of physmax6 as a double


% --- Executes during object creation, after setting all properties.
function physmax6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physmax6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimin6_Callback(hObject, eventdata, handles)
% hObject    handle to digimin6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimin6 as text
%        str2double(get(hObject,'String')) returns contents of digimin6 as a double


% --- Executes during object creation, after setting all properties.
function digimin6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimin6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function digimax6_Callback(hObject, eventdata, handles)
% hObject    handle to digimax6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of digimax6 as text
%        str2double(get(hObject,'String')) returns contents of digimax6 as a double


% --- Executes during object creation, after setting all properties.
function digimax6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to digimax6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numsam6_Callback(hObject, eventdata, handles)
% hObject    handle to numsam6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numsam6 as text
%        str2double(get(hObject,'String')) returns contents of numsam6 as a double


% --- Executes during object creation, after setting all properties.
function numsam6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numsam6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function physdim6_Callback(hObject, eventdata, handles)
% hObject    handle to physdim6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of physdim6 as text
%        str2double(get(hObject,'String')) returns contents of physdim6 as a double


% --- Executes during object creation, after setting all properties.
function physdim6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to physdim6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function transducer6_Callback(hObject, eventdata, handles)
% hObject    handle to transducer6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of transducer6 as text
%        str2double(get(hObject,'String')) returns contents of transducer6 as a double


% --- Executes during object creation, after setting all properties.
function transducer6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transducer6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function prefiltering6_Callback(hObject, eventdata, handles)
% hObject    handle to prefiltering6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prefiltering6 as text
%        str2double(get(hObject,'String')) returns contents of prefiltering6 as a double


% --- Executes during object creation, after setting all properties.
function prefiltering6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prefiltering6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function signalname6_Callback(hObject, eventdata, handles)
% hObject    handle to signalname6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of signalname6 as text
%        str2double(get(hObject,'String')) returns contents of signalname6 as a double


% --- Executes during object creation, after setting all properties.
function signalname6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signalname6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in signaltype6.
function signaltype6_Callback(hObject, eventdata, handles)
signaltype = get(hObject,'Value');
if (signaltype == 1)
    set(handles.signalbrowse6,'Visible','off');
    set(handles.signalname6,'String','None');
    posit = get(handles.signalname6,'Position');
    posit(1) = 32;
    posit(3) = 22;
    set(handles.signalname6,'Position',posit);
else
    set(handles.signalbrowse6,'Visible','on');
    set(handles.signalname6,'String','0');
    posit = get(handles.signalname6,'Position');
    posit(1) = 40.5;
    posit(3) = 13.5;
    set(handles.signalname6,'Position',posit);
end
% hObject    handle to signaltype6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns signaltype6 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from signaltype6


% --- Executes during object creation, after setting all properties.
function signaltype6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signaltype6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in signalbrowse6.
function signalbrowse6_Callback(hObject, eventdata, handles)
[sigfilename,sigpathname] = uigetfile('*.txt','Signal File');
set(handles.signalname6,'String',sigfilename);
% hObject    handle to signalbrowse6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


