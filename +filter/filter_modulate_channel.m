function filtsig = filter_modulate_channel(src_index, ref_index, varargin)
% Modulate src_index by ref_index
%written by Hyatt Moore IV, January, 2013
global CHANNELS_CONTAINER;
if(numel(src_index)>20)
    src_sig = src_index;
    ref_sig = ref_index;
%     params = optional_params;
%     sample_rate = params.sample_rate;

filtsig = src_sig.*ref_sig;
else
    filtsig = CHANNELS_CONTAINER.getData(src_index).*CHANNELS_CONTAINER.getData(ref_index);
end


