function varargout = channelSelector(varargin)
% CHANNELSELECTOR MATLAB code for channelSelector.fig
%      CHANNELSELECTOR, by itself, creates a new CHANNELSELECTOR or raises the existing
%      singleton*.
%
%      H = CHANNELSELECTOR returns the handle to a new CHANNELSELECTOR or the handle to
%      the existing singleton*.
%
%      CHANNELSELECTOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CHANNELSELECTOR.M with the given input arguments.
%
%      CHANNELSELECTOR('Property','Value',...) creates a new CHANNELSELECTOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before channelSelector_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to channelSelector_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help channelSelector

% Last Modified by GUIDE v2.5 18-Mar-2014 14:21:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @channelSelector_OpeningFcn, ...
                   'gui_OutputFcn',  @channelSelector_OutputFcn, ...
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


% --- Executes just before channelSelector is made visible.
function channelSelector_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to channelSelector (see VARARGIN)

% Choose default command line output for channelSelector
handles.output = hObject;

if(numel(varargin)<3)
    selectedIndices = [];
else
    selectedIndices = varargin{3};
end
if(numel(varargin)<2)
    disp('channelSelector requires at least 2 inputs: 1. number source required; 2. Cell of Channel labels; 3. Selected Indices (can be empty)');
    handles.user.selectedIndices = [];

    guidata(hObject, handles);

else
    nReqdIndices = varargin{1};
    channelLabels = varargin{2};
    
    if(isempty(selectedIndices)|| numel(selectedIndices)<nReqdIndices)
        selectedIndices = 1:nReqdIndices;
    end
    handles.user.selectedIndices = selectedIndices;
    handles.user.nReqdIndices = nReqdIndices;
    handles.user.numSelectMenus = 14;
    populateLabels(handles,channelLabels);
    
    % Update handles structure
    guidata(hObject, handles);

    uiwait(handles.figure1);

end
    

function populateLabels(handles,channelLabels)

for n=1:handles.user.numSelectMenus
    textH = sprintf('text%u',n);
    menuH = sprintf('menuSrc%u',n);
    if(n<=handles.user.nReqdIndices)
        set(handles.(textH),'enable','on');
        set(handles.(menuH),'enable','on','string',channelLabels,'value',handles.user.selectedIndices(n));
    else
        set(handles.(textH),'enable','off');
        set(handles.(menuH),'enable','off','string',{''});
    end
end

function selectedIndices = getSelectedIndices(handles)

selectedIndices = nan(handles.user.nReqdIndices,1);
for n=1:handles.user.nReqdIndices
    menuH = sprintf('menuSrc%u',n);
    selectedIndices(n) = get(handles.(menuH),'value');
end



% --- Outputs from this function are returned to the command line.
function varargout = channelSelector_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.user.selectedIndices;

delete(hObject);




% --- Executes on button press in push_cancel.
function push_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to push_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.user.selectedIndices = [];
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes on button press in push_ok.
function push_ok_Callback(hObject, eventdata, handles)
% hObject    handle to push_ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% disp 'You pressed cancel';
handles.selectedIndices = getSelectedIndices(handles);
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.user.selectedIndices = [];
guidata(hObject, handles);
uiresume(handles.figure1);
