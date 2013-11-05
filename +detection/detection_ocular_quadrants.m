%> @file
%> @brief Eye movement detector designed for Woodward's horizontal/vertical 
%> EOG montage.  See dissertation by Hyatt Moore.
%======================================================================
%> @brief Detect eye movements and the quadrant they fall into.  Quadrants are defined as
%> @li @c 1 = North East
%> @li @c 2 = North West
%> @li @c 3 = South West
%> @li @c 4 = South East
%
%> Detections are defined when pupil position exceeds set distance from pupil's center (defined as 0,0).
%> @param data_cell Two element cell of equal lengthed digitized EOG channel samples
%> @param params A structure for variable parameters passed in
%> with following fields  {default}
%> @li @c params.radius_threshold_uV Eye movements detected when pupil position is greater than the radius threshold {30}
%
%> @param stageStruct Not used; can be empty (i.e. []).
%> @retval detectStruct a structure with following fields
%> @li @c new_data Smoothed version of first input data (i.e.
%> data_cell{1}).
%> @li @c new_events A two column matrix of three start stop sample points of
%> the consecutively ordered detections (i.e. per row).
%> @li @c paramStruct Structure with following field(s) which are vectors
%> with the same numer of elements as rows of @c new_events.
%> @li @c paramStruct.quadrants Values in the set {0,1,2,3} that represent the quadrant of the detected eye movement.
%> Values are mapped to quadrants as follows:
%> @li @c 1 = North East
%> @li @c 2 = North West
%> @li @c 3 = South West
%> @li @c 4 = South East
function detectStruct = detection_ocular_quadrants(data_cell, params, stageStruct)
% data_cell is a cell with eog channels: {horizontal eog, vertical eog}
% detect when eye movements fall into a particular quadrant defined as
% 1 = North East
% 2 = North West
% 3 = South West
% 4 = South East
% varargin{1} params
% varargin{2} optional stage struct

% written by Hyatt Moore IV, March 5, 2013
if(nargin<2 || isempty(params))
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