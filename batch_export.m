function varargout = batch_export(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @batch_export_OpeningFcn, ...
    'gui_OutputFcn',  @batch_export_OutputFcn, ...
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

end

% --- Executes just before batch_export is made visible.
function batch_export_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to batch_export (see VARARGIN)

global MARKING;
global GUI_TEMPLATE;

%if MARKING is not initialized, then call sev.m with 'batch' argument in
%order to initialize the MARKING global before returning here.
debugMode = true;
if(isempty(MARKING))
    sev('init_batch_export'); %runs the sev first, and then goes to the default batch export callback.
else
    
    %have to assign user data to the button that handles multiple channel
    %sourcing
    
    initializeSettings(hObject);
    initializeCallbacks(hObject)
    
    
    % have to implement this still.
    if(~debugMode)
        loadExportMethods();
        
        %still using a global here; not great...
        createGlobalTemplate(handles);
        
        
        set(handles.menu_export_method,'string',GUI_TEMPLATE.export.labels,'callback',...
            {@menu_event_callback,[handles.menu_event_channel1,handles.menu_event_channel2],handles.push_method_settings,handles.button_selectChannels});
        
        
        if(isfield(MARKING.SETTINGS.BATCH_PROCESS,'edf_folder'))
            if(~isdir(MARKING.SETTINGS.BATCH_PROCESS.edf_folder) || strcmp(MARKING.SETTINGS.BATCH_PROCESS.edf_folder,'.'))
                MARKING.SETTINGS.BATCH_PROCESS.edf_folder = pwd;
            end;
            set(handles.edit_edf_directory,'string',MARKING.SETTINGS.BATCH_PROCESS.edf_folder);
        else
            set(handles.edit_edf_directory,'string',pwd);
        end

    end
    edfPath = pwd;
    edfPathStruct = CLASS_batch.checkPathForEDFs(edfPath); %Internally, this calls getPlayList since no argument is given.
    
    
    
        % have to implement this still.
    if(~debugMode)
        handles.user.BATCH_PROCESS = MARKING.SETTINGS.BATCH_PROCESS;
    end
    
    % Choose default command line output for batch_export
    handles.output = hObject;
    
    % Update handles structure
    guidata(hObject, handles);
    
end
end

function initializeSettings(hObject)

    handles = guidata(hObject);

    % edf directory
    set(handles.push_edf_directory,'enable','on');  % start here.
    set([handles.edit_edf_directory;
        handles.text_edfs_to_process],'enable','off');
    
    
    
    % file selection
    set(handles.radio_processAll,'value',1);
    set([handles.radio_processAll;
        handles.radio_processList;
        handles.edit_selectPlayList],'enable','off');
    
    % channel selection
    set(handles.radio_channelsAll,'value',1);
    set([handles.radio_channelsAll;
        handles.radio_channelsSome;
        handles.button_selectChannels],'enable','off');
    
    maxSourceChannelsAllowed = 14;
    userdata.nReqdIndices = maxSourceChannelsAllowed;
    userdata.selectedIndices = 1:maxSourceChannelsAllowed;    
    set(handles.button_selectChannels,'userdata',userdata,'value',0);
   
    % export methods
    methods = handles.user.export_inf_filename
    set([handles.push_add_method;
        handles.push_method_settings],'enable','off');
    set(handles.menu_export_method,'string',export_methods);
    
    % Start
    set(handles.push_start,'enable','off');
    
end

function initializeCallbacks(hObject)

    handles = guidata(hObject);
    set(handles.push_edf_directory,'callback',{@push_edf_directory_Callback,guidata(hObject)});
    set(handles.edit_edf_directory,'callback',{@edit_edf_directory_Callback,guidata(hObject)});
	set(handles.edit_selectPlayList,'callback',{@edit_selectPlaylist_ButtonDownFcn,guidata(hObject)});
    set(handles.button_selectChannels,'callback',[]);
    set(handles.menu_export_method,'callback',[]);
    set(handles.push_start,'callback',[]);
    set(handles.push_add_method,'callback',{@push_add_event_Callback,guidata(hObject)});
    
    set(handles.edit_selectPlayList,'buttondownfcn',{@edit_selectPlayList_ButtonDownFcn,guidata(hObject)});

end


% --- Outputs from this function are returned to the command line.
function varargout = batch_export_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

end

% --- Executes on button press in push_edf_directory.
function push_edf_directory_Callback(hObject, eventdata, handles)
% hObject    handle to push_edf_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global MARKING;
    
    edfPath = get(handles.edit_edf_directory,'string');
    
    if(~exist(edfPath,'file'))
        edfPath = MARKING.SETTINGS.BATCH_PROCESS.edf_folder;
    end;
    
    pathname = uigetdir(edfPath,'Select the directory containing EDF files to process');
    
    if(isempty(pathname)||(isnumeric(pathname)&&pathname==0))
        pathname = edfPath;
    else
        MARKING.SETTINGS.BATCH_PROCESS.edf_folder = pathname; %update for the next time..
    end;
    
    set(handles.edit_edf_directory,'string',pathname);
    edfPathStruct = CLASS_batch.checkPathForEDFs(pathname);
    updateGUI(edfPathStruct);
end








% --- Executes during object creation, after setting all properties.
function edit_edf_directory_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_edf_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in push_start.
function push_start_Callback(hObject, eventdata, handles)
% hObject    handle to push_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
%This function can only be called when there a valid directory (one which
%contains EDF files) has been selected.
%This function grabs the entries from the GUI and puts them into the global
%variable BATCH_PROCESS which will be referenced during the batch
%processing.
end

% --- Executes on button press in push_add_method.
function push_add_method_Callback(hObject, eventdata, handles)
% hObject    handle to push_add_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addEventRow(handles);
end
% --- Executes on button press in push_add_psd.
function push_add_psd_Callback(hObject, eventdata, handles)
% hObject    handle to push_add_psd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addPSDRow(handles);
end
% --- Executes on button press in push_add_artifact.
function push_add_artifact_Callback(hObject, eventdata, handles)
% hObject    handle to push_add_artifact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addArtifactRow(handles);
end

function createGlobalTemplate(handles)
%uses the intial panel entries created with GUIDE to serve as templates for
%adding more entries later.
global GUI_TEMPLATE;


push_parameter_settings = get(handles.push_method_settings);

export_method = get(handles.menu_export_method);



%I should really consider implementing a for loop at this point....

%the added Position and removal is to bypass a warning that pops because
%Matalb does not like the units field to follow the position field when
%initializing a uicontrol- notice that the copy is a lower case and thus
%different than the upper-cased Position name
push_parameter_settings = rmfield(push_parameter_settings,'Type');
push_parameter_settings = rmfield(push_parameter_settings,'Extent');
push_parameter_settings = rmfield(push_parameter_settings,'BeingDeleted');
push_parameter_settings.position = push_parameter_settings.Position;
push_parameter_settings = rmfield(push_parameter_settings,'Position');

export_method = rmfield(export_method,'Type');
export_method = rmfield(export_method,'Extent');
export_method = rmfield(export_method,'BeingDeleted');
export_method.position = export_method.Position;
export_method = rmfield(export_method,'Position');

GUI_TEMPLATE.push_parameter_settings = push_parameter_settings;

add_button_pos = get(handles.push_add_method,'position');

%I liked the distance between these two on the GUIDE display of the figure
%and would like to keep the same spacing for additional rows that are added
GUI_TEMPLATE.row_separation = add_button_pos(2)-export_method.position(2);
end

function loadExportMethods()
%load up any available export methods found in the export_path
%(initially this was labeled '+export' from the working path

global MARKING;
global GUI_TEMPLATE;
    

if(isfield(MARKING.SETTINGS.VIEW,'export_path'))
    export_inf = fullfile(MARKING.SETTINGS.VIEW.export_path,'export.inf');
else
    export_inf = fullfile('+export','export.inf');
end

%this part is initialized for the first choice, which is 'none' - no
%artifact or event selected...
export_label = 'none';
mfile = 'Error';
num_reqd_indices = 0;
param_gui = 'none';
batch_mode_label = '_';

if(exist(export_inf,'file'))
    [loaded_mfile, loaded_export_label, loaded_num_reqd_indices, loaded_param_gui, loaded_batch_mode_label] = textread(export_inf,'%s%s%n%s%s','commentstyle','shell');

    export_label = [{export_label};loaded_export_label];
    mfile = [{mfile};loaded_mfile];
    num_reqd_indices = [num_reqd_indices;loaded_num_reqd_indices];
    param_gui = [{param_gui};loaded_param_gui];
    batch_mode_label = [batch_mode_label; loaded_batch_mode_label];
end;

GUI_TEMPLATE.export.labels = export_label;
GUI_TEMPLATE.export.mfile = mfile;
GUI_TEMPLATE.export.reqd_indices = num_reqd_indices;
GUI_TEMPLATE.export.param_gui = param_gui;
GUI_TEMPLATE.export.batch_mode_label = batch_mode_label;
GUI_TEMPLATE.export_method.String = export_label;  %need this here so that newly created rows have these export options available.
end
%%%%%%%%%%%%%%%%%%%%%%%%%%

function settings_callback(hObject,~,~)
global GUI_TEMPLATE;
global MARKING;

% choice = userdata.choice;

% userdata = get(hObject,'userdata');
% userdata.choice = choice;
% userdata.pBatchStruct = [];
% userdata.rocStruct = [];
userdata = get(hObject,'userdata');
if(~isempty(userdata) && isfield(userdata,'pBatchStruct'))
    paramStruct = userdata.pBatchStruct;
end
if(~isempty(userdata) && isfield(userdata,'rocStruct'))
    rocStruct = userdata.rocStruct;
end

exportPath = fullfile(MARKING.SETTINGS.rootpathname,MARKING.SETTINGS.VIEW.export_path);
% exportFilename = MARKING.SETTINGS.VIEW.export_inf_file;
rocPath = fullfile(MARKING.SETTINGS.BATCH_PROCESS.output_path.parent,MARKING.SETTINGS.BATCH_PROCESS.output_path.roc);
exportLabels = GUI_TEMPLATE.export.labels{userdata.choice};
[pBatchStruct,rocStruct] = plist_batch_editor_dlg(exportLabels,exportPath,rocPath,paramStruct,rocStruct);
if(~isempty(pBatchStruct))
    userdata.pBatchStruct =pBatchStruct;
    userdata.rocStruct = rocStruct;
    set(hObject,'userdata',userdata);
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%

function menu_event_callback(hObject,event_data,h_pop_channels,h_push_settings,h_buttonSelectSource)
global GUI_TEMPLATE;
choice = get(hObject,'value');

settings_gui = GUI_TEMPLATE.export.param_gui{choice};

userdata.choice = choice;
userdata.pBatchStruct = [];
userdata.rocStruct = [];
set(h_push_settings,'userdata',userdata);

if(strcmp(settings_gui,'none'))
    set(h_push_settings,'enable','off','callback',[]);
else
    %want to avoid calling plist_editor, and rather call plist_batch_editor
    %here so that the appropriate settings can be made.
    if(strcmp(settings_gui,'plist_editor_dlg'))
        set(h_push_settings,'userdata',userdata,'enable','on','callback',{@settings_callback,guidata(hObject)});
    else
        set(h_push_settings,'enable','on','callback',settings_gui);
    end
end

%turn off all channels first.
set(h_pop_channels,'visible','off');

nReqdIndices = GUI_TEMPLATE.export.reqd_indices(choice);
if(nReqdIndices<=2)
    set(h_buttonSelectSource,'visible','off','enable','off','value',0);
    for k=1:nReqdIndices
        set(h_pop_channels(k),'visible','on','enable','on','string',GUI_TEMPLATE.EDF.labels);
    end
else
    userdata.nReqdIndices = nReqdIndices;
    if(~isfield(userdata,'selectedIndices'))
        userdata.selectedIndices = 1:nReqdIndices;
    end
    set(h_buttonSelectSource,'visible','on','enable','on','value',1,'userdata',userdata,'callback', @buttonSelectSources_Callback);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press of buttonSelectSource
function buttonSelectSources_Callback(hObject, eventdata)
global GUI_TEMPLATE;
userdata = get(hObject,'userdata');

selectedIndices = channelSelector(userdata.nReqdIndices,GUI_TEMPLATE.EDF.labels,userdata.selectedIndices);
if(~isempty(selectedIndices))
    set(hObject,'userdata',userdata);
    guidata(hObject);  %is this necessary?
end

end



% returns whether the batch mode is ready for running.
function isReady = canRun(handles)
    isReady = strcmpi(get(handles.push_start,'enable'),'on');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global MARKING;
% in order to save settings between use.
try
    MARKING.SETTINGS.BATCH_PROCESS = handles.user.BATCH_PROCESS; %need to return this to the global for now 

    if(ishandle(MARKING.figurehandle.sev))
        MARKING.initializeSEV(); %this currently deletes any other MATLAB figures that are up.
    else
        delete(hObject);
    end
catch ME
    try
        delete(hObject);
    catch me2
        showME(me2);
    end
end
    
end


% --- Executes during object creation, after setting all properties.
function edit_selectPlayList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_selectPlayList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes when selected object is changed in bg_panel_playList.
function bg_panel_playList_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in bg_panel_playList 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if(eventdata.NewValue==handles.radio_processList)
    playList = getPlaylist(handles);
    if(isempty(playList))
        playList = getPlaylist(handles,'-gui');
    end
    handles.user.playList = playList;
    checkPathForEDFs(handles,handles.user.playList);
    guidata(hObject,handles);
    
end
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over edit_selectPlayList.
function edit_selectPlayList_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to edit_selectPlayList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

warndlg('This has been implemented, but not yet tested');
            
                
% if(strcmpi('on',get(handles.radio_processList,'enable')) && get(handles.radio_processList,'value'))
%     filenameOfPlayList = get(handles.edit_selectPlayList,'string');
% else
%     filenameOfPlayList = [];  %just in case this is called unwantedly
% end


[handles.user.playList, filenameOfPlayList] = CLASS_batch.getPlaylist(handles,'-gui');

%update the gui
if(isempty(handles.user.playList))
    set(handles.radio_processAll,'value',1);
    set(handles.edit_selectPlayList,'string','<click to select play list>');
else
    set(handles.radio_processList,'value',1);
    set(handles.edit_selectPlayList,'string',filenameOfPlayList);
end

CLASS_batch.checkPathForEDFs(getCurrentEDFPathname(hObject),handles.user.playList);

guidata(hObject,handles);

end

function addEventRow(handles)
%adds an event selection/export row to the specified panel
%make room for the event row
    resizeForAddedRow(handles,handles.panel_exportMethods);
end



function resizeForAddedRow(handles,resized_panel_h)
global GUI_TEMPLATE;

%move all of the children up to account for the change in size and location
%of the panel being resized.
pan_children = allchild(resized_panel_h);
children_pos = cell2mat(get(pan_children,'position'));
children_pos(:,2)=children_pos(:,2)+GUI_TEMPLATE.row_separation;
for k =1:numel(pan_children), set(pan_children(k),'position',children_pos(k,:));end;

resized_panel_pos = get(resized_panel_h,'position');

h = [handles.panel_directory
    handles.panel_synth_CHANNEL
    handles.panel_exportMethods
    handles.panel_artifact
    handles.panel_psd
    handles.push_start
    handles.figure1];

for k=1:numel(h)
    pos = get(h(k),'position');
    
    if(h(k) == handles.figure1)
        pos(2) = pos(2)-GUI_TEMPLATE.row_separation;
        pos(4) = pos(4)+GUI_TEMPLATE.row_separation;
    elseif(h(k)==resized_panel_h)
        pos(4) = pos(4)+GUI_TEMPLATE.row_separation;
    elseif(pos(2)>resized_panel_pos(2))
        pos(2) = pos(2)+GUI_TEMPLATE.row_separation;
    end;
    set(h(k),'position',pos);
end


%add the additional controls depending on the panel being adjusted.
if(resized_panel_h==handles.panel_psd)
    hc1 = uicontrol(GUI_TEMPLATE.channel1,'parent',resized_panel_h,'string',GUI_TEMPLATE.EDF.labels);
    h_params = uicontrol(GUI_TEMPLATE.push_parameter_settings,'parent',resized_panel_h,'userdata',handles.user.PSD);
    userdata.channel_h = hc1;
    userdata.settings_h = h_params;
    uicontrol(GUI_TEMPLATE.spectrum,'parent',resized_panel_h,'enable','on',...
        'callback',{@pop_spectral_method_Callback,hc1,h_params},'userdata',userdata);
elseif(resized_panel_h==handles.panel_synth_CHANNEL)
    
    %add a source channel - channel1
    hc1 = uicontrol(GUI_TEMPLATE.channel1,'parent',resized_panel_h,'string',GUI_TEMPLATE.EDF.labels,'enable','on');
   
    %add the edit output channel name
    he1 = uicontrol(GUI_TEMPLATE.edit_synth_CHANNEL,'parent',resized_panel_h);
    
    %add the configuration/settings button
    h_params = uicontrol(GUI_TEMPLATE.push_CHANNEL_configuration,'parent',resized_panel_h,'enable','on',...
        'callback',{@synthesize_CHANNEL_configuration_callback,hc1,he1});
else
    hc1=uicontrol(GUI_TEMPLATE.channel1,'parent',resized_panel_h);
    hc2=uicontrol(GUI_TEMPLATE.channel2,'parent',resized_panel_h);
    buttonEventSelectSources = uicontrol(GUI_TEMPLATE.buttonEventSelectSources,'parent',resized_panel_h);
    
    h_check_save_img = uicontrol(GUI_TEMPLATE.check_save_image,'parent',resized_panel_h);
    h_params=uicontrol(GUI_TEMPLATE.push_parameter_settings,'parent',resized_panel_h);
    uicontrol(GUI_TEMPLATE.export_method,'parent',resized_panel_h,'callback',{@menu_event_callback,[hc1,hc2],h_params,buttonEventSelectSources});
end;
end
