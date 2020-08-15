function aStruct = getArtifactStruct(num2get)
    % Cannot leave empty cells in a struct call and have it result
    % correctly in a complete struct.  You can get a fresh one with no
    % memory allocated yet.  e.g. 'channel_labels',{}  causes problems
    % don't add struct() as values here either as it causes problems by not
    % being able to see that they are empty later (e.g. no to 'params',
    % struct())
    if(~nargin)
        num2get = 1;
    end
    artifactTemplate = @()struct('numConfigurations',1,'use_psd_channel',false,...
        'channel_labels',[],'channel_indices',[],'channel_configs',[],'method_label','',...
        'method_function','','pBatchStruct',[],'rocStruct',[],...  
        'params',[],'configID',NaN,'batch_mode_label','');
%     artifactTemplate = struct('numConfigurations',1,'use_psd_channel',false,...
%         'channel_labels',[],'channel_indices',[],'channel_configs',[],'method_label','',...
%         'method_function','','pBatchStruct',[],'rocStruct',[],...  
%         'params',[],'configID',NaN,'batch_mode_label','');

    aStruct = repmat(artifactTemplate(),num2get,1);
end