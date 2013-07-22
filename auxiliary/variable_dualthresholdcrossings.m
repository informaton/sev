function cross_mat =  variable_dualthresholdcrossings(data, thresh_high, thresh_low, dur_below_samplecount)
% similar to dualthresholdcrossings, with the exception that the
% thresh_high and thresh_low are vectors of length(data).
% Written: Hyatt Moore IV
% Halloween, 2012
% updated 1/10/2013 - need to account for the duration below time

cross_vec = false(size(data));
active_flag = false;
drop_index = 1;
drop_count = 0;
for k=1:numel(data)
    
    if(data(k)>thresh_high(k))        
        active_flag = true;
        drop_count = 0;
    end
    if(active_flag)        
        if(data(k)<thresh_low(k))
%             if(k>448001)
%                 disp(k);
%             end
            if(drop_count==0)
                drop_index = k;
            end
            drop_count = drop_count+1;
            if(drop_count>dur_below_samplecount)
                active_flag = false;
                cross_vec(drop_index:k) = active_flag;
            end
        end
    end
    cross_vec(k) = active_flag;
end

cross_mat = thresholdcrossings(cross_vec);