%> @file filter_invert
%> @brief Inverts signal (i.e. multiplication by -1).
%======================================================================
%> @brief Invert signal; scale by -1.
%> @param sigData Vector of sample data to filter.
%> @param params N/A
%> @retval filtsig The inverted signal.
%> @note written by Hyatt Moore IV, 11/14/2016
function filtsig = filter_invert(sigData, varargin)
params.scalar=-1;
% return default parameters if no input arguments are provided.
if(nargin==0)
    filtsig = params;
else
    filtsig = sigData*params.scalar;
end