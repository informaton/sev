%> @file filter_subtract_channel.m
%> @brief Returns the element by element difference of two input channels.
%======================================================================
%> @brief Get difference of two input channels.
%> @param src_data The first PSG channel
%> @param ref_data The second PSG channel
%> @note @c src_data and @ref_data must be the same length.
%> @param varargin Additional arguments are not used.
%> @retval The difference of parameters 1 and 2 (i.e. src_data - ref_data)
%  @note written by Hyatt Moore IV, May 12, 2012
%> @note Last modified on 5/6/2014
%> @note Last modified on 8/21/2014
function filtsig = filter_subtract_channel(src_data,ref_data, varargin)
    if(nargin<1)
        filtsig = [];  %useful for abstracting other cases when we have no parameters.
    else
        filtsig = src_data - ref_data;
    end
end
