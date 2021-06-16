%----------------------------------------function-------------------------
function pixel=normalized2pixel(normalized)
% Input is normalized value of screen units to be converted to pixel units 

screen_size = get(0,'Screensize');
width = screen_size(3);
height = screen_size(4);

if(numel(normalized)==2)
    pixel = normalized.*[width,height];
elseif(numel(normalized)==4)
    pixel = normalized.*repmat(width,height,1,2);
else
    pixel = normalized(1)*width;
end