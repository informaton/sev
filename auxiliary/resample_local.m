function  [y, h] = resample( x, p, q, N, bta )
%RESAMPLE  Change the sampling rate of a signal.
%   Y = RESAMPLE(X,P,Q) resamples the sequence in vector X at P/Q times
%   the original sample rate using a polyphase implementation.  Y is P/Q 
%   times the length of X (or the ceiling of this if P/Q is not an integer).  
%   P and Q must be positive integers.
%
%   RESAMPLE applies an anti-aliasing (lowpass) FIR filter to X during the 
%   resampling process, and compensates for the filter's delay.  The filter 
%   is designed using FIRLS.  RESAMPLE provides an easy-to-use alternative
%   to UPFIRDN, which does not require you to supply a filter or compensate
%   for the signal delay introduced by filtering.
%
%   In its filtering process, RESAMPLE assumes the samples at times before
%   and after the given samples in X are equal to zero. Thus large
%   deviations from zero at the end points of the sequence X can cause
%   inaccuracies in Y at its end points.
%
%   Y = RESAMPLE(X,P,Q,N) uses a weighted sum of 2*N*max(1,Q/P) samples of X 
%   to compute each sample of Y.  The length of the FIR filter RESAMPLE applies
%   is proportional to N; by increasing N you will get better accuracy at the 
%   expense of a longer computation time.  If you don't specify N, RESAMPLE uses
%   N = 10 by default.  If you let N = 0, RESAMPLE performs a nearest
%   neighbor interpolation; that is, the output Y(n) is X(round((n-1)*Q/P)+1)
%   ( Y(n) = 0 if round((n-1)*Q/P)+1 > length(X) ).
%
%   Y = RESAMPLE(X,P,Q,N,BTA) uses BTA as the BETA design parameter for the 
%   Kaiser window used to design the filter.  RESAMPLE uses BTA = 5 if
%   you don't specify a value.
%
%   Y = RESAMPLE(X,P,Q,B) uses B to filter X (after upsampling) if B is a 
%   vector of filter coefficients.  RESAMPLE assumes B has odd length and
%   linear phase when compensating for the filter's delay; for even length 
%   filters, the delay is overcompensated by 1/2 sample.  For non-linear 
%   phase filters consider using UPFIRDN.
%
%   [Y,B] = RESAMPLE(X,P,Q,...) returns in B the coefficients of the filter
%   applied to X during the resampling process (after upsampling).
%
%   If X is a matrix, RESAMPLE resamples the columns of X.
%
%   See also UPFIRDN, INTERP, DECIMATE, FIRLS, KAISER, INTFILT,
%   MFILT/FIRSRC in the Filter Design Toolbox.

%   NOTE-1: digital anti-alias filter is desiged via windowing

%   Author(s): James McClellan, 6-11-93
%              Modified to use upfirdn, T. Krauss, 2-27-96
%   Copyright 1988-2003 The MathWorks, Inc.
%   $Revision: 1.9.4.3 $  $Date: 2004/04/13 00:19:02 $

if nargin < 5,  bta = 5;  end   %--- design parameter for Kaiser window LPF
if nargin < 4,   N = 10;   end
if abs(round(p))~=p | p==0, error('P must be a positive integer.'), end
if abs(round(q))~=q | q==0, error('Q must be a positive integer.'), end
[row,col]=size(x);

[p,q] = rat( p/q, 1e-12 );  %--- reduce to lowest terms 
   % (usually exact, sometimes not; loses at most 1 second every 10^12 seconds)
if (p==1)&(q==1)
    y = x; 
    h = 1;
    return
end
pqmax = max(p,q);
if length(N)>1      % use input filter
   L = length(N);
   h = N;
else                % design filter
   if( N>0 )
      fc = 1/2/pqmax;
      L = 2*N*pqmax + 1;
      h = p*firls( L-1, [0 2*fc 2*fc 1], [1 1 0 0]).*kaiser(L,bta)' ;
      % h = p*fir1( L-1, 2*fc, kaiser(L,bta)) ;
   else
      L = p;
      h = ones(1,p);
   end
end

Lhalf = (L-1)/2;
isvect = any(size(x)==1);
if isvect
    Lx = length(x);
else
    [Lx,num_sigs]=size(x);
end

% Need to delay output so that downsampling by q hits center tap of filter.
nz = floor(q-mod(Lhalf,q));
z = zeros(1,nz);
h = [z h(:).'];  % ensure that h is a row vector.
Lhalf = Lhalf + nz;

% Number of samples removed from beginning of output sequence 
% to compensate for delay of linear phase filter:
delay = floor(ceil(Lhalf)/q);

% Need to zero-pad so output length is exactly ceil(Lx*p/q).
nz1 = 0;
while ceil( ((Lx-1)*p+length(h)+nz1 )/q ) - delay < ceil(Lx*p/q)
    nz1 = nz1+1;
end
h = [h zeros(1,nz1)];

% ----  HERE'S THE CALL TO UPFIRDN  ----------------------------
y = upfirdn(x,h,p,q);

% Get rid of trailing and leading data so input and output signals line up
% temporally:
Ly = ceil(Lx*p/q);  % output length
% Ly = floor((Lx-1)*p/q+1);  <-- alternately, to prevent "running-off" the
%                                data (extrapolation)
if isvect
    y(1:delay) = [];
    y(Ly+1:end) = [];
else
    y(1:delay,:) = [];
    y(Ly+1:end,:) = [];
end

h([1:nz (end-nz1+1):end]) = [];  % get rid of leading and trailing zeros 
                                 % in case filter is output

end

function [h,a]=firls(N,F,M,W,ftype);
% FIRLS Linear-phase FIR filter design using least-squares error minimization.
%   B=FIRLS(N,F,A) returns a length N+1 linear phase (real, symmetric
%   coefficients) FIR filter which has the best approximation to the
%   desired frequency response described by F and A in the least squares
%   sense. F is a vector of frequency band edges in pairs, in ascending
%   order between 0 and 1. 1 corresponds to the Nyquist frequency or half
%   the sampling frequency. A is a real vector the same size as F
%   which specifies the desired amplitude of the frequency response of the
%   resultant filter B. The desired response is the line connecting the
%   points (F(k),A(k)) and (F(k+1),A(k+1)) for odd k; FIRLS treats the
%   bands between F(k+1) and F(k+2) for odd k as "transition bands" or
%   "don't care" regions. Thus the desired amplitude is piecewise linear
%   with transition bands.  The integrated squared error is minimized.
%
%   For filters with a gain other than zero at Fs/2, e.g., highpass
%   and bandstop filters, N must be even.  Otherwise, N will be
%   incremented by one. Alternatively, you can use a trailing 'h' flag to
%   design a type 4 linear phase filter and avoid incrementing N.
%
%   B=FIRLS(N,F,A,W) uses the weights in W to weight the error. W has one
%   entry per band (so it is half the length of F and A) which tells
%   FIRLS how much emphasis to put on minimizing the integral squared error
%   in each band relative to the other bands.
%
%   B=FIRLS(N,F,A,'Hilbert') and B=FIRLS(N,F,A,W,'Hilbert') design filters
%   that have odd symmetry, that is, B(k) = -B(N+2-k) for k = 1, ..., N+1.
%   A special case is a Hilbert transformer which has an approx. amplitude
%   of 1 across the entire band, e.g. B=FIRLS(30,[.1 .9],[1 1],'Hilbert').
%
%   B=FIRLS(N,F,A,'differentiator') and B=FIRLS(N,F,A,W,'differentiator')
%   also design filters with odd symmetry, but with a special weighting
%   scheme for non-zero amplitude bands. The weight is assumed to be equal
%   to the inverse of frequency, squared, times the weight W. Thus the
%   filter has a much better fit at low frequency than at high frequency.
%   This designs FIR differentiators.
%
%   % Example of a length 31 lowpass filter.
%   h=firls(30,[0 .1 .2 .5]*2,[1 1 0 0]);
%   fvtool(h);
%
%   % Example of a length 45 lowpass differentiator.
%   h=firls(44,[0 .3 .4 1],[0 .2 0 0],'differentiator');
%   fvtool(h);
%
%   % Example of a length 26 type 4 highpass filter.
%   h=firls(25,[0 .4 .5 1],[0 0 1 1],'h');
%   fvtool(h);
%
%   See also FIRPM, FIR1, FIR2, FREQZ and FILTER.

%       Author(s): T. Krauss
%   History: 10-18-91, original version
%            3-30-93, updated
%            9-1-95, optimize adjacent band case
%   Copyright 1988-2004 The MathWorks, Inc.
%   $Revision: 1.11.4.3 $  $Date: 2004/07/28 04:37:44 $

% check number of arguments, set up defaults.
nargchk(3,5,nargin);

if (max(F)>1) || (min(F)<0)
    error('Frequencies in F must be in range [0,1].')
end
if (rem(length(F),2)~=0)
    error('F must have even length.');
end
if (length(F) ~= length(M))
    error('F and A must be equal lengths.');
end
if (nargin==3),
    W = ones(length(F)/2,1);
    ftype = '';
end
if (nargin==4),
    if isstr(W),
        ftype = W; W = ones(length(F)/2,1);
    else
        ftype = '';
    end
end
if (nargin==5),
    if isempty(W),
        W = ones(length(F)/2,1);
    end
end
if isempty(ftype)
    ftype = 0;  differ = 0;
else
    ftype = lower(ftype);
    if strcmpi(ftype,'h') || strcmpi(ftype,'hilbert')
        ftype = 1;  differ = 0;
    elseif strcmpi(ftype,'d') || strcmpi(ftype,'differentiator')
        ftype = 1;  differ = 1;
    else
        error('Requires symmetry to be ''Hilbert'' or ''differentiator''.')
    end
end

% Check for valid filter length
[N,msg1,msg2] = firchk(N,F(end),M,ftype);
error(msg1);

if ~isempty(msg2),
    msg2 = sprintf([msg2,'\r',...
        '\nAlternatively, you can pass a trailing ''h'' argument,\r',...
        'as in firls(N,F,A,W,''h''), to design a type 4 linear phase filter.']);
end
warning(msg2);


N = N+1;                   % filter length
F=F(:)/2;  M=M(:);  W=sqrt(W(:));  % make these guys columns
dF = diff(F);

if (length(F) ~= length(W)*2)
    error('There should be one weight per band.');
end;
if any(dF<0),
    error('Frequencies in F must be nondecreasing.')
end

% Fix for 67187
if all(dF(2:2:length(dF)-1)==0) && length(dF) > 1,
    fullband = 1;
else
    fullband = 0;
end
if all((W-W(1))==0)
    constant_weights = 1;
else
    constant_weights = 0;
end

L=(N-1)/2;

Nodd = rem(N,2);

if (ftype == 0),  % Type I and Type II linear phase FIR
    % basis vectors are cos(2*pi*m*f) (see m below)
    if ~Nodd
        m=(0:L)+.5;   % type II
    else
        m=(0:L);      % type I
    end
    k=m';
    need_matrix = (~fullband) || (~constant_weights);
    if need_matrix
        I1=k(:,ones(size(m)))+m(ones(size(k)),:);    % entries are m + k
        I2=k(:,ones(size(m)))-m(ones(size(k)),:);    % entries are m - k
        G=zeros(size(I1));
    end

    if Nodd
        k=k(2:length(k));
        b0=0;       %  first entry must be handled separately (where k(1)=0)
    end;
    b=zeros(size(k));
    for s=1:2:length(F),
        m=(M(s+1)-M(s))/(F(s+1)-F(s));    %  slope
        b1=M(s)-m*F(s);                   %  y-intercept
        if Nodd
            b0 = b0 + (b1*(F(s+1)-F(s)) + m/2*(F(s+1)*F(s+1)-F(s)*F(s)))...
                * abs(W((s+1)/2)^2) ;
        end
        b = b+(m/(4*pi*pi)*(cos(2*pi*k*F(s+1))-cos(2*pi*k*F(s)))./(k.*k))...
            * abs(W((s+1)/2)^2);
        b = b + (F(s+1)*(m*F(s+1)+b1)*sinc(2*k*F(s+1)) ...
            - F(s)*(m*F(s)+b1)*sinc(2*k*F(s))) ...
            * abs(W((s+1)/2)^2);
        if need_matrix
            G = G + (.5*F(s+1)*(sinc(2*I1*F(s+1))+sinc(2*I2*F(s+1))) ...
                - .5*F(s)*(sinc(2*I1*F(s))+sinc(2*I2*F(s))) ) ...
                * abs(W((s+1)/2)^2);
        end
    end;
    if Nodd
        b=[b0; b];
    end;

    if need_matrix
        a=G\b;
    else
        a=(W(1)^2)*4*b;
        if Nodd
            a(1) = a(1)/2;
        end
    end
    if Nodd
        h=[a(L+1:-1:2)/2; a(1); a(2:L+1)/2].';
    else
        h=.5*[flipud(a); a].';
    end;
elseif (ftype == 1),  % Type III and Type IV linear phase FIR
    %  basis vectors are sin(2*pi*m*f) (see m below)
    if (differ),      % weight non-zero bands with 1/f^2
        do_weight = ( abs(M(1:2:length(M))) +  abs(M(2:2:length(M))) ) > 0;
    else
        do_weight = zeros(size(F));
    end

    if Nodd
        m=(1:L);      % type III
    else
        m=(0:L)+.5;   % type IV
    end;
    k=m';
    b=zeros(size(k));

    need_matrix = (~fullband) || (any(do_weight)) || (~constant_weights);
    if need_matrix
        I1=k(:,ones(size(m)))+m(ones(size(k)),:);    % entries are m + k
        I2=k(:,ones(size(m)))-m(ones(size(k)),:);    % entries are m - k
        G=zeros(size(I1));
    end

    i = sqrt(-1);
    for s=1:2:length(F),
        if (do_weight((s+1)/2)),      % weight bands with 1/f^2
            if F(s) == 0, F(s) = 1e-5; end     % avoid singularities
            m=(M(s+1)-M(s))/(F(s+1)-F(s));
            b1=M(s)-m*F(s);
            snint1 = sineint(2*pi*k*F(s+1)) - sineint(2*pi*k*F(s));
            %snint1 = (-1/2/i)*(expint(i*2*pi*k*F(s+1)) ...
            %    -expint(-i*2*pi*k*F(s+1)) -expint(i*2*pi*k*F(s)) ...
            %    +expint(-i*2*pi*k*F(s)) );
            % csint1 = cosint(2*pi*k*F(s+1)) - cosint(2*pi*k*F(s)) ;
            csint1 = (-1/2)*(expint(i*2*pi*k*F(s+1))+expint(-i*2*pi*k*F(s+1))...
                -expint(i*2*pi*k*F(s))  -expint(-i*2*pi*k*F(s)) );
            b=b + ( m*snint1 ...
                + b1*2*pi*k.*( -sinc(2*k*F(s+1)) + sinc(2*k*F(s)) + csint1 ))...
                * abs(W((s+1)/2)^2);
            snint1 = sineint(2*pi*F(s+1)*(-I2));
            snint2 = sineint(2*pi*F(s+1)*I1);
            snint3 = sineint(2*pi*F(s)*(-I2));
            snint4 = sineint(2*pi*F(s)*I1);
            G = G - ( ( -1/2*( cos(2*pi*F(s+1)*(-I2))/F(s+1)  ...
                - 2*snint1*pi.*I2 ...
                - cos(2*pi*F(s+1)*I1)/F(s+1) ...
                - 2*snint2*pi.*I1 )) ...
                - ( -1/2*( cos(2*pi*F(s)*(-I2))/F(s)  ...
                - 2*snint3*pi.*I2 ...
                - cos(2*pi*F(s)*I1)/F(s) ...
                - 2*snint4*pi.*I1) ) ) ...
                * abs(W((s+1)/2)^2);
        else      % use usual weights
            m=(M(s+1)-M(s))/(F(s+1)-F(s));
            b1=M(s)-m*F(s);
            b=b+(m/(4*pi*pi)*(sin(2*pi*k*F(s+1))-sin(2*pi*k*F(s)))./(k.*k))...
                * abs(W((s+1)/2)^2) ;
            b = b + (((m*F(s)+b1)*cos(2*pi*k*F(s)) - ...
                (m*F(s+1)+b1)*cos(2*pi*k*F(s+1)))./(2*pi*k)) ...
                * abs(W((s+1)/2)^2) ;
            if need_matrix
                G = G + (.5*F(s+1)*(sinc(2*I1*F(s+1))-sinc(2*I2*F(s+1))) ...
                    - .5*F(s)*(sinc(2*I1*F(s))-sinc(2*I2*F(s)))) * ...
                    abs(W((s+1)/2)^2);
            end
        end;
    end

    if need_matrix
        a=G\b;
    else
        a=-4*b*(W(1)^2);
    end
    if Nodd
        h=.5*[flipud(a); 0; -a].';
    else
        h=.5*[flipud(a); -a].';
    end
    if differ, h=-h; end
end

if nargout > 1
    a = 1;
end
end
%----------------------------------------------------------------------------
function y = sineint(x)
% SINEINT (a.k.a. SININT)   Numerical Sine Integral
%   Used by FIRLS in the Signal Processing Toolbox.
%   Untested for complex or imaginary inputs.
%
%   See also SININT in the Symbolic Toolbox.

%   Was Revision: 1.5, Date: 1996/03/15 20:55:51

i1 = find(real(x)<0);   % this equation is not valid if x is in the
% left-hand plane of the complex plane.
% use relation Si(-z) = -Si(z) in this case (Eq 5.2.19, Abramowitz
%  & Stegun).
x(i1) = -x(i1);
y = zeros(size(x));
ind = find(x);
% equation 5.2.21 Abramowitz & Stegun
%  y(ind) = (1/(2*i))*(expint(i*x(ind)) - expint(-i*x(ind))) + pi/2;
y(ind) = imag(expint(i*x(ind))) + pi/2;
y(i1) = -y(i1);

end
% FIRCHK   Check if specified filter order is valid.
function [N,msg1,msg2,msgObj] = firchk(N,Fend,a,exception) %#codegen

%   Copyright 2000-2018 The MathWorks, Inc.

%   FIRCHK(N,Fend,A) checks if the specified order N is valid given the
%   final frequency point Fend and the desired magnitude response vector A.
%   Type 2 linear phase FIR filters (symmetric, odd order) must have a
%   desired magnitude response vector that ends in zero if Fend = 1.  This
%   is because type 2 filters necessarily have a zero at w = pi.
%
%   If the order is not valid, a warning is given and the order
%   of the filter is incremented by one.
%
%   If A is a scalar (as when called from fircls1), A = 0 is
%   interpreted as lowpass and A = 1 is interpreted as highpass.
%
%   FIRCHK(N,Fend,A,EXCEPTION) will not warn or increase the order
%   if EXCEPTION = 1.  Examples of EXCEPTIONS are type 4 filters
%   (such as differentiators or hilbert transformers) or non-linear
%   phase filters (such as minimum and maximum phase filters).


narginchk(3,4);

if nargin == 3
    exception = false;
end
    msg1 = '';
    msg2 = '';
    
if coder.target('MATLAB') % for MATLAB Execution    
    msgObj = [];   
else
    msgObj = zeros(0,1);
end

if isempty(N) || length(N) > 1 || ~isnumeric(N) || ~isreal(N) || N~=round(N) || N<=0
    [msg1, msgObj] = constructErrorObj("error",'signal:firchk:NeedRealPositiveOrder');    
    return;
end
 
if (a(end) ~= 0) && Fend == 1 && isodd(N) && ~exception
    [msg2, msgObj] = constructErrorObj("warning",'signal:firchk:NeedZeroGain');
    N = N + 1;
end

end

function [msg,msgobj] = constructErrorObj(errorType,varargin)
% constructErrorObj : constructs the required error object based on the
% target and error type. Type can be warning or error.
    if coder.target('MATLAB')
        msgobj = message(varargin{:});
        msg = getString(msgobj);
    elseif errorType == "error"
        msgobj = [];
        msg = '';
        coder.internal.error(varargin{:});
        return;
    elseif errorType == "warning"
        msgobj = [];
        msg = '';
        coder.internal.warning(varargin{:});
        return;    
    end

end

function y=sinc(x)
%SINC Sin(pi*x)/(pi*x) function.
%   SINC(X) returns a matrix whose elements are the sinc of the elements 
%   of X, i.e.
%        y = sin(pi*x)/(pi*x)    if x ~= 0
%          = 1                   if x == 0
%   where x is an element of the input matrix and y is the resultant
%   output element.
%
%   % Example of a sinc function for a linearly spaced vector:
%   t = linspace(-5,5);
%   y = sinc(t);
%   plot(t,y);
%   xlabel('Time (sec)');ylabel('Amplitude'); title('Sinc Function')
%
%   See also SQUARE, SIN, COS, CHIRP, DIRIC, GAUSPULS, PULSTRAN, RECTPULS,
%   and TRIPULS.

%   Author(s): T. Krauss, 1-14-93
%   Copyright 1988-2004 The MathWorks, Inc.
%   $Revision: 1.7.4.1 $  $Date: 2004/08/10 02:11:27 $

i=find(x==0);                                                              
x(i)= 1;      % From LS: don't need this is /0 warning is off                           
y = sin(pi*x)./(pi*x);                                                     
y(i) = 1;   

end

function w = kaiser(n_est,bta)
%KAISER Kaiser window.
%   W = KAISER(N) returns an N-point Kaiser window in the column vector W.
% 
%   W = KAISER(N,BTA) returns the BETA-valued N-point Kaiser window.
%       If ommited, BTA is set to 0.500.
%
%   See also CHEBWIN, GAUSSWIN, TUKEYWIN, WINDOW.

%   Author(s): L. Shure, 3-4-87
%   Copyright 1988-2003 The MathWorks, Inc.
%   $Revision: 1.17.4.2 $  $Date: 2004/04/13 00:18:04 $

error(nargchk(1,2,nargin));

% Default value for the BETA parameter.
if nargin < 2 || isempty(bta), 
    bta = 0.500;
end

[nn,w,trivialwin] = check_order(n_est);
if trivialwin, return, end;

nw = round(nn);
bes = abs(besseli(0,bta));
odd = rem(nw,2);
xind = (nw-1)^2;
n = fix((nw+1)/2);
xi = (0:n-1) + .5*(1-odd);
xi = 4*xi.^2;
w = besseli(0,bta*sqrt(1-xi/xind))/bes;
w = abs([w(n:-1:odd+1) w])';

    
% [EOF] kaiser.m
end

function [n_out, w, trivalwin] = check_order(n_in)
%CHECK_ORDER Checks the order passed to the window functions.
% [N,W,TRIVALWIN] = CHECK_ORDER(N_ESTIMATE) will round N_ESTIMATE to the
% nearest integer if it is not already an integer. In special cases (N is
% [], 0, or 1), TRIVALWIN will be set to flag that W has been modified.

%   Copyright 1988-2018 The MathWorks, Inc.

%#codegen

w = 0;
trivalwin = 0;

% Special case of N is []
if isempty(n_in)
    n_out = 0;
    w = zeros(0,1);
    trivalwin = 1;
    return
end

validateattributes(n_in,{'numeric'},{'scalar','finite','real','nonnegative'},'check_order','N');
n_in = n_in(1);

% Check if order is already an integer or empty
% If not, round to nearest integer.
if n_in == floor(n_in)
    n_out = n_in;
else
    n_out = round(n_in);
    coder.internal.warning('signal:check_order:InvalidOrderRounding');
end
    
% special cases: N is 0 0r 1
if n_out == 0 
    w = zeros(0,1);       % Empty matrix: 0-by-1
    trivalwin = 1;
elseif n_out == 1
    w = 1;
    trivalwin = 1;
end


% LocalWords:  TRIVALWIN
end

function Y = upfirdn(x,h,varargin)
%UPFIRDN  Upsample, apply a specified FIR filter, and downsample a signal.
%   UPFIRDN(X,H,P,Q) is a cascade of three systems applied to input signal X:
%         (1) Upsampling by P (zero insertion).  P defaults to 1 if not 
%             specified.
%         (2) FIR filtering with the filter specified by the impulse response 
%             given in H.
%         (3) Downsampling by Q (throwing away samples).  Q defaults to 1 if not 
%             specified.
%   UPFIRDN uses an efficient polyphase implementation.
%
%   Usually X and H are vectors, and the output is a (signal) vector. 
%   UPFIRDN permits matrix arguments under the following rules:
%   If X is a matrix and H is a vector, each column of X is filtered through H.
%   If X is a vector and H is a matrix, each column of H is used to filter X.
%   If X and H are both matrices with the same number of columns, then the i-th
%      column of H is used to filter the i-th column of X.
%
%   Specifically, these rules are carried out as follows.  Note that the length
%   of the output is Ly = ceil( ((Lx-1)*P + Lh)/Q ) where Lx = length(X) and 
%   Lh = length(H). 
%
%      Input Signal X    Input Filter H    Output Signal Y   Notes
%      -----------------------------------------------------------------
%   1) length Lx vector  length Lh vector  length Ly vector  Usual case.
%   2) Lx-by-Nx matrix   length Lh vector  Ly-by-Nx matrix   Each column of X
%                                                            is filtered by H.
%   3) length Lx vector  Lh-by-Nh matrix   Ly-by-Nh matrix   Each column of H is
%                                                            used to filter X.
%   4) Lx-by-N matrix    Lh-by-N matrix    Ly-by-N matrix    i-th column of H is
%                                                            used to filter i-th
%                                                            column of X.
%
%   For an easy-to-use alternative to UPFIRDN, which does not require you to 
%   supply a filter or compensate for the signal delay introduced by filtering,
%   use RESAMPLE.
%
%   EXAMPLE: Sample-rate conversion by a factor of 147/160 (used to
%     downconvert from 48kHz to 44.1kHz)
%        L = 147; M = 160;                   % Interpolation/decimation factors.
%        N = 24*M;
%        h = fir1(N,1/M,kaiser(N+1,7.8562));
%        h = L*h; % Passband gain = L
%        Fs = 48e3;                           % Original sampling frequency: 48kHz
%        n = 0:10239;                         % 10240 samples, 0.213 seconds long
%        x  = sin(2*pi*1e3/Fs*n);             % Original signal, sinusoid at 1kHz
%        y = upfirdn(x,h,L,M);                % 9408 samples, still 0.213 seconds
%
%        % Overlay original (48kHz) with resampled signal (44.1kHz) in red.
%        stem(n(1:49)/Fs,x(1:49)); hold on 
%        stem(n(1:45)/(Fs*L/M),y(13:57),'r','filled'); 
%        xlabel('Time (sec)');ylabel('Signal value');
%  
%   See also RESAMPLE, INTERP, DECIMATE, FIR1, INTFILT, MFILT/FIRSRC in the
%   Filter Design Toolbox.
  
%   Author(s): Paul Pacheco
%   Copyright 1988-2002 The MathWorks, Inc.
%   $Revision: 1.6.4.1 $  $Date: 2002/12/19 10:34:29 $

%   This M-file validates the inputs, sets defaults, and then calls the C MEX-file.

% Validate number of I/O args.
error(nargchk(2,4,nargin));
error(nargoutchk(0,1,nargout));

% Force to be a column if input is a vector
[mx,nx] = size(x);
if find([mx nx]==1),
  x = x(:);  % columnize it.
end
[Lx,nChans] = size(x);

% Force to be a column if filter is a vector
if find(size(h)==1),
  h = h(:);  % columnize it.
end
[Lh,hCols] = size(h);

% Validate input args and define defaults.
[p,q,msg] = validateinput(x,h,varargin);
error(msg);

% Call the MEX-file
Y = upfirdnmex(x,h,p,q,Lx,Lh,hCols,nChans);
if mx==1,
  % Convert output to be a row vector.
  Y = Y(:).';
end

end
%----------------------------------------------------------------------
function [p,q,errmsg] = validateinput(x,h,opts);

% Default values
p = 1;
q = 1;
errmsg = '';

% Validate 1st two input args: signal and filter.
if isempty(x) | issparse(x) | ~isnumeric(x),
  errmsg = 'The input signal X must be a double-precision vector.';
  return;
end
if isempty(h) | issparse(h) | ~isnumeric(h),
  errmsg = 'The filter H must be a double-precision vector.';
  return;
end

% At this point x and h have been columnized if necessary.
% Make sure x and h have the same number of columns.
[Lx,nChans] = size(x);
[Lh,hCols]  = size(h);
if (hCols > 1) & (hCols ~= nChans),
  error('Signal X and filter H must have the same number of columns.');
end

% Validate optional input args: upsample and downsample factors.
nopts = length(opts);
if (nopts >= 1),
    p = opts{1};
    if isempty(p) | ~isnumeric(p) | p<1 | ~isequal(round(p),p), 
        errmsg = 'The upsample factor P must be a positive, double-precision, integer.';
        return;
        
    elseif (nopts == 2),
        q = opts{2};
        if isempty(q) | ~isnumeric(q) | q<1 | ~isequal(round(q),q),
            errmsg = 'The downsample factor Q must be a positive, double-precision, integer.';
            return;
        end
    end
end

% [EOF]

end