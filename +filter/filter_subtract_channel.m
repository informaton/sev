function filtsig = filter_subtract_channel(src_channel,ref_channel, varargin)
% Add the two src_indices together as output filtsig
%written by Hyatt Moore IV, May 12, 2012
global CHANNELS_CONTAINER;
filtsig = CHANNELS_CONTAINER.getData(src_channel)-CHANNELS_CONTAINER.getData(ref_channel);

