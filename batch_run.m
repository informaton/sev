function varargout = batch_run(varargin)
%batch_run(varargin)
%batch mode portion of the Stanford EDF Viewer
%Written by Hyatt Moore IV
%modified September 18, 2012 
%   added channel_config component to event_settings struct to help audit
%   synthetic channels used for events.  These are inserted into database
%   when applicable now due to changes in CLASS_events_container.
%last edit: 18 July, 2012

% Edit the above text to modify the response to help batch_run

% Last Modified by GUIDE v2.5 08-Jan-2013 09:47:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @batch_run_OpeningFcn, ...
                   'gui_OutputFcn',  @batch_run_OutputFcn, ...
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


% --- Executes just before batch_run is made visible.
function batch_run_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to batch_run (see VARARGIN)

global MARKING;
global GUI_TEMPLATE;

%if MARKING is not initialized, then call sev.m with 'batch' argument in
%order to initialize the MARKING global before returning here.
if(isempty(MARKING))
    sev('batch'); %runs the sev first, and then goes to the default batch run...?
else
    
    %still using a global here; not great...
    createGlobalTemplate(handles);
    
    loadDetectionMethods();
    
    
    set(handles.push_synth_CHANNEL_settings,...
        'callback',{@synthesize_CHANNEL_configuration_callback,...
        handles.menu_synth_CHANNEL_channel1,handles.edit_synth_CHANNEL_name});
    
    set(handles.menu_event_method,'string',GUI_TEMPLATE.detection.labels,'callback',...
        {@menu_event_callback,[handles.menu_event_channel1,handles.menu_event_channel2],handles.push_event_settings});
    
    userdata.channel_h = handles.menu_psd_channel;
    userdata.settings_h = handles.push_psd_settings;
    
    set(handles.pop_spectral_method,'userdata',userdata,'callback',{@pop_spectral_method_Callback,handles.menu_psd_channel,handles.push_psd_settings},...
        'enable','off','string',GUI_TEMPLATE.spectrum_labels);
    
    set(handles.menu_artifact_method,'string',GUI_TEMPLATE.detection.labels,'callback',...
        {@menu_event_callback,[handles.menu_artifact_channel1,handles.menu_artifact_channel2],handles.push_artifact_settings});
    
    set(handles.push_psd_settings,'enable','off','userdata',MARKING.SETTINGS.PSD);
    
    
    if(isfield(MARKING.SETTINGS.BATCH_PROCESS,'edf_folder'))
        if(~isdir(MARKING.SETTINGS.BATCH_PROCESS.edf_folder) || strcmp(MARKING.SETTINGS.BATCH_PROCESS.edf_folder,'.'))
            MARKING.SETTINGS.BATCH_PROCESS.edf_folder = pwd;
        end;
        set(handles.edit_edf_directory,'string',MARKING.SETTINGS.BATCH_PROCESS.edf_folder);
    else
        set(handles.edit_edf_directory,'string',pwd);
    end
    
    checkPathForEDFs(handles);
    
    
    set([handles.menu_artifact_channel1
        handles.menu_event_channel1],'enable','off','string','Channel 1');
    set([handles.menu_artifact_channel2
        handles.menu_event_channel2],'enable','off','string','Channel 2');
    set([handles.push_event_settings
        handles.push_artifact_settings],'enable','off');
    handles.user.BATCH_PROCESS = MARKING.SETTINGS.BATCH_PROCESS;
    handles.user.PSD = MARKING.SETTINGS.PSD;
    handles.user.PSD = MARKING.SETTINGS.PSD;
    update_view(handles);
    
    % Choose default command line output for batch_run
    handles.output = hObject;
    
    % Update handles structure
    guidata(hObject, handles);
    
end


function addCHANNELRow(handles)
resizeForAddedRow(handles,handles.panel_synth_CHANNEL);

function addEventRow(handles)
%adds an event selection/detection row to the specified panel
%make room for the event row
resizeForAddedRow(handles,handles.panel_events);


function addArtifactRow(handles)
resizeForAddedRow(handles,handles.panel_artifact);


function addPSDRow(handles)
resizeForAddedRow(handles,handles.panel_psd);

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
    handles.panel_events
    handles.panel_artifact
    handles.panel_psd
    handles.push_run
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
    h_check_save_img = uicontrol(GUI_TEMPLATE.check_save_image,'parent',resized_panel_h);
    h_params=uicontrol(GUI_TEMPLATE.push_parameter_settings,'parent',resized_panel_h);
    uicontrol(GUI_TEMPLATE.evt_method,'parent',resized_panel_h,'callback',{@menu_event_callback,[hc1,hc2],h_params});
end;


% --- Outputs from this function are returned to the command line.
function varargout = batch_run_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in push_directory.
function push_directory_Callback(hObject, eventdata, handles)
% hObject    handle to push_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global MARKING;
path = get(handles.edit_edf_directory,'string');
if(~exist(path,'file'))
    path = MARKING.SETTINGS.BATCH_PROCESS.edf_folder;
end;
pathname = uigetdir(path,'Select the directory containing EDF files to process');

if(isempty(pathname)||(isnumeric(pathname)&&pathname==0))
    pathname = path;
else
    MARKING.SETTINGS.BATCH_PROCESS.edf_folder = pathname; %update for the next time..
end;

set(handles.edit_edf_directory,'string',pathname);
checkPathForEDFs(handles);


function checkPathForEDFs(handles)
%looks in the path for EDFs
global GUI_TEMPLATE;

path = get(handles.edit_edf_directory,'string');
if(~exist(path,'file'))
    EDF_message = 'Directory does not exist. ';
    num_edfs = 0;
else
    %pc's do not have a problem with case; unfortunately the other side
    %does
    if(ispc)
        edf_file_list = dir(fullfile(path,'*.EDF'));
    else
        edf_file_list = [dir(fullfile(path, '*.EDF'));dir(fullfile(path, '*.edf'))]; %dir(fullfile(path, '*.EDF'))];
    end
    num_edfs = numel(edf_file_list);
    bytes_cell = cell(num_edfs,1);
    [bytes_cell{:}]=edf_file_list.bytes;
    total_bytes = sum(cell2mat(bytes_cell))/1E6;
    EDF_message = [num2str(num_edfs),' EDF files (',num2str(total_bytes,'%0.2f'),' MB) found in the current directory. '];
end;

if(num_edfs==0)
    EDF_message = [EDF_message, 'Please choose a different directory'];
    set(handles.push_run,'enable','off');
    EDF_labels = 'No Channels Available';
    set(get(handles.panel_synth_CHANNEL,'children'),'enable','off');
    set(get(handles.panel_events,'children'),'enable','off');
    set(get(handles.panel_psd,'children'),'enable','off');
    set(get(handles.panel_artifact,'children'),'enable','off');
else
    set(get(handles.panel_synth_CHANNEL,'children'),'enable','on');
    set(handles.edit_synth_CHANNEL_name,'enable','off');
    set(handles.push_run,'enable','on');
    set(get(handles.panel_events,'children'),'enable','on');
%     set(get(handles.panel_psd,'children'),'enable','on');
    set(handles.pop_spectral_method,'enable','on');
    set(handles.push_add_psd,'enable','on');
    set(get(handles.panel_artifact,'children'),'enable','on');
        
    first_edf_filename = edf_file_list(1).name;
    HDR = loadEDF(fullfile(path,first_edf_filename));
    EDF_labels = HDR.label;
end;

GUI_TEMPLATE.EDF.labels = EDF_labels;

set(handles.text_edfs_to_process,'string',EDF_message);

%adjust all popupmenu selection data/strings for changed EDF labels
set(...
    findobj(handles.figure1,'-regexp','tag','.*channel.*'),...
    'string',EDF_labels);

function edit_edf_directory_Callback(hObject, eventdata, handles)
% hObject    handle to edit_edf_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkPathForEDFs(handles);


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


% --- Executes on button press in push_run.
function push_run_Callback(hObject, eventdata, handles)
% hObject    handle to push_run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
%This function can only be called when there a valid directory (one which
%contains EDF files) has been selected.
%This function grabs the entries from the GUI and puts them into the global
%variable BATCH_PROCESS which will be referenced during the batch
%processing.


global GUI_TEMPLATE;
global MARKING;




BATCH_PROCESS = handles.user.BATCH_PROCESS;

% BATCH_PROCESS.output_files.MUSIC_filename = 'MUSIC'; %already set in the
% _sev.parameters.txt
EDF_labels = GUI_TEMPLATE.EDF.labels;
detection_inf = GUI_TEMPLATE.detection;

%% grab the synthesize channel configurations
%flip handles up and down to put in more correct order as seen by the user from top to bottom
synth_channel_settings_h = flipud(findobj(handles.panel_synth_CHANNEL,'-regexp','tag','push_synth_CHANNEL_settings'));
synth_channel_names_h = flipud(findobj(handles.panel_synth_CHANNEL,'-regexp','tag','edit_synth_CHANNEL_name'));

synth_channel_structs = get(synth_channel_settings_h,'userdata');
synth_channel_names = get(synth_channel_names_h,'string');

if(~iscell(synth_channel_names))
    synth_channel_names = {synth_channel_names};
    synth_channel_structs = {synth_channel_structs};
end
synth_indices = false(numel(synth_channel_structs),1);

for k=1:numel(synth_indices)
    if(~isempty(synth_channel_names{k})&&~isempty(synth_channel_structs{k}))
        synth_indices(k)= true;
        
        %for the case where the synthetic channel has multiple
        %configurations for it (e.g. adaptive noise cancel followed by
        %wavelet denoising
        for p=1:numel(synth_channel_structs{k})
            if(isempty(synth_channel_structs{k}(p).params))
                pfile = fullfile(MARKING.SETTINGS.rootpathname,MARKING.SETTINGS.VIEW.filter_path,strcat(synth_channel_structs{k}(p).m_file,'.plist'));
                matfile = fullfile(MARKING.SETTINGS.rootpathname,MARKING.SETTINGS.VIEW.filter_path,strcat(synth_channel_structs{k}(p).m_file,'.mat'));
                if(exist(pfile,'file'))
                    try
                        synth_channel_structs{k}(p).params = plist.loadXMLPlist(pfile);
                    catch me
                        fprintf(1,'Could not load parameters from %s directly.\n',pfile);
                        showME(me);
                    end
                elseif(exist(matfile,'file'))
                    try
                        matfileStruct = load(matfile);
                        synth_channel_structs{k}(p).params = matfileStruct.params;
                    catch me
                        fprintf(1,'Could not load parameters from %s directly.\n',matfile);
                        showME(me);
                    end
                end
            end
        end
    end
end

synth_channel_structs = synth_channel_structs(synth_indices);
synth_channel_names = synth_channel_names(synth_indices);

BATCH_PROCESS.synth_CHANNEL.names = synth_channel_names;
BATCH_PROCESS.synth_CHANNEL.structs = synth_channel_structs;

%this is for the source channels found in the .EDF which need to be loaded
%in order to subsequently synthesize the channels in BATCH_PROCESS.synth_CHANNEL
synth_channel_settings_lite = cell(numel(synth_channel_names),1);

for k = 1:numel(synth_channel_structs)
    labels = {synth_channel_structs{k}.src_channel_label}; %keep it as a cell for loading later in batch.load_file subfunction getChannelIndices
    for j=1:numel(synth_channel_structs{k})
        labels = [labels, synth_channel_structs{k}(j).ref_channel_label];
    end
    synth_channel_settings_lite{k}.channel_labels = labels;
end

BATCH_PROCESS.synth_CHANNEL.settings_lite = synth_channel_settings_lite; %necessary for loading the channels with batch.load_file

%% grab the PSD parameters
psd_spectral_methods_h = findobj(handles.panel_psd,'-regexp','tag','pop_spectral_method');

selected_PSD_channels = [];
psd_channel_settings = {};
selected_MUSIC_channels = [];
MUSIC_channel_settings = {};
selected_coherence_channels = [];
coherence_channel_settings = {};

for k=1:numel(psd_spectral_methods_h)
    method = GUI_TEMPLATE.spectrum_labels{get(psd_spectral_methods_h(k),'value')}; %labels defined in opening function at {'None','PSD','MUSIC'}

    userdata = get(psd_spectral_methods_h(k),'userdata');
    switch(lower(method))
        case 'none'
            
        case 'psd'
            selected_PSD_channels(end+1) = get(userdata.channel_h,'value');
            psd_channel_settings{end+1} = get(userdata.settings_h,'userdata');
        case 'music'
            selected_MUSIC_channels(end+1) = get(userdata.channel_h,'value');
            MUSIC_channel_settings{end+1} = get(userdata.settings_h,'userdata');
        case 'coherence'
            selected_coherence_channels(end+1) = get(userdata.channel_h,'value');
            coherence_channel_settings{end+1} = get(userdata.settings_h,'userdata');
        otherwise
            disp(['unhandled selection ',lower(method)]);
    end
end     

%PSD
num_selected_PSD_channels = numel(selected_PSD_channels);
PSD_settings = cell(num_selected_PSD_channels,1);

for k = 1:num_selected_PSD_channels
    PSDstruct = psd_channel_settings{k};
    PSDstruct.channel_labels = EDF_labels(selected_PSD_channels(k));
 
    PSD_settings{k} = PSDstruct;
end

BATCH_PROCESS.PSD_settings = PSD_settings;

%MUSIC

num_selected_MUSIC_channels = numel(selected_MUSIC_channels);
MUSIC_settings = cell(num_selected_MUSIC_channels,1);

for k = 1:num_selected_MUSIC_channels
    MUSICstruct = MUSIC_channel_settings{k};
    MUSICstruct.channel_labels = EDF_labels(selected_MUSIC_channels(k));
 
    MUSIC_settings{k} = MUSICstruct;
end

BATCH_PROCESS.MUSIC_settings = MUSIC_settings;

BATCH_PROCESS.standard_epoch_sec = MARKING.SETTINGS.VIEW.standard_epoch_sec;
BATCH_PROCESS.base_samplerate = MARKING.SETTINGS.VIEW.samplerate;

%The following snippet was an alternative, but I found it easier to keep
%the same cell of structures format as the events and artifact settings
%below, when dealing with processing functions such as batch.load_file and
%such;
% BATCH_PROCESS.PSD_settings.channel_labels= EDF_labels(psd_menu_values);

%grab the event detection paramaters
event_method_values = get(flipud(findobj(handles.panel_events,'-regexp','tag','method')),'value');
event_channel1_values = get(flipud(findobj(handles.panel_events,'-regexp','tag','channel1')),'value');
event_channel2_values = get(flipud(findobj(handles.panel_events,'-regexp','tag','channel2')),'value');

if(iscell(event_method_values))
    event_method_values = cell2mat(event_method_values);
    event_channel1_values = cell2mat(event_channel1_values);
    event_channel2_values = cell2mat(event_channel2_values);
end;

event_settings_handles = flipud(findobj(handles.panel_events,'-regexp','tag','settings'));
if(iscell(event_settings_handles))
    event_settings_handles = cell2mat(event_settings_handles);
end

event_save_image_choices = get(flipud(findobj(handles.panel_events,'-regexp','tag','images')),'value');
if(iscell(event_save_image_choices))
    event_save_image_choices = cell2mat(event_save_image_choices);
end

selected_events = event_method_values>1;
event_method_values = event_method_values(selected_events);
event_settings_handles = event_settings_handles(selected_events);
event_channel_values = [event_channel1_values(selected_events),event_channel2_values(selected_events)];
event_save_image_choices = event_save_image_choices(selected_events);

num_selected_events = sum(selected_events);
event_settings = cell(num_selected_events,1);

for k = 1:num_selected_events
    selected_method = event_method_values(k);
    num_reqd_channels = detection_inf.reqd_indices(selected_method);
    eventStruct.numConfigurations = 1;
    eventStruct.save2img = event_save_image_choices(k);
    eventStruct.channel_labels = EDF_labels(event_channel_values(k,1:num_reqd_channels));
    
    eventStruct.channel_configs = cell(size(eventStruct.channel_labels));
    
    %check to see if we are using a synthesized channel so we can audit it
    if(~isempty(BATCH_PROCESS.synth_CHANNEL.names))
        for ch=1:numel(eventStruct.channel_labels)
           eventStruct.channel_configs{ch}  = BATCH_PROCESS.synth_CHANNEL.structs(strcmp(eventStruct.channel_labels{ch},BATCH_PROCESS.synth_CHANNEL.names));  %insert the corresponding synthetic channel where applicable
            channel_config = BATCH_PROCESS.synth_CHANNEL.structs(strcmp(eventStruct.channel_labels{ch},BATCH_PROCESS.synth_CHANNEL.names));  %insert the corresponding synthetic channel where applicable
%            if(~isempty(channel_config))
%                 channel_config = channel_config{1};
%                 channel_config.channel_label = eventStruct.channel_labels{ch};
%                eventStruct.channel_configs{ch} = channel_config;
%            end
        end
    end
    
    eventStruct.method_label = detection_inf.labels{selected_method};
    eventStruct.method_function = detection_inf.mfile{selected_method};
    eventStruct.batch_mode_label = char(detection_inf.batch_mode_label{selected_method});
    settings_userdata = get(event_settings_handles(k),'userdata');
    eventStruct.pBatchStruct = settings_userdata.pBatchStruct;
    eventStruct.rocStruct = settings_userdata.rocStruct;
    params = [];
    
    %may not work on windows platform....
    %if there is a change to the settings in the batch mode, then make sure
    %that the change occurs here as well
    if(~isempty(eventStruct.pBatchStruct))
        for p=1:numel(eventStruct.pBatchStruct)
           params.(eventStruct.pBatchStruct{p}.key) =  eventStruct.pBatchStruct{p}.start;
        end
    else
        pfile = ['+detection/',eventStruct.method_function,'.plist'];
        if(exist(pfile,'file'))
            params =plist.loadXMLPlist(pfile);
        end
    end
    
    eventStruct.detectorID = [];
    eventStruct.params = params;
    if(BATCH_PROCESS.database.auto_config==0 && BATCH_PROCESS.database.config_start>=0)
        eventStruct.configID = BATCH_PROCESS.database.config_start;
    else
        eventStruct.configID = 0; %0 represents autoconfiguration required
    end
    event_settings{k} = eventStruct;
end

BATCH_PROCESS.event_settings = event_settings;

%grab the artifact detection paramaters
artifact_method_values = get(flipud(findobj(handles.panel_artifact,'-regexp','tag','method')),'value');
artifact_channel1_values = get(flipud(findobj(handles.panel_artifact,'-regexp','tag','channel1')),'value');
artifact_channel2_values = get(flipud(findobj(handles.panel_artifact,'-regexp','tag','channel2')),'value');

if(iscell(artifact_method_values))
    artifact_method_values = cell2mat(artifact_method_values);
    artifact_channel1_values = cell2mat(artifact_channel1_values);
    artifact_channel2_values = cell2mat(artifact_channel2_values);
end;

artifact_settings_handles = flipud(findobj(handles.panel_artifact,'-regexp','tag','settings'));
if(iscell(artifact_settings_handles))
    artifact_settings_handles = cell2mat(artifact_settings_handles);
end

artifact_save_image_choices = get(flipud(findobj(handles.panel_artifact,'-regexp','tag','images')),'value');
if(iscell(artifact_save_image_choices))
    artifact_save_image_choices = cell2mat(artifact_save_image_choices);
end

selected_artifacts = artifact_method_values>1;
artifact_save_image_choices = artifact_save_image_choices(selected_artifacts);
artifact_settings_handles = artifact_settings_handles(selected_artifacts);
artifact_method_values = artifact_method_values(selected_artifacts);
artifact_channel_values = [artifact_channel1_values(selected_artifacts),artifact_channel2_values(selected_artifacts)];

num_selected_artifacts = sum(selected_artifacts);
artifact_settings = cell(num_selected_artifacts,1);

for k = 1:num_selected_artifacts
    selected_method = artifact_method_values(k);
    num_reqd_channels = detection_inf.reqd_indices(selected_method);

    artifactStruct.save2img = artifact_save_image_choices(k);
    artifactStruct.channel_labels = EDF_labels(artifact_channel_values(k,1:num_reqd_channels));
    artifactStruct.method_label = detection_inf.labels{selected_method};
    artifactStruct.method_function = detection_inf.mfile{selected_method};
    artifactStruct.batch_mode_label = char(detection_inf.batch_mode_label{selected_method});
    
    settings_userdata = get(artifact_settings_handles(k),'userdata');
    pBatchStruct = settings_userdata.pBatchStruct;

    params = [];
    %for artifacts, only apply the first step in each case, that is the
    %start value given
    if(~isempty(pBatchStruct))
        for key_ind=1:numel(pBatchStruct);
            params.(pBatchStruct{key_ind}.key)=pBatchStruct{key_ind}.start;
        end
    end

    %left overs fromn April 9, 2012 - which may not be necessary anymore...
%         params = [];
%        %may not work on windows platform....
%         pfile = ['+detection/',artifactStruct.method_function,'.plist'];
%         if(exist(pfile,'file'))
%             params =plist.loadXMLPlist(pfile);
%         end
%     else
%         params = [];

    artifactStruct.params = params;
    artifact_settings{k} = artifactStruct;
end

BATCH_PROCESS.artifact_settings = artifact_settings;

pathname = get(handles.edit_edf_directory,'string');

batch_process(pathname,BATCH_PROCESS);
% warndlg({'you are starting the batch mode with the following channels',BATCH_PROCESS.PSD_settings});

%goal two - run the batch mode with knowledge of the PSD channel only...

% --- Executes on button press in push_add_event.
function push_add_event_Callback(hObject, eventdata, handles)
% hObject    handle to push_add_event (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addEventRow(handles);

% --- Executes on button press in push_add_psd.
function push_add_psd_Callback(hObject, eventdata, handles)
% hObject    handle to push_add_psd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addPSDRow(handles);

% --- Executes on button press in push_add_artifact.
function push_add_artifact_Callback(hObject, eventdata, handles)
% hObject    handle to push_add_artifact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addArtifactRow(handles);

function createGlobalTemplate(handles)
%uses the intial panel entries created with GUIDE to serve as templates for
%adding more entries later.
global GUI_TEMPLATE;

edit_synth_CHANNEL = get(handles.edit_synth_CHANNEL_name);
push_CHANNEL_configuration = get(handles.push_synth_CHANNEL_settings);

channel1 = get(handles.menu_event_channel1);
channel2 = get(handles.menu_event_channel2);
check_save_image = get(handles.check_event_export_images);
push_parameter_settings = get(handles.push_event_settings);

evt_method = get(handles.menu_event_method);

spectrum = get(handles.pop_spectral_method);


%I should really consider implementing a for loop at this point....

%the added Position and removal is to bypass a warning that pops because
%Matalb does not like the units field to follow the position field when
%initializing a uicontrol- notice that the copy is a lower case and thus
%different than the upper-cased Position name
edit_synth_CHANNEL = rmfield(edit_synth_CHANNEL,'Type');
edit_synth_CHANNEL = rmfield(edit_synth_CHANNEL,'Extent');
edit_synth_CHANNEL = rmfield(edit_synth_CHANNEL,'BeingDeleted');
edit_synth_CHANNEL.position = edit_synth_CHANNEL.Position;
edit_synth_CHANNEL = rmfield(edit_synth_CHANNEL,'Position');

push_CHANNEL_configuration = rmfield(push_CHANNEL_configuration,'Type');
push_CHANNEL_configuration = rmfield(push_CHANNEL_configuration,'Extent');
push_CHANNEL_configuration = rmfield(push_CHANNEL_configuration,'BeingDeleted');
push_CHANNEL_configuration.position = push_CHANNEL_configuration.Position;
push_CHANNEL_configuration = rmfield(push_CHANNEL_configuration,'Position');

check_save_image = rmfield(check_save_image,'Type');
check_save_image = rmfield(check_save_image,'Extent');
check_save_image = rmfield(check_save_image,'BeingDeleted');
check_save_image.position = check_save_image.Position;
check_save_image = rmfield(check_save_image,'Position');

spectrum = rmfield(spectrum,'Type');
spectrum = rmfield(spectrum,'Extent');
spectrum = rmfield(spectrum,'BeingDeleted');
spectrum.position = spectrum.Position;
spectrum = rmfield(spectrum,'Position');

channel1 = rmfield(channel1,'Type');
channel1 = rmfield(channel1,'Extent');
channel1 = rmfield(channel1,'BeingDeleted');
channel1.position = channel1.Position;
channel1 = rmfield(channel1,'Position');

channel2 = rmfield(channel2,'Type');
channel2 = rmfield(channel2,'Extent');
channel2 = rmfield(channel2,'BeingDeleted');
channel2.position = channel2.Position;
channel2 = rmfield(channel2,'Position');

push_parameter_settings = rmfield(push_parameter_settings,'Type');
push_parameter_settings = rmfield(push_parameter_settings,'Extent');
push_parameter_settings = rmfield(push_parameter_settings,'BeingDeleted');
push_parameter_settings.position = push_parameter_settings.Position;
push_parameter_settings = rmfield(push_parameter_settings,'Position');

evt_method = rmfield(evt_method,'Type');
evt_method = rmfield(evt_method,'Extent');
evt_method = rmfield(evt_method,'BeingDeleted');
evt_method.position = evt_method.Position;
evt_method = rmfield(evt_method,'Position');

GUI_TEMPLATE.edit_synth_CHANNEL = edit_synth_CHANNEL;
GUI_TEMPLATE.push_CHANNEL_configuration = push_CHANNEL_configuration;
GUI_TEMPLATE.check_save_image = check_save_image;
GUI_TEMPLATE.spectrum = spectrum;
GUI_TEMPLATE.channel1 = channel1;
GUI_TEMPLATE.channel2 = channel2;
GUI_TEMPLATE.evt_method = evt_method;
GUI_TEMPLATE.push_parameter_settings = push_parameter_settings;
GUI_TEMPLATE.num_synth_channels = 0;  %number of synthesized channels is zero at first

add_button_pos = get(handles.push_add_event,'position');

%I liked the distance between these two on the GUIDE display of the figure
%and would like to keep the same spacing for additional rows that are added
GUI_TEMPLATE.row_separation = add_button_pos(2)-evt_method.position(2);
GUI_TEMPLATE.spectrum_labels = {'None','PSD','MUSIC'};
% GUI_TEMPLATE.spectrum_labels = {'None','PSD','MUSIC','Coherence'};

function loadDetectionMethods()
%load up any available detection methods found in the detection_path
%(initially this was labeled '+detection' from the working path

global MARKING;
global GUI_TEMPLATE;


if(isfield(MARKING.SETTINGS.VIEW,'detection_path'))
    detection_inf = fullfile(MARKING.SETTINGS.VIEW.detection_path,'detection.inf');
else
    detection_inf = fullfile('+detection','detection.inf');
end

%this part is initialized for the first choice, which is 'none' - no
%artifact or event selected...
evt_label = 'none';
mfile = 'Error';
num_reqd_indices = 0;
param_gui = 'none';
batch_mode_label = '_';

if(exist(detection_inf,'file'))
    [loaded_mfile, loaded_evt_label, loaded_num_reqd_indices, loaded_param_gui, loaded_batch_mode_label] = textread(detection_inf,'%s%s%n%s%s','commentstyle','shell');

    evt_label = [{evt_label};loaded_evt_label];
    mfile = [{mfile};loaded_mfile];
    num_reqd_indices = [num_reqd_indices;loaded_num_reqd_indices];
    param_gui = [{param_gui};loaded_param_gui];
    batch_mode_label = [batch_mode_label; loaded_batch_mode_label];
end;

GUI_TEMPLATE.detection.labels = evt_label;
GUI_TEMPLATE.detection.mfile = mfile;
GUI_TEMPLATE.detection.reqd_indices = num_reqd_indices;
GUI_TEMPLATE.detection.param_gui = param_gui;
GUI_TEMPLATE.detection.batch_mode_label = batch_mode_label;
GUI_TEMPLATE.evt_method.String = evt_label;  %need this here so that newly created rows have these detection options available.

%%%%%%%%%%%%%%%%%%%%%%%%%%

function settings_callback(hObject,~,~)
global GUI_TEMPLATE;
% choice = userdata.choice;

% userdata = get(hObject,'userdata');
% userdata.choice = choice;
% userdata.pBatchStruct = [];
% userdata.rocStruct = [];
userdata = get(hObject,'userdata');
[pBatchStruct,rocStruct] = plist_batch_editor_dlg(GUI_TEMPLATE.detection.labels{userdata.choice},userdata);
if(~isempty(pBatchStruct))
    userdata.pBatchStruct =pBatchStruct;
    userdata.rocStruct = rocStruct;
    set(hObject,'userdata',userdata);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%


function menu_event_callback(hObject,event_data,h_pop_channels,h_push_settings)
global GUI_TEMPLATE;
choice = get(hObject,'value');
set(h_pop_channels,'visible','off');
for k=1:GUI_TEMPLATE.detection.reqd_indices(choice)    
    set(h_pop_channels(k),'visible','on','enable','on','string',GUI_TEMPLATE.EDF.labels);
end

settings_gui = GUI_TEMPLATE.detection.param_gui{choice};

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


%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in push_PSD_settings.
function push_psd_settings_Callback(hObject, eventdata)
% hObject    handle to push_psd_settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
psd = get(hObject,'userdata');
new_settings = psd_dlg(psd);  %.wintype,psd.FFT_window_sec,psd.interval);

if(new_settings.modified)
    new_settings = rmfield(new_settings,'modified');
    set(hObject,'userdata',new_settings);
end;

function cancel_batch_Callback(hObject,eventdata)
% userdata = get(hObject,'userdata');
user_cancelled = true;
disp('Cancelling batch job');
set(hObject,'userdata',user_cancelled);

%%%%%%%%%%%%%%%%%%%%%%%%%%
function batch_process(pathname, BATCH_PROCESS)
%this function executes the batch job with the specified parameters
global MARKING;


%why does this need to be persistent?  
persistent log_fid; 



% BATCH_PROCESS.output_path =
%        parent: 'output'
%           roc: 'ROC'
%         power: 'PSD'
%        events: 'events'
%     artifacts: 'artifacts'
%        images: 'images'
%       current: '/Users/hyatt4/Documents/Sleep Project/Data/Spindle_7Jun11/output'
%this is a given since the button is not activated unless an EDF is
%found in the current directory

if(pathname)
    DEFAULTS.batch_folder = pathname;
    
%     file_list = dir([fullfile(path, '*.EDF');fullfile(path, '*.edf')]);
    %pc's do not have a problem with case; unfortunately the other side
    %does
    if(ispc)
        file_list = dir(fullfile(pathname,'*.EDF'));
    else
        file_list = [dir(fullfile(pathname, '*.EDF'));dir(fullfile(pathname, '*.edf'))]; %dir(fullfile(path, '*.EDF'))];
    end
    
    MARKING.STATE.batch_process_running = true;
    
    
    %reference sev.m - sev_OpeningFcn (line ~192)
    BATCH_PROCESS.output_path.current = fullfile(pathname, BATCH_PROCESS.output_path.parent);
%     BATCH_PROCESS.roc_path = 'ROC';
%     BATCH_PROCESS.psd_path = 'PSD';
%     BATCH_PROCESS.events_path = 'events';
%     BATCH_PROCESS.artifacts_path = 'artifacts';
%     BATCH_PROCESS.images_path = 'images';

    % waitHandle = waitbar(0,'Initializing batch processing job','name','Batch Processing Statistics','resize','on','createcancelbtn',{@cancel_batch_Callback});
    user_cancelled = false;
    waitHandle = waitbar(0,'Initializing batch processing job','name','Batch Processing Statistics','resize','on','createcancelbtn',@cancel_batch_Callback,'userdata',user_cancelled,'tag','waitbarHTag');
    
    
    BATCH_PROCESS.waitHandle = waitHandle;
    %turn off the interpeter so that '_' does not cause subscripting 
    set(findall(waitHandle,'interpreter','tex'),'interpreter','none');

    waitbarPos = get(waitHandle,'position');
    waitbarPos(4)=waitbarPos(4)*1.5;
    set(waitHandle,'position',waitbarPos);
    
    file_count = numel(file_list);
    
    if(~isdir(BATCH_PROCESS.output_path.current))
        mkdir(BATCH_PROCESS.output_path.current);        
    end;
    
    full_roc_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.roc);
    if(~isdir(full_roc_path))
        mkdir(full_roc_path);
    end;
    
    full_psd_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.power);
    if(~isdir(full_psd_path))
        mkdir(full_psd_path);
    end;
    full_events_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.events);
    if(~isdir(full_events_path))
        mkdir(full_events_path);
    end;
    full_events_images_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.events,BATCH_PROCESS.output_path.images);
    if(~isdir(full_events_images_path))
        mkdir(full_events_images_path);
    end
    full_artifacts_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.artifacts);
    if(~isdir(full_artifacts_path))
        mkdir(full_artifacts_path);
    end;
    full_artifacts_images_path = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.artifacts,BATCH_PROCESS.output_path.images);
    if(~isdir(full_artifacts_images_path))
        mkdir(full_artifacts_images_path);
    end
    
   
    if(BATCH_PROCESS.output_files.log_checkbox)
        BATCH_PROCESS.start_time = datestr(now,'yyyymmmdd_HH_MM_SS');
        log_filename = fullfile(BATCH_PROCESS.output_path.current,[BATCH_PROCESS.output_files.log_filename,BATCH_PROCESS.start_time,'.txt']);
        log_fid = fopen(log_filename,'w');
        
        fprintf(log_fid,'SEV batch process run on %i files.\r\n',file_count);
        if(numel(BATCH_PROCESS.event_settings)>0)
            
            fprintf(log_fid,'The following event detectors were run with this batch job.\r\n');
            for k=1:numel(BATCH_PROCESS.event_settings)
                method_label = char(BATCH_PROCESS.event_settings{k}.method_label);
                pStruct = BATCH_PROCESS.event_settings{k}.pBatchStruct;
                channel_labels = reshape(char(BATCH_PROCESS.event_settings{k}.channel_labels)',1,[]);
                batch_mode_label = char(BATCH_PROCESS.event_settings{k}.batch_mode_label);
                
                fprintf(log_fid,'%u.\t%s\t(labeled as ''%s'')\tApplied to Channel(s): %s',k,method_label,batch_mode_label,channel_labels);
                
                %put one of these two in the log file
                if(numel(pStruct)>0)
                    fprintf(log_fid,'\t(Parameter, start, stop, num steps):');
                    for c=1:numel(pStruct)
                         fprintf(log_fid,' %s(%d,%d,%d)',pStruct{c}.key,pStruct{c}.start,pStruct{c}.stop,pStruct{c}.num_steps);
                    end
                else
                   params = BATCH_PROCESS.event_settings{k}.params; 
                   if(~isempty(params))
                       keys =fieldnames(params);
                       fprintf(log_fid,'\tParameter(value):');
                       for c=1:numel(keys)
                           fprintf(log_fid,' %s(%d)',keys{c},params.(keys{c}));
                       end
                   else
                       fprintf(log_fid,' No adjustable settings for this method');
                   end
                end
                fprintf(log_fid,'\r\n');               
            end            
        else
            fprintf(log_fid,'No event detectors were run with this batch job.\r\n');
        end;
        if(numel(BATCH_PROCESS.artifact_settings)>0)
            fprintf(log_fid,'The following artifact detectors were run with this batch job.\r\n');
            
            for k=1:numel(BATCH_PROCESS.artifact_settings)
                method_label = char(BATCH_PROCESS.artifact_settings{k}.method_label);
                params = BATCH_PROCESS.artifact_settings{k}.params;
                channel_labels = reshape(char(BATCH_PROCESS.artifact_settings{k}.channel_labels)',1,[]);
                batch_mode_label = char(BATCH_PROCESS.artifact_settings{k}.batch_mode_label);
                
                fprintf(log_fid,'%u.\t%s\t(labeled as ''%s'')\tApplied to Channel(s): %s',k,method_label,batch_mode_label,channel_labels);
                
                if(~isempty(params))
                    keys =fieldnames(params);
                    fprintf(log_fid,'\tParameter(value):');
                    for c=1:numel(keys)
                        fprintf(log_fid,' %s(%d)',keys{c},params.(keys{c}));
                    end
                else
                    fprintf(log_fid,' No adjustable settings for this method');
                end
                fprintf(log_fid,'\r\n');
               
            end
            
                        
        else
            fprintf(log_fid,'No artifact detectors were run with this batch job.\r\n');
        end;
        
        if(numel(BATCH_PROCESS.PSD_settings)>0)
            fprintf(log_fid,'Power spectral density by periodogram analysis was conducted with the following configuration(s):\r\n');
            for k=1:numel(BATCH_PROCESS.PSD_settings)
               params = BATCH_PROCESS.PSD_settings{k};
               fprintf(log_fid,'%u.\t',k);

               if(~isempty(params))
                   fprintf(log_fid,'Parameter(value):\t');
                    keys =fieldnames(params);
                    for c=numel(keys):-1:1
                        switch(class(params.(keys{c})))
                            case 'double'
                                fprintf(log_fid,' %s(%d)',keys{c},params.(keys{c}));
                            case 'cell'
                                fprintf(log_fid,' %s(%s)',keys{c},params.(keys{c}){1});
                            case 'char'
                                fprintf(log_fid,' %s(%s)',keys{c},params.(keys{c}));
                            otherwise
                                fprintf(log_fid,' %s(unknownType)',keys{c});
                        end
                    end
               else
                   fprintf(log_fid,' No adjustable settings for this method');
                end
                fprintf(log_fid,'\r\n');
            end
        end
        
        if(numel(BATCH_PROCESS.MUSIC_settings)>0)
            fprintf(log_fid,'Power spectral density by MUSIC analysis was conducted with the following configuration(s):\r\n');
            for k=1:numel(BATCH_PROCESS.MUSIC_settings)
               params = BATCH_PROCESS.MUSIC_settings{k};
               fprintf(log_fid,'%u.\t',k);
               if(~isempty(params))
                    keys =fieldnames(params);
                    fprintf(log_fid,'Parameter(value):\t');
                    for c=numel(keys):-1:1
                        switch(class(params.(keys{c})))
                            case 'double'
                                fprintf(log_fid,' %s(%d)',keys{c},params.(keys{c}));
                            case 'cell'
                                fprintf(log_fid,' %s(%s)',keys{c},params.(keys{c}){1});
                            case 'string'
                                fprintf(log_fid,' %s(%s)',keys{c},params.(keys{c}));
                            otherwise
                                fprintf(log_fid,' %s(unknownType)',keys{c});
                        end
                    end
               else
                   fprintf(log_fid,' No adjustable settings for this method');
                end
                fprintf(log_fid,'\r\n');
            end
        end        
        fprintf(log_fid,'Job was started: %s\r\n\r\n',BATCH_PROCESS.start_time);
    else
        disp('No log file created for this run.  Choose settings to change this, and check the log checkbox if you want to change this.');
        BATCH_PROCESS.start_time = ' ';
    end;
    
    event_settings = BATCH_PROCESS.event_settings;
    artifact_settings = BATCH_PROCESS.artifact_settings;
    
    image_settings =[];
    if(BATCH_PROCESS.images.save2img)
        image_settings.limit_count = BATCH_PROCESS.images.limit_count*BATCH_PROCESS.images.limit_flag;
        image_settings.buffer_sec = BATCH_PROCESS.images.buffer_sec*BATCH_PROCESS.images.buffer_flag;
        image_settings.format = BATCH_PROCESS.images.format; 
        for k = 1:numel(event_settings)
            if(event_settings{k}.save2img)
                %put images in subdirectory based on detection method                
                event_images_path = fullfile(full_events_images_path,event_settings{k}.method_label);
                if(~isdir(event_images_path))
                    mkdir(event_images_path);
                end
            end
        end
        for k = 1:numel(artifact_settings)
            if(artifact_settings{k}.save2img)
                %put images in subdirectory based on detection method                
                artifact_images_path = fullfile(full_events_images_path,artifact_settings{k}.method_label);
                if(~isdir(artifact_images_path))
                    mkdir(artifact_images_path);
                end
            end
        end
    end
    
    for k = 1:numel(event_settings)
        method_label = event_settings{k}.method_label;
        
        pBatchStruct = event_settings{k}.pBatchStruct;
        paramStruct = event_settings{k}.params;
        event_settings{k}.numConfigurations = 1;
        %grid out the combinations here...and reassign to pBatchStruct
        if(~isempty(pBatchStruct))
            
            num_keys = numel(pBatchStruct); %this is the number of distinct settings that can be manipulated for the current (k) event detector
            all_properties = cell(num_keys,1);
            keys = cell(size(all_properties));
            
            %determine the range of values to go
            %through for each property value
            %allowed/specified
            clear pStruct;
            for j = 1:num_keys
                keys{j} = pBatchStruct{j}.key;
                pStruct.(keys{j}) = [];
                if(isnumeric(pBatchStruct{j}.start))
                    %add this check in here, otherwise a user may change
                    %the start value, leaving the num steps one, but the
                    %start value is less than the end value and linspace
                    %will instead return the lesser value, and not
                    %what the user wants in this case
                    if(pBatchStruct{j}.num_steps==1)
                        all_properties{j} = pBatchStruct{j}.start;
                    else
                        all_properties{j} = linspace(pBatchStruct{j}.start,pBatchStruct{j}.stop,pBatchStruct{j}.num_steps);
                    end
                else
                    if(strcmp(pBatchStruct{j}.start,pBatchStruct{j}.stop))
                        all_properties{j} = pBatchStruct{j}.start;
                    else
                        all_properties{j} = {pBatchStruct{j}.start,pBatchStruct{j}.stop};
                    end
                end
            end
            cell_all_properties = cell(size(all_properties));
            [cell_all_properties{:}] = ndgrid(all_properties{:}); %grid it out, with all combinations...
            
            numConfigurations = numel(cell_all_properties{1});
            pStructArray = repmat(pStruct,numConfigurations,1);

            for j = 1:numConfigurations;
                for p = 1:num_keys
                    pStructArray(j).(keys{p}) = cell_all_properties{p}(j);
                end
            end
            event_settings{k}.numConfigurations = numConfigurations;
            event_settings{k}.params = pStructArray;
            
        end
        
        %this saves the detector configurations for each detector to a
        %separate file, with an id for each cconfiguration setup that can
        %be used to determine which file output is for which configuration
        if(~isempty(paramStruct))
            batch.saveDetectorConfigLegend(full_events_path,method_label,paramStruct);
        end
    end
    
    %% setup database for events 
    if(BATCH_PROCESS.database.save2DB)
        %database_struct contains fields 'name','user','password' for interacting with a mysql database
        DBstruct = CLASS_events_container.loadDatabaseStructFromInf(BATCH_PROCESS.database.filename,BATCH_PROCESS.database.choice);
        if(~isempty(DBstruct))
            DBstruct.table = 'events_t';
            if(BATCH_PROCESS.database.auto_config~=0||BATCH_PROCESS.database.config_start==0)
                event_settings = CLASS_events_container.getDatabaseAutoConfigID(DBstruct,event_settings);
            else
                event_settings = CLASS_events_container.setDatabaseConfigID(DBstruct,event_settings,BATCH_PROCESS.database.config_start);
            end
            event_settings = CLASS_events_container.deleteDatabaseRecordsUsingSettings(DBstruct,event_settings);
        end
    else
        DBstruct = [];
    end
    
    
    BATCH_PROCESS.event_settings = event_settings;
    
    
    %% Begin batch file processing  - parallel computing parfor
    %     parfor i = 1:file_count - need to update global calls to work
    %     better here.
    
    startClock = clock;
    files_attempted = false(file_count,1);
    files_completed = false(file_count,1);
    files_skipped = false(file_count,1); %logical indices to mark which files were skipped

    
    start_time = now;
%     est_str = '?'; %estimate of how much time is left to run the job

% user_cancelled = get(waitHandle,'userdata');

    clear configID;
    clear detectorID;
    clear elapsed_dur_total_sec;

%     if(BATCH_PROCESS.output_files.log_checkbox && ~isempty(log_fid))
%         fclose(log_fid);
%     end
assignin('base','files_completed',files_completed);

try
%     matlabpool open
catch me
   showME(me)  
end
%     parfor i = 1:file_count

    for i = 1:file_count
      tStart = tic;
      configID = [];
      detectorID = [];
      user_cancelled = false;
%       waitHandle = findall(0,'tag','waitbarHTag');

      
      if(~user_cancelled)
        
        try

%             if(BATCH_PROCESS.output_files.log_checkbox)
%                 log_filename = fullfile(BATCH_PROCESS.output_path.current,[BATCH_PROCESS.output_files.log_filename,BATCH_PROCESS.start_time,'.txt']);
%                 log_fid = fopen(log_filename,'w');
%             end
            if(~file_list(i).isdir)
                files_attempted(i) = 1;
                
                
                
                %initialize the files...
%                 tStart = clock;
                cur_filename = file_list(i).name;
                
                skip_file = false;

%                 BATCH_PROCESS.cur_filename = cur_filename;
                stages_filename = fullfile(pathname,[cur_filename(1:end-3) 'STA']);
                
                %require stages filename to exist.
                if(~exist(stages_filename,'file'))
                    skip_file = true;
                    
                    %%%%%%%%%%%%%%%%%%%%%REVIEW%%%%%%%%%%%%%%%%%%%%%%%%
%                     if(BATCH_PROCESS.output_files.log_checkbox)
%                         fprintf(log_fid,'%s not found!  This EDF will be skipped.\r\n',stages_filename);
%                     end;
                end;
                
                if(~skip_file)
                    
                    
                    %this loads the channels specified in the BATCH_PROCESS
                    %variable, for the current EDF file
                    
                    %CREATES A GLOBAL CHANNELS_CONTAINER CLASS FOR THIS
                    %iteration/run
                    [batch_CHANNELS_CONTAINER, parBATCH_PROCESS, studyInfo] = batch.load_file(pathname,cur_filename, BATCH_PROCESS);
                    %the following two settings need to follow batch.load
                    %due the side effects that occur in batch.load_file
                    %that change the event_settings to include new field
                    %channel_indices which may change per EDF loaded as the
                    %naming convention should/must remain the same, while
                    %the channel numbering/ordering does not have the same
                    %requirement
                    artifact_settings = parBATCH_PROCESS.artifact_settings;
                    event_settings = parBATCH_PROCESS.event_settings;
               
                    %handle the stage data, which is a requirement for
                    %batch processing - that is, it must exist for batch
                    %processing to continue/work
                    batch_STAGES = loadSTAGES(stages_filename,studyInfo.num_epochs);
                    studyInfo.STAGES = batch_STAGES;
                    studyInfo.standard_epoch_sec = parBATCH_PROCESS.standard_epoch_sec;
                    
                    %PROCESS ARTIFACTS
                    batch_ARTIFACT_CONTAINER = CLASS_events_container([],[],parBATCH_PROCESS.base_samplerate,batch_STAGES); %this global variable may be checked in output functions and
                    batch_ARTIFACT_CONTAINER.CHANNELS_CONTAINER = batch_CHANNELS_CONTAINER;
                    artifact_filenames = fullfile(full_artifacts_path,[parBATCH_PROCESS.output_files.artifacts_filename,cur_filename(1:end-4)]);
                        
                    %this requires initialization

                    if(numel(artifact_settings)>0)
                        for k = 1:numel(artifact_settings)
                            
                            function_name = artifact_settings{k}.method_function;
%                             function_call = [detection_path,'.',function_name];
                            
                            source_indices = artifact_settings{k}.channel_indices;
                            
                            detectStruct = batch_ARTIFACT_CONTAINER.evaluateDetectFcn(function_name,source_indices, artifact_settings{k}.params);

%                             detectStruct = feval(function_call,source_indices,params);
                            sourceStruct = [];
                            sourceStruct.channel_indices = source_indices;
                            sourceStruct.algorithm = function_name;
                            sourceStruct.editor = 'none';
                            if(~isempty(detectStruct.new_events))
                                
                                batch_ARTIFACT_CONTAINER.addEvent(detectStruct.new_events,artifact_settings{k}.method_label,0,sourceStruct,detectStruct.paramStruct);
                                if(artifact_settings{k}.save2img)
                                    
                                    %put these images in their own subdirectory based on
                                    %patients identifier
                                    artifact_images_path = fullfile(full_artifacts_images_path,cur_filename(1:end-4));
                                    if(~isdir(artifact_images_path))
                                        mkdir(artifact_images_path);
                                    end
                                    img_filename_prefix = [cur_filename(1:end-4),'-',artifact_settings{k}.method_label];
                                    full_img_filename_prefix = fullfile(artifact_images_path,img_filename_prefix);
                                    batch_ARTIFACT_CONTAINER.save2images(k,full_img_filename_prefix,image_settings);
                                end
                                
                            else %add empty
                                %                         events as well so that we can show what was and
                                %                         was not met in the periodogram output...
                                batch_ARTIFACT_CONTAINER.addEmptyEvent(artifact_settings{k}.method_label,0,sourceStruct,detectStruct.paramStruct);
                                
                            end
                            batch_ARTIFACT_CONTAINER.cell_of_events{k}.batch_mode_label = artifact_settings{k}.batch_mode_label;
                            
                        end
                        if(BATCH_PROCESS.output_files.save2mat)
                            batch_ARTIFACT_CONTAINER.save2mat(artifact_filenames,studyInfo);
                        end
                        if(BATCH_PROCESS.database.save2DB)
                            batch_ARTIFACT_CONTAINER.save2DB(artifact_filenames);
                        end
                        if(BATCH_PROCESS.output_files.save2txt)
                            batch_ARTIFACT_CONTAINER.save2txt(artifact_filenames,studyInfo);
                        end
                    end

                    
                    %PROCESS THE EVENTS
                    if(numel(event_settings)>0)
                        batch_EVENT_CONTAINER = CLASS_events_container([],[],parBATCH_PROCESS.base_samplerate,batch_STAGES);
                        batch_EVENT_CONTAINER.CHANNELS_CONTAINER = batch_CHANNELS_CONTAINER;
                        event_filenames = fullfile(full_events_path,[parBATCH_PROCESS.output_files.events_filename,cur_filename(1:end-4)]);
                        
                        for k = 1:numel(event_settings)
                            function_name = event_settings{k}.method_function;
%                             function_call = [detection_path,'.',function_name];
                            
                            pBatchStruct = event_settings{k}.pBatchStruct;
                            
                            %there are no combinations to use....
                            if(isempty(pBatchStruct))
                                source_indices = event_settings{k}.channel_indices;
                                detectStruct = batch_EVENT_CONTAINER.evaluateDetectFcn(function_name, source_indices, event_settings{k}.params);
                                if(~isempty(detectStruct.new_events))
                                    sourceStruct = [];
                                    sourceStruct.channel_indices = source_indices;
                                    sourceStruct.algorithm = function_name;
                                    sourceStruct.editor = 'none';
                                    sourceStruct.pStruct = [];
                                    
                                    %add the event
                                    batch_EVENT_CONTAINER.addEvent(detectStruct.new_events,event_settings{k}.method_label,source_indices,sourceStruct,detectStruct.paramStruct);                                    
                                    batch_EVENT_CONTAINER.getCurrentChild.batch_mode_label = event_settings{k}.batch_mode_label;
                                                                        
                                    batch_EVENT_CONTAINER.getCurrentChild.configID = event_settings{k}.configID;
                                    batch_EVENT_CONTAINER.getCurrentChild.detectorID = event_settings{k}.detectorID;
                                    
                                    
%                                     if(~isempty(event_settings{k}.params)) %in this case, configurationLegend.detection_method.txt file was created
%                                         configID = 1;
%                                     else
%                                         configID = 0; %this is the default anyway...-> no file was created
%                                     end
%                                     
%                                     EVENT_CONTAINER.cell_of_events{EVENT_CONTAINER.num_events}.configID = configID;
                                    
                                    if(event_settings{k}.save2img)
                                        %put these images in their own subdirectory based on
                                        %patients identifier
                                        % event_images_path = full_events_images_path;
                                        % event_images_path = fullfile(full_events_images_path,cur_filename(1:end-4));
                                        event_images_path = fullfile(full_events_images_path,event_settings{k}.method_label);
                                        
                                        %this is now handled earlier
                                        %if(~isdir(event_images_path))
                                        %    mkdir(event_images_path);
                                        %end
                                        img_filename_prefix = [cur_filename(1:end-4),'_',event_settings{k}.method_label];
                                        full_img_filename_prefix = fullfile(event_images_path,img_filename_prefix);
                                        batch_EVENT_CONTAINER.save2images(k,full_img_filename_prefix,image_settings);                                        
                                    end
                                end
                                
                                %alternate case is to create and add an event
                                %for each pStruct combination possible from the
                                %given pBatchStruct parameters.
                            else
                                start_evt_ind = batch_EVENT_CONTAINER.num_events +1;
                                for j = 1:event_settings{k}.numConfigurations;
                                    pStruct = event_settings{k}.params(j);
                                    source_indices = event_settings{k}.channel_indices;
                                    detectStruct = batch_EVENT_CONTAINER.evaluateDetectFcn(function_name, source_indices, pStruct);
%                                     detectStruct = feval(function_call,source_indices,pStruct);
                                    try
                                        configID = event_settings{k}.configID(j);
                                        if(~isempty(event_settings{k}.detectorID))
                                            detectorID = event_settings{k}.detectorID(j);
                                        end
                                    catch me
                                       showME(me); 
                                    end
                                    if(~isempty(detectStruct.new_events))                                        
                                        sourceStruct.channel_indices = source_indices;
                                        sourceStruct.algorithm = function_name;
                                        sourceStruct.editor = 'none';
                                        sourceStruct.pStruct = pStruct;
                                        batch_EVENT_CONTAINER.addEvent(detectStruct.new_events,event_settings{k}.method_label,source_indices,sourceStruct,detectStruct.paramStruct);
                                        batch_EVENT_CONTAINER.cell_of_events{batch_EVENT_CONTAINER.num_events}.batch_mode_label = event_settings{k}.batch_mode_label;
                                        batch_EVENT_CONTAINER.cell_of_events{batch_EVENT_CONTAINER.num_events}.configID = configID;
                                        batch_EVENT_CONTAINER.cell_of_events{batch_EVENT_CONTAINER.num_events}.batch_mode_label = event_settings{k}.batch_mode_label;
                                        batch_EVENT_CONTAINER.cell_of_events{batch_EVENT_CONTAINER.num_events}.detectorID = detectorID;
                                    end
                                end
                                end_evt_ind = batch_EVENT_CONTAINER.num_events;
                                
                                if(~isempty(event_settings{k}.rocStruct))
                                    if(end_evt_ind>=start_evt_ind)  %make sure I didn't go through and get nothing...
                                        rocStruct = event_settings{k}.rocStruct;
                                        truth_file = dir(fullfile(rocStruct.truth_pathname,['*.',cur_filename(1:end-3),'*',rocStruct.truth_evt_suffix]));
                                        if(~isempty(truth_file))
                                            truth_filename = fullfile(rocStruct.truth_pathname,truth_file(1).name);
                                            if(exist(truth_filename,'file'))
                                                
                                                batch_EVENT_CONTAINER.loadEvtFile(truth_filename,MARKING.STATE.batch_process_running);
                                                
                                                %add this check here since the EVENT_CONTAINER will not load the event from a file if it was previously
                                                %loaded.  Without this check, the roc may produce 100% matches since it would be comparing to itself
                                                if(batch_EVENT_CONTAINER.num_events~=end_evt_ind)
                                                    batch_EVENT_CONTAINER.roc_truth_ind = batch_EVENT_CONTAINER.num_events;
                                                end
                                                save_filename = fullfile(full_roc_path,['ROC_',rocStruct.truth_evt_suffix,'_VS_',function_name,'.txt']);
                                                if(i==1 && exist(save_filename,'file'))
                                                    delete(save_filename);
                                                end
                                                batch_EVENT_CONTAINER.save2roc_txt(save_filename,[start_evt_ind,end_evt_ind],rocStruct.truth_evt_suffix,cur_filename);
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        if(BATCH_PROCESS.output_files.save2mat)
                            batch_EVENT_CONTAINER.save2mat(event_filenames,studyInfo);
                        end
                        if(BATCH_PROCESS.database.save2DB)                            
                            batch_EVENT_CONTAINER.save2DB(DBstruct,cur_filename(1:end-4)); %database_struct contains fileds 'name','user','password' for interacting with a mysql database
                        end
                        if(BATCH_PROCESS.output_files.save2txt)
                            batch_EVENT_CONTAINER.save2txt(event_filenames,studyInfo);
                        end
                        
                    end
                           
                    %SAVE THINGS TO FILE....
                    %save the events to file... - this is now handled in
                    %save_periodograms.m now
                    %AGAIN - THIS IS NOW HANDLED IN SAVE_PERIODOGRAMS.M
%                     if(BATCH_PROCESS.output_files.cumulative_stats_checkbox)
%                          batch.updateBatchStatisticsTally();
%                     end

                    %this is handled in batch/save_periodograms.m now
%                     if(BATCH_PROCESS.output_files.statistics_checkbox) %artifact statistics
% %                         save_art_stats_Callback(hObject, eventdata, handles);
%                           batch.saveArtifactandStageStatistics();
%                     end;
                    for k = 1:numel(BATCH_PROCESS.PSD_settings)
                        channel_label = BATCH_PROCESS.PSD_settings{k}.channel_labels{:};
                        channel_index = BATCH_PROCESS.PSD_settings{k}.channel_indices;
                        filename_out = fullfile(full_psd_path,[cur_filename(1:end-3), channel_label,'.', BATCH_PROCESS.output_files.psd_filename]);
                        
                        batch.save_periodograms(channel_index,filename_out,BATCH_PROCESS.PSD_settings{k});
                    end;

                    for k = 1:numel(BATCH_PROCESS.MUSIC_settings)
                        channel_label = BATCH_PROCESS.MUSIC_settings{k}.channel_labels{:};
                        channel_index = BATCH_PROCESS.MUSIC_settings{k}.channel_indices;
                        filename_out = fullfile(full_music_path,[cur_filename(1:end-3), channel_label,'.', BATCH_PROCESS.output_files.music_filename]);
                        
                        batch.save_pmusic(channel_index,filename_out,BATCH_PROCESS.MUSIC_settings{k});
                    end;
                    
                    %save the files to disk
                    if(BATCH_PROCESS.output_files.log_checkbox)
                        if(~isempty(fopen(log_fid)))
                            fprintf(log_fid,'%s . . . completed successfully at %s\r\n',file_list(i).name,datestr(now));
                        end
                    end;
                    
                else
                    if(BATCH_PROCESS.output_files.log_checkbox)
%                         fprintf(log_fid,'%s . . . NOT PROCESSED (see notes above)\r\n',file_list(i).name);
                    end;
                    
                    files_skipped(i) = true;
                end;
                files_completed(i) = true;
                elapsed_dur_sec = toc(tStart);
                fprintf('File %d of %d (%0.2f%%) Completed in %0.2f seconds\n',i,file_count,i/file_count*100,elapsed_dur_sec);
                elapsed_dur_total_sec = etime(clock,startClock);
                avg_dur_sec = elapsed_dur_total_sec/i;
                
                %                 num_files_completed = randi(1,0,100);
                num_files_completed = i;
                remaining_dur_sec = avg_dur_sec*(file_count-num_files_completed);
                est_str = sprintf('%01ihrs %01imin %01isec',floor(mod(remaining_dur_sec/3600,24)),floor(mod(remaining_dur_sec/60,60)),floor(mod(remaining_dur_sec,60)));

                msg = {['Processing ',file_list(i).name, ' (file ',num2str(i) ,' of ',num2str(file_count),')'],...
                    ['Time Elapsed Time: ',datestr(now-start_time,'HH:MM:SS')],...
                    ['Estimated Time Remaining: ',est_str]};
                fprintf('%s\n',msg{2});
                if(ishandle(waitHandle))
                    waitbar(i/file_count,waitHandle,char(msg));
                else
%                     waitHandle = findall(0,'tag','waitbarHTag');
                end

            end;
        catch cur_error
%             showME(cur_error);
            disp([file_list(i).name, ' SKIPPED: The following error was encountered: (' cur_error.message ')']);
            file_warnmsg = cur_error.message;
            showME(cur_error);
            
%             console_warnmsg = cur_error.message;           
%             for s = 1:min(numel(cur_error.stack),2)
%                 % disp(['<a href="matlab:opentoline(''',file,''',',linenum,')">Open Matlab to this Error</a>']);
%                 stack_error = cur_error.stack(s);
%                 console_warnmsg = sprintf('%s\r\n\tFILE: %s <a href="matlab:opentoline(''%s'',%s)">LINE: %s</a> FUNCTION: %s', console_warnmsg,stack_error.file,stack_error.file,num2str(stack_error.line),num2str(stack_error.line), stack_error.name);
%                 file_warnmsg = sprintf('\t%s\r\n\t\tFILE: %s LINE: %s FUNCTION: %s', file_warnmsg,stack_error.file,num2str(stack_error.line), stack_error.name);
%             end
%             disp(console_warnmsg)

            if(BATCH_PROCESS.output_files.log_checkbox)
                if(~isempty(fopen(log_fid)))
                    fprintf(log_fid,'%s . . . NOT PROCESSED.  The following error was encountered:\r\n%s\r\n',file_list(i).name,file_warnmsg);
                end
            end
            files_skipped(i)= true;
            files_completed(i) = true;
            
            
            elapsed_dur_sec = toc(tStart);
            fprintf('File %d of %d (%0.2f%%) Completed in %0.2f seconds\n',i,file_count,i/file_count*100,elapsed_dur_sec);
            elapsed_dur_total_sec = etime(clock,startClock);
            avg_dur_sec = elapsed_dur_total_sec/i;
            remaining_dur_sec = avg_dur_sec*(file_count-i);
            est_str = sprintf('%01ihrs %01imin %01isec',floor(mod(remaining_dur_sec/3600,24)),floor(mod(remaining_dur_sec/60,60)),floor(mod(remaining_dur_sec,60)));
            
            msg = {['Processing ',file_list(i).name, ' (file ',num2str(i) ,' of ',num2str(file_count),')'],...
                ['Elapsed Time: ',datestr(now-start_time,'HH:MM:SS')],...
                ['Estimated Time Remaining: ',est_str]};
            
            if(ishandle(waitHandle))
                fprintf('You finished recently!\n');
                waitbar(i/file_count,waitHandle,char(msg));
            else
%                 waitHandle = findall(0,'tag','waitbarHTag');
            end
        end
      else
          
          files_skipped(i) = true;
      end %end if not batch_process.cancelled
    end; %end for all files
%     matlabpool close;
    num_files_completed = sum(files_completed);
    num_files_skipped = sum(files_skipped);
%     waitHandle = findobj('tag','waitbarTag');
    
    finish_str = {'SEV batch process completed!',['Files Completed = ',...
        num2str(num_files_completed)],['Files Skipped = ',num2str(num_files_skipped)],...
        ['Elapsed Time: ',datestr(now-start_time,'HH:MM:SS')]};
        
    if(ishandle(waitHandle))
        waitbar(100,waitHandle,finish_str);
    end;
    
    if(BATCH_PROCESS.output_files.log_checkbox)
        if(~isempty(fopen(log_fid)))
            fprintf(log_fid,'Job finished: %s\r\n',datestr(now));
            fclose(log_fid);
        end
    end
    [log_path,log_filename,log_file_ext] = fileparts(MARKING.SETTINGS.VIEW.parameters_filename);
    MARKING.SETTINGS.saveParametersToFile([],fullfile(BATCH_PROCESS.output_path.current,[log_filename,log_file_ext]));
    
    %not really necessary, since I am not going to update the handles after
    %this function call in order for everything to go back to what it was
    %before hand ...;
    
    MARKING.STATE.batch_process_running = false;
%     message = sprintf('Batch Processing finished.\r\n%i files attempted.\r\n%i files processed successfully.\r\n%i files skipped.',...
%         num_files_attempted,num_files_completed,files_skipped);
    message = finish_str;
    
    if(num_files_skipped>0)
        skipped_filenames = cell(num_files_skipped,1);
        [skipped_filenames{:}]=file_list(files_skipped).name;
        [selections,clicked_ok]= listdlg('PromptString',message,'Name','Batch Completed',...
            'OKString','Copy to Clipboard','CancelString','Close','ListString',skipped_filenames);
        
        if(clicked_ok)
            %char(10) is newline
            skipped_files = [char(skipped_filenames(selections)),repmat(char(10),numel(selections),1)];
            skipped_files = skipped_files'; %filename length X number of files
            
            clipboard('copy',skipped_files(:)'); %make it a column (1 row) vector
            disp([num2str(numel(selections)),' filenames copied to the clipboard.']);
        end;
    else
         msgbox(message,'Completed');
    end
    
    if(exist('waitHandle','var')&&ishandle(waitHandle))
        delete(waitHandle(1));
    end;

else
    disp 'nothing selected'
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in push_output_settings.
function push_output_settings_Callback(hObject, eventdata, handles)
% hObject    handle to push_output_settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
BATCH_PROCESS = handles.user.BATCH_PROCESS;

settings = batch_output_settings_dlg(BATCH_PROCESS);
if(~isempty(settings))
    BATCH_PROCESS.output_files = settings.output_files;
    BATCH_PROCESS.output_path = settings.output_path;
    BATCH_PROCESS.database = settings.database;
    BATCH_PROCESS.images = settings.images; 
    handles.user.BATCH_PROCESS = BATCH_PROCESS;
    update_view(handles);
end;

guidata(hObject,handles);

% --- Executes on selection change in pop_spectral_method.
function pop_spectral_method_Callback(hObject, eventdata, channels_h, settings_h)
% hObject    handle to pop_spectral_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global MARKING;
PSD = MARKING.SETTINGS.PSD;
MUSIC = MARKING.SETTINGS.MUSIC;
contents = cellstr(get(hObject,'String'));% returns pop_spectral_method contents as cell array
selection = contents{get(hObject,'Value')}; %returns selected item from pop_spectral_method

switch(lower(selection))
    case 'none'
        %disable channel selection
        %disable settings
        set(channels_h,'enable','off');
        set(settings_h,'enable','off');
    case 'psd'
        %enable channel selection
        %enable settings
        set(channels_h,'enable','on');
        set(settings_h,'enable','on','callback',@push_psd_settings_Callback,'userdata',PSD);        
    case 'music'
        %enable  channel selection
        %disable settings
        set(channels_h,'enable','on');
        set(settings_h,'enable','off','userdata',MUSIC);
    case 'coherence'
        %enable  channel selection
        %disable settings
        set(channels_h,'enable','on');
        set(settings_h,'enable','off','userdata',[]);        
    otherwise
        disp 'Selection not handled';
end


% --- Executes on button press in check_event_export_images.
function check_event_export_images_Callback(hObject, eventdata, handles)
% hObject    handle to check_event_export_images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_event_export_images


% --- Executes on button press in check_artifact_export_images.
function check_artifact_export_images_Callback(hObject, eventdata, handles)
% hObject    handle to check_artifact_export_images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_artifact_export_images


% --- Executes on button press in push_add_CHANNEL.
function push_add_CHANNEL_Callback(hObject, eventdata, handles)
% hObject    handle to push_add_CHANNEL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addCHANNELRow(handles);


% --- Executes on selection change in menu_synth_CHANNEL_channel1.
function menu_synth_CHANNEL_channel1_Callback(hObject, eventdata, handles)
% hObject    handle to menu_synth_CHANNEL_channel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_synth_CHANNEL_channel1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_synth_CHANNEL_channel1


% --- Executes on button press in push_synth_CHANNEL_settings.
function push_synth_CHANNEL_settings_Callback(hObject, eventdata, handles)
% hObject    handle to push_synth_CHANNEL_settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on selection change in edit_synth_CHANNEL_name.
function edit_synth_CHANNEL_name_Callback(hObject, eventdata, handles)
% hObject    handle to edit_synth_CHANNEL_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns edit_synth_CHANNEL_name contents as cell array
%        contents{get(hObject,'Value')} returns selected item from edit_synth_CHANNEL_name

function synthesize_CHANNEL_configuration_callback(hObject,eventdata,menuchannels_h,editoutputname_h)
%enter the configuration parameters for the specified channel...
global GUI_TEMPLATE;

settings = get(hObject,'userdata');
cur_channel_index = get(menuchannels_h,'value');
settings = prefilter_dlg(GUI_TEMPLATE.EDF.labels,settings,cur_channel_index);

%the user did not cancel and a settings structure exists
if(~isempty(settings))
    disp(settings);
    set(hObject,'userdata',settings);
    
    %if this is the first time a channel has been synthesized on this row
    %then give it a name, lock the row from using different source channels
    %and update all other references to GUI_TEMPLATE.EDF.labels with the
    %new name
    if(isempty(get(editoutputname_h,'string')))
        handles = guidata(hObject);
        GUI_TEMPLATE.num_synth_channels =  GUI_TEMPLATE.num_synth_channels+1;
        cur_label = GUI_TEMPLATE.EDF.labels{cur_channel_index};
        set(menuchannels_h,'enable','inactive');
        new_label = [cur_label,'_synth',num2str(GUI_TEMPLATE.num_synth_channels)];
        set(editoutputname_h,'string',new_label);
        
        %adjust all popupmenu selection data/strings for changed EDF labels
        GUI_TEMPLATE.EDF.labels{end+1} = new_label;
        set(...
            findobj(handles.figure1,'-regexp','tag','.*channel.*'),...
            'string',GUI_TEMPLATE.EDF.labels);
    end
end

function update_view(handles)
%update whether the image option is available for selection or not based on
%batch_process settings which can be changed and update

global GUI_TEMPLATE;
image_checkboxes = [findobj(handles.panel_events,'-regexp','tag','images');findobj(handles.panel_artifact,'-regexp','tag','images')];

img_h = [handles.text_artifact_export_img;handles.text_event_export_img;image_checkboxes];

if(handles.user.BATCH_PROCESS.images.save2img)
    set(img_h,'enable','on');
    GUI_TEMPLATE.check_save_image.enable = 'on';
else
    set(img_h,'enable','off','value',0);
    GUI_TEMPLATE.check_save_image.enable = 'off';
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global MARKING;
global BATCH_PROCESS;
BATCH_PROCESS = handles.user.BATCH_PROCESS; %need to return this to the global for now 
% in order to save settings between use.
try
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
    
