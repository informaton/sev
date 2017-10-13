function detectStruct = screencapture_hypnogram(~,varargin)
%this serves as a batch mode for capturing hypnograms only
% screen shots are placded in MARKING.sev_screenshot_path if it exists, and
% the current working directory otherwise.
%
% format = 1 for .png
% format = 2 for .jpeg

%  Written Hyatt Moore, IV
%  1/16/2013
% modified 3/1/2013 - use varargin
global MARKING;
global BATCH_PROCESS;
global STATE;

updateHypnogram(MARKING);

%empty event data - not a detector
detectStruct.new_events = [];
detectStruct.paramStruct = [];
detectStruct.new_data = [];

filterspec = {'png','PNG';'jpeg','JPEG'};
save_format = {'-dpng','-djpeg'};

if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        params.format = 1; %1 is PNG, 2 is 
        plist.saveXMLPlist(pfile,params);
    end
end

img_pathname = pwd;
if(STATE.batch_process_running)
    img_pathname = fullfile(BATCH_PROCESS.output_path.current,BATCH_PROCESS.output_path.images);
    img_filename = strrep(BATCH_PROCESS.cur_filename,'.EDF','');
    img_filename = strrep(img_filename,'.edf','');
    img_filename = strcat(img_filename, whois(img_filename));
    
    
    
else
    if(isfield(MARKING.sev,'screenshot_path'))
        img_pathname = MARKING.sev.screenshot_path;        
    end
    img_filename = MARKING.sev.src_edf_filename;
end


save_format = save_format{params.format};
filterspec = filterspec{params.format,1};

img_filename = sprintf('hypnogram_%s.%s',img_filename,filterspec);


    try
        fig_h = MARKING.figurehandle.sev;
        axes_hypno_copy = copyobj(MARKING.axeshandle.timeline,fig_h);
%         axes_hypno_props = get(axes_hypno_copy);
%         text_h = strcmp(get(axes_hypno_props.Children,'type'),'text');
%         text_h = axes_hypno_props.Children(text_h);
%         
        %         apos = get(handles.axes1,'position');
        %         dataaspectratio = get(handles.axes1,'dataaspectratio');
        %         original_axes_settings = get(handles.axes1);
        %         f = figure('visible','off','paperpositionmode','auto','units',axes1_props.Units);
        f = figure('visible','off','paperpositionmode','auto',...
            'units',get(fig_h,'units'),'position',get(fig_h,'position'),...
            'toolbar','none','menubar','none');
        set(f,'units','normalized');
        set(axes_hypno_copy,'parent',f);
        
        cropFigure2Axes(f,axes_hypno_copy);

%         set(text_h,'Units','normalized');
%         
%         text_E = get(text_h,'extent');
%         pos_E = get(text_h,'position');
%         if(iscell(text_E))
%             text_E = cell2mat(text_E);
%             pos_E = cell2mat(pos_E);
%         end
%         max_E_width = max(text_E(:,3));
%         
%         for k=1:numel(text_h)
%             set(text_h(k),'position',[-text_E(k,3)-0.1*max_E_width,pos_E(k,2)]);
%         end
%         
%         
%         set(axes_hypno_copy,'Position',[max_E_width,(1-sum(axes_hypno_props.Position([2,4])))/2,1-max_E_width*1.1,sum(axes_hypno_props.Position([2,4]))])
%         
        set(f,'visible','on');
        set(f,'clipping','off');
        
        
        %         style = getappdata(f,'Exportsetup');
        %         if isempty(style)
        %             try
        %                 style = hgexport('readstyle','Default');
        %             catch me
        %                 style = hgexport('factorystyle');
        %             end
        %         end
        %         hgexport(f,fullfile(img_pathname,img_filename),style,'Format',filterspec{filterindex,1});
        print(f,save_format,'-r0',fullfile(img_pathname,img_filename));
        
        %save the screenshot
        %         print(f,['-d',filterspec{filterindex,1}],'-r75',fullfile(img_pathname,img_filename));
        %         print(f,fullfile(img_pathname,img_filename),['-d',filterspec{filterindex,1}]);
        %         print(f,['-d',filterspec{filterindex,1}],fullfile(img_pathname,img_filename));
        %         set(handles.axes1,'position',apos,'dataaspectratiomode','manual' ,'dataaspectratio',dataaspectratio,'parent',handles.sev_main_fig)
        delete(f);
        
        MARKING.sev.screenshot_path = img_pathname;
    catch ME
        showME(ME);
        %         set(handles.axes1,'parent',handles.sev_main_fig);
    end

end

function theyare = whois(patid)
openPTSD();
q= mym('select ptsdf, combat, curmddf from diagnostics_t where concat(patid,visitsequence)="{S}"',patid);
theyare = '';
if(q.combat==2)
    theyare = strcat(theyare,'_combat');
end
if(q.ptsdf==2)
    theyare = strcat(theyare,'_PTSD');
end

if(q.curmddf==2)
    theyare = strcat(theyare,'_MDD');
end
mym('close');
end

    
function updateHypnogram(MARKING)
hypno_axes = MARKING.axeshandle.timeline;
sev_STAGES = MARKING.sev_STAGES;
num_epochs = numel(sev_STAGES.line);

cla(hypno_axes);  %do this so I don't have to have transition line handles and sleep stage line handles, etc.

%show hypnogram and such
xticks = linspace(1,num_epochs,min(num_epochs,5));

set(hypno_axes,...
    'xlim',[0 num_epochs+1],... %add a buffer of one to each side of the x limit/axis
    'ylim',[0 10],...
    'xtick',xticks,...
    'xticklabel',MARKING.getTimestampAtSamplePt(xticks*MARKING.sev.standard_epoch_sec*MARKING.sev.samplerate,'HH:MM'));

ylim = get(hypno_axes,'ylim');

axes_buffer = 0.05;
upper_portion_height_percent = axes_buffer;
fontsize=10;

lower_portion_height_percent = 1-upper_portion_height_percent;
y_delta = abs(diff(ylim))*upper_portion_height_percent; %just want the top part - the +1 is to keep it in the range a little above and below the portion set aside for it

ylim(2) = ylim(2)-y_delta/2;


y_max = 10*lower_portion_height_percent;
adjustedStageLine = sev_STAGES.line;


%expect stages to be 0, 1, 2, 3, 4, 5, 6, 7
possible_stages = [7,6,5,4,3,2,1,0];
tick = linspace(0,y_max,numel(possible_stages));

for k=1:numel(tick)
    %                 adjustedStageLine(obj.sev_STAGES.line==possible_stages(k))=tick(k);
    adjustedStageLine(sev_STAGES.line==possible_stages(k))=tick(k);
end

cycle_y = tick(2); %put the cycle label where stage 6 might be shown
tick(2) = []; %don't really want to show stage 6 as a label
set(hypno_axes,...
    'ytick',tick,...
    'yticklabel','7|5|4|3|2|1|0','fontsize',fontsize);

%reverse the ordering so that stage 0 is at the top
x = 0:num_epochs-1;
x = [x;x+1;nan(1,num_epochs)];


y = [adjustedStageLine'; adjustedStageLine'; nan(1,num_epochs)]; %want three rows
line('xdata',x(:),'ydata',y(:),'color',[1 1 1]*.4,'linestyle','-','parent',hypno_axes,'linewidth',1.5,'hittest','off');

%update the vertical lines with sleep cycle information
adjustedStageCycles = sev_STAGES.cycles;
transitions = [0;find(diff(adjustedStageCycles)==1);numel(adjustedStageCycles)];

cycle_z = -0.5; %put slightly back
for k=3:numel(transitions)
    curCycle = k-2;
    cycle_x = floor(mean(transitions(k-1:k)));
    text('string',num2str(curCycle),'parent',hypno_axes,'color',[1 1 1]*.5,'fontsize',fontsize,'position',[cycle_x,cycle_y,cycle_z]);
    %     if(k<numel(transitions)) %don't draw the very last transition
    line('xdata',[transitions(k-1),transitions(k-1)],'ydata',ylim,'linestyle',':','parent',hypno_axes,'linewidth',1,'hittest','off','color',[1 1 1]*0.5);
    %     end
end


end

