%> @file filter_add_channel.m
%> @brief Sums two input channels together as one.
%======================================================================
%> @brief Sums two input channels together as one.
%> @param src_data The first PSG channel
%> @param ref_data The second PSG channel
%> @note @c src_data and @ref_data must be the same length.
%> @param varargin Additional arguments are not used.
%> @retval filstig The sum of src_data and ref_data
%> @note Last modified on 5/6/2014
function filtsig = filter_add_channel(src_data, ref_data, varargin)
% Add the two input channels together as a single output file.
%
%written by Hyatt Moore IV, May 12, 2012
% updated 5/6/2014 - removed the global CHANNELS_CONTAINER.  Add
% documentation.
%
filtsig = src_data+ref_data;

