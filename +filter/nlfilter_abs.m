function output = nlfilter_abs(src_index,varargin)
%returns the absolute value of the signal

global CHANNELS_CONTAINER;
if(numel(src_index)>20)
    output = abs(src_index);
else
    output = abs(CHANNELS_CONTAINER.getData(src_index));
end