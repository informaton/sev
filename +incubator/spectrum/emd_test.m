%y is the signal of interest
x = 1:numel(y);
num_decompositions = 5;


close all;


y_smooth = emd_slow(y,num_decompositions);
y_smooth = y_smooth{end};

x = (1:numel(y_smooth));
firstDeriv = [0, diff(y_smooth)./diff(x)]; 
secondDeriv =[0, diff(firstDeriv)./diff(x)];


figure;
hold on;
% plot(x,y,'b'); hold on;

delta = 100;

% plot(x,firstDeriv+delta,'k');
plot(x,secondDeriv,'r');


num_decompositions = 4;



y_smooth = emd_slow(y,num_decompositions);
y_smooth = y_smooth{end};

x = (1:numel(y_smooth));
firstDeriv = [0, diff(y_smooth)./diff(x)]; 
secondDeriv =[0, diff(firstDeriv)./diff(x)];
plot(x,secondDeriv+0.5,'b');


% 
% wname = 'db1';
% 
% %emd 4 or 5 looks best
% for k=1:num_decompositions
%     y_emd = emd_slow(y,k);
% 
%     plot(x,y_emd{end}+k*delta,'k');  
%     
% end;
% 
% for k=1:2
%     [c,l]=wavedec(y,k,wname);
%     plot(1:numel(c),c-k*delta,0.1,0.5);
% end
