function go2sev()
%helper function to get to the SEV directory, replace with your own folder
%name if you like and make sure the sev/auxiliary path (where this file is located)
%is in your MATLAB path  sev/auxialiary.  And now it is different.
fmf = mfilename('fullpath');
cd(fileparts(fmf));
cd ..;