function cross_mat =  variable_triplethresholdcrossings(data, thresh_high, thresh_low,dur_below_samplecount)
% similar to dualthresholdcrossings, with the exception that the
% thresh_high and thresh_low are vectors of length(data).
% Written: Hyatt Moore IV
% February 6, 2013
% modificatoin from variable dualthresholdcrossings - after seeing the
% length that some lm's go on for.

cross_vec = false(size(data));
active_flag = false;
drop_count = 0;
last_above_middle_index = 1;
for k=1:numel(data)  
%     if(k>1179420)
%         disp(k);
%     end
    if(data(k)>thresh_high(k))
        active_flag = true;
        drop_count = 0;
    end
    if(active_flag)
        if(data(k)>(thresh_high(k)+thresh_low(k))/2)           
           last_above_middle_index = k;
        end
        if(data(k)<thresh_low(k))
            drop_count = drop_count+1;
            if(drop_count>dur_below_samplecount)
                active_flag = false;
                
                cross_vec(last_above_middle_index+1:k) = active_flag;  %remove the spots up until now that are not active
            end
        end
    end
    cross_vec(k) = active_flag;
end

cross_mat = thresholdcrossings(cross_vec);