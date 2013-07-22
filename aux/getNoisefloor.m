function [variable_threshold_low_uv, variable_threshold_high_uv, clean_data] = getNoisefloor(data, params, samplerate)
% function [variable_threshold_low_uv, variable_threshold_high_uv, clean_data] = getNoisefloor(data, params, samplerate)
%
% calculates the low and higher variable thresholds using a moving average
% measure for the noise floor and the settings provided in the struct
% params
%
% Hyatt Moore, IV (<June, 2013)

%     high_uv(x,nf(x)) = 0.5*x.*log(x) + high_threshold
    %apply noise floor rules now
    %1. turn off variable noise floor when below engagement threshold

    ma_params.order=samplerate*params.average_power_window_sec;
    ma_params.rms = 1;
    
    noisefloor = filter.filter_ma(data,ma_params);
%     noisefloor = filter.nlfilter_rms(data,ma_params);
    
    low_scale = params.threshold_low_uV/params.threshold_high_uV;
    
    
%      engage_and_square_indices = noisefloor<params.noisefloor_scale_uV_to_engage;
%      engage_and_scale_indices = noisefloor>=params.noisefloor_scale_uV_to_engage & noisefloor<params.noisefloor_uV_to_turnoff_detection;
     disengage_indices = noisefloor>=params.noisefloor_uV_to_turnoff_detection;
     summer_indices = noisefloor<=params.threshold_low_uV;

%      noisefloor(engage_and_square_indices) = (noisefloor(engage_and_square_indices).^2)/params.noisefloor_scale_uV_to_engage + params.threshold_high_uV;
%      noisefloor(engage_and_scale_indices) = noisefloor(engage_and_scale_indices)*params.noisefloor_scale;
%      noisefloor(disengage_indices) = inf;
 
%     high_uv(x,nf(x)) = 0.5*x.*log(x) + high_threshold

%     variable_threshold_high_uv = 0.5*noisefloor.*log(noisefloor) + params.threshold_high_uV;
    
%     variable_threshold_high_uv = 0.5*noisefloor.*(1+1*log(noisefloor+1)) + params.threshold_high_uV; %version 5 and 6

% variable_threshold_high_uv = noisefloor.*(1+1*log(noisefloor+1)) + params.threshold_high_uV;  %version 3 and 4

        variable_threshold_high_uv = noisefloor.*(log(noisefloor+1)) + params.threshold_high_uV;  %version 3 and 4

     %     variable_threshold_high_uv = noisefloor.*(1+1*log(noisefloor+1))
     %     + params.threshold_high_uV; 
    
    
    variable_threshold_high_uv(disengage_indices) = inf;    
    variable_threshold_low_uv = variable_threshold_high_uv*low_scale;
    
    %     variable_threshold_low_uv
    
    %     %2 smooth absolute value of data with moving averager
    %     ma.params.order = ceil(params.min_duration_sec*samplerate);
    %     ma.params.rms = 1; %  clean_data = abs(data); %moved this to rms = 1 in the below field
    %     clean_data = filter.filter_ma(data,ma.params);
    %     rms.params.order = ceil(samplerate*0.15);  %0.15 second time constant
    
%     rms.params.order = ceil(samplerate*0.5);  %0.15 second time constant
    rms.params.order = ceil(samplerate*0.15);  %0.15 second time constant
    %      rms.params.order = ceil(samplerate*params.min_duration_sec);  %0.15 second time constant
    clean_data = filter.nlfilter_rms(data,rms.params);
    
    if(params.use_summer)
        %3 increase SNR using 2 point moving integrator
        integrator.params.rms = 1;
        integrator.params.order = params.summer_order;
       
        clean_data2 = filter.filter_sum(clean_data,integrator.params);
%         variable_threshold_high_uv = variable_threshold_high_uv*2;
%          variable_threshold_low_uv = variable_threshold_low_uv*2;

        clean_data(summer_indices) = clean_data2(summer_indices); %original detection method;

        %this is configuration#2 settings
        %         variable_threshold_high_uv(summer_indices) = variable_threshold_high_uv(summer_indices)+params.threshold_low_uV;
%          variable_threshold_low_uv(summer_indices) = variable_threshold_high_uv(summer_indices)*low_scale;

      variable_threshold_low_uv(summer_indices) = variable_threshold_low_uv(summer_indices)+params.threshold_low_uV;
    
    
    
% 
%          
%            variable_threshold_low_uv = variable_threshold_low_uv+params.threshold_low_uV;
%           clean_data = clean_data2;
        
    end
end