%> @file detection_artifact_saturation
%> @brief This function calculates [start stop] for artefact periods in the
%> saturation channel and corrects the saturation signal if flipped.
%> @note Written by Henriette Koch, 2014.
%======================================================================
%> @brief This function calculates [start stop] for artefact periods in the
%> saturation channel and corrects the saturation signal if flipped.
% =========================================================================
%> @param Signal data vector.  (saturation signal)
%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c equipment_delay [= 4]  equipment uses the previous 4 heart beats to determine saturation 
%> @li @c samplerate
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c .new_data  corrected saturation signal, -1 if signal is flipped
%> @li @c .new_events A two column matrix of start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c .paramStruct Empty value returned (i.e. []).
%> @note Written by Henriette Koch, 2014.
%> Modified Aug. 15 2014 to include a max threshold and check diff 
function detectStruct = detection_artifact_saturation(srcSig,params,stageStruct)

if(nargin<2 || isempty(params))
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.equipment_delay = 4;  % equipment uses the previous 8 heart beats to determine saturation (50% forward and backward used).
        plist.saveXMLPlist(pfile,params);
        
    end
end

Fs = params.samplerate;
% begin hkoch code:

eq_delay = params.equipment_delay; 

% Median of signal must be within 70-110% saturation (above 100 if drift in
% equipment), else flipped
if median(srcSig)<70 || median(srcSig)>110 % OUTPUT if signal is flipped
    flip = -1;
else
    flip = 1;
end
outSig = flip*srcSig; % signal adjusted if flipped

% if flipped/shifted crazy
if sum(sign(outSig)) < 0
    artefact = [1 size(srcSig,1)];
    
% if flat line
elseif sum(diff(outSig)) == 0
    artefact = [1 size(srcSig,1)];
    return

% Initially check if complete signal is disrupted with noise (C0674_7 has this problem) - used to be > 4 and 0.04*size...
elseif sum(abs(diff(srcSig))>2)/size(srcSig,1) >= 0.05
    artefact = [1 size(srcSig,1)];
    
else
    
    % Equipment is turned off/wrong monitoring when saturation drops below 50% saturation.
    [idx_zero idx_up idx_down] = zerocrossing(outSig-50); % find crossing with 50%
    % Noise when above 110%
    [idx_zero2 idx_up2 idx_down2] = zerocrossing(outSig-110); % find crossing with 105%, more than 100% saturation is not possible but high threshold due to drift


    %% Min threshold
    if ~isempty(idx_zero) || ~isempty(idx_zero2)
        
        if ~isempty(idx_zero)
            if isempty(idx_down) % if zero crossings but no "down" detected
                idx_down = 1;
            elseif isempty(idx_up) % if zero crossings but no "up" detected
                idx_up = size(outSig,1);
            end
            if idx_down(1) < idx_up(1) && size(idx_down,1)==size(idx_up,1)+1 % if first down is before first up
                idx_up = [idx_up;size(outSig,1)];
            elseif idx_down(1) > idx_up(1) % if first up is before first down
                if size(idx_down,1)==size(idx_up,1)
                    idx_down = [1;idx_down];
                    idx_up = [idx_up;size(outSig,1)];
                elseif size(idx_down,1)+1==size(idx_up,1)
                    idx_down = [1;idx_down];
                end
            end
            % Add "eq_delay" second on each end to ensure stability in the signal
            idx_down = idx_down-eq_delay*Fs; idx_up = idx_up+eq_delay*Fs;
        end
        
        
        %% Max threshold
        if ~isempty(idx_zero2)
            if isempty(idx_down2) % if zero crossings but no "down" detected
                idx_down2 = size(outSig,1);
            elseif isempty(idx_up2) % if zero crossings but no "up" detected
                idx_up2 = 1;
            end
            if idx_down2(1) < idx_up2(1)
                if size(idx_down2,1)==size(idx_up2,1)+1 % if first down is before first up
                    idx_up2 = [1;idx_up2];
                elseif size(idx_down2,1)==size(idx_up2,1)
                    idx_up2 = [1;idx_up2]; idx_down2 = [idx_down2;size(outSig,1)];
                end
            elseif idx_down2(1) > idx_up2(1) && size(idx_down2,1)+1==size(idx_up2,1) % if first up is before first down
                idx_down2 = [idx_down2;size(outSig,1)];
            end
            idx_up2 = idx_up2-eq_delay*Fs; idx_down2 = idx_down2+eq_delay*Fs;
        end
        
        art50 = [idx_down idx_up]; % [start stop] for periods below 50
        art110 = [idx_up2 idx_down2]; % [start stop] for periods above 110
        artefact = eventoverlap(sort([art50 ; art110],'ascend')); % OUTPUT: artefact [start stop] for each artefact event
        
        artefact(artefact<1) = 1; % may be negative because delay is extracted
        
        
    else
        artefact = [NaN NaN]; % if no artefact events
        
    end
end

detectStruct.new_events = artefact;
detectStruct.new_data = outSig;
detectStruct.paramStruct = [];
end

function [idx_zero idx_up idx_down] = zerocrossing(sig)
% This function calculates when a signal crosses zero and specifies the
% crossing direction.
% Written by Henriette Koch
%
% INPUT
% sig: signal
%
% OUTPUT
% idx_zero: index for all zerocrossings
% idx_up: index for negative->postive values
% idx_down: index for positive->negative values
% =========================================================================

% Find zeros crossings
t1=sig(1:end-1);
t2=sig(2:end);
tt = t1.*t2;
idx_zero = find(tt<0);

% Specify direction of crossing up/down
x = diff(sign(sig));
idx_up = find(x>0);
idx_down = find(x<0);
end

function [eventout] = eventoverlap(eventin)
% This function merges overlapping events.
% Written by Henriette Koch, 2014.
%
% INPUT
% eventin: input event vector [start stop], two column matrix.
%
% OUTPUT
% eventout: output event vector where events are merged [start stop], two
% column matrix.
% =========================================================================


% Overlapped events are merged
A = [[eventin(:,1);NaN] [NaN;eventin(:,2)]]; % prepare for subtracting
A(A(:,2)-A(:,1)>=0,:)=[]; % delete overlapping start/stop
hstart = A(1:end-1,1); hend = A(2:end,2); % define new start/stop

eventout = [hstart hend]; % OUTPUT: merged event vector

end