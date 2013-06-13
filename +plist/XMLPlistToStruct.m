function S = XMLPlistToStruct(xml)
% XMLPlistToStruct  Parse Mac OSX XML property list into matlab structure
%
%   S = XMLPlistToStruct(xmlText)
%
%       return structure S from OS X style XML property list in string xmlText
%
%           The mapping is straightforward:
%           dict -> structure
%           array -> cell array
%           property list keys become field names
%               (note: keys may only contain alphanumeric or space chars)
%           integer, real -> double
%           string, data, date -> string
%
%       Note: data and date are treated as strings, with a suffix (_DATA or
%               _DATE) added to the field name indicating the original type, 
%               similarly _INTEGER is added for integers. This ensures
%               that the original type is preserved if we convert the 
%               structure back to XML.
%
%   See the example plist and usage at the end of this file
%
%   Details of XML property list format are found at:
%   http://developer.apple.com/documentation/Cocoa/Conceptual/PropertyLists/Concepts/XMLPListsConcept.html
%   http://www.apple.com/DTDs/PropertyList-1.0.dtd
%
%   JRI 3/14/05 (John R. Iversen <iversen@nsi.edu>)

dictLevel = 0;
inArray = 0;
arrayIndex = 0;
key = {};

ibra = findstr(xml,'<');
iket = findstr(xml,'>');

if (length(ibra) ~= length(iket)),
    error('unmatched brackets')
end

itag = 1;
while (itag <= length(ibra)),
    
    value = [];
    valueStr = '';
    keySuffix = '';
    
    tag = xml( (ibra(itag)+1):(iket(itag)-1) );
    
    %split tag on first space into tag proper and additional information
    iSpace = strfind(tag, ' ');
    if ~isempty(iSpace),
        tagInfo = tag( (iSpace(1)+1):end );
        tag = tag(1:(iSpace(1)-1));
    end
    
    %if we're in an array, increase the index by one
    if (dictLevel > 0) & inArray(dictLevel),
       arrayIndex(dictLevel) = arrayIndex(dictLevel) + 1;
    end

    switch tag,
        
        case '!DOCTYPE', %make sure it's a plist
            if isempty(findstr(tagInfo, 'plist')),
                error('This is not an Apple plist')
            end
                
        case {'?xml', 'plist', '/plist'},
            %skip other header tags--assume they, as well as outer <plist></plist>, are correct
            
        case 'dict',
            dictLevel = dictLevel + 1;
            inArray(dictLevel) = 0;
            
        case '/dict',
            key(dictLevel) = [];
            if (inArray(dictLevel) ~= 0), error('Array not closed by end of dict'); end
            dictLevel = dictLevel - 1;
            
        case 'key',
            key{dictLevel} = strrep(xml( (iket(itag)+1):(ibra(itag+1)-1) ), ' ', '_');%space->_
            itag = itag + 1; %skip to close
            ctag = xml( (ibra(itag)+1):(iket(itag)-1) );
            if ~strcmp(ctag, ['/' tag]), error(['<' tag '> not properly closed']); end
            
        case 'array',
            inArray(dictLevel) = 1;
            arrayIndex(dictLevel) = 0;
            
        case '/array',
            inArray(dictLevel) = 0;
            arrayIndex(dictLevel) = 0;
            
        case 'array/', %empty array
            value = { [] };
                
        case 'true/'
            value = true; %logical

        case 'false/'
            value = false; %logical

        case {'string', 'date', 'data'},
            valueStr = xml( (iket(itag)+1):(ibra(itag+1)-1) );
            itag = itag + 1; %skip to close
            closetag = xml( (ibra(itag)+1):(iket(itag)-1) );
            if ~strcmp(closetag, ['/' tag]), error(['<' tag '> not properly closed']); end
            %add suffix to indicate original type
            if strcmp(tag, 'date') | strcmp(tag, 'data'),
                keySuffix = ['__' upper(tag)];
            end
            
        case {'integer', 'real'}
            valueStr = xml( (iket(itag)+1):(ibra(itag+1)-1) );
            value = str2num(valueStr);
            itag = itag + 1; %skip to close
            closetag = xml( (ibra(itag)+1):(iket(itag)-1) );
            if ~strcmp(closetag, ['/' tag]), error(['<' tag '> not properly closed']); end
            %add suffix to indicate original type
            if strcmp(tag, 'integer'),
                keySuffix = ['__' upper(tag)];
            end
                
        otherwise
            error(['Unexpected tag: ' tag])
            
    end
    
    if (dictLevel > 0 & length(key)==dictLevel), %if we have the key for current dictLevel

        if ~isempty(value) | ~isempty(valueStr),
            %construct the field name hierarchy, including advancing the array indexing
            fieldname = '';
            for ifield = 1:dictLevel,
                fieldname = [fieldname '.' key{ifield}];
                if inArray(ifield),
                    fieldname = [fieldname '{' num2str(arrayIndex(ifield)) '}'];
                end
            end

            %store value, if we have one
            if ~isempty(value), %it's numeric
                cmd = ['S' fieldname keySuffix ' =  value ;'];
                eval(cmd);
            elseif ~isempty(valueStr),  %it's string
                cmd = ['S' fieldname keySuffix ' =  valueStr ;'];
                eval(cmd);
            end
        end
        
    end
    itag = itag+1;
            
end

if (dictLevel > 0) | any(inArray),
    error('unfinished dict or array, but now at end of file')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%example plist
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% <?xml version="1.0" encoding="UTF-8"?>
% <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
% <plist version="1.0">
% <dict>
% 	<key>string</key>
% 	<string>aString</string>
% 	<key>int</key>
% 	<integer>123</integer>
% 	<key>double</key>
% 	<real>123.456</real>
% 	<key>true</key>
% 	<true/>
% 	<key>false</key>
% 	<false/>
% 	<key>stringarray</key>
% 	<array>
% 		<string>string 1</string>
% 		<string>string 2</string>
% 	</array>
% 	<key>subDict</key>
% 	<dict>
% 		<key>nodes</key>
% 		<integer>6</integer>
% 		<key>channels</key>
% 		<integer>2</integer>
% 	</dict>
% 	<key>arrayofdict</key>
% 	<array>
% 		<dict>
% 			<key>nodes</key>
% 			<integer>6</integer>
% 			<key>channels</key>
% 			<integer>2</integer>
% 		</dict>
% 		<dict>
% 			<key>nodes</key>
% 			<integer>6</integer>
% 			<key>channels</key>
% 			<integer>2</integer>
% 		</dict>
% 	</array>
% 	<key>emptyArray</key>
% 	<array/>
%   <key>aDate</key>
%   <date>2005-03-15T07:08:06Z</date>
%   <key>someData</key>
%   <data>ZDI5eWF5Qm1iM0lnY0dWaFkyVT0=</data>
% </dict>
% </plist>

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%example usage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% >>S = XMLPlistToStruct(xmlString)
%
% S = 
% 
%          string: 'aString'
%     int__INTEGER: 123
%          double: 123.46
%            true: 1
%           false: 0
%     stringarray: {'string 1'  'string 2'}
%         subDict: [1x1 struct]
%     arrayofdict: {[1x1 struct]  [1x1 struct]}
%      emptyArray: {[]}
%      aDate__DATE: '2005-03-15T07:08:06Z'
%   someData__DATA: 'ZDI5eWF5Qm1iM0lnY0dWaFkyVT0='
% 
% >> S.arrayofdict{1}.nodes
% 
% ans =
% 
%      6
%
% >> xml = structToXMLPlist(S);
