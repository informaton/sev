function cross_mat =  dualthresholdcrossings(data, thresh_high, thresh_low)
% cross_mat =  dualthresholdcrossings(data, thresh_high, thresh_low)
%
%determines where input data crosses thresh_high and the subsequent
%location where it falls below thresh_low.  These start and stop sample
%indices are returned in the matrix cross_mat.  
%cross_mat(k,1) = start sample index for event k (> thresh_high)
%cross_mat(k,2) = stop sample index for event k (< thresh_low)
%data is a vector of data

% Hyatt Moore IV (< June, 2013)

cross_vec = false(size(data));
active_flag = false;

for k=1:numel(data)
    if(data(k)>thresh_high)
        active_flag = true;
    elseif(data(k)<thresh_low)
        active_flag = false;
    end
    cross_vec(k) = active_flag;    
end

cross_mat = thresholdcrossings(cross_vec);