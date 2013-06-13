function S = saveXMLPlist(fname, S)
% saveXMLPlist  Save structure as Mac OSX XML property list
%
%   saveXMLPlist(filename, S)
%
%       Convert S into property list and save to filename
%
%   See structToXMLPlist.m for details.
%
%   JRI 3/16/05 (John R. Iversen <iversen@nsi.edu>)

text = plist.structToXMLPlist(S);

fid = fopen(fname, 'w');
fprintf(fid, '%s', text);
fclose(fid);