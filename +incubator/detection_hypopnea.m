function detectStruct = detection_hypopnea(channel_index,optional_debug_data)
% Definition: Hypopnea refers to a transient reduction of airflow (often
% while asleep) that lasts for at least 10 seconds, shallow breathing, or
% an abnormally low respiratory rate. Hypopnea is less severe than apnea
% (which is a more complete loss of airflow). It may likewise result in a
% decreased amount of air movement into the lungs and can cause oxygen
% levels in the blood to drop. It more commonly is due to partial
% obstruction of the upper airway.
%Source: http://sleepdisorders.about.com/od/glossary/g/Hypopnea.htm

global CHANNELS_CONTAINER;

%nasal air pressure channel
NASAL_channel.data = CHANNELS_CONTAINER.getData(channel_index);
NASAL_channel.sample_rate = CHANNELS_CONTAINER.getSamplerate(channel_index);

air_flow_pressure_threshold = 20;
min_dur_sec = 10;
min_dur = min_dur_sec*NASAL_channel.sample_rate;

if(nargin==2)
    detectStruct.new_data = abs(optional_debug_data);
else
    detectStruct.new_data = abs(NASAL_channel.data);
end

hyp_evts = thresholdcrossings(detectStruct.new_data<air_flow_pressure_threshold,0);
hyp_evts = CLASS_events.cleanup_events(hyp_evts,min_dur);

detectStruct.new_events = hyp_evts;

detectStruct.paramStruct = [];
