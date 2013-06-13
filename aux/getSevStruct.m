function sevStruct = getSevStruct()
%sevStruct builder - sets the default names for the SEV
%

%Hyatt Moore, IV
%> June, 2013
    sevStruct.src_edf_pathname = '.'; %initial directory to look in for EDF files to load
    sevStruct.src_event_pathname = '.'; %initial directory to look in for EDF files to load
    sevStruct.batch_folder = '.'; %'/Users/hyatt4/Documents/Sleep Project/EE Training Set/';
    sevStruct.yDir = 'normal';  %or can be 'reverse'
    sevStruct.standard_epoch_sec = 30; %perhaps want to base this off of the hpn file if it exists...
    sevStruct.samplerate = 100;
    sevStruct.channelsettings_file = 'channelsettings.mat'; %used to store the settings for the file
    sevStruct.output_pathname = 'output';
    sevStruct.detectionInf_file = 'detection.inf';
    sevStruct.detection_path = '+detection';
    sevStruct.filter_path = '+filter';
    sevStruct.databaseInf_file = 'database.inf';
    sevStruct.parameters_filename = '_sev.parameters.txt';
end

