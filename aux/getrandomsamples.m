function indices = getrandomsamples(samplesize, numsampleswanted)
%indices = getrandomsamples(samplesize, numsampleswanted)
%
%returns the number of indices specified by the parameter numsampleswanted
%taken randomly from sample space of size samplesize (n)

%Hyatt Moore, IV (< June, 2013)
r = rand(samplesize,1);
[~,randomindices] = sort(r);

indices = randomindices(1:numsampleswanted);



