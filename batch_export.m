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
    
    checkPathForEDFs(handles); %Internally, this calls getPlayList since no argument is given.
    
    
    
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
    set([handles.push_add_method;
        handles.push_method_settings],'enable','off');
    
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
    
end







function edit_edf_directory_Callback(hObject, eventdata, handles)
% hObject    handle to edit_edf_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkPathForEDFs(handles);

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


global GUI_TEMPLATE;
global MARKING;

BATCH_PROCESS = handles.user.BATCH_PROCESS;

% BATCH_PROCESS.output_files.MUSIC_filename = 'MUSIC'; %already set in the
% _sev.parameters.txt
EDF_labels = GUI_TEMPLATE.EDF.labels;
export_inf = GUI_TEMPLATE.export;

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

%grab the event export paramaters

% This is the indices of the event method(s) selected from the event method
% drop down widget.  One value per event 
event_method_values = get(flipud(findobj(handles.panel_exportMethods,'-regexp','tag','method')),'value');

event_channel1_values = get(flipud(findobj(handles.panel_exportMethods,'-regexp','tag','channel1')),'value');
event_channel2_values = get(flipud(findobj(handles.panel_exportMethods,'-regexp','tag','channel2')),'value');

%obtain the userdata and value fields of the multichannel source button.
event_multichannel_data = get(flipud(findobj(handles.panel_exportMethods,'tag','buttonEventSelectSources')),'userdata');
event_multichannel_value = get(flipud(findobj(handles.panel_exportMethods,'tag','buttonEventSelectSources')),'value');

event_settings_handles = flipud(findobj(handles.panel_exportMethods,'-regexp','tag','settings'));
event_save_image_choices = get(flipud(findobj(handles.panel_exportMethods,'-regexp','tag','images')),'value');

% convert from cell structures where needed.
if(iscell(event_settings_handles))
    event_settings_handles = cell2mat(event_settings_handles);
end
if(iscell(event_method_values))
    event_method_values = cell2mat(event_method_values);
    
    event_channel1_values = cell2mat(event_channel1_values);
    event_channel2_values = cell2mat(event_channel2_values);
    
    event_multichannel_data = cell2mat(event_multichannel_data);
    event_multichannel_value = cell2mat(event_multichannel_value);
    
    event_save_image_choices = cell2mat(event_save_image_choices);
end


% The user can select 'none' for an event.  We want to remove these.
selected_events = event_method_values>1;
event_method_values = event_method_values(selected_events);
event_settings_handles = event_settings_handles(selected_events);
event_channel_values = [event_channel1_values(selected_events),event_channel2_values(selected_events)];
event_save_image_choices = event_save_image_choices(selected_events);

event_multichannel_data = event_multichannel_data(selected_events);
event_multichannel_value = event_multichannel_value(selected_events);

num_selected_events = sum(selected_events);
event_settings = cell(num_selected_events,1);

for k = 1:num_selected_events
    selected_method = event_method_values(k);
    num_reqd_channels = export_inf.reqd_indices(selected_method);
    eventStruct.numConfigurations = 1;
    eventStruct.save2img = event_save_image_choices(k);

    %if we are using a multiple channel sourced event method
    if(event_multichannel_value(k))
        eventStruct.channel_labels = EDF_labels(event_multichannel_data(k).selectedIndices);        
    else
        eventStruct.channel_labels = EDF_labels(event_channel_values(k,1:num_reqd_channels));
    end
    
    eventStruct.channel_configs = cell(size(eventStruct.channel_labels));
    
    %check to see if we are using a synthesized channel so we can audit it
    if(~isempty(BATCH_PROCESS.synth_CHANNEL.names))
        for ch=1:numel(eventStruct.channel_labels)
           eventStruct.channel_configs{ch}  = BATCH_PROCESS.synth_CHANNEL.structs(strcmp(eventStruct.channel_labels{ch},BATCH_PROCESS.synth_CHANNEL.names));  %insert the corresponding synthetic channel where applicable

%           This was commented out on 7/12/2014->
%           channel_config = BATCH_PROCESS.synth_CHANNEL.structs(strcmp(eventStruct.channel_labels{ch},BATCH_PROCESS.synth_CHANNEL.names));  %insert the corresponding synthetic channel where applicable
%           This was found commented out on 7/12/2014->
%            if(~isempty(channel_config))
%                 channel_config = channel_config{1};
%                 channel_config.channel_label = eventStruct.channel_labels{ch};
%                eventStruct.channel_configs{ch} = channel_config;
%            end
        end
    end
    
    eventStruct.method_label = export_inf.labels{selected_method};
    eventStruct.method_function = export_inf.mfile{selected_method};
    eventStruct.batch_mode_label = char(export_inf.batch_mode_label{selected_method});
    settings_userdata = get(event_settings_handles(k),'userdata');
    eventStruct.pBatchStruct = settings_userdata.pBatchStruct;
    eventStruct.rocStruct = settings_userdata.rocStruct;
    params = [];
    
    % may not work on windows platform....
    % if there is a change to the settings in the batch mode, then make sure
    % that the change occurs here as well
    if(~isempty(eventStruct.pBatchStruct))
        for p=1:numel(eventStruct.pBatchStruct)
           params.(eventStruct.pBatchStruct{p}.key) =  eventStruct.pBatchStruct{p}.start;
        end
    else
        pfile = ['+export/',eventStruct.method_function,'.plist'];
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

%grab the artifact export paramaters
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
    num_reqd_channels = export_inf.reqd_indices(selected_method);

    artifactStruct.save2img = artifact_save_image_choices(k);
    artifactStruct.channel_labels = EDF_labels(artifact_channel_values(k,1:num_reqd_channels));
    artifactStruct.method_label = export_inf.labels{selected_method};
    artifactStruct.method_function = export_inf.mfile{selected_method};
    artifactStruct.batch_mode_label = char(export_inf.batch_mode_label{selected_method});
    
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
%         pfile = ['+export/',artifactStruct.method_function,'.plist'];
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
playlist = getPlaylist(handles); 
batch_process(pathname,BATCH_PROCESS,playlist);
% warndlg({'you are starting the batch mode with the following channels',BATCH_PROCESS.PSD_settings});

%goal two - run the batch mode with knowledge of the PSD channel only...
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



%%%%%%%%%%%%%%%%%%%%%%%%%%
function batch_process(pathname, BATCH_PROCESS,playlist)
end
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
    
end;

guidata(hObject,handles);
end

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
end


% --- Executes on button press in push_add_CHANNEL.
function push_add_CHANNEL_Callback(hObject, eventdata, handles)
% hObject    handle to push_add_CHANNEL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addCHANNELRow(handles);
end


% --- Executes on selection change in edit_synth_CHANNEL_name.
function edit_synth_CHANNEL_name_Callback(hObject, eventdata, handles)
% hObject    handle to edit_synth_CHANNEL_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns edit_synth_CHANNEL_name contents as cell array
%        contents{get(hObject,'Value')} returns selected item from edit_synth_CHANNEL_name
end

function synthesize_CHANNEL_configuration_callback(hObject,eventdata,menuchannels_h,editoutputname_h)
%enter the configuration parameters for the specified channel...
global GUI_TEMPLATE;

settings = get(hObject,'userdata');
cur_channel_index = get(menuchannels_h,'value');

[settings, noneEventIndices] = prefilter_dlg(GUI_TEMPLATE.EDF.labels{cur_channel_index},settings);
settings(noneEventIndices) = [];


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
function menu_playlist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menu_playlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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


% --- Executes when selected object is changed in bg_panel_playlist.
function bg_panel_playlist_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in bg_panel_playlist 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if(eventdata.NewValue==handles.radio_processList)
    playlist = getPlaylist(handles);
    if(isempty(playlist))
        playlist = getPlaylist(handles,'-gui');
    end
    handles.user.playlist = playlist;
    checkPathForEDFs(handles,handles.user.playlist);
    guidata(hObject,handles);
    
end
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over edit_selectPlayList.
function edit_selectPlayList_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to edit_selectPlayList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[playlist,ply_filename] = getPlaylist(handles,'-gui');

handles.user.playlist = playlist;
checkPathForEDFs(handles,handles.user.playlist);
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
