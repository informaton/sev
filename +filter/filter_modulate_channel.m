%> @file filter_modulate_channel.m
%> @brief Modulate two signals by each other.
%======================================================================
%> @brief Modulate src_index by ref_index
%> @param src_sig The source signal
%> @param ref_sig The reference signal
%> @param varargin Not used.
%> @retval filstig src_sig modulated by ref_sig
%> @note written by Hyatt Moore IV, January, 2013
%> @note Modified on 5/6/2014 - removed global CHANNELS_CONTAINER reference
function filtsig = filter_modulate_channel(src_sig, ref_sig, varargin)
filtsig = src_sig.*ref_sig;


