function  valleys = findvalleys( x )
% valleys = findvalleys( x )
% return local valleys in vector x

%Hyatt Moore IV (< June, 2013)

valleys = findpeaks(-x);

end

