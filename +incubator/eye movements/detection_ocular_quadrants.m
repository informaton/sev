function detectStruct = detection_ocular_quadrants(data_cell, varargin )
% data_cell is a cell with eog channels: {horizontal eog, vertical eog}
% detect when eye movements fall into a particular quadrant defined as
% 1 = North East
% 2 = North West
% 3 = South West
% 4 = South East
% varargin{1} params
% varargin{2} optional stage struct

% written by Hyatt Moore IV, March 5, 2013
if(nargin>=2 && ~isempty(varargin{1}))
    params = varargin{1};
else    
    pfile = strcat(mfilename('fullpath'),'.plist');

    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.radius_threshold_uv = 30;
        plist.saveXMLPlist(pfile,params);
    end
end

heog = data_cell{1}; %heog > positive lead is on the right side of face in both cases (when examining the patient)
veog = data_cell{2};

x = heog;
y = veog;
r = sqrt(x.^2+y.^2);

resting_ind = r<params.radius_threshold_uv;
quadrants = zeros(size(resting_ind));

quadrants(x>0&y>0&~resting_ind) = 1;
quadrants(x<0&y>0&~resting_ind) = 2;
quadrants(x<0&y<0&~resting_ind) = 3;
quadrants(x>0&y<0&~resting_ind) = 4;

events = thresholdcrossings(quadrants,0.5);
paramStruct.quadrants = quadrants(events(:,1));
detectStruct.new_events = events;

detectStruct.new_data = r;
detectStruct.paramStruct = paramStruct;