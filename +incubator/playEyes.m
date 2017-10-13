function playEyes(heog, veog, samplerate,axes_h)
%show what it looks like to see an eye moving around
% heog = heog-mean(heog);
% veog = veog-mean(veog);
% heog = heog/max(abs(heog));
% heog = -heog;  %swap it to make math work with degrees
% veog = veog/max(abs(veog)); %normalize

%normalize using a reference
normalizing_threshold_uv = 60;
heog = -heog/normalizing_threshold_uv;
veog = veog/normalizing_threshold_uv;
delete(timerfindall);
close all;

if(nargin<4||isempty(axes_h)||~ishandle(axes_h))
    f = figure('units','pixels','position',[520, 478, 560,430+200]);
    axes_h = axes('parent',f,'units','normalized','position',[0.05,0.4, 0.9, 0.55]);
    eog_axes_h = axes('parent',f,'units','normalized','position',[0.05,0.05, 0.9, 0.3],...
        'yminortick','off','xminortick','off','xticklabelmode',...
        'manual','xtick',[],'yticklabelmode','manual','ytick',[],'xlim',[0 1],'ylim',[0 1],'box','on');
    xdata = 1:numel(heog);
    line('parent',eog_axes_h,'ydata',heog+0.5,'xdata',xdata,'color','red');
    line('parent',eog_axes_h,'ydata',veog-0.5,'xdata',xdata,'color','blue');
    annotation('rectangle','parent',f,'units','normalized','position',[0.475 0.05 0.05 0.3],'facealpha',1,'linewidth',0.5,'linestyle',':','color',[0 0 0]);
    
    set(eog_axes_h,'ylim',[-1.6,1.6]);
    set(eog_axes_h,'xlim',[-0.5,0.5]);
end

[board_img_h,clean_board,board_map,quad_ind] = init_board(axes_h);
fps = 25;
samples_per_frame = round(samplerate/fps);
numFrames = floor(numel(heog)/samples_per_frame);

waitforbuttonpress;
timer_h = timer('executionmode','fixedrate','period',1/fps,'timerfcn',{@sim_fcn,board_img_h,clean_board,board_map,quad_ind,veog,heog,samples_per_frame,eog_axes_h},'taskstoexecute',numFrames);
set(timer_h,'stopfcn',@timerStop);
start(timer_h);

end

function timerStop(hObject,event_data)
    stop(hObject);
    delete(hObject);
end

function sim_fcn(hObject,event_data, img_h,clean_board,board_map,quad_ind,veog,heog,frame_size,eog_axes_h)
% pupil_size = 3;
samplerate = 100;
eog_window= 10; %10 seconds
if(ishandle(img_h))
    datarange = (hObject.TasksExecuted-1)*frame_size+1:(hObject.TasksExecuted)*frame_size;
    if(ishandle(eog_axes_h))
       set(eog_axes_h,'xlim',[datarange(1)-eog_window/2*samplerate,datarange(end)+eog_window/2*samplerate]);
    end
    [r,c] = size(clean_board);
    x = min(c-1,max(2,round((1+mean(heog(datarange)))*c/2)));
    y = min(c-1,max(2,round((1+mean(veog(datarange)))*r/2)));
    
    elapsed_str = sprintf('%0.2f s',(hObject.TasksExecuted*hObject.Period));
    title(get(img_h,'parent'),elapsed_str);
    title(eog_axes_h,elapsed_str);
    
%     disp([x,y]);
    
    bc = board_map(y,x)-2;

    if(bc>0 && bc<5)
        clean_board(quad_ind{bc})= bc+2;
    end
    
    clean_board(y      ,x-1:x+1) = 7;
    clean_board(y-1:y+1,      x) = 7;
    set(img_h,'cdata',clean_board);
else
    stop(hObject)
end
    
end

function [img_h,clean_board,board_map,quad_ind] = init_board(axes_h)

colormap(axes_h,[1 1 1
    0.65 0.65 0.65
    1 0 0
    0 1 0
    0 0 1
    1 1 0
    0 0 0]);

n = 100;
img_h = image('parent',axes_h);
clean_board = ones(n,n);

[x,y] = meshgrid(linspace(-n/2,n/2,n),linspace(-n/2,n/2,n));

resting_ind = sqrt(x.^2+y.^2)<n/3;

quad_ind = cell(4,1);
quad_ind{1} = x>0&y>0&~resting_ind;
quad_ind{2} = x<0&y>0&~resting_ind;
quad_ind{3} = x<0&y<0&~resting_ind;
quad_ind{4} = x>0&y<0&~resting_ind;

clean_board(resting_ind) = 2;
board_map = clean_board;
for q =1:numel(quad_ind)
    board_map(quad_ind{q}) = q+2;
end

set(img_h,'cdata',clean_board,'XData',[1 n],'YData',[1 n]);

set(axes_h,'yminortick','off','xminortick','off','xticklabelmode',...
    'manual','xtick',[],'yticklabelmode','manual','ytick',[],'xlim',[0 n+1],'ylim',[0+0.1 n+1],'box','on');
end