function plotROC(confusion_matrix,axes_h,drawQROC)
% function plotROC(confusion_cell,axes_h,drawQROC)
% confusion_cell is an Mx4 matrix of values of the form [TP,FN,FP,TN]
% axes_h is a axes handle for where the plot should be displayed to
% drawQROC is a boolean variable to draw the QROC or [not] (otherwise draw
% ROC)

% Hyatt Moore IV (< June, 2013)

if(nargin<3)
    drawQROC = false;
end


[TPR, FPR, K_1_0, K_0_0] = confusion2roc(confusion_matrix);

if(drawQROC)
    y = K_1_0;
    x = K_0_0;
    xlabel(axes_h,'\kappa(0,0) (Quality of specificity)');
    ylabel(axes_h,'\kappa(1,0) (Quality of sensitivity)');
    
    %draw the random line...
    line('parent',axes_h,'xdata',[0 1],'ydata',[1 0],'linestyle',':','color',[0.5 0.5 0.5],'tag','random_line');

else
    x = FPR;
    y = TPR;
    xlabel(axes_h,'False Positive Rate (1 - Specificity)');
    ylabel(axes_h,'True Positive Rate (Sensitivity)');
    %draw the random line...
    line('parent',axes_h,'xdata',[0 1],'ydata',[0 1],'linestyle',':','color',[0.5 0.5 0.5],'tag','random_line');

end

marker = 'o';
line('parent',axes_h,'xdata',x,'ydata',y,'linestyle','none','marker',marker,'userdata',confusion_matrix,'tag','marker');



