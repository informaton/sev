% Returns indices of peak values for vector x.  
function n = sev_findpeaks(x)
% Find peaks.
% n = findpeaks(x)

%Hyatt Moore IV (< June, 2013)
n    = find(diff(diff(x) > 0) < 0);
u    = find(x(n+1) > x(n));
n(u) = n(u)+1;

%% an older iteration..
% function [ind,peaks] = findpeaks(y)
% % FINDPEAKS  Find peaks in real vector.
% %  ind = findpeaks(y) finds the indices (ind) which are
% %  local maxima in the sequence y.  
% %
% %  [ind,peaks] = findpeaks(y) returns the value of the peaks at 
% %  these locations, i.e. peaks=y(ind);
% 
% y = y(:)';
% 
% switch length(y)
% case 0
%     ind = [];
% case 1
%     ind = 1;
% otherwise
%     dy = diff(y);
%     not_plateau_ind = find(dy~=0);
%     ind = find( ([dy(not_plateau_ind) 0]<0) & ([0 dy(not_plateau_ind)]>0) );
%     ind = not_plateau_ind(ind);
%     if y(1)>y(2)
%         ind = [1 ind];
%     end
%     if y(end-1)<y(end)
%         ind = [ind length(y)];
%     end
% end
% 
% if nargout > 1
%     peaks = y(ind);
% end
