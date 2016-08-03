function varargout = prefilter_dlg(varargin)
% PREFILTER_DLG M-file for prefilter_dlg.fig
%      PREFILTER_DLG, by itself, creates a new PREFILTER_DLG or raises the existing
%      singleton*.
%
%      H = PREFILTER_DLG returns the handle to a new PREFILTER_DLG or the handle to
%      the existing singleton*.
%
%      PREFILTER_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PREFILTER_DLG.M with the given input arguments.
%
%      PREFILTER_DLG('Property','Value',...) creates a new PREFILTER_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before prefilter_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to prefilter_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Written by Hyatt Moore IV
% modified 10.29.2012 - pull parameter settings from gui changes and not
% from xml file updates.  This allows multiple uses of the same filter with
% different parameter settings to be applied.

% Edit the above text to modify the response to help prefilter_dlg

% Last Modified by GUIDE v2.5 25-Mar-2012 11:42:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @prefilter_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @prefilter_dlg_OutputFcn, ...
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


% --- Executes just before prefilter_dlg is made visible.
function prefilter_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to prefilter_dlg (see VARARGIN)

% Choose default command line output for prefilter_dlg
%
% varargin{1} = cell of channel label names which are used to determine
% which channel is going to be filtered and which channels are used as
% reference(s) as applicable
% varargin{2} = filterArrayStruct - an array of filters passed in which
% will be used to populate this gui so that the user does not have to
% repeate previous options.
% varargin{3} = filter path
% varargin{4} = filter filename for filter.inf data
% varargin{5} = instance of CLASS_channels_container

if(numel(varargin)>0)
    handles.user.channel_label = varargin{1};
    
    %make it a cell because of how I handle indexing for this variable.
    if(~iscell(handles.user.channel_label))
        handles.user.channel_label = {handles.user.channel_label};
    end
else
    handles.user.channel_label = {'No channels provided'};
end

if(numel(varargin)>1)
    filterArrayStruct = varargin{2};
else
    filterArrayStruct = [];
end

if(numel(varargin)>2)
    filter_inf_path = varargin{3}; 
else
    filter_inf_path = '+filter';
end

if(numel(varargin)>3)
    filter_inf_file = varargin{4};
else
    filter_inf_file = 'filter.inf';
end

if(numel(varargin)>4)
    handles.user.CHANNELS_CONTAINER = varargin{5};
else
    handles.user.CHANNELS_CONTAINER = [];
end

handles.output = [];
 
% keep track of event indices that were returned as 'none'.  I used to
% remove 'none' entries directly in this code and not return them to the
% user, but this caused difficulty when trying to remove the last filter
% (i.e. if a user wanted to turn filtering off for a channel); however I
% could not completely switch to this as the batch mode needs to know when
% a user not entered anything, and I would rather prevent having to write
% another for loop externally to find the none indices since it has already
% been done here.
handles.user.none_evt_indices = [];

%load the filter detection methods
handles.user.filterInf=CLASS_settings.loadParametersInf(filter_inf_path,filter_inf_file);
handles.user.filterInf.evt_label{end+1} = 'None';
handles.user.filterInf.mfile{end+1} = '';
handles.user.filterInf.num_reqd_indices(end+1) = 0;
handles.user.filterInf.batch_mode_label{end+1} = '';
handles.user.filterInf.param_gui{end+1} = '';
handles.user.filterInf.params{end+1} = [];
handles.user.filter_path = filter_inf_path;


% import the filter methods.
handles.user.filter_packageName = '';
if(exist(handles.user.filter_path,'dir'))
    [~,f,~] = fileparts(handles.user.filter_path);
    if(~isempty(f)&&f(1)=='+')
        handles.user.filter_packageName = strcat(f(2:end),'.');
        import(fullfile(handles.user.filter_path,strcat(handles.user.filter_packageName,'*')));
    end
end

numOptions =  numel(handles.user.filterInf.evt_label);

handles.user.none_evt_index = numOptions;

handles.user.new_row_y_delta = 2; %separation amount between rows
handles.user.num_rows = 1;  %start on the first row.
set(handles.push_remove_row,'enable','off'); %can't remove the initial filter..

nFilters = numel(filterArrayStruct)+1;
handles.user.paramCell = cell(nFilters,1);

if(nFilters>1)
    [handles.user.paramCell{1:nFilters-1}] = filterArrayStruct.params;
end

for k=1:nFilters
    cur_row = num2str(handles.user.num_rows);
    
    if(k==nFilters)
        evt_labl_index = handles.user.none_evt_index;
        channel_labl_index = 1;
        ref_channel_index = [1 1];
        index = 1;
    else
        index = find((strcmp(handles.user.filterInf.mfile,filterArrayStruct(k).m_file)&...
            numel(filterArrayStruct(k).ref_channel_index)==handles.user.filterInf.num_reqd_indices));
        evt_labl_index = index;
        channel_labl_index = filterArrayStruct(k).src_channel_index;
        ref_channel_index = filterArrayStruct(k).ref_channel_index;
        handles =push_add_row_Callback(handles.push_add_row, [], handles);
    end

    set(handles.(['menu_filter_',cur_row]),'string',handles.user.filterInf.evt_label,'value',evt_labl_index);
    set(handles.(['menu_src_channel_',cur_row]),'string',handles.user.channel_label,'value',channel_labl_index);
    
    updateFilterSelection(handles,cur_row); 
    
    params = handles.user.paramCell{k};
    if(~isempty(params))
        set(handles.(['push_settings_',cur_row]),'userdata',params);
    end
    
    %update the reference channels as applicable
    for r=1:handles.user.filterInf.num_reqd_indices(index)
        set(handles.(['menu_ref',num2str(r),'_',cur_row]),'value',ref_channel_index(r));
    end
end

set(hObject,'name','Filter Toolbox');

% store handles structure
guidata(hObject, handles);

% UIWAIT makes prefilter_dlg wait for user response (see UIRESUME)
uiwait(handles.fig1);

%% Update filter
function updateFilterSelection(handles,cur_row)
%update available reference channels and settings availability based on
% filter selection for that row

if(isnumeric(cur_row))
    cur_row = num2str(cur_row);
end

for k = 1:2
    set(handles.(['menu_ref',num2str(k),'_',cur_row]),'enable','on','string',handles.user.channel_label);
end

filter_index = get(handles.(['menu_filter_',cur_row]),'value');

for k = handles.user.filterInf.num_reqd_indices(filter_index)+1:2
    set(handles.(['menu_ref',num2str(k),'_',cur_row]),'enable','off','string',handles.user.channel_label);
end

param_gui = handles.user.filterInf.param_gui{filter_index};
if(strcmpi(param_gui,'none') || isempty(param_gui))
    set(handles.(['push_settings_',cur_row]),'enable','off','userdata',[]);
else
    
    % obtain the parameters for the selected filter method and assign to the 'userdata'
    % filed of the settings widget for the current row.  
    filterInf = handles.user.filterInf;
    pFile = fullfile(handles.user.filter_path,strcat(filterInf.mfile{filter_index},'.plist'));
    
    mFile = strcat(filterInf.mfile{filter_index},'.m');
    mFullFilename = fullfile(handles.user.filter_path,mFile);
    
    if(exist(pFile,'file'))
        params = plist.loadXMLPlist(pFile);
    elseif(exist(mFullFilename,'file'))
        % get rid of the '.m' we just added on earlier to actually evalute
        % the filter
        params = feval(strcat(handles.user.filter_packageName,mFile(1:end-2)));
        if(strcmpi(param_gui,'plist_editor_dlg'))
            plist.saveXMLPlist(pFile,params);
        end
    else
        params = [];
        fprintf('The filter (%s) could not be found!\n\t"%s" not found.\n',mFile,mFullFilename);
    end
    
%     if(exist(
%     params = getFilterParams();
%     params = feval(param_gui,filter_label,'+filter',curParams);
    set(handles.(['push_settings_',cur_row]),'enable','on','userdata',params);
end

%% --- Outputs from this function are returned to the command line.
function varargout = prefilter_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
if(nargout>1)
    varargout{2}= handles.user.none_evt_indices;
end
delete(hObject);


% --- Executes on button press in push_add_row.
function handles = push_add_row_Callback(hObject, eventdata, handles)
% hObject    handle to push_add_row (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% --- Executes on button press in push_add_entry.

handles.user.num_rows = handles.user.num_rows+1;
handles.user.paramCell{end+1} = {};

cur_row = handles.user.num_rows;
last_row_h = findobj(allchild(handles.pan_settings),'-regexp','tag',['.*_',num2str(handles.user.num_rows-1)]);
props = get(last_row_h);

config_pos = get(handles.pan_settings,'position');
config_pos(4) = config_pos(4)+handles.user.new_row_y_delta;
set(handles.pan_settings,'position',config_pos);

config_children = allchild(handles.pan_settings);

config_positions = get(config_children,'position');

config_positions = cell2mat(config_positions);

config_positions(:,2) = config_positions(:,2)+handles.user.new_row_y_delta;

for k=1:numel(config_children)
    if(all(config_positions(k,:)>0))
        set(config_children(k),'position',config_positions(k,:));
    end
end

fig_pos = get(handles.fig1,'position');
fig_pos(4) = fig_pos(4)+handles.user.new_row_y_delta;
fig_pos(2) = fig_pos(2)-handles.user.new_row_y_delta;
set(handles.fig1,'position',fig_pos);

props = rmfieldSafe(props,'Selected');
props = rmfieldSafe(props,'Extent');
props = rmfieldSafe(props,'Type');

pos = cell(numel(props),1);
[pos{:}] = props.Position;
props = rmfieldSafe(props,'Position');
props = rmfieldSafe(props,'BeingDeleted');
new_tag_suffix = num2str(handles.user.num_rows);
for k=1:numel(props)
    props(k).Position = pos{k};
    
    if(handles.user.num_rows>10)
        props(k).Tag = [props(k).Tag(1:end-2),num2str(new_tag_suffix)]; %update the tag name
    else
        props(k).Tag = [props(k).Tag(1:end-1),num2str(new_tag_suffix)]; %update the tag name
    end
    
    handles.(props(k).Tag) = uicontrol(props(k));  %bang out the new row
end

set(handles.push_remove_row,'enable','on');

set(handles.(['menu_filter_',num2str(cur_row)]),'value',handles.user.none_evt_index);
updateFilterSelection(handles,cur_row);

guidata(hObject,handles);

% --- Executes on button press in push_remove_row.
function push_remove_row_Callback(hObject, eventdata, handles)
% hObject    handle to push_remove_row (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%remove rows until only one remaining.  If only one remaining, and the user
%clicks '-' button again, it will then set the filter choice to 'none' and
%also disable the '-' button

if(handles.user.num_rows>1)
    removeLastRow(handles);
end

handles.user.num_rows = handles.user.num_rows-1;
handles.user.paramCell(end) = []; %remove this last one
if(handles.user.num_rows == 0)
    set(handles.menu_filter_1,'value',handles.user.none_evt_index)
    set(hObject,'enable','off');
    handles.user.num_rows = 1;
end;

guidata(hObject,handles);

% --- Executes on button press in push_accept.
function push_accept_Callback(hObject, eventdata, handles)
% hObject    handle to push_accept (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
outputStruct.src_channel_index = [];
outputStruct.src_channel_label = [];
outputStruct.m_file = [];
outputStruct.ref_channel_index = [];
outputStruct.ref_channel_label = {};
outputStruct.params = [];
handles.output = repmat(outputStruct,handles.user.num_rows,1);
none_evt_indices = false(handles.user.num_rows,1);
for cur_row = 1:handles.user.num_rows
    cur_row_str = num2str(cur_row);
    handles.output(cur_row).filter_path = handles.user.filter_path;
    handles.output(cur_row).src_channel_index = get(handles.(['menu_src_channel_',cur_row_str]),'value');
    handles.output(cur_row).src_channel_label = handles.user.channel_label{handles.output(cur_row).src_channel_index};
    filter_choice = get(handles.(['menu_filter_',cur_row_str]),'value');
    
    handles.output(cur_row).m_file = handles.user.filterInf.mfile{filter_choice};
    for k=1:handles.user.filterInf.num_reqd_indices(filter_choice)
        handles.output(cur_row).ref_channel_index(end+1) = get(handles.(['menu_ref',num2str(k),'_',cur_row_str]),'value');
        handles.output(cur_row).ref_channel_label{end+1} = handles.user.channel_label{handles.output(cur_row).ref_channel_index(k)};
    end
    
    % do not return parameters in case where no filter is selected ('none')
    if(filter_choice==handles.user.none_evt_index)
        none_evt_indices(cur_row) = true;
    else
        %check if there are parameters for this one...
        if(strcmpi(get(handles.(['push_settings_',cur_row_str]),'enable'),'on') && isempty(handles.user.filterInf.params{cur_row}))
            handles.output(cur_row).params = handles.user.paramCell{cur_row}; % often true when we come in with a value already
            if(isempty(handles.output(cur_row).params))
                try
                    handles.output(cur_row).params = CLASS_events.loadXMLparams(handles.output(cur_row).m_file); %the .m gets stripped and replaced with .pfile in the loadXMLparams function
                catch me
                    showME(me);
                    % just leave it empty
                end
            end
        else
            handles.output(cur_row).params = handles.user.filterInf.params{cur_row}; %empty
        end
    end
end

handles.user.none_evt_indices = none_evt_indices;
% handles.output = handles.output(~none_evt_indices);

guidata(hObject,handles);
uiresume(gcf);

% --- Executes on button press in push_cancel.
function push_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to push_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(gcf);


function removeLastRow(handles)

row_index = handles.user.num_rows;
row_h = findobj(allchild(handles.pan_settings),'-regexp','tag',['.*_',num2str(row_index)]);

config_pos = get(handles.pan_settings,'position');
config_pos(4) = config_pos(4)-handles.user.new_row_y_delta;
set(handles.pan_settings,'position',config_pos);

config_children = allchild(handles.pan_settings);

config_positions = get(config_children,'position');

config_positions = cell2mat(config_positions);
% config_positions = mat2cell(config_positions,ones(numel(config_children),1));

config_positions(:,2) = config_positions(:,2)-handles.user.new_row_y_delta;

for k=1:numel(config_children)
    if(all(config_positions(k,:)>0))
        set(config_children(k),'position',config_positions(k,:));
    end
end

fig_pos = get(handles.fig1,'position');
fig_pos(4) = fig_pos(4)-handles.user.new_row_y_delta;
fig_pos(2) = fig_pos(2)+handles.user.new_row_y_delta;
set(handles.fig1,'position',fig_pos);

delete(row_h);


% --- Executes on selection change in menu_filter_1.
function menu_filter_1_Callback(hObject, eventdata, handles)
% hObject    handle to menu_filter_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_filter_1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_filter_1
cur_row = get(hObject,'tag');
cur_row = regexp(cur_row,'.*_(\d+)','tokens');
updateFilterSelection(handles,cur_row{1}{1})

% --- Executes when user attempts to close fig1.
function fig1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to fig1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(gcf);

% --- Executes on button press in push_settings_1.
function push_settings_1_Callback(hObject, eventdata, handles)
% hObject    handle to push_settings_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cur_row = get(hObject,'tag');
cur_row = regexp(cur_row,'.*_(\d+)','tokens');

menu_tag = ['menu_filter_',char(cur_row{1})];
filter_index = get(handles.(menu_tag),'value');

param_gui = handles.user.filterInf.param_gui{filter_index};
filter_label = handles.user.filterInf.evt_label{filter_index};

% filter_mfile = handles.user.filterInf.mfile{filter_index};

cur_row = str2double(cur_row{1});

if(~isempty(param_gui) && ~strcmp(param_gui,'none'))
    
    curParams = get(hObject,'userdata');
    
    if(strcmpi(param_gui,'wavelet_dlg'))
        channel_index = get(handles.(sprintf('menu_src_channel_%u',cur_row)),'value');
        if(~isempty(handles.user.CHANNELS_CONTAINER))
            params = feval(param_gui,curParams,handles.user.CHANNELS_CONTAINER.getCurrentData(channel_index));
        else
            params = feval(param_gui,curParams);
        end
    else
        % params_gui (plist_editor_dlg) will take care of checking if
        % params file exists and will create it if not.
        params = feval(param_gui,filter_label,'+filter',curParams);
    end
    if(~isempty(params))
        handles.user.paramCell{cur_row} = params;
    end
    set(handles.(menu_tag),'userdata',filter_index);
end

guidata(hObject,handles);
