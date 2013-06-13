function varargout = roc_dlg(varargin)
% ROC_DLG M-file for roc_dlg.fig
%      ROC_DLG, by itself, creates a new ROC_DLG or raises the existing
%      singleton*.
%
%      H = ROC_DLG returns the handle to a new ROC_DLG or the handle to
%      the existing singleton*.
%
%      ROC_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROC_DLG.M with the given input arguments.
%
%      ROC_DLG('Property','Value',...) creates a new ROC_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before roc_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to roc_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% written by: Hyatt Moore IV (< June, 2013)
% Edit the above text to modify the response to help roc_dlg

% Last Modified by GUIDE v2.5 07-Jul-2011 10:13:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @roc_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @roc_dlg_OutputFcn, ...
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

% --- Executes just before roc_dlg is made visible.
function roc_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to roc_dlg (see VARARGIN)

% Choose default command line output for roc_dlg
handles.output = hObject;

default_dir = '/Users/hyatt4/Documents/Sleep Project/Data/events';

%uncomment for release to others
%default_dir = pwd;
set(handles.text_dir,'string',default_dir);
fillListBoxes(default_dir,handles);
set(handles.axes1,'box','on','xlimmode','manual','ylimmode','manual');
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes roc_dlg wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = roc_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in list_tru.
function list_tru_Callback(hObject, eventdata, handles)
% hObject    handle to list_tru (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_tru contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_tru


% --- Executes during object creation, after setting all properties.
function list_tru_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_tru (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in list_est.
function list_est_Callback(hObject, eventdata, handles)
% hObject    handle to list_est (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_est contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_est


% --- Executes during object creation, after setting all properties.
function list_est_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_est (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in list_art.
function list_art_Callback(hObject, eventdata, handles)
% hObject    handle to list_art (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_art contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_art


% --- Executes during object creation, after setting all properties.
function list_art_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_art (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in push_dir.
function push_dir_Callback(hObject, eventdata, handles)
% hObject    handle to push_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cur_path = get(handles.text_dir,'string');
dirname = uigetdir(cur_path,'Select Root Directory');
if(dirname) %uigetdir returns 0 on user cancelation
    set(handles.text_dir,'string',dirname);
    
    fillListBoxes(dirname,handles)
   
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over push_dir.
function push_dir_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to push_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function fillListBoxes(dirname,handles)
%popuplate the listboxes with events found at dirname - if any

%% Process handles.list_tru
files = dir(fullfile(dirname,'truth'));
if(numel(files)>0)
    files_c = cell(numel(files),1);
    [files_c{:}] = files(:).name;
%     evt=cell2mat(regexp(files_c,'evt\..+\.(?<channel>[^\.]+)\.(?<suffix>.+)','names'));
    evt=cell2mat(regexp(files_c,'evt\..+\.(?<suffix>([^\.]\.+)?.+)','names'));
    suffix_c = cell(numel(evt),1);
    [suffix_c{:}]=evt(:).suffix;
    listbox_true_items = unique(suffix_c);
    set(handles.list_tru,'string',listbox_true_items);
else
    set(handles.list_tru,'string','');
end

%% Process handles.list_est - the estimates
% files = dir(fullfile(dirname,'estimates'));
files = dir(fullfile(dirname,'all'));
if(numel(files)>0)
    files_c = cell(numel(files),1);
    [files_c{:}] = files(:).name;
%     evt=cell2mat(regexp(files_c,'evt\..+\.(?<channel>[^\.]+)\.(?<suffix>.+)','names'));
    evt=cell2mat(regexp(files_c,'evt\..+\.(?<suffix>([^\.]\.+)?.+)','names'));
    suffix_c = cell(numel(evt),1);
    [suffix_c{:}]=evt(:).suffix;
    listbox_est_items = unique(suffix_c);
    set(handles.list_est,'string',listbox_est_items);
else
    set(handles.list_est,'string','');
end

%% Process handles.list_art - the artifacts
files = dir(fullfile(dirname,'artifacts'));
if(numel(files)>0)
    files_c = cell(numel(files),1);
    [files_c{:}] = files(:).name;
%     evt=cell2mat(regexp(files_c,'evt\..+\.(?<suffix>.+)','names'));
    evt=cell2mat(regexp(files_c,'evt\..+\.(?<suffix>([^\.]\.+)?.+)','names'));
%     evt=cell2mat(regexp(files_c,'evt\..+\.(?<suffix>.+)','names'));
    suffix_c = cell(numel(evt),1);
    [suffix_c{:}]=evt(:).suffix;
    listbox_art_items = unique(suffix_c);
    set(handles.list_art,'string',{'NONE',listbox_art_items{:}});
else
    set(handles.list_art,'string','');
end

% --- Executes on button press in push_draw.
function push_draw_Callback(hObject, eventdata, handles)
% hObject    handle to push_draw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

rootdir = get(handles.text_dir,'string');

if(isdir(rootdir))
    truth_list = get(handles.list_tru,'string');
    truth_suffix = truth_list{get(handles.list_tru,'value')};
    
    %estimate remains a cell here, by design
    est_list = get(handles.list_est,'string');
    est_suffix = est_list(get(handles.list_est,'value'));
    
    art_list = get(handles.list_art,'string');
    art_suffix = art_list{get(handles.list_art,'value')};
    
    % Solve the confusion matrix for the selected events
    truth_filenames = dir(fullfile(rootdir,'truth',['*.',truth_suffix]));
    
    
    num_files = numel(truth_filenames);
    num_selected_estimates = numel(est_suffix);
    FPR = cell(num_selected_estimates,1);
    TPR = cell(num_selected_estimates,1);
    ACC = cell(num_selected_estimates,1);
    Q = cell(num_selected_estimates,1);
    beforeAfterMatrix = cell(num_selected_estimates,1); %number of events for actual and estimates before and after artifact removal (if any).
    for i = 1:num_selected_estimates
        FPR{i} = zeros(num_files,1);
        TPR{i} = zeros(num_files,1);
        ACC{i} = zeros(num_files,1);
        Q{i} = cell(num_files,1);
        beforeAfterMatrix{i} = zeros(num_files,4);
        
        %% takedown
        good_indices = true(num_files,1);
        disp('New detection');
        for k = 1:num_files
            
            true_events = load(fullfile(rootdir,'truth',truth_filenames(k).name),'-mat');
            field_names = fieldnames(true_events);
            
            true_events = true_events.(field_names{1});
            if(~issorted(true_events(:,1)))
                [~,ind]=sort(true_events(:,1));
                true_events = true_events(ind,:);
            end
            
            if(~isempty(true_events))
                predicted_event_name = regexp(truth_filenames(k).name,'(?<study>evt.[^\.]+.[^\.]+\.).+','names');
                predicted_event_filename = [predicted_event_name.study,est_suffix{i}];
                
%                 predicted_events = load(fullfile(rootdir,'estimates',predicted_event_filename),'-mat');
                predicted_events = load(fullfile(rootdir,'all',predicted_event_filename),'-mat');

                
                field_names = fieldnames(predicted_events);
            
                predicted_events = predicted_events.(field_names{1});
                if(~issorted(predicted_events(:,1)))
                    [~,ind]=sort(predicted_events(:,1));
                    predicted_events = predicted_events(ind,:);
                end
                
                if(~isempty(predicted_events))
                    %                 predicted_events = predicted_events.events;
                    
                    study_name = regexp(truth_filenames(k).name,'(?<study>evt.[^\.]+\.).+','names');
                    study_name = study_name.study;
                    if(~strcmpi(art_suffix,'NONE'))
                        artifacts = load(fullfile(rootdir,'artifacts',[study_name,art_suffix]),'-mat');
                        artifacts = artifacts.events;
                    else
                        artifacts = [];
                    end;
                    %     [score, event_space,sumAandB,sumAorB] = compareEvents(sw1_events,sev_bp_events,[sw1_events(1),sw1_events(end)]);
                    %     disp([sw1_filenames(k).name,' ',num2str(size(sw1_events,1)),' score ',num2str(score)]);
                    
                    comparison_range = [true_events(1),true_events(end)];
                    [Q{i}{k}, FPR{i}(k), TPR{i}(k), ACC{i}(k),beforeAfterMatrix{i}(k,:)] = confusionMatrix(true_events, predicted_events, comparison_range,artifacts);
              %      disp([predicted_event_filename,' TPR = ',num2str(TPR{i}(k)),' FPR = ',num2str(FPR{i}(k)),' ACC = ',num2str(ACC{i}(k))]);
                    
%                     disp([predicted_event_filename, num2str([beforeAfterMatrix{i}(k,:),TPR{i}(k),FPR{i}(k)],'%0.2f\t')]);
%                     disp([predicted_event_filename, num2str([beforeAfterMatrix{i}(k,:),TPR{i}(k),FPR{i}(k)],'%0.2f\t')]);
                    confusion =  Q{i}{k}';
                    N = sum(confusion(:));
                    TP = confusion(1,1)/N;
                    FP = confusion(2,1)/N;
                    TN = confusion(2,2)/N;
                    FN = confusion(1,2)/N;
                    P = TP+FN;
                    quality = TP+FP;
                    SE = TP/P;
                    SP = TN/(1-P);
                    K_0_0 = (SP-(1-quality))/quality;
                    K_1_0 = (SE-quality)/(1-quality);
                     disp([predicted_event_filename,' TPR = ',num2str(SE),' FPR = ',num2str(1-SP),' quality = ',num2str(quality),' K(1,0) = ',num2str(K_1_0),' K(0,0) = ',num2str(K_0_0)]);
%                      disp([predicted_event_filename,' TPR = ',num2str(SE),' FPR = ',num2str(1-SP),' quality = ',num2str(quality),' prevalence = ',num2str(P),' K(1,0) = ',num2str(K_1_0),' K(0,0) = ',num2str(K_0_0)]);
%                     disp([predicted_event_filename,' ',num2str(beforeAfterMatrix{i}(k,:)),' TPR = ',num2str(SE),' FPR = ',num2str(1-SP),' quality = ',num2str(quality),' K(1,0) = ',num2str(K_1_0),' K(0,0) = ',num2str(K_0_0)]);
                    
%                     TP = confusion(1,1);
%                     FP = confusion(2,1);
%                     TN = confusion(2,2);
%                     FN = confusion(1,2);
%                     P = TP+FN;
%                     N = FP+TN;
%                     quality = TP+FP;
%                     SE = TP/P;
%                     SP = TN/(1-P);
%                     K_0_0 = (SP-(1-quality))/quality;
%                     K_1_0 = (SE-quality)/(1-quality);
%                      disp([predicted_event_filename,' TPR = ',num2str(SE),' FPR = ',num2str(1-SP),' K(1,0) = ',num2str(K_1_0),' K(0,0) = ',num2str(K_0_0)]);

                else
                    disp([predicted_event_filename,' did not contain any events!']);
                    good_indices(k) = false;
                end
            else
                disp([truth_filenames(k).name,' did not contain any events!']);
                good_indices(k) = false;

            end;
            
        end
        Q{i} = Q{i}(good_indices);
        FPR{i} = FPR{i}(good_indices);
        TPR{i} = TPR{i}(good_indices);
        ACC{i} = ACC{i}(good_indices);
        
%         disp(['Average results: TPR = ',num2str(mean(TPR{i})),' FPR = ',num2str(mean(FPR{i})),' ACC = ',num2str(mean(ACC{i}))]);

    end
        cla(handles.axes1);
        drawROC(Q,FPR,TPR,handles.axes1,est_suffix);
        check_number_Callback(handles.check_number,eventdata,handles);
        check_cluster_Callback(handles.check_cluster, eventdata, handles);
end


% --- Executes on button press in check_cluster.
function check_cluster_Callback(hObject, eventdata, handles)
% hObject    handle to check_cluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_cluster
marker_handles = findall(handles.axes1,'tag','marker');
rectangle_handles = findall(handles.axes1,'type','rectangle');

Q_data = get(marker_handles,'userdata');
if(numel(marker_handles)==1)
    Q_data = {Q_data};
end;

for k=1:numel(marker_handles)
    Q = reshape(cell2mat(Q_data{k}{1}'),2,2,[]); %transform into 2x2xN matrix

    TP = Q(1,1,:);
    FP = Q(1,2,:);
    FN = Q(2,1,:);
    TN = Q(2,2,:);
    
    P = TP+FN;
    N = FP+TN;
    
    %avoid divide by zero
    N = max(N,1);
    P = max(P,1);
    
    FPR = FP./N;
    TPR = TP./P;

%     %handle the obscure cases...
%     FPR(isnan(FPR))=0;
%     TPR(isnan(TPR))=0;
    

    if(get(hObject,'value'))
        TP_sum = sum(TP);
        FP_sum = sum(FP);
        FN_sum = sum(FN);
        TN_sum = sum(TN);
        
        P_sum = TP_sum+FN_sum;
        N_sum = FP_sum+TN_sum;
        FPR_mean = FP_sum/N_sum;
        TPR_mean = TP_sum/P_sum;
        
        x = FPR_mean;
        y = TPR_mean;

        FPR_w = N/N_sum;
        TPR_w = P/P_sum;
        std_FPR = sqrt(sum(FPR_w.*(FPR-FPR_mean).^2));
        std_TPR = sqrt(sum(TPR_w.*(TPR-TPR_mean).^2));
        
        w = 3*std_FPR;
        h = 3*std_TPR;
        if(w>0 && h>0)
            set(rectangle_handles(k),'visible','on','position',[x-w/2,y-h/2,w,h]);
        else
            set(rectangle_handles(k),'visible','off');
        end        
    else

        x = FPR;
        y = TPR;
        
        set(rectangle_handles(k),'visible','off');

    end

    
    set(marker_handles(k),'xdata',x,'ydata',y);

    
end

% --- Executes on button press in check_number.
function check_number_Callback(hObject, eventdata, handles)
% hObject    handle to check_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_number
text_handles = findall(handles.axes1,'tag','number');
marker_handles = findall(handles.axes1,'type','line');
if(get(hObject,'value'))
    set(text_handles,'visible','on');
    set(marker_handles,'visible','off');
    legend(handles.axes1,'hide');
else
    set(text_handles,'visible','off');
    set(marker_handles,'visible','on');
    legend(handles.axes1,'show');
end;