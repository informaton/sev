function varargout = montage_dlg(varargin)
% MONTAGE_DLG M-file for montage_dlg.fig
%      MONTAGE_DLG, by itself, creates a new MONTAGE_DLG or raises the existing
%      singleton*.
%
%      varagout{1} is a struct with the following fields
%         channels_selected = vector of indices selected
%         artifact_channel = index of artifact channel
%         primary_channel = index of primary channel
%         occular_channel = indices of occular channels 
%       *these fields are empty in the event that they are not selected.
%
%      MONTAGE_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MONTAGE_DLG.M with the given input arguments.
%
%      MONTAGE_DLG('Property','Value',...) creates a new MONTAGE_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before montage_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to montage_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Use this to pick which channels to load from an EDF based on the EDF channel_labels
% information that should be passed as a parameter.  The user clicks on the
% checkboxes for the channels they want loaded and then presses either OK
% or CANCEL.  The selected channels are returned as a logical vector (which can be used as indices) 
% if the user presses OK with some channels selected, otherwise
% an empty vector is returned.  
% primary, artifact, and occular 

%Hyatt Moore IV (<= 05-Oct-2010 12:35:55)

% Edit the above text to modify the response to help montage_dlg

% Last Modified by GUIDE v2.5 05-Oct-2010 12:35:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @montage_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @montage_dlg_OutputFcn, ...
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


% --- Executes just before montage_dlg is made visible.
function montage_dlg_OpeningFcn(hObject, eventdata, handles, channel_labels, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to montage_dlg (see VARARGIN)
%

units = 'pixels';
selected_handles = [];

if(~isempty(varargin))
    if(numel(varargin)>0)
        selected_handles = varargin{1};
    end;
    
end;


fig = handles.figure1;
set(fig,'visible','on','units',units,'CloseRequestFcn',@closeFigureCallback);


checkbox_handles = zeros(1,numel(channel_labels));
% radio_handles = zeros(1,numel(channel_labels));
cb_extent = [0 0 0 0];

% handles.button_group_handle = uibuttongroup('parent',fig,'visible','off','bordertype','none','units',units);
handles.user.artifact.color = [1 0 .5 ];
handles.user.primary.color = [0 1 .5];
handles.user.eye1.color = [1 .5 .5];
handles.user.eye2.color = [1 .5 .5];

handles.user.current_checkbox_handle = -1; %initialize to invalid handle

for k=1:numel(channel_labels)
    checkbox_handles(k) = uicontrol(fig,'style','checkbox','string',channel_labels{k},...
        'units',units,'visible','off','value',0,...
        'hittest','on','selectionhighlight','on','userdata',k);
    cb_extent = max([cb_extent;get(checkbox_handles(k),'extent')]);
end


pb_extent = [0 0 0 0];
handles.pushbutton_ok = uicontrol(fig,'style','pushbutton','units',units,'callback',@pushbutton_ok_callback,'string','OK','visible','off');
pb_extent = max([pb_extent;get(handles.pushbutton_ok,'extent')]);

handles.pushbutton_cancel = uicontrol(fig,'style','pushbutton','units',units,'callback',@pushbutton_cancel_callback,'string','CANCEL','visible','off');
pb_extent = max([pb_extent;get(handles.pushbutton_cancel,'extent')]);

spacing = max([20,cb_extent(4)]); %height of the text in pixels
cb_extent(4) = spacing;
cb_extent(3) = cb_extent(3)+spacing*2; %add the checkbox part in
pb_extent(3:4) = [pb_extent(3)+spacing, pb_extent(4)+spacing*3/5]; %add the button part in

rad_extent = [0 0 20 spacing];

fig_width = max([2*pb_extent(3)+spacing*3,cb_extent(3)+spacing*3+rad_extent(3)]);
fig_height = pb_extent(4)+spacing*3+cb_extent(4)*numel(channel_labels);

fig_pos = get(fig,'position');
fig_pos(3:4) = [fig_width, fig_height];

set(0,'Units',units) 
scnsize = get(0,'ScreenSize');
                
                
                    

set(fig,'position',fig_pos);
set(fig,'position',[(scnsize(3:4)-fig_pos(3:4))/2,fig_pos(3:4)]);

% set(handles.button_group_handle,'position',[1 1 fig_pos(3:4)],'visible','on','bordertype','none');

for k=1:numel(channel_labels) %align them to the left and drop them down the middle.  
    pos = [spacing, fig_height-spacing*(k)-spacing, cb_extent(3:4)];
    set(checkbox_handles(k),'visible','on','position',pos);
    
%     pos = [pos(1)+pos(3)+spacing,pos(2), rad_extent(3:4)];
%     set(radio_handles(k),'visible','on','position',pos);
end;

pos = [fig_width/2-spacing/2-pb_extent(3), spacing, pb_extent(3:4)];

set(handles.pushbutton_ok,'visible','on','position',pos);
pos = [fig_width/2+spacing/2, spacing, pb_extent(3:4)];
set(handles.pushbutton_cancel,'visible','on','position',pos);


set(checkbox_handles(selected_handles),'value',1,'enable','off');
handles.user.checkbox_handles = checkbox_handles;


% pri_index = strmatch(primary_string,channel_labels);
% art_index = strmatch(artifact_string,channel_labels);
% eye1_index = strmatch(ocular_strings{1},channel_labels);
% eye2_index = strmatch(ocular_strings{2},channel_labels);
% 
% if(~isempty(pri_index))
%     set(checkbox_handles(pri_index),'value',1);
%     handles.user.primary.handle = checkbox_handles(pri_index);
%     handles.user.primary.channel_index = pri_index;
%     set(handles.user.primary.panel_h,'visible','on','position',get(handles.user.primary.handle,'position'));
% end;
% 
% if(~isempty(art_index))
%     set(checkbox_handles(art_index),'value',1);
%     handles.user.artifact.handle = checkbox_handles(art_index);
%     handles.user.artifact.channel_index = art_index;
%     set(handles.user.artifact.panel_h,'visible','on','position',get(handles.user.artifact.handle,'position'));
% end;
% 
% if(~isempty(eye1_index))
%     set(checkbox_handles(eye1_index),'value',1);
%     handles.user.eye1.handle = checkbox_handles(eye1_index);
%     handles.user.eye1.channel_index = eye1_index;
%     set(handles.user.eye1.panel_h,'visible','on','position',get(handles.user.eye1.handle,'position'));
% end;
% 
% if(~isempty(eye2_index))
%     set(checkbox_handles(eye2_index),'value',1);
%     handles.user.eye2.handle = checkbox_handles(eye2_index);
%     handles.user.eye2.channel_index = eye2_index;
%     set(handles.user.eye2.panel_h,'visible','on','position',get(handles.user.eye2.handle,'position'));
% end;

uicontrol(handles.pushbutton_ok); %give OK the focus
% handles.text1 = uicontrol('style','text','string','hello world');
handles.output = []; %default output is empty

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes montage_dlg wait for user response (see UIRESUME)
uiwait(handles.figure1);


function pushbutton_ok_callback(hObject, eventdata)
handles = guidata(hObject);
select_values = get(handles.user.checkbox_handles,'value');
if(iscell(select_values))
    output.channels_selected = cell2mat(select_values)==1;
else
    output.channels_selected = select_values;
end


if(any(output.channels_selected))
    handles.output = output;
else
    handles.output = [];
end;

guidata(hObject, handles);
uiresume(handles.figure1);

function pushbutton_cancel_callback(hObject, eventdata)
% disp 'You pressed cancel';
handles = guidata(hObject);
handles.output = [];
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = montage_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(hObject);


function closeFigureCallback(hObject,eventdata)
%handles closing the function
handles = guidata(hObject);
handles.output = [];
guidata(hObject, handles);
uiresume(handles.figure1);



% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


