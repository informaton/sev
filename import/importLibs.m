function importLibs()
    
    matlab.widgets = {
        'getMenuUserData.m'
        'enableFigureHandles.m'
        'disableFigureHandles.m'
        'resizePanelAndFigureForUIControls.m'
        'resizeBatchPanelAndFigureForUIControls.m'
        'resizePanelAndParentForAddedControls.m'        
    };

    
    srcPath = '~/git/matlab';
    destPath = '~/git/sev';
    fields = fieldnames(matlab);
    for f=1:numel(fields)
        curField = fields{f};
        curStruct = matlab.(curField);
        curDestPath = fullfile(destPath,curField);
        for c=1:numel(curStruct)
            filename = curStruct{c};
            fullSrcFile = fullfile(srcPath,curField,filename);
            if(exist(fullSrcFile,'file'))
                curDestFile = fullfile(curDestPath,filename);
                copyfile(fullSrcFile,curDestFile,'f');
                [status, result] = system(strcat('chmod -w ',curDestFile)); % make sure we can't write to these files.  Want to update them in their own repositories (and I don't want to use git submodules)
                if(~status)
                    fprintf('Could not make %s read only.\n\t%s\n',result);
                end
            else
                fprintf('%s: file not found!\n',fullSrcFile);
            end
        end
    end
end