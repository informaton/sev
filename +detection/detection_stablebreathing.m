%> @file detection_stablebreathing
%> @brief Stable breathing detector designed by Henriette Koch, Oct.2013-Aug.2014.
%======================================================================
%> @brief Identifies stable breathing events.  
%> @param data Signal data as a cell of column vectors.  The cell contents represent the following signals, in order:
%> @li @c SaO2
%> @li @c NasalPres
%> @li @c Chest       iir_butter_bp (order = 4, start = 1, stop = 5)
%> @li @c Abdomen     iir_butter_bp (order = 4, start = 1, stop = 5)
%> @li @c C3-x        iir_butter_bp (order = 8, start = 3, stop = 35)
%> @li @c Chin EMG    iir_butter_bp (order = 8, start = 5, stop = 49)
%> @li @c ECG
%> @li @c OralTherm


%> @param params A structure for variable parameters passed in
%> with following fields
%> @li @c 
%> @param stageStruct 
%> @retval detectStruct a structure with following fields
%> @li @c new_data Copy of input data.
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c paramStruct Structure with following fields which are vectors
%> with the same numer of elements as rows of @c new_events.
%> @li @c pmean Mean of the data covered by event
%> @li @c pmax Maximum value of the data covered for each event.
function detectStruct = detection_stablebreathing(data_cell,params, stageStruct)

% modified 9/15/2014 - streamline default parameter behavior.

% initialize default parameters
defaultParams.scale = 1;

% return default parameters if no input arguments are provided.
if(nargin==0)
    detectStruct = defaultParams;
else
    
    if(nargin<2 || isempty(params))
        
        pfile =  strcat(mfilename('fullpath'),'.plist');
        
        if(exist(pfile,'file'))
            %load it
            params = plist.loadXMLPlist(pfile);
        else
            %make it and save it for the future            
            params = defaultParams;
            plist.saveXMLPlist(pfile,params);
        end
    end
    
    
    
    % samplerate = params.samplerate;
    
    detectStruct.new_data = data_cell;
    detectStruct.new_events = [1, 300;
        1100, 1400;
        3001, 3700];
    
    pmean = [mean(data_cell(1:300));
        mean(data_cell(1100:1400));
        mean(data_cell(3001:3700))];
    pmax = [max(data_cell(1:300));
        max(data_cell(1100:1400));
        max(data_cell(3001:3700))];
    
    
    detectStruct.paramStruct.pmean = pmean;
    detectStruct.paramStruct.pmax = pmax;
end


% Saturation (sat, major drop)
[flip_sat artefact_sat] = artefact_saturation(signal{nsao2},hdr.fs(isao2)); % input saturation

% Nasal pressure (NP, extreme values and white noise)
[artefact_np] = artefact_nasalpressure(signal{npres},hdr.fs(ipres)); % input nasal pressure

% Put all artefacts in struct
artefact.sat = artefact_sat; artefact.np = artefact_np;
if ~isempty(ieeg) && ~isempty(iemg)
    % EEG and EMG (artefact_emg: major muscle artefacts disturbing EEG, artefact_eeg: flat line and electrodepop)
    [artefact_eeg artefact_emg] = artefact_eegemg(eeg,hdr.fs(ieeg)); % input EEG to detect EMG artefact, Brunner 1996 paper
    artefact.eeg = artefact_eeg; artefact.emg = artefact_emg;
end

% Artefact corrections
% Periods with artefacts in saturation, nasal pressure and major muscle artefacts in EEG are never included, therefore changed to NaN.
% Saturation
if ~isnan(artefact.sat)
    for i = 1:size(artefact.sat,1)
        signal{nsao2}(artefact.sat(i,1):artefact.sat(i,2)) = NaN;
    end
end

% Nasal pressure
if ~isnan(artefact.np)
    for i = 1:size(artefact.np,1)
        signal{npres}(artefact.np(i,1):artefact.np(i,2)) = NaN;
    end
end

% If the full saturation or nasal pressure channel is contaimned with noise
% the PSG is excluded
if sum(isnan(signal{nsao2}))==size(signal{nsao2},1) || sum(isnan(signal{npres}))==size(signal{npres},1), continue, end

% EEG
if ~isempty(ieeg) && sum(sum(~isnan(artefact.eeg)))~=0
    for i = 1:size(artefact.eeg,1)
        eeg(artefact.eeg(i,1):artefact.eeg(i,2)) = NaN;
    end
end



%% Detection
% Desaturation events
% Use output from  "artefact_saturation" and SAO2 channel
threshold_desat = 3; % saturation drop to detect desaturation events (WSC 3%)
[desat_event resat_event] = detection_desaturation(signal{nsao2},threshold_desat,artefact.sat,hdr.fs(isao2),flip_sat);
desat.desat = desat_event; desat.resat = resat_event;


% Breath detection
% Use output from "artefact_nasalpressure", nasal pressure, oral flow channel (if same channel label on flow channels, use both channels), rib and abdominal belt
[pressure_event pressure_startInspExp flip_np] = detection_breath(signal{npres},rib,abd,artefact.np,hdr.fs(ipres));
breath.pressure = pressure_event; breath.inspexp = pressure_startInspExp; breath.flip = flip_np;


% Drop in nasal pressure events
% Use output from "artefact_nasalpressure", "detection_breaths", nasal pressure, oral flow channel (if same channel label on flow channels, use both channels), rib and abdominal belt
[npdrop_event] = detection_npdrop(signal{npres}*breath.flip,breath.pressure,artefact.np,rib,abd,flowsignal,flowFs,hdr);


% Stable breathing periods
% Use output from "artefact_nasalpressure", "detection_breath", "detection_npdrop"
[stable_event stablesleep_stage] = detection_stablebreath(npdrop_event(:,1:2),breath.pressure,artefact.np,STA,hdr.fs(ipres));
nasaldrop.npdrop = npdrop_event; nasaldrop.stableev = stable_event; nasaldrop.stable = stablesleep_stage;


% Time-locked events
% Use output from "detection_desaturation", "detection_breath", "detection_npdrop" and nasal pressure channel
delaysat = 4*hdr.fs(isao2); % Delay in saturation equipment is 8 seconds, therefore 4 sec.
[tlock selected_events overlap_events] = detection_timelocknpdropdesat(desat.desat,nasaldrop.npdrop,breath.pressure,signal{npres},delaysat,hdr.fs(ipres));
timelock.tlock = tlock; timelock.selected = selected_events; timelock.overlap = overlap_events; timelock.excl = artefact;



%% Features
% All features are calculated using the detected events, STA and individual
% signals. Time-locked events uses EEG, EMG and heart rate detected by
% rr_simple in SEV.

% Desasturation features
desat_feat = features_desaturation(signal{nsao2},desat.desat,desat.resat,STA,hdr.fs(isao2));

% Nasal pressure drop features
npdrop_feat = features_npdrop(signal{npres},nasaldrop.npdrop,breath.pressure,STA,hdr.fs(ipres));

% Stable breathing features
stab_featmat = features_stablebreath(signal,artefact,nasaldrop.stable,STA,breath.pressure,breath.inspexp,hdr);

% Heart rate run in SEV
load(['/data1/home/hkoch/Breath_part/Apnea_final/WSC_stablebreathing/ECG/evt.' patname(1:14) '.ECG.rr_simple.0.mat']);
heartrate = [start_stop_matrix(:,1) paramStruct.inst_hr]; % heart rate index, heart rate

% "hdr" order of signals: nsao2 = 1; npres = 2; nrib = 3; nab = 4; neeg = 5; nemg = 6; necg = 7; % signal index when loaded into "signal" cell
PSGorder = [nsao2 npres neeg nemg];
if isempty(ieeg) || isempty(iemg)
    TimeLockFeat = cell(6,1); % used to output features for each sleep stage
    tlockfeat_out = cell(6,1); tlockfeat_evnum = nan(6,6);
    tlockevents.desat=NaN; tlockevents.br=NaN; tlockevents.brfreq=NaN; tlockevents.delta=NaN; tlockevents.theta=NaN;
    tlockevents.alpha=NaN; tlockevents.beta=NaN; tlockevents.eegratio=NaN; tlockevents.emg=NaN; tlockevents.hr=NaN;
else
    [TimeLockFeat tlockevents tlockfeat_out tlockfeat_evnum] = features_timelock(timelock.tlock,eeg,emg,signal{nsao2},signal{npres},timelock.excl,breath.pressure,timelock.selected,desat.desat,nasaldrop.npdrop,heartrate,hdr,PSGorder,STA,patname(1:14),NaN);
end

features.desat = desat_feat;
features.npdrop = npdrop_feat;
features.stable = stab_featmat;
features.tlock.var1 = TimeLockFeat;
features.tlock.var2 = tlockevents;
features.tlock.var3 = tlockfeat_out;
features.tlock.var4 = tlockfeat_evnum;



end
end
