function detectStruct = detection_handj(data,optional_params, stageStruct)

if(nargin>=2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.threshold1 = 10.5;
        params.feature2 = 10;
        params.feature3 = 0.45;
        plist.saveXMLPlist(pfile,params);
    end
end

samplerate = params.samplerate;

detectStruct.new_data = data;
detectStruct.new_events = [1, 300;
    1100, 1400;
    3001, 3700];

pmean = [mean(data(1:300)); 
    mean(data(1100:1400));
    mean(data(3001:3700))];
pmax = [max(data(1:300));
    max(data(1100:1400));
    max(data(3001:3700))];


detectStruct.paramStruct.pmean = pmean;
detectStruct.paramStruct.pmax = pmax;
end
