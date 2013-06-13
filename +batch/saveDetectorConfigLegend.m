function saveDetectorConfigLegend(full_events_path,method_label,paramStruct)
%saveDetectorConfigLegend(full_events_path,method_label,paramStruct)
%
%
%saves detector configurations for batch mode runs.  Especially helpful
%when running a multiplicity of configurations for a particular event
%detector.  
% full_events_path = the directory name where the events are being saved to
% method_label = the name of the detector being configured
% paramStruct = a parameter structure with fields representative of the
% configurable parameters, and the values in the fields containing the
% possible settings.  
% paramStruct contains M fields, each with a vector of N values.
% A file is saved to disk containing the configurations and an ordinal ID
% for each configuration beginning with 1.
%
%--output file looks like this
%ConfigNumber Label {variable parameters}
%1            method_label  [variable parameter values]
%2            method_label  [variable parameter values]
%3            method_label  [variable parameter values]
%...

%Hyatt Moore, IV (< June, 2013)
output_filename = fullfile(full_events_path, ['_configLegend_',method_label,'.txt']);

fid = fopen(output_filename,'w');

paramNames = fieldnames(paramStruct(1));
numParams = numel(paramNames);
fprintf(fid,'ConfigNumber\tLabel'); %do this so that I can import directly?

for k=1:numParams
    fprintf(fid,'\t%s',paramNames{k});
end

fprintf(fid,'\r\n');

%each paramNames field will have the same vector size
numConfigurations = numel(paramStruct);

for c=1:numConfigurations
    fprintf(fid,'%s\t%s',num2str(c),method_label);
    for k=1:numParams
        value = paramStruct(c).(paramNames{k});
        if(isnumeric(value))
            value = num2str(value);
        end
        fprintf(fid,'\t%s',value);
    end
    fprintf(fid,'\r\n');
end

fclose(fid);  %close it out.