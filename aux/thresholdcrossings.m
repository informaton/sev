function x = thresholdcrossings(line_in, threshold_line)
%returns start and stop pairs of the sample points where where line_in is
%greater (i.e. crosses) than threshold_line
%threshold_line and line_in must be of the same length if threshold_line is
%not a scalar value.
%returns an empty matrix if no pairings are found...

%Hyatt Moore, IV (< June, 2013)
if(nargin==1 && islogical(line_in))
    ind = find(line_in);
else
    ind = find(line_in>threshold_line); 
end
cur_i = 1;

if(isempty(ind))
    x = ind;
else
    x_tmp = zeros(length(ind),2);
    x_tmp(1,:) = [ind(1) ind(1)];
    for k = 2:length(ind);
        if(ind(k)==x_tmp(cur_i,2)+1)
            x_tmp(cur_i,2)=ind(k);
        else
            cur_i = cur_i+1;
            x_tmp(cur_i,:) = [ind(k) ind(k)];
        end;
    end;
    x = x_tmp(1:cur_i,:);
end;
