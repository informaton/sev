function filtsig = filter_add_channel(src_index, ref_index, varargin)
% Add the two src_indices together as output filtsig
%written by Hyatt Moore IV, May 12, 2012
global CHANNELS_CONTAINER;
filtsig = CHANNELS_CONTAINER.getData(src_index)+CHANNELS_CONTAINER.getData(ref_index);

