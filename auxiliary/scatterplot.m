function scatterplot(xdata,ydata,x_label,y_label,idData)
% scatterplot(xdata,ydata,x_label,y_label,idData)
%
%idData{k} is a label identifying the owner of the [xdata(k), ydata(k)]
%pair.

% Hyatt Moore, IV (< June, 2013)

if(nargin<5)
    idData = {};
end

figure;
hold on;
plot(xdata,ydata,'ko');

r2 = xcorr(xdata,ydata,0,'coeff')^2;
p = polyfit(xdata,ydata,1);
xlim = get(gca,'xlim');
ylim = get(gca,'ylim');

x_line = xlim(1):xlim(2);
y_line = polyval(p,x_line);
plot(gca,x_line,y_line,'r-');
xlabel(x_label,'interpreter','none');
ylabel(y_label,'interpreter','none');
m = p(1);
b = p(2);

% h=text(xlim(1)+diff(xlim)/2,ylim(1)+diff(ylim)*0.9,sprintf('y(x) = %0.2f*x\t+\t%0.2f\nr2=%0.2f',m,b,r2));
% set(h,'edgecolor','r');

title(sprintf('y(x) = %0.2f*x\t+\t%0.2f\nr2=%0.2f',m,b,r2));

if(~isempty(idData))
    offset_x = diff(xlim)/50;
    offset_y = diff(ylim)/50;
    y_predict = polyval(p,xdata);
    residuals = abs(y_predict-ydata);
    
    %find outliers as the top 2.5% greatest offenders
    outliers = find(residuals>prctile(residuals,98));
    fprintf('OutlierID\tx\ty\n');
    for k=1:numel(outliers)
        out_i = outliers(k);
        
        text(xdata(out_i)+offset_x,ydata(out_i)+offset_y,sprintf('%s',idData{out_i}),'interpreter','none');
        fprintf('%s\t%0.2f\t%0.2f\n',char(idData(out_i)),xdata(out_i),ydata(out_i));
        
    end
end
