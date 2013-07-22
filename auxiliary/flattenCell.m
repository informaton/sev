function [X,G] = flattenCell(cell_of_data)
% [X,G] = flattenGroups(cell_of_data)
%       cell_of_data is a cell structure with each element containing a
%       numeric vector of arbitrary length
%       The cells are consolidated into a single vector whose length is the
%       sum of the individual vector lengths at each cell element.
%       G is a vector of size X whose elements correspond to the cell
%       position the corresponding position of X was taken from.  
%
% written by Hyatt Moore IV
% 5/27/2013
%

if(~iscell(cell_of_data))
    cell_of_data = {cell_of_data};
end
numGroups = numel(cell_of_data);

x_len = 0;
for c=1:numGroups
    x_len = x_len+numel(cell_of_data{c});
end

G = zeros(x_len,1);
X = zeros(x_len,1);

cur_ind = 0;
try
for c=1:numGroups
    roi = (1:numel(cell_of_data{c}))+cur_ind;
    X(roi) = cell_of_data{c};
    G(roi) = c;
    cur_ind = cur_ind + numel(cell_of_data{c});
end
catch me
    showME(me);
end
