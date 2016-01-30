function [A,f,tt] = hhspectrum(imf,t,l,aff)

% [A,f,tt] = HHSPECTRUM(imf,t,l,aff) computes the Hilbert-Huang spectrum
%
% inputs:
% 	- imf : matrix with one IMF per row
%   - t   : time instants
%   - l   : estimation parameter for instfreq
%   - aff : if 1, displays the computation evolution
%
% outputs:
%   - A   : amplitudes of IMF rows
%   - f   : instantaneous frequencies
%   - tt  : truncated time instants
%
% calls:
%   - hilbert  : computes the analytic signal
%   - instfreq : computes the instantaneous frequency
% Hyatt found this on the internet at
% http://read.pudn.com/downloads91/sourcecode/speech/348429/hhspectrum.m__.htm
%
% modified the code in a few parts to help optimize for our purposes
% (variable assignments and for loop parameters)

imf = imf(:).'; %fails otherwise here...
if nargin < 2

  t=1:size(imf,2);

end

if nargin < 3

  l=1;

end

if nargin < 4

  aff = 0;

end

lt=length(t);

tt=t((l+1):(lt-l));

% an = zeros(size(imf));

for i=1:(size(imf,1)) %edited this so that it no longer has a -1 inside the last parenthesis, thus allowing imfs with just one emd

  an(i,:)=hilbert(imf(i,:)')';
  f(i,:)=instfreq(an(i,:)',tt,l)';
  A=abs(an(:,l+1:end-l));

  if aff

    disp(['mode ',int2str(i),' traitŽ'])

  end

end