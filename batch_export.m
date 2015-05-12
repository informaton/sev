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

%if MARKING is not initialized, then call sev.m with 'init_batch_Export' argument in
%order to initialize the MARKING global before returning here.
debugMode = true;

if(isempty(MARKING) && ~debugMode)
    %     sev('init_batch_export'); %runs the sev first, and then goes to the default batch export callback.
    sev('init_batch_export');
else

    %have to assign user data to the button that handles multiple channel
    %sourcing
    if(debugMode)
        handles.user.exportInfFullFilename = '/Users/hyatt4/git/sev/+export/export.inf';

    end
    
    handles.user.methodsStruct = CLASS_batch.getExportMethods(handles.user.exportInfFullFilename);
    guidata(hObject,handles);
    
    initializeSettings(hObject);
    initializeCallbacks(hObject)
    

    edfPath = pwd;
    updateGUI(CLASS_batch.checkPathForEDFs(edfPath),handles); 
   

    % Update handles structure
    guidata(hObject, handles);
    
    %bring this to the front...
    

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
        handles.push_method_settings
        handles.menu_export_method],'enable','off');
    set(handles.menu_export_method,'string',handles.user.methodsStruct.description,'value',1);
    
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
    set(handles.push_start,'callback',{@push_start_Callback,guidata(hObject)});
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
varargout{1} = handles;

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
    updateGUI(edfPathStruct,handles);
end


function updateGUI(edfPathStruct,handles)
  set(handles.text_edfs_to_process,'string',edfPathStruct.statusString); 
  relevantHandles = [handles.push_start
      handles.text_edfs_to_process
      get(handles.panel_exportMethods,'children')];
  if(~isempty(edfPathStruct.edf_filename_list))
      set(relevantHandles,'enable','on');
      
      set(handles.edit_edf_directory,'enable','inactive');
      
      % have/may not implemented this yet.
      set(handles.push_add_method,'enable','off');
      
  else
      set(relevantHandles,'enable','off');
  end
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
%This function grabs the entries from the GUI and puts them into a settings
%struct which is then passed to the export function.
    exportSettings = getExportSettings(handles);
    
    process_export(edfPath,exportSettings);
end


function exportSettings = getExportSettings(handles)
    method_selection_index = get(handles.menu_export_method,'value');
    methodFields = fieldnames(handles.user.methodsStruct);
    for m=1:numel(methodFields)
       fname = methodFields{m};
       methodStruct.(fname) = handles.user.methodsStruct.(fname){method_selection_index};
    end
    channelSelection.all = get(radio_channels_all,'value');
    
    exportSettings.methodStruct = methodStruct;
    exportSettings.edfPath = get(handles.edit_edf_directory,'string');
end

%> @brief This method controls the batch export process according to the
%> settings provided.
%> @param exportSettings is a struct with the following fields
%> - @c methodStruct
%> -- @c mfilename
%> -- @c description
%> -- @c settings
%> - @c channel_selection
%> -- @c all True/False If true, then load all channels for each file.
%> (Optional, Default is True).
%> -- @c sources Cell of channel labels to use if @c all is false.
%> @param playList Optional Px1 cell of EDF filenames (not full filenames) to
%> process from edfPath instead of using all .EDF files found in edfPath.
function process_export(edfPath,exportSettings, channel_selection, playList)
    
    if(nargin<4)
        playList = [];
        if(nargin<3 || isempty(channel_selection))
            channel_selection.all = true;
        end
    end
    edfSelectionStruct = CLASS_batch.checkPathForEDFs(edfPath);
    edf_fullfilenames = edfSelectionStruct.edf_full_filenames;
    file_count = numel(edf_fullfilenames);
    if(file_count>0)
        waitbarH = waitbar(0,sprintf('%s\n\tInitializing',edfSelectionStruct.statusMessage),'name','Batch Export','resize','on','createcancelbtn',@cancel_batch_Callback,'tag','waitbarH');
        set(findall(waitbarH,'interpreter','tex'),'interpreter','none');
        
        waitbarPos = get(waitbarH,'position');
        waitbarPos(4)=waitbarPos(4)*1.5;
        set(waitbarPos,'position',waitbarPos);
        files_attempted = zeros(size(edf_fullfilenames));
        files_failed = files_attemtped;
        files_skipped = files_attempted;
        for i=1:file_count
            try
                cur_edf_fullfilename = edf_fullfilenames{i};
                [stages_filename, cur_edf_name] = CLASS_code.getStageFilenameFromEDF(cur_edf_fullfilename);
                files_attempted(i)=1;
                
                
                %require stages filename to exist.                
                if(isempty(stages_filename) || ~exist(stages_filename,'file'))
                    files_skipped(i) = true;
                    
                    %%%%%%%%%%%%%%%%%%%%%REVIEW%%%%%%%%%%%%%%%%%%%%%%%%
%                     if(BATCH_PROCESS.output_files.log_checkbox)
%                         fprintf(log_fid,'%s not found!  This EDF will be skipped.\r\n',stages_filename);
%                     end;

                else
                    HDR = loadEDF(cur_edf_fullfilename);
                    if(exportSettings.all_channels)
                        
                    else
                        fprintf('Not implemented yet\n');
                    end
                    stagesStruct = CLASS_code.loadSTAGES(stages_filename,studyInfo.num_epochs);
                    
                end; 
                
                
            catch me
                showME(me);
                files_failed(i) = 1;
            end
            
        end
        
        
    else
        warndlg(sprintf('The check for EDFs in the following directory failed!\n\t%s',edfPath));
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
% in order to save settings between use.
delete(hObject);
    
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


