function varargout = batch_roc_viewer(varargin)
% BATCH_ROC_VIEWER M-file for batch_roc_viewer.fig
%      BATCH_ROC_VIEWER, by itself, creates a new BATCH_ROC_VIEWER or raises the existing
%      singleton*.
%
%      H = BATCH_ROC_VIEWER returns the handle to a new BATCH_ROC_VIEWER or the handle to
%      the existing singleton*.
%
%      BATCH_ROC_VIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BATCH_ROC_VIEWER.M with the given input arguments.
%
%      BATCH_ROC_VIEWER('Property','Value',...) creates a new BATCH_ROC_VIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before batch_roc_viewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to batch_roc_viewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help batch_roc_viewer

% Last Modified by GUIDE v2.5 12-Aug-2011 10:43:10

%written by Hyatt Moore, IV (< 12-Aug-2011)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @batch_roc_viewer_OpeningFcn, ...
                   'gui_OutputFcn',  @batch_roc_viewer_OutputFcn, ...
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


% --- Executes just before batch_roc_viewer is made visible.
function batch_roc_viewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to batch_roc_viewer (see VARARGIN)
global DEFAULTS;
global MAX_NUM_PARAMS;
MAX_NUM_PARAMS = 7;
% Choose default command line output for batch_roc_viewer
handles.output = hObject;

if(isfield(DEFAULTS,'batch_folder'))
    default_dir = DEFAULTS.batch_folder;
else
    default_dir = pwd;
end

if(exist(fullfile(default_dir,'output'),'dir'))
    default_dir = fullfile(default_dir,'output');
end

if(exist(fullfile(default_dir,'roc'),'dir'))
    default_dir = fullfile(default_dir,'roc');
end
handles.user.directory = default_dir;
set(handles.axes1,'box','on','xlimmode','manual','ylimmode','manual');

handles.text_keys = flipud(findobj(handles.pan_params,'style','text'));
handles.pop_values = flipud(findobj(handles.pan_params,'style','popupmenu'));

set(handles.list_id,'enable','off','min',0,'max',2); %make this multiselectable
set(handles.list_study,'enable','off');
set(handles.text_keys,'string','Key','enable','off');
set(handles.pop_values,'string','Value','enable','off','callback',@pop_values_Callback);
set(handles.check_number,'enable','off');
set(handles.check_cluster,'enable','off');
set(handles.check_qroc,'enable','off');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes batch_roc_viewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = batch_roc_viewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on selection change in list_study.
function list_study_Callback(hObject, eventdata, handles)
% hObject    handle to list_study (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_study contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_study
cur_id = get(handles.list_id,'value');

if(numel(cur_id)==1)

    cur_study = get(hObject,'value');
    
    
    study_config_index = (cur_study-1)*handles.user.num_ids+cur_id;
    rocStruct = handles.user.rocStruct;
    % roc_struct.config - unique id for each parameter combination
    % roc_struct.truth_algorithm = algorithm name for gold standard
    % roc_struct.estimate_algorithm = algorithm name for the estimate
    % roc_struct.study - edf filename
    % roc_struct.Q    - confusion matrix (2x2)
    % roc_struct.FPR    - false positive rate (1-specificity)
    % roc_struct.TPR   - true positive rate (sensitivity)
    % roc_struct.ACC    - accuracy
    % roc_struct.values   - parameter values
    % roc_struct.key_names - key names for the associated values
    
    
    fpr = rocStruct.FPR(study_config_index);
    tpr = rocStruct.TPR(study_config_index);
    acc = rocStruct.ACC(study_config_index);
    
    fpr = num2str(fpr);
    tpr = num2str(tpr);
    acc = num2str(acc);
    
    opt = '?';
    enable = 'on';
else
    enable = 'inactive';
    fpr = 'n/a';
    tpr = 'n/a';
    acc = 'n/a';
    
    opt = '?';
end
    set(handles.edit_fpr,'string',fpr,'enable',enable);
    set(handles.edit_tpr,'string',tpr,'enable',enable);
    set(handles.edit_acc,'string',acc,'enable',enable);
    set(handles.edit_opt,'string',opt,'enable',enable);


% --- Executes on button press in check_cluster.
function check_cluster_Callback(hObject, eventdata, handles)
% hObject    handle to check_cluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_cluster
marker_handles = findall(handles.axes1,'tag','marker');
rectangle_handles = findall(handles.axes1,'type','rectangle');

Q_data = get(marker_handles,'userdata');
% if(numel(marker_handles)==1)
%     if(~iscell(Q_data))
%         Q_data = {Q_data};
%     else
%         Q_data = {{Q_data}};
%     end
% end;

for cur_index=1:numel(marker_handles)
    
%     if(numel(marker_handles)==1 && ~iscell(Q_data))
%         Q_data = {Q_data};
%     end;
%     Q = reshape(cell2mat(Q_data{cur_index}{1}'),2,2,[]); %transform into 2x2xN matrix

%     Q = d_data;
%     TP = Q(1,1,:);
%     FP = Q(1,2,:);
%     FN = Q(2,1,:);
%     TN = Q(2,2,:);
    
    Q = Q_data;    %  Q = [TP,FN,FP,TN]; 
    TP = Q(:,1);
    FP = Q(:,2);
    FN = Q(:,3);
    TN = Q(:,4);

    P = TP+FN;
    N = FP+TN;
    
    %avoid divide by zero
    N = max(N,1);
    P = max(P,1);
    
    FPR = FP./N; %or 1 - [TN/total/(1-prevalence)]
    TPR = TP./P; %or TP/total/prevalence

    total = sum(sum(Q,1),2);
    quality = (TP+FP)./total;
    prevalence =  (TP+FN)./total;

    efficiency = (TP+TN)./total;
%     quality = P.*TPR+N.*(1-FPR);
%     quality = P.*TP./P+N.*(1-FP./N)
%    quality = TP+N-FP;

%     K_0_0 = (1-FPR-(1-Q))./Q;
%     K_0_0 = (1-FPR-1+Q)./Q;
%     K_0_0 = (-FPR+Q)./Q;
%     K_0_0 = (Q-FPR)./Q;
%     K_0_0 = Q./Q-FPR./Q;
    K_0_0 = 1-FPR./quality;
%     K_0_0 = 1-(FP./N)./quality;
%     K_0_0 = 1-FPR./(P.*TPR+N.*(1-FPR));
    K_1_0 = (TPR-quality)./(1-quality);
        

    %if need to cluster...
    if(get(hObject,'value'))
        TP_sum = sum(TP);
        FP_sum = sum(FP);
        FN_sum = sum(FN);
        TN_sum = sum(TN);
        total_sum = sum(total);
        
        P_sum = TP_sum+FN_sum;
        N_sum = FP_sum+TN_sum;
        FPR_mean = FP_sum/N_sum;
        TPR_mean = TP_sum/P_sum;
        
        quality_mean = (TP_sum+FP_sum)/total_sum;
        K_0_0_mean = 1-FPR_mean/quality_mean;
        K_1_0_mean = (TPR_mean-quality_mean)/(1-quality_mean);
        
        if(get(handles.check_qroc,'value'))
            x = K_0_0_mean;
            y = K_1_0_mean;
            
            %a weighted standard deviation
            K_0_0_w = N/N_sum;  %may need to weight these based on quality instead or in addition too
            K_1_0_w = P/P_sum;
            std_K_0_0 = sqrt(sum(K_0_0_w.*(K_0_0-K_0_0_mean).^2));
            std_K_1_0 = sqrt(sum(K_1_0_w.*(K_1_0-K_1_0_mean).^2));
            
            w = 3*std_K_0_0;
            h = 3*std_K_1_0;

        else
            x = FPR_mean;
            y = TPR_mean;
            
            FPR_w = N/N_sum;
            TPR_w = P/P_sum;
            std_FPR = sqrt(sum(FPR_w.*(FPR-FPR_mean).^2));
            std_TPR = sqrt(sum(TPR_w.*(TPR-TPR_mean).^2));
            
            w = 3*std_FPR;
            h = 3*std_TPR;

        end
        
        
        if(w>0 && h>0)
            set(rectangle_handles(cur_index),'visible','on','position',[x-w/2,y-h/2,w,h]);
        else
            set(rectangle_handles(cur_index),'visible','off');
        end        
    else
        if(get(handles.check_qroc,'value'))
            x = K_0_0;
            y = K_1_0;
            
            
        else
            x = FPR;
            y = TPR;
        end
        
        set(rectangle_handles(cur_index),'visible','off');

    end

    
    set(marker_handles(cur_index),'xdata',x,'ydata',y);

end



% --- Executes on button press in check_number.
function check_number_Callback(hObject, eventdata, handles)
% hObject    handle to check_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_number
text_handles = findall(handles.axes1,'tag','number');
marker_handles = findall(handles.axes1,'tag','marker');
if(get(hObject,'value'))
    x = get(marker_handles,'xdata');
    if(iscell(x))
        x = cell2mat(x);
    end
    y = get(marker_handles,'ydata');
    if(iscell(y))
        y = cell2mat(y);
    end
    for x_ind = 1:numel(x)
        set(text_handles(x_ind),'position',[x(x_ind)-0.005 y(x_ind)],'string',num2str(x_ind),'visible','on');
    end
    
%     set(text_handles,'visible','on');
    set(marker_handles,'visible','off');
%     legend(handles.axes1,'hide');
else
    set(text_handles,'visible','off');
    set(marker_handles,'visible','on');
%     legend(handles.axes1,'show');
end;


% --- Executes on button press in push_select_file.
function push_select_file_Callback(hObject, eventdata, handles)
% hObject    handle to push_select_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
suggested_filename = 'ROC*.txt';

[filename,pathname]=uigetfile({suggested_filename,'ROC Flat Database';...
    '*.*','All Files (*.*)'},'ROC Database Finder',...
    handles.user.directory);
if(filename~=0)
    handles.user.directory = pathname;
    filename = fullfile(pathname,filename);
    handles.user.rocStruct = CLASS_events_container.loadROCdata(filename);
    handles = setupGUI(handles);
    list_id_Callback(handles.list_id,[],handles);
end;

guidata(hObject,handles);

% --- Executes on selection change in list_id.
function list_id_Callback(hObject, eventdata, handles)
% hObject    handle to list_id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_id contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_id
selection = get(hObject,'value');
values = handles.user.parameter_indices(selection,:);
if(numel(selection)==1)

    set([handles.check_cluster,handles.check_number],'enable','on');
    for k=1:size(values,2)
        set(handles.pop_values(k),'value',values(k),'enable','on');    
    end
else
    set([handles.check_cluster,handles.check_number],'enable','off','value',0);

    for k=1:size(values,2)    
        set(handles.pop_values(k),'enable','off');
    end
end

updatePlot(handles);


%Popup menu callback
function pop_values_Callback(hObject,eventdata)
handles = guidata(hObject);
values = handles.user.parameter_indices;
parameter_selection = get(handles.pop_values(1:size(values,2)),'value');
num_params = numel(parameter_selection);

if(num_params==1)
    selection = parameter_selection;
else
    selection_matrix = cell2mat(parameter_selection);
    selection = find(ismember(values,selection_matrix(:)','rows'));
end

set(handles.list_id,'value',selection);
updatePlot(handles);



function handles = setupGUI(handles)
%initialize GUI based on recently loaded roc file
global MAX_NUM_PARAMS;
rocStruct = handles.user.rocStruct;
% roc_struct.config - unique id for each parameter combination
% roc_struct.truth_algorithm = algorithm name for gold standard
% roc_struct.estimate_algorithm = algorithm name for the estimate
% roc_struct.study - edf filename
% roc_struct.Q    - confusion matrix (2x2)
% roc_struct.FPR    - false positive rate (1-specificity)
% roc_struct.TPR   - true positive rate (sensitivity)
% roc_struct.ACC    - accuracy
% roc_struct.values   - parameter values
% roc_struct.key_names - key names for the associated values
unique_ids = unique(rocStruct.config);
handles.user.num_ids = numel(unique_ids);
set(handles.list_id,'string',num2str(unique_ids),'value',1,'listboxtop',1);
set(handles.list_study,'string',unique(rocStruct.study));
set(handles.text_filename,'string',[rocStruct.truth_algorithm,'(TRUTH) VS ',rocStruct.estimate_algorithm]);

set(handles.list_id,'enable','on');
set(handles.list_study,'enable','on');
set(handles.check_number,'enable','on');
set(handles.check_cluster,'enable','on');
set(handles.check_qroc,'enable','on');


set(handles.text_keys,'visible','off');
set(handles.pop_values,'visible','off');
key_names = rocStruct.key_names;
handles.user.num_params = min(numel(key_names),MAX_NUM_PARAMS);
parameter_indices = zeros(handles.user.num_ids,handles.user.num_params);

%for each key available,
% 1. find the unique set of parameters it can take
% 2. fill those parameters into the popup string
% 3. fill the parameter indices table with the popup value indices for the 
% matching parameter values
%This can then be used to query the database quicker
% 1. the rows represent the configuration id
% 2. the columns represent the keys that are available
% 3. the contents represent the index into the popup menu of that key which
% holds a string array of the unique values available.
for k = 1:handles.user.num_params
   set(handles.text_keys(k),'visible','on','enable','on','string',key_names{k});
   values = rocStruct.values{k}(1:numel(unique_ids));
   unique_values = unique(values);
   set(handles.pop_values(k),'visible','on','enable','on','string',num2str(unique_values,'%0.02f'));
   for j=1:numel(unique_values)
      parameter_indices(unique_values(j)==values,k)=j; 
   end
end

handles.user.parameter_indices = parameter_indices;


function updatePlot(handles)
%updates the GUI based on selection parameters of the gui and
%handles.user.rocStruct
rocStruct = handles.user.rocStruct;

%retrieves the configuration ID
selection_value = rocStruct.config(get(handles.list_id,'value'));

cla(handles.axes1);
qROC = get(handles.check_qroc,'value');

num_selections = numel(selection_value);

%removed this case...

% if(num_selections==1)
%     
%     
%     %retrieves the indices for the studies with the given configuration ID;
%     selection_indices = rocStruct.config==selection_value;
%     
%     
%     
%      drawROC(rocStruct.Q(selection_indices,:),rocStruct.FPR(selection_indices),...
%          rocStruct.TPR(selection_indices),handles.axes1,rocStruct.estimate_algorithm,qROC);
%     
%     
% 
%     check_cluster_Callback(handles.check_cluster, [], handles);
%     check_number_Callback(handles.check_number,[],handles);
if(false)
else
    
    Q = zeros(num_selections,4);
%     FPR = cell(num_selections,1);
%     TPR = cell(num_selections,1);
%     K_1_0 = cell(num_selections,1);
%     K_0_0 = cell(num_selections,1);
    
    for k=1:numel(selection_value)
        selection_indices = rocStruct.config==selection_value(k);
        cur_Q = sum(rocStruct.Q(selection_indices,:),1);  %[TP,FN,FP,TN]
        
        Q(k,:) = cur_Q/sum(cur_Q); %normalize to zero here...
        
%         [TPR{k}, FPR{k}, K_1_0{k}, K_0_0{k}] = confusion2roc(cur_Q);

        
        
%         drawROC(Q,FPR,TPR,handles.axes1,rocStruct.estimate_algorithm,qROC);
        
        
    end
    drawQROC = qROC;
    plotROC(Q,handles.axes1,drawQROC);
    
    
end

random_line_h = findall(handles.axes1,'tag','random_line');

if(get(handles.check_qroc,'value'))
    set(random_line_h,'ydata',[1 0]);
    xlabel(handles.axes1,'\kappa(0,0) (Quality of specificity)');
    ylabel(handles.axes1,'\kappa(1,0) (Quality of sensitivity)');
else
    set(random_line_h,'ydata',[0 1]);
    xlabel(handles.axes1,'False Positive Rate (1 - Specificity)');
    ylabel(handles.axes1,'True Positive Rate (Sensitivity)');
end

list_study_Callback(handles.list_study,[],handles);


% --- Executes on button press in check_qroc.
function check_qroc_Callback(hObject, eventdata, handles)
% hObject    handle to check_qroc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_qroc
updatePlot(handles);


% --- Executes on selection change in pop_value7.
function pop_value7_Callback(hObject, eventdata, handles)
% hObject    handle to pop_value7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_value7 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_value7


% --- Executes during object creation, after setting all properties.
function pop_value7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_value7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
