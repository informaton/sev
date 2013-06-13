function S = loadXMLPlist(fname)
% loadXMLPlist  Load and parse Mac OSX XML property list into a structure
%
%   S = loadXMLPlist(filename)
%
%       Returns hierarchical structure S from property list in filename
%
%   See XMLPlistToStruct.m for details.
%
%   JRI 3/16/05 (John R. Iversen <iversen@nsi.edu>)

fid = fopen(fname,'r');
text = char(fread(fid,inf,'uchar'))'; %read as single string
fclose(fid);

S = plist.XMLPlistToStruct(text);