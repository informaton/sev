function annotations = loadEDFPlusAnnotations(filename)
% [HDR, signal] = loadEDFPlusAnnotations(filename)
% Loads EDF+ formatted file annotations.
% Written by Hyatt Moore
% 11/14/2016

% test: loadEDFPlusAnnotations('~/Data/sleep/EDF+-selected/INN003 N1.EDF')

if(nargin==0)
    disp 'No input filename given; aborting';
    return;
end;

if(nargin>1)
    disp('Too many input arguments in loadEDFPlusAnnotations.  Extra input arguments are ignored');
end;

%handle filenames with unicode characters in them
filename = char(unicode2native(filename,'utf-8'));
fid = fopen(filename,'r');
precision = 'uint8';

HDR.ver = str2double(char(fread(fid,8,precision)'));% 8 ascii : version of this data format (0) 
HDR.patient = char(fread(fid,80,precision)');% 80 ascii : local patient identification (mind item 3 of the additional EDF+ specs)')
HDR.local = char(fread(fid,80,precision)');% 80 ascii : local recording identification (mind item 4 of the additional EDF+ specs)')
HDR.startdate = char(fread(fid,8,precision)');% 8 ascii : startdate of recording (dd.mm.yy)') (mind item 2 of the additional EDF+ specs)')
HDR.starttime = char(fread(fid,8,precision)');% 8 ascii : starttime of recording (hh.mm.ss)') 
HDR.HDR_size_in_bytes = str2double(char(fread(fid,8,precision)'));% 8 ascii : number of bytes in header record 
HDR.reserved = char(fread(fid,44,precision)');% 44 ascii : reserved 
HDR.number_of_data_records = str2double(char(fread(fid,8,precision)'));% 8 ascii : number of data records (-1 if unknown, obey item 10 of the additional EDF+ specs)')  %236

% 'EDF+C' means continuous recording
% 'EDF+D' means interrupted recording
% See EDF+ spec at http://www.edfplus.info/specs/edfplus.html
if(~(strncmpi('EDF+C',HDR.reserved,5)||strncmpi('EDF+D',HDR.reserved,5)))
    throw(MException('INFORMATON:EDFPlus','Reserved field must begin with ''EDF+C'' or ''EDF+D'''));
end
HDR.duration_of_data_record_in_seconds = str2double(char(fread(fid,8,precision)'));% 8 ascii : duration of a data record, in seconds 
HDR.num_signals = str2double(char(fread(fid,4,precision)'));% 4 ascii : number of signals (ns)') in data record 
ns = HDR.num_signals;

datetime = [HDR.startdate, '.' , HDR.starttime];
HDR.T0 = zeros(1,6); %[year(4) month(2) day(2) hour(2) minute(2) second(2)]
try
    for k=1:6
        [str, datetime] = strtok(datetime,'.');
        HDR.T0(k) = str2num(str);
    end
    yy = HDR.T0(3);
    dd = HDR.T0(1);
    HDR.T0(3) = dd;
    if(yy>=85)
        yy = yy+1900;
    else
        yy = yy+2000;
    end;
    HDR.T0(1) = yy;
catch ME
    disp(['Failed to load the date/time in this EDF.  Filename: ', filename]);
end

%ns = number of channels/signals in the EDF
%duration_of_signal_in_samples = 

HDR.label = cellstr(char(fread(fid,[16,ns],precision)'));% ns * 16 ascii : ns * label (e.g. EEG Fpz-Cz or Body temp)') (mind item 9 of the additional EDF+ specs)')
HDR.transducer = cellstr(char(fread(fid,[80,ns],precision)'));% ns * 80 ascii : ns * transducer type (e.g. AgAgCl electrode)')
HDR.physical_dimension = cellstr(char(fread(fid,[8,ns],precision)'));% ns * 8 ascii : ns * physical dimension (e.g. uV or degreeC)')
HDR.physical_minimum = str2double(cellstr(char(fread(fid,[8,ns],precision)')));% ns * 8 ascii : ns * physical minimum (e.g. -500 or 34)')
HDR.physical_maximum = str2double(cellstr(char(fread(fid,[8,ns],precision)')));% ns * 8 ascii : ns * physical maximum (e.g. 500 or 40)')
HDR.digital_minimum = str2double(cellstr(char(fread(fid,[8,ns],precision)')));% ns * 8 ascii : ns * digital minimum (e.g. -2048)')
HDR.digital_maximum = str2double(cellstr(char(fread(fid,[8,ns],precision)')));% ns * 8 ascii : ns * digital maximum (e.g. 2047)')
HDR.prefiltering = cellstr(char(fread(fid,[80,ns],precision)'));% ns * 80 ascii : ns * prefiltering (e.g. HP:0.1Hz LP:75Hz)')
HDR.number_samples_in_each_data_record = str2double(cellstr(char(fread(fid,[8,ns],precision)')));% ns * 8 ascii : ns * nr of samples in each data record
HDR.reserved2 = cellstr(char(fread(fid,[32,ns],precision)'));% ns * 32 ascii : ns * reserved

HDR.fs = HDR.number_samples_in_each_data_record/HDR.duration_of_data_record_in_seconds; %sample rate
HDR.samplerate = HDR.fs;
HDR.duration_sec = HDR.duration_of_data_record_in_seconds*HDR.number_of_data_records;
HDR.duration_samples = HDR.duration_sec*HDR.fs;

cur_channel = 1;
bytesPerSample = 2;

samplesPerDataRecord = HDR.number_samples_in_each_data_record(cur_channel);
numDataRecords = HDR.number_of_data_records;  %HDR.duration_samples(cur_channel)*bytesPerSample;
bytesPerDataRecord = samplesPerDataRecord*bytesPerSample;
precision = [num2str(bytesPerDataRecord),'*uint8=>char']; % *2 here because we are now using uint8's instead of uint16's.  And we are using uint8's so we can get at the annotations which contain characters.
skip = (sum(HDR.number_samples_in_each_data_record)-samplesPerDataRecord)*bytesPerSample; %*2 because there are two bytes used for each integer

cur_channel_offset = sum(HDR.number_samples_in_each_data_record(1:cur_channel-1))*bytesPerSample; %*2 because there are two bytes used for each integer
offset = HDR.HDR_size_in_bytes+cur_channel_offset;
fseek(fid,offset,'bof');

% Store as column vector
annotations_signal = fread(fid,[bytesPerDataRecord,numDataRecords],precision,skip)'; % fills columns first (all rows of first column, then all rows of send column, etc)
annotations = parseAnnotationsSignal(annotations_signal,bytesPerDataRecord);

fclose(fid);

end

function annotations = parseAnnotationsSignal(annotations_signal,frame_size)
    % The first TAL in the first data record always starts with +0.X2020, indicating that the first data record starts a fraction, X, of a second after the startdate/time that is specified in the EDF+ header. If X=0, then the .X may be omitted.
    if(annotations_signal(1)~='+')
        throw(MException('INFORMATON:EDFPlus','The first TAL in the first data record does not start with +0.x2020'));
    end
    
end

% The voltage (i.e. signal) in the file by definition equals
% [(physical miniumum)
% + (digital value in the data record - digital minimum) 
% x (physical maximum - physical minimum) 
% / (digital maximum - digital minimum)].


% HEADER Specs...
% 8 ascii : version of this data format (0)') 
% 80 ascii : local patient identification (mind item 3 of the additional EDF+ specs)')
% 80 ascii : local recording identification (mind item 4 of the additional EDF+ specs)')
% 8 ascii : startdate of recording (dd.mm.yy)') (mind item 2 of the additional EDF+ specs)')
% 8 ascii : starttime of recording (hh.mm.ss)') 
% 8 ascii : number of bytes in header record 
% 44 ascii : reserved 
% 8 ascii : number of data records (-1 if unknown, obey item 10 of the additional EDF+ specs)') 
% 8 ascii : duration of a data record, in seconds 
% 4 ascii : number of signals (ns)') in data record 
% ns * 16 ascii : ns * label (e.g. EEG Fpz-Cz or Body temp)') (mind item 9 of the additional EDF+ specs)')
% ns * 80 ascii : ns * transducer type (e.g. AgAgCl electrode)') 
% ns * 8 ascii : ns * physical dimension (e.g. uV or degreeC)') 
% ns * 8 ascii : ns * physical minimum (e.g. -500 or 34)') 
% ns * 8 ascii : ns * physical maximum (e.g. 500 or 40)') 
% ns * 8 ascii : ns * digital minimum (e.g. -2048)') 
% ns * 8 ascii : ns * digital maximum (e.g. 2047)') 
% ns * 80 ascii : ns * prefiltering (e.g. HP:0.1Hz LP:75Hz)') 
% ns * 8 ascii : ns * nr of samples in each data record 
% ns * 32 ascii : ns * reserved




