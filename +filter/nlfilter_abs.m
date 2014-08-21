%> @file nfilter_abs.m
%> @brief Returns absolute value of the input signal.
%======================================================================
%> @brief Sums two input channels together as one.
%> @param Vector of time series signal data.
%> @param varargin Additional arguments are not used.
%> @retval filstig The absolute value of of srcData 
function output = nlfilter_abs(srcData,varargin)
%returns the absolute value of the signal
    output = abs(srcData);
end