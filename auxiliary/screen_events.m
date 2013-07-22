function screenedEvents = screen_events(events, screenRange)
%screenedEvents = screen_events(events,screenRange)
%events is a 2 column matrix of start/stop points
%screenRange is a 2 column matrix containing ranges of acceptable
%start/stop points
%screenedEvents is a 2 column matrix of start/stop points that are within
%the accepted range(s) listed by screenRange
%
%Author: Hyatt Moore IV
%August 4, 2012

screen = false(max([events(:,2);screenRange(:,2)]),1);

%set screen to true for sections in screenRange
for r=1:size(screenRange,1)
    screen(screenRange(r,1):screenRange(r,2)) = true;
end

%apply the screen
screenedEvents = events(screen(events(:,1)),:);