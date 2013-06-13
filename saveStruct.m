function saveStruct(fid,root,varargin)
%saves the root structure to the file with file identifier fid.
%to display the output to the screen set fid=1
%Note: the root node of a structure is not saved as a field to fid.
%See the second example on how to save the root node if desired.  
%
%
%example: 
%p.x = 1;
%p.z.b = 'hi'
%fid = fopen(filename,'w');
%saveStruct(fid,p);
%fclose(fid);
%
%will save the following to the file named filename
%    x 1
%    z.b 'hi'
%
%if the above example is altered as such
%
%  p.x = 1;
%  p.z.b = 'hi'
%  tmp.p = p;
%  fid = fopen(filename,'w');
%  saveStruct(fid,tmp);
%  fclose(fid);
%
%the following output is saved to the file named filename
%
%    p.x 1
%    p.z.b 'hi'
%
%use loadStruct to recover a structure that has been saved with this
%function.
%
%Author: Hyatt Moore IV
%21JULY2010
%Stanford University

if(isempty(varargin))
    if(isstruct(root))
        fields = fieldnames(root);
        for k=1:numel(fields)
            saveStruct(fid,root,deblank(fields{k}));
        end;
    else
        fprintf(fid,'root %s\r',num2str(root));
    end;
else
    field = getfield(root,varargin{:});
    if(isstruct(field))
        fields = fieldnames(getfield(root,varargin{:}));
        for k=1:numel(fields)
            saveStruct(fid,root,varargin{:},fields{k});
        end;
        fprintf(fid,'\r');
    else
        fprintf(fid,'%s\t%s\r',strcat_with_dot(varargin{:}),num2str(field));
    end;

end;

    
function out_str = strcat_with_dot(root,varargin)
%like strcat, except here a '.' is placed in between each element
if(isempty(varargin))
    out_str = root;
else 
    out_str = strcat(root,'.',strcat_with_dot(varargin{:}));
end;
