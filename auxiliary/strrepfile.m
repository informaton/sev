% contents of inFile.txt
 
% 1 2 NA 3 4 1 2 3
% 1 2 3 4 1 2 3
% 
% 1 2 NA 3 4 1 NA 3
% 1 NA 2 NA 3 4 1 2 3


%>>strrepfile('inFile.txt','outFile.txt','NA','3');

% contents of outFile.txt

% 1 2 3 3 4 1 2 3
% 1 2 3 4 1 2 3
% 
% 1 2 3 3 4 1 3 3
% 1 3 2 3 3 4 1 2 3
function strrepfile(filenameIN,filenameOUT, searchStr, replaceStr)
if(exist(filenameIN,'file'))
    fidOut = fopen(filenameOUT,'w');
    if(fidOut>0)
        fidIn = fopen(filenameIN,'r');
        if(fidIn>0)
            while(~feof(fidIn))
                curLine = fgetl(fidIn);                        
                fprintf(fidOut,'%s\n',strrep(curLine,searchStr,replaceStr));                
            end            
        else
            fprintf('Could not open %s for reading!\n',filenameIN);
        end
        fclose(fidIn);
    else
        fprintf('Could not open %s for writing!\n',filenameOUT);
    end
    fclose(fidOut);
end
    
