function drawROC(Q,FPR, TPR,optional_axes_h,event_label_cell,drawQROC)
% function drawROC(Q,FPR, TPR,optional_axes_h,event_label_cell)
% function drawROC(Q,FPR, TPR,optional_axes_h,event_label_cell)
%creates a figure and displays the Receiver Operatating Characteristic
%curves for the parameters TPR (sensitivity, or true positive rate) and FPR
%(1 - specificity = False Positive Rate).   
%if FPR and TPR are matrices, then each row is interpreted as a different
%point on the ROC.
%
% A ROC space is defined by FPR and TPR as x and y axes respectively,
%which depicts relative trade-offs between true positive (benefits) and
%false positive (costs).
%optional_axes_h is an optional parameter that refers to the axes handle
%where the ROC will be drawn to.
% TPR = [0.9 0.85 0.91];
% FPR = [0.1 0.4 0.3];
%drawQROC is an optional boolean value (a flag) that specifies whether to
%draw a QROC instead of an ROC (default is false - which draws ROC)

%Hyatt Moore, IV (< June, 2013)
if(nargin>=4)
    a = optional_axes_h;
else
    f = figure('name','ROC');
    a = axes('parent',f,'xlim',[0 1],'ylim',[0 1]);
end;
if(nargin<5)
    event_label_cell = [];
end;
if(nargin<6)
    drawQROC = false;
end;

if(~iscell(FPR))
    FPR = {FPR};
end
if(~iscell(TPR))
    TPR = {TPR};
end
if(~iscell(Q))
    Q = {Q};
end
marker_cell = {'o','square','diamond','pentagram','hexagram','v'};
line_h = zeros(numel(FPR),1);
label_h = zeros(numel(FPR),1);

% cluster_cell= {'+','*','.','x','^','>','<'};
for k = 1:numel(FPR)
    
    x = FPR{k};
    y = TPR{k};
    marker = marker_cell{mod(k-1,numel(marker_cell))+1};

%     if(~bool_cluster)
%         x = FPR{k};
%         y = TPR{k};
%         marker = marker_cell{mod(k-1,numel(marker_cell))+1};
%     else
%         marker = cluster_cell{mod(k-1,numel(cluster_cell))+1};
%         x = mean(FPR{k});
%         std_x = std(FPR{k});
%         
%         y = mean(TPR{k});
%         std_y = std(TPR{k});
%         
%         w = 3*std_x;
%         h = 3*std_y;
%         rectangle('parent',a,'Position',[x-w/2,y-h/2,w,h],'Curvature',[1,1],...
%             'linestyle',':','linewidth',0.4,'edgecolor',[0.5 0.5 0.5]);
%     end;

    %draw rectangle here which will later be used to put the ellipse in
    %place for the clustered data
    rectangle('parent',a,'Curvature',[1,1],'visible','off',...
        'linestyle',':','linewidth',0.4,'edgecolor',[0.5 0.5 0.5]);

    line_h(k) = line('parent',a,'xdata',x,'ydata',y,'linestyle','none','marker',marker,'userdata',Q{k},'tag','marker');
    
    for x_ind = 1:numel(x)
        label_h(k) = text('parent',a,'position',[x(x_ind)-0.005 y(x_ind)],'string',num2str(x_ind),'tag','number','visible','off');
%         text_ext = get(label_h(k),'extent');
%         set(label_h(k),'position',[text_ext(1)-text_ext(3)/2,text_ext(2)-text_ext(4)/2]);
    end
end;

%draw the random line...
line('parent',a,'xdata',[0 1],'ydata',[0 1],'linestyle',':','color',[0.5 0.5 0.5],'tag','random_line');
if(~isempty(event_label_cell))
  l =  legend(a,line_h,event_label_cell);
  set(l,'interpreter','none','location','southeast','visible','off');
%     legend(a,label_h,event_label_cell,'interpreter','none','location','so
%     utheast');
end;
% P = polyfit(FPR,TPR,deg);
% x = linspace(0,1);
% y_poly = polyval(P,x);
% line('parent',a,'xdata',x,'ydata',y_poly,'linestyle',':','color',[0.5 0.5 0.5]);
xlabel(a,'False Positive Rate (1 - Specificity)');
ylabel(a,'True Positive Rate (Sensitivity)');
