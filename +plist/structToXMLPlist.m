function xmlStr = structToXMLPlist(S, key, dictLevel)
% structToXMLPlist  write a structure in Mac OSX XML property list format
%
%   sml = structToXMLPlist(S)
%
%       convert structure S to OS X xml plist format
%           The mapping is straightforward:
%           structure -> dict
%               field names -> keys (Underscores converted to spaces)
%           cellarray -> array
%           logical -> boolean
%           number -> integer or real, depending on key suffix (see below)
%           string -> string, data or date, depending on key suffix
%
%       Note: Since data and date are represented as strings, and integers
%       are represented as doubles, a suffix added to the field name
%       enables them to be tagged with the correct type in xml. The suffix 
%       follows two underscores, and can be one of 'DATA', 'DATE', 
%       or 'INTEGER'. The suffix is removed to make the key.
%
%       for example:
%           S.aNumber__INTEGER = 1     ->   <key>aNumber</key> 
%                                           <integer>1</integer>
%
%           S.anotherNumber    = 1     ->   <key>anotherNumber</key>
%                                           <real>1.0</real>
%   
%           S.a_String         = 'hi'  ->   <key>a String</key>
%                                           <string>hi</string>
%
%           S.a_Date__DATE     = '2005-03-15T07:08:06Z'
%                                      ->   <key>a Date</key>
%                                           <date>2005-03-16T07:08:06Z</date>
%
%       Note: the only non-scalars allowed are cell arrays. For string 
%       arrays, use cellstr. Could add convenience support for 
%       converting numeric vectors into arrays.
%
%   JRI 3/16/05 (John R. Iversen <iversen@nsi.edu>)

%
%   Recursive call:  xml = structToXMLPlist(SSub, key, level)
%       where SSub is the value of a field of the original (or subsequent)
%       structure, and can be another structure, a cell array, string, etc.
%       key is the field name of this value
%       level simply controls the amount of indentation: within a dict or
%       array, level is increased by 1.
%       
%   Limitations: doesn't accept non-cell arrays

if (nargin ~= 1 & nargin ~= 3),
    error('requires 1 or 3 arguments')
end

% starting out at the top level, must be a struct
if (nargin == 1),
    dictLevel = 1;
    if ~isstruct(S), error('Argument must be a struct');end
    key = '';
end

indent = repmat(sprintf('\t'), 1, dictLevel-1);

if ~isempty(key),
    %extract keySuffix
    i2Underscore = findstr(key,'__');
    if ~isempty(i2Underscore),
        keySuffix = key((i2Underscore+2):end);
        key = key(1:(i2Underscore-1));
        %validate suffix
        legalSuffixes = {'DATE','DATA','INTEGER'};
        isLegal = ~isempty(strmatch(keySuffix, legalSuffixes));
        if ~isLegal,
            error(['illegal type suffix: ' keySuffix ' for key ' key])
        end
    else
        keySuffix = '';
    end
    keyStr = sprintf('%s<key>%s</key>\n', indent, key);
else
   keyStr = '';
   keySuffix = '';
end

% Process S recursively. 
% Emit, or accumulate xml, depending on the type of variable in the
%   subfields of S (or its descendents)
%   

%dict
if isstruct(S),
    
    if (any(size(S) > 1)), error('Struct must be scalar');end
    xmlStr = sprintf('%s%s<dict>\n', keyStr, indent);
    fields = fieldnames(S);
    for iField = 1:length(fields),
        subKey = fields{iField};
        var = eval(['S.' subKey]);
        newStr = plist.structToXMLPlist(var, subKey, dictLevel + 1);
        xmlStr = [xmlStr newStr];
    end
    xmlStr = sprintf('%s%s</dict>\n', xmlStr, indent);

%array
elseif iscell(S),

    if (all(size(S) > 1)), error('can only do onedimensional arrays');end
    if (any(size(S) == 0)), error('empty array'); end

    if ( all(size(S) == 1) & isempty(S{1}) ), %one empty entry->empty array
        xmlStr = sprintf('%s%s<array/>\n', keyStr, indent);
    else
        xmlStr = sprintf('%s%s<array>\n', keyStr, indent);
        for i = 1:length(S),
            newStr = plist.structToXMLPlist(S{i}, '', dictLevel + 1); %indent arrays, no individual keys
            xmlStr = [xmlStr newStr];
        end
        xmlStr = sprintf('%s%s</array>\n', xmlStr, indent);
    end

%various leaf types: integer, real, string, date, data, boolean
elseif isnumeric(S),
    if (any(size(S) > 1)), error('Numbers must be scalar');end
    switch keySuffix,
        case 'INTEGER',
            xmlStr = sprintf('%s%s<integer>%.0f</integer>\n', keyStr, indent, S);
        otherwise
            xmlStr = sprintf('%s%s<real>%f</real>\n', keyStr, indent, S);
    end

elseif ischar(S),
    if ( all(size(S) > 1) ), error('Strings must be vectors, not arrays'); end
    switch keySuffix,
        case 'DATA',
            xmlStr = sprintf('%s%s<data>%s</data>\n', keyStr, indent, S);
        case 'DATE',
            xmlStr = sprintf('%s%s<date>%s</date>\n', keyStr, indent, S);
        otherwise
            xmlStr = sprintf('%s%s<string>%s</string>\n', keyStr, indent, S);
    end

elseif islogical(S),
    if (any(size(S) > 1)), error('Logicals must be scalar');end
    if (S == true),
        xmlStr = sprintf('%s%s<true/>\n', keyStr, indent);
    else
        xmlStr = sprintf('%s%s<false/>\n', keyStr, indent);
    end

else
    error('unknown type: fall through')
end

%back to the top level, now finished, add header and footer
if (dictLevel == 1), 
   headerStr = sprintf(['<?xml version="1.0" encoding="UTF-8"?>\n' ...
       '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n' ...
       '<plist version="1.0">\n']);
   footerStr = '</plist>';
   xmlStr = [headerStr xmlStr footerStr];
end
