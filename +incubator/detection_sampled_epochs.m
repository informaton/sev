function detectStruct = detection_sampled_epochs(channel_indices, optional_params)
% obtains four epochs, 1 per quarter.  useful for validating channels
% channel indices is vector of channel indices
% written by Hyatt Moore IV, January 4, 2013

global CHANNELS_CONTAINER;

src_data = CHANNELS_CONTAINER.getData(channel_indices(1));
num_samples = numel(src_data);
samplerate = CHANNELS_CONTAINER.getSamplerate(channel_indices(1));

% this allows direct input of parameters from outside function calls, which
%can be particularly useful in the batch job mode

if(nargin==2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile =  strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.epoch_dur_seconds = 30; %30 second epochs
        params.num_epochs = 4;%number of epochs to pick
        plist.saveXMLPlist(pfile,params);
        
    end
end
samples_per_epoch = params.epoch_dur_seconds*samplerate;
num_epochs = floor(num_samples/samples_per_epoch);
epochs = linspace(1,num_epochs,params.num_epochs+2)';
epochs = floor(epochs(2:end-1));
detectStruct.new_events = [(epochs-1)*samples_per_epoch+1,epochs*samples_per_epoch];
detectStruct.new_data = src_data;
detectStruct.paramStruct = [];