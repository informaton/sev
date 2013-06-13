function cross_mat =  triplethresholdcrossings(data, thresh_high, thresh_low,dur_below_samplecount)
% wrapper for variable_triplethresholdcrossings
%this one can take scalar arguments for thresh_high and thresh_low

% written by Hyatt Moore IV
% 

if(numel(thresh_high)==1)
    thresh_high = repmat(thresh_high,size(data));
end
if(numel(thresh_low)==1)
    thresh_low = repmat(thresh_low,size(data));
end

cross_mat =  variable_triplethresholdcrossings(data, thresh_high, thresh_low,dur_below_samplecount);