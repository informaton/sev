function detectStruct = detection_plm_world(source_indices)
% World criteria (ref:
% http://sleepcohort.wisc.edu/operations/overnight_study/protocols_current/
% SCORGDL95.htm)
% Definition of Leg Movements (LM):
%  Duration: 0.5 to 5.0 seconds 
%  Amplitude: >50% flexion recorded during calibration
% Frequency: Need greater than 4 seconds to distinguish separate LM
%     Movements within 4 seconds of each other, are counted as  one movement.
%     Movements which are separated by at least 4 seconds  are counted as separate movements.  
%     Movements that occur during wakefulness are not counted. 
% LM AROUSAL (LMA):  
% "An arousal event and movement event are considered associated with each
% other when there is less than .5s between the end of one event and the
% onset of the other event regardless of which is first."   

detectStruct.paramStruct = [];

end